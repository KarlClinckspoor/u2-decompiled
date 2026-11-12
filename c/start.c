/* start.c -- START.ASM (original addresses 0100-0730) read as C: the program's start, the title
 * screens, the menu, the demonstration, and the speed-scaled delays.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/START.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine, that it prints
 * the same texts and that it calls the same routines at least as often. It cannot check the logic.
 *
 * The flow, all by jumps in the assembly:
 *     ProgramEntry -> TitleScreen -> (Escape at any wait) MainMenu -> DemoShow / GameStart /
 *                                                                     CreateCharacter
 *     TitleScreen ends in the dragon picture, then the menu, or the demonstration when it has been
 *     seen (DemoSeen); DemoShow ends back at TitleScreen. In the C each of these hands over to the
 *     next with an ordinary call and returns: none of them returns to its caller in the
 *     assembly (a `jmp`), so what comes after such a call is only the C unwinding. The one place
 *     where the assembly's stack is not clean (the Escape path, see WaitForEscape) is a plain return.
 * Escape: ReadKey answers FF1Bh. WaitForEscape, TitleWait and DemoWait return true when Escape
 * was pressed: the menu has then run (and ended), and the caller returns at once.
 *
 * "][" is how the game's font draws the roman II ("PART ][" is Part II); "ULTIMA ][" is Ultima II.
 * The PIC pictures (16 KB, CGA mode 4) are read straight onto the screen: ReadWriteFile with a
 * name starting with "PI" uses the segment B800h, the buffer being the offset in it (CgaMemory).
 *
 * Not translated: two pieces of dead code of the 1989 patch (a castle scene PICCAS at 04A9, which
 * a jmp skips and for which the release has no file, and the tail of the old speed calibration at
 * 06B3), and the padding.
 *
 * See shops.c for the conventions shared by all the C files.
 */

#include "u2.h"

/* ---- Start-up ------------------------------------------------------------------------------- */

/* asm: ProgramEntry @0100
 *
 * The entry of the program, also what character generation calls to restart it after a new
 * character was written. DS and SS are set (the stack is just above the data, SP = 100h: no C
 * counterpart); the six bytes of the random seed all get the low byte of the BIOS tick count, the
 * first two one more, so that they differ; the text screen is cleared, the demonstration is "not
 * seen", and the speed setting and the delay table are set up. Then the title. */
void ProgramEntry(void)
{
    u8 tick = BiosTickLow();

    RandSeed[0] = (u8)(tick + 1);
    RandSeed[1] = (u8)(tick + 1);
    RandSeed[2] = tick;
    RandSeed[3] = tick;
    RandSeed[4] = tick;
    RandSeed[5] = tick;
    SetTextMode();
    DemoSeen = 0;
    SetDefaultSpeed();
    CalcDelayTbl();
    TitleScreen();
}

/* ---- The title ------------------------------------------------------------------------------ */

/* asm: WaitForEscape @0696 returns: MainMenu
 *
 * `polls` times: a speed delay (table entry 5) and one poll of the keyboard. Other keys are ignored.
 * On Escape the assembly drops its own return address and jumps to the menu, which leaves the caller's
 * return address on the stack for good (about 120 Escapes from the end of the stack; harmless).
 * Here: the menu is run and true is returned. With the 1989 speed setting the delay is 0, so the
 * length of the wait depends on the speed of the machine. */
static bool WaitForEscape(u16 polls)
{
    do {
        SpeedDelay(0x0A);
        if (ReadKey() == 0xFF1B) {
            MainMenu();
            return true;
        }
    } while (--polls != 0);
    return false;
}

/* asm: TitleWait @0688 -- up to 6000h polls of the keyboard; true if Escape took the player to
 * the menu. */
static bool TitleWait(void)
{
    return WaitForEscape(0x6000);
}

/* asm: DemoWait @068F -- the same with A000h polls, for the demonstration's pictures. */
static bool DemoWait(void)
{
    return WaitForEscape(0xA000);
}

/* asm: TitleScreen @013E
 *
 * Two text screens, each held by TitleWait (and checked once more for Escape): "ORIGIN PROUDLY
 * PRESENTS", then "PART ][ OF THE #1 BEST SELLING FANTASY ROLE-PLAYING GAME BY LORD BRITISH"; then
 * the dragon, picture PICDRA, held by TitleWait and then 5 x (a busy loop of 2C00h and speed delay
 * entry 4); Escape is not looked for in that last hold. After it comes the menu, or, when the
 * demonstration has been seen, the demonstration again. Escape anywhere before goes to the menu. */
void TitleScreen(void)
{
    int n;
    u16 d;

    SetTextMode();
    SetCursor(0x10, 0x0A);
    PrintInline("ORIGIN");
    SetCursor(0x0B, 0x0C);
    PrintInline("PROUDLY PRESENTS");
    if (TitleWait()) return;
    if (ReadKey() == 0xFF1B) {
        MainMenu();
        return;
    }

    SetTextMode();
    SetCursor(0x10, 8);
    PrintInline("PART ][");
    SetCursor(9, 0x0A);
    PrintInline("OF THE #1 BEST SELLING");
    SetCursor(7, 0x0C);
    PrintInline("FANTASY ROLE-PLAYING GAME");
    SetCursor(0x0C, 0x0E);
    PrintInline("BY LORD BRITISH");
    if (TitleWait()) return;
    if (ReadKey() == 0xFF1B) {
        MainMenu();
        return;
    }

    SetGraphicsMode();                              /* the dragon: CGA mode 4 */
    ReadWriteFile(0x27, "PICDRA  ", CgaMemory, 0x4000);
    if (TitleWait()) return;
    for (n = 5; n != 0; n--) {
        d = 0x2C00;
        do { } while (--d != 0);                    /* CPU-speed dependent */
        SpeedDelay(8);
    }
    if (DemoSeen == 0)
        MainMenu();
    else
        DemoShow();
}

/* asm: MainMenu @0242
 *
 * The menu, in text mode: the title, the three choices, "CHOICE:". D starts the demonstration,
 * P the game (GameStart, which never returns), C character generation (CreateCharacter, which
 * does not return either: it restarts the program; if it did return, the game would start).
 * Any other key draws the menu again. */
void MainMenu(void)
{
    u8 key;

    SetTextMode();
    CursorRow = 1;
    CursorCol = 0x0F;
    PrintInline("ULTIMA ][");
    CursorRow = 3;
    CursorCol = 0x10;
    PrintInline("REVENGE");
    CursorRow = 5;
    CursorCol = 0x10;
    PrintInline("OF  THE");
    CursorRow = 7;
    CursorCol = 0x0E;
    PrintInline("ENCHANTRESS");
    CursorRow = 0x16;
    CursorCol = 6;
    PrintInline("(C)-1983,1989 BY LORD BRITISH");
    CursorRow = 0x17;
    CursorCol = 0x0F;
    PrintInline("AND ORIGIN");
    CursorRow = 0x0B;
    CursorCol = 5;
    PrintInline("TYPE -");
    CursorRow = 0x0D;
    CursorCol = 6;
    PrintInline("'D' - FOR A DEMONSTRATION");
    CursorRow = 0x0F;
    CursorCol = 6;
    PrintInline("'P' - PLAY A GAME OF ULTIMA ][");
    CursorRow = 0x11;
    CursorCol = 6;
    PrintInline("'C' - CREATE A NEW CHARACTER");
    CursorRow = 0x13;
    CursorCol = 5;
    PrintInline("CHOICE:");

    key = ReadAsciiKey();
    PrintChar(key);
    if (key == 'D') {
        DemoShow();
        return;
    }
    if (key == 'P') {
        GameStart();
        return;
    }
    if (key == 'C') {
        CreateCharacter();
        GameStart();                                /* (not reached: CreateCharacter restarts the program) */
        return;
    }
    MainMenu();
}

/* asm: DemoShow @03AF
 *
 * The demonstration: five CGA pictures, each read onto the screen, captioned on text rows 23 and
 * 24 and held by DemoWait (Escape goes to the menu): PICOUT outdoors, PICTWN a town, PICDNG a
 * dungeon, PICSPA space, PICMIN Minax. Between pictures the captions (ClearBottomLines) and the
 * picture (ClearViewArea) are cleared. DemoSeen is set, so the title sequence runs the
 * demonstration by itself from now on. It ends by going back to the title. (A sixth picture,
 * PICCAS, a castle, was cut by the 1989 patch.) */
void DemoShow(void)
{
    SetGraphicsMode();
    DemoSeen = 1;

    ReadWriteFile(0x27, "PICOUT  ", CgaMemory, 0x4000);
    CursorRow = 0x17;
    CursorCol = 0;
    PrintInline("        BATTLE STRANGE CREATURES");
    CursorCol = 0;
    CursorRow = 0x18;
    PrintInline("      ACROSS THE FACE OF THE EARTH");
    if (DemoWait()) return;
    ClearBottomLines();
    ClearViewArea();

    ReadWriteFile(0x27, "PICTWN  ", CgaMemory, 0x4000);
    CursorCol = 0;
    CursorRow = 0x17;
    PrintInline("   SEARCH FOR CLUES IN CARELESS WORDS");
    CursorCol = 2;
    CursorRow = 0x18;
    PrintInline("      SPOKEN AT THE LOCAL PUB");
    if (DemoWait()) return;
    ClearBottomLines();                             /* asm: Demo_Dungeon (the PICCAS scene is dead code) */
    ClearViewArea();

    ReadWriteFile(0x27, "PICDNG  ", CgaMemory, 0x4000);
    CursorCol = 0;
    CursorRow = 0x17;
    PrintInline("   TRAVERSE DEEP DARK DEADLY DUNGEONS");
    CursorCol = 1;
    CursorRow = 0x18;
    PrintInline("      AND TALL TERRIFYING TOWERS");
    if (DemoWait()) return;
    ClearBottomLines();
    ClearViewArea();

    ReadWriteFile(0x27, "PICSPA  ", CgaMemory, 0x4000);
    CursorCol = 0;
    CursorRow = 0x17;
    PrintInline("      TRAVEL THROUGHOUT THE GALAXY");
    CursorCol = 1;
    CursorRow = 0x18;
    PrintInline("  TO THE PLANETS OF OUR SOLAR SYSTEM");
    if (DemoWait()) return;
    ClearBottomLines();
    ClearViewArea();

    ReadWriteFile(0x27, "PICMIN  ", CgaMemory, 0x4000);
    CursorCol = 0;
    CursorRow = 0x17;
    PrintInline("   AND CONQUER TIME ITSELF TO BATTLE");
    CursorCol = 8;
    CursorRow = 0x18;
    PrintInline("MINAX THE ENCHANTRESS");
    if (DemoWait()) return;
    TitleScreen();                                  /* and round again */
}

/* ---- The speed ------------------------------------------------------------------------------ */

/* asm: SetDefaultSpeed @06AC -- SpeedSetting = 00FFh. The 1989 patch put this over the old speed
 * calibration. 00FFh is below the base value SpeedMin, so CalcDelayTbl makes every delay 0 (the
 * fastest); Ctrl-Left and Ctrl-Right (ReadKey) change it by 200h, and the first Ctrl-Right
 * hangs the game (see ReadKey). Also called by GameStart when the PLAYER file has no setting. */
void SetDefaultSpeed(void)
{
    SpeedSetting = 0xFF;
}

/* asm: CalcDelayTbl @06ED
 *
 * The 20 delays from the speed setting: DelayTbl[i] = (SpeedSetting - SpeedMin) * DelayFactorTbl[i]
 * / SpeedMin, or 0 when SpeedSetting is below SpeedMin: the faster the machine (the higher the
 * setting), the longer the delay loops. The upper limit 3A00h of Ctrl-Left is about where the
 * largest factor (2000h) still fits the 16-bit quotient; a quotient too big (or SpeedMin 0) is a
 * divide error, which ends (in DOSBox hangs) the program. */
void CalcDelayTbl(void)
{
    int i;
    u16 diff;
    u32 product;

    for (i = 19; i >= 0; i--) {                     /* byte offsets 26h down to 0 */
        if (SpeedSetting < SpeedMin) {
            DelayTbl[i] = 0;
            continue;
        }
        diff = (u16)(SpeedSetting - SpeedMin);
        product = (u32)diff * DelayFactorTbl[i];
        if ((product >> 16) >= SpeedMin)
            DivideError();                          /* does not return */
        DelayTbl[i] = (u16)(product / SpeedMin);
    }
}

/* asm: SpeedDelay @0711
 *
 * A delay: DelayTbl[entry] times a busy loop of 12 rounds, the entry given as its byte offset (2 x
 * the number). Nothing for 0; the value is a signed count, so 8001h and above also do nothing
 * (8000h would run 8000h times). Used with entry 0 by the command prompt, 4 for the dragon, 5 for
 * the title waits, and by many other places. */
void SpeedDelay(u16 entry_offset)
{
    u16 n = DelayTbl[entry_offset / 2];
    u16 d;

    for (;;) {
        n--;
        if (n >= 0x8000)                            /* js: the count went below zero */
            return;
        d = 0x0C;
        do { } while (--d != 0);
    }
}
