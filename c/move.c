/* move.c -- MOVE.ASM (original addresses 2362-26F9) read as C: a step on the surface or in a
 * town, the direction a command asks for, the monster in that direction, and the time doors.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/MOVE.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine, that it prints
 * the same texts and that it calls the same routines at least as often. It cannot check the logic.
 *
 * A step: MAIN's loop changes PlayerX/PlayerY first, prints the direction and then asks
 * CheckStep about the tile entered (a half code, the map byte / 2; bit 7 is MAPVIEW's redraw
 * flag). The assembly answers in AL and the zero flag (0 allowed, FFh refused: MAIN steps back and
 * prints "--INVALID MOVE!"), but two of its paths never come back: leaving a town over its edge
 * (LeaveToSurface) and a time door (EnterTimeDoor) end the turn with `jmp EndCommand`. Here they
 * return STEP_DONE (u2.h), and the caller does nothing more. Death (PlayerDies, DieOfStarvation)
 * does not return at all.
 *
 * The routines below CheckStep jump to and call each other freely (the horse's step calls the
 * walker's step and adds its own rules, the plane calls the horse's); each one here returns what
 * it decided, and the two exits CheckStep_Allow and CheckStep_Refuse are the two return values.
 *
 * Half codes of the tiles: 0 water, 2 marsh, 4 grass, 6 woods, 8 mountains, 0Ah-14h village,
 * towne, tower, castle, dungeon, sign; 22h horse, 24h frigate, 26h plane, 28h rocket, 2Eh force
 * field, 60h time door, 78h and up the player on foot.
 *
 * See shops.c for the conventions shared by all the C files.
 */

#include "u2.h"

/* ---- What a command asks for ---------------------------------------------------------------- */

/* asm: ReadDirection @2362
 *
 * Waits for one of the four direction keys (KeyNorth...KeyWest), prints its name and sets
 * DeltaX/DeltaY to the step (-1, 0 or +1). Other keys are ignored but do not restart the wait:
 * after 65536 polls without a direction it prints "PASS" and returns false; the assembly then
 * drops its caller and ends the turn with the error beep (EndCommandBeep), so every caller
 * returns at once. (Five NOPs in the wait loop show where something was patched out.) */
bool ReadDirection(void)
{
    u16 timeout;                /* asm: Temp1F (low), Temp20 (high) */
    u16 key;
    u8 k;

    timeout = 0;
    DeltaX = 0;
    DeltaY = 0;
    for (;;) {
        key = ReadKey();
        if ((key >> 8) != 0xFF) {
            if (++timeout == 0) {
                PrintInline("PASS");
                Beep();
                return false;
            }
            continue;
        }
        k = (u8)key;
        if (k == KeyNorth) {
            PrintInline("NORTH");
            DeltaY--;
            return true;
        }
        if (k == KeySouth) {
            PrintInline("SOUTH");
            DeltaY++;
            return true;
        }
        if (k == KeyEast) {
            PrintInline("EAST");
            DeltaX++;
            return true;
        }
        if (k == KeyWest) {
            PrintInline("WEST");
            DeltaX--;
            return true;
        }
    }
}

/* asm: FindMonsterInDir @23E6
 *
 * The monster on the square next to the player in the direction DeltaX/DeltaY: the slot of a live
 * monster (MonsterTile not 0) standing there, searched from 31 down to 1, or 0 for none. LookX/LookY
 * are left on that square. BUG, as in the original: the square is not wrapped at 64, so a monster
 * across the edge of the surface map is not found; and slot 0 is never looked at. (Attack, Fire,
 * Offer, Steal, Transact.) */
u8 FindMonsterInDir(void)
{
    u8 slot;                    /* asm: DI */

    LookX = (u8)(PlayerX + DeltaX);
    LookY = (u8)(PlayerY + DeltaY);
    for (slot = 0x1F; slot != 0; slot--) {
        if (MonsterTile[slot] != 0 && MonsterX[slot] == LookX && MonsterY[slot] == LookY)
            return slot;
    }
    return 0;
}

/* ---- A step --------------------------------------------------------------------------------- */

static u8 StepOnFoot(u8 tile);
static u8 StepHorse(u8 tile);
static u8 EnterTimeDoor(void);

/* asm: CheckStep_Allow @2664 -- allowed: the position wraps round the 64x64 map. (In a town the
 * edge was tested before, so the wrap only matters outdoors.) */
static u8 CheckStep_Allow(void)
{
    PlayerX &= 0x3F;
    PlayerY &= 0x3F;
    return STEP_ALLOWED;
}

/* asm: CheckStep @2423 also: @248B @25FB
 *
 * The rules for the step onto `tile` (half code), in this order:
 *   - in a town (MapType not 0) a position outside 0-3Fh means the player walked off the edge:
 *     LeaveToSurface, and the turn is over;
 *   - marsh (2) poisons: 5 hit points off, below zero is death;
 *   - a force field (2Eh) takes 1000 hit points, unless the player has a ring;
 *   - with paralysed legs the step is refused ("--PARALIZED!", so spelt);
 *   - then by transport (PlayerTile): the rocket never moves on the ground (L)aunch flies it), the
 *     frigate moves on water only, the plane and the horse have their own rules, everything else
 *     walks (StepOnFoot).
 * A QUIRK of the assembly, kept: after the marsh the test for the force field compares HitPointsHi
 * (left in AL by the subtraction) instead of the tile. A BCD hundreds byte is never 2Eh, so it
 * never matters. */
u8 CheckStep(u8 tile)
{
    u8 al;                      /* asm: AL, what the force-field test compares */
    u8 transport;
    u16 d;
    u8 i;
    int borrow;

    /* asm: Temp29 = tile */
    if (MapType != 0 && (PlayerX >= 0x40 || PlayerY >= 0x40)) {
        LeaveToSurface();
        return STEP_DONE;
    }

    /* CheckStep_Terrain */
    al = tile & 0x7F;
    if (al == 2) {                                  /* marsh: 5 hit points of poison */
        borrow = 0;
        HitPointsLo = bcd_sbb(HitPointsLo, 5, &borrow);
        HitPointsHi = bcd_sbb(HitPointsHi, 0, &borrow);
        if (borrow) {
            PlayerDies();                           /* does not return */
            return STEP_DONE;
        }
        al = HitPointsHi;                           /* see the quirk above */
    }
    if (al == 0x2E) {                               /* force field */
        if (ItemCounts[0] != 0) {                   /* rings */
            PrintInline("\nRING PROTECTS FROM FIELD!");
            PlayHurtSound();
        } else {
            PrintInline("\nFIELD CAUSES 1000 DAMAGE!");
            DeltaX = 0;                             /* direction 0,0: the mark on the player's own square */
            DeltaY = 0;
            XorAttackMark();
            PlayHurtSound();
            XorAttackMark();
            borrow = 0;
            HitPointsHi = bcd_sbb(HitPointsHi, 0x10, &borrow);   /* 10h hundreds */
            if (borrow) {
                PlayerDies();
                return STEP_DONE;
            }
        }
    }
    if (LegsParalyzed != 0) {
        PrintInline("--PARALIZED!\n");
        return STEP_REFUSED;
    }

    transport = PlayerTile;
    if (transport == 0x28)                          /* asm: StepRocket */
        return STEP_REFUSED;
    if (transport == 0x26) {                        /* asm: StepPlane: the horse's rules, and no woods */
        u8 r = StepHorse(tile);
        if (r != STEP_ALLOWED) return r;
        if ((tile & 0x7F) == 6) return STEP_REFUSED;
        return CheckStep_Allow();
    }
    if (transport == 0x24) {                        /* asm: StepFrigate: water only, no food, no delay */
        if (tile == 0 || tile == 0x80)
            return CheckStep_Allow();
        return STEP_REFUSED;
    }
    if (transport == 0x22) {                        /* horse: a delay first, then StepHorse */
        PlayStepSound();                            /* asm: HorseStep_Delay */
        for (i = 0xFF; i != 0; i--) {               /* 255 x (32 empty loops + speed delay 10h) */
            d = 0x20;
            do { } while (--d != 0);
            SpeedDelay(0x10);
        }
        return StepHorse(tile);
    }
    return StepOnFoot(tile);
}

/* asm: StepOnFoot @2575
 *
 * One step on foot (and inside the horse's and the plane's step): two step sounds and the
 * speed-dependent delays, 0.19 food (below zero is starvation), then the walker's terrain:
 *   - the time door (60h): EnterTimeDoor, the turn is over;
 *   - water (0) and mountains (8) refused;
 *   - 22h-2Eh (the transports, 2Ah, 2Ch and the force field) and 38h allowed;
 *   - anything else from 16h up refused, everything below allowed (marsh, grass, woods, the
 *     entrances of villages, townes, towers, castles, dungeons, signs). */
static u8 StepOnFoot(u8 tile)
{
    u16 d;
    u8 i;
    int borrow;

    PlayStepSound();
    for (i = 0xFF; i != 0; i--) {                   /* the same delay as the horse's */
        d = 0x20;
        do { } while (--d != 0);
        SpeedDelay(0x10);
    }
    PlayStepSound();
    SpeedDelay(0x12);

    borrow = 0;                                     /* food -= 0.19 (FoodFrac holds the hundredths) */
    FoodFrac = bcd_sbb(FoodFrac, 0x19, &borrow);
    FoodLo = bcd_sbb(FoodLo, 0, &borrow);
    FoodHi = bcd_sbb(FoodHi, 0, &borrow);
    if (borrow) {
        DieOfStarvation();                          /* does not return */
        return STEP_DONE;
    }

    tile &= 0x7F;
    if (tile == 0x60)
        return EnterTimeDoor();
    if (tile == 0 || tile == 8)
        return STEP_REFUSED;
    if (tile == 0x22 || tile == 0x24 || tile == 0x26 || tile == 0x28
        || tile == 0x2A || tile == 0x2C || tile == 0x2E || tile == 0x38)
        return CheckStep_Allow();
    if (tile >= 0x16)
        return STEP_REFUSED;
    return CheckStep_Allow();
}

/* asm: StepHorse @2626
 *
 * The horse's step, also the start of the plane's: 0.19 food, then a whole step on foot
 * (StepOnFoot: its delay and another 0.19 food, the walker's terrain), and in addition no marsh.
 * So a horse pays two delays and 0.38 food a step, a plane on the ground one delay and 0.38.
 * The test for the time door that follows can never be true: StepOnFoot has already gone through
 * the door (and then this is not reached).
 * BUG, as in the original: StepOnFoot's "allowed" has already wrapped the position (CheckStep_Allow)
 * when the marsh here, or the plane's woods in CheckStep, refuse the step; MAIN then steps back from
 * the wrapped value. A horse at x = 0 refused marsh at x = 63 ends up at x = 40h, off the map (and
 * the same at the other three edges, FFh going the other way). See docs/FINDINGS.md. */
static u8 StepHorse(u8 tile)
{
    int borrow;
    u8 r;

    borrow = 0;
    FoodFrac = bcd_sbb(FoodFrac, 0x19, &borrow);
    FoodLo = bcd_sbb(FoodLo, 0, &borrow);
    FoodHi = bcd_sbb(FoodHi, 0, &borrow);
    if (borrow) {
        DieOfStarvation();
        return STEP_DONE;
    }
    r = StepOnFoot(tile);                           /* asm: StepHorse_Walk */
    if (r != STEP_ALLOWED) return r;
    tile &= 0x7F;
    if (tile == 2) return STEP_REFUSED;             /* marsh */
    if (tile == 0x60) return STEP_REFUSED;          /* never true */
    return CheckStep_Allow();
}

/* ---- Leaving -------------------------------------------------------------------------------- */

/* asm: LeaveToSurface @243E returns: EndCommand
 *
 * From a town (CheckStep, the plane's flight) or a dungeon (CMDAL) back to the surface: the
 * remembered surface position, MapType 0, the surface map and monsters reloaded. On another
 * planet those maps were never saved, so the parked rocket (map byte 50h) is put back at
 * RocketX/RocketY; on Earth the player record is written to PLAYER. Then the turn is over. */
void LeaveToSurface(void)
{
    PlayerX = SurfaceX;
    PlayerY = SurfaceY;
    MapType = 0;
    LoadMapAndMonsters();
    if (Planet != 0) {
        LookX = RocketX;
        LookY = RocketY;
        GetMapSquare();                             /* MapCellPtr -> the rocket's square */
        *MapCellPtr = 0x50;
        return;
    }
    ReadWriteFile(0x28, "PLAYER  ", PlayerRecord, 0x100);   /* DOS block write */
}

/* asm: EnterTimeDoor @2677 returns: EndCommand
 *
 * Through a time door (map byte C0h, half code 60h): the door's square gets back the terrain it
 * covered (TimeDoorUnder), and the map window is drawn once with that terrain on the player's
 * square, so that the player vanishes. Then the game is saved (SaveGame) and the door takes the
 * player to another era: the door's spot (TimeDoorSpot / 2, 0-3) counted over the eras other than
 * the present one (spot 0 in era 0 leads to era 1, in era 2 to era 0). That era's map and monsters
 * are loaded and the player stands at the same spot of its row of TimeDoorTbl (DUNGEON.ASM: four
 * x,y pairs per era, the places MoveTimeDoor moves the door between). The turn is over. */
static u8 EnterTimeDoor(void)
{
    u8 saved_tile;              /* asm: Temp1F */
    u8 zone;
    u8 i;

    saved_tile = PlayerTile;
    LookX = PlayerX;
    LookY = PlayerY;
    GetMapSquare();                                 /* MapCellPtr -> the door's square */
    *MapCellPtr = TimeDoorUnder;                    /* the door is gone from this map */
    PlayerTile = (u8)(TimeDoorUnder >> 1);          /* draw the terrain in place of the player */
    UpdateMapView();
    PlayerTile = saved_tile;
    PlayWarpSound();
    SurfaceX = PlayerX;                             /* (SaveGame sets them again) */
    SurfaceY = PlayerY;
    SaveGame();

    zone = (u8)(TimeDoorSpot >> 1);
    if (zone >= TimeZone)
        zone++;                                     /* skip the era we are in */
    TimeZone = zone;
    LoadMapAndMonsters();
    i = (u8)(TimeZone * 8 + TimeDoorSpot);
    PlayerX = TimeDoorTbl[i];
    PlayerY = TimeDoorTbl[i + 1];
    UpdateMapView();
    PlayWarpSound();
    return STEP_DONE;
}
