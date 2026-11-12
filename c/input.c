/* input.c -- INPUT.ASM (original addresses 2028-2290) read as C: number and money entry, the
 * shops' prices, "illegal command", and the monsters' step outdoors and in towns.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/INPUT.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine, that it prints
 * the same texts and that it calls the same routines at least as often. It cannot check the logic.
 *
 * Despite the module's name, half of it is monster movement. MonsterStepToward and
 * MoveMonsterToTarget are not called but JUMPED to by the monster loops (MAIN's OutdoorMonsters,
 * EVENTS' TownTurn), and they jump back into the loop: to TownTurnNextMonster when MapType is not
 * 0 (a town), to OutdoorMonsters_Next on the surface. Here they are functions that return to the
 * loop, so both of those jumps are a plain return.
 *
 * Map bytes here are full codes (twice the tile number): 00 water, 04 marsh, 08 grass, 0Ch woods,
 * 10h mountains, 5Ch force field, 70h town floor.
 *
 * See shops.c for the conventions shared by all the C files.
 */

#include "u2.h"

/* ---- Numbers and money ---------------------------------------------------------------------- */

/* asm: ReadDigit @2028 -- waits for a key '0'-'9' (every other key is ignored), echoes it and a
 * carriage return, and returns its value. (The assembly also leaves the zero flag set for 0, which
 * its callers test; here they compare the value.) */
u8 ReadDigit(void)
{
    u8 key;

    do {
        key = ReadAsciiKey();
    } while (key < '0' || key > '9');
    PutChar(key);
    PutChar('\n');
    return (u8)(key - '0');
}

/* asm: PayPrice @2052 -- the gold (GoldHi:GoldLo, four BCD digits) minus the price
 * (AmountHi:AmountLo), the borrow passed from the low byte to the high one. A borrow out of the
 * high byte means the player is too poor: the price is added back (which restores the gold
 * exactly, for valid BCD), and the assembly drops its caller's return address, prints the text and
 * ends the turn with the error beep (EndCommandBeep). Here it returns false and the caller returns
 * (see u2.h). */
bool PayPrice(void)
{
    int borrow = 0;
    int carry = 0;

    GoldLo = bcd_sbb(GoldLo, AmountLo, &borrow);
    GoldHi = bcd_sbb(GoldHi, AmountHi, &borrow);
    if (!borrow)
        return true;
    GoldLo = bcd_adc(GoldLo, AmountLo, &carry);     /* too poor: put the price back */
    GoldHi = bcd_adc(GoldHi, AmountHi, &carry);
    PrintInline("YOU DONT HAVE THAT MUCH!");
    Beep();
    return false;
}

/* asm: CalcPrice @20AB
 *
 * A shop's price for item (or price class) n. The price walks a Fibonacci-like series in BCD,
 * starting from the pair (4, 4): 8, 12, 20, 32, 52, 84, 136, ... (each term the sum of the two
 * before), for n + 8 - b steps, where b is the number of significant bits of Intelligence +
 * Charisma (1 for 0, 8 for 80h-FFh). Better attributes make things cheaper, at most down to n steps.
 *
 * QUIRK, as in the original: the two attributes are BCD but are added as plain binary bytes, and
 * the sum wraps at 100h. Intelligence 40 + charisma 40 is 80h, the best price; 80 + 80 is 100h,
 * which wraps to 0: one bit, seven more steps than the best, the dearest prices in the game (a
 * dagger 0220 instead of 0008). 95 + 95 (12Ah -> 2Ah) pays what 15 + 15 pays. See
 * docs/FINDINGS.md.
 *
 * Other details: the carry out of the high byte is lost, so a price past 9999 wraps; the addition
 * of the attributes takes in the carry of "n + 8" (always 0 for the shops' n of 1-12); and n + 8 - b
 * = 0 would run the loop 65536 times (it cannot happen: the shops never ask for item 0). */
void CalcPrice(u8 item)
{
    u8 steps;                   /* asm: Temp20, then DI */
    u8 sum;
    u8 bits;                    /* asm: SI */
    u8 prev_hi, prev_lo;        /* asm: Temp29, Temp2A: the term before */
    u8 new_lo;
    int carry;
    u16 n;

    steps = (u8)(item + 8);
    AmountHi = 0;   prev_hi = 0;
    AmountLo = 4;   prev_lo = 4;
    sum = (u8)(Intelligence + Charisma);            /* binary, not BCD: see above */
    bits = 0;
    do {
        bits++;
        sum >>= 1;
    } while (sum != 0);
    steps = (u8)(steps - bits);

    n = steps;
    do {                                            /* (price, prev) := (price + prev, price) */
        carry = 0;
        new_lo = bcd_adc(prev_lo, AmountLo, &carry);
        prev_lo = AmountLo;
        AmountLo = new_lo;
        new_lo = bcd_adc(prev_hi, AmountHi, &carry);    /* the low byte's carry goes in here */
        prev_hi = AmountHi;
        AmountHi = new_lo;
    } while (--n != 0);
}

/* ---- Monsters on the surface and in towns --------------------------------------------------- */

/* asm: MonsterCanEnter @2199
 *
 * May the monster in this slot enter the square LookX/LookY, whose map byte is `square`?
 *   - nothing moves while time is stopped (N)egate time);
 *   - the sea serpent (2Ch) and the pirate ship (48h) move on water only;
 *   - the other monsters below 78h (not the townspeople) may also cross force fields (5Ch);
 *   - otherwise: grass and woods (below 14h, but not water 00 or marsh 04) and town floor (70h);
 *     never mountains (10h).
 * In a town (MapType not 0) a square on row 0 or column 0 is refused as well. */
static bool MonsterCanEnter(u8 slot, u8 square)
{
    u8 kind;

    if (TimeStopTurns != 0)
        return false;
    kind = MonsterTile[slot];
    if (kind == 0x2C || kind == 0x48) {
        if (square != 0)
            return false;
    } else if (!(kind < 0x78 && square == 0x5C)) {
        if (square == 0x10 || square == 4 || square == 0)
            return false;
        if (square >= 0x14 && square != 0x70)
            return false;
    }
    if (MapType != 0 && (LookX == 0 || LookY == 0))
        return false;
    return true;
}

/* asm: MonsterStepToward @2122 returns: TownTurnNextMonster OutdoorMonsters_Next
 *
 * Moves the monster one square along DeltaX/DeltaY (each -1, 0 or +1: towards the player, or away
 * when the caller made it flee). First a monster with fewer than 10h hit points heals one. Then it
 * tries, in order, the diagonal step (x+dx, y+dy), the step along y (x, y+dy) if dy is not 0, and
 * the step along x (x+dx, y); coordinates wrap at 64. The first square MonsterCanEnter allows is
 * where MoveMonsterToTarget takes it; if none is, it stays. (With dx = 0 the first two tries are
 * the same square, with dy = 0 the first and the third.) */
void MonsterStepToward(u8 slot)
{
    if (MonsterHP[slot] < 0x10)
        MonsterHP[slot]++;

    LookX = (u8)((MonsterX[slot] + DeltaX) & 0x3F);
    LookY = (u8)((MonsterY[slot] + DeltaY) & 0x3F);
    if (MonsterCanEnter(slot, GetMapSquare())) {
        MoveMonsterToTarget(slot);
        return;
    }
    if (DeltaY != 0) {
        LookX = MonsterX[slot];                     /* LookY stays y + dy */
        if (MonsterCanEnter(slot, GetMapSquare())) {
            MoveMonsterToTarget(slot);
            return;
        }
    }
    LookX = (u8)((MonsterX[slot] + DeltaX) & 0x3F);
    LookY = MonsterY[slot];
    if (MonsterCanEnter(slot, GetMapSquare()))
        MoveMonsterToTarget(slot);
}

/* asm: MoveMonsterToTarget @2201 returns: MonsterStep_Done TownTurnNextMonster OutdoorMonsters_Next
 *
 * Moves the monster to LookX/LookY, unless that is the player's square (then it stays). The square
 * it leaves gets back the map byte it stood on (MonsterUnder); it takes the new position,
 * remembers the map byte there and is written into the map. The assembly keeps the new position in
 * AmountHi/AmountLo meanwhile (they are free here; the shops use them for prices). Also jumped to
 * by the town wanderers (EVENTS' TownTurn). */
void MoveMonsterToTarget(u8 slot)
{
    u8 new_x, new_y;            /* asm: AmountHi, AmountLo */

    if (LookX == PlayerX && LookY == PlayerY)
        return;
    new_x = LookX;
    new_y = LookY;
    LookX = MonsterX[slot];
    LookY = MonsterY[slot];
    GetMapSquare();                                 /* MapCellPtr -> the square it leaves */
    *MapCellPtr = MonsterUnder[slot];
    LookX = MonsterX[slot] = new_x;
    LookY = MonsterY[slot] = new_y;
    MonsterUnder[slot] = GetMapSquare();
    *MapCellPtr = MonsterTile[slot];
}

/* ---- Two ends ------------------------------------------------------------------------------- */

/* asm: IllegalCommand @2275 -- a key that is no command (MAIN's DispatchCommand); the turn ends
 * with the error beep (EndCommandBeep). */
void IllegalCommand(void)
{
    PrintInline("-ILLEGAL COMMAND!");
    Beep();
}

/* asm: DieOfStarvation @228D -- the food has run out (MAIN's EndTurn, MOVE): the player dies. */
void DieOfStarvation(void)
{
    PlayerDies();
}
