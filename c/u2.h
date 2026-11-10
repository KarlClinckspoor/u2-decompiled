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

extern u8 PlayerX, PlayerY;     /* D:0000 D:0001  position on the 64x64 map (towns: 0-3Fh)     */
extern u8 PlayerTile;           /* D:0013  the player's tile, half code: 22h = on a horse       */
extern u8 PlayerSex;            /* D:0046  1 = female                                           */
extern u8 PlayerClass;          /* D:0047  0 fighter, 1 cleric, 2 wizard, 3 thief               */
extern u8 MapType;              /* D:004A  0 surface, 1 village, 2 towne, 3 castle, 4 tower, 5 dungeon */

/* Packed BCD, two digits per byte (see bcd.h). */
extern u8 FoodHi;               /* D:0053  food hundreds                                        */
extern u8 GoldHi, GoldLo;       /* D:0058 D:0059  gold: hundreds, units                         */

/* Counts of what the player owns, BCD, indexed by the item's number. */
extern u8 WeaponCounts[10];     /* D:0076  weapons 0-9 (0 = hands, 9 = the quick sword)         */
extern u8 ArmourCounts[7];      /* D:0096  armour 0-6 (0 = skin)                                */
extern u8 SpellCounts[10];      /* D:00B6  spells 1-9 (index 0 unused)                          */

/* The price the last CalcPrice computed: hundreds and units, BCD. (In the assembly the same two
 * bytes are also used as a word holding a table address; here the table is a parameter.) */
extern u8 AmountHi, AmountLo;   /* D:0027 D:0028 */

extern const char *TalkBufPtr;  /* D:0476  the TLKxxx file of the current town (zero-separated strings) */

/* ---- Routines of other modules -------------------------------------------------------------- */

/* Printing. A '\n' in a string is the game's carriage return (0Dh/8Dh). */
void PrintInline(const char *text);     /* C:4FDF  text after "call PrintInline" in the assembly   */
void PutChar(u8 c);                     /* C:53F4  one character at the cursor                     */
void PrintNameStr(u8 n);                /* C:508C  string n (1-75) of NameStrTbl: weapon/armour/spell names... */
void PrintPlayerName(void);             /* C:507A                                                  */
void PrintBcdWord(u8 hi, u8 lo);        /* C:51A5  four BCD digits ("0300")                        */

/* Input. */
u8   ReadDigit(void);                   /* C:2028  waits for '0'-'9', echoes it; returns 0-9       */
u8   ReadAsciiKey(void);                /* C:4F4D  ReadKey repeated until it returns an ASCII key (AH = FFh);
                                           returns the upper-cased character                       */

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
