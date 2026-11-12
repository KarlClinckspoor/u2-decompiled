/* chargen.c -- CHARGEN.ASM (original addresses 5400-5AB1) read as C: character generation.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/CHARGEN.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine, that it prints
 * the same texts and that it calls the same routines at least as often. It cannot check the logic.
 *
 * "C" on the title menu (START) calls CreateCharacter, which never returns. It reads the PLAYER
 * file into the player record; if the record is not blank (the first byte of the name is not 0)
 * it complains and hangs. Otherwise the sketch of the character is drawn and the player is asked
 * for, in this order:
 *   - the six attributes, two digits each (BCD): at least 10 each, and 90 points in all
 *     (SpendAttrPoints checks each against the points left; any mistake starts all over);
 *   - sex, race and type, each adding a bonus to one attribute (BCD):
 *         M)ale +5 strength, F)emale +10 charisma;
 *         1 human +5 intelligence, 2 elf +5 agility, 3 dwarf +5 strength, 4 hobbit +10 wisdom;
 *         1 fighter +15 strength, 2 cleric +10 wisdom, 3 wizard +10 intelligence, 4 thief +10 agility;
 *   - the name (12 letters at most, Backspace starts it over) and SATISFACTORY (Y/N).
 * The manual says hobbit +5 and fighter +10; nothing but "female" touches charisma.
 * N starts the whole sketch again; Y sets the starting values (position 20,20, hit points, food
 * and gold 400, TimeZone 2), writes the record to PLAYER and restarts the program (ProgramEntry).
 *
 * Not translated: the floppy version's two "insert disk" prompts, still in the file as dead bytes
 * after a jmp short (5414 and 5A1E), and the work byte MapViewCol of MAPVIEW in the padding at
 * the end (see mapview.c).
 *
 * See shops.c for the conventions shared by all the C files.
 */

#include "u2.h"

/* the points left to distribute, BCD (asm: Temp29); the value just typed is Temp2A */
static u8 PointsLeft;

/* asm: SpendAttrPoints @5A66 returns: CreateChar_Sketch
 *
 * Takes an attribute from the points left: the value must be at least 0Ah and not more than the
 * points left (BCD subtraction, a borrow is an error); then PointsLeft goes down by it and the new
 * total is shown highlighted at row 2, column 33. Otherwise three bells (the text is three 07h)
 * and false: the assembly drops its caller and starts the sketch again. */
static bool SpendAttrPoints(u8 value)
{
    int borrow = 0;
    u8 left;

    if (value < 0x0A) goto error;
    left = bcd_sbb(PointsLeft, value, &borrow);
    if (borrow) goto error;
    SetTextWarning();
    PointsLeft = left;
    SetCursor(0x21, 2);
    PrintBcdByte(PointsLeft);
    SetTextNormal();
    return true;
error:
    PrintInline("\7\7\7");
    return false;
}

/* asm: CreateCharacter @5400 also: @5498 @5A61 unrolled: ReadTwoDigits-5 SpendAttrPoints-5 SetCursor-5
 *
 * The whole of it; see the header. Rows and columns of the sketch: the attributes on rows 4-9 and
 * M/F, RACE, TYPE, NAME on rows 11-14, all with their values at column 26 (the attributes) or 20,
 * SATISFACTORY on row 16, and the lists of races and types below. */
void CreateCharacter(void)
{
    u8 key;
    int i;

    SetTextMode();
    SetCursor(6, 0x0C);
    ReadWriteFile(0x27, "PLAYER  ", PlayerRecord, 0x100);
    if (PlayerRecord[0] != 0) {                     /* not a blank player disk: the player must reboot */
        SetTextMode();
        SetCursor(0x0E, 0x0B);
        PrintInline("NOT A BLANK");
        SetCursor(0x0E, 0x0D);
        PrintInline("PLAYER DISK");
        HangForever();
        return;
    }

sketch:                                             /* asm: CreateChar_Sketch */
    SetTextMode();
    PrintInline("          PLAYER GENERATION :");
    PrintInline("\n\n     POINTS LEFT TO DISTRIBUTE : ");
    SetTextWarning();
    PointsLeft = 0x90;
    PrintBcdByte(PointsLeft);
    SetTextNormal();
    PrintInline("\n\n           STRENGTH.......\n           AGILITY........\n           STAMINA........\n"
                "           CHARISMA.......\n           WISDOM.........\n           INTELLIGENCE...\n\n"
                "                M/F-\n               RACE-\n               TYPE-\n               NAME-\n\n"
                "          SATISFACTORY (Y/N)-\n\n        RACES:         TYPES:\n"
                "         1-HUMAN        1-FIGHTER\n         2-ELF          2-CLERIC\n"
                "         3-DWARF        3-WIZARD\n         4-HOBBIT       4-THIEF");

    /* the six attributes, strength first: rows 4-9, column 26 */
    for (i = 0; i < 6; i++) {
        SetCursor(0x1A, (u8)(4 + i));
        Attributes[i] = ReadTwoDigits();
        if (!SpendAttrPoints(Attributes[i]))
            goto sketch;
    }

    /* sex: M or F, other keys ask again (but the key is already stored in PlayerSex) */
    SetCursor(0x14, 0x0B);
    for (;;) {
        key = WaitKey();
        PlayerSex = key;
        if (key == 'M') {
            PrintInline("MALE");
            Strength = bcd_add(Strength, 0x05);
            SetCursor(0x1A, 4);
            PrintBcdByte(Strength);
            break;
        }
        if (key == 'F') {
            PrintInline("FEMALE");
            Charisma = bcd_add(Charisma, 0x10);
            SetCursor(0x1A, 7);
            PrintBcdByte(Charisma);
            break;
        }
    }

    /* race: 1-4; the key stays in PlayerRace as ASCII until the type is asked */
    for (;;) {
        SetCursor(0x14, 0x0C);
        key = WaitKey();
        PlayerRace = key;
        if (key == '1') {
            PrintInline("HUMAN");
            Intelligence = bcd_add(Intelligence, 0x05);
            SetCursor(0x1A, 9);
            PrintBcdByte(Intelligence);
            break;
        }
        if (key == '2') {
            PrintInline("ELF");
            Agility = bcd_add(Agility, 0x05);
            SetCursor(0x1A, 5);
            PrintBcdByte(Agility);
            break;
        }
        if (key == '3') {
            PrintInline("DWARF");
            Strength = bcd_add(Strength, 0x05);
            SetCursor(0x1A, 4);
            PrintBcdByte(Strength);
            break;
        }
        if (key == '4') {
            PrintInline("HOBBIT");
            Wisdom = bcd_add(Wisdom, 0x10);         /* the manual says +5 */
            SetCursor(0x1A, 8);
            PrintBcdByte(Wisdom);
            break;
        }
    }

    /* type: 1-4. BUG, as in the original: the conversion of the race key to 0-3 is the head of this
     * loop, so every wrong key at this prompt takes another 31h off PlayerRace and the race comes out
     * as garbage (Ztats prints string 44h + race). Checked in play: human and two wrong keys saves
     * race 9Eh, and Ztats prints no race at all. */
    for (;;) {
        PlayerRace = (u8)(PlayerRace - '1');
        SetCursor(0x14, 0x0D);
        key = WaitKey();
        PlayerClass = key;
        if (key == '1') {
            PrintInline("FIGHTER");
            Strength = bcd_add(Strength, 0x15);     /* the manual says +10 */
            SetCursor(0x1A, 4);
            PrintBcdByte(Strength);
            break;
        }
        if (key == '2') {
            PrintInline("CLERIC");
            Wisdom = bcd_add(Wisdom, 0x10);
            SetCursor(0x1A, 8);
            PrintBcdByte(Wisdom);
            break;
        }
        if (key == '3') {
            PrintInline("WIZARD");
            Intelligence = bcd_add(Intelligence, 0x10);
            SetCursor(0x1A, 9);
            PrintBcdByte(Intelligence);
            break;
        }
        if (key == '4') {
            PrintInline("THIEF");
            Agility = bcd_add(Agility, 0x10);
            SetCursor(0x1A, 5);
            PrintBcdByte(Agility);
            break;
        }
    }
    PlayerClass = (u8)(PlayerClass - '1');          /* asm: CreateChar_TypeDone */

    /* the name: 15 blanks over the field, bytes 1-0Eh of the record cleared (byte 0 is left to the
     * first key), then up to 12 characters; Backspace starts again, Enter ends */
name:                                               /* asm: CreateChar_AskName */
    SetCursor(0x14, 0x0E);
    PrintInline("               ");
    SetCursor(0x14, 0x0E);
    for (i = 0x0E; i != 0; i--)
        PlayerRecord[i] = 0;
    i = 0;
    for (;;) {
        key = WaitKey();
        if (key == 8) goto name;
        if (key == 0x0D) break;
        PrintChar(key);
        PlayerRecord[i++] = key;
        if ((u8)i >= 0x0C) break;
    }

    /* SATISFACTORY (Y/N) */
    for (;;) {
        SetCursor(0x1D, 0x10);
        key = WaitKey();
        PrintChar(key);
        if (key == 'N') goto sketch;
        if (key == 'Y') break;
    }

    SurfaceX = 0x14;                                /* the starting position and values */
    SurfaceY = 0x14;
    TimeZone = 2;
    HitPointsHi = 4;
    FoodHi = 4;
    GoldHi = 4;
    ReadWriteFile(0x28, "PLAYER  ", PlayerRecord, 0x100);
    SetTextMode();
    SetCursor(0x0B, 0x0B);
    ProgramEntry();                                 /* the game starts again from its entry point */
    HangForever();
}

/* asm: MapViewCol @5AB0 check: none -- a work byte of MAPVIEW (the map column being read), in the padding at the end of this
 * module; see mapview.c. */
