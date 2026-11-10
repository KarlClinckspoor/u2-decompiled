/* shops.c -- SHOPS.ASM (original addresses 154E-2028) read as C.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/SHOPS.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine, that it prints
 * exactly the same texts in the same order, that it calls the same routines, and that the text
 * tables match byte for byte. It cannot check the logic.
 *
 * How the shopkeepers are reached: T)ransact (CMDMZ.ASM) finds a merchant (tile 68h) across a
 * counter and jumps to ShopDispatch, which picks the shop from the map type and the quarter of
 * the map the player stands in. Every shop ends the player's turn; here that is simply
 * "return" (the assembly's `jmp EndCommand`).
 *
 * The same few things happen in every shop, which the assembly spells out each time:
 *     CalcPrice(item)                       price of item n -> AmountHi:AmountLo (BCD)
 *     PrintBcdWord(AmountHi, AmountLo)      show it
 *     ReadAsciiKey() == 'Y'                 ask
 *     PayPrice()                            take the gold; false = too poor (see u2.h)
 *     x = bcd_add(x, n)                     the BCD count goes up and wraps past 99
 * Nothing checks a count for overflow: buy 100 of anything and it is back at 0.
 *
 * Conventions: '\n' in a text is the game's carriage return (8Dh); the assembly's scratch bytes
 * (Temp1F, Temp21, DungeonLevel) are local variables here.
 */

#include "u2.h"

/* ---- Printing the n-th string of a table ---------------------------------------------------- */

/* asm: PrintNth_Skip @1564 -- the loop that PrintTalkString and PrintCsTblString share.
 * Skips n zero bytes, then prints the text up to the next zero. A table therefore starts with a
 * zero byte, so that n = entry + 1 prints entry 0-based. n = 0 would run 65536 zeros past the
 * end, as in the original; callers never pass it. */
static void PrintNthString(const char *p, u16 n)
{
    for (;;) {
        if (*p == 0 && (u16)--n == 0)
            break;
        p++;
    }
    for (p++; *p != 0; p++)
        PutChar((u8)*p);
}

/* asm: PrintTalkString @154E -- the n-th string (1-based) of the town's talk file, which is
 * how townspeople speak. Called by T)ransact with the person's tile minus 80h. */
void PrintTalkString(u8 n)
{
    PrintNthString(TalkBufPtr, n);
}

/* asm: PrintCsTblString @155D -- the same for one of the tables below (the assembly passes the
 * table's address in the word AmountHi). */
static void PrintCsTblString(const char *table, u16 si)
{
    PrintNthString(table, si);
}

/* ---- Which shop? ---------------------------------------------------------------------------- */

void ShopWeapons(void);
void ShopArmour(void);
void ShopPub(void);
void ShopTransport(void);
void ShopOracle(void);
void ShopFood(void);
void ShopWizardSpells(void);
void ShopClericSpells(void);

/* asm: ShopDispatch @1590
 *
 *                 west half (x < 20h)            east half
 *   north (y<20h) towne: weapons | else: oracle  towne: armour    | else: food
 *   south         towne: pub     | else: wizard  towne: transport  | else: cleric
 *
 * "towne" is MapType 2; the other town maps (villages, castles) have the magic shops instead. */
void ShopDispatch(void)
{
    bool towne = (MapType == 2);

    if (PlayerX < 0x20) {
        if (PlayerY < 0x20) {
            if (towne) ShopWeapons(); else ShopOracle();
        } else {
            if (towne) ShopPub();     else ShopWizardSpells();
        }
    } else {
        if (PlayerY < 0x20) {
            if (towne) ShopArmour();    else ShopFood();
        } else {
            if (towne) ShopTransport(); else ShopClericSpells();
        }
    }
}

/* ---- The pub (southwest of a towne) --------------------------------------------------------- */

/* The barkeep's tips, a zero byte and then ten texts, 0-9. Tip 1 is the only one a drink gives. */
/* asm: PubTipTbl @16BC */
static const char PubTipTbl[] =
    "\0"
    "CAUGH...\0"
    "ISN'T THIS A GREAT GAME?\0"
    "HHMMM...\0"
    "SOME FIGHTERS WEAR MAGIC HELMS!\0"
    "AVIATORS USE SKULL KEYS!\0"
    "SAYLORS WEAR BLUE TASSLES!\0"
    "MAGES CARRY WANDS OR STAFFS!\0"
    "GUARDS CARRY KEYS!\0"
    "ANKHS OPEN SPACE!\0"
    "PLANES NEED BRASS BUTTONS!";

/* asm: ShopPub @15E4 -- "1-BUY, 2-TIP". Any other digit leaves. */
void ShopPub(void)
{
    u8 tip;                     /* asm: DungeonLevel, borrowed as a scratch byte */
    u8 choice;

    PrintInline("WELCOME TO THE PUB!\n1-BUY, 2-TIP --- ");
    choice = ReadDigit();

    if (choice == 1) {                              /* a drink: 5 gold */
        AmountLo = 5;
        AmountHi = 0;
        if (!PayPrice()) return;
        PrintInline("HERE, HAVE A STRONG ONE!\n");
        /* BUG, as in the original: a random number is drawn, masked with 3 (apparently to pick
         * one of tips 0-3) and then overwritten with 1. Every drink gives tip 1. */
        Random();
        tip = 1;
    } else if (choice == 2) {                       /* a tip of 0-9 gold */
        PrintInline("TIP HOW MUCH? ");
        tip = ReadDigit();
        AmountLo = tip;
        AmountHi = 0;
        if (!PayPrice()) return;
        /* The tip you hear is the amount plus or minus one (once in 256 times exactly the
         * amount). Anything outside 0-9, which includes 0 - 1 = FFh, becomes tip 0, so tip 9
         * can only be reached by paying 8. */
        tip = (u8)(SignOf(Random()) + tip);
        if (tip >= 10)
            tip = 0;
    } else {
        return;
    }

    PrintInline("THE BARKEEP SAYS:\n");
    PrintCsTblString(PubTipTbl, tip + 1);           /* +1: the table starts with a zero */
}

/* ---- The food stand (northeast of a village or castle) -------------------------------------- */

/* asm: ShopFood @1799 -- 100 food for the price of item 3. */
void ShopFood(void)
{
    PrintInline("THE FOOD HERE COSTS ");
    CalcPrice(3);
    PrintBcdWord(AmountHi, AmountLo);
    PrintInline("\nPER 100, WANT ONE? ");
    if (ReadAsciiKey() != 'Y') {
        PrintInline("NO");
        return;
    }
    PrintInline("YES,\nNO ONIONS AND TO GO PLEASE!\n");
    if (!PayPrice()) return;
    FoodHi = bcd_add(FoodHi, 1);                    /* +100 food (hundreds digit pair) */
    PrintInline("THANK YOU, COME AGAIN!");
}

/* ---- The magic shops (south of a village or castle) ----------------------------------------- */

/* asm: ShopClericSpells @1841 -- clerics only. Spells 1-6 (light, down ladder, up ladder,
 * passwall, surface, prayer), five at a time, at the price of item n. Any other digit leaves. */
void ShopClericSpells(void)
{
    u8 spell;                   /* asm: Temp1F */

    if (PlayerClass != 1) {
        PrintPlayerName();
        PrintInline(" YOU ARE NOT A CLERIC!");
        return;
    }
    PrintInline("WELCOME ");
    if (PlayerSex != 1)
        PrintInline("BROTHER ");
    else
        PrintInline("SISTER ");
    PrintPlayerName();
    PrintInline("\n1-LIGHT, 2-L.D., 3-L.U.,\n4-PASS 5-SURFACE, 6-PRAYER.\nYOUR INTEREST? ");

    spell = ReadDigit();
    if (spell == 0 || spell >= 7) {
        PrintInline("FOLLOW THE LIGHT, FRIEND!");
        return;
    }
    PrintInline("FIVE ");
    PrintNameStr(spell + 0x24);                     /* spell names start at string 24h */
    PrintInline("S FOR ");
    CalcPrice(spell);
    PrintBcdWord(AmountHi, AmountLo);
    PrintInline("\nYES, FRIEND? ");
    if (ReadAsciiKey() != 'Y') {
        PrintInline("NO\nI'M SORRY, GOOD DAY.");
        return;
    }
    PrintInline("YES,\nI WILL TAKE 5!");
    if (!PayPrice()) return;
    SpellCounts[spell] = bcd_add(SpellCounts[spell], 5);
}

/* asm: ShopWizardSpells @19AF -- the twin of the cleric's shop, for wizards, with Turkish
 * patter. Menu 1-6 sells spells 1, 2, 3, 7, 8, 9 (light, down ladder, up ladder, magic missile,
 * blink, kill). */
void ShopWizardSpells(void)
{
    u8 choice;
    u8 spell;                   /* asm: Temp1F */

    PrintPlayerName();
    if (PlayerClass != 2) {
        PrintInline(" YOU ARE NOT A WIZARD!");
        return;
    }
    PrintInline(" MUSERREF OLDUM!\n1-LIGHT, 2-L.D., 3-L.U.,\n4-M.M., 5-BLINK, 6-KILL,\nBIR IKI UC...? ");

    choice = ReadDigit();
    if (choice == 0 || choice >= 7) {
leave:
        PrintInline("\nUGURLA OLSUN!");
        return;
    }
    spell = (choice < 4) ? choice : (u8)(choice + 3);   /* menu 4-6 are spells 7-9 */
    PrintInline("FIVE ");
    PrintNameStr(spell + 0x24);
    PrintInline("S FOR ");
    CalcPrice(spell);
    PrintBcdWord(AmountHi, AmountLo);
    PrintInline("\nLUTFEN EVET? ");
    if (ReadAsciiKey() != 'Y') {
        PrintInline("NO!");
        goto leave;                                 /* says goodbye too */
    }
    PrintInline("YES\n");
    if (!PayPrice()) return;
    SpellCounts[spell] = bcd_add(SpellCounts[spell], 5);
    PrintInline("GULE GULE!");
}

/* ---- The oracle (northwest of a village or castle) ------------------------------------------ */

/* The oracle's verses, a zero byte and then ten, 0-9. Each is two lines. */
/* asm: OracleVerseTbl @1B6A */
static const char OracleVerseTbl[] =
    "\0"
    "ASK ME NO QUESTIONS,\nI'LL TELL YOU NO LIES.\0"
    "THE QUEEN IS THE KING\nAND THE KING IS A SPY.\0"
    "THE EVIL MEN DO\nIS A HORRIBLE THING.\0"
    "BUT DISPELLING MEANS\nTHAT YOU MUST HAVE THE RING.\0"
    "JUST WHERE IT IS,\nI CANNOT SAY.\0"
    "BUT I'LL TELL YOU RIGHT NOW,\nTHERE IS NO OTHER WAY.\0"
    "I HEAR IN A TOWN\nWHERE THE WATER RUNS FREE.\0"
    "THERE IS AN OLD MAN\nLIVING UNDER A TREE.\0"
    "HE HAS NOT A NAME\nBUT HE DOES HAVE A CLUE\0"
    "MAYHAPS IF YOU FIND HIM,\nHE'LL TELL IT TO YOU!";

/* asm: ShopOracle @1AE0 -- pay n hundred gold (one digit, 0 is free) and hear verse n. */
void ShopOracle(void)
{
    u8 hundreds;                /* asm: Temp1F */

    /* There is no line break after "BUYS!" in the original's text. */
    PrintInline("TIME AND TRAVEL MADE ME WISE,\nPRECIOUS GOLD, A CLUE IT BUYS!HOW MUCH WILL YOU PAY *100?");
    hundreds = ReadDigit();
    AmountHi = hundreds;                            /* the digit already is BCD hundreds */
    AmountLo = 0;
    if (!PayPrice()) return;
    PrintCsTblString(OracleVerseTbl, hundreds + 1);
}

/* ---- The armour and weapon shoppes (northeast and northwest of a towne) --------------------- */

/* asm: ShopArmour @1D1D -- armour 1-6 (cloth, leather, chain, plate, reflect, power) at the
 * price of item 2n, one at a time. Any other digit leaves. */
void ShopArmour(void)
{
    u8 armour;                  /* asm: Temp1F */
    u8 key;                     /* asm: Temp21 */

    PrintInline("     THE ARMOUR SHOPPE:\n1-CLOTH, 2-LEATHER, 3-CHAIN,\n4-PLATE, 5-REFLECT, 6-POWER,\nYOUR INTEREST? ");
    armour = ReadDigit();
    if (armour == 0 || armour >= 7) {
        PrintInline("THANKS FOR COMING BY...");
        return;
    }
    PrintInline("AH! YES! ");
    PrintNameStr(armour + 0x1D);                    /* armour names start at string 1Dh */
    PrintInline("\nFOR YOU ONLY ");
    CalcPrice(armour * 2);
    PrintBcdWord(AmountHi, AmountLo);
    PrintInline("\nHOW 'BOUT IT? ");
    key = ReadAsciiKey();
    PutChar(key);                                   /* echo the answer */
    PutChar('\n');
    if (key != 'Y') {
        PrintInline("OH, WELL.");
        return;
    }
    if (!PayPrice()) return;
    PrintInline("SOLD!");
    ArmourCounts[armour] = bcd_add(ArmourCounts[armour], 1);
}

/* asm: ShopWeapons @1E4F -- the same, for weapons 1-8 (dagger, mace, axe, bow, sword, great
 * sword, light sword, phaser) at the price of item n. 0 and 9 leave: the quick sword (9) is not
 * for sale. */
void ShopWeapons(void)
{
    u8 weapon;                  /* asm: Temp1F */
    u8 key;                     /* asm: Temp21 */

    PrintInline("  THE WEAPONS SHOPPE:\n1-DA, 2-MA, 3-AX, 4-BO,\n5-SW, 6-GR, 7-LI, 8-PH.\nYOUR INTEREST? ");
    weapon = ReadDigit();
    if (weapon == 0 || weapon == 9) {
        PrintInline("THANKS FOR COMING BY...");
        return;
    }
    PrintInline("AH! YES! A ");
    PrintNameStr(weapon + 0x13);                    /* weapon names start at string 13h */
    PrintInline("\nFOR YOU ONLY ");
    CalcPrice(weapon);
    PrintBcdWord(AmountHi, AmountLo);
    PrintInline("\nHOW 'BOUT IT? ");
    key = ReadAsciiKey();
    PutChar(key);
    PutChar('\n');
    if (key != 'Y') {
        PrintInline("OH, WELL.");
        return;
    }
    if (!PayPrice()) return;
    PrintInline("SOLD!");
    WeaponCounts[weapon] = bcd_add(WeaponCounts[weapon], 1);
}

/* ---- The transport shoppe (southeast of a towne) -------------------------------------------- */

/* asm: ShopTransport @1F75 -- sells one thing, a horse, at the price of item 4. */
void ShopTransport(void)
{
    u8 key;

    PrintInline("WELCOME, TO THE TRANSPORT\nSHOPPE. I SELL YOU HORSE ");
    CalcPrice(4);
    PrintBcdWord(AmountHi, AmountLo);
    PrintInline("\nGOLD, DEAL, OK? --- ");
    key = ReadAsciiKey();
    PutChar(key);
    PutChar('\n');
    if (key != 'Y') {
        PrintInline("\nO.K. BYE THEN...");
        return;
    }
    if (!PayPrice()) return;
    PrintInline("\nRIDE SWIFTLY!");
    PlayerTile = 0x22;          /* now on a horse; whatever he rode before is replaced */
}
