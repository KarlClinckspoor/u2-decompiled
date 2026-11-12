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
typedef uint32_t u32;

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
extern u8 FacingDX, FacingDY;   /* D:0002 D:0003  which way the player faces underground        */
extern u8 DungeonLevel;         /* D:0025  0-15; in a tower the floors count upwards            */
extern u8 *DungeonCellPtr;      /* D:0008  the dungeon cell ReadDungeonCell last read           */
extern u8 LightTurns;           /* D:0026  turns of light left (96h from a torch or the spell)  */
extern u8 OffMapTile;           /* D:0012  the tile drawn beyond the map's edge                 */
extern u8 SurfaceX, SurfaceY;   /* D:005A D:005B  the outdoor position, remembered on entering a town */
extern u8 RocketParked;         /* D:0069  1 = the rocket stands at RocketX/RocketY             */
extern u8 RocketX, RocketY;     /* D:006A D:006B                                                */
extern u8 TimeDoorSpot;         /* D:006E  where the time door stands: 0, 2, 4, 6, the offset of its x,y pair
                                           in the era's row of TimeDoorTbl                         */
extern u8 TimeDoorUnder;        /* D:0070  the map byte the door covers                         */
extern u8 TimeDoorTimer;        /* D:006F  surface turns until the door moves on (8)            */
extern const u8 TimeDoorTbl[];  /* C:2798  (DUNGEON.ASM) four x,y pairs per era, the door's places */
extern u8 PlaneFlying;          /* D:054E  FFh while the plane is in the air                    */
extern u8 KeyNorth, KeySouth, KeyEast, KeyWest;   /* D:026E-0271  the direction keys' codes     */
extern u8 ArmsParalyzed;        /* D:026C  turns the arms stay paralysed                        */
extern u8 PlotX, PlotY;         /* D:0479 D:047A  the pixel PlotPixel draws                     */
extern u8 TileNorth, TileSouth, TileEast, TileWest;   /* D:0015-0018  the tiles around the player (half codes) */
extern u8 LegsParalyzed;        /* D:026B  turns the legs stay paralysed                        */
extern u8 SleepTurns;           /* D:026D  turns of sleep left                                  */
extern u8 SpawnCounter;         /* D:0060  counts the outdoor spawn attempts; saved with the player */
extern u8 LastKey;              /* D:005D  the key just read at the prompt                      */
extern u8 Temp20, Temp21, Temp22;   /* D:0020-0022  scratch. In the turn: attacks made on the player, hits,
                                       damage; at the prompt: the idle timer (Temp21, Temp22)    */
extern u16 SpeedSetting;        /* D:0074  the speed setting (a word in the PLAYER record); 0 = never set */
extern u8 *MonsterBufPtr;       /* D:0474  the buffer the MONSTERS file is read into            */

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
extern u8 HitPointsHi, HitPointsLo;     /* D:0051 D:0052  hit points: hundreds, units           */
extern u8 ExpHi, ExpLo;         /* D:0056 D:0057  experience: ExpHi is the level                */
extern u8 PlayerRecord[256];    /* D:0036  the PLAYER file image: name, sex, class, race, attributes... */
extern u8 FoodHi, FoodLo, FoodFrac;     /* D:0053-0055  food: hundreds, units, hundredths        */
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
#define Boots        ItemCounts[3]
#define Cloaks       ItemCounts[4]
#define Wands        ItemCounts[1]
#define Staffs       ItemCounts[2]
#define Helms        ItemCounts[5]
#define Ankhs        ItemCounts[7]
#define SkullKeys    ItemCounts[9]
#define BrassButtons ItemCounts[11]
#define BlueTassles  ItemCounts[12]
#define StrangeCoins ItemCounts[13]
#define GreenIdols   ItemCounts[14]
#define TriLithium   ItemCounts[15]

/* The people and monsters of the current map, slots 1-31 (slot 0 holds the town's alarm flag in
 * MonsterMood). */
extern u8 MonsterX[32];         /* D:0137  position                                             */
extern u8 MonsterY[32];         /* D:0157                                                       */
extern u8 MonsterHP[32];        /* D:0177  hit points                                           */
extern u8 MonsterUnder[32];     /* D:01B7  the tile under it (outdoors); the dungeon level it is on (underground) */
extern u8 MonsterTile[32];      /* D:0197  map code of the monster, 0 = free slot               */
extern u8 MonsterStepX[32];     /* D:01F7  a wandering monster's step; scratch for the new position underground */
extern u8 MonsterStepY[32];     /* D:0217 */
extern u8 *MapBufPtr;           /* D:0472  the map buffer: the 64x64 map, or 16 dungeon levels of 256 bytes */
extern u8 MonsterMood[32];      /* D:01D7  80h + n = talks (talk file string n); 1 = hostile    */
extern u8 TimeStopTurns;        /* D:026A  turns of stopped time left                           */

/* The price the last CalcPrice computed: hundreds and units, BCD. (In the assembly the same two
 * bytes are also used as a word holding a table address; here the table is a parameter.) */
extern u8 AmountHi, AmountLo;   /* D:0027 D:0028 */

extern const char *TalkBufPtr;  /* D:0476  the TLKxxx file of the current town (zero-separated strings) */

/* The screen. */
extern u8 CursorCol;            /* D:002E */
extern u8 CursorRow;            /* D:002F */
extern u8 TextAttr;             /* D:023E  text attribute: 0Fh normal, 2 or 70h warning          */
extern u8 GraphicsMode;         /* D:0478  0 = text screen, else the CGA map screen             */
extern u8 RandSeed[6];          /* D:023F  the random generator's history, newest first         */
extern u8 SoundOff;             /* D:054D  FFh = sound off (Ctrl-S)                             */
extern u16 SpeedMin;            /* D:0554  the lowest speed setting Ctrl-Right accepts          */
extern u8 TextRightCol;         /* D:0031  text wraps at this column                            */
extern u8 TextLeftCol;          /* D:054F  column after a carriage return                       */
extern u8 TileCache[256];       /* D:0272  the map window as it will be drawn                   */
extern u8 TileCacheShown[256];  /* D:0372  the map window as it is on screen                    */

/* ---- Routines of other modules -------------------------------------------------------------- */

/* The commands (CMDAL.ASM, CMDMZ.ASM), each ends the turn by returning. */
void CmdAttack(void);  void CmdBoard(void);   void CmdCast(void);       void CmdDescend(void);
void CmdEnter(void);   void CmdFire(void);    void CmdGet(void);        void CmdHyperspace(void);
void CmdIgniteTorch(void);  void CmdJump(void);    void CmdKlimb(void);      void CmdLaunch(void);
void CmdMagic(void);   void CmdNegateTime(void);   void CmdOffer(void);  void CmdPass(void);
void CmdQuit(void);    void CmdReady(void);   void CmdSteal(void);      void CmdTransact(void);
void CmdUnlock(void);  void CmdView(void);    void CmdWear(void);       void CmdXit(void);
void CmdYell(void);    void CmdZtats(void);

/* The turn (MAIN.ASM, EVENTS.ASM, INPUT.ASM, DUNGEON.ASM). */
void DungeonLoop(void);                 /* C:27C0  one command underground (reads the key, moves or dispatches);
                                           the caller ends the turn                                */
void IllegalCommand(void);              /* C:2275  "-ILLEGAL COMMAND!" and the error beep          */
void DieOfStarvation(void);             /* C:228D  the player dies of hunger                       */
u8   CheckStep(u8 tile);                /* C:2423  the rules for a step onto this tile (half code): one of */
#define STEP_ALLOWED 0                  /*   the step stands                                           */
#define STEP_REFUSED 0xFF               /*   the caller steps back ("--INVALID MOVE!")                 */
#define STEP_DONE    1                  /*   the step ended the turn by itself (out of a town, through a time
                                             door; the assembly's jmp EndCommand): the caller does nothing more */
void MoveTimeDoor(void);                /* C:26F9  once per turn on the surface                    */
void TownTurnVillage(void);             /* C:1013  the monsters' turn in a village, towne, castle   */
void TownTurnTowne(void);               /* C:1014                                                  */
void TownTurnCastle(void);              /* C:1015                                                  */
void DungeonTurnTower(void);            /* C:115F  the monsters' turn in a tower, dungeon           */
void DungeonTurnDungeon(void);          /* C:115E                                                  */
void MonsterStepToward(u8 slot);        /* C:2122  moves the monster one square along DeltaX/DeltaY */
void DistToPlayer(u8 slot);             /* C:4F36  DeltaX, DeltaY = player minus monster, not reduced */
void DirToPlayer(u8 slot);              /* C:4F11  DeltaX, DeltaY = the sign of that, the short way round the map */
u8   AbsOf(u8 x);                       /* C:50EF  the absolute value of a signed byte             */
void SpellParalyzeLegs(void);           /* C:0E70  what monsters cast at the player (EVENTS.ASM)    */
void MinaxCurse(void);                  /* C:0F8E  */
void TownTurn(void);                    /* C:101C  the code behind the three TownTurn entries       */
void SpawnDungeonMonsters(void);        /* C:147F  */
void DirToPlayerDungeon(u8 slot);       /* C:152E  */
void DungeonMonsterAttack(u8 slot);     /* C:1308  */
void EatFood(u8 hundredths);            /* C:12DB  food drops by this many hundredths (BCD); starves below 0 */
u8   ReadCellIfSameLevel(u8 slot);      /* C:143C  the dungeon cell at LookX/LookY on the monster's level if it is the player's, else FFh */
u8   ReadMonsterCell(u8 slot);          /* C:144C  the same without the level test                  */
void MoveMonsterToTarget(u8 slot);      /* C:2201  moves a monster to LookX/LookY (INPUT.ASM)       */
void ClearViewArea(void);               /* C:4B4E  */
void UpdateDungeonView(void);           /* C:6000  draws the 3D view and fills TileHere..TileSouth  */
void SpellParalyzeArms(void);           /* C:0EC2 */
void SpellMagicMissile(void);           /* C:0F12 */
void SpellSleep(void);                  /* C:0F48 */
void ThiefStealItem(void);              /* C:0FCD  */
void SetDefaultSpeed(void);             /* C:06AC  */
void CalcDelayTbl(void);                /* C:06ED  (START) the delay table from SpeedSetting */
void AnimateWater(void);                /* C:4AE6  scrolls the water tile's picture one row         */
void AnimateForceField(void);           /* C:4AF1 */
void XorPlayerMark(void);               /* C:5255  draws or erases the mark on the player's square  */
void PlayHurtSound(void);               /* C:5EF2 */
void PlayTrapSound(void);               /* C:5E3B */
void HangForever(void);                 /* stands for the endless loop (jmp $) the original ends in  */

/* The turn's own routines (MAIN.ASM), declared here for the C files that call them. */
void MainLoop(void);
void DispatchCommand(u8 key);
void EndCommand(void);
void EndTurn(void);
void OutdoorMonsters(void);
void MonsterTurn(u8 slot);
void MonsterAttack(u8 slot);
void PlayerDies(void);                  /* C:0C62  the end of the player; shows "IS DEAD" and hangs */
void SpawnMonster(void);

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

void PlotPixel(void);                   /* C:4B76  the pixel PlotX, PlotY                          */
void InvertViewArea(void);              /* C:4B26  the screen flash                                */
void XorAttackMark(void);               /* C:523E  draws or erases the attack mark next to the player */
void UpdateMapView(void);               /* C:5AB1  redraws the map window                          */

/* Input. */
u16  ReadKey(void);                     /* C:4F4D  one poll of the keyboard, it does not wait: AH = 0 for no key,
                                           else AH = FFh and AL = the key (upper case)             */
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
void DrawHelmMap(void);                 /* C:29D2  the whole map from above (4x2 pixels a square), for the helm */
void PlotOverviewDot(u8 dot_col, u8 dot_row);   /* C:2B65  (CMDAL) one dot of the square DeltaX, DeltaY */
void ShopDispatch(void);                /* C:1590  SHOPS: the shop across the counter              */

u8   ReadDungeonCell(u8 level);         /* C:1451  the dungeon cell at LookX/LookY on that level; also sets DungeonCellPtr */
void LoadMapAndMonsters(void);          /* C:2290  loads the map and monster files for TimeZone and MapType */
void LoadTalkFile(void);                /* C:22D5                                                  */
void LeaveToSurface(void);              /* C:243E  from a town back to the outdoor map             */
void SpaceFlight(void);                 /* C:6999  the rocket's flight; returns when it lands      */
void MinaxDead(void);                   /* C:72A0  the end of the game; never returns              */
/* C:52CA  read (27h) or write (28h) a file in one block: DOS function, a name of 8 letters, a buffer, a length */
void ReadWriteFile(u8 dos_function, const char *name8, void *buffer, u16 length);

/* Saving, time and sound. */
void SaveGame(void);                    /* C:22FD  writes the map, the monsters and PLAYER (on Earth only) */
void PlayFailSound(void);               /* C:5E83 */
void PlayAttackSound(void);             /* C:5EAC */
void PlayStepSound(void);               /* C:5EC7 */
void PlayHitSound(void);                /* C:5ED7 */
void PlayWarpSound(void);               /* C:5FA6 */
void PlaySpellSound(void);              /* C:5FC3 */
void PlaySwingSound(void);              /* C:5FE0 */
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

/* The BIOS and DOS services the game uses (stand-ins: the C does not implement them). */
bool BiosKeyWaiting(void);              /* int 16h AH=1: a key is waiting                          */
u16  BiosReadKey(void);                 /* int 16h AH=0: AH = scan code, AL = ASCII                */
void BiosWriteChar(u8 c, u8 attr);      /* int 10h AH=9: a character at the cursor, no advance     */
void BiosScrollUp(u8 lines, u8 top, u8 left, u8 bottom, u8 right);   /* int 10h AH=6, blank colour 0 */
void BiosSetCursor(u8 row, u8 col);     /* int 10h AH=2, page 0                                    */
u8   DosOpenFcb(u8 *fcb);               /* int 21h AH=0Fh: 0 = opened                              */
void DosSetDta(void *buffer, bool onto_screen);   /* int 21h AH=1Ah (the CGA segment B800h if onto_screen) */
void DosRandomBlock(u8 function, u8 *fcb, u16 count);   /* int 21h AH=27h read / 28h write, from record 0 */
void DosCloseFcb(u8 *fcb);              /* int 21h AH=10h                                          */
void XorBitmapCS(u16 x, u16 y, const u8 *bitmap);   /* C:4C1E  (SCREEN) draws a picture XOR onto the screen */

/* TEXTIO.ASM */
void PrintChar(u8 c);                   /* C:5003  */
u8   ReadTwoDigits(void);               /* C:51B0  two digits, echoed; BCD                         */
u8   WaitKey(void);                     /* C:53D0  */
void ClearBottomLines(void);            /* C:538F  */
void SetTextNormal(void);               /* C:53D9  */
void SetTextWarning(void);              /* C:53DF  */


/* CHARGEN.ASM, START.ASM */
void CreateCharacter(void);             /* C:5400  character generation; never returns             */
void ProgramEntry(void);                /* C:0100  the program restarts from its entry point        */

/* ENDGAME.ASM, sound */
extern u8  SpeakerIsOff;                /* C:6998  a byte in the code segment (VIEW3D): FFh speaker off, 0 on */
extern u16 BleepCountdown;              /* C:6994  a word in the code segment (VIEW3D)             */
void StartTone(u16 divisor);            /* C:5CB2  PIT channel 2 square wave, speaker on           */
void HoldTone(u16 divisor, u16 duration);   /* C:5CD2  sets the pitch, waits duration x delay      */
void StopTone(void);                    /* C:5CE4  */
void SpaceSpeakerOn(u16 divisor);       /* C:7276  */
void SpaceSpeakerOff(void);             /* C:7289  */
void ToggleSpaceBleep(void);            /* C:7242  */

/* START.ASM */
extern u8  DemoSeen;                    /* D:0239  1 once the demonstration has been shown          */
extern u16 DelayTbl[20];                /* D:0580  the speed-scaled delays                          */
extern const u16 DelayFactorTbl[20];    /* D:0558                                                   */
#define CgaMemory ((void *)0)           /* the PIC pictures are read to B800:0000 (the name starts with "PI") */
u8   BiosTickLow(void);                 /* the low byte of the BIOS tick count (40h:6Ch)            */
void DivideError(void);                 /* the CPU's divide error: the original never recovers      */
void GameStart(void);                   /* C:0764  (MAIN) play; never returns                       */
void TitleScreen(void);                 /* C:013E  */
void MainMenu(void);                    /* C:0242  */
void DemoShow(void);                    /* C:03AF  */
#endif
