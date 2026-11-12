/* space.c -- SPACE.ASM (original addresses 6999-7242) read as C: space flight.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/SPACE.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine, that it prints
 * the same texts and that it calls the same routines at least as often, and that the tables match
 * byte for byte. It cannot check the logic.
 *
 * SpaceFlight is called by L)aunch (CmdLaunch) when the rocket lifts off, and returns when the
 * rocket has landed; the caller then loads the map that the file letter, TimeZone and MapType say.
 * In between the screen is a CGA star field seen from the rocket, and the player has the
 * coordinates of a point in a 10x10x10 space (Xeno, Yako, Zabo):
 *   - launching costs 1 fuel (TriLithium, BCD), and runs the hyperwarp to the coordinates of
 *     the planet left; without reflect or power armour (WornArmour 5 or 6) the player explodes
 *     and the game hangs;
 *   - the command loop: the four direction keys only move the centre the stars fly away from
 *     (and the crosshair), H hyperwarps (1 fuel, three digits), L lands;
 *   - after each hyperwarp FindOrbit says where the rocket is: the sun at 4,4,4 (death), a planet
 *     (Earth ... Pluto and planet X, numbered 0-9) or deep space (Planet = 0Ah: landing is denied).
 * Landing sets the file letter ('X' Earth, 'G' the other planets), MapType 0 and TimeZone (Earth: 4;
 * elsewhere the planet's number), which LoadMapAndMonsters turns into MAPX40 or MAPG10-MAPG90.
 *
 * Not translated: the floppy version's "insert disk" prompts at 71CF and 7207, which the 1989
 * patch jumped over (the bytes are still there) and three NOPs at 71F6 and 7230 where a wait
 * for the disk was taken out.
 *
 * See shops.c for the conventions shared by all the C files.
 */

#include "u2.h"

/* ---- Data ----------------------------------------------------------------------------------- */

/* asm: PlanetXenoTbl @7012 -- the planets' Xeno, Yako and Zabo coordinates, indexed by planet number:
 * Earth, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto, planet X. */
static const u8 PlanetXenoTbl[10] = { 6, 5, 3, 6, 1, 2, 9, 4, 0, 9 };

/* asm: PlanetYakoTbl @701C */
static const u8 PlanetYakoTbl[10] = { 6, 4, 3, 2, 3, 8, 4, 0, 1, 9 };

/* asm: PlanetZaboTbl @7026 */
static const u8 PlanetZaboTbl[10] = { 6, 5, 4, 3, 4, 5, 6, 5, 4, 9 };

/* asm: StarStepXTbl @6CAC -- the step of a star in pixels by its distance from the centre / 16: X, 16 entries. */
static const u8 StarStepXTbl[16] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };

/* asm: StarStepYTbl @6CBC -- the same for Y, 8 entries. */
static const u8 StarStepYTbl[8] = { 1, 2, 3, 4, 5, 6, 7, 8 };

/* ---- The star generator --------------------------------------------------------------------- */

/* asm: ResetStarRnd @6D5B -- the star generator's two seeds, 3Bh and 67h, so that the star field
 * repeats the same pattern every time. (They are bytes in the code segment, defined in VIEW3D.) */
static void ResetStarRnd(void)
{
    StarRndSeed = 0x3B;
    StarRndSeed2 = 0x67;
}

/* asm: StarRnd @6D68 -- the star field's own generator (not Random): a two-byte additive sequence,
 * new = StarRndSeed + StarRndSeed2 + 9 (and the carry of the first addition); then StarRndSeed2
 * becomes the old StarRndSeed and StarRndSeed the new value. */
static u8 StarRnd(void)
{
    unsigned s;
    u8 al, old;

    s = (unsigned)StarRndSeed + 9;
    al = (u8)s;
    s = (unsigned)al + StarRndSeed2 + (s > 0xFF);
    al = (u8)s;
    old = StarRndSeed;
    StarRndSeed = al;
    StarRndSeed2 = old;
    return al;
}

/* asm: ScatterStars @6D3E -- the generator reset, then all 64 stars given a place from it: X (0-255)
 * and Y (0-127), from star 63 down to 0. Nothing is drawn. */
static void ScatterStars(void)
{
    int i;

    ResetStarRnd();
    for (i = 0x3F; i >= 0; i--) {
        StarXs[i] = StarRnd();
        StarYs[i] = StarRnd() & 0x7F;
    }
}

/* ---- The crosshair -------------------------------------------------------------------------- */

/* asm: DrawCrosshair @6D83 unrolled: PlotPixel-11
 *
 * The crosshair at LineEndX, LineEndY: a vertical bar from Y-3 to Y+3 and a horizontal one from X-3
 * to X+3 without its centre pixel (the vertical bar has it). */
static void DrawCrosshair(void)
{
    int i;

    PlotX = LineEndX;
    PlotY = (u8)(LineEndY - 3);
    for (i = 0; i < 7; i++) {
        PlotPixel();
        PlotY++;
    }
    PlotX = (u8)(LineEndX - 3);
    PlotY = LineEndY;
    PlotPixel();
    PlotX++;
    PlotPixel();
    PlotX++;
    PlotPixel();
    PlotX += 2;                                     /* skips the centre */
    PlotPixel();
    PlotX++;
    PlotPixel();
    PlotX++;
    PlotPixel();
}

/* asm: EraseCrosshair @6CC4 unrolled: ErasePixel-11 -- the same pixels, erased. */
static void EraseCrosshair(void)
{
    int i;

    PlotX = LineEndX;
    PlotY = (u8)(LineEndY - 3);
    for (i = 0; i < 7; i++) {
        ErasePixel();
        PlotY++;
    }
    PlotX = (u8)(LineEndX - 3);
    PlotY = LineEndY;
    ErasePixel();
    PlotX++;
    ErasePixel();
    PlotX++;
    ErasePixel();
    PlotX += 2;
    ErasePixel();
    PlotX++;
    ErasePixel();
    PlotX++;
    ErasePixel();
}

/* ---- The star field ------------------------------------------------------------------------- */

/* asm: MoveStars @6B3D also: @6C76 @6C8C
 *
 * One frame of the star field: the crosshair is drawn, then each of the 64 stars (X in StarXs, Y
 * in StarYs, the view being 256 x 128 pixels) moves away from the centre LineEndX, LineEndY by
 * a step of (distance / 16) + 1 pixels, per axis (StarStepXTbl, StarStepYTbl): near stars crawl,
 * far ones race. A star that leaves the view (X past 0 or 255, Y below 0 or above 127) is given a
 * new place from StarRnd (X 0-255, Y 0-127) instead. StarMode says what else happens:
 *   0      the old pixel is not erased: the stars leave streaks; the engine tone sweeps
 *   1      erased and redrawn; the tone sweeps
 *   2+     erased and redrawn; random "bleeps" (BleepCountdown runs out, ToggleSpaceBleep)
 * After the 64 stars a frame waits StarMode * 16 rounds of an empty loop (CPU-speed dependent),
 * so a bigger StarMode is a slower flight. The tone sweeps by SpaceToneStep (-1 or +1) per star. */
void MoveStars(void)
{
    int i;
    u8 x, y, new_x, new_y;
    u8 d;
    u16 cx, bx;

    DrawCrosshair();
    for (i = 0; i < 0x40; i++) {
        x = StarXs[i];                              /* asm: StarCurX */
        y = StarYs[i];                              /* asm: StarCurY */

        /* new X: right of (or at) the centre, away to the right; left of it, away to the left */
        if (x >= LineEndX) {
            d = (u8)((u8)(x - LineEndX) >> 4);
            if ((unsigned)x + StarStepXTbl[d] > 0xFF) goto new_star;
            new_x = (u8)(x + StarStepXTbl[d]);
        } else {
            d = (u8)((u8)((x - LineEndX) ^ 0xFF) >> 4);
            if (x < StarStepXTbl[d]) goto new_star;
            new_x = (u8)(x - StarStepXTbl[d]);
        }
        /* new Y: the same; a result outside 0-7Fh (sign bit) is a new star */
        if (y >= LineEndY) {
            d = (u8)((u8)(y - LineEndY) >> 4);
            new_y = (u8)(y + StarStepYTbl[d]);
            if (new_y >= 0x80) goto new_star;
        } else {
            d = (u8)((u8)((y - LineEndY) ^ 0xFF) >> 4);
            new_y = (u8)(y - StarStepYTbl[d]);
            if (new_y >= 0x80) goto new_star;
        }
        goto plot;

new_star:                                           /* asm: MoveStars_NewStar */
        new_x = StarRnd();
        new_y = StarRnd() & 0x7F;

plot:                                               /* asm: MoveStars_Plot */
        StarIndex = (u8)i;
        if (StarMode != 0) {                        /* erase the old pixel (not in mode 0) */
            PlotX = StarXs[i];
            PlotY = StarYs[i];
            ErasePixel();
        }
        PlotX = new_x;
        StarXs[i] = new_x;
        PlotY = new_y;
        StarYs[i] = new_y;
        PlotPixel();

        if (StarMode < 2) {                         /* the engine tone sweeps */
            SpaceToneDivisor = (u16)(SpaceToneDivisor + SpaceToneStep);
            HoldTone(SpaceToneDivisor, 1);
        } else if (--BleepCountdown == 0) {
            ToggleSpaceBleep();
        }
    }

    /* MoveStars_Delay */
    if (StarMode == 0)
        return;
    for (cx = StarMode; cx != 0; cx--) {
        bx = 0x10;
        do { } while (--bx != 0);
    }
}

/* ---- The flight ----------------------------------------------------------------------------- */

/* asm: ShowFuelCoords @6FA3
 *
 * The fuel and Xeno, Yako, Zabo as two digits each at column 37, rows 20-23, next to the labels
 * SpaceFlight printed. Then the right edge of the message window is set to 31 and the cursor goes
 * to column 0 of row 23, the command line. */
static void ShowFuelCoords(void)
{
    TextRightCol = 0x28;
    SetCursor(0x25, 0x14);
    PrintBcdByte(TriLithium);
    SetCursor(0x25, 0x15);
    PrintBcdByte(Xeno);
    SetCursor(0x25, 0x16);
    PrintBcdByte(Yako);
    SetCursor(0x25, 0x17);
    PrintBcdByte(Zabo);
    TextRightCol = 0x1F;
    SetCursor(0, 0x17);
}

/* asm: Space_Die @6A74 -- death in space (the armour, or the sun): the speaker is switched off and
 * the program hangs; the player must reboot. */
static void Space_Die(void)
{
    SpaceSpeakerOff();
    HangForever();
}

/* asm: FindOrbit @7030
 *
 * Where is the rocket? 4,4,4 is the sun: "YOU HIT THE SUN!", the screen is cleared, death. Otherwise
 * the planet table is searched from 9 (planet X) down to 0 (Earth): on a match Planet is its number
 * and "YOU ARE ORBITING <name>." is printed (a chain of compares, not a table); with no match "YOU
 * ARE IN DEEP SPACE." and Planet = 0Ah. */
static void FindOrbit(void)
{
    int i;

    if (Xeno == 4 && Yako == 4 && Zabo == 4) {
        PrintInline("\n\nYOU HIT THE SUN!\n");
        ClearViewArea();
        Space_Die();
        return;
    }
    for (i = 9; i >= 0; i--) {
        if (PlanetXenoTbl[i] == Xeno && PlanetYakoTbl[i] == Yako && PlanetZaboTbl[i] == Zabo)
            break;
    }
    if (i < 0) {
        PrintInline("YOU ARE IN DEEP SPACE.\n");
        Planet = 0x0A;
        return;
    }
    Planet = (u8)i;
    PrintInline("YOU ARE ORBITING ");
    switch (Planet) {
    case 0: PrintInline("EARTH.\n");   break;
    case 1: PrintInline("MERCURY.\n"); break;
    case 2: PrintInline("VENUS.\n");   break;
    case 3: PrintInline("MARS.\n");    break;
    case 4: PrintInline("JUPITER.\n"); break;
    case 5: PrintInline("SATURN.\n");  break;
    case 6: PrintInline("URANUS.\n");  break;
    case 7: PrintInline("NEPTUNE.\n"); break;
    case 8: PrintInline("PLUTO.\n");   break;
    default: PrintInline("X.\n");      break;
    }
}

/* asm: Hyperwarp @6DFD
 *
 * The hyperwarp itself, to the coordinates already in Xeno, Yako, Zabo: "HYPERWARP ENGAGED!" and
 * three phases of star frames (each a MoveStars and a speed delay):
 *   1. 128 frames with StarMode 0: streaks; the speaker on at divisor 2200h, falling by 1 a star
 *      (a rising note);
 *   2. 128 frames with StarMode 1: the new coordinates are shown; the tone rises again;
 *   3. StarMode 2, 4 ... 7Eh: slowing down; random bleeps from now on (the first star toggles the
 *      engine tone off).
 * If the fuel left (TriLithium) has its two low bits set (low digit 3 or 7), "SHIP OFF COURSE!"
 * and the coordinates become random, 0-7 each (from StarRnd). Finally FindOrbit says where the
 * rocket is (and kills the player at the sun). Leaves StarMode 80h and WarpFrames 0. */
static void Hyperwarp(void)
{
    PrintInline("HYPERWARP ENGAGED!\n");

    WarpFrames = 0x80;                              /* phase 1: streaks, pitch rising */
    StarMode = 0;
    ResetStarRnd();
    SpaceToneDivisor = 0x2200;
    SpaceToneStep = 0xFFFF;
    SpaceSpeakerOn(0x2200);
    do {
        MoveStars();
        SpeedDelay(0x16);
    } while (--WarpFrames != 0);

    WarpFrames = 0x80;                              /* phase 2: the new coordinates, pitch falling */
    StarMode = 1;
    ShowFuelCoords();
    ResetStarRnd();
    SpaceToneStep = 1;
    do {
        MoveStars();
        SpeedDelay(0x16);
    } while (--WarpFrames != 0);

    StarMode++;                                     /* phase 3: slowing down */
    BleepCountdown = 1;
    do {
        MoveStars();
        SpeedDelay(0x18);
        StarMode += 2;
    } while (StarMode < 0x80);

    if ((TriLithium & 3) == 3) {                    /* off course */
        PrintInline("SHIP OFF COURSE!\n");
        Xeno = StarRnd() & 7;
        Yako = StarRnd() & 7;
        Zabo = StarRnd() & 7;
    }
    FindOrbit();
}

/* asm: ReadCoordDigit @6F7F -- one digit 0-9 for a coordinate, the stars flying while it waits;
 * other keys are ignored; the digit is echoed. */
static u8 ReadCoordDigit(void)
{
    u16 key;
    u8 k;

    for (;;) {
        MoveStars();
        SpeedDelay(0x14);
        key = ReadKey();
        if ((key >> 8) != 0xFF) continue;
        k = (u8)key;
        if (k >= '0' && k <= '9') break;
    }
    PutChar(k);
    return (u8)(k - '0');
}

/* asm: SpaceCmdHyperwarp @6EC5 returns: SpaceCmdLoop
 *
 * The H command: "NO FUEL!" with none; else 1 fuel, the centre back to the middle, and
 * "HYPERWARP TO:" with the three digits (Xeno, Yako, Zabo). "PREPARE FOR HYPERWARP!": the stars
 * speed up (StarMode down from 80h to 2, a frame each), cruise 64 frames at full speed, and
 * Hyperwarp. Back to the command loop. */
static void SpaceCmdHyperwarp(void)
{
    if (TriLithium == 0) {
        PrintInline("NO FUEL!\n");
        return;
    }
    TriLithium = bcd_sub(TriLithium, 1);
    EraseCrosshair();
    LineEndX = 0x80;
    LineEndY = 0x40;
    PrintInline("HYPERWARP TO:\nXENO=");
    Xeno = ReadCoordDigit();
    PrintInline(" YAKO=");
    Yako = ReadCoordDigit();
    PrintInline(" ZABO=");
    Zabo = ReadCoordDigit();
    PrintInline("\nPREPARE FOR HYPERWARP!\n");
    ResetStarRnd();
    do {                                            /* speed up */
        MoveStars();
        SpeedDelay(0x1A);
        StarMode--;
    } while (StarMode != 2);
    WarpFrames = 0x40;                              /* cruise */
    ResetStarRnd();
    do {
        MoveStars();
        SpeedDelay(0x1A);
    } while (--WarpFrames != 0);
    Hyperwarp();
}

/* asm: SetMapFileLetter @720B -- the letter of the three file names (MAP, MON, TLK), 'X' Earth, 'G' the
 * others: bytes in LOAD's inline names (FcbMapName[3] etc. in load.c). */
static void SetMapFileLetter(char letter)
{
    FcbMapName[3] = letter;
    FcbMonName[3] = letter;
    FcbTlkName[3] = letter;
}

/* asm: SpaceCmdLand @7185 also: @7222 returns: SpaceCmdLoop
 *
 * The L command: the centre back to the middle, "LANDING REQUESTED!", FindOrbit; in deep space
 * "REQUEST DENIED!" and back to the command loop (false). Otherwise the files for the caller:
 * Earth, letter 'X', TimeZone 4, MapType 0 (MAPX40); the other planets letter 'G', TimeZone = the
 * planet's number, MapType 0 (MAPG10 ... MAPG90). The speaker is switched off and the flight is over
 * (true: SpaceFlight returns). A frame of stars and a delay come first. */
static bool SpaceCmdLand(void)
{
    EraseCrosshair();
    LineEndX = 0x80;
    LineEndY = 0x40;
    PrintInline("LANDING REQUESTED!\n");
    FindOrbit();
    if (Planet == 0x0A) {
        PrintInline("REQUEST DENIED!\n");
        return false;
    }
    if (Planet == 0) {                              /* asm: SpaceLand_Earth */
        MoveStars();
        SpeedDelay(0x14);
        SetMapFileLetter('X');
        MapType = 0;
        TimeZone = 4;
        SpaceSpeakerOff();
        return true;
    }
    MoveStars();                                    /* asm: SpaceLand_Planet */
    SpeedDelay(0x14);
    SetMapFileLetter('G');
    MapType = 0;
    TimeZone = Planet;
    SpaceSpeakerOff();
    return true;
}

/* asm: SpaceCmdLoop @6A79
 *
 * The command loop: the fuel and coordinates, "CMD: ", then the stars fly until a key comes. The
 * direction keys only move the centre the stars fly from, to the left, right, top or bottom of
 * the view ("LEFT", "RIGHT", "CLIMB", "DIVE") with no other effect; H hyperwarps, L lands (and
 * returns when it does); any other key silently puts the centre back in the middle. */
static void SpaceCmdLoop(void)
{
    u16 key;
    u8 k;

    for (;;) {
        ShowFuelCoords();
        PrintInline("CMD: ");
        for (;;) {
            do {                                    /* asm: SpaceCmd_Poll */
                MoveStars();
                SpeedDelay(0x14);
                key = ReadKey();
            } while ((key >> 8) != 0xFF);
            k = (u8)key;
            if (k == KeyWest) {
                PrintInline("LEFT\n");
                EraseCrosshair();
                LineEndX = 0x20;
                LineEndY = 0x40;
                break;
            }
            if (k == KeyEast) {
                PrintInline("RIGHT\n");
                EraseCrosshair();
                LineEndX = 0xDF;
                LineEndY = 0x40;
                break;
            }
            if (k == KeyNorth) {
                PrintInline("CLIMB\n");
                EraseCrosshair();
                LineEndY = 0x10;
                LineEndX = 0x80;
                break;
            }
            if (k == KeySouth) {
                PrintInline("DIVE\n");
                EraseCrosshair();
                LineEndY = 0x6F;
                LineEndX = 0x80;
                break;
            }
            if (k == 'H') {
                SpaceCmdHyperwarp();
                break;
            }
            if (k == 'L') {
                if (SpaceCmdLand())
                    return;
                break;
            }
            EraseCrosshair();                       /* asm: SpaceCmd_Recenter: no new prompt */
            LineEndX = 0x80;
            LineEndY = 0x40;
        }
    }
}

/* asm: SpaceFlight @6999
 *
 * From launch to landing. Planet is where the rocket lifted off from. The CGA screen, the speaker
 * off, the star centre in the middle (80h, 40h), Xeno, Yako, Zabo the planet's own; 1 fuel taken;
 * "FUEL=", "XENO=", "YAKO=", "ZABO=" on rows 20-23; the stars scattered and the hyperwarp played.
 * Without reflect or power armour: "YOU HAVE EXPLODED!" and the hang. Otherwise the command loop,
 * which ends with the landing. */
void SpaceFlight(void)
{
    SetGraphicsMode();
    SpeakerIsOff = 0xFF;
    LineEndX = 0x80;
    LineEndY = 0x40;
    Xeno = PlanetXenoTbl[Planet];
    Yako = PlanetYakoTbl[Planet];
    Zabo = PlanetZaboTbl[Planet];
    TriLithium = bcd_sub(TriLithium, 1);

    TextRightCol = 0x28;
    SetCursor(0x1E, 0x14);
    PrintInline("  FUEL=");
    SetCursor(0x1E, 0x15);
    PrintInline("  XENO=");
    SetCursor(0x1E, 0x16);
    PrintInline("  YAKO=");
    SetCursor(0x1E, 0x17);
    PrintInline("  ZABO=");
    TextRightCol = 0x20;
    ShowFuelCoords();
    ScatterStars();
    Hyperwarp();
    if (WornArmour >= 5) {
        SpaceCmdLoop();
        return;
    }
    PrintInline("\nYOU HAVE EXPLODED!\n\n");
    Space_Die();
}
