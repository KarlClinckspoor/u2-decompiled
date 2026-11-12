/* sound.c -- SOUND.ASM (original addresses 5C90-6000) read as C: the PC speaker.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/SOUND.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine and that it calls
 * the same routines at least as often. It cannot check the logic.
 *
 * A tone is channel 2 of the timer chip (PIT) in square-wave mode: the control word B6h to port
 * 43h and the divisor, low byte then high byte, to port 42h; the pitch is 1193182 Hz / divisor
 * (a bigger divisor is a lower note). The speaker is switched on by bits 0 and 1 of port 61h. The
 * C does the port accesses with OutPort and InPort (u2.h). Durations are busy loops of
 * duration * (ToneDelay + 1) rounds, so they depend on the machine's speed; ToneDelay is set by
 * CalcDelayTbl from the speed setting. With SoundOff not 0 (Ctrl-S) every effect returns at once; only
 * StartTone (used by the space routines) still programs the PIT, without switching the speaker on.
 *
 * The effects are PlaySweep (a pitch that goes back and forth between two divisors) with different
 * numbers, apart from the error beep and the step sound (a tone sequence).
 *
 * Not translated: three runs of dead code (a one-shot tone at 5CED, a falling tone at 5E56 and a
 * sound scaled by the speed setting at 5F0D), the unused words 5C91 and 5C93 they used, and the
 * zero padding at 5FFD.
 *
 * See shops.c for the conventions shared by all the C files.
 */

#include "u2.h"

/* asm: SpeakerPortSave @5C90 check: none -- the state of port 61h as StartTone found it, a byte in
 * the code segment; StopTone puts it back. */
static u8 SpeakerPortSave;

/* ---- The speaker ---------------------------------------------------------------------------- */

/* asm: StartTone @5CB2
 *
 * Starts a tone: channel 2 programmed with this divisor, port 61h saved in SpeakerPortSave and,
 * if the sound is on, the speaker switched on (bits 0 and 1). Must be paired with StopTone: calling
 * it twice would save the speaker-on state. */
void StartTone(u16 divisor)
{
    OutPort(0x43, 0xB6);                            /* channel 2, low and high byte, square wave */
    OutPort(0x42, (u8)divisor);
    OutPort(0x42, (u8)(divisor >> 8));
    SpeakerPortSave = InPort(0x61);
    if (SoundOff == 0)
        OutPort(0x61, (u8)(SpeakerPortSave | 3));
}

/* asm: HoldTone @5CD2 -- sets the tone's divisor and waits `duration` times (ToneDelay + 1) rounds
 * of a counting loop while it sounds (duration 0 is 65536). */
void HoldTone(u16 divisor, u16 duration)
{
    u16 ax;

    OutPort(0x42, (u8)divisor);                     /* the mode stays */
    OutPort(0x42, (u8)(divisor >> 8));
    do {
        ax = ToneDelay;
        do {
            ax--;
        } while (ax < 0x8000);                      /* jns */
    } while (--duration != 0);
}

/* asm: StopTone @5CE4 -- port 61h back as it was: the speaker is off. */
void StopTone(void)
{
    OutPort(0x61, SpeakerPortSave);
}

/* asm: Beep @5C95 -- the error sound ("WHAT?", the torch is out...): a short tone, divisor 500h
 * (about 930 Hz), 4000h units long. */
void Beep(void)
{
    if (SoundOff != 0)
        return;
    StartTone(0x500);
    HoldTone(0x500, 0x4000);
    StopTone();
}

/* ---- Tone sequences ------------------------------------------------------------------------- */

/* asm: ToneSeqTbl @5D9B check: none -- three tone sequences, reached through this table of code
 * offsets (5D5D, 5D61, 5D65; the bytes themselves have no label). A sequence is a list of 3-byte
 * entries, a duration byte (the duration is the byte times 256; 0 ends the sequence) and a divisor
 * word (FFFFh is a rest: the speaker off for the duration, and the next entry's divisor started
 * after it). Only sequence 0 is used (PlayStepSound); 1 and 2 are a single tone each. */
static const u8 ToneSeq0[] = { 0x05, 0x00, 0x40, 0x00 };    /* 500h units of divisor 4000h (about 73 Hz) */
static const u8 ToneSeq1[] = { 0x01, 0x00, 0x01, 0x00 };    /* 100h units of divisor 0100h */
static const u8 ToneSeq2[] = { 0x01, 0x00, 0x01, 0x00 };
static const u8 *const ToneSeqTbl[3] = { ToneSeq0, ToneSeq1, ToneSeq2 };

/* asm: PlayToneSeq @5D09
 *
 * Plays tone sequence n (0-2). The first entry's divisor starts the tone; each entry is then held
 * for its duration (HoldTone), or, for a rest (divisor FFFFh), the speaker is stopped, the
 * duration waited and the NEXT entry's divisor started. At the end the tone stops. */
static void PlayToneSeq(u16 n)
{
    const u8 *p;
    u16 divisor, cx, ax;

    if (SoundOff != 0)
        return;
    p = ToneSeqTbl[n];
    StartTone((u16)(p[1] | (p[2] << 8)));
    for (;;) {
        if (p[0] == 0)
            break;
        cx = (u16)(p[0] << 8);
        divisor = (u16)(p[1] | (p[2] << 8));
        if (divisor == 0xFFFF) {                    /* a rest */
            StopTone();
            do {
                ax = ToneDelay;
                do {
                    ax--;
                } while (ax < 0x8000);
            } while (--cx != 0);
            StartTone((u16)(p[4] | (p[5] << 8)));
        } else {
            HoldTone(divisor, cx);
        }
        p += 3;
    }
    StopTone();
}

/* asm: PlayStepSound @5EC7 -- the step: sequence 0, one low tone. Played when the player moves
 * (MOVE, by vehicle), in the plane's flight and in the idle loop when the player is the plane. */
void PlayStepSound(void)
{
    if (SoundOff != 0)
        return;
    PlayToneSeq(0);
}

/* ---- Sweeps --------------------------------------------------------------------------------- */

/* asm: PlaySweep @5DA9
 *
 * A pitch sweep: the divisor goes back and forth between `low` and `high` in steps of `step`, each
 * step held bp/2 units, `steps` of them in all (the sweep ends after that many wherever it is).
 * A positive step starts at `low` going up (the pitch falls); a zero or negative one (as a signed
 * word: FFFFh is -1) starts at `high` going down by minus the step. Going up it turns at the first
 * divisor not below `high`, going down at the first not above `low`, and the turning note
 * (high or low itself, not the one passed) is the next one played. */
static void PlaySweep(u16 low, u16 high, u16 step, u16 steps, u16 bp)
{
    u16 cur;                    /* asm: SweepCur */
    bool up;

    if (SoundOff != 0)
        return;
    bp >>= 1;
    StartTone(low);
    if ((u16)(0 - step) >= 0x8000) {                /* step > 0: start going up */
        up = true;
    } else {
        step = (u16)(0 - step);                     /* start going down with step -CX */
        up = false;
    }
    for (;;) {
        if (up) {                                   /* asm: PlaySweep_Up */
            cur = low;
            for (;;) {
                HoldTone(cur, bp);
                if (--steps == 0) goto end;
                cur = (u16)(cur + step);
                if (cur >= high) break;
            }
            up = false;
        } else {                                    /* asm: PlaySweep_Down */
            cur = high;
            for (;;) {
                HoldTone(cur, bp);
                if (--steps == 0) goto end;
                cur = (u16)(cur - step);
                if (cur <= low) break;
            }
            up = true;
        }
    }
end:
    StopTone();
}

/* asm: PlayTrapSound @5E3B -- "ARGH! A TRAP!": a long sweep, divisor 100h to 4000h in steps of 1, 1000h steps of 40h units. */
void PlayTrapSound(void)
{
    PlaySweep(0x100, 0x4000, 1, 0x1000, 0x80);
}

/* asm: PlayAttackSound @5EAC -- a monster attacks (EVENTS, MAIN) or the player fires: sweep 300h to 1000h, step 2, 200h steps of 4 units. */
void PlayAttackSound(void)
{
    PlaySweep(0x300, 0x1000, 2, 0x200, 8);
}

/* asm: PlayHitSound @5ED7 -- "HIT!!!" (and Minax's end): sweep 200h to 3000h, step 20h, E00h steps of 4 units. */
void PlayHitSound(void)
{
    PlaySweep(0x200, 0x3000, 0x20, 0x0E00, 8);
}

/* asm: PlayHurtSound @5EF2 -- the player is hurt (between two screen flashes; traps, force fields,
 * Minax's curse): sweep 800h to 1800h, step 47h, 800h steps of 4 units. */
void PlayHurtSound(void)
{
    PlaySweep(0x800, 0x1800, 0x47, 0x800, 8);
}

/* asm: PlayWarpSound @5FA6 -- teleports and "YOU FEEL A STRANGE FORCE!": a slow warble between
 * 320h and 2F8h, starting at 320h going down by 1, 50h steps of 780h units. */
void PlayWarpSound(void)
{
    PlaySweep(0x2F8, 0x320, 0xFFFF, 0x50, 0x0F00);
}

/* asm: PlaySpellSound @5FC3 -- a spell is cast: a warble between 4C0h and 492h (starting at 4C0h
 * going down by 1), 5Ch steps of 580h units. */
void PlaySpellSound(void)
{
    PlaySweep(0x492, 0x4C0, 0xFFFF, 0x5C, 0x0B00);
}

/* asm: PlaySwingSound @5FE0 -- the player attacks: sweep 400h to 1000h, step 1, 200h steps of 40h units. */
void PlaySwingSound(void)
{
    PlaySweep(0x400, 0x1000, 1, 0x200, 0x80);
}

/* asm: PlayFailSound @5E83
 *
 * A failure ("NO SPELL!", "-FAILED!", "NEED WAND OR STAFF!"): a rising chirp, divisor 800h down to
 * 0 in steps of 40h, each step 2 units shorter than the one before (100h to start). The last
 * divisor is 0, which the PIT takes as 65536 (18 Hz): the sound ends in a low buzz. */
void PlayFailSound(void)
{
    u16 divisor = 0x800;        /* asm: BX */
    u16 duration = 0x100;       /* asm: DX */

    if (SoundOff != 0)
        return;
    StartTone(divisor);
    do {
        HoldTone(divisor, duration);
        duration = (u16)(duration - 2);
        divisor = (u16)(divisor - 0x40);
    } while (divisor < 0x8000);                     /* jns: until it goes below zero */
    StopTone();
}
