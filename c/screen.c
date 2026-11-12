/* screen.c -- SCREEN.ASM (original addresses 48CD-4C60) read as C: the graphics of the CGA screen.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/SCREEN.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine, that it prints
 * the same texts and that it calls the same routines at least as often, and that the tables match
 * byte for byte. It cannot check the logic.
 *
 * The screen is BIOS mode 4: CGA 320x200 in four colours, two bits a pixel, 80 bytes a scan line,
 * the even lines in the bank at B800:0000 and the odd lines in the one at BA00:0000. Only the top 160
 * scan lines (the map and 3D view window) are drawn by the game itself; the text rows below are
 * written by TEXTIO through the BIOS. Instead of computing line * 80 the assembly takes a SEGMENT for
 * each scan line from a table (CgaLineSegTbl) and uses x / 4 as the offset in it: a line is 5
 * paragraphs (80 bytes) after the one two before it. The C asks for the video memory with VideoByte
 * (u2.h): the byte at segment:offset of the CGA's two banks.
 *
 * What the C leaves out: the registers the routines save and restore, and the original's
 * three zero padding bytes at 48CD and eleven at 4C55.
 *
 * See shops.c for the conventions shared by all the C files.
 */

#include <string.h>
#include "u2.h"

/* ---- Tables --------------------------------------------------------------------------------- */

/* asm: PixelMaskTbl @48D0 -- the mask of a pixel in its byte by x mod 4: two bits a pixel, the
 * leftmost in the high bits. */
static const u8 PixelMaskTbl[4] = { 0xC0, 0x30, 0x0C, 0x03 };

/* asm: FillPatternTbl @48D4 -- the fill bytes of FillBlock4x4: FFh is four pixels of colour 3;
 * 11h, 88h, CCh and 33h are two-colour dithers; the last three entries are 0 (black). */
static const u8 FillPatternTbl[8] = { 0xFF, 0x11, 0x88, 0xCC, 0x33, 0x00, 0x00, 0x00 };

/* asm: CgaLineSegTbl @48DC check: none
 *
 * The video segment of scan line 0-159, a table of words in the assembly (and CgaLineSegTbl1 @48DE
 * is the same table one line on): B800h + 5 * (line / 2) for an even line, BA00h + 5 * (line / 2)
 * for an odd one. Written as the formula here; all 160 entries were compared with the
 * assembly's bytes. The pixel byte of (x, y) is then at segment CgaLineSeg(y), offset x / 4. */
static u16 CgaLineSeg(u16 line)
{
    return (u16)(((line & 1) ? 0xBA00 : 0xB800) + 5 * (line / 2));
}

/* ---- The two screen modes ------------------------------------------------------------------- */

/* asm: SetTextMode @4A1C -- 40x25 colour text (BIOS mode 1, which also clears the screen), the
 * cursor at (0, 0), the message window's right edge at column 40, GraphicsMode 0 and the normal
 * text attribute. */
void SetTextMode(void)
{
    BiosSetVideoMode(1);
    CursorCol = 0;
    CursorRow = 0;
    UpdateBiosCursor();
    TextRightCol = 0x28;
    GraphicsMode = 0;
    SetTextNormal();
}

/* asm: SetGraphicsMode @4A3E -- CGA graphics (BIOS mode 4, which clears the screen), black
 * background, palette 1 (cyan, magenta, white); GraphicsMode 1 and the normal text colour; and
 * both tile caches filled with FFh (no tile is FFh), so that the next UpdateMapView draws every
 * tile again. */
void SetGraphicsMode(void)
{
    BiosSetVideoMode(4);
    BiosSetColour(0, 0);                            /* the background: black */
    BiosSetColour(1, 1);                            /* palette 1 */
    GraphicsMode = 1;
    SetTextNormal();
    memset(TileCache, 0xFF, sizeof TileCache);
    memset(TileCacheShown, 0xFF, sizeof TileCacheShown);
}

/* ---- Tiles ---------------------------------------------------------------------------------- */

/* asm: DrawTile @4A74
 *
 * A 16x16 tile copied (not XORed) to the screen at pixel column x (a multiple of 4) and scan line y
 * (0-144). The tile is a record of 2 header bytes (04h, 10h: 4 bytes a line, 16 lines) and 16
 * lines of 4 bytes. */
static void DrawTile(u16 x, u16 y, const u8 *tile)
{
    u16 offset = (u16)(x >> 2);
    int line, i;

    tile += 2;                                      /* the header */
    for (line = 0; line < 16; line++) {
        u16 segment = CgaLineSeg((u16)(y + line));
        for (i = 0; i < 4; i++)
            *VideoByte(segment, (u16)(offset + i)) = tile[i];
        tile += 4;
    }
}

/* asm: DrawMapWindow @4AAD
 *
 * The map window: 20 columns by 10 rows of 16x16 tiles (320x160 pixels) from the tile cache,
 * row by row. A cache byte is the tile number times 2 (the offset of its pointer in TilePtrTbl);
 * with bit 7 set the tile is unchanged and is skipped. */
void DrawMapWindow(void)
{
    u16 x, y;
    int si = 0;                 /* index into TileCache */
    u8 cl;

    for (y = 0; y < 0xA0; y += 0x10) {
        for (x = 0; x < 0x140; x += 0x10) {
            cl = TileCache[si++];
            if (cl & 0x80)
                continue;
            DrawTile(x, y, TilePtrTbl[cl >> 1]);
        }
    }
}

/* asm: RotateTileUp @4AFC -- a tile's picture scrolled up one line: lines 1-15 become 0-14 and the
 * old line 0 becomes line 15. (The tile record is 2 header bytes and 16 lines of 4 bytes.) */
static void RotateTileUp(u8 *tile)
{
    u8 first[4];

    memcpy(first, tile + 2, 4);
    memmove(tile + 2, tile + 6, 60);
    memcpy(tile + 62, first, 4);
}

/* asm: AnimateWater @4AE6 -- the water tile's (tile 0's) picture scrolls up one line; the screen
 * shows it when the water tiles are drawn again. */
void AnimateWater(void)
{
    RotateTileUp(TilePtrTbl[0]);
}

/* asm: AnimateForceField @4AF1 -- the same for the force field (tile 17h = cache value 2Eh,
 * the one MOVE treats as a force field; ForceFieldTilePtr is TilePtrTbl + 2Eh). */
void AnimateForceField(void)
{
    RotateTileUp(TilePtrTbl[0x17]);
}

/* ---- Clearing and flashing ------------------------------------------------------------------ */

/* asm: InvertCgaBank @4B35 -- the first 1900h bytes of one bank (80 lines of 80 bytes) XORed with FFh. */
static void InvertCgaBank(u16 segment)
{
    u16 off;

    for (off = 0; off != 0x1900; off++)
        *VideoByte(segment, off) ^= 0xFF;
}

/* asm: InvertViewArea @4B26 -- the whole window (scan lines 0-159, both banks) inverted: the flash
 * when the player is hit or something magic happens; twice restores the picture. */
void InvertViewArea(void)
{
    InvertCgaBank(0xB800);                          /* the even lines */
    InvertCgaBank(0xBA00);                          /* the odd lines */
}

/* asm: ClearCgaBank @4B5D -- the first 1900h bytes of one bank zeroed. */
static void ClearCgaBank(u16 segment)
{
    u16 off;

    for (off = 0; off != 0x1900; off++)
        *VideoByte(segment, off) = 0;
}

/* asm: ClearViewArea @4B4E -- the window (scan lines 0-159) black; the text rows are not touched. */
void ClearViewArea(void)
{
    ClearCgaBank(0xB800);
    ClearCgaBank(0xBA00);
}

/* ---- Pixels and blocks ---------------------------------------------------------------------- */

/* asm: PlotPixel @4B76 -- one pixel to colour 3 (white) at x = PlotX + PlotOriginX, y = PlotY +
 * PlotOriginY (both origins are 16: the corner of the 3D view). */
void PlotPixel(void)
{
    u16 x = (u16)(PlotX + PlotOriginX);
    u16 y = (u16)(PlotY + PlotOriginY);

    *VideoByte(CgaLineSeg(y), (u16)(x >> 2)) |= PixelMaskTbl[x & 3];
}

/* asm: ErasePixel @4BAA -- the same pixel back to colour 0. */
void ErasePixel(void)
{
    u16 x = (u16)(PlotX + PlotOriginX);
    u16 y = (u16)(PlotY + PlotOriginY);

    *VideoByte(CgaLineSeg(y), (u16)(x >> 2)) &= (u8)(PixelMaskTbl[x & 3] ^ 0xFF);
}

/* asm: FillBlock4x4 @4BE0
 *
 * A block of 4x4 pixels (one byte on each of four scan lines) filled with the pattern byte
 * FillPatternTbl[pattern], at x = x + PlotOriginX (a multiple of 4), y = y + PlotOriginY (even).
 * Lines y and y+2 are in one bank (80 bytes apart), y+1 and y+3 in the other. Used once, by the 3D
 * view. */
void FillBlock4x4(u16 x, u16 y, u16 pattern)
{
    u16 offset = (u16)((x + PlotOriginX) >> 2);
    u8 fill = FillPatternTbl[pattern];
    u16 line = (u16)(y + PlotOriginY);

    *VideoByte(CgaLineSeg(line), offset) = fill;
    *VideoByte(CgaLineSeg(line), (u16)(offset + 0x50)) = fill;          /* line y+2: same bank, 80 bytes on */
    *VideoByte(CgaLineSeg((u16)(line + 1)), offset) = fill;
    *VideoByte(CgaLineSeg((u16)(line + 1)), (u16)(offset + 0x50)) = fill;   /* line y+3 */
}

/* asm: XorBitmapCS @4C1E
 *
 * A 16x16 picture in the format of DrawTile (here from the code segment) XORed onto the screen at
 * pixel column x (a multiple of 4) and scan line y, without PlotOrigin; drawing it twice erases it.
 * Its only caller is XorAttackMark (the attack mark). */
void XorBitmapCS(u16 x, u16 y, const u8 *bitmap)
{
    u16 offset = (u16)(x >> 2);
    int line, i;

    bitmap += 2;
    for (line = 0; line < 16; line++) {
        u16 segment = CgaLineSeg((u16)(y + line));
        for (i = 0; i < 4; i++)
            *VideoByte(segment, (u16)(offset + i)) ^= bitmap[i];
        bitmap += 4;
    }
}
