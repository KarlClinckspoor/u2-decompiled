/* endgame.c -- ENDGAME.ASM (original addresses 7242-740B) read as C: the speaker helpers of space
 * flight, and the end of the game.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/ENDGAME.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine, that it prints
 * the same texts and that it calls the same routines at least as often. It cannot check the logic.
 *
 * Two pieces that only happen to sit together:
 *   - the PC speaker helpers of space flight (SPACE calls them): SpeakerIsOff (a byte in the code
 *     segment, in VIEW3D) is FFh while the speaker is off and 0 while it is on; BleepCountdown (a
 *     word, also in VIEW3D) counts the star moves until the next toggle of the "computer bleeps";
 *   - MinaxDead, the end of the game.
 *
 * See shops.c for the conventions shared by all the C files.
 */

#include "u2.h"

/* ---- The speaker in space ------------------------------------------------------------------- */

/* asm: SpaceSpeakerOn @7276 -- tone divisor `divisor` on the speaker, unless it is on already
 * (SpeakerIsOff 0). */
void SpaceSpeakerOn(u16 divisor)
{
    if (SpeakerIsOff != 0xFF)
        return;
    StartTone(divisor);
    SpeakerIsOff = 0;
}

/* asm: SpaceSpeakerOff @7289 -- the speaker off, unless it is off already. */
void SpaceSpeakerOff(void)
{
    if (SpeakerIsOff != 0)
        return;
    StopTone();
    SpeakerIsOff = 0xFF;
}

/* asm: ToggleSpaceBleep @7242
 *
 * Called by the star field (SPACE's MoveStars) each time BleepCountdown runs out while cruising.
 * A sounding speaker goes quiet for E0h star moves; a quiet one starts a tone with a random
 * divisor, 0100h-2000h, for 18h star moves. */
void ToggleSpaceBleep(void)
{
    u16 divisor;

    if (SpeakerIsOff != 0xFF) {
        SpaceSpeakerOff();
        BleepCountdown = 0xE0;
        return;
    }
    divisor = (u16)(((Random() << 8) & 0x1F00) + 0x100);
    SpaceSpeakerOn(divisor);
    HoldTone(divisor, 1);                           /* sets the pitch, a short delay */
    BleepCountdown = 0x18;
}

/* ---- The end -------------------------------------------------------------------------------- */

/* asm: MinaxDead @72A0
 *
 * Called from the attack code (CmdAttack) when the monster just killed is Minax (type 40h). Never
 * returns; the player has to reboot.
 *   1. "MINAX IS DEAD!! ALL HER WORKS SHALL DIE!"
 *   2. 64 rounds: a sound, 64 random squares of the 64x64 map set to 74h, the map window redrawn
 *      and a delay (so the world falls apart);
 *   3. "YOU FEEL A STRANGE FORCE!", the warp sound, MAPX30 read over the map (the 64x64 map of
 *      era 3), the sound again, and the victory text (the game's font draws "][" as the roman II,
 *      so "ULTIMA ][" is Ultima II, and its sequel Exodus is "]I[-D ]II[-P");
 *   4. the player, drawn as tile 28h (the rocket), starts at 0,0 on a map that wraps round and
 *      flies over it for ever: one row down each frame and one column right every fourth frame. */
void MinaxDead(void)
{
    u8 rounds;                  /* asm: Temp1F */
    u8 cells;                   /* asm: Temp20 */

    TextRightCol = 0x28;
    PrintInline("\n\n     MINAX IS DEAD!!\nALL HER WORKS SHALL DIE!\n");
    for (rounds = 0x40; rounds != 0; rounds--) {
        PlayHitSound();
        for (cells = 0x40; cells != 0; cells--) {
            LookX = Random() & 0x3F;
            LookY = Random() & 0x3F;
            GetMapSquare();
            *MapCellPtr = 0x74;
        }
        UpdateMapView();
        SpeedDelay(0x0E);
    }
    PrintInline("\nYOU FEEL A STRANGE FORCE!");
    PlayWarpSound();
    ReadWriteFile(0x27, "MAPX30  ", MapBufPtr, 0x1000);
    PlayWarpSound();
    PrintInline("\n\nYOU HAVE SAVED THE UNIVERSE,\nAND COMPLETED ULTIMA ][! SEEK\nNOW TO CONQUER WICKED EXODUS,\n");
    PrintInline("FOUND IN ULTIMA ]I[-D ]II[-P!");
    OffMapTile = 0xFF;                              /* the map wraps round */
    PlayerTile = 0x28;
    PlayerX = 0;
    PlayerY = 0;
    for (;;) {
        PlayerY = (u8)((PlayerY + 1) & 0x3F);
        if ((PlayerY & 3) == 0)
            PlayerX = (u8)((PlayerX + 1) & 0x3F);
        UpdateMapView();
        SpeedDelay(6);
    }
}
