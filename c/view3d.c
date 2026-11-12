/* view3d.c -- VIEW3D.ASM (original addresses 6000-6999) read as C: the 3D view of dungeons and towers.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/VIEW3D.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine, that it calls
 * the same routines at least as often, and that the tables match byte for byte. It cannot check
 * the logic.
 *
 * The first-person wireframe view. UpdateDungeonView (called by the dungeon turn after each turn
 * underground) reads the cells under, ahead of and behind the player and, while a light burns
 * (LightTurns), draws the view:
 *   - GetViewCells collects the cells of the 8 rows ahead (depth 0 is the player's own): the one
 *     to the left, the one in the line of sight and the one to the right, as the high nibble of the
 *     cell, and the low three bits of the middle one (a monster);
 *   - DrawViewWalls clears the screen and draws depth by depth the front wall (with a door), the
 *     left and right walls (with doors) or the openings at the sides, ladders and chests, until a
 *     wall blocks the view; ViewDepth is the depth being drawn;
 *   - DrawViewMonster draws the nearest monster from its shape in the monster buffer.
 * Every line goes through DrawViewLine: a Bresenham line from (PlotX, PlotY) to (LineEndX, LineEndY),
 * drawn with PlotPixel (so offset by PlotOriginX/PlotOriginY, 16, 16). The view is 256 x 128 pixels
 * and all its coordinates come from ViewCoordTbl, one row of numbers per kind of point, indexed by
 * depth.
 *
 * The map is the dungeon: level DungeonLevel is page DungeonLevel of the map buffer, 16x16 cells,
 * offset Y*16 + X. The cell's high nibble: 80h wall, C0h door, E0h secret door (drawn as a wall,
 * passable), 20h ladder down (D)escend), 10h ladder up (K)limb), 40h chest (G)et); the low bits a
 * monster (and 7, here). Position PlayerX, PlayerY and the facing FacingDX, FacingDY (signed bytes).
 *
 * The drawing routines are written the way the assembly writes them: each sets the start and end
 * point in the four variables and calls DrawViewLine, which leaves PlotX, PlotY at the end point so
 * that the next line continues from it.
 *
 * Also here, because they sit in the code segment at 6990-6998: the work variables of space flight
 * (SPACE, ENDGAME). The assembly's `mov di, bx` after each line (reloading the depth) has no
 * counterpart: the C keeps the depth in a local.
 *
 * See shops.c for the conventions shared by all the C files.
 */

#include "u2.h"

/* ---- The coordinates ------------------------------------------------------------------------ */

/* asm: ViewCoordTbl @620D check: none -- the screen coordinates of the 3D view, one row per kind of point,
 * each indexed by the depth d (0 is the player's cell); several rows are read at d+1, d+2, d+3 as well.
 * X runs 0-FFh and Y 0-7Fh; the right half mirrors the left (x' = FFh - x) and the bottom half the
 * top (y' = 7Fh - y). XL and XR have 10 entries (d+3 for d up to 6), the others 8. */

/* asm: ViewXL @620D -- x of the left edge of the depth-d rectangle */
static const u8 ViewXL[10] = { 0x00, 0x40, 0x60, 0x70, 0x78, 0x7C, 0x7E, 0x7F, 0x7F, 0x7F };

/* asm: ViewXR @6217 -- x of the right edge (FFh - XL) */
static const u8 ViewXR[10] = { 0xFF, 0xBF, 0x9F, 0x8F, 0x87, 0x83, 0x81, 0x80, 0x80, 0x80 };

/* asm: ViewYT @6221 -- y of the top edge */
static const u8 ViewYT[8] = { 0x00, 0x20, 0x30, 0x38, 0x3C, 0x3E, 0x3F, 0x3F };

/* asm: ViewYB @6229 -- y of the bottom edge (7Fh - YT) */
static const u8 ViewYB[8] = { 0x7F, 0x5F, 0x4F, 0x47, 0x43, 0x41, 0x40, 0x40 };

/* asm: ViewLNearX @6231 -- x of the near jamb of a left-wall door; [d+1]: ladder hole, near left corner */
static const u8 ViewLNearX[8] = { 0x10, 0x48, 0x64, 0x72, 0x79, 0x7C, 0x7F, 0x7F };

/* asm: ViewLFarX @6239 -- x of the far jamb of a left-wall door; [d+1]: ladder hole, far left corner */
static const u8 ViewLFarX[8] = { 0x30, 0x58, 0x6C, 0x76, 0x7B, 0x7C, 0x7F, 0x7F };

/* asm: ViewRNearX @6241 -- the same for the right wall: the near jamb; [d+1]: ladder hole, near right */
static const u8 ViewRNearX[8] = { 0xEF, 0xB7, 0x9B, 0x8D, 0x86, 0x83, 0x80, 0x80 };

/* asm: ViewRFarX @6249 -- the far jamb of a right-wall door; [d+1]: ladder hole, far right corner */
static const u8 ViewRFarX[8] = { 0xCF, 0xA7, 0x93, 0x89, 0x84, 0x83, 0x80, 0x80 };

/* asm: ViewFootNearY @6251 -- y of the foot of the near jamb of a side door; the bottom of a chest's front */
static const u8 ViewFootNearY[8] = { 0x77, 0x5B, 0x4D, 0x46, 0x42, 0x40, 0x40, 0x40 };

/* asm: ViewFootFarY @6259 -- y of the foot of the far jamb of a side door; the back edge of a chest */
static const u8 ViewFootFarY[8] = { 0x67, 0x53, 0x49, 0x44, 0x42, 0x40, 0x40, 0x40 };

/* asm: ViewDoorTopY @6261 -- y of the top of the far jamb of a side door (the near one is YT[d+1]) */
static const u8 ViewDoorTopY[8] = { 0x2A, 0x35, 0x3B, 0x3D, 0x3E, 0x3F, 0x3F, 0x3F };

/* asm: ViewCeilNearY @6269 -- y of the near edge of a ladder hole in the ceiling; the top of the pole */
static const u8 ViewCeilNearY[8] = { 0x08, 0x24, 0x32, 0x39, 0x3C, 0x3E, 0x3F, 0x3F };

/* asm: ViewCeilFarY @6271 -- y of the far edge of a ladder hole in the ceiling */
static const u8 ViewCeilFarY[8] = { 0x18, 0x2C, 0x36, 0x3A, 0x3D, 0x3E, 0x3F, 0x3F };

/* asm: ViewFloorNearY @6279 -- y of the near edge of a ladder hole in the floor; the foot of the pole */
static const u8 ViewFloorNearY[8] = { 0x77, 0x5B, 0x4D, 0x46, 0x43, 0x41, 0x40, 0x40 };

/* asm: ViewFloorFarY @6281 -- y of the far edge of a ladder hole in the floor */
static const u8 ViewFloorFarY[8] = { 0x67, 0x53, 0x49, 0x45, 0x42, 0x41, 0x40, 0x40 };

/* asm: ViewChestTopY @6289 -- y of the top of a chest's front */
static const u8 ViewChestTopY[8] = { 0x6F, 0x57, 0x4B, 0x45, 0x42, 0x40, 0x40, 0x40 };

/* asm: MonsterShapeOfsTbl @697E -- the offset of the generic monster shape in page 0 of the monster
 * buffer, by depth (depths 0 and 1 are not used: the near monster has its own shape): 80h, C0h,
 * E0h ... smaller shapes farther away. Padding follows. */
static const u8 MonsterShapeOfsTbl[18] = {
    0x00, 0x00, 0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00
};

/* ---- Space flight's variables (they only sit here) ------------------------------------------ */

/* asm: SpaceToneDivisor @6990 check: none -- the pitch of the hyperwarp sound (a divisor for HoldTone); a word in the code segment */
u16 SpaceToneDivisor;

/* asm: SpaceToneStep @6992 check: none -- its step per star (FFFFh or 1) */
u16 SpaceToneStep;

/* asm: BleepCountdown @6994 check: none -- star moves until the next toggle of the bleeps */
u16 BleepCountdown;

/* asm: StarRndSeed @6996 check: none -- the star generator's state (reset to 3Bh and 67h) */
u8 StarRndSeed;

/* asm: StarRndSeed2 @6997 check: none */
u8 StarRndSeed2;

/* asm: SpeakerIsOff @6998 check: none -- the speaker's state: FFh off, 0 on */
u8 SpeakerIsOff;

/* ---- Reading the dungeon -------------------------------------------------------------------- */

/* asm: GetDungeonCell @68C0
 *
 * The dungeon cell at (LookX, LookY) of the present level: page DungeonLevel of the map buffer,
 * offset LookY * 16 + LookX. The assembly forms the address from the level (as the high byte, added to
 * the buffer's high byte: the buffer's low byte is 0 and is ignored) and a low byte that is LookY * 16
 * (the four shifted-out bits lost) plus LookX plus the last bit shifted out, bit 4 of LookY (a
 * carry that is zero for Y below 16). That is the cell for X, Y below 16; the callers mask their
 * coordinates with 3Fh, so a position beyond 15 is read from some other cell of the page. */
static u8 GetDungeonCell(void)
{
    u8 low = (u8)((u8)(LookY << 4) + LookX + ((LookY >> 4) & 1));

    return MapBufPtr[(u16)(DungeonLevel << 8) + low];
}

/* asm: GetViewCells @6078
 *
 * The cells ahead, for depth d = 0 to 7. Three walkers start side by side: the left one at the
 * player's (X + dy, Y - dx), the middle one at the player's square, the right one at (X - dy, Y +
 * dx), where (dx, dy) is the facing (LineDX, LineDY). For each depth each walker reads its cell
 * (coordinates masked with 3Fh) and then steps one forward. ViewLeftCells[d] / ViewAheadCells[d] /
 * ViewRightCells[d] get the high nibble of the cell, ViewMonsters[d] the low three bits of the middle
 * one. (The walkers are PlotX/PlotY, LineEndX/LineEndY and LineStepX/LineStepY in the assembly.) */
static void GetViewCells(void)
{
    u8 lx, ly, mx, my, rx, ry;  /* left, middle, right walker */
    u8 cell;
    int d;

    mx = PlayerX;
    lx = (u8)(PlayerX + LineDY);
    ly = (u8)(PlayerY - LineDX);
    rx = (u8)(PlayerX - LineDY);
    my = PlayerY;
    ry = (u8)(PlayerY + LineDX);
    for (d = 0; d < 8; d++) {
        LookX = lx & 0x3F;
        lx = (u8)(LookX + LineDX);
        LookY = ly & 0x3F;
        ly = (u8)(LookY + LineDY);
        ViewLeftCells[d] = GetDungeonCell() & 0xF0;

        LookX = mx & 0x3F;
        mx = (u8)(LookX + LineDX);
        LookY = my & 0x3F;
        my = (u8)(LookY + LineDY);
        cell = GetDungeonCell();
        ViewAheadCells[d] = cell & 0xF0;
        ViewMonsters[d] = GetDungeonCell() & 7;

        LookX = rx & 0x3F;
        rx = (u8)(LookX + LineDX);
        LookY = ry & 0x3F;
        ry = (u8)(LookY + LineDY);
        ViewRightCells[d] = GetDungeonCell() & 0xF0;
    }
}

/* ---- Lines ---------------------------------------------------------------------------------- */

/* asm: DrawViewLine @67B3
 *
 * A line from (PlotX, PlotY) to (LineEndX, LineEndY), Bresenham in 8 bits. A pixel is plotted after
 * each step, so the start pixel itself is not (the previous line of a polyline ended there), and
 * nothing is drawn when the two ends are the same. It leaves PlotX, PlotY at the end point. Work:
 * LineDX, LineDY are |dx| and |dy|, LineStepX, LineStepY the steps (1 or FFh), LineCount the number
 * of steps (the larger of |dx|, |dy|) and LineErr the error term, which starts at half of it; each
 * step adds the smaller delta, and when that reaches the larger the larger is taken off and the other
 * coordinate steps too. (The 8-bit sums can wrap for a long, steep line; none is drawn.) */
static void DrawViewLine(void)
{
    if (LineEndX == PlotX && LineEndY == PlotY)
        return;

    LineDX = (u8)(LineEndX - PlotX);
    if (LineEndX >= PlotX) {
        LineStepX = 1;
    } else {
        LineDX = (u8)((LineDX ^ 0xFF) + 1);         /* |dx| */
        LineStepX = 0xFF;
    }
    LineDY = (u8)(LineEndY - PlotY);
    if (LineEndY >= PlotY) {
        LineStepY = 1;
    } else {
        LineDY = (u8)((LineDY ^ 0xFF) + 1);         /* |dy| */
        LineStepY = 0xFF;
    }

    if (LineDX >= LineDY) {                         /* step x every time, y when the error overflows */
        LineCount = LineDX;
        LineErr = LineCount >> 1;
        do {
            LineErr = (u8)(LineErr + LineDY);
            if (LineErr >= LineDX) {
                LineErr = (u8)(LineErr - LineDX);
                PlotY = (u8)(PlotY + LineStepY);
            }
            PlotX = (u8)(PlotX + LineStepX);
            PlotPixel();
        } while (--LineCount != 0);
    } else {                                        /* step y every time, x when it overflows */
        LineCount = LineDY;
        LineErr = LineCount >> 1;
        do {
            LineErr = (u8)(LineErr + LineDX);
            if (LineErr >= LineDY) {
                LineErr = (u8)(LineErr - LineDY);
                PlotX = (u8)(PlotX + LineStepX);
            }
            PlotY = (u8)(PlotY + LineStepY);
            PlotPixel();
        } while (--LineCount != 0);
    }
}

/* ---- The pieces of the picture -------------------------------------------------------------- */

/* asm: DrawLeftOpening @6291 -- the left side is open at depth d: the near corner edge (x = XL[d]) and the
 * face of the wall across the side passage (the rectangle edge at depth d+1). */
static void DrawLeftOpening(void)
{
    u8 d = ViewDepth;

    PlotX = LineEndX = ViewXL[d];
    PlotY = ViewYT[d];
    LineEndY = ViewYB[d];
    DrawViewLine();
    PlotY = LineEndY = ViewYT[d + 1];
    LineEndX = ViewXL[d + 1];
    DrawViewLine();
    LineEndY = ViewYB[d + 1];
    DrawViewLine();
    LineEndX = ViewXL[d];
    DrawViewLine();
}

/* asm: DrawRightOpening @6304 -- the right side open at depth d (the mirror of DrawLeftOpening). */
static void DrawRightOpening(void)
{
    u8 d = ViewDepth;

    PlotX = LineEndX = ViewXR[d];
    PlotY = ViewYT[d];
    LineEndY = ViewYB[d];
    DrawViewLine();
    PlotY = LineEndY = ViewYT[d + 1];
    LineEndX = ViewXR[d + 1];
    DrawViewLine();
    LineEndY = ViewYB[d + 1];
    DrawViewLine();
    LineEndX = ViewXR[d];
    DrawViewLine();
}

/* asm: DrawLeftWall @6377 -- the left wall at depth d: its top and bottom edges, from depth d to depth d+1. */
static void DrawLeftWall(void)
{
    u8 d = ViewDepth;

    PlotX = ViewXL[d];
    LineEndX = ViewXL[d + 1];
    PlotY = ViewYT[d];
    LineEndY = ViewYT[d + 1];
    DrawViewLine();
    LineEndX = ViewXL[d];
    LineEndY = ViewYB[d];
    PlotY = ViewYB[d + 1];
    DrawViewLine();
}

/* asm: DrawRightWall @63CE -- the right wall at depth d (the mirror of DrawLeftWall). */
static void DrawRightWall(void)
{
    u8 d = ViewDepth;

    PlotX = ViewXR[d];
    LineEndX = ViewXR[d + 1];
    PlotY = ViewYT[d];
    LineEndY = ViewYT[d + 1];
    DrawViewLine();
    LineEndX = ViewXR[d];
    LineEndY = ViewYB[d];
    PlotY = ViewYB[d + 1];
    DrawViewLine();
}

/* asm: DrawDepthRect @6425 -- the rectangle of depth d: the face of a wall ahead (for d = 0 the frame of
 * the view). Corners (XL, YT), (XR, YT), (XR, YB), (XL, YB). */
static void DrawDepthRect(void)
{
    u8 d = ViewDepth;

    PlotX = ViewXL[d];
    PlotY = LineEndY = ViewYT[d];
    LineEndX = ViewXR[d];
    DrawViewLine();
    LineEndY = ViewYB[d];
    DrawViewLine();
    LineEndX = ViewXL[d];
    DrawViewLine();
    LineEndY = ViewYT[d];
    DrawViewLine();
}

/* asm: DrawFrontDoor @648D -- a door in the wall ahead at depth d: two jambs at XL and XR of depth d+1
 * from the floor line YB[d] up to YT[d+1], and the lintel between them. */
static void DrawFrontDoor(void)
{
    u8 d = ViewDepth;

    PlotX = LineEndX = ViewXL[d + 1];
    PlotY = ViewYB[d];
    LineEndY = ViewYT[d + 1];
    DrawViewLine();
    LineEndX = ViewXR[d + 1];
    DrawViewLine();
    LineEndY = ViewYB[d];
    DrawViewLine();
}

/* asm: DrawLeftDoor @64E2 -- a door in the left wall at depth d: the near jamb (x LNearX, from FootNearY
 * up to YT[d+1]), the slanted top to the far jamb (x LFarX, top DoorTopY) and the far jamb down to
 * FootFarY. Open at the bottom. */
static void DrawLeftDoor(void)
{
    u8 d = ViewDepth;

    PlotX = LineEndX = ViewLNearX[d];
    PlotY = ViewFootNearY[d];
    LineEndY = ViewYT[d + 1];
    DrawViewLine();
    LineEndX = ViewLFarX[d];
    LineEndY = ViewDoorTopY[d];
    DrawViewLine();
    LineEndY = ViewFootFarY[d];
    DrawViewLine();
}

/* asm: DrawRightDoor @653F -- a door in the right wall at depth d (the mirror of DrawLeftDoor). */
static void DrawRightDoor(void)
{
    u8 d = ViewDepth;

    PlotX = LineEndX = ViewRNearX[d];
    PlotY = ViewFootNearY[d];
    LineEndY = ViewYT[d + 1];
    DrawViewLine();
    LineEndX = ViewRFarX[d];
    LineEndY = ViewDoorTopY[d];
    DrawViewLine();
    LineEndY = ViewFootFarY[d];
    DrawViewLine();
}

/* asm: DrawLadderPole @6684 -- the pole of a ladder at depth d: two vertical lines at x = 7Fh and 80h from
 * y = CeilNearY (the ceiling) to FloorNearY (the floor). */
static void DrawLadderPole(void)
{
    u8 d = ViewDepth;

    PlotX = LineEndX = 0x7F;
    PlotY = ViewCeilNearY[d];
    LineEndY = ViewFloorNearY[d];
    DrawViewLine();
    PlotX = LineEndX = 0x80;
    PlotY = ViewCeilNearY[d];
    LineEndY = ViewFloorNearY[d];
    DrawViewLine();
}

/* asm: DrawLadderDown @6594 -- a ladder down in the cell at depth d: the hole in the floor (a trapezoid
 * between the rows FloorNearY and FloorFarY, its x from the four Near and Far rows at d+1) and the pole. */
static void DrawLadderDown(void)
{
    u8 d = ViewDepth;

    PlotX = ViewLNearX[d + 1];
    LineEndX = ViewLFarX[d + 1];
    PlotY = ViewFloorNearY[d];
    LineEndY = ViewFloorFarY[d];
    DrawViewLine();
    LineEndX = ViewRFarX[d + 1];
    DrawViewLine();
    LineEndX = ViewRNearX[d + 1];
    LineEndY = ViewFloorNearY[d];
    DrawViewLine();
    LineEndX = ViewLNearX[d + 1];
    DrawViewLine();
    DrawLadderPole();
}

/* asm: DrawLadderUp @660C -- a ladder up in the cell at depth d: the hole in the ceiling (rows CeilNearY and
 * CeilFarY) and the pole. */
static void DrawLadderUp(void)
{
    u8 d = ViewDepth;

    PlotX = ViewLNearX[d + 1];
    LineEndX = ViewLFarX[d + 1];
    PlotY = ViewCeilNearY[d];
    LineEndY = ViewCeilFarY[d];
    DrawViewLine();
    LineEndX = ViewRFarX[d + 1];
    DrawViewLine();
    LineEndX = ViewRNearX[d + 1];
    LineEndY = ViewCeilNearY[d];
    DrawViewLine();
    LineEndX = ViewLNearX[d + 1];
    DrawViewLine();
    DrawLadderPole();
}

/* asm: DrawChest @66CB -- a chest in the cell at depth d, a box in oblique view: the front face from
 * (XL[d+2], ChestTopY) to (XR[d+3], FootNearY), the top face going back to the edge at y = FootFarY
 * between XL[d+3] and XR[d+2]. (Unlike the others it relies on the depth being in DI already.) */
static void DrawChest(void)
{
    u8 d = ViewDepth;

    PlotX = ViewXL[d + 2];
    PlotY = LineEndY = ViewChestTopY[d];
    LineEndX = ViewXR[d + 3];
    DrawViewLine();
    LineEndY = ViewFootNearY[d];
    DrawViewLine();
    LineEndX = ViewXL[d + 2];
    DrawViewLine();
    LineEndY = ViewChestTopY[d];
    DrawViewLine();
    LineEndX = ViewXL[d + 3];
    LineEndY = ViewFootFarY[d];
    DrawViewLine();
    LineEndX = ViewXR[d + 2];
    DrawViewLine();
    LineEndY = ViewChestTopY[d];
    DrawViewLine();
    LineEndX = ViewXR[d + 3];
    LineEndY = ViewFootNearY[d];
    DrawViewLine();
    PlotX = ViewXR[d + 3];
    PlotY = ViewChestTopY[d];
    LineEndX = ViewXR[d + 2];
    LineEndY = ViewFootFarY[d];
    DrawViewLine();
}

/* asm: DrawViewWalls @6144
 *
 * The walls: the screen is cleared and the frame (the depth-0 rectangle) drawn; then for depth d =
 * ViewDepth = 0, 1 ...:
 *   - a wall ahead (bit 7): its face; with a door (40h) and no secret (20h) the door is drawn too,
 *     and only a door in the player's own cell (depth 0) lets the view go on (to depth 7 at most);
 *     otherwise the view ends;
 *   - an open cell: a ladder down (20h), a ladder up (10h) or, if it is no ladder up, a chest (40h);
 *     then the left and right sides: a wall (with a door if it has 40h and not 20h) or the opening;
 *     and on to the next depth, up to 6.
 * ViewDepth is left at the last depth drawn (DrawViewMonster reads it). */
static void DrawViewWalls(void)
{
    u8 d;

    ClearViewArea();
    ViewDepth = 0;
    DrawDepthRect();                                /* the frame */
    for (;;) {
        d = ViewDepth;
        if (ViewAheadCells[d] & 0x80) {             /* a wall ahead */
            DrawDepthRect();
            if ((ViewAheadCells[d] & 0x40) == 0) return;
            if ((ViewAheadCells[d] & 0x20) != 0) return;
            DrawFrontDoor();
            if (ViewDepth != 0) return;
            ViewDepth++;
            if (ViewDepth >= 8) return;
            continue;
        }
        if (ViewAheadCells[d] & 0x20)
            DrawLadderDown();
        if (ViewAheadCells[d] & 0x10)
            DrawLadderUp();
        else if (ViewAheadCells[d] & 0x40)
            DrawChest();

        if (ViewLeftCells[d] & 0x80) {              /* left side */
            DrawLeftWall();
            if ((ViewLeftCells[d] & 0x40) && !(ViewLeftCells[d] & 0x20))
                DrawLeftDoor();
        } else {
            DrawLeftOpening();
        }
        if (ViewRightCells[d] & 0x80) {             /* right side */
            DrawRightWall();
            if ((ViewRightCells[d] & 0x40) && !(ViewRightCells[d] & 0x20))
                DrawRightDoor();
        } else {
            DrawRightOpening();
        }
        ViewDepth++;
        if (ViewDepth >= 7) return;
    }
}

/* ---- Monsters ------------------------------------------------------------------------------- */

/* asm: PlotShapeBlock @68A3 -- one 4x4-pixel block of a monster's shape at (WorkX * 4, WorkY * 4) with the
 * colour pattern BlockColor (0-7, an index into FillPatternTbl), by FillBlock4x4 (it overwrites). */
static void PlotShapeBlock(void)
{
    FillBlock4x4((u16)(WorkX * 4), (u16)(WorkY * 4), BlockColor);
}

/* asm: DrawViewMonster @68ED
 *
 * The nearest monster in the line of sight: from depth 1 up to the last depth drawn, the first d
 * with ViewMonsters[d] not 0 is drawn, and the routine ends. At depth 1 the monster has its own shape,
 * page ViewMonsters[d] of the monster buffer; farther away the type is dropped and a generic, smaller
 * shape is used, at offset MonsterShapeOfsTbl[d] of page 0. A shape is a list of byte pairs (X,
 * pattern * 32 + Y), 0 for X ending it; each pair is one 4x4 block. ViewDepth ends one more than it was. */
static void DrawViewMonster(void)
{
    const u8 *shape;
    u8 d;

    ViewDepth++;                                    /* the last depth + 1: the limit */
    for (d = 1; d < ViewDepth; d++) {
        if (ViewMonsters[d] == 0)
            continue;
        if (d == 1)
            shape = MonsterBufPtr + (u16)(ViewMonsters[d] << 8);    /* its own page (the buffer is page aligned) */
        else
            shape = MonsterBufPtr + MonsterShapeOfsTbl[d];
        while (*shape != 0) {
            WorkX = shape[0];
            WorkY = shape[1] & 0x1F;
            BlockColor = (u8)(shape[1] >> 5);
            shape += 2;
            PlotShapeBlock();
        }
        return;
    }
}

/* ---- The whole view ------------------------------------------------------------------------- */

/* asm: UpdateDungeonView @6000
 *
 * After each turn underground: while a light burns (LightTurns not 0) the cells ahead are collected,
 * the walls drawn and the nearest monster. Always: TileHere is the cell under the player, TileNorth
 * the cell ahead and TileSouth the one behind (full bytes, not just the nibble). LineDX, LineDY are
 * the facing; DrawViewLine uses them as |dx| and |dy|, so they are set again before the three
 * cells are read. */
void UpdateDungeonView(void)
{
    LineDX = FacingDX;
    LineDY = FacingDY;
    if (LightTurns != 0) {
        GetViewCells();
        DrawViewWalls();
        DrawViewMonster();
    }
    LineDX = FacingDX;
    LineDY = FacingDY;
    LookX = PlayerX;
    LookY = PlayerY;
    TileHere = GetDungeonCell();
    LookX = (u8)(PlayerX + LineDX);
    LookY = (u8)(PlayerY + LineDY);
    TileNorth = GetDungeonCell();
    LookX = (u8)(PlayerX - LineDX);
    LookY = (u8)(PlayerY - LineDY);
    TileSouth = GetDungeonCell();
}
