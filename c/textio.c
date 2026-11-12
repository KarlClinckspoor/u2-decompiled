/* textio.c -- TEXTIO.ASM (original addresses 4C60-5400) read as C: the support library for text,
 * keys, numbers, random numbers and files.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/TEXTIO.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine, that it prints
 * the same texts and that it calls the same routines at least as often, and that the tables
 * match byte for byte. It cannot check the logic.
 *
 * What the C stands in for: the BIOS (keyboard int 16h, video int 10h) and DOS (FCB file calls
 * int 21h). Those are the Bios... and Dos... routines declared in u2.h; everything else here is
 * the game's own.
 *
 * Text goes through the BIOS at the cursor (CursorCol, CursorRow) with the attribute TextAttr, in
 * text and in graphics mode alike. The message window is rows 20-23 from column TextLeftCol to
 * TextRightCol; it scrolls up one line when the cursor leaves row 23.
 *
 * Not translated: three runs of dead code (a second sign routine at 50E4, a delay loop at 5380,
 * zero padding at 53F8): nothing calls them. The assembly's inline text (the string after
 * `call PrintInline`) is a parameter here.
 *
 * See shops.c for the conventions shared by all the C files.
 */

#include <string.h>
#include "u2.h"

/* ---- Names ---------------------------------------------------------------------------------- */

/* asm: NameStrTbl @4C60 -- the names PrintNameStr prints: a zero byte, then zero-terminated strings
 * numbered from 1: 1-18 terrain ("IN THE WATER." ... "ON COBBLE."), 19-28 weapons (HANDS ... QUICK
 * SWORD), 29-35 armour (SKIN ... POWER), 36-45 spells (NONE ... KILL), 46-53 items (RING ... ANKH),
 * 54-61 special items (RED GEM ... TRI-LITHIUM), 62-67 attributes (STRENGTH ... INTELL.),
 * 68-71 races (HUMAN ... HOBBIT), 72-75 classes (FIGHTER ... THIEF). */
static const char NameStrTbl[] =
    "\0"
    "IN THE WATER.\0"
    "IN A MARSH.\0"
    "ON GRASS.\0"
    "IN WOODS.\0"
    "IN THE MTS.\0"
    "NEAR A VILLAGE.\0"
    "NEAR A TOWNE.\0"
    "NEAR A TOWER.\0"
    "NEAR A CASTLE.\0"
    "NEAR A DUNGEON.\0"
    "NEAR A SIGN.\0"
    "NEAR A HORSE.\0"
    "NEAR A FRIGATE.\0"
    "NEAR A PLANE.\0"
    "NEAR A ROCKET.\0"
    "NEAR ARMOUR.\0"
    "NEAR A HOLE.\0"
    "ON COBBLE.\0"
    "HANDS\0"
    "DAGGER\0"
    "MACE\0"
    "AXE\0"
    "BOW\0"
    "SWORD\0"
    "GREAT SWORD\0"
    "LIGHT SWORD\0"
    "PHASER\0"
    "QUICK SWORD\0"
    "SKIN\0"
    "CLOTH\0"
    "LEATHER\0"
    "CHAIN\0"
    "PLATE\0"
    "REFLECT\0"
    "POWER\0"
    "NONE\0"
    "LIGHT\0"
    "DOWN LADDER\0"
    "UP LADDER\0"
    "PASSWALL\0"
    "SURFACE\0"
    "PRAYER\0"
    "MAGIC MISSILE\0"
    "BLINK\0"
    "KILL\0"
    "RING\0"
    "WAND\0"
    "STAFF\0"
    "BOOTS\0"
    "CLOAK\0"
    "HELM\0"
    "GEM\0"
    "ANKH\0"
    "RED GEM\0"
    "SKULL KEY\0"
    "GREEN GEM\0"
    "BRASS BUTTON\0"
    "BLUE TASSLE\0"
    "STRANGE COIN\0"
    "GREEN IDOL\0"
    "TRI-LITHIUM\0"
    "STRENGTH\0"
    "AGILITY\0"
    "STAMINA\0"
    "CHARISMA\0"
    "WISDOM\0"
    "INTELL.\0"
    "HUMAN\0"
    "ELF\0"
    "DWARF\0"
    "HOBBIT\0"
    "FIGHTER\0"
    "CLERIC\0"
    "WIZARD\0"
    "THIEF";

/* asm: ArrowScanTbl @4F09 check: none -- (scan code, key) pairs for the arrow keys, as ReadKey reads
 * them: the table's bytes are 48h 0Eh 50h 19h 4Dh 05h 4Bh 17h. Up (48h) is north 0Eh, down (50h)
 * south 19h, right (4Dh) east 05h, left (4Bh) west 17h: the direction keys KeyNorth...KeyWest
 * (the assembly labels ArrowScanTbl the first byte and ArrowKeyTbl the second). */
static const u8 ArrowTbl[8] = { 0x48, 0x0E, 0x50, 0x19, 0x4D, 0x05, 0x4B, 0x17 };

/* ---- Where the player is, relative to a monster --------------------------------------------- */

/* asm: DirToPlayer @4F11 -- DeltaX, DeltaY = the direction from the monster to the player on the
 * wrapping 64x64 map, each 0, 1 or FFh. The difference is shifted left twice before its sign is
 * taken, so bit 5 of the raw difference becomes the sign: the shorter way round the map wins.
 * (The stc before each sub is a leftover of the 6502's SEC/SBC and does nothing.) */
void DirToPlayer(u8 slot)
{
    DeltaX = SignOf((u8)((u8)(PlayerX - MonsterX[slot]) << 2));
    DeltaY = SignOf((u8)((u8)(PlayerY - MonsterY[slot]) << 2));
}

/* asm: DistToPlayer @4F36 -- DeltaX, DeltaY = player minus monster, neither wrapped nor reduced to
 * a sign. */
void DistToPlayer(u8 slot)
{
    DeltaX = (u8)(PlayerX - MonsterX[slot]);
    DeltaY = (u8)(PlayerY - MonsterY[slot]);
}

/* ---- The keyboard --------------------------------------------------------------------------- */

/* asm: ReadKey @4F4D
 *
 * One poll of the keyboard, it does not wait. Returns AH = 0 (high byte) for no key, else AH = FFh
 * and AL = the key, letters in upper case; Escape is FF1Bh. The BIOS buffer is emptied after every
 * key, so there is no type-ahead. Keys that are handled here and reported as "no key" (AH = 0):
 *   Ctrl-S           switches the sound off and on (SoundOff)
 *   Ctrl-Right/Left  the speed setting SpeedSetting minus/plus 200h, within SpeedMin..3A00h, and
 *                    CalcDelayTbl rescales the delays
 * The arrow keys become the direction keys 0Eh, 19h, 05h, 17h (ArrowTbl). A typed Ctrl-E, Ctrl-N
 * or Ctrl-W (which are those codes) and every other extended key come out as FF00h, so only the
 * arrows make a direction. (Ctrl-Y = 19h, which is "south", is not filtered.)
 *
 * BUG, as in the original: the speed setting starts at 00FFh (SetDefaultSpeed), and the first
 * Ctrl-Right takes it to FEFFh, which passes the unsigned test against SpeedMin;
 * CalcDelayTbl's division then overflows. Checked in play: the game hangs. */
u16 ReadKey(void)
{
    u16 ax;
    u8 al, ah;
    int bx;
    u16 speed;

    if (!BiosKeyWaiting()) {
        al = 0;                                     /* "meaningless" */
        ah = 0;
        goto upcase;
    }
    ax = BiosReadKey();                             /* AH = scan code, AL = ASCII */
    al = (u8)ax;
    ah = (u8)(ax >> 8);
    if (al == 5 || al == 0x0E || al == 0x17) {      /* Ctrl-E, Ctrl-N, Ctrl-W typed: FF00h */
        al = 0;
        goto got;
    }
    while (BiosKeyWaiting())                        /* empty the buffer */
        BiosReadKey();
    if (al == 0x13) {                               /* Ctrl-S */
        SoundOff ^= 0xFF;
        return 0;
    }
    if (al != 0)
        goto got;                                   /* an ordinary key */
    if (ax == 0x7400) {                             /* Ctrl-Right: faster */
        speed = (u16)(SpeedSetting - 0x200);
        if (speed < SpeedMin)
            return 0;
        SpeedSetting = speed;
        CalcDelayTbl();
        return 0;
    }
    if (ax == 0x7300) {                             /* Ctrl-Left: slower */
        speed = (u16)(SpeedSetting + 0x200);
        if (speed > 0x3A00)
            return 0;
        SpeedSetting = speed;
        CalcDelayTbl();
        return 0;
    }
    for (bx = 6; bx >= 0; bx -= 2) {                /* another extended key: an arrow? */
        if (ah == ArrowTbl[bx]) {
            al = ArrowTbl[bx + 1];
            break;
        }
    }
got:
    ah = 0xFF;
upcase:
    if (al >= 'a' && al <= 'z')
        al &= 0xDF;
    return (u16)((ah << 8) | al);
}

/* asm: WaitKey @53D0 -- waits for a key (ReadKey repeated; Ctrl-S and the speed keys are handled
 * there) and returns it upper-cased. */
u8 WaitKey(void)
{
    return ReadAsciiKey();
}

/* asm: ReadTwoDigits @51B0
 *
 * Reads a two-digit number, echoing each digit; other keys are ignored (no Escape, no backspace).
 * Returns it as BCD (tens in the high nibble), which is how the game keeps its counts. The tens
 * digit is held in AmountHi meanwhile. */
u8 ReadTwoDigits(void)
{
    u8 key;

    do {
        key = ReadAsciiKey();
    } while (key < '0' || key > '9');
    PrintChar(key);
    AmountHi = (u8)((key - '0') << 4);
    do {
        key = ReadAsciiKey();
    } while (key < '0' || key > '9');
    PrintChar(key);
    return (u8)((key - '0') + AmountHi);
}

/* ---- Printing ------------------------------------------------------------------------------- */

/* asm: PrintChar @5003
 *
 * Prints the character at the cursor (bit 7 ignored, so the game's 8Dh is a carriage return) and
 * advances it. CR goes back to column TextLeftCol and down a line; 0Ah is a line feed (down a line only).
 * The C texts write both 0Dh and 0Ah as the one character newline, so the C treats 0Ah as CR too: the
 * only 0Ah in the game follow a 0Dh (CHARGEN texts), where the two come to the same. Past column
 * TextRightCol the text wraps like a CR. Below row 23 the message window (rows 20-23, columns 0 to
 * TextRightCol) scrolls up one line and the cursor stays on row 23. The attribute (the colour in
 * graphics mode) is TextAttr. */
void PrintChar(u8 c)
{
    c &= 0x7F;
    if (c != 0x0D && c != 0x0A) {
        BiosWriteChar(c, TextAttr);
        CursorCol++;
        if (TextRightCol >= CursorCol) {
            UpdateBiosCursor();
            return;
        }
        c = 0x0D;                                   /* past the right edge: a new line */
    }
    if (c == 0x0D || c == 0x0A)                    /* asm: PrintChar_CR (0Ah: see above) */
        CursorCol = TextLeftCol;
    CursorRow++;                                    /* asm: PrintChar_LF */
    if (CursorRow == 0x18) {
        BiosScrollUp(1, 0x14, 0, 0x17, TextRightCol);
        CursorRow--;
    }
    UpdateBiosCursor();
}

/* asm: PutChar @53F4 -- PrintChar, under the name the other modules use. */
void PutChar(u8 c)
{
    PrintChar(c);
}

/* asm: PrintInline @4FDF -- prints the zero-terminated text that follows the call in the code
 * (in the C it is the parameter): the cursor is moved to the screen first, then each character is
 * printed with PrintChar. */
void PrintInline(const char *text)
{
    UpdateBiosCursor();
    for (; *text != 0; text++)
        PrintChar((u8)*text);
}

/* asm: PrintSex @505F -- MALE if PlayerSex is the letter 'M', else FEMALE. */
void PrintSex(void)
{
    if (PlayerSex == 'M')
        PrintInline("MALE");
    else
        PrintInline("FEMALE");
}

/* asm: PrintPlayerName @507A -- the zero-terminated name at the start of the player record. */
void PrintPlayerName(void)
{
    int i;

    for (i = 0; PlayerRecord[i] != 0; i++)
        PrintChar(PlayerRecord[i]);
}

/* asm: PrintNameStr @508C -- string n (1-75) of NameStrTbl. n = 0 would skip 65536 strings;
 * callers never pass 0. */
void PrintNameStr(u8 n)
{
    u16 skip = n;               /* asm: SI */
    u16 i = 0;                  /* asm: DI */

    for (;;) {
        if (NameStrTbl[i] == 0 && --skip == 0)
            break;
        i++;
    }
    for (i++; NameStrTbl[i] != 0; i++)
        PrintChar((u8)NameStrTbl[i]);
}

/* asm: PrintBcdByte @53B5 -- the two nibbles of the byte as digits (each OR 30h, so only 0-9 are
 * digits; A-F print as : ; < = > ?). */
void PrintBcdByte(u8 bcd)
{
    PrintChar((u8)((bcd >> 4) | 0x30));
    PrintChar((u8)((bcd & 0x0F) | 0x30));
}

/* asm: PrintBcdWord @51A5 -- four BCD digits: the high two, then the low two. */
void PrintBcdWord(u8 hi, u8 lo)
{
    PrintBcdByte(hi);
    PrintBcdByte(lo);
}

/* asm: SetTextNormal @53D9 -- TextAttr 0Fh: bright white in text mode, colour 3 (white) in
 * graphics mode. */
void SetTextNormal(void)
{
    TextAttr = 0x0F;
}

/* asm: SetTextWarning @53DF -- the warning colour: 2 (magenta) in graphics mode, 70h (inverse
 * video) in text mode. */
void SetTextWarning(void)
{
    if (GraphicsMode == 0)
        TextAttr = 0x70;
    else
        TextAttr = 2;
}

/* asm: SetCursor @51EB -- column, row; the BIOS cursor follows. */
void SetCursor(u8 col, u8 row)
{
    CursorCol = col;
    CursorRow = row;
    UpdateBiosCursor();
}

/* asm: UpdateBiosCursor @51FD -- the BIOS cursor (page 0) to CursorCol/CursorRow. */
void UpdateBiosCursor(void)
{
    BiosSetCursor(CursorRow, CursorCol);
}

/* asm: ClearTextLine @53A0 -- 40 spaces from column 0 of the cursor's row; the cursor ends at
 * column 40 (the next row if the window wraps there). */
static void ClearTextLine(void)
{
    int n;

    CursorCol = 0;
    for (n = 0x28; n != 0; n--)
        PrintChar(' ');
}

/* asm: ClearBottomLines @538F -- rows 23 and 24 blanked. */
void ClearBottomLines(void)
{
    CursorRow = 0x17;
    ClearTextLine();
    CursorRow = 0x18;
    ClearTextLine();
}

/* asm: DrawStatusLines @50F9
 *
 * The four status lines at column 30, rows 20-23: "H.P.=", "FOOD=", "EXP.=", "GOLD=" and each a
 * four-digit BCD number. Hit points and food are in the warning colour when below 100 (the
 * hundreds byte is 0). Then the message window is narrowed to columns 0-29 (TextRightCol = 29)
 * and the cursor goes to (0, 23). (TextRightCol is 40 while the lines are drawn.) */
void DrawStatusLines(void)
{
    TextRightCol = 0x28;
    CursorCol = 0x1E;
    CursorRow = 0x14;
    PrintInline("H.P.=");
    if (HitPointsHi == 0)
        SetTextWarning();
    PrintBcdWord(HitPointsHi, HitPointsLo);
    SetTextNormal();
    CursorCol = 0x1E;
    CursorRow = 0x15;
    PrintInline("FOOD=");
    if (FoodHi == 0)
        SetTextWarning();
    PrintBcdWord(FoodHi, FoodLo);
    SetTextNormal();
    CursorCol = 0x1E;
    CursorRow = 0x16;
    PrintInline("EXP.=");
    PrintBcdWord(ExpHi, ExpLo);
    CursorCol = 0x1E;
    CursorRow = 0x17;
    PrintInline("GOLD=");
    PrintBcdWord(GoldHi, GoldLo);
    TextRightCol = 0x1D;
    SetCursor(0, 0x17);
}

/* ---- The map and random numbers ------------------------------------------------------------- */

/* asm: GetMapSquare @50B3 -- the map byte at (LookX, LookY): MapBufPtr + 64 * LookY + LookX. Its
 * address stays in MapCellPtr, so callers write the square through the pointer. No range check and
 * no wrap. */
u8 GetMapSquare(void)
{
    MapCellPtr = MapBufPtr + (u16)(LookY << 6) + LookX;
    return *MapCellPtr;
}

/* asm: SignOf @50D8 -- 0 -> 0, 1-7Fh -> 1, 80h-FFh -> FFh. (The assembly's AbsOf shares its
 * return instruction.) */
u8 SignOf(u8 x)
{
    if (x == 0) return 0;
    if (x < 0x80) return 1;
    return 0xFF;
}

/* asm: AbsOf @50EF -- the absolute value of a signed byte. */
u8 AbsOf(u8 x)
{
    if (x < 0x80) return x;
    return (u8)((x ^ 0xFF) + 1);
}

/* asm: Random @5217
 *
 * An additive generator over a six-byte history, RandSeed (newest) to RandSeed5, a byte array
 * RandSeed[6] here. The new byte is RandSeed1 + RandSeed4 + RandSeed5 + 1 (the first carry is set,
 * and the carry runs on through the adc chain), the history moves down one place and the new byte
 * is the answer. The seed is set from the BIOS tick count at the start (START). */
u8 Random(void)
{
    unsigned s;
    u8 v;
    int i;

    s = (unsigned)RandSeed[1] + RandSeed[4] + 1;
    s = (unsigned)(u8)s + RandSeed[5] + (s > 0xFF);
    v = (u8)s;
    for (i = 4; i >= 0; i--)
        RandSeed[i + 1] = RandSeed[i];
    RandSeed[0] = v;
    return v;
}

/* ---- The attack mark ------------------------------------------------------------------------ */

/* asm: AttackMarkBmp @5288 -- a 16x16 picture in the format XorBitmapCS draws: a header 04h
 * (bytes a line), 10h (lines), then 16 lines of 4 bytes, colour 3: a filled circle. */
static const u8 AttackMarkBmp[] = {
    0x04, 0x10, 0x00, 0x0F, 0xF0, 0x00, 0x00, 0xFF,
    0xFF, 0x00, 0x03, 0xFF, 0xFF, 0xC0, 0x0F, 0xFF,
    0xFF, 0xF0, 0x0F, 0xFF, 0xFF, 0xF0, 0x3F, 0xFF,
    0xFF, 0xFC, 0x3F, 0xFF, 0xFF, 0xFC, 0x3F, 0xFF,
    0xFF, 0xFC, 0x3F, 0xFF, 0xFF, 0xFC, 0x3F, 0xFF,
    0xFF, 0xFC, 0x3F, 0xFF, 0xFF, 0xFC, 0x0F, 0xFF,
    0xFF, 0xF0, 0x0F, 0xFF, 0xFF, 0xF0, 0x03, 0xFF,
    0xFF, 0xC0, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x0F,
    0xF0, 0x00
};

/* asm: XorAttackMark @523E
 *
 * Draws or erases (XOR: twice undoes it) the attack mark on the map square next to the player in
 * the direction DeltaX/DeltaY; the player's own square is at pixel (90h, 50h), column 9, row 5 of
 * the window. A vertical direction wins over a horizontal one; (0, 0) is the player's square
 * (that is the assembly's XorPlayerMark entry, the same routine). Called in pairs around a sound:
 * draw, sound, erase. */
void XorAttackMark(void)
{
    u16 x = 0x90, y = 0x50;

    if (DeltaY == 1)         y = 0x60;
    else if (DeltaY == 0xFF) y = 0x40;
    else if (DeltaX == 1)    x = 0xA0;
    else if (DeltaX == 0xFF) x = 0x80;
    XorBitmapCS(x, y, AttackMarkBmp);
}

/* asm: XorPlayerMark @5255 -- the same on the player's own square, whatever DeltaX/DeltaY say. */
void XorPlayerMark(void)
{
    XorBitmapCS(0x90, 0x50, AttackMarkBmp);
}

/* ---- Files ---------------------------------------------------------------------------------- */

/* asm: ReadWriteFile @52CA
 *
 * Reads (DOS function 27h) or writes (28h) one file in one block, through an FCB. The name is 8
 * letters, no extension, padded with blanks (inline after the call in the assembly, a parameter
 * here). The FCB is cleared and given the name and a blank extension on the default drive; the
 * file is opened. If that fails the screen says "WRONG DISK" and waits for Escape, then tries
 * again, forever. The buffer becomes the DTA (in the CGA screen segment B800h when the name starts
 * with "PI": the PIC pictures are read straight onto the screen), the record size is 1 byte, and
 * the random block call transfers `length` bytes from record 0. Errors of the transfer and the
 * close are not checked. */
void ReadWriteFile(u8 dos_function, const char *name8, void *buffer, u16 length)
{
    u8 fcb[0x25];               /* asm: Fcb (D:0245): drive, name at 1, extension at 9, record size at 0Eh */
    bool onto_screen;

    memset(fcb, 0, sizeof fcb);
    memcpy(fcb + 1, name8, 8);
    memset(fcb + 9, ' ', 3);
    while (DosOpenFcb(fcb) != 0) {
        PrintInline("\n               WRONG DISK");
        while (ReadKey() != 0xFF1B) { }             /* wait for Escape */
    }
    onto_screen = (fcb[1] == 'P' && fcb[2] == 'I');
    DosSetDta(buffer, onto_screen);
    fcb[0x0E] = 1;                                  /* record size 1 (a word) */
    fcb[0x0F] = 0;
    DosRandomBlock(dos_function, fcb, length);
    DosCloseFcb(fcb);
}
