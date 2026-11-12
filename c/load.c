/* load.c -- LOAD.ASM (original addresses 2290-2362) read as C: loading the map, monster and talk
 * files of a place, and saving the game.
 *
 * A READING AID, NOT A PORT, and not byte-matching: it says what the assembly does, in the shape
 * a C programmer would expect. It has never been run against the game. The assembly in
 * ../src/LOAD.ASM is the ground truth; when the two disagree, the C is wrong.
 * tools/ccheck.py checks that every function below is anchored to a real routine and that it
 * calls the same routines at least as often. It cannot check the logic.
 *
 * Every place has three files named <kind><letter><zone><type>, eight letters with the blanks:
 * MAPX03, MONX03, TLKX21 ("MAPX03  "). The letter is 'X' on Earth and 'G' on the other planets,
 * the zone is TimeZone as a digit (the era on Earth, the planet elsewhere), the type is MapType as
 * a digit (0 surface, 1 village, 2 towne, 3 castle, 4 tower, 5 dungeon). The assembly keeps each
 * name inline after its `call ReadWriteFile` and PATCHES THE DIGITS INTO ITS OWN CODE before the
 * call; SPACE's SetMapFileLetter patches the letters (FcbMapLetter, FcbMonLetter, FcbTlkLetter)
 * the same way. Here the names are arrays, patched just the same; the "FF" they hold before the
 * first patch is what the assembly holds.
 *
 * Saving always writes the 'X' names, and only on Earth: the other planets are never saved, so
 * what happens there is forgotten when the player leaves.
 *
 * See shops.c for the conventions shared by all the C files.
 */

#include "u2.h"

#define DOS_READ_BLOCK  0x27    /* FCB random block read  */
#define DOS_WRITE_BLOCK 0x28    /* FCB random block write */

/* The inline names. Index 3 is the letter (FcbMapLetter etc. in the assembly, set by SPACE's
 * SetMapFileLetter), 4 the zone digit, 5 the type digit. */
char FcbMapName[9] = "MAPXFF  ";
char FcbMonName[9] = "MONXFF  ";
char FcbTlkName[9] = "TLKXFF  ";
static char FcbSaveMapName[9] = "MAPXFF  ";    /* the save names: the letter is a fixed 'X' */
static char FcbSaveMonName[9] = "MONXFF  ";

/* asm: LoadMapAndMonsters @2290
 *
 * Loads the map of the place (1000h bytes, the 64x64 map, or 16 dungeon levels of 256) into the
 * map buffer and its monster file (100h bytes) over the monster table: the eight arrays of 32
 * from MonsterX to MonsterStepY lie one after the other, so one read fills all of them. Then one
 * poll of the keyboard throws a waiting key away. (ReadWriteFile asks for the disk until the file
 * opens.) */
void LoadMapAndMonsters(void)
{
    char zone = (char)('0' + TimeZone);
    char type = (char)('0' + MapType);

    FcbMapName[4] = zone;   FcbMonName[4] = zone;
    FcbMapName[5] = type;   FcbMonName[5] = type;
    ReadWriteFile(DOS_READ_BLOCK, FcbMapName, MapBufPtr, 0x1000);
    ReadWriteFile(DOS_READ_BLOCK, FcbMonName, MonsterX, 0x100);
    ReadKey();
}

/* asm: LoadTalkFile @22D5 -- the talk file of a village, towne or castle (100h bytes: the
 * zero-separated strings PrintTalkString prints) into the talk buffer. Called after
 * LoadMapAndMonsters on entering one. */
void LoadTalkFile(void)
{
    FcbTlkName[4] = (char)('0' + TimeZone);
    FcbTlkName[5] = (char)('0' + MapType);
    ReadWriteFile(DOS_READ_BLOCK, FcbTlkName, (void *)TalkBufPtr, 0x100);
}

/* asm: SaveGame @22FD
 *
 * On Earth only (Planet 0; anywhere else it does nothing): the player's position becomes the
 * surface position (SurfaceX/SurfaceY), then the map, the monster table and the player record
 * (PlayerRecord, which holds SurfaceX/SurfaceY among the rest) are written back to MAPXzt, MONXzt
 * and PLAYER. Called before entering a place (CmdEnter), before a time door, and by Q)uit. */
void SaveGame(void)
{
    char zone, type;

    if (Planet != 0)
        return;
    zone = (char)('0' + TimeZone);
    type = (char)('0' + MapType);
    FcbSaveMapName[4] = zone;   FcbSaveMonName[4] = zone;
    FcbSaveMapName[5] = type;   FcbSaveMonName[5] = type;
    SurfaceX = PlayerX;
    SurfaceY = PlayerY;
    ReadWriteFile(DOS_WRITE_BLOCK, FcbSaveMapName, MapBufPtr, 0x1000);
    ReadWriteFile(DOS_WRITE_BLOCK, FcbSaveMonName, MonsterX, 0x100);
    ReadWriteFile(DOS_WRITE_BLOCK, "PLAYER  ", PlayerRecord, 0x100);
}
