/* u2.h -- the game's state and the routines the C files in this folder use.
 *
 * READING AID, NOT A PORT. See README.md. The assembly in ../src is the ground truth.
 *
 * Variable names are the assembly's (src/U2DATA.ASM); "D:xxxx" is the offset in the original's
 * data segment (`python3 tools/syms.py NAME` finds it). Routine names are the assembly's too, with
 * "C:xxxx" the original address. Anything that is only declared here is implemented elsewhere
 * (another module of the game, or a stand-in for a DOS/BIOS service).
 */
#ifndef U2_H
#define U2_H

#include <stdbool.h>
#include <stdint.h>
#include "bcd.h"

typedef uint8_t  u8;
typedef uint16_t u16;

/* ---- State (src/U2DATA.ASM) --------------------------------------------------------------- */

/* Where the player is. */
extern u8 PlayerX, PlayerY;     /* D:0000 D:0001  position on the 64x64 map (towns: 0-3Fh)     */
extern u8 PlayerTile;           /* D:0013  the player's tile, half code: 22h horse, 24h frigate, 26h plane,
                                           28h rocket, 78h + 2*class on foot                     */
extern u8 TileHere;             /* D:0014  tile (map code / 2) under the player                 */
extern u8 MapType;              /* D:004A  0 surface, 1 village, 2 towne, 3 castle, 4 tower, 5 dungeon */
extern u8 TimeZone;             /* D:0049  the era, 0-4 on Earth                                */
extern u8 Planet;               /* D:006D  0 = Earth, 9 = planet X                              */
extern u8 *MapCellPtr;          /* D:0006  the map byte GetMapSquare last read (the assembly keeps its
                                           address; writing through it changes the map)         */
extern u8 LookX, LookY;         /* D:0023 D:0024  the square being looked at                    */
extern u8 DeltaX, DeltaY;       /* D:0019 D:001A  a step: 0, 1, or FFh (-1) per axis            */

/* The character. Sex is the letter 'M' or 'F' (character generation stores the key pressed). */
extern u8 PlayerSex;            /* D:0046                                                       */
extern u8 PlayerClass;          /* D:0047  0 fighter, 1 cleric, 2 wizard, 3 thief               */
extern u8 PlayerRace;           /* D:0048  0 human, 1 elf, 2 dwarf, 3 hobbit                    */
extern u8 Attributes[6];        /* D:004B  strength, agility, stamina, charisma, wisdom, intelligence (BCD) */
#define Strength     Attributes[0]
#define Agility      Attributes[1]
#define Stamina      Attributes[2]
#define Charisma     Attributes[3]
#define Wisdom       Attributes[4]
#define Intelligence Attributes[5]

/* Packed BCD, two digits per byte (see bcd.h). */
extern u8 HitPointsHi;          /* D:0051  hit points / 100                                     */
extern u8 ExpHi;                /* D:0056  experience / 100 = the level                         */
extern u8 FoodHi;               /* D:0053  food hundreds                                        */
extern u8 GoldHi, GoldLo;       /* D:0058 D:0059  gold: hundreds, units                         */

/* What the player holds and uses. */
extern u8 ReadyWeapon;          /* D:0061  0 hands, 1-9                                         */
extern u8 WornArmour;           /* D:0062  0 skin, 1-6                                          */
extern u8 ReadySpell;           /* D:0063  0 none, 1-9                                          */
extern u8 Torches, Keys, Tools; /* D:0064 D:0065 D:0066  BCD counts                             */
extern u8 RingEarned;           /* D:006C  set by T)ransact with the right person on planet X   */

/* Counts of what the player owns, BCD, indexed by the item's number. */
extern u8 WeaponCounts[10];     /* D:0076  weapons 0-9 (0 = hands, 9 = the quick sword)         */
#define QuickSwordCount WeaponCounts[9]
extern u8 ArmourCounts[7];      /* D:0096  armour 0-6 (0 = skin)                                */
extern u8 SpellCounts[10];      /* D:00B6  spells 1-9 (index 0 unused)                          */
extern u8 ItemCounts[16];       /* D:00D6  items 0-15: 0 ring, 1 wand, 2 staff, 3 boots, 5 helms, 13 strange coins... */
#define Helms        ItemCounts[5]
#define StrangeCoins ItemCounts[13]

/* The people and monsters of the current map, slots 1-31 (slot 0 holds the town's alarm flag in
 * MonsterMood). */
extern u8 MonsterTile[32];      /* D:0197  map code of the monster, 0 = free slot               */
extern u8 MonsterMood[32];      /* D:01D7  80h + n = talks (talk file string n); 1 = hostile    */
extern u8 TimeStopTurns;        /* D:026A  turns of stopped time left                           */

/* The price the last CalcPrice computed: hundreds and units, BCD. (In the assembly the same two
 * bytes are also used as a word holding a table address; here the table is a parameter.) */
extern u8 AmountHi, AmountLo;   /* D:0027 D:0028 */

extern const char *TalkBufPtr;  /* D:0476  the TLKxxx file of the current town (zero-separated strings) */

/* The screen. */
extern u8 CursorCol;            /* D:002E */
extern u8 TextRightCol;         /* D:0031  text wraps at this column                            */
extern u8 TextLeftCol;          /* D:054F  column after a carriage return                       */
extern u8 TileCache[256];       /* D:0272  the map window as it will be drawn                   */
extern u8 TileCacheShown[256];  /* D:0372  the map window as it is on screen                    */

/* ---- Routines of other modules -------------------------------------------------------------- */

/* Printing. A '\n' in a string is the game's carriage return (0Dh/8Dh); PutChar takes either. */
void PrintInline(const char *text);     /* C:4FDF  text after "call PrintInline" in the assembly   */
void PutChar(u8 c);                     /* C:53F4  one character at the cursor                     */
void PrintNameStr(u8 n);                /* C:508C  string n (1-75) of NameStrTbl: weapon/armour/spell names... */
void PrintPlayerName(void);             /* C:507A                                                  */
void PrintSex(void);                    /* C:505F  MALE or FEMALE, from PlayerSex                  */
void PrintBcdWord(u8 hi, u8 lo);        /* C:51A5  four BCD digits ("0300")                        */
void PrintBcdByte(u8 bcd);              /* C:53B5  two BCD digits                                  */
void PrintTalkString(u8 n);             /* C:154E  SHOPS: the n-th (1-based) string of the talk file */
void SetCursor(u8 col, u8 row);         /* C:51EB                                                  */
void UpdateBiosCursor(void);            /* C:51FD  move the screen cursor to CursorCol/CursorRow   */
void SetTextMode(void);                 /* C:4A1C  40x25 text screen, cleared                      */
void SetGraphicsMode(void);             /* C:4A3E  the CGA map screen; both tile caches invalid    */
void DrawStatusLines(void);             /* C:50F9  H.P., FOOD, EXP., GOLD                          */

/* Input. */
u8   ReadDigit(void);                   /* C:2028  waits for '0'-'9', echoes it; returns 0-9       */
u8   ReadAsciiKey(void);                /* C:4F4D  ReadKey repeated until it returns an ASCII key (AH = FFh);
                                           returns the upper-cased character                       */
bool ReadDirection(void);               /* C:2362  reads a direction key into DeltaX/DeltaY and prints its name.
                                           If no key comes in time it prints "PASS" and returns false; the
                                           original then abandons the caller and ends the turn with a beep. */

/* The map and its people. */
u8   GetMapSquare(void);                /* C:50B3  the map byte at LookX/LookY; also sets MapCellPtr */
u8   FindMonsterInDir(void);            /* C:23E6  the slot (1-31) of the monster next to the player in the
                                           direction DeltaX/DeltaY, 0 if none; sets LookX/LookY to that square */
void AlertTownGuards(void);             /* C:113A  makes the guards hostile                        */
void DrawHelmMap(void);                 /* C:29D2  the whole map from above, centred on LookX/LookY */
void ShopDispatch(void);                /* C:1590  SHOPS: the shop across the counter              */

/* Saving, time and sound. */
void SaveGame(void);                    /* C:22FD  writes the map, the monsters and PLAYER (on Earth only) */
void SpeedDelay(u16 entry_offset);      /* C:0711  a speed-dependent delay: table entry at byte offset n */
void Beep(void);                        /* C:5C95  the error beep; the original's EndCommandBeep is a Beep
                                           and then the end of the turn                            */

/* Money. */
void CalcPrice(u8 item);                /* C:20AB  sets AmountHi:AmountLo; cheaper with Intelligence + Charisma */
bool PayPrice(void);                    /* C:2052  takes AmountHi:AmountLo from the gold. If there is not
                                           enough it prints "YOU DONT HAVE THAT MUCH!" and returns false;
                                           the original then abandons the caller and ends the turn with a
                                           beep, so every caller here just returns when it gets false.   */

/* Random numbers. */
u8   Random(void);                      /* C:5217  0-FFh                                           */
u8   SignOf(u8 x);                      /* C:50D8  0 -> 0, 1-7Fh -> 1, 80h-FFh -> FFh              */

#endif
