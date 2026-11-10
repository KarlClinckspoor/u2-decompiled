/* cmdmz.c -- CMDMZ.ASM (original addresses 3B92-48CD) read as C: the commands M to Z.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/CMDMZ.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine, that it prints
 * the same texts, that it calls the same routines at least as often. It cannot check the logic.
 *
 * Each command is reached through the jump table in MAIN (key letter -> handler), prints its own
 * name and ends the player's turn. Here a handler simply returns for the assembly's
 * `jmp EndCommand`, and calls Beep() before returning for `jmp EndCommandBeep` (the same, after
 * the error beep). The names of weapons, armour, spells, items, attributes, races and classes
 * are strings of one table, NameStrTbl, printed with PrintNameStr(n); the bases are:
 *     13h weapons 0-9    1Dh armour 0-6    24h spells 0-9    2Eh items 0-15
 *     3Eh attributes     44h races         48h classes
 *
 * See shops.c for the conventions shared by all the C files ('\n' is the game's carriage
 * return; scratch bytes such as Temp1F become locals; bugs are written as they behave).
 */

#include <string.h>
#include "u2.h"

/* ---- M: Magic ------------------------------------------------------------------------------- */

/* asm: CmdMagic @3B92 -- choose which spell C)ast will cast (0 none, 1 light ... 9 kill). There
 * is no check that the player owns it; C)ast checks that. */
void CmdMagic(void)
{
    PrintInline("MAGIC SPELL READY #");
    ReadySpell = ReadDigit();
    PrintInline("SPELL READY => ");
    PrintNameStr(ReadySpell + 0x24);
}

/* ---- N: Negate time ------------------------------------------------------------------------- */

/* asm: CmdNegateTime @3BCE -- uses up a strange coin to stop time for 20 turns, during which
 * the monsters do not move. */
void CmdNegateTime(void)
{
    PrintInline("NEGATE TIME");
    if (StrangeCoins == 0) {
        PrintInline(" HOW?\nYOU'RE NOT EINSTEIN");
        return;
    }
    StrangeCoins = bcd_sub(StrangeCoins, 1);
    PrintInline("\nYOU RUB A COIN...");
    TimeStopTurns = 20;
}

/* ---- O: Offer gold -------------------------------------------------------------------------- */

/* asm: CmdOffer @3C2E -- offer n hundred gold (one digit) to the person in a direction, who just
 * says thank you, unless the person has a talk number (MonsterMood >= 80h), the map is a towne
 * (type 2) and the era is 3. Then, by talk number:
 *   81h  500 gold or more buys the quick sword
 *   82h  500 gold or more buys the ring, once T)ransact has set RingEarned
 *   83h  any amount: one more of a random weapon 1-8
 *   else 6 times in 8: one random attribute goes up by 4 x the amount
 * Everything else, and every refusal, ends with the thanks (and the gold is gone). */
void CmdOffer(void)
{
    u8 who;                     /* asm: Temp1F */
    u8 mood;
    u8 which;

    PrintInline("OFFER GOLD DIRECT-");
    if (!ReadDirection()) return;
    who = FindMonsterInDir();
    PutChar('\n');
    if (who == 0) {
        PrintInline("OFFER TO WHOM?");
        return;
    }
    PrintInline("HOW MUCH (*100) ? ");
    AmountHi = ReadDigit();                         /* the digit already is BCD hundreds */
    AmountLo = 0;
    if (!PayPrice()) return;

    mood = MonsterMood[who];
    if (mood >= 0x80 && MapType == 2 && TimeZone == 3) {
        switch (mood) {
        case 0x81:
            if (AmountHi >= 5) {
                PrintInline("ENILNO IS YOURS!");
                QuickSwordCount = 1;
                return;
            }
            break;
        case 0x82:
            if (AmountHi >= 5) {
                if (!RingEarned) {
                    PrintInline("EARN THE RING!");
                    return;
                }
                PrintInline("THE RING IS YOURS!");
                ItemCounts[0] = 1;
                return;
            }
            break;
        case 0x83:
            which = (u8)((Random() & 7) + 1);       /* weapon 1-8 */
            WeaponCounts[which] = bcd_add(WeaponCounts[which], 1);
            PrintInline("HERE TAKE THIS!");
            return;
        default:
            which = Random() & 7;
            if (which < 6) {                        /* attribute 0-5 */
                /* Four BCD additions of the amount in a row WITHOUT clearing the carry between
                 * them (the assembly does adc/daa four times after a single clc). When the
                 * attribute passes 99 the carry leaks into the next addition and the total is
                 * one too many (checked in play: 95 + 4 x 5 became 16). And there is no limit:
                 * past 99 the attribute wraps to 0. */
                int cf = 0;
                u8 a = Attributes[which];
                a = bcd_adc(a, AmountHi, &cf);
                a = bcd_adc(a, AmountHi, &cf);
                a = bcd_adc(a, AmountHi, &cf);
                a = bcd_adc(a, AmountHi, &cf);
                Attributes[which] = a;
                PrintInline("ALAKAZAM!");
                return;
            }
            break;
        }
    }
    PrintInline("THANK YOU VERY MUCH!");
}

/* ---- P: Pass -------------------------------------------------------------------------------- */

/* asm: CmdPass @3DBC */
void CmdPass(void)
{
    PrintInline("PASS");
}

/* ---- Q: Quit and save ----------------------------------------------------------------------- */

/* asm: CmdQuit @3DC7 -- only outdoors, on Earth and on foot. The game goes on afterwards: it
 * does not exit to DOS. */
void CmdQuit(void)
{
    PrintInline("QUIT OR SAVE GAME.");
    if (MapType != 0) {
        PrintInline("\nONLY OUTDOORS!");
        Beep();
        return;
    }
    if (Planet != 0) {
        PrintInline("\nONLY ON EARTH!");
        Beep();
        return;
    }
    if (PlayerTile < 0x78) {                        /* in a vehicle */
        PrintInline("\nONLY ON FOOT!");
        Beep();
        return;
    }
    PrintInline("\nONE MOMENT PLEASE!");
    SaveGame();
}

/* ---- R: Ready weapon ------------------------------------------------------------------------ */

/* asm: CmdReady @3E50 -- 0 hands (always owned), 1 dagger, 2 mace, 3 axe, 4 bow, 5 sword,
 * 6 great sword, 7 light sword, 8 phaser, 9 quick sword. */
void CmdReady(void)
{
    u8 n;                       /* asm: Temp1F */

    PrintInline("READY WEAPON:\n1-DA, 2-MA, 3-AX, 4-BO,\n5-SW, 6-GR, 7-LI, 8-PH.\n9-QU, WHICH? ");
    n = ReadDigit();
    PrintNameStr(n + 0x13);
    if (WeaponCounts[n] == 0 && n != 0) {
        PrintInline(" NOT OWNED!");
        Beep();
        return;
    }
    /* BUG, as in the original: n * 8 is a binary number but Agility is BCD, so the byte compared
     * is the agility's digits read as hex: agility 15 is the byte 15h = 21, which beats the mace's
     * 16. The real limits are 08, 10, 18, 20... (as BCD digits), not 8, 16, 24... Checked in play. */
    if (!((u8)(n * 8) < Agility)) {
        PrintInline(" <-THOU ART NOT \nAGILE ENOUGH TO WIELD!");
        return;
    }
    PrintInline(" READY.");
    ReadyWeapon = n;
}

/* ---- S: Steal ------------------------------------------------------------------------------- */

/* asm: CmdSteal @3F25 -- reach over a shop counter and take something from the shop, if the
 * merchant (tile 68h) behind it does not notice. The shop's quarter of the map decides the loot:
 *   village (type 1), northeast: 100 food
 *   towne (type 2), northeast: one more of a random armour 1-4
 *   towne, northwest: one more of a random weapon 1-8
 * It works with a coin flip for a thief and two for the others, and never while the town is
 * alarmed. Any failure says NO LUCK! and one time in 8 alarms the guards. */
void CmdSteal(void)
{
    enum { NOTHING, FOOD, ARMOUR, WEAPONS } loot = NOTHING;
    u8 square;
    u8 which;

    PrintInline("STEAL DIRECT-");
    if (!ReadDirection()) return;
    LookX = (u8)(PlayerX + DeltaX);
    LookY = (u8)(PlayerY + DeltaY);
    PutChar('\n');

    /* a counter (7Ch or anything from 80h up) with a merchant right behind it? */
    square = GetMapSquare();
    if (square >= 0x80 || square == 0x7C) {
        LookX = (u8)(LookX + DeltaX);
        LookY = (u8)(LookY + DeltaY);
        if (GetMapSquare() == 0x68) {
            /* the coin flips (a negative random number is a miss); the thief skips the first */
            if ((PlayerClass == 3 || Random() < 0x80) && Random() < 0x80 && MonsterMood[0] != 1) {
                if (MapType == 1 && PlayerY < 0x20 && PlayerX >= 0x20)
                    loot = FOOD;
                else if (MapType == 2 && PlayerY < 0x20)
                    loot = (PlayerX >= 0x20) ? ARMOUR : WEAPONS;
            }
        }
    }

    if (loot == NOTHING) {
        PrintInline("NO LUCK!");
        /* BUG, as in the original: AlertTownGuards also makes the monster in slot Temp20
         * hostile, the victim, but Steal never sets Temp20 (it still holds what ReadDirection
         * left there, usually 0). */
        if ((Random() & 7) == 0)
            AlertTownGuards();
        return;
    }
    if (loot == FOOD) {
        PrintInline("STEAL FOOD!");
        FoodHi = bcd_add(FoodHi, 1);
    } else if (loot == ARMOUR) {
        PrintInline("STEAL ARMOUR!");
        which = (u8)((Random() & 3) + 1);           /* armour 1-4: cloth .. plate */
        ArmourCounts[which] = bcd_add(ArmourCounts[which], 1);
    } else {
        PrintInline("STEAL WEAPONS!");
        which = (u8)((Random() & 7) + 1);           /* weapon 1-8: dagger .. phaser */
        WeaponCounts[which] = bcd_add(WeaponCounts[which], 1);
    }
}

/* ---- T: Transact ---------------------------------------------------------------------------- */

/* asm: CmdTransact @4050 -- talk to the person in a direction, or buy from the merchant behind a
 * counter. Outdoors nobody answers. In a town:
 *   nobody there, but a counter with a merchant behind it: that shop (ShopDispatch)
 *   a person with a talk number (MonsterMood = 80h + n): talk string n of the town's talk file,
 *     then a pause; talk string 1 on planet X in a castle also earns the ring (see CmdOffer)
 *   otherwise by the person's kind: the king takes 50 gold and raises your hit points; guard,
 *     jester, merchant, fighter, cleric, wizard and thief each say a line; anyone else does not
 *     answer. */
void CmdTransact(void)
{
    u8 who;                     /* asm: Temp20 (the slot), kept for after the pause */
    u8 kind;
    u8 square;
    u8 raise;
    u16 i;

    PrintInline("TRANSACT-");
    if (!ReadDirection()) return;
    who = FindMonsterInDir();                       /* also sets LookX/LookY */
    PutChar('\n');
    if (MapType == 0) goto no_response;

    if (who == 0) {
        /* nobody: a counter with a merchant behind it (as in CmdSteal) */
        square = GetMapSquare();
        if (square >= 0x80 || square == 0x7C) {
            LookX = (u8)(LookX + DeltaX);
            LookY = (u8)(LookY + DeltaY);
            if (GetMapSquare() == 0x68) {
                ShopDispatch();
                return;
            }
        }
        goto no_response;
    }

    if (MonsterMood[who] >= 0x80) {                 /* someone with something to say */
        PrintTalkString((u8)(MonsterMood[who] - 0x80));
        /* a pause to read it: three times 65535 empty loops and a speed-dependent delay */
        for (i = 3; i != 0; i--) {
            u16 s;
            for (s = 0xFFFF; s != 0; s--) { }
            SpeedDelay(4);
        }
        if (Planet == 9 && MapType == 3 && MonsterMood[who] == 0x81)
            RingEarned = 1;
        return;
    }

    kind = MonsterTile[who];
    if (kind == 0x6C) {                             /* the king */
        PrintInline("WELCOME MY CHILD ");
        PrintPlayerName();
        PrintInline("\nFIRST MY 50 G.P. TRIBUTE!\n");
        AmountLo = 0x50;
        AmountHi = 0;
        if (!PayPrice()) return;
        PrintInline("AND FOR IT I RAISE THEE ");
        /* hit points are HitPointsHi hundreds (BCD): 300 more below 5000, 200 below 7500,
         * 100 below 9900, nothing from 9900 up */
        if (HitPointsHi < 0x50)      raise = 3;
        else if (HitPointsHi < 0x75) raise = 2;
        else if (HitPointsHi < 0x99) raise = 1;
        else                         raise = 0;
        PrintBcdWord(raise, 0);                     /* "0300" */
        HitPointsHi = bcd_add(HitPointsHi, raise);
        return;
    }
    if (kind == 0x60)      PrintInline("A GUARD SAYS:\nPAY YOUR TAXES!");
    else if (kind == 0x64) PrintInline("A JESTER SINGS:\nHO HO HO!");
    else if (kind == 0x68) PrintInline("A MERCHANT SAYS:\nWILL YOU BUY MY APPLES?");
    else if (kind == 0xF0) PrintInline("A FIGHTER SAYS:\nUGH, ME TOUGH!");
    else if (kind == 0xF4) PrintInline("A CLERIC SAYS:\nBELIEVE!");
    else if (kind == 0xF8) PrintInline("A WIZARD SAYS:\nHEX-E-POO-HEX-ON-YOU!");
    else if (kind == 0xFC) PrintInline("A THIEF SAYS:\nPSST, WANNA BUY A WATCH?");
    else goto no_response;
    return;

no_response:
    PrintInline("FUNNY, NO RESPONSE!");
}

/* ---- U: Unlock ------------------------------------------------------------------------------ */

/* asm: CmdUnlock @42F1 -- open the locked door (map code A0h) beside the player with a key. Only
 * east and west are looked at (the maps put every locked door in a north-south wall, so this
 * never matters). The door becomes the tile the player stands on. */
void CmdUnlock(void)
{
    bool door = false;

    PrintInline("UNLOCK DIRECTION-");
    if (!ReadDirection()) return;
    if (DeltaX != 0) {                              /* north and south are ignored */
        LookY = PlayerY;
        LookX = (u8)(PlayerX + DeltaX);
        door = (GetMapSquare() == 0xA0);
    }
    if (!door) {
        PrintInline("\nNO DOOR THERE!");
        Beep();
        return;
    }
    if (Keys == 0) {
        PrintInline("\nNO KEYS THAT FIT!");
        Beep();
        return;
    }
    Keys = bcd_sub(Keys, 1);
    *MapCellPtr = (u8)(TileHere * 2);               /* a map code is twice the tile number */
}

/* ---- V: View -------------------------------------------------------------------------------- */

/* asm: CmdView @437E -- with a magical helm (used up), outdoors or in a town: the whole map
 * from above until a key is pressed. */
void CmdView(void)
{
    if (Helms == 0 || MapType >= 4) {
        PrintInline("VIEW WHAT?");
        return;
    }
    PrintInline("VIEW\nWITH MAGICAL HELM!");
    Helms = bcd_sub(Helms, 1);
    LookX = 0x20;
    LookY = 0x20;
    DrawHelmMap();
    ReadAsciiKey();
    memset(TileCache, 0xFF, sizeof TileCache);      /* both caches "unknown": the normal view is */
    memset(TileCacheShown, 0xFF, sizeof TileCacheShown);   /* drawn again on the next turn */
}

/* ---- W: Wear armour ------------------------------------------------------------------------- */

/* asm: CmdWear @43F3 -- 0 skin (always owned; so are 7-9), 1 cloth, 2 leather, 3 chain, 4 plate,
 * 5 reflect, 6 power. */
void CmdWear(void)
{
    u8 n;                       /* asm: Temp1F */

    PrintInline("WEAR ARMOUR:\n1-CLOTH, 2-LEATHER, 3-CHAIN,\n4-PLATE, 5-REFLECT, 6-POWER,\nWHICH? ");
    n = ReadDigit();
    if (n >= 7) n = 0;
    PrintNameStr(n + 0x1D);
    if (ArmourCounts[n] == 0 && n != 0) {
        PrintInline(" NOT OWNED!");                  /* no beep here, unlike CmdReady */
        return;
    }
    /* BUG, as in the original: the same binary-against-BCD comparison as CmdReady, with Strength.
     * Checked in play. */
    if (!((u8)(n * 8) < Strength)) {
        PrintInline(" <-THOU ART NOT\nSTRONG ENOUGH TO WEAR!");
        return;
    }
    PrintInline(" READY.");
    WornArmour = n;
}

/* ---- X: X-it -------------------------------------------------------------------------------- */

/* asm: CmdXit @44D4 -- get off the horse, frigate, plane or rocket. Only on grass (tile 4), or on
 * water (tile 0) from the frigate. The vehicle is left on the map. */
void CmdXit(void)
{
    PrintInline("X-IT");
    if (PlayerTile >= 0x78) {                       /* on foot already */
        PrintInline(" WHAT?");
        Beep();
        return;
    }
    LookX = PlayerX;
    LookY = PlayerY;
    GetMapSquare();                                 /* only to set MapCellPtr */
    if (TileHere != 4 && !(TileHere == 0 && PlayerTile == 0x24)) {
        PrintInline("-NOT HERE!");
        Beep();
        return;
    }
    *MapCellPtr = (u8)(PlayerTile * 2);             /* the vehicle stays on the map, as a map code */
    PlayerTile = (u8)(0x78 + 2 * PlayerClass);      /* the player's figure on foot */
}

/* ---- Y: Yell -------------------------------------------------------------------------------- */

/* asm: CmdYell @4542 -- echoes what you type, in capitals, until Enter. Nothing else happens. */
void CmdYell(void)
{
    u8 c;

    PrintInline("YELL WHAT?\n");
    for (;;) {
        c = ReadAsciiKey();
        if (c == '\r') break;
        PutChar(c);
    }
    PutChar(c);                                     /* the Enter: a carriage return */
}

/* ---- Z: Ztats ------------------------------------------------------------------------------- */

/* asm: CmdZtats @4568 unrolled: PrintNameStr-5 PutChar-5 PrintBcdByte-5 SetCursor-5
 *
 * The status screen, in 40-column text mode with a one-column margin:
 *     name
 *     A LEVEL nn MALE HUMAN FIGHTER
 *     WEAPON-HANDS                TORCHES-nn
 *       ARMOUR-SKIN                KEYS-nn
 *        SPELL-NONE               TOOLS-nn
 *     the six attributes, scattered (columns and rows below)
 *     WEAPONS: DAGGERS-nn MACES-nn ...     every weapon, armour, spell and item held,
 *     ARMOUR: ...  SPELLS: ...  ITEMS: ...  with its count
 * then waits for a key and goes back to the map. The assembly writes the six attributes out one
 * after the other; here they are a loop over a table of positions. */
void CmdZtats(void)
{
    /* where each attribute goes: column, row (strength .. intelligence) */
    static const u8 place[6][2] = { {1, 6}, {2, 7}, {16, 6}, {15, 7}, {30, 6}, {29, 7} };
    u8 i;

    SetTextMode();
    TextLeftCol = 1;
    CursorCol = 1;
    TextRightCol = 0x26;
    UpdateBiosCursor();

    PrintPlayerName();
    PrintInline("\nA LEVEL ");
    PrintBcdByte(ExpHi);                            /* experience / 100 is the level */
    PutChar(' ');
    PrintSex();
    PutChar(' ');
    PrintNameStr(PlayerRace + 0x44);
    PutChar(' ');
    PrintNameStr(PlayerClass + 0x48);
    PutChar('\n');
    PutChar('\n');

    PrintInline("  WEAPON-");
    PrintNameStr(ReadyWeapon + 0x13);
    SetCursor(29, 3);
    PrintInline("TORCHES-");
    PrintBcdByte(Torches);
    SetCursor(1, 4);
    PrintInline("  ARMOUR-");
    PrintNameStr(WornArmour + 0x1D);
    SetCursor(32, 4);
    PrintInline("KEYS-");
    PrintBcdByte(Keys);
    SetCursor(4, 5);
    PrintInline("SPELL-");
    PrintNameStr(ReadySpell + 0x24);
    SetCursor(31, 5);
    PrintInline("TOOLS-");
    PrintBcdByte(Tools);

    for (i = 0; i < 6; i++) {                       /* the attributes, "NAME-nn" */
        SetCursor(place[i][0], place[i][1]);
        PrintNameStr(0x3E + i);
        PutChar('-');
        PrintBcdByte(Attributes[i]);
    }

    SetCursor(1, 9);
    PrintInline("WEAPONS: ");
    for (i = 1; i < 10; i++) {                      /* "DAGGERS-03 " for each one held */
        if (WeaponCounts[i] != 0) {
            PrintNameStr(i + 0x13);
            PrintInline("S-");
            PrintBcdByte(WeaponCounts[i]);
            PutChar(' ');
        }
    }
    SetCursor(1, 12);
    PrintInline("ARMOUR: ");
    for (i = 1; i < 7; i++) {
        if (ArmourCounts[i] != 0) {
            PrintNameStr(i + 0x1D);
            PrintInline("-");
            PrintBcdByte(ArmourCounts[i]);
            PutChar(' ');
        }
    }
    SetCursor(1, 14);
    PrintInline("SPELLS: ");
    for (i = 1; i < 10; i++) {
        if (SpellCounts[i] != 0) {
            PrintNameStr(i + 0x24);
            PrintInline("S-");
            PrintBcdByte(SpellCounts[i]);
            PutChar(' ');
        }
    }
    SetCursor(1, 18);
    PrintInline("ITEMS: ");
    for (i = 0; i < 16; i++) {
        if (ItemCounts[i] != 0) {
            PrintNameStr(i + 0x2E);
            if (i != 3)                             /* the boots are already plural */
                PrintInline("S");
            PrintInline("-");
            PrintBcdByte(ItemCounts[i]);
            PutChar(' ');
        }
    }

    CursorCol = 0;                                  /* the normal margins again */
    TextLeftCol = 0;
    TextRightCol = 0x28;
    ReadAsciiKey();
    SetGraphicsMode();
    DrawStatusLines();
}
