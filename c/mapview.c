/* mapview.c -- MAPVIEW.ASM (original addresses 5AB1-5C90) read as C: the map window.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/MAPVIEW.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine, that it prints
 * the same texts and that it calls the same routines at least as often. It cannot check the logic.
 *
 * UpdateMapView, the one routine, fills the window of 20 x 10 tiles of the 64x64 map around the
 * player (PlayerX, PlayerY), who is in column 9, row 5, and has it drawn. The assembly has two
 * copies of the loop: for maps that wrap round (OffMapTile FFh: the outdoor maps; coordinates are
 * taken mod 64) and for maps with an edge (towns, castles), outside of which every square shows
 * the tile OffMapTile. Here it is one loop with the test.
 *
 * A map byte is the tile number times 4; the window caches hold the tile number times 2 (the
 * offset of the picture's pointer in TilePtrTbl). TileCache is the new window, TileCacheShown what
 * the screen shows. A cell that has not changed gets bit 7 set in TileCache and DrawMapWindow
 * skips it, except water (0, unless the plane is flying) and the force field (2Eh): those are
 * animated and are always drawn again.
 *
 * It also leaves the tiles under and around the player in TileHere, TileNorth, TileSouth, TileEast
 * and TileWest (cache values: bit 7 may be set, callers mask it), and puts the player's own picture
 * (PlayerTile) in the middle cell.
 *
 * The assembly's scratch (FacingDX, FacingDY: the map square at the window's top left; WorkX, WorkY:
 * the cell being filled; MapCellPtr: the address read) is local here; the one byte in the code
 * segment, MapViewCol, sits in the padding of CHARGEN (the map x in the wrapping version).
 *
 * See shops.c for the conventions shared by all the C files.
 */

#include "u2.h"

/* asm: MapViewCol @5AB0 check: none -- the map column being read, a work byte in the code segment (in
 * the wrapping loop only); a local variable in the C. */

/* asm: UpdateMapView @5AB1 also: @5B98 @5C6D
 *
 * See the header. The window's top-left square is (PlayerX - 9, PlayerY - 5), taken mod 64 on a
 * wrapping map. On a map with an edge a square whose x or y is outside 0-63 (a negative one is
 * above 7Fh) shows OffMapTile. The cell index is 20 * row + column; the cells that matter later are
 * 6Dh (the middle: row 5, column 9), 59h north of it, 81h south, 6Ch west and 6Eh east.
 * The picture of the changed cells is drawn by DrawMapWindow; then TileCacheShown remembers what is on
 * the screen (the cache without bit 7). The copy runs over 240 bytes though the window has only 200
 * cells (the rest are never drawn). */
void UpdateMapView(void)
{
    bool wrap = (OffMapTile == 0xFF);
    u8 top_y, left_x;           /* asm: FacingDY, FacingDX */
    u8 row, col;                /* asm: WorkY, WorkX */
    u8 map_x, map_y, tile;
    int cell = 0;               /* asm: DI */

    top_y = (u8)(PlayerY - 5);
    left_x = (u8)(PlayerX - 9);
    if (wrap) {
        top_y &= 0x3F;
        left_x &= 0x3F;
    }
    for (row = 0; row < 10; row++) {
        for (col = 0; col < 20; col++) {
            map_x = (u8)(col + left_x);
            map_y = (u8)(row + top_y);
            if (wrap) {
                map_x &= 0x3F;                      /* asm: MapViewCol */
                map_y &= 0x3F;
                tile = (u8)((MapBufPtr[map_y * 64 + map_x] >> 1) & 0xFE);
            } else if (map_x >= 0x40 || map_y >= 0x40) {
                tile = OffMapTile;                  /* outside the map: the border tile */
            } else {
                tile = (u8)((MapBufPtr[map_y * 64 + map_x] >> 1) & 0xFE);
            }
            /* unchanged since the last draw: mark it with bit 7, except the animated tiles */
            if (tile == TileCacheShown[cell]) {
                if (tile == 0) {
                    if (PlaneFlying == 0xFF)
                        tile |= 0x80;
                } else if (tile != 0x2E) {
                    tile |= 0x80;
                }
            }
            TileCache[cell++] = tile;
        }
    }

    TileHere = TileCache[0x6D];
    TileNorth = TileCache[0x59];
    TileSouth = TileCache[0x81];
    TileWest = TileCache[0x6C];
    TileEast = TileCache[0x6E];
    TileCache[0x6D] = PlayerTile;                   /* the player's picture, always drawn */

    DrawMapWindow();
    for (cell = 0; cell < 0xF0; cell++)
        TileCacheShown[cell] = (u8)(TileCache[cell] & 0x7F);
}
