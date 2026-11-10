/* events.c -- EVENTS.ASM (original addresses 0E70-154E) read as C: what monsters do to the player.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/EVENTS.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine, that it prints
 * the same texts and that it calls the same routines at least as often. It cannot check the logic.
 *
 * Four things live here:
 *   - the spells monsters cast on the player (legs, arms, magic missile, sleep), Minax's curse
 *     and the thief's theft;
 *   - the monsters' turn in a village, towne or castle (TownTurn...): each monster acts by its
 *     "mood", a behaviour byte;
 *   - the monsters' turn in a tower or dungeon (DungeonTurn...), which also keeps the torch, the
 *     view and the food;
 *   - the dungeon cell readers and the spawning of dungeon monsters.
 *
 * The town turn ends, like the outdoor one, with MAIN's EndTurn (EndCommand calls it after the
 * routine returns, see main.c). The dungeon turn does NOT use EndTurn: the monsters' blows take
 * their hit points off directly (DungeonMonsterAttack), and the turn ends with the torch and the
 * food. In the assembly's jumps, DungeonTurn_Next and TownTurnNextMonster are "on to the next
 * monster" and here simply a return to the loop.
 *
 * See shops.c for the conventions shared by all the C files.
 */

#include "u2.h"

/* ---- Spells monsters cast on the player ----------------------------------------------------- */

/* asm: SpellParalyzeLegs @0E70 -- a daemon's spell: the screen flashes. Magic boots save the
 * player three times in four; otherwise the legs are paralysed for 0-15 turns (a step is then
 * refused). */
void SpellParalyzeLegs(void)
{
    PrintInline("LEGS PARALIZED!\n");
    InvertViewArea();
    PlaySpellSound();
    InvertViewArea();
    if (Boots != 0 && Random() >= 0x40) {
        PrintInline("SAVED BY MAGICAL BOOTS!\n");
        return;
    }
    LegsParalyzed = Random() & 0x0F;
}

/* asm: SpellParalyzeArms @0EC2 -- a devil's spell: the same for the arms (no attacking), saved
 * three times in four by a magical cloak. */
void SpellParalyzeArms(void)
{
    PrintInline("ARMS PARALIZED!\n");
    InvertViewArea();
    PlaySpellSound();
    InvertViewArea();
    if (Cloaks != 0 && Random() >= 0x40) {
        PrintInline("SAVED BY MAGICAL CLOAK\n");
        return;
    }
    ArmsParalyzed = Random() & 0x0F;
}

/* asm: SpellMagicMissile @0F12 -- a wizard's spell: adds two attacks, two hits and 40h to this
 * turn's damage (MAIN's EndTurn turns those into hit points lost). Nothing saves the player. */
void SpellMagicMissile(void)
{
    PrintInline("MAGIC MISSILE!\n");
    InvertViewArea();
    PlaySpellSound();
    InvertViewArea();
    Temp20 += 2;                                    /* attacks this turn */
    Temp21 += 2;                                    /* hits this turn */
    Temp22 = (u8)(Temp22 + 0x40);                   /* damage */
}

/* asm: SpellSleep @0F48 -- a balron's spell: the player sleeps 0-15 turns (the main loop then
 * lets the turns pass), saved three times in four by a green idol. */
void SpellSleep(void)
{
    PrintInline("SLEEP SPELL!\n");
    InvertViewArea();
    PlaySpellSound();
    InvertViewArea();
    if (GreenIdols != 0 && Random() >= 0x40) {
        PrintInline("SAVED BY IDOL!\n");
        return;
    }
    SleepTurns = Random() & 0x0F;
}

/* asm: MinaxCurse @0F8E -- while Minax is within 3 squares the town loop calls
 * this every turn: a hit mark on the player's square and 100 hit points lost; below zero is death. */
void MinaxCurse(void)
{
    int borrow;

    PrintInline("MINAX CRIES: DIE FOOL!\n");
    DeltaX = 0;                                     /* direction 0,0: the player's own square */
    DeltaY = 0;
    XorAttackMark();
    PlayHurtSound();
    XorAttackMark();
    borrow = 0;
    HitPointsHi = bcd_sbb(HitPointsHi, 1, &borrow);
    if (borrow)
        PlayerDies();
}

/* asm: ThiefStealItem @0FCD -- a thief next to the player: one time in four it picks one of the 16
 * magic items at random and, if the player has any, takes one. */
void ThiefStealItem(void)
{
    u8 item;

    if (Random() >= 0x40) return;
    item = Random() & 0x0F;
    if (ItemCounts[item] == 0) return;
    ItemCounts[item] = bcd_sub(ItemCounts[item], 1);
    PrintInline("A THIEF STOLE SOMETHING!\n");
}

/* ---- The monsters' turn in a village, towne or castle --------------------------------------- */

/* asm: TownTurn_Loop @101C also: @1040 returns: EndTurn
 *
 * Every monster slot from 31 down to 0 acts by its mood (MonsterMood), a behaviour byte:
 *   0, or 80h and up  stays where it is (80h + n: it has a talk string)
 *   1  hostile: it takes its turn as outdoors (MonsterTurn: casts, attacks or approaches)
 *   2  follows the player (steps towards him)
 *   3  and up: wanders
 * A wanderer keeps its step (MonsterStepX/Y); one time in four it picks a new one at random, -1,
 * 0 or +1 in each direction. The square it would step to must be within 4 to 3Bh in both
 * directions, must not share the player's column or his row (the two are tested separately),
 * and must be town floor (70h) or grass (8). After each slot Minax, if she is the monster, curses
 * the player when within 3 squares in both directions. */
void TownTurn(void)
{
    int slot;
    u8 mood;
    u8 x;
    u8 y;
    u8 sq;

    for (slot = 0x1F; slot >= 0; slot--) {
        if (MonsterTile[slot] != 0) {
            mood = MonsterMood[slot];
            if (mood != 0 && mood < 0x80) {
                if (mood >= 3) {                                    /* wanders */
                    DeltaX = MonsterStepX[slot];
                    DeltaY = MonsterStepY[slot];
                    if (Random() < 0x40) {                          /* a new direction */
                        MonsterStepX[slot] = DeltaX = SignOf(Random());
                        MonsterStepY[slot] = DeltaY = SignOf(Random());
                    }
                    x = (u8)((MonsterX[slot] + DeltaX) & 0x3F);
                    LookX = x;
                    if (x >= 4 && x < 0x3C && x != PlayerX) {
                        y = (u8)((MonsterY[slot] + DeltaY) & 0x3F);
                        LookY = y;
                        if (y >= 4 && y < 0x3C && y != PlayerY) {
                            sq = GetMapSquare();
                            if (sq == 0x70 || sq == 8)
                                MoveMonsterToTarget(slot);
                        }
                    }
                } else if (mood == 2) {                             /* follows */
                    DirToPlayer(slot);
                    MonsterStepToward(slot);
                } else {                                            /* 1: hostile */
                    MonsterTurn(slot);
                }
            }
        }
        /* TownTurnNextMonster: Minax curses the player from within 3 squares (x and y) */
        if (MonsterTile[slot] == 0x40
            && AbsOf((u8)(MonsterX[slot] - PlayerX)) < 4
            && AbsOf((u8)(MonsterY[slot] - PlayerY)) < 4)
            MinaxCurse();
    }
}

/* asm: TownTurnVillage @1013 -- three entries into the same code. */
void TownTurnVillage(void)
{
    TownTurn();
}

/* asm: TownTurnTowne @1014 */
void TownTurnTowne(void)
{
    TownTurn();
}

/* asm: TownTurnCastle @1015 */
void TownTurnCastle(void)
{
    TownTurn();
}

/* asm: AlertTownGuards @113A -- in a town (not outdoors) the guards turn hostile: mood 1 for
 * slots 0-7 and for the slot in Temp20, the monster just attacked or robbed. CmdSteal never sets
 * Temp20, so there it is whatever was left in it. */
void AlertTownGuards(void)
{
    int i;

    if (MapType == 0) return;
    for (i = 7; i >= 0; i--)
        MonsterMood[i] = 1;
    MonsterMood[Temp20] = 1;
}

/* ---- The monsters' turn in a tower or dungeon ----------------------------------------------- */

/* asm: DungeonTurnTower @115F returns: MainLoop
 *
 * First new monsters may appear (SpawnDungeonMonsters). Then every live monster in slots 31
 * down to 1 steps one square towards the player, away from him if it has fewer than 0Fh hit
 * points: in x if that is possible, else in y; never onto a wall (80h) or another monster; only a
 * monster on the player's own level moves at all. A step onto the player's square is an attack
 * (DungeonMonsterAttack). At the end: the torch, the 3D view, 0.10 food and the status lines.
 * (The new position is kept in MonsterStepX/Y in the assembly; here in locals.) */
void DungeonTurnTower(void)
{
    u8 slot;
    u8 cell;
    u8 x;
    u8 y;

    SpawnDungeonMonsters();
    for (slot = 0x1F; slot != 0; slot--) {
        if (MonsterTile[slot] == 0) continue;
        DirToPlayerDungeon(slot);
        if (MonsterHP[slot] < 0x0F) {                       /* weak: away from the player */
            DeltaX = (u8)(0 - DeltaX);
            DeltaY = (u8)(0 - DeltaY);
        }

        if (DeltaX != 0) {                                  /* the step in x */
            x = (u8)(DeltaX + MonsterX[slot]);
            y = MonsterY[slot];
            LookX = x;
            LookY = y;
            if (x == PlayerX && y == PlayerY) {
                DungeonMonsterAttack(slot);
                continue;
            }
            cell = ReadCellIfSameLevel(slot);               /* FFh: not on the player's level */
            if (cell == 0 || (cell != 0xFF && (cell & 0x7F) != 0))
                goto check_cell;
        }
        if (DeltaY == 0) continue;                          /* no step possible */
        y = (u8)(DeltaY + MonsterY[slot]);                  /* the step in y */
        x = MonsterX[slot];
        LookY = y;
        LookX = x;
        if (x == PlayerX && y == PlayerY) {
            DungeonMonsterAttack(slot);
            continue;
        }
        cell = ReadCellIfSameLevel(slot);
        if (cell == 0 || (cell != 0xFF && (cell & 0x7F) != 0))
            goto check_cell;
        continue;                                           /* a wall, or another level: blocked */

    check_cell:
        if ((ReadMonsterCell(slot) & 7) != 0) continue;     /* another monster stands there */
        x = LookX;                                          /* the move: the old cell loses the monster bits... */
        y = LookY;
        LookX = MonsterX[slot];
        LookY = MonsterY[slot];
        ReadMonsterCell(slot);
        *DungeonCellPtr = (u8)(*DungeonCellPtr & 0xF0);
        LookX = x;                                          /* ...the new cell gets the monster's kind */
        LookY = y;
        MonsterX[slot] = x;
        MonsterY[slot] = y;
        ReadMonsterCell(slot);
        *DungeonCellPtr = (u8)(*DungeonCellPtr | MonsterTile[slot]);
    }

    /* the end of the turn: the torch */
    if (LightTurns == 0) {
        ClearViewArea();
        PrintInline("IT'S DARK!\n");
    } else {
        LightTurns--;
        if (LightTurns == 0) {
            PrintInline("TORCH BURNED OUT!\n");
            Beep();
        }
    }
    UpdateDungeonView();
    EatFood(0x10);                                          /* 0.10 food per dungeon turn */
    DrawStatusLines();
}

/* asm: DungeonTurnDungeon @115E -- the same code as the tower's. */
void DungeonTurnDungeon(void)
{
    DungeonTurnTower();
}

/* asm: EatFood @12DB -- the food (three BCD bytes, the last in hundredths) drops by `hundredths`
 * (BCD), the borrow passed from byte to byte. Below zero the player starves. */
void EatFood(u8 hundredths)
{
    int borrow = 0;

    Temp20 = hundredths;                            /* (the assembly keeps it in Temp20, scratch) */
    FoodFrac = bcd_sbb(FoodFrac, hundredths, &borrow);
    FoodLo = bcd_sbb(FoodLo, 0, &borrow);
    FoodHi = bcd_sbb(FoodHi, 0, &borrow);
    if (borrow)
        PlayerDies();
}

/* asm: DungeonMonsterAttack @1308 returns: DungeonTurn_Next
 *
 * The dungeon monster in slot `slot` would step onto the player: it attacks. One time in four the
 * monsters of kinds 2, 5 and 7 use a special attack instead of a blow (and the attack counts only
 * if the monster is on the player's level):
 *   2 ghost    blows the torch out
 *   5 gremlin  steals 100 food (the player dies if he has less)
 *   7 balron   "a strong magic": sleep for 0-7 turns, no saving throw
 * A blow (also only from a monster on the player's level) misses half the time (a random number
 * with bit 7 set) and when the low 3 bits of that number are below the armour worn. A hit flashes
 * the screen and costs (random AND 77h) + ((level x 4) AND 77h) hit points, taken as BCD although the
 * sum is a plain binary one. */
void DungeonMonsterAttack(u8 slot)
{
    u8 r;
    u8 damage;
    int borrow;

    if (Random() < 0x40) {                                  /* one time in four: a special attack */
        if (DungeonLevel != MonsterUnder[slot]) return;
        switch (MonsterTile[slot]) {
        case 2:
            if (LightTurns != 0) {
                PrintInline("YOUR TORCH IS BLOWN OUT!\n");
                Beep();
                LightTurns = 0;
            }
            return;
        case 5:
            PrintInline("A GREMLIN STOLE SOME FOOD!\n");
            Beep();
            borrow = 0;
            FoodHi = bcd_sbb(FoodHi, 1, &borrow);
            if (borrow)
                PlayerDies();
            return;
        case 7:
            PrintInline("YOU FEEL A STRONG MAGIC!\n");
            Beep();
            SleepTurns = Random() & 7;
            return;
        default:
            break;                                          /* the others strike a blow */
        }
    }

    if (DungeonLevel != MonsterUnder[slot]) return;
    PlayAttackSound();
    r = Random();
    if (r >= 0x80) return;                                  /* a miss */
    if ((r & 7) < WornArmour) return;                       /* a miss: the armour turned it */
    InvertViewArea();                                       /* a hit: a flash */
    PlayHurtSound();
    InvertViewArea();
    damage = (u8)((Random() & 0x77) + ((DungeonLevel * 4) & 0x77));
    borrow = 0;
    HitPointsLo = bcd_sbb(HitPointsLo, damage, &borrow);
    HitPointsHi = bcd_sbb(HitPointsHi, 0, &borrow);
    if (borrow)
        PlayerDies();
}

/* ---- Reading the dungeon map ---------------------------------------------------------------- */

/* asm: ReadCellIfSameLevel @143C -- the dungeon cell at LookX/LookY on the level of monster
 * `slot`, but only if that is the player's level; otherwise FFh. */
u8 ReadCellIfSameLevel(u8 slot)
{
    if (DungeonLevel != MonsterUnder[slot])
        return 0xFF;
    return ReadMonsterCell(slot);
}

/* asm: ReadMonsterCell @144C -- the same without the level test: the cell on the monster's level. */
u8 ReadMonsterCell(u8 slot)
{
    return ReadDungeonCell(MonsterUnder[slot]);
}

/* asm: ReadDungeonCell @1451 -- the dungeon cell (LookX, LookY) on a level; also sets
 * DungeonCellPtr to its address in the map buffer: 16 levels of 16 x 16 cells, a 256-byte page
 * each. The assembly builds only the low byte of the address from y and x (so the buffer must
 * start on a page boundary), and adds the carry out of y x 16, so a y above 15 gives a cell one too
 * far; callers keep both coordinates to 0-15. */
u8 ReadDungeonCell(u8 level)
{
    u8 low = (u8)(((LookY << 4) & 0xFF) + LookX + ((LookY >> 4) & 1));

    DungeonCellPtr = MapBufPtr + level * 256 + low;
    return *DungeonCellPtr;
}

/* ---- New monsters underground --------------------------------------------------------------- */

/* asm: SpawnDungeonMonsters @147F -- called every dungeon turn: each free slot (31 down to 1) may
 * get a monster. Slot n belongs to level n / 2, so each level has two slots. A candidate gets a
 * random odd x and y (1-15) and its level; the cell must be empty; then a random kind 1-7 (an
 * eighth outcome means none) that is allowed only if 2 (kind - 1) <= level: deeper levels have the
 * worse monsters. Hit points = ((2 x kind + level) x 8) OR 10h. The monster's kind goes into the
 * low bits of the cell. Note that x, y and the level of a free slot are stored BEFORE the checks, so
 * a refused candidate leaves them changed. */
void SpawnDungeonMonsters(void)
{
    u8 slot;
    u8 r;
    u8 kind;

    for (slot = 0x1F; slot != 0; slot--) {
        if (MonsterTile[slot] != 0) continue;
        r = (u8)(((Random() & 7) * 2) | 1);
        MonsterX[slot] = r;
        LookX = r;
        r = (u8)(((Random() & 7) * 2) | 1);
        MonsterY[slot] = r;
        LookY = r;
        MonsterUnder[slot] = (u8)(slot >> 1);               /* the level */
        if (ReadMonsterCell(slot) != 0) continue;           /* the cell is not empty */
        r = Random() & 7;
        if (r == 7) continue;                               /* none */
        if ((u8)(r * 2) > MonsterUnder[slot]) continue;     /* too strong for this level */
        kind = (u8)(r + 1);
        MonsterTile[slot] = kind;
        MonsterHP[slot] = (u8)((((kind * 2) + MonsterUnder[slot]) * 8) | 0x10);
        ReadMonsterCell(slot);
        *DungeonCellPtr = (u8)(*DungeonCellPtr | MonsterTile[slot]);
    }
}

/* asm: DirToPlayerDungeon @152E -- DeltaX, DeltaY = the sign (-1, 0, +1) of the player's x and y
 * minus the monster's: the way to the player underground (no wrap-around). */
void DirToPlayerDungeon(u8 slot)
{
    DeltaX = SignOf((u8)(PlayerX - MonsterX[slot]));
    DeltaY = SignOf((u8)(PlayerY - MonsterY[slot]));
}
