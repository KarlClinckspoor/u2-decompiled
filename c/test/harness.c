/* harness.c -- a test harness for the C in c/: runs it headless against stand-ins for the machine.
 *
 *     harness GAMEDIR WORKDIR "KEYS" [OUT.png]
 *
 * It calls ProgramEntry() (the program's start) and plays KEYS into the game; when the keys run
 * out and the game polls on with no key, it stops and shows the text screen and (in graphics mode)
 * writes the picture as a PNG. Files are read from WORKDIR if they are there and else from
 * GAMEDIR, and written to WORKDIR only: GAMEDIR is never changed.
 *
 * The stand-ins (all declared in u2.h):
 *   - the keyboard: the keys are given one at a time, each after a short run of empty polls (the
 *     game empties the keyboard buffer on every key, so type-ahead would be lost, as it is for a
 *     person); {ESC} {UP} {DOWN} {LEFT} {RIGHT} {ENTER} {BS} are special keys;
 *   - the text screen (40x25 characters, kept as text) and the CGA memory (VideoByte);
 *   - DOS FCB files, the ports (ignored: no sound), the BIOS tick count (fixed);
 *   - the data segment: the variables are separate C variables here; gen/gen_data.h (made by
 *     gendata.py from src/U2DATA.ASM) gives them their starting values and says where each one lies
 *     in the data segment, so that the PLAYER file (D:0036-0135) and the monster file
 *     (D:0137-0236), which the C reads and writes as one block, are moved to and from the variables.
 * HangForever and DivideError (the game's endless loops and its divide error) stop the run.
 */

#include <setjmp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../u2.h"

/* ---- Data segment --------------------------------------------------------------------------- */

u8 *MapCellPtr;
u8 *DungeonCellPtr;
u8 *MapBufPtr;
u8 *MonsterBufPtr;
const char *TalkBufPtr;
u8 *TilePtrTbl[64];
u8 PlayerRecord[256];

#include "gen/gen_data.h"

static u8 DS[D_END + 0x2000];       /* the data segment: initialised data, then the buffers and the stack */

static u16 word_at(const u8 *p) { return (u16)(p[0] | (p[1] << 8)); }

static void init_data(void)
{
    const struct VarEnt *v;
    int i;

    memcpy(DS, DataImage, D_END);
    for (v = Vars; v->p; v++)
        memcpy(v->p, DataImage + v->addr, v->size);
    MapBufPtr = DS + word_at(DataImage + A_MapBufPtr);
    MonsterBufPtr = DS + word_at(DataImage + A_MonsterBufPtr);
    TalkBufPtr = (const char *)(DS + word_at(DataImage + A_TalkBufPtr));
    for (i = 0; i < 64; i++)
        TilePtrTbl[i] = DS + word_at(DataImage + A_TilePtrTbl + 2 * i);
}

/* The PLAYER record and the monster table are one block each in the file. */
static void block_to_vars(const u8 *block, unsigned first, unsigned last)
{
    const struct VarEnt *v;

    for (v = Vars; v->p; v++)
        if (v->addr >= first && v->addr + v->size <= last)
            memcpy(v->p, block + (v->addr - first), v->size);
}

static void vars_to_block(u8 *block, unsigned first, unsigned last)
{
    const struct VarEnt *v;

    for (v = Vars; v->p; v++)
        if (v->addr >= first && v->addr + v->size <= last)
            memcpy(block + (v->addr - first), v->p, v->size);
}

static u8 MonsterBlock[0x100];

/* ---- Running and stopping ------------------------------------------------------------------- */

static jmp_buf Stop;
static const char *StopReason;

static void stop(const char *why)
{
    StopReason = why;
    longjmp(Stop, 1);
}

void HangForever(void) { stop("the game hangs (an endless loop)"); }
void DivideError(void) { stop("divide error"); }

/* ---- Keys ----------------------------------------------------------------------------------- */

static unsigned KeyQueue[512];
static int KeyHead, KeyTail;
static long EmptyPolls;             /* polls since the last key, or since the last key was given */
#define KEY_GAP 50                  /* empty polls before the next key arrives */
static long GiveUp = 3000;             /* empty polls with no keys left: the run is over (env U2_GIVEUP) */

static void queue_keys(const char *s)
{
    static const struct { const char *name; unsigned code; } special[] = {
        { "{ESC}", 0x011B }, { "{UP}", 0x4800 }, { "{DOWN}", 0x5000 }, { "{LEFT}", 0x4B00 },
        { "{RIGHT}", 0x4D00 }, { "{ENTER}", 0x1C0D }, { "{BS}", 0x0E08 }, { "{CTRL-RIGHT}", 0x7400 },
        { "{CTRL-LEFT}", 0x7300 }, { "{CTRL-S}", 0x1F13 }
    };
    unsigned i;
    int found;

    while (*s) {
        found = 0;
        for (i = 0; i < sizeof special / sizeof special[0]; i++) {
            size_t n = strlen(special[i].name);
            if (strncmp(s, special[i].name, n) == 0) {
                KeyQueue[KeyTail++] = special[i].code;
                s += n;
                found = 1;
                break;
            }
        }
        if (!found)
            KeyQueue[KeyTail++] = (unsigned)(unsigned char)*s++;
    }
}

bool BiosKeyWaiting(void)
{
    if (KeyHead < KeyTail) {
        if (EmptyPolls >= KEY_GAP)
            return true;
        EmptyPolls++;
        return false;
    }
    if (++EmptyPolls > GiveUp)
        stop("out of keys");
    return false;
}

u16 BiosReadKey(void)
{
    EmptyPolls = 0;
    return (u16)KeyQueue[KeyHead++];
}

u8 ReadAsciiKey(void)
{
    u16 k;

    for (;;) {
        k = ReadKey();
        if ((k >> 8) == 0xFF)
            return (u8)k;
    }
}

/* ---- Screen --------------------------------------------------------------------------------- */

/* The BIOS writes a character at the cell row * 40 + column of the text memory, so column 40 is column 0 of the next row. */
static char Text[25 * 40];
static int CurRow, CurCol;
static int VideoMode = 3;
static u8 Video[0x8000];            /* B8000-BFFFF */
static long VideoFaults;

static void clear_text(void)
{
    memset(Text, ' ', sizeof Text);
}

void BiosSetVideoMode(u8 mode)
{
    VideoMode = mode;
    clear_text();
    if (mode == 4)
        memset(Video, 0, sizeof Video);
}

void BiosSetColour(u8 which, u8 value) { (void)which; (void)value; }

void BiosSetCursor(u8 row, u8 col) { CurRow = row; CurCol = col; }

void BiosWriteChar(u8 c, u8 attr)
{
    (void)attr;
    if (CurRow * 40 + CurCol < 25 * 40)
        Text[CurRow * 40 + CurCol] = (char)((c >= 32 && c < 127) ? c : '?');
    else
        stop("BiosWriteChar off the screen");
}

void BiosScrollUp(u8 lines, u8 top, u8 left, u8 bottom, u8 right)
{
    int r, c;

    (void)lines;
    if (right > 39) right = 39;
    for (r = top; r < bottom; r++)
        for (c = left; c <= right; c++)
            Text[r * 40 + c] = Text[(r + 1) * 40 + c];
    for (c = left; c <= right; c++)
        Text[bottom * 40 + c] = ' ';
}

u8 *VideoByte(u16 segment, u16 offset)
{
    unsigned lin = (unsigned)segment * 16u + offset;

    if (lin < 0xB8000u || lin >= 0xC0000u) {
        VideoFaults++;
        stop("write outside the CGA memory");
    }
    return &Video[lin - 0xB8000u];
}

static void show_text(FILE *f)
{
    int r;

    for (r = 0; r < 25; r++)
        fprintf(f, "|%.40s|\n", Text + r * 40);
}

/* A PNG of the graphics screen (320x200, palette 1: black, cyan, magenta, white), doubled in size. */
static unsigned crc_table[256];

static unsigned crc32_update(unsigned crc, const u8 *p, size_t n)
{
    size_t i;
    int k;

    if (!crc_table[1]) {
        for (i = 0; i < 256; i++) {
            unsigned c = (unsigned)i;
            for (k = 0; k < 8; k++)
                c = (c & 1) ? 0xEDB88320u ^ (c >> 1) : c >> 1;
            crc_table[i] = c;
        }
    }
    crc = ~crc;
    for (i = 0; i < n; i++)
        crc = crc_table[(crc ^ p[i]) & 0xFF] ^ (crc >> 8);
    return ~crc;
}

static void put32(u8 *p, unsigned v) { p[0] = (u8)(v >> 24); p[1] = (u8)(v >> 16); p[2] = (u8)(v >> 8); p[3] = (u8)v; }

static void png_chunk(FILE *f, const char *type, const u8 *data, size_t n)
{
    u8 head[8], tail[4];
    unsigned crc;

    put32(head, (unsigned)n);
    memcpy(head + 4, type, 4);
    fwrite(head, 1, 8, f);
    if (n) fwrite(data, 1, n, f);
    crc = crc32_update(0, head + 4, 4);
    crc = crc32_update(crc, data, n);   /* (crc32_update continues from a finished crc) */
    {
        u8 buf[4 + 65536];
        memcpy(buf, type, 4);
        if (n > 65536) n = 65536;
        memcpy(buf + 4, data, n);
        crc = crc32_update(0, buf, 4 + n);
    }
    put32(tail, crc);
    fwrite(tail, 1, 4, f);
}

static void write_png(const char *path)
{
    enum { W = 640, H = 400 };
    static const u8 pal[4][3] = { {0, 0, 0}, {0x55, 0xFF, 0xFF}, {0xFF, 0x55, 0xFF}, {0xFF, 0xFF, 0xFF} };
    static u8 raw[(1 + W * 3) * H];
    static u8 z[sizeof raw + sizeof raw / 65535 * 5 + 64];
    u8 hdr[13];
    size_t i, zn = 0, pos = 0;
    unsigned a = 1, b = 0;
    int x, y;
    FILE *f;

    for (y = 0; y < H; y++) {
        u8 *row = raw + (size_t)y * (1 + W * 3);
        row[0] = 0;
        for (x = 0; x < W; x++) {
            int sx = x / 2, sy = y / 2, c = 0;
            if (sy < 160) {
                unsigned off = (sy & 1 ? 0x2000u : 0u) + 80u * (unsigned)(sy / 2) + (unsigned)(sx / 4);
                c = (Video[off] >> (6 - 2 * (sx & 3))) & 3;
            }
            memcpy(row + 1 + x * 3, pal[c], 3);
        }
    }
    z[zn++] = 0x78; z[zn++] = 0x01;
    while (pos < sizeof raw) {
        size_t n = sizeof raw - pos > 65535 ? 65535 : sizeof raw - pos;
        z[zn++] = (pos + n == sizeof raw) ? 1 : 0;
        z[zn++] = (u8)n; z[zn++] = (u8)(n >> 8); z[zn++] = (u8)~n; z[zn++] = (u8)(~n >> 8);
        memcpy(z + zn, raw + pos, n);
        zn += n;
        pos += n;
    }
    for (i = 0; i < sizeof raw; i++) { a = (a + raw[i]) % 65521; b = (b + a) % 65521; }
    put32(z + zn, (b << 16) | a);
    zn += 4;
    f = fopen(path, "wb");
    if (!f) return;
    fwrite("\x89PNG\r\n\x1a\n", 1, 8, f);
    put32(hdr, W); put32(hdr + 4, H);
    hdr[8] = 8; hdr[9] = 2; hdr[10] = 0; hdr[11] = 0; hdr[12] = 0;
    png_chunk(f, "IHDR", hdr, 13);
    {   /* IDAT: chunks of at most 65536 bytes */
        size_t at = 0;
        while (at < zn) {
            size_t n = zn - at > 60000 ? 60000 : zn - at;
            png_chunk(f, "IDAT", z + at, n);
            at += n;
        }
    }
    png_chunk(f, "IEND", hdr, 0);
    fclose(f);
}

/* ---- DOS files ------------------------------------------------------------------------------ */

static const char *GameDir, *WorkDir;
static void *Dta;
static bool DtaOnScreen;

static void fcb_path(const u8 *fcb, const char *dir, char *out)
{
    char name[9];
    int n = 8;

    memcpy(name, fcb + 1, 8);
    while (n > 0 && name[n - 1] == ' ') n--;
    name[n] = 0;
    sprintf(out, "%s/%s", dir, name);
}

u8 DosOpenFcb(u8 *fcb)
{
    char path[512];
    FILE *f;

    fcb_path(fcb, WorkDir, path);
    f = fopen(path, "rb");
    if (!f) {
        fcb_path(fcb, GameDir, path);
        f = fopen(path, "rb");
    }
    if (!f) {
        fprintf(stderr, "[file not found: %.8s]\n", fcb + 1);
        return 1;
    }
    fclose(f);
    return 0;
}

void DosSetDta(void *buffer, bool onto_screen)
{
    Dta = buffer;
    DtaOnScreen = onto_screen;
}

void DosRandomBlock(u8 function, u8 *fcb, u16 count)
{
    char path[512];
    FILE *f;
    u8 *buf;
    u8 tmp[0x4000];
    u16 got = 0;
    bool is_player = (Dta == (void *)PlayerRecord);
    bool is_monsters = (Dta == (void *)MonsterX);

    if (function == 0x28) {                         /* write */
        if (count > sizeof tmp) stop("write too long");
        if (DtaOnScreen)
            stop("write from the screen");
        if (is_player) { vars_to_block(PlayerRecord, 0x36, 0x136); buf = PlayerRecord; }
        else if (is_monsters) { vars_to_block(MonsterBlock, 0x137, 0x237); buf = MonsterBlock; }
        else buf = (u8 *)Dta;
        fcb_path(fcb, WorkDir, path);
        f = fopen(path, "wb");
        if (!f) stop("cannot write to the work directory");
        fwrite(buf, 1, count, f);
        fclose(f);
        return;
    }
    fcb_path(fcb, WorkDir, path);                   /* read */
    f = fopen(path, "rb");
    if (!f) {
        fcb_path(fcb, GameDir, path);
        f = fopen(path, "rb");
    }
    if (!f) stop("file vanished");
    if (count > sizeof tmp) count = sizeof tmp;
    got = (u16)fread(tmp, 1, count, f);
    fclose(f);
    if (got < count)
        memset(tmp + got, 0, count - got);
    if (DtaOnScreen) {
        u16 i;
        for (i = 0; i < count; i++)
            *VideoByte(0xB800, i) = tmp[i];         /* B800:0000 */
    } else if (is_player) {
        memcpy(PlayerRecord, tmp, 0x100);
        block_to_vars(PlayerRecord, 0x36, 0x136);
    } else if (is_monsters) {
        memcpy(MonsterBlock, tmp, 0x100);
        block_to_vars(MonsterBlock, 0x137, 0x237);
    } else {
        memcpy(Dta, tmp, count);
    }
}

void DosCloseFcb(u8 *fcb) { (void)fcb; }

/* ---- The rest of the machine ---------------------------------------------------------------- */

void OutPort(u16 port, u8 value) { (void)port; (void)value; }
u8 InPort(u16 port) { (void)port; return 0; }
u8 BiosTickLow(void) { return 0x42; }

/* ---- Main ----------------------------------------------------------------------------------- */

int main(int argc, char **argv)
{
    const char *png = "harness.png";

    if (argc < 4) {
        fprintf(stderr, "usage: harness GAMEDIR WORKDIR \"KEYS\" [OUT.png]\n");
        return 2;
    }
    if (getenv("U2_GIVEUP")) GiveUp = atol(getenv("U2_GIVEUP"));
    GameDir = argv[1];
    WorkDir = argv[2];
    if (argc > 4) png = argv[4];
    queue_keys(argv[3]);
    init_data();
    clear_text();
    if (setjmp(Stop) == 0)
        ProgramEntry();
    printf("stopped: %s (keys left: %d)\n", StopReason, KeyTail - KeyHead);
    printf("video mode %d, cursor row %d col %d, player at %d,%d, map type %d\n",
           VideoMode, CurRow, CurCol, PlayerX, PlayerY, MapType);
    show_text(stdout);
    if (VideoMode == 4) {
        write_png(png);
        printf("picture: %s\n", png);
    }
    return 0;
}
