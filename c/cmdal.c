/* cmdal.c -- CMDAL.ASM (original addresses 2B65-3B92) read as C: the commands A to L.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/CMDAL.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine, that it prints
 * the same texts and that it calls the same routines at least as often. It cannot check the logic.
 *
 * Attack, Board, Cast, Descend, Enter, Fire, Get, Hyperspace, Ignite torch, Jump, Klimb and
 * Launch, plus what they share: the fight (damage, loot, the monster's death), the search for
 * the monster in front of you, and the way out of a dungeon. Each handler is reached through the
 * jump table in MAIN, prints its own name and ends the player's turn: here it simply returns for
 * the assembly's `jmp EndCommand`, and calls Beep() before returning for `jmp EndCommandBeep`.
 * Where the assembly names a label inside a routine (Attack_Damage, AttackD_Killed...) that other
 * routines jump to, the C has a function of that name.
 *
 * See shops.c for the conventions shared by all the C files, and cmdmz.c for the names of the
 * strings of NameStrTbl (13h weapons, 1Dh armour, 24h spells, 2Eh items).
 */

#include <string.h>
#include "u2.h"

/* the ladder code, used before it is defined */
void Ladder_LevelInc(void);
void Ladder_LevelDec(void);
void Ladder_ShowLevel(void);
void ExitToSurface(void);
void Launch_Plane(void);

/* ---- The overview map ----------------------------------------------------------------------- */

/* asm: PlotOverviewDot @2B65 -- one dot of a map cell in the overview that DrawHelmMap draws:
 * each of the 64x64 cells is 4x2 pixels; DeltaX and DeltaY hold the cell's column and row here
 * (not a direction). */
void PlotOverviewDot(u8 dot_col, u8 dot_row)
{
    PlotX = (u8)(DeltaX * 4 + dot_col);
    PlotY = (u8)(DeltaY * 2 + dot_row);
    PlotPixel();
}

/* ---- A: Attack ------------------------------------------------------------------------------ */

/* asm: Attack_Miss @2E09 -- also used by CmdFire. */
void Attack_Miss(void)
{
    PrintInline("--MISS");
}

/* asm: Attack_Damage @2C19 -- the monster in slot `who` takes `damage` hit points (also from
 * CmdFire). It dies only if the damage is MORE than its hit points: a monster hit down to exactly
 * 0 stays alive. When it dies, whatever it carried falls to the player, then gold and experience.
 *   guard (60h)    2 keys
 *   thief (FCh)    a tool one time in 4, and a random item 1-15 (15 times in 16)
 *   fighter (F0h)  a magical helm one time in 4, and 1-4 torches
 *   wizard (F8h)   a wand or a staff
 *   Minax (40h)    nothing: killing her is the end of the game (MinaxDead)
 * A Minax who survives a hit teleports: (x, y) becomes (y, x). */
void Attack_Damage(u8 who, u8 damage)
{
    u8 kind;
    u8 item;
    u8 gold;
    u8 exp;
    int cf;

    if (MonsterHP[who] >= damage) {                 /* survives, even at exactly 0 */
        MonsterHP[who] = (u8)(MonsterHP[who] - damage);
        XorAttackMark();                            /* erase the hit marker */
        if (MonsterTile[who] == 0x40) {
            InvertViewArea();                       /* a flash */
            PlayWarpSound();
            InvertViewArea();
            LookX = MonsterX[who];
            LookY = MonsterY[who];
            GetMapSquare();
            *MapCellPtr = MonsterUnder[who];        /* the tile under her goes back */
            MonsterY[who] = LookX;                  /* (x, y) -> (y, x) */
            MonsterX[who] = LookY;
            LookX = MonsterX[who];
            LookY = MonsterY[who];
            GetMapSquare();
            *MapCellPtr = MonsterTile[who];         /* her tile at the new place; MonsterUnder is not updated */
            MonsterMood[who] = 0x84;
            PrintInline("\nSHE'S GONE!!!");
        }
        return;
    }

    /* killed: the tile under it goes back on the map */
    LookX = MonsterX[who];
    LookY = MonsterY[who];
    GetMapSquare();
    *MapCellPtr = MonsterUnder[who];

    kind = MonsterTile[who];
    if (kind == 0x40) {
        MinaxDead();
        return;
    }
    if (kind == 0x60) {
        Keys = bcd_add(Keys, 2);
    } else if (kind == 0xFC) {
        if (Random() < 0x40)
            Tools = bcd_add(Tools, 1);
        item = Random() & 0x0F;
        if (item != 0)
            ItemCounts[item] = bcd_add(ItemCounts[item], 1);
    } else if (kind == 0xF0) {
        if (Random() < 0x40)
            Helms = bcd_add(Helms, 1);
        Torches = bcd_add(Torches, (u8)((Random() & 3) + 1));
    } else if (kind == 0xF8) {
        item = (u8)((Random() & 1) + 1);            /* item 1 or 2: wand or staff */
        ItemCounts[item] = bcd_add(ItemCounts[item], 1);
    }

    /* the monster's record is cleared, then gold 1-17 (BCD, odd) and experience 1-4 */
    MonsterUnder[who] = 0;
    MonsterHP[who] = 0;
    MonsterX[who] = 0;
    MonsterY[who] = 0;
    MonsterTile[who] = 0;
    PrintInline("\nKILLED--GOLD+");
    gold = (u8)((Random() & 0x17) | 1);
    PrintBcdByte(gold);
    cf = 0;
    GoldLo = bcd_adc(GoldLo, gold, &cf);            /* the carry goes on into the hundreds */
    GoldHi = bcd_adc(GoldHi, 0, &cf);
    PrintInline("--EXP.+");
    exp = (u8)((Random() & 3) + 1);
    PrintBcdByte(exp);
    cf = 0;
    ExpLo = bcd_adc(ExpLo, exp, &cf);
    ExpHi = bcd_adc(ExpHi, 0, &cf);
    XorAttackMark();
}

/* asm: AttackD_Miss @2F64 */
void AttackD_Miss(void)
{
    PrintInline("MISS");
}

/* asm: AttackD_Killed @2ED1 -- a dungeon monster dies (also from CmdCast: prayer, magic missile,
 * kill). Its hit points, tile and level are cleared (but not its position), the monster bits of its
 * cell are cleared, then gold 1-17 (BCD, odd) and experience 0-7. */
void AttackD_Killed(u8 who)
{
    u8 gold;
    u8 exp;
    int cf;

    MonsterHP[who] = 0;
    MonsterTile[who] = 0;
    MonsterUnder[who] = 0;
    LookX = MonsterX[who];
    LookY = MonsterY[who];
    ReadDungeonCell(DungeonLevel);
    *DungeonCellPtr = (u8)(*DungeonCellPtr & 0xF0); /* the low 3 bits of a cell are its monster */
    PrintInline("\nKILLED--GOLD+");
    gold = (u8)((Random() & 0x17) | 1);
    PrintBcdByte(gold);
    cf = 0;
    GoldLo = bcd_adc(GoldLo, gold, &cf);
    GoldHi = bcd_adc(GoldHi, 0, &cf);
    PrintInline("--EXP.+");
    exp = Random() & 7;
    PrintBcdByte(exp);
    cf = 0;
    ExpLo = bcd_adc(ExpLo, exp, &cf);
    ExpHi = bcd_adc(ExpHi, 0, &cf);
}

/* asm: Attack_Dungeon @2E16 -- Attack underground: the square in front of the player. The low 3
 * bits of a dungeon cell say a monster stands there, and the monster is then looked up in the
 * monster table by position and level. The hit roll and the damage are as outdoors. */
void Attack_Dungeon(void)
{
    u8 slot;
    u8 al;
    u8 damage;

    PlaySwingSound();
    LookX = (u8)(PlayerX + FacingDX);
    LookY = (u8)(PlayerY + FacingDY);
    if ((ReadDungeonCell(DungeonLevel) & 7) == 0) {
        AttackD_Miss();
        return;
    }
    /* BUG, as in the original: this search goes down from slot 31 and is meant to stop after
     * slot 1 (the 6502's DEC, LDX, BNE: LDX sets the flags from the slot number). The 8086 code
     * tests AL instead, the last field it compared, so it ends at the first slot whose failing
     * field is 0. In play that is nearly harmless, because the spawn routine gives every free
     * slot a non-zero x, y (odd) and a level (slot / 2); the search then runs down to slot 0.
     * What it never does is look at MonsterTile: a free slot whose random position and level
     * match the square in front is "found" and can be "killed" for gold and experience. */
    slot = 0x1F;
    for (;;) {
        al = MonsterX[slot];
        if (al == LookX) {
            al = MonsterY[slot];
            if (al == LookY) {
                al = MonsterUnder[slot];                /* the dungeon level it is on */
                if (al == DungeonLevel)
                    break;
            }
        }
        slot--;
        if (al == 0) {
            AttackD_Miss();
            return;
        }
    }
    if (!((Random() >> 1) < Agility)) {             /* half a random number below Agility */
        AttackD_Miss();
        return;
    }
    PrintInline("HIT!");
    XorAttackMark();
    PlayHitSound();
    XorAttackMark();
    damage = (u8)((u8)(ReadyWeapon * 8 + Strength) >> 2);   /* as outdoors */
    if (MonsterHP[slot] >= damage) {                /* survives, even at exactly 0 */
        MonsterHP[slot] = (u8)(MonsterHP[slot] - damage);
        return;
    }
    AttackD_Killed(slot);
}

/* asm: CmdAttack @2B8F -- hit the monster next to the player in a direction. Refused while the
 * arms are paralysed. The hit lands if half a random number is below Agility (Agility is BCD
 * but is compared as a plain number). Damage = (weapon * 8 + Strength) / 4, Strength likewise read
 * as a plain number. In a town a hit also turns the guards hostile. Underground: Attack_Dungeon. */
void CmdAttack(void)
{
    u8 who;                     /* asm: Temp20 */
    u8 damage;                  /* asm: Temp1F */

    PrintInline("ATTACK--");
    if (MapType >= 4) {
        Attack_Dungeon();
        return;
    }
    if (ArmsParalyzed != 0) {
        PrintInline("PARALIZED!");
        Beep();
        return;
    }
    if (!ReadDirection()) return;
    PlaySwingSound();
    who = FindMonsterInDir();
    if (who == 0) {
        Attack_Miss();
        return;
    }
    if (!((Random() >> 1) < Agility)) {
        Attack_Miss();
        return;
    }
    XorAttackMark();                                /* draw the hit marker */
    AlertTownGuards();                              /* (does nothing outdoors) */
    PrintInline("--HIT!!!");
    PlayHitSound();
    damage = (u8)((u8)(ReadyWeapon * 8 + Strength) >> 2);
    Attack_Damage(who, damage);
}

/* ---- B: Board ------------------------------------------------------------------------------- */

/* asm: CmdBoard @2F6F -- get on the vehicle standing on the player's square: 22h a horse, 24h a
 * frigate (needs a blue tassle), 26h a plane (needs a skull key), 28h a rocket (needs an ankh).
 * Not underground, and only on foot. The vehicle leaves the map (grass where it stood, water for
 * the frigate) and becomes the player's tile. */
void CmdBoard(void)
{
    PrintInline("BOARD");
    if (MapType >= 4 || PlayerTile < 0x78) {        /* underground, or already riding */
        PrintInline("\nTHINK AGAIN ");
        PrintPlayerName();
        Beep();
        return;
    }
    LookX = PlayerX;
    LookY = PlayerY;
    GetMapSquare();                                 /* only to set MapCellPtr */
    switch (TileHere) {
    case 0x22:
        PrintInline(" HORSE");
        *MapCellPtr = 8;
        PlayerTile = 0x22;
        return;
    case 0x24:
        if (BlueTassles == 0) {
            PrintInline(" SHIP\nTHE CREW OF THIS SHIP\nWILL NOT LET YOU BOARD!");
            Beep();
            return;
        }
        PrintInline(" FRIGATE");
        *MapCellPtr = 0;
        PlayerTile = 0x24;
        return;
    case 0x26:
        if (SkullKeys == 0) {
            PrintInline(" PLANE\nSTRANGE YOU CAN'T GET IN!");
            Beep();
            return;
        }
        PrintInline(" PLANE");
        *MapCellPtr = 8;
        PlayerTile = 0x26;
        return;
    case 0x28:
        PrintInline(" ROCKET");
        if (Ankhs == 0) {
            PrintInline("\nA METALIC VOICE COMMANDS:\nYOU MUST HAVE AN ANKH!");
            Beep();
            return;
        }
        *MapCellPtr = 8;
        PlayerTile = 0x28;
        return;
    default:
        PrintInline(" WHAT?");
        Beep();
        return;
    }
}

/* ---- C: Cast -------------------------------------------------------------------------------- */

/* asm: FindMonsterAhead @330C -- the live monster on this dungeon level at the square in front of
 * the player: its slot (31 down to 1), or 0 if there is none. */
u8 FindMonsterAhead(void)
{
    u8 slot;

    for (slot = 0x1F; slot != 0; slot--) {
        if (MonsterTile[slot] == 0) continue;                       /* an empty slot */
        if (MonsterUnder[slot] != DungeonLevel) continue;           /* on another level */
        if ((u8)(PlayerX + FacingDX) != MonsterX[slot]) continue;
        if ((u8)(PlayerY + FacingDY) != MonsterY[slot]) continue;
        return slot;
    }
    return 0;
}

/* asm: CmdCast @310B -- cast the spell chosen with M)agic. It needs a wand or a staff and a count
 * of that spell, one of which is used up even if the spell then fails; and it works only in a
 * dungeon or tower. The spells:
 *   1 light     the light counter is set as a torch does
 *   2 down      a ladder down: one level deeper in a dungeon, one floor down in a tower
 *   3 up        a ladder up
 *   4 passwall  the wall in front (not on the map's rim) is removed
 *   5 surface   back to the outdoor map
 *   6 prayer    one time in two, the kill spell
 *   7 missile   hits the monster in front for 2 x experience hundreds + 30
 *   8 blink     to a random odd square of this level, if it is empty
 *   9 kill      the monster in front dies
 * Anything that goes wrong is "-FAILED!". */
void CmdCast(void)
{
    u8 who;
    u8 cell;
    u8 x;
    u8 y;
    unsigned sum;
    u8 damage;
    int borrow;
    int extra;

    PrintInline("CAST-");
    PrintNameStr(ReadySpell + 0x24);
    if ((u8)(Wands + Staffs) == 0) {
        PrintInline("\nNEED WAND OR STAFF!");
        PlayFailSound();
        return;
    }
    if (ReadySpell == 0) return;
    if (SpellCounts[ReadySpell] == 0) {
        PrintInline("\nNO SPELL!");
        PlayFailSound();
        return;
    }
    PlaySpellSound();
    SpellCounts[ReadySpell] = bcd_sub(SpellCounts[ReadySpell], 1);
    if (MapType < 4) {                              /* spells work only underground */
        PrintInline("-FAILED!");
        PlayFailSound();
        return;
    }

    switch (ReadySpell) {
    case 1:
        LightTurns = 0x96;
        return;
    case 2:
        if (MapType == 4) goto level_minus;         /* in a tower the floors count upwards */
        goto level_plus;
    case 3:
        if (MapType == 4) goto level_plus;
        goto level_minus;
    case 4:                                         /* passwall: x and y of the cell in front, 1-15 */
        x = (u8)((PlayerX + FacingDX) & 0x0F);
        if (x == 0) goto failed;
        LookX = x;
        y = (u8)((PlayerY + FacingDY) & 0x0F);
        if (y == 0) goto failed;
        LookY = y;
        cell = ReadDungeonCell(DungeonLevel);
        if (!(cell & 0x80)) goto failed;            /* only a wall can be passed */
        *DungeonCellPtr = 0;
        return;
    case 5:
        ExitToSurface();
        return;
    case 6:                                         /* prayer: the kill spell, 50% */
        if (Random() >= 0x80) goto failed;
        goto kill;
    case 7:                                         /* magic missile */
        who = FindMonsterAhead();
        if (who == 0) goto failed;
        /* BUG, as in the original: the 6502 subtract was meant to be SEC / SBC, but the carry
         * flag is left over from the addition, so one more hit point than the damage is taken
         * (unless the sum overflowed). The monster dies if it had no more than that. */
        sum = (unsigned)ExpHi * 2;
        damage = (u8)(sum + 0x1E + (sum > 0xFF));
        extra = !((sum & 0xFF) + 0x1E + (sum > 0xFF) > 0xFF);
        borrow = MonsterHP[who] < damage + extra;
        MonsterHP[who] = (u8)(MonsterHP[who] - damage - extra);
        if (!borrow) return;                        /* it lives */
        AttackD_Killed(who);
        return;
    case 8:                                         /* blink: odd x and y, 1-15 */
        LookX = (u8)((Random() & 0x0F) | 1);
        LookY = (u8)((Random() & 0x0F) | 1);
        if (ReadDungeonCell(DungeonLevel) != 0) goto failed;
        PlayerX = LookX;
        PlayerY = LookY;
        return;
    default:                                        /* 9 and up: kill */
    kill:
        who = FindMonsterAhead();
        if (who == 0) goto failed;
        AttackD_Killed(who);
        return;
    }

level_plus:
    /* BUG, as in the original: the level below is tested for emptiness at LookX/LookY, which are
     * not set here but left over from the 3D view: the square BEHIND the player. Checked in play:
     * the result depends on the way the player faces. */
    if (DungeonLevel >= 0x0F) goto failed;
    if (ReadDungeonCell((u8)(DungeonLevel + 1)) != 0) goto failed;
    DungeonLevel++;
    Ladder_ShowLevel();
    return;

level_minus:
    if (DungeonLevel == 0) {                        /* from the top level: out */
        ExitToSurface();
        return;
    }
    if (ReadDungeonCell((u8)(DungeonLevel - 1)) != 0) goto failed;      /* same leftover square */
    DungeonLevel--;
    Ladder_ShowLevel();
    return;

failed:
    PrintInline("-FAILED!");
    PlayFailSound();
}

/* ---- D: Descend, K: Klimb, and the ladder code they share ------------------------------------ */

/* asm: Ladder_LevelInc @3381 -- one level up the counter: deeper in a dungeon, higher in a tower
 * (also from CmdKlimb in a tower). */
void Ladder_LevelInc(void)
{
    DungeonLevel++;
    Ladder_ShowLevel();
}

/* asm: CmdDescend @334D -- go down a ladder, underground, when the cell under the player has the
 * down-ladder bit (20h): one level deeper in a dungeon, one floor lower in a tower. */
void CmdDescend(void)
{
    PrintInline("DESCEND");
    if ((MapType != 5 && MapType != 4) || (TileHere & 0x20) == 0) {
        PrintInline("-WHAT?");
        Beep();
        return;
    }
    if (MapType != 4)
        Ladder_LevelInc();
    else
        Ladder_LevelDec();
}

/* ---- E: Enter ------------------------------------------------------------------------------- */

/* asm: CmdEnter @3389 unrolled: SaveGame-4 LoadMapAndMonsters-3 LoadTalkFile-2
 *
 * Go into the town, castle, tower or dungeon the player stands on, or read a sign. Only outdoors
 * and on foot. What it is follows the tile underfoot (TileHere / 2): 5 village, 6 town, 7 tower,
 * 8 castle, 9 dungeon, 10 sign. The outdoor position is remembered and everything saved first.
 * Towns and castles start at the bottom middle (1Fh, 3Eh) with their talk file; towers and
 * dungeons at (5, 5) on level 0, facing east. The sign names the era. (The assembly repeats the
 * saving and loading for each kind; here it is written once.) */
void CmdEnter(void)
{
    u8 map_type;

    PrintInline("ENTER");
    if (MapType != 0) {
        PrintInline(" WHAT?");
        return;
    }
    if (PlayerTile < 0x78) {                        /* in a vehicle */
        PrintInline("-ONLY ON FOOT!");
        Beep();
        return;
    }
    switch (TileHere >> 1) {
    case 5:  PrintInline("-VILLAGE"); map_type = 1; break;
    case 6:  PrintInline("-TOWN");    map_type = 2; break;
    case 7:  PrintInline("-TOWER");   map_type = 4; break;
    case 8:  PrintInline("-CASTLE");  map_type = 3; break;
    case 9:  PrintInline("-DUNGEON"); map_type = 5; break;
    case 10:                        /* the sign: era 0 Legends, 1 Pangea, 2 B.C., 3 A.D., 4+ the Aftermath */
        PrintInline("-THE SIGN READS:\n");
        switch (TimeZone) {
        case 0:  PrintInline("ANOS: LEGENDS!");          break;
        case 1:  PrintInline("ANOS: 9,000,000 B.C.");    break;
        case 2:  PrintInline("ANOS: 1423 B.C.");         break;
        case 3:  PrintInline("ANOS: 1990 A.D.");         break;
        default: PrintInline("ANOS: 2112 A.D.");         break;
        }
        return;
    default:
        PrintInline(" WHAT?");
        return;
    }

    SurfaceX = PlayerX;                             /* where to come back to */
    SurfaceY = PlayerY;
    SaveGame();
    if (map_type == 4 || map_type == 5) {           /* tower, dungeon */
        DungeonLevel = 0;
        FacingDY = 0;
        FacingDX = 1;
        PlayerX = 5;
        PlayerY = 5;
        MapType = map_type;
        LoadMapAndMonsters();
    } else {                                        /* village, town, castle */
        PlayerX = 0x1F;
        PlayerY = 0x3E;
        MapType = map_type;
        LoadMapAndMonsters();
        LoadTalkFile();
        OffMapTile = 4;                             /* grass beyond the map's edge */
    }
}

/* ---- F: Fire -------------------------------------------------------------------------------- */

/* asm: CmdFire @35C1 -- fire the frigate's cannons (only on a frigate) at the monster next to the
 * ship in a direction: damage 20h to FFh (a random number with bit 5 set), through Attack_Damage,
 * so even Minax's teleport applies. */
void CmdFire(void)
{
    u8 who;                     /* asm: Temp20 */
    u8 damage;                  /* asm: Temp1F */

    PrintInline("FIRE");
    if (PlayerTile != 0x24) {
        PrintInline(" WHAT?");
        Beep();
        return;
    }
    PrintInline(" DIRECT-");
    if (!ReadDirection()) return;
    PlayAttackSound();
    who = FindMonsterInDir();
    if (who == 0) {
        Attack_Miss();
        return;
    }
    damage = Random() | 0x20;
    XorAttackMark();
    PlayHitSound();
    Attack_Damage(who, damage);
}

/* ---- G: Get --------------------------------------------------------------------------------- */

/* asm: RemoveItemHere @361C -- outside dungeons and towers, the item the player picked up leaves the
 * map: the square becomes 8 (grass or floor). Underground it does nothing. */
void RemoveItemHere(void)
{
    if (MapType >= 4) return;
    LookX = PlayerX;
    LookY = PlayerY;
    GetMapSquare();
    *MapCellPtr = 8;
}

/* asm: CmdGet @363B -- pick up what lies on the square. Outdoors and in towns: tile 2Ah is armour
 * (1-3: cloth, leather, chain; empty one time in 4), tile 2Ch a weapon (1-7, dagger to light sword;
 * empty one time in 8). Underground: tile 40h is a chest, which disappears and holds Tri-lithium on
 * the deepest level (0Fh), otherwise gold (3 times in 4: 2 x level + 0-31, kept to valid BCD by
 * and 77h), otherwise armour on odd levels and a weapon on even ones. */
void CmdGet(void)
{
    u8 r;
    u8 amount;
    int cf;

    PrintInline("GET");
    if (MapType >= 4) {
        if (TileHere != 0x40) {
            PrintInline(" WHAT?");
            return;
        }
        PrintInline(" CHEST!\nIT CONTAINS ");
        LookX = PlayerX;
        LookY = PlayerY;
        ReadDungeonCell(DungeonLevel);
        *DungeonCellPtr = 0;                        /* the chest is gone */
        if (DungeonLevel == 0x0F) {
            PrintInline("TRI-LITHIUM!");
            TriLithium = bcd_add(TriLithium, 1);
            return;
        }
        if (Random() >= 0x40) {                     /* gold */
            PrintInline("GOLD!");
            amount = (u8)(((Random() & 0x1F) + DungeonLevel + DungeonLevel) & 0x77);
            cf = 0;
            GoldLo = bcd_adc(GoldLo, amount, &cf);
            GoldHi = bcd_adc(GoldHi, 0, &cf);
            return;
        }
        if ((DungeonLevel & 1) == 0) {              /* even level: a weapon */
            PrintInline("A ");                      /* printed before " WEAPON": two spaces */
            goto weapon;
        }
        goto armour;                                /* odd level: armour */
    }

    if (TileHere == 0x2A) goto armour;
    if (TileHere == 0x2C) goto weapon;
    PrintInline(" WHAT?");
    return;

weapon:
    PrintInline(" WEAPON");
    RemoveItemHere();
    r = Random() & 7;
    if (r == 0) goto empty;
    WeaponCounts[r] = bcd_add(WeaponCounts[r], 1);
    return;

empty:
    PrintInline(" EMPTY!");
    return;

armour:
    PrintInline(" ARMOUR");
    RemoveItemHere();
    r = Random() & 3;
    if (r == 0) goto empty;
    ArmourCounts[r] = bcd_add(ArmourCounts[r], 1);
}

/* ---- H, I, J: Hyperspace, Ignite torch, Jump ------------------------------------------------ */

/* asm: CmdHyperspace @3782 -- nothing on the ground (in space, H is read by the flight code). */
void CmdHyperspace(void)
{
    PrintInline("HYPER WHAT?");
}

/* asm: CmdIgniteTorch @3794 -- only underground (elsewhere nothing happens): uses up a torch and
 * sets the light counter to 96h. */
void CmdIgniteTorch(void)
{
    PrintInline("IGNITE TORCH");
    if (MapType < 4) return;
    if (Torches == 0) {
        PrintInline("\nNONE OWNED!");
        Beep();
        return;
    }
    Torches = bcd_sub(Torches, 1);
    LightTurns = 0x96;
}

/* asm: CmdJump @37DC -- prints a text, nothing else. */
void CmdJump(void)
{
    PrintInline("JUMP...WHEE...");
}

/* asm: CmdKlimb @37F1 -- go up a ladder, underground, when the cell under the player has the
 * up-ladder bit (10h): one floor higher in a tower, one level up in a dungeon (from the top level
 * out to the surface). */
void CmdKlimb(void)
{
    PrintInline("KLIMB");
    if ((MapType != 5 && MapType != 4) || (TileHere & 0x10) == 0) {
        PrintInline("-WHAT?");                      /* no beep here, unlike CmdDescend */
        return;
    }
    if (MapType != 4)
        Ladder_LevelDec();
    else
        Ladder_LevelInc();
}

/* asm: Ladder_LevelDec @3823 -- one level down the counter; below 0 is the way out. */
void Ladder_LevelDec(void)
{
    DungeonLevel--;
    if (DungeonLevel >= 0x80) {                     /* wrapped below 0 */
        ExitToSurface();
        return;
    }
    Ladder_ShowLevel();
}

/* asm: Ladder_ShowLevel @382A -- "TO LEVEL nn" (the level as two BCD digits, 00-15). Also the end
 * of the ladder spells. */
void Ladder_ShowLevel(void)
{
    PrintInline("\nTO LEVEL ");
    PrintBcdByte(bcd_add(DungeonLevel, 0));         /* binary 0-15 -> BCD 00-15 */
}

/* asm: ExitToSurface @3844 -- leave a dungeon or tower for the outdoor map (from Klimb, Descend and
 * the spells). Back to the remembered outdoor position, both tile caches invalid, the outdoor map
 * and monsters reloaded. Away from Earth the rocket is put back on the map where it stands;
 * on Earth the PLAYER file is written. */
void ExitToSurface(void)
{
    PlayerX = SurfaceX;
    PlayerY = SurfaceY;
    memset(TileCache, 0xFF, sizeof TileCache);
    memset(TileCacheShown, 0xFF, sizeof TileCacheShown);
    MapType = 0;
    LoadMapAndMonsters();
    PlayerX = SurfaceX;
    PlayerY = SurfaceY;
    if (Planet != 0) {
        LookX = RocketX;
        LookY = RocketY;
        GetMapSquare();
        *MapCellPtr = 0x50;                         /* the rocket's map byte */
        return;
    }
    ReadWriteFile(0x28, "PLAYER  ", PlayerRecord, 0x100);   /* DOS block write: save the character */
}

/* ---- L: Launch ------------------------------------------------------------------------------ */

/* asm: Launch_Plane @39FA -- launch the plane (needs a brass button). It then flies by itself,
 * one square a turn in the heading chosen with the direction keys, over any terrain, until L
 * lands it (on grass only). In a town, reaching row 0 or column 0 is the way out. */
void Launch_Plane(void)
{
    u8 dx;                      /* asm: Temp21, the heading */
    u8 dy;                      /* asm: Temp22 */
    u16 key;

    PrintInline("LAUNCH--PLANE");
    if (BrassButtons == 0) {
        PrintInline("\nFUNNY THIS PLANE IS\nMISSING A BRASS BUTTON!");
        Beep();
        return;
    }
    dx = 0;                                         /* north to begin with */
    dy = 0xFF;
    PrintInline("\nCMD: ");
    PlaneFlying = 0xFF;
    for (;;) {
        PlayStepSound();
        SpeedDelay(2);
        key = ReadKey();
        if ((key >> 8) == 0xFF) {                   /* a key was pressed */
            if ((u8)key == KeyNorth) {
                dx = 0;    dy = 0xFF;
                PrintInline("NORTH\nCMD: ");
            } else if ((u8)key == KeySouth) {
                dx = 0;    dy = 1;
                PrintInline("SOUTH\nCMD: ");
            } else if ((u8)key == KeyEast) {
                dx = 1;    dy = 0;
                PrintInline("EAST\nCMD: ");
            } else if ((u8)key == KeyWest) {
                dx = 0xFF; dy = 0;
                PrintInline("WEST\nCMD: ");
            } else if ((u8)key == 'L') {            /* land: only on grass (map byte exactly 8) */
                LookX = PlayerX;
                LookY = PlayerY;
                if (GetMapSquare() == 8) {
                    PrintInline("LAND PLANE.");
                    PlaneFlying = 0;
                    return;
                }
                PrintInline("LAND--NOT HERE!!!!!\nCMD: ");
            }
        }
        PlayerX = (u8)((PlayerX + dx) & 0x3F);      /* one step, wrapping at 64 */
        PlayerY = (u8)((PlayerY + dy) & 0x3F);
        if (MapType != 0 && (PlayerX == 0 || PlayerY == 0)) {
            PlaneFlying = 0;                        /* at a town's edge: back outdoors */
            LeaveToSurface();
            return;
        }
        UpdateMapView();
    }
}

/* asm: CmdLaunch @38B0 -- launch the plane (see Launch_Plane) or the rocket. The rocket needs
 * Tri-lithium (not used up). From the outdoor map of Earth the rocket's position is remembered
 * (RocketX/RocketY, RocketParked) and the game saved; then space flight. Back on a map the landing
 * scrolls by until a key is pressed: grass (map byte 8) is a landing, anything else kills the
 * player. */
void CmdLaunch(void)
{
    if (PlayerTile == 0x26) {
        Launch_Plane();
        return;
    }
    if (PlayerTile != 0x28) {
        PrintInline("LAUNCH WHAT?");
        return;
    }
    PrintInline("LAUNCH--ROCKET");
    if (TriLithium == 0) {
        PrintInline("\nA METALLIC VOICE SAYS:\nSHIP INCAPABLE OF LAUNCH!");
        return;
    }
    PrintInline("\nPREPARE FOR LAUNCH!");
    if (Planet == 0 && MapType == 0) {
        RocketX = PlayerX;                          /* remember where the rocket stood */
        RocketY = PlayerY;
        RocketParked = 1;
        SaveGame();
    }
    SpaceFlight();
    LoadMapAndMonsters();                           /* the map where we came down */
    memset(TileCache, 0xFF, sizeof TileCache);
    memset(TileCacheShown, 0xFF, sizeof TileCacheShown);
    PlayerX = 0;
    PlayerY = 0;
    OffMapTile = 0xFF;
    PrintInline("(PRESS ANY KEY)");
    do {                                            /* the descent: the map scrolls by */
        PlayerY = (u8)((PlayerY + 2) & 0x3F);
        if ((PlayerY & 7) == 0)
            PlayerX = (u8)((PlayerX + 1) & 0x3F);
        UpdateMapView();
        SpeedDelay(0x1C);
    } while ((ReadKey() >> 8) != 0xFF);
    LookX = PlayerX;
    LookY = PlayerY;
    if ((GetMapSquare() & 0x7F) != 8) {             /* not grass: a crash */
        PlayerDies();
        return;
    }
    if (Planet == 0) {
        RocketParked = 0;
    } else {
        RocketX = PlayerX;                          /* away from Earth the landing spot is remembered */
        RocketY = PlayerY;
        RocketParked = 1;
    }
}
