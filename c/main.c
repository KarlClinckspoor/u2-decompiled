/* main.c -- MAIN.ASM (original addresses 0730-0E70) read as C: the heart of the game on a map.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/MAIN.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine, that it prints
 * the same texts and that it calls the same routines at least as often. It cannot check the logic.
 *
 * One turn of the game, outdoors or in a town (a dungeon has its own loop, DungeonLoop, in
 * DUNGEON.ASM):
 *
 *     MainLoop        one pass per command: wait for a key, move or run a command...
 *     EndCommand      ...then the turn ends: the monsters move (OutdoorMonsters here, the town and
 *                     dungeon turns in EVENTS.ASM), and EndTurn applies what they did
 *
 * In the assembly all of this is a web of jumps (every command ends with `jmp EndCommand`, the
 * monsters' loops jump on to EndTurn, EndTurn jumps back to MainLoop). Here the commands and the
 * monsters' turns simply return, and MainLoop calls EndCommand after each pass; so a jump to
 * EndTurn or MainLoop in the assembly is a plain `return` in the C (the anchors say so with
 * `returns:`). The assembly's `mov sp, 100h` at the top of MainLoop, which forgets pending
 * returns, has no counterpart.
 *
 * Three scratch bytes count what happens to the player in one turn: Temp20 the attacks made
 * against him, Temp21 how many of them hit, Temp22 the damage. EndCommand clears them, the
 * monsters' routines add to them, EndTurn applies them. At the prompt Temp21 and Temp22 are also
 * the idle timer.
 *
 * See shops.c for the conventions shared by all the C files.
 */

#include <string.h>
#include "u2.h"

/* ---- The command table ---------------------------------------------------------------------- */

/* asm: CmdJumpTbl @0730 check: none -- the handler of each key A-Z, as in the manual. */
void (*const CmdJumpTbl[26])(void) = {
    CmdAttack, CmdBoard, CmdCast, CmdDescend, CmdEnter, CmdFire, CmdGet, CmdHyperspace,
    CmdIgniteTorch, CmdJump, CmdKlimb, CmdLaunch, CmdMagic, CmdNegateTime, CmdOffer, CmdPass,
    CmdQuit, CmdReady, CmdSteal, CmdTransact, CmdUnlock, CmdView, CmdWear, CmdXit,
    CmdYell, CmdZtats
};

void MainLoop(void);

/* ---- Starting the game ---------------------------------------------------------------------- */

/* asm: GameStart @0764 -- 'P' on the title menu. Reads the PLAYER file (an empty name means "no
 * character on disk": wait for Escape and read it again, forever), sets the delays from the saved
 * speed, reads the MONSTERS file, loads the map and monsters of the saved place, switches to the
 * graphics screen, puts the player on foot (78h + 2 x class) at the saved surface position, clears
 * the timers, puts a parked rocket back on the map and draws everything. Then the main loop;
 * it does not return. (The 1989 patch jumps over the old "(INSERT PLAYER DISK)" prompt.) */
void GameStart(void)
{
    for (;;) {
        SetTextMode();
        SetCursor(10, 12);
        ReadWriteFile(0x27, "PLAYER  ", PlayerRecord, 0x100);
        if (PlayerRecord[0] != 0) break;
        SetTextMode();
        SetCursor(10, 12);
        PrintInline("NO CHARACTER ON DISK");
        while (ReadKey() != 0xFF1B) { }             /* wait for Escape */
    }
    if (SpeedSetting == 0)                          /* never set: the default */
        SetDefaultSpeed();
    CalcDelayTbl();
    ReadWriteFile(0x27, "MONSTERS", MonsterBufPtr, 0x800);
    LoadMapAndMonsters();
    SetGraphicsMode();
    PlayerTile = (u8)(0x78 + 2 * PlayerClass);
    TimeStopTurns = 0;
    LegsParalyzed = 0;
    ArmsParalyzed = 0;
    SleepTurns = 0;
    PlayerX = SurfaceX;
    PlayerY = SurfaceY;
    if (RocketParked != 0) {                        /* a rocket stands somewhere: back on the map */
        LookX = RocketX;
        LookY = RocketY;
        GetMapSquare();
        *MapCellPtr = 0x50;
    }
    /* Both tile caches "unknown", so that every tile is drawn. The assembly's loop stops one
     * short: entry FFh is left alone (CmdLaunch and ExitToSurface do all 256). */
    memset(TileCache, 0xFF, 255);
    memset(TileCacheShown, 0xFF, 255);
    UpdateMapView();
    OffMapTile = 0xFF;                              /* the surface map wraps around */
    DrawStatusLines();
    MainLoop();
}

/* ---- One command ---------------------------------------------------------------------------- */

/* asm: MainLoop_InvalidMove @0A02 -- a step that CheckStep refused. */
void MainLoop_InvalidMove(void)
{
    PrintInline("--INVALID MOVE!");
    Beep();
}

/* asm: DispatchCommand @09FB also: @0A18 -- run the command for the key A-Z through CmdJumpTbl;
 * any other key is an illegal command. (Also called by the dungeon loop.) */
void DispatchCommand(u8 key)
{
    if (key < 'A') {
        IllegalCommand();
        return;
    }
    if (key > 'Z') {
        IllegalCommand();
        return;
    }
    CmdJumpTbl[key - 'A']();
}

/* asm: MainLoop @086F unrolled: AnimateWater-6 returns: MainLoop
 *
 * One pass of the main loop, forever: in a tower or dungeon DungeonLoop does the command;
 * otherwise "CMD: " is printed and the water and force-field pictures scroll a little. Asleep
 * (SleepTurns), 20 Z's are printed slowly and the turn is lost. Awake, the keyboard is polled
 * (with a speed-dependent delay each time); every 256 polls the plane's engine sounds (when
 * flying) and the map window is redrawn so that the water moves; and after 64 x 256 polls
 * without a key the turn passes by itself.
 *   space        pass: the turn goes by and food drops by 0.1
 *   arrow keys   one step: the position is changed first and CheckStep judges the square entered
 *                (0 = allowed); if it is refused the position is put back
 *   A-Z          the command (a command resets the horse's half-turn, LightTurns)
 * A step that is allowed flips LightTurns: on horseback the slow monsters move only every other
 * step (see OutdoorMonsters). Running out of food is death. */
void MainLoop(void)
{
    u16 key;
    u8 k;
    int i;
    int borrow;

    for (;;) {
        if (MapType >= 4) {
            DungeonLoop();
            EndCommand();
            continue;
        }
        PrintInline("CMD: ");
        for (i = 0; i < 4; i++)
            AnimateWater();
        AnimateForceField();
        Temp21 = 0;                                 /* the idle timer */
        Temp22 = 0xC0;

        if (SleepTurns != 0) {                      /* asleep: 20 Z's, one turn lost */
            for (AmountHi = 20; AmountHi != 0; AmountHi--) {
                u16 d;
                PrintInline("Z");
                for (d = 0xFF; d != 0; d--) { }     /* a short busy loop, CPU-speed dependent */
            }
            EndCommand();
            continue;
        }

        for (;;) {                                  /* wait for a key */
            SpeedDelay(0);
            key = ReadKey();
            if ((key >> 8) == 0xFF) break;
            Temp21++;
            if (Temp21 != 0) continue;
            if (PlayerTile == 0x26)                 /* the plane's engine */
                PlayStepSound();
            UpdateMapView();
            for (i = 0; i < 4; i++)
                AnimateWater();
            AnimateForceField();
            Temp22++;
            if (Temp22 != 0) continue;
            LightTurns = 0;                         /* nothing happened for a long time: pass */
            PrintInline("PASS");
            goto pass_turn;
        }

        k = (u8)key;
        LastKey = k;
        if (k == ' ') {
            LightTurns = 0;
            PrintInline("PASS");
            goto pass_turn;
        } else if (k == KeyNorth) {
            PlayerY--;
            PrintInline("NORTH");
            if (CheckStep(TileNorth) != 0) {
                PlayerY++;                          /* refused: step back */
                MainLoop_InvalidMove();
            } else {
                LightTurns ^= 0xFF;
            }
        } else if (k == KeySouth) {
            PlayerY++;
            PrintInline("SOUTH");
            if (CheckStep(TileSouth) != 0) {
                PlayerY--;
                MainLoop_InvalidMove();
            } else {
                LightTurns ^= 0xFF;
            }
        } else if (k == KeyWest) {
            PlayerX--;
            PrintInline("WEST");
            if (CheckStep(TileWest) != 0) {
                PlayerX++;
                MainLoop_InvalidMove();
            } else {
                LightTurns ^= 0xFF;
            }
        } else if (k == KeyEast) {
            PlayerX++;
            PrintInline("EAST");
            if (CheckStep(TileEast) != 0) {
                PlayerX--;
                MainLoop_InvalidMove();
            } else {
                LightTurns ^= 0xFF;
            }
        } else {
            LightTurns = 0;
            DispatchCommand(k);
        }
        EndCommand();
        continue;

pass_turn:
        /* food drops by 0.10: the three BCD bytes FoodHi FoodLo FoodFrac, with the borrow passed
         * on from one to the next. Below zero is starvation. */
        borrow = 0;
        FoodFrac = bcd_sbb(FoodFrac, 0x0A, &borrow);
        FoodLo = bcd_sbb(FoodLo, 0, &borrow);
        FoodHi = bcd_sbb(FoodHi, 0, &borrow);
        if (borrow) {
            DieOfStarvation();
            continue;
        }
        EndCommand();
    }
}

/* ---- The end of a command ------------------------------------------------------------------- */

/* asm: EndCommandBeep @0A30 -- a command that failed: the error beep, and then the turn ends like
 * any other (here: the caller returns and MainLoop calls EndCommand). */
void EndCommandBeep(void)
{
    Beep();
}

/* asm: EndCommand @0A33
 *
 * The end of every command: a new line, the turn's counters cleared, then the monsters' turn
 * for this kind of map, then EndTurn. (Each of the monsters' routines used to end with a jump to
 * EndTurn; here they return and it is called once.) */
void EndCommand(void)
{
    PutChar('\n');
    Temp22 = 0;                                     /* damage this turn */
    Temp20 = 0;                                     /* attacks this turn */
    Temp21 = 0;                                     /* hits this turn */
    switch (MapType) {
    case 1:  TownTurnVillage();     break;
    case 2:  TownTurnTowne();       break;
    case 3:  TownTurnCastle();      break;
    case 4:  DungeonTurnTower();    break;
    case 5:  DungeonTurnDungeon();  break;
    default: OutdoorMonsters();     break;          /* 0: outdoors */
    }
    EndTurn();
}

/* ---- The monsters' turn outdoors ------------------------------------------------------------ */

/* asm: OutdoorMonsters @0A6D -- every monster in slots 31 down to 1 takes its turn (slot 0 is not
 * used outdoors; a free slot has MonsterTile 0). On horseback, on the half-turns when LightTurns
 * is negative, only the fast monsters move: the pirate ship (48h), the balron (3Ch) and the sea
 * serpent (2Ch). Then a new monster may appear. */
void OutdoorMonsters(void)
{
    u8 slot;
    u8 kind;

    for (slot = 0x1F; slot != 0; slot--) {
        if (MonsterTile[slot] == 0) continue;
        if (PlayerTile == 0x22 && LightTurns >= 0x80) {
            kind = MonsterTile[slot];
            if (kind != 0x48 && kind != 0x3C && kind != 0x2C) continue;
        }
        MonsterTurn(slot);
    }
    SpawnMonster();
}

/* asm: MonsterTurn @0AA7 returns: OutdoorMonsters_Next TownTurnNextMonster
 *
 * One monster's turn (also for the monsters of a town). Within 2 squares of the player (the raw
 * difference, no wrap-around) it casts a spell one time in 8, by what it is:
 *   daemon (34h) paralyses the legs      devil (38h) the arms
 *   wizard (F8h) a magic missile         balron (3Ch) sleep
 * Then it steps one square towards the player, or away if it has fewer than 0Fh hit points; if
 * that square is the player's it attacks instead (MonsterAttack), otherwise MonsterStepToward
 * moves it. */
void MonsterTurn(u8 slot)
{
    u8 kind;

    DistToPlayer(slot);                             /* DeltaX, DeltaY: player minus monster */
    if (AbsOf(DeltaX) < 3 && AbsOf(DeltaY) < 3 && Random() < 0x20) {
        kind = MonsterTile[slot];
        if (kind == 0x34)      SpellParalyzeLegs();
        else if (kind == 0x38) SpellParalyzeArms();
        else if (kind == 0xF8) SpellMagicMissile();
        else if (kind == 0x3C) SpellSleep();
    }
    DirToPlayer(slot);                              /* DeltaX, DeltaY: -1, 0 or 1, the short way round */
    if (MonsterHP[slot] < 0x0F) {                   /* weak: run away */
        DeltaX = (u8)(0 - DeltaX);
        DeltaY = (u8)(0 - DeltaY);
    }
    if ((u8)((MonsterX[slot] + DeltaX) & 0x3F) != PlayerX) {
        MonsterStepToward(slot);
        return;
    }
    if ((u8)((MonsterY[slot] + DeltaY) & 0x3F) != PlayerY) {
        MonsterStepToward(slot);
        return;
    }
    MonsterAttack(slot);
}

/* asm: MonsterAttack @0B4D returns: TownTurnNextMonster OutdoorMonsters_Next
 *
 * The monster attacks. A thief may steal first. The attack misses half the time (a random number
 * with bit 7 set), and when the low 3 bits of that number are below the armour worn. A hit adds
 * hit points / 4 + 1 to the turn's damage, doubled on the tile type 6 (woods?) under the player. */
void MonsterAttack(u8 slot)
{
    u8 r;
    u8 damage;

    Temp20++;                                       /* an attack this turn */
    if (MonsterTile[slot] == 0xFC)
        ThiefStealItem();
    r = Random();
    if (r >= 0x80) return;                          /* a miss */
    if ((r & 7) < WornArmour) return;               /* a miss: the armour turned it */
    Temp21++;                                       /* a hit */
    damage = (u8)((MonsterHP[slot] >> 2) + 1 + Temp22);
    if (TileHere == 6)
        damage = (u8)(damage * 2);
    Temp22 = damage;
}

/* ---- The end of the turn -------------------------------------------------------------------- */

/* asm: EndTurn @0BAF returns: MainLoop
 *
 * Redraw the map. For each attack of the turn an attack sound; for the first Temp21 of them the
 * player's square flashes with the hit sound. Then the damage: (a random number AND the turn's
 * damage AND 77h) + 1 hit points, taken from the BCD hit points (borrow passed from the low byte to
 * the high one; below zero is death), and in a town, tower or dungeon MapType hundreds more (which
 * is why guards are so deadly). Then the status lines, the off-map tile (4 around a town, FFh for
 * the wrapping surface, where the time door also moves) and the four timers count down. */
void EndTurn(void)
{
    u8 damage;
    int borrow;

    UpdateMapView();
    while (Temp20 != 0) {
        PlayAttackSound();
        Temp20--;
        Temp21--;
        if (Temp21 >= 0x80) continue;               /* no hits left: this one missed */
        XorPlayerMark();
        PlayHurtSound();
        XorPlayerMark();
    }
    if (Temp22 != 0) {
        damage = (u8)((Random() & Temp22 & 0x77) + 1);
        Temp22 = damage;
        borrow = 0;
        HitPointsLo = bcd_sbb(HitPointsLo, damage, &borrow);
        HitPointsHi = bcd_sbb(HitPointsHi, 0, &borrow);
        if (borrow) {
            PlayerDies();
            return;
        }
        if (MapType != 0) {
            Temp22 = MapType;
            borrow = 0;
            HitPointsHi = bcd_sbb(HitPointsHi, Temp22, &borrow);
            if (borrow) {
                PlayerDies();
                return;
            }
        }
    }
    DrawStatusLines();
    OffMapTile = 4;
    if (MapType == 0) {
        OffMapTile = 0xFF;
        MoveTimeDoor();
    }
    if (LegsParalyzed != 0) LegsParalyzed--;
    if (ArmsParalyzed != 0) ArmsParalyzed--;
    if (SleepTurns != 0)    SleepTurns--;
    if (TimeStopTurns != 0) TimeStopTurns--;
}

/* asm: PlayerDies @0C62 -- hit points, food, experience and gold all become 0 and are shown, then
 * "<name> IS DEAD!" and the program hangs in an endless loop: the player must reboot. */
void PlayerDies(void)
{
    HitPointsHi = 0;
    HitPointsLo = 0;
    FoodHi = 0;
    FoodLo = 0;
    FoodFrac = 0;
    ExpHi = 0;
    ExpLo = 0;
    GoldHi = 0;
    GoldLo = 0;
    DrawStatusLines();
    PrintInline("\n\n\n");
    PrintPlayerName();
    PrintInline(" IS DEAD!\n");
    HangForever();
}

/* ---- New monsters outdoors ------------------------------------------------------------------ */

/* One kind of monster for SpawnMonster to make: the map code it has, its hit points and the
 * terrain it needs (8 grass, 0 water). */
struct SpawnKind { u8 code; u8 hit_points; u8 terrain; };

/* asm: SpawnMonster @0C9C returns: EndTurn
 *
 * Outdoors, after the monsters moved, maybe one more appears. It takes the highest free slot (1Fh
 * down to 1; none free: nothing), then rolls a random number and spawns only if it is below 3Fh
 * (about one turn in four), x = that number, and y from a second roll (0-3Fh; a negative roll: nothing),
 * notes the terrain there in MonsterUnder, and picks what to make from the counter SpawnCounter
 * (saved with the player), which goes up by one each time: the lowest set bit of the counter decides, so
 * the kinds come in a fixed rotation:
 *     bit 0 orc  1 thief  2 daemon  3 sea serpent (water)  4 fighter  5 pirate ship (water)
 *     6 devil  7 wizard   none (the counter is 0): balron
 * The land kinds need grass, the water kinds water; on the wrong terrain the counter goes back one
 * and nothing is made (the same kind is tried again next time). The monster's code goes into the map
 * and into MonsterTile, its hit points into MonsterHP. A square that already holds a monster has its
 * code, not 8 or 0, so it is refused; the player's own square is not checked (he is not in the
 * map), so a monster can appear right on top of him. Note that x, y and MonsterUnder of the free
 * slot are written before any of these checks, so a refused spawn leaves them changed. */
void SpawnMonster(void)
{
    static const struct SpawnKind kinds[9] = {
        { 0x30, 0x10, 8 },      /* orc */
        { 0xFC, 0x20, 8 },      /* thief */
        { 0x34, 0x40, 8 },      /* daemon */
        { 0x2C, 0x40, 0 },      /* sea serpent */
        { 0xF0, 0x80, 8 },      /* fighter */
        { 0x48, 0xA0, 0 },      /* pirate ship */
        { 0x38, 0xC0, 8 },      /* devil */
        { 0xF8, 0xE0, 8 },      /* wizard */
        { 0x3C, 0xFF, 8 },      /* balron */
    };
    u8 slot;
    u8 r;
    u8 bit;
    u8 counter;

    for (slot = 0x1F; slot != 0; slot--) {
        if (MonsterTile[slot] == 0) break;          /* a free slot */
    }
    if (slot == 0) return;                          /* none */
    r = Random();
    if (r >= 0x3F) return;                          /* most of the time: no spawn */
    MonsterX[slot] = r;
    LookX = r;
    r = Random();
    if (r >= 0x80) return;                          /* a negative roll: no spawn */
    r &= 0x3F;
    MonsterY[slot] = r;
    LookY = r;
    MonsterUnder[slot] = GetMapSquare();            /* the terrain there */
    SpawnCounter++;
    counter = SpawnCounter;
    for (bit = 0; bit < 8; bit++) {                 /* the lowest set bit of the counter */
        if (counter & 1) break;
        counter >>= 1;
    }
    if (MonsterUnder[slot] != kinds[bit].terrain) { /* bit 8 = no bit set: the balron */
        SpawnCounter--;                             /* wrong terrain: try this kind again next time */
        return;
    }
    *MapCellPtr = kinds[bit].code;
    MonsterTile[slot] = kinds[bit].code;
    MonsterHP[slot] = kinds[bit].hit_points;
}
