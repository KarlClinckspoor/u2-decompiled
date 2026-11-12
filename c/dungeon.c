/* dungeon.c -- DUNGEON.ASM (original addresses 26F9-2B65) read as C: the time door's walk, the
 * command loop underground, and the helm's map.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/DUNGEON.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine, that it prints
 * the same texts and that it calls the same routines at least as often, and that the table
 * matches byte for byte. It cannot check the logic.
 *
 * Three pieces that only happen to sit together:
 *   - MoveTimeDoor: every 8 surface turns on Earth the time door moves to the next of four places
 *     of the present era (TimeDoorTbl); MOVE's EnterTimeDoor uses the same table;
 *   - DungeonLoop: one command in a tower or dungeon. MAIN's loop calls it instead of reading the
 *     key itself, and ends the turn afterwards (EndCommand), so every `jmp EndCommand` here is a
 *     return; the arrow keys walk and turn, any other key goes to the letter commands;
 *   - DrawHelmMap: the whole map as a picture, for V)iew with the magic helm.
 *
 * Underground the player has a facing, FacingDX/FacingDY (each 0, 1 or FFh = -1; one of them 0),
 * and the 3D view (VIEW3D) leaves the dungeon cells ahead and behind in TileNorth and TileSouth.
 *
 * See shops.c for the conventions shared by all the C files.
 */

#include "u2.h"

/* ---- The time door -------------------------------------------------------------------------- */

/* asm: TimeDoorTbl @2798 -- where the time door can stand: four x,y pairs per era (8 bytes a row,
 * TimeZone 0-4); TimeDoorSpot (0, 2, 4, 6) is the offset of the pair in the row. Era 0's four
 * places sit side by side near the bottom of the map. */
const u8 TimeDoorTbl[] = {
    0x1D, 0x38, 0x1F, 0x38, 0x21, 0x38, 0x23, 0x38,     /* era 0 */
    0x22, 0x08, 0x2F, 0x1C, 0x24, 0x38, 0x14, 0x25,     /* era 1 */
    0x10, 0x10, 0x30, 0x18, 0x2A, 0x18, 0x13, 0x34,     /* era 2 */
    0x38, 0x34, 0x1C, 0x0C, 0x21, 0x17, 0x14, 0x34,     /* era 3 */
    0x12, 0x17, 0x32, 0x22, 0x34, 0x18, 0x08, 0x0B      /* era 4 */
};

/* asm: MoveTimeDoor @26F9
 *
 * Once per surface turn (MAIN's EndTurn), on Earth only. A counter (TimeDoorTimer) runs down 8
 * turns; then the door (map byte C0h) at its present place gets back the terrain it covered
 * (TimeDoorUnder), if the door is still there, and TimeDoorSpot moves to the next place, round
 * the four. If the map byte there is plain terrain (below 14h: water, marsh, grass, woods,
 * mountains; but not a monster, a town...), it is remembered and the door is put on it;
 * otherwise there is no door for these 8 turns. The player is not in the map (the map keeps the
 * terrain under him), so the door can appear under his feet.
 * (The assembly returns the new door's x and y in AL and DI, which MAIN ignores.) */
void MoveTimeDoor(void)
{
    u8 row;                     /* asm: Temp1F: the era's row of TimeDoorTbl, TimeZone * 8 */
    u8 i;
    u8 sq;

    if (Planet != 0)
        return;
    if (--TimeDoorTimer != 0)
        return;

    /* TimeDoor_Remove */
    row = (u8)(TimeZone * 8);
    i = (u8)(row + TimeDoorSpot);
    LookX = TimeDoorTbl[i];
    LookY = TimeDoorTbl[i + 1];
    if (GetMapSquare() == 0xC0)                     /* still a door there (EnterTimeDoor removes it) */
        *MapCellPtr = TimeDoorUnder;

    /* TimeDoor_NextSpot */
    TimeDoorTimer = 8;
    TimeDoorSpot = (u8)((TimeDoorSpot + 2) & 7);
    i = (u8)(TimeDoorSpot + row);
    LookX = TimeDoorTbl[i];
    LookY = TimeDoorTbl[i + 1];
    sq = GetMapSquare();
    if (sq >= 0x14)
        return;
    TimeDoorUnder = sq;
    *MapCellPtr = 0xC0;
}

/* ---- One command underground ---------------------------------------------------------------- */

/* asm: DungeonAdvance @2861
 *
 * ADVANCE: refused ("-BLOCKED!", and the error beep) when the cell ahead has any of its low four
 * bits set or is exactly 80h; otherwise one step along the facing, wrapping at 64. Then a random
 * byte below the level number springs a trap (so never on level 0, and more often deeper): the
 * view goes dark, the torch is out (LightTurns 0), and without tools the player dies; with them
 * one tool is used up. */
static void DungeonAdvance(void)
{
    PrintInline("ADVANCE");
    if ((TileNorth & 0x0F) != 0 || TileNorth == 0x80) {
        PrintInline("-BLOCKED!");                   /* asm: Advance_Blocked */
        Beep();
        return;
    }
    PlayerX = (u8)((PlayerX + FacingDX) & 0x3F);
    PlayerY = (u8)((PlayerY + FacingDY) & 0x3F);
    if (Random() >= DungeonLevel)
        return;

    /* Advance_Trap */
    ClearViewArea();
    LightTurns = 0;
    PrintInline("\nARGH! A TRAP!\n");
    PlayTrapSound();
    PlayHurtSound();
    PlayHurtSound();
    PlayHurtSound();
    PlayHurtSound();
    if (Tools == 0) {
        PlayerDies();                               /* does not return */
        return;
    }
    PrintInline("ESCAPED! BY USE OF TOOLS!");
    Tools = bcd_sub(Tools, 1);
}

/* asm: DungeonTurnLeft @2912 -- TURN LEFT: the facing turns a quarter anticlockwise,
 * (dx, dy) -> (dy, -dx). North (0, -1) becomes west (-1, 0). */
static void DungeonTurnLeft(void)
{
    PrintInline("TURN LEFT");
    if (FacingDY != 0) {
        FacingDX = FacingDY;
        FacingDY = 0;
    } else {
        FacingDY = (u8)(0 - FacingDX);
        FacingDX = 0;
    }
}

/* asm: DungeonTurnRight @2944 -- TURN RIGHT: (dx, dy) -> (-dy, dx). East (1, 0) becomes
 * south (0, 1). */
static void DungeonTurnRight(void)
{
    PrintInline("TURN RIGHT");
    if (FacingDX != 0) {
        FacingDY = FacingDX;
        FacingDX = 0;
    } else {
        FacingDX = (u8)(0 - FacingDY);
        FacingDY = 0;
    }
}

/* asm: DungeonRetreat @2977 -- RETREAT: one step back against the facing, wrapping at 64. The test
 * of the cell behind is stricter than ADVANCE's (bit 7 or any of the low four bits refuses), and
 * there is no trap. */
static void DungeonRetreat(void)
{
    PrintInline("RETREAT");
    if ((TileSouth & 0x8F) != 0) {
        PrintInline("-BLOCKED!");
        Beep();
        return;
    }
    PlayerX = (u8)((PlayerX - FacingDX) & 0x3F);
    PlayerY = (u8)((PlayerY - FacingDY) & 0x3F);
}

/* asm: DungeonPass @29BC -- the space bar. (Unlike the surface's pass it costs no food here: the
 * dungeon turn eats.) */
static void DungeonPass(void)
{
    PrintInline("PASS");
}

/* asm: DungeonLoop @27C0
 *
 * One command in a tower or dungeon; MAIN's loop then ends the turn. Asleep: "CMD: ", 20 Z's
 * slowly, one turn of sleep less. Awake: "CMD: " and a wait for a key; with none it passes
 * ("PASS"). BUG, as in the original: the wait counts its inner loop in the 16-bit DI where the
 * 6502 had the 8-bit Y, so the first round is 255 polls and the second 65536, not the 2 x 256
 * meant. The keys: north (up arrow) ADVANCE, west TURN LEFT, east TURN RIGHT, south RETREAT,
 * space PASS, anything else a letter command (DispatchCommand: A-Z, or "-ILLEGAL COMMAND!"). */
void DungeonLoop(void)
{
    u16 inner;                  /* asm: DI */
    u8 rounds;                  /* asm: SI */
    u16 d;
    u16 key;
    u8 k;

    if (SleepTurns != 0) {
        PrintInline("CMD: ");
        for (AmountHi = 20; AmountHi != 0; AmountHi--) {
            PrintInline("Z");
            d = 0xFF;
            do { } while (--d != 0);                /* a short busy loop, CPU-speed dependent */
        }
        SleepTurns--;
        return;
    }

    /* Dungeon_ReadCmd */
    PrintInline("CMD: ");
    inner = 0xFF;
    rounds = 2;
    for (;;) {
        SpeedDelay(0);
        key = ReadKey();
        if ((key >> 8) == 0xFF)
            break;
        /* (six push ax / pop ax pairs: a little more delay) */
        if (--inner != 0) continue;
        if (--rounds != 0) continue;
        PrintInline("PASS");
        return;
    }

    /* Dungeon_GotKey */
    k = (u8)key;
    if (k == KeyNorth)      DungeonAdvance();
    else if (k == KeyWest)  DungeonTurnLeft();
    else if (k == KeyEast)  DungeonTurnRight();
    else if (k == KeySouth) DungeonRetreat();
    else if (k == ' ')      DungeonPass();
    else                    DispatchCommand(k);
}

/* ---- The helm's map ------------------------------------------------------------------------- */

/* The picture's origin, two bytes in the code segment (HelmOriginX/HelmOriginY @29D0). Always 0:
 * DrawHelmMap clears them and nothing else writes them (a left-over of a scrolling view?). */
static u8 HelmOriginX, HelmOriginY;

/* asm: DrawHelmMap @29D2
 *
 * V)iew with the magic helm (CMDMZ): the whole 64x64 map, from its corner (0,0) since the origin is
 * always 0, as a 256x128-pixel picture with 4x2 pixels a square. While it draws, DeltaX and DeltaY
 * hold the square's column and row (PlotOverviewDot reads them). The patterns, as (column 0-3,
 * row 0-1) dots of the cell:
 *     water (0)                  nothing
 *     grass (8)                  (1,0) (3,1)
 *     woods (0Ch)                (1,1) (3,0) and grass's: columns 1 and 3
 *     mountains (10h), 78h-EFh   all eight (the people and monsters of a town are solid)
 *     marsh (4)                  (1,0) (3,0)
 *     town floor (70h)           columns 0 and 2
 *     anything else              the 2x2 square in the middle (towns, signs...)
 * The assembly reaches the solid pattern's last four dots by falling into woods and then grass. */
void DrawHelmMap(void)
{
    u8 sq;

    HelmOriginX = 0;
    HelmOriginY = 0;
    DeltaX = 0;
    DeltaY = 0;
    ClearViewArea();
    do {
        LookX = (u8)((HelmOriginX + DeltaX) & 0x3F);
        LookY = (u8)((HelmOriginY + DeltaY) & 0x3F);
        sq = GetMapSquare();
        if (sq == 0) {
            /* water: nothing */
        } else if (sq == 0x10 || (sq >= 0x78 && sq < 0xF0) || sq == 0x0C || sq == 8) {
            if (sq != 0x0C && sq != 8) {            /* asm: HelmMap_Solid */
                PlotOverviewDot(0, 0);
                PlotOverviewDot(0, 1);
                PlotOverviewDot(2, 1);
                PlotOverviewDot(2, 0);
            }
            if (sq != 8) {                          /* asm: HelmMap_Woods */
                PlotOverviewDot(1, 1);
                PlotOverviewDot(3, 0);
            }
            PlotOverviewDot(1, 0);                  /* asm: HelmMap_Grass */
            PlotOverviewDot(3, 1);
        } else if (sq == 4) {                       /* asm: HelmMap_Marsh */
            PlotOverviewDot(1, 0);
            PlotOverviewDot(3, 0);
        } else if (sq == 0x70) {                    /* asm: HelmMap_TownFloor */
            PlotOverviewDot(0, 0);
            PlotOverviewDot(0, 1);
            PlotOverviewDot(2, 0);
            PlotOverviewDot(2, 1);
        } else {                                    /* asm: HelmMap_Other */
            PlotOverviewDot(1, 0);
            PlotOverviewDot(2, 0);
            PlotOverviewDot(2, 1);
            PlotOverviewDot(1, 1);
        }
        /* HelmMap_Next: x runs 0-3Fh along a row, then the next row */
        DeltaX = (u8)((DeltaX + 1) & 0x3F);
        if (DeltaX == 0)
            DeltaY++;
    } while (DeltaY < 0x40);
}
