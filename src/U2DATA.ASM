; U2DATA.ASM: the data segment: variables, tables, tile bitmaps.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); DATA segment, original image 7410-8AC0.
;
; Variables in the 6502 "zero page" style at low offsets (position, cursor, scratch), the
; character from PlayerRecord (PlayerRecord, the 256-byte PLAYER file image: name, sex, class, race,
; time zone, map type, attributes, BCD hit points/food/exp/gold, inventory counts, speed),
; the monster table (8 arrays of 32 bytes from MonsterX, the MONxxx file image), random seed,
; DOS FCB, key codes, the map-window tile caches, line/plot and 3D-view work areas, the star
; field, delay tables, and TilePtrTbl: 64 pointers to the 0x42-byte tile bitmaps TileBmp00-3F.
; After D_END (not in the file): BSS, the map/talk/monster buffers and the stack (HANDOFF).
; Names and notes come from the code that uses each variable; "?" marks a guess.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	PUBLIC PlayerX, PlayerY, FacingDX, FacingDY, WorkX, WorkY
	PUBLIC MapCellPtr, MapCellPtrHi, DungeonCellPtr, DungeonCellPtrHi, OffMapTile, PlayerTile
	PUBLIC TileHere, TileNorth, TileSouth, TileEast, TileWest, DeltaX
	PUBLIC DeltaY, Temp1F, Temp20, Temp21, Temp22, LookX
	PUBLIC LookY, DungeonLevel, LightTurns, AmountHi, AmountLo, Temp29
	PUBLIC Temp2A, InlineTextPtr, CursorCol, CursorRow, TextRightCol, PlayerRecord
	PUBLIC PlayerSex, PlayerClass, PlayerRace, TimeZone, MapType, Strength
	PUBLIC Agility, Stamina, Charisma, Wisdom, Intelligence, HitPointsHi
	PUBLIC HitPointsLo, FoodHi, FoodLo, FoodFrac, ExpHi, ExpLo
	PUBLIC GoldHi, GoldLo, SurfaceX, SurfaceY, LastKey, SpawnCounter
	PUBLIC ReadyWeapon, WornArmour, ReadySpell, Torches, Keys, Tools
	PUBLIC RocketParked, RocketX, RocketY, RingEarned, Planet, TimeDoorSpot
	PUBLIC TimeDoorTimer, TimeDoorUnder, SpeedSetting, WeaponCounts, QuickSwordCount, ArmourCounts
	PUBLIC SpellCounts, ItemCounts, Wands, Staffs, Boots, Cloaks
	PUBLIC Helms, Ankhs, SkullKeys, BrassButtons, BlueTassles, StrangeCoins
	PUBLIC GreenIdols, TriLithium, MonsterX, MonsterY, MonsterHP, MonsterTile
	PUBLIC MonsterUnder, MonsterMood, MonsterStepX, MonsterStepY, DemoSeen, TextAttr
	PUBLIC RandSeed, RandSeed1, RandSeed2, RandSeed3, RandSeed4, RandSeed5
	PUBLIC Fcb, FcbName, FcbExt, FcbExt1, FcbExt2, FcbRecSize
	PUBLIC TimeStopTurns, LegsParalyzed, ArmsParalyzed, SleepTurns, KeyNorth, KeySouth
	PUBLIC KeyEast, KeyWest, TileCache, TileCacheNorth, TileCacheWest, TileCacheCentre
	PUBLIC TileCacheEast, TileCacheSouth, TileCacheShown, MapBufPtr, MonsterBufPtr, TalkBufPtr
	PUBLIC GraphicsMode, PlotX, PlotY, LineEndX, LineEndY, LineStepX
	PUBLIC LineStepY, BlockColor, LineCount, LineErr, ViewDepth, LineDX
	PUBLIC LineDY, CellPtr, CellPtrHi, ShapePtr, ShapePtrHi, ViewLeftCells
	PUBLIC ViewAheadCells, ViewRightCells, ViewMonsters, PlotOriginX, PlotOriginY, StarCurX
	PUBLIC StarCurY, StarNewX, StarNewY, StarMode, WarpFrames, StarIndex
	PUBLIC Xeno, Yako, Zabo, StarXs, StarYs, SoundOff
	PUBLIC PlaneFlying, TextLeftCol, SpeedMin, DelayFactorTbl, DelayTbl, ToneDelay
	PUBLIC TilePtrTbl, ForceFieldTilePtr, STACK_PARA
D_START label byte	; offset 0 of DATA: keep it the first line (sizes are measured from it)
PlayerX label byte	; 0-63; W dec / E inc at 09A3/09C9; compared with monster X+dx at 0B30
	db 0h
PlayerY label byte	; N dec / S inc at 0955/097C
	db 0h
FacingDX label byte	; dungeon facing dx (0/1/0FFh): turned at 2912/2944, added on advance 288F
	db 0h
FacingDY label byte	; dungeon facing dy, same
	db 0h
WorkX label byte	; MAPVIEW column counter 0-19 (VIEW3D reuses it?)
	db 0h
WorkY label byte	; MAPVIEW row counter 0-9 (VIEW3D reuses it?)
	db 0h
MapCellPtr label byte	; word: address of the map cell set by GetMapSquare (written via [bx+si] at 084E, 0D55)
	db 0h
MapCellPtrHi label byte	; high byte of MapCellPtr, built separately in MAPVIEW
	db 0h
DungeonCellPtr label byte	; word: -> dungeon cell, set by ReadDungeonCell; CMDAL 2EF4, 3299, 3705
	db 0h
DungeonCellPtrHi label byte	; high byte of DungeonCellPtr (alias: ReadDungeonCell writes it as a byte)
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h
OffMapTile label byte	; tile drawn outside the map: 0FFh = map wraps (surface) 0869/0C2D, 4 = grass 0C21
	db 0h
PlayerTile label byte	; the player's tile as a half code: 22h horse ... 28h rocket, 78h+ on foot
	db 0h
TileHere label byte	; tile (map code/2) under the player, from MAPVIEW; 6 = woods? doubles damage 0B96
	db 0h
TileNorth label byte	; tile north of the player, passed to CheckStep at 0962
	db 0h
TileSouth label byte	; 0989
	db 0h
TileEast label byte	; 09D5
	db 0h
TileWest label byte	; 09AF
	db 0h
DeltaX label byte	; player X - monster X (DistToPlayer), then direction -1/0/1 (DirToPlayer); negated to flee 0B13
	db 0h
DeltaY label byte	; same for Y
	db 0h,0h,0h,0h,0h
Temp1F label byte	; scratch: time-out low byte (ReadDirection), loop slot (DungeonTurnTower), tile...
	db 0h
Temp20 label byte	; scratch; also attacks this turn (SpellMagicMissile, MAIN 0B4D) and victim slot...
	db 0h
Temp21 label byte	; scratch; here the plane heading dx (3A48)?
	db 0h
Temp22 label byte	; scratch; here the plane heading dy (3A4D)?
	db 0h
LookX label byte	; X argument of GetMapSquare (map cell lookup) 083C/0CCC
	db 0h
LookY label byte	; Y argument of GetMapSquare 0842/0CE8
	db 0h
DungeonLevel label byte	; player's dungeon level (ReadCellIfSameLevel compares MonsterUnder); town loop reuses it as...
	db 0h
LightTurns label byte	; light left: 96h by Ignite/Light (CMDAL 321E/37D6), TORCH BURNED OUT at 0 (EVENTS 12AE);...
	db 0h
AmountHi label byte	; BCD hundreds of a price/amount (CalcPrice result, paid by PayPrice; SHOPS 1B42 oracle...
	db 0h
AmountLo label byte	; BCD units of the amount (pub price 5 at 161F)
	db 0h
Temp29 label byte	; scratch: current monster slot in MonsterTurn 0AAC (CheckStep also uses it)?
	db 0h
Temp2A label byte	; previous Fibonacci term low byte in CalcPrice; scratch elsewhere?
	db 0h
InlineTextPtr label byte	; word: pointer into the inline text while PrintInline prints
	db 0h,0h,0h
CursorCol label byte	; text cursor column (SetCursor: DI -> CursorCol)
	db 0h
CursorRow label byte	; text cursor row (SetCursor: SI -> CursorRow)
	db 0h,0h
TextRightCol label byte	; last column of the text window (inclusive): wrap and scroll edge; 28h, 1Dh with status
	db 0h,0h,0h,0h,0h
PlayerRecord label byte	; start of the PLAYER file image, 100h bytes (SaveGame writes it)
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
PlayerSex label byte	; 1 = female: "SISTER" at SHOPS 1879 (TEXTIO 506F prints FEMALE)
	db 0h
PlayerClass label byte	; 0-3 fighter/cleric/wizard/thief (CHARGEN 5959); figure = 78h+2*class 080D
	db 0h
PlayerRace label byte	; 0-3 human/elf/dwarf/hobbit (587F); Ztats prints string 44h+race
	db 0h
TimeZone label byte	; zone digit of MAP/MON/TLK names; time zone 0-4 on Earth, planet number?
	db 0h
MapType label byte	; 0 surface, 1 village, 2 town, 3 castle, 4 tower, 5 dungeon (CMDAL 3436-351C); 0A43
	db 0h
Strength label byte	; Ztats order; damage formula CMDAL 2C04
	db 0h
Agility label byte	; Ztats order; hit roll CMDAL 2BDD
	db 0h
Stamina label byte	; Ztats 46D6
	db 0h
Charisma label byte	; CalcPrice: Int + Cha lower prices; Ztats prints it 4th of 6 attributes
	db 0h
Wisdom label byte	; Ztats 4714
	db 0h
Intelligence label byte	; CalcPrice; 6th attribute (string INTELL.)
	db 0h
HitPointsHi label byte	; BCD hit points, high two digits (DrawStatusLines "H.P."), decremented 0BF5
	db 0h
HitPointsLo label byte	; BCD hit points, low two digits 0BE8
	db 0h
FoodHi label byte	; BCD food, high two digits (DrawStatusLines "FOOD") 0923
	db 0h
FoodLo label byte	; BCD food, low two digits 0918
	db 0h
FoodFrac label byte	; BCD food hundredths; -10 per passed turn 0911
	db 0h
ExpHi label byte	; BCD experience, high (DrawStatusLines "EXP."), zeroed on death 0C73
	db 0h
ExpLo label byte	; BCD experience, low
	db 0h
GoldHi label byte	; BCD gold, high (DrawStatusLines "GOLD") 0C79
	db 0h
GoldLo label byte	; BCD gold, low
	db 0h
SurfaceX label byte	; saved surface X (Enter saves it, game start uses it 0826)
	db 0h
SurfaceY label byte	; saved surface Y 082C
	db 0h,0h
LastKey label byte	; the key just read 0936 (only used there)
	db 0h,0h,0h
SpawnCounter label byte	; incremented per spawn try 0CFA; its lowest set bit picks the type; saved in PLAYER
	db 0h
ReadyWeapon label byte	; Ztats "WEAPON-"; damage formula CMDAL 2BFB
	db 0h
WornArmour label byte	; Wear 44CE; Ztats 4617 prints name 1Dh+n
	db 0h
ReadySpell label byte	; Ztats "SPELL-"; Cast 3154 (0 none .. 9 Kill)
	db 0h
Torches label byte	; Ztats "TORCHES-"; Ignite 37AE, loot 2D52
	db 0h
Keys label byte	; Ztats "KEYS-"; +2 for killing tile 60h, CMDAL 2CDF
	db 0h
Tools label byte	; BCD count; one used to escape a trap (DUNGEON 2904), none = death
	db 0h,0h,0h
RocketParked label byte	; 1 = a rocket stands at RocketX/RocketY (CMDAL 3957/39F4); put back at start 0832
	db 0h
RocketX label byte	; 0839
	db 0h
RocketY label byte	; 083F
	db 0h
RingEarned label byte	; set by Transact 4243 (talk 81h, planet 9, map type 3); Offer 3D17 needs it for the ring
	db 0h
Planet label byte	; 0 = Earth; nonzero: no saving (SaveGame), rocket restored (LeaveToSurface)
	db 0h
TimeDoorSpot label byte	; 0/2/4/6: offset of the active spot in the period's row of TimeDoorTbl (DUNGEON 2749); /2 =...
	db 0h
TimeDoorTimer label byte	; turns until the time door moves, reset to 8 (DUNGEON 2701/2746)
	db 0h
TimeDoorUnder label byte	; map tile covered by the time door (DUNGEON 277B; restored by EnterTimeDoor)
	db 0h,0h,0h,0h
SpeedSetting label byte	; word in the PLAYER record; delay scale, 0FFh default (SetDefaultSpeed), Ctrl-Left/Right +-200h
	db 0h,0h
WeaponCounts label byte	; BCD count per weapon 0-9 (Ready 3EB3, Ztats 475B, Steal 4042, Offer 3D5D)
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h
QuickSwordCount label byte	; = WeaponCounts+9; Offer 3D0A sets 1 ("ENILNO IS YOURS!")
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h
ArmourCounts label byte	; BCD count per armour 0-6 (Wear 4463, Ztats 47B4, Steal 4016)
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
SpellCounts label byte	; BCD count per spell 1-9 (Ztats 480C; Cast 3194)
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
ItemCounts label byte	; 16 BCD item counts, item 0 = ring (Offer 3D4C; Ztats 4864 names 2Eh+n)
	db 0h
Wands label byte	; item 1; Cast 315D
	db 0h
Staffs label byte	; item 2; Cast 3161
	db 0h
Boots label byte	; boots: SpellParalyzeLegs save
	db 0h
Cloaks label byte	; cloaks: SpellParalyzeArms save
	db 0h
Helms label byte	; item 5; loot 2D34
	db 0h,0h
Ankhs label byte	; item 7; Board rocket 30B5
	db 0h,0h
SkullKeys label byte	; item 9; Board plane 305A
	db 0h,0h
BrassButtons label byte	; item 11; Launch plane 3A0B
	db 0h
BlueTassles label byte	; item 12; Board frigate 2FF7
	db 0h
StrangeCoins label byte	; = ItemCounts+13 (STRANGE COIN); Negate time 3BDD uses one
	db 0h
GreenIdols label byte	; green idols: SpellSleep save
	db 0h
TriLithium label byte	; item 15; Launch rocket 38E4, chest 3771
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h
MonsterX label byte	; monster table x[32]; start of the 100h-byte MONxxx file image
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
MonsterY label byte	; monster y[32]
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
MonsterHP label byte	; monster hit points[32]: flees below 0Fh, heals to 10h (MonsterStepToward)
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
MonsterTile label byte	; monster tile/kind[32], 0 = free slot (dungeon: kind 1-7)
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
MonsterUnder label byte	; tile under the monster[32] (MoveMonsterToTarget); in dungeons its level (SpawnDungeonMonsters)
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
MonsterMood label byte	; per monster: 80h+n = talk string n (Transact 40C0), 1 = hostile (AlertTownGuards); entry 0...
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
MonsterStepX label byte	; wander dx[32] (TownTurn_Wander); scratch new x in dungeons (DungeonTurn_Step)
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
MonsterStepY label byte	; wander dy[32]
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h
DemoSeen label byte	; 0 at boot, 1 after the demonstration: the title then repeats it 0238
	db 0h,0h,0h,0h,0h
TextAttr label byte	; BIOS attribute/colour for PrintChar: 0Fh normal, 2 / 70h warning
	db 0Fh
RandSeed label byte	; 6-byte seed RandSeed-RandSeed5, from the BIOS tick at 0112 (Random shifts it)
	db 0h
RandSeed1 label byte	; seed byte 1
	db 0h
RandSeed2 label byte	; seed byte 2
	db 0h
RandSeed3 label byte	; seed byte 3
	db 0h
RandSeed4 label byte	; seed byte 4
	db 0h
RandSeed5 label byte	; seed byte 5
	db 0h
Fcb label byte	; DOS FCB, drive byte (0 = default); 25h bytes cleared by ReadWriteFile
	db 0h
FcbName label byte	; FCB file name, 8 bytes (copied from the inline name; "PI" test)
	db 0h,0h,0h,0h,0h,0h,0h,0h
FcbExt label byte	; FCB extension byte 1 (blank)
	db 0h
FcbExt1 label byte	; extension byte 2 (blank)
	db 0h
FcbExt2 label byte	; extension byte 3 (blank)
	db 0h,0h,0h
FcbRecSize label byte	; word: FCB record size (FCB+0Eh), set to 1
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h
TimeStopTurns label byte	; (N)egate time counter: no monster moves while nonzero (MonsterCanEnter)
	db 0h
LegsParalyzed label byte	; turns (SpellParalyzeLegs sets rnd&0Fh; MOVE refuses moves), counted down 0C33
	db 0h
ArmsParalyzed label byte	; turns (SpellParalyzeArms; Attack refuses), counted down 0C3E
	db 0h
SleepTurns label byte	; turns left asleep (SpellSleep, DgnAttack_StrongMagic)
	db 0h
KeyNorth label byte	; 0Eh, the code ReadKey returns for the up arrow 094F
	db 0Eh
KeySouth label byte	; 19h, down arrow 0976
	db 19h
KeyEast label byte	; 05h, right arrow 09C3
	db 5h
KeyWest label byte	; 17h, left arrow 099D
	db 17h
TileCache label byte	; 256 bytes: new window, 20x10 cells of tile*2, bit 7 = unchanged (MAPVIEW, DrawMapWindow)
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h
TileCacheNorth label byte	; TileCache cell 59h (column 9, row 4)
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h
TileCacheWest label byte	; TileCache cell 6Ch
	db 0h
TileCacheCentre label byte	; TileCache cell 6Dh: the player's square (icon written here)
	db 0h
TileCacheEast label byte	; TileCache cell 6Eh
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h
TileCacheSouth label byte	; TileCache cell 81h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
TileCacheShown label byte	; 256-byte cache: tiles on the screen (MAPVIEW compares with it)? 085E
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
MapBufPtr label byte	; pointer to the map buffer (DS:1800); file loads, ReadDungeonCell (page aligned)
	dw D_END+150h
MapBufPtrHi equ byte ptr MapBufPtr+1
MonsterBufPtr label byte	; word: address of the monster buffer; MONSTERS read there 07F6
	dw D_END+1250h
TalkBufPtr label byte	; pointer to the talk buffer (DS:2800); LoadTalkFile
	dw D_END+1150h
GraphicsMode label byte	; 0 = text mode 1, 1 = graphics mode 4 (SetTextMode/SetGraphicsMode; SetTextWarning)
	db 0h
PlotX label byte	; pixel x for PlotPixel/ErasePixel (before the origin PlotOriginX)
	db 0h
PlotY label byte	; pixel y for PlotPixel/ErasePixel
	db 0h
LineEndX label byte	; line end X; GetViewCells centre walker X
	db 0h
LineEndY label byte	; line end Y; GetViewCells centre walker Y
	db 0h
LineStepX label byte	; +1/FFh; GetViewCells right walker X
	db 0h
LineStepY label byte	; +1/FFh; GetViewCells right walker Y
	db 0h
BlockColor label byte	; colour pattern 0-7 of a shape block (index into FillPatternTbl)
	db 0h
LineCount label byte	; pixels left in the line
	db 0h
LineErr label byte	; Bresenham error term
	db 0h
ViewDepth label byte	; depth being drawn by DrawViewWalls (0-7); +1 = limit for DrawViewMonster
	db 0h
LineDX label byte	; |dx| of the line; in UpdateDungeonView/GetViewCells a copy of the facing dx
	db 0h
LineDY label byte	; |dy| of the line; in UpdateDungeonView/GetViewCells a copy of the facing dy
	db 0h,0h,0h
CellPtr label byte	; word pointer to the cell read by GetDungeonCell
	db 0h
CellPtrHi label byte	; high byte of CellPtr (label inside the word)
	db 0h
ShapePtr label byte	; word pointer into the monster shape being drawn (DrawViewMonster)
	db 0h
ShapePtrHi label byte	; high byte of ShapePtr (label inside the word)
	db 0h,0h,0h,0h,0h
ViewLeftCells label byte	; 8 bytes: high nibble of the cell left of the line of sight, by depth
	db 0h,0h,0h,0h,0h,0h,0h,0h
ViewAheadCells label byte	; 8 bytes: centre cells by depth
	db 0h,0h,0h,0h,0h,0h,0h,0h
ViewRightCells label byte	; 8 bytes: right cells by depth
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
ViewMonsters label byte	; 8 bytes: centre cell and 7 (monster type) by depth
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
PlotOriginX label byte	; word, 16: x origin added by PlotPixel/ErasePixel/FillBlock4x4 (never written)
	db 10h,0h
PlotOriginY label byte	; word, 16: y origin
	db 10h,0h
StarCurX label byte	; current star's X (work)
	db 0h
StarCurY label byte	; current star's Y (work)
	db 0h
StarNewX label byte	; current star's new X
	db 0h
StarNewY label byte	; current star's new Y
	db 0h
StarMode label byte	; star field mode / slowness: 0 streaks, 1 sweep, >=2 bleeps; frame delay = n*16
	db 0h
WarpFrames label byte	; frame counter for the hyperwarp phases
	db 0h
StarIndex label byte	; current star 0-63
	db 0h
Xeno label byte	; rocket coordinate Xeno 0-9
	db 0h
Yako label byte	; rocket coordinate Yako 0-9
	db 0h
Zabo label byte	; rocket coordinate Zabo 0-9
	db 0h
StarXs label byte	; 64 star X positions (0-255)
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
StarYs label byte	; 64 star Y positions (0-127)
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
SoundOff label byte	; 0 = sound on; Ctrl-S toggles (ReadKey); every sound checks it
	db 0h
PlaneFlying label byte	; FFh while the plane flies (3A5A), 0 after landing
	db 0h
TextLeftCol label byte	; column a CR returns to (PrintChar); 0, 1 on the Ztats screen
	db 0h,0h,0h,0h,0h
SpeedMin label byte	; word 068Ah: lower limit of SpeedSetting for Ctrl-Right, divisor in CalcDelayTbl
	db 8Ah,6h,0h,0h
DelayFactorTbl label byte	; 20 words: per-delay factors (CalcDelayTbl)
	db 6h,0h,0DEh,2h,0h,20h,0h,5h,3h,0h,3h,0h,3h,0h,0h,5h
	db 0Ah,0h,0h,10h,0E0h,1h,40h,1h,40h,2h,0h,2h,0h,8h,1h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h
DelayTbl label byte	; 20 words: delay counts for SpeedDelay (SpeedDelay), computed by CalcDelayTbl
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
ToneDelay label byte	; word: per-unit delay of the sounds = DelayTbl entry 6, scaled by CalcDelayTbl (0 at start)
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h
TilePtrTbl label byte	; 64 words: tile number -> 0x42-byte bitmap record
	dw TileBmp00
	dw TileBmp01
	dw TileBmp02
	dw TileBmp03
	dw TileBmp04
	dw TileBmp05
	dw TileBmp06
	dw TileBmp07
	dw TileBmp08
	dw TileBmp09
	dw TileBmp0A
	dw TileBmp0B
	dw TileBmp0C
	dw TileBmp0D
	dw TileBmp0E
	dw TileBmp0F
	dw TileBmp10
	dw TileBmp11
	dw TileBmp12
	dw TileBmp13
	dw TileBmp14
	dw TileBmp15
	dw TileBmp16
ForceFieldTilePtr label byte	; TilePtrTbl entry 23 (2Eh/2): the force field bitmap (AnimateForceField)
	dw TileBmp17
	dw TileBmp18
	dw TileBmp19
	dw TileBmp1A
	dw TileBmp1B
	dw TileBmp1C
	dw TileBmp1D
	dw TileBmp1E
	dw TileBmp1F
	dw TileBmp20
	dw TileBmp21
	dw TileBmp22
	dw TileBmp23
	dw TileBmp24
	dw TileBmp25
	dw TileBmp26
	dw TileBmp27
	dw TileBmp28
	dw TileBmp29
	dw TileBmp2A
	dw TileBmp2B
	dw TileBmp2C
	dw TileBmp2D
	dw TileBmp2E
	dw TileBmp2F
	dw TileBmp30
	dw TileBmp31
	dw TileBmp32
	dw TileBmp33
	dw TileBmp34
	dw TileBmp35
	dw TileBmp36
	dw TileBmp37
	dw TileBmp38
	dw TileBmp39
	dw TileBmp3A
	dw TileBmp3B
	dw TileBmp3C
	dw TileBmp3D
	dw TileBmp3E
	dw TileBmp3F
TileBmp00 label byte
	db 4h,10h,0h,0h,0h,0h,0h,0h,0h,0h,22h,0h,20h,2h,0h,22h
	db 2h,20h,0h,0h,0h,0h,0h,0h,0h,0h,0h,20h,2h,22h,22h,2h
	db 20h,0h,0h,0h,0h,0h,0h,0h,0h,0h,20h,2h,22h,0h,2h,20h
	db 0h,22h,0h,0h,0h,0h,0h,0h,0h,0h,0h,22h,2h,20h,22h,0h
	db 20h,2h
TileBmp01 label byte
	db 4h,10h,0h,11h,0h,0h,0h,0h,0h,0h,3h,0h,1h,10h,0h,0h
	db 0h,0h,1h,10h,0h,30h,0h,0h,0h,0h,0h,11h,0h,3h,0h,0h
	db 0h,0h,0h,3h,0h,11h,0h,0h,0h,0h,1h,10h,0h,30h,0h,0h
	db 0h,0h,3h,0h,11h,0h,0h,0h,0h,0h,11h,0h,30h,0h,0h,0h
	db 0h,0h
TileBmp02 label byte
	db 4h,10h,0h,1h,0h,0h,0h,0h,1h,0h,1h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,1h,0h,10h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,10h,0h,1h,0h,0h,0h,0h,0h,0h,1h,0h,0h,0h,0h,0h
	db 1h,0h,0h,0h,0h,0h,0h,0h,0h,10h,0h,10h,0h,0h,0h,0h
	db 0h,0h
TileBmp03 label byte
	db 4h,10h,1h,50h,0h,0h,15h,55h,0h,0h,15h,55h,0h,0h,15h,55h
	db 0h,0h,1h,50h,0h,0h,0h,0h,1h,50h,0h,0h,15h,55h,0h,0h
	db 15h,55h,0h,0h,15h,55h,0h,0h,1h,50h,1h,50h,0h,0h,15h,55h
	db 0h,0h,15h,55h,0h,0h,15h,55h,0h,0h,1h,50h,0h,0h,0h,0h
	db 0h,0h
TileBmp04 label byte
	db 4h,10h,0C0h,0C0h,0Ch,0h,33h,30h,33h,3h,0Ch,0Ch,0C0h,0CCh,30h,3h
	db 0h,30h,0C0h,0Ch,0h,0Ch,0h,30h,0h,3h,0C0h,0C0h,0C0h,0Ch,33h,3h
	db 30h,30h,0Ch,0Ch,0Ch,0C0h,3h,30h,3h,3h,0C0h,0C0h,0h,0CCh,33h,0h
	db 0h,30h,0Ch,0h,0h,0C0h,3h,3h,3h,0h,0h,0CCh,0CCh,0h,0h,30h
	db 30h,0h
TileBmp05 label byte
	db 4h,10h,0h,0h,0h,0h,3h,0C0h,0h,0h,0Ch,30h,0Fh,0h,0Ch,30h
	db 30h,0C0h,3h,0C0h,30h,0C0h,0h,0h,0Fh,0h,0h,0Fh,0h,0h,0h,30h
	db 0C0h,0h,0h,30h,0C0h,0h,0h,0Fh,0h,0h,0h,0h,3h,0C0h,3h,0C0h
	db 0Ch,30h,0Ch,30h,0Ch,30h,0Ch,30h,3h,0C0h,3h,0C0h,0h,0h,0h,0h
	db 0h,0h
TileBmp06 label byte
	db 4h,10h,0h,0h,0h,0h,0h,0h,0h,0h,0Fh,0FCh,3Fh,0F0h,0Ch,0Ch
	db 30h,30h,0Ch,0Ch,30h,30h,0Ch,0Ch,30h,30h,0Fh,0FFh,0FFh,0F0h,0h,0Ch
	db 30h,0h,0h,0Ch,30h,0h,0Fh,0FFh,0FFh,0F0h,0Ch,0Ch,30h,30h,0Ch,0Ch
	db 30h,30h,0Ch,0Ch,30h,30h,0Fh,0FCh,3Fh,0F0h,0h,0h,0h,0h,0h,0h
	db 0h,0h
TileBmp07 label byte
	db 4h,10h,0h,0h,0h,0h,0h,3Ch,3Ch,0h,0h,3Fh,0FCh,0h,0h,3Fh
	db 0FCh,0h,0h,0Fh,0F0h,0h,0h,0Fh,0F0h,0h,0h,0Fh,0F0h,0h,0h,0Fh
	db 0F0h,0h,0h,3Fh,0FCh,0h,0h,3Fh,0FCh,0h,0h,3Fh,0FCh,0h,0h,3Fh
	db 0FCh,0h,0h,0FFh,0FFh,0h,0h,0FFh,0FFh,0h,0h,0FFh,0FFh,0h,0h,0FFh
	db 0FFh,0h
TileBmp08 label byte
	db 4h,10h,0h,0h,0h,0h,0h,0h,0h,0h,0Fh,0h,0h,0F0h,0Fh,0FFh
	db 0FFh,0F0h,3h,0FFh,0FFh,0C0h,3h,0C0h,3h,0C0h,3h,0C0h,3h,0C0h,3h,0C0h
	db 3h,0C0h,3h,0C0h,3h,0C0h,3h,0C0h,3h,0C0h,3h,0C0h,3h,0C0h,3h,0FCh
	db 3Fh,0C0h,0Fh,0FCh,3Fh,0F0h,0Fh,0h,0h,0F0h,0h,0h,0h,0h,0h,0h
	db 0h,0h
TileBmp09 label byte
	db 4h,10h,0C0h,0C0h,0Ch,0h,33h,30h,33h,3h,0Ch,0Ch,0C0h,0CCh,30h,3h
	db 0h,30h,0C0h,0Ch,0h,0Ch,0h,30h,0h,3h,0C0h,0C0h,0C0h,0Ch,33h,3h
	db 30h,30h,0Ch,0h,0h,0C0h,3h,0Fh,0F0h,3h,0C0h,3Ch,3Ch,0Ch,30h,30h
	db 0Ch,30h,0Ch,30h,0Ch,0C0h,3h,30h,0Ch,3h,0C0h,30h,0Ch,0Ch,30h,30h
	db 0Ch,30h
TileBmp0A label byte
	db 4h,10h,0h,0h,0h,0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,3h,0FFh
	db 0FFh,0C0h,3h,0FFh,0FFh,0C0h,3h,0FFh,0FFh,0C0h,3h,0FFh,0FFh,0C0h,3h,0FFh
	db 0FFh,0C0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,0h,3h
	db 0C0h,0h,0h,3h,0C0h,0h,0h,0FFh,0FFh,0h,0Fh,0FFh,0FFh,0F0h,0h,0h
	db 0h,0h
TileBmp0B label byte
	db 4h,10h,0h,0h,0h,0h,0h,0h,0h,0h,22h,0h,20h,2h,0h,22h
	db 2h,20h,0h,0h,0h,0h,0h,0h,0Fh,0F0h,0h,20h,3Fh,0FCh,22h,0h
	db 0C3h,0FCh,0h,0h,0Ch,3Ch,0h,0h,0h,3Ch,20h,0h,0h,3Ch,0h,0FFh
	db 0C0h,3Ch,3h,0FFh,0F0h,3Ch,0Fh,0FFh,0FCh,3Ch,0h,22h,2h,20h,22h,2h
	db 22h,2h
TileBmp0C label byte
	db 4h,10h,0h,0h,0h,0h,0h,30h,0Ch,0h,0h,3Fh,0FCh,0h,0h,0Fh
	db 0F0h,0h,0h,0Fh,0F0h,0h,0h,3h,0C0h,0h,0h,0FFh,0FFh,0h,3h,0FFh
	db 0FFh,0C0h,0Fh,0Fh,0F0h,0F0h,0Fh,0Fh,0F0h,0F0h,0Fh,3Fh,0FCh,0F0h,0h,3Ch
	db 3Ch,0h,0h,3Ch,3Ch,0h,0h,3Ch,3Ch,0h,0h,0FCh,3Fh,0h,0h,0h
	db 0h,0h
TileBmp0D label byte
	db 4h,10h,0h,0h,0h,0h,0h,0Ch,30h,0h,0h,0Fh,0F0h,0h,0h,0Fh
	db 0F0h,0h,0h,3h,0C0h,0h,30h,3Fh,0FCh,0Ch,0Ch,0CFh,0F3h,30h,3h,0Fh
	db 0F0h,0C0h,0h,3h,0C0h,0h,0h,0Fh,0F0h,0h,0h,0Fh,0F0h,0h,0h,0Ch
	db 30h,0h,0h,0Ch,30h,0h,0h,0Ch,30h,0h,0h,3Ch,3Ch,0h,0h,0h
	db 0h,0h
TileBmp0E label byte
	db 4h,10h,0h,0h,0h,80h,0h,0C3h,8h,8h,0h,0FFh,8h,88h,0h,0FFh
	db 3h,0F0h,0h,3Ch,0h,0C0h,3h,0FFh,0C0h,0C0h,0Ch,0FFh,33h,0C0h,0Ch,3Ch
	db 0Ch,0C0h,0Ch,3Ch,0h,0C0h,0Ch,0FFh,0h,0C0h,0h,0FFh,0h,0C0h,0h,0C3h
	db 0h,0C0h,0h,0C3h,0h,0C0h,0h,0C3h,0h,0C0h,3h,0C3h,0C0h,0C0h,0h,0h
	db 0h,0h
TileBmp0F label byte
	db 4h,10h,0h,0h,0h,0h,0h,0Ch,30h,0h,0h,0Fh,0F0h,0h,3h,0Fh
	db 0F0h,0C0h,0Fh,0C3h,0C3h,0F0h,3Fh,0FFh,0FFh,0FCh,3Fh,0FFh,0FFh,0FCh,3Fh,0CFh
	db 0F3h,0FCh,3Fh,0CFh,0F3h,0FCh,3Fh,0C3h,0C3h,0FCh,3Fh,0CFh,0F3h,0FCh,3Fh,0Fh
	db 0F0h,0FCh,3Fh,0Ch,30h,0FCh,3Ch,0Ch,30h,3Ch,30h,3Ch,3Ch,0Ch,0h,0h
	db 0h,0h
TileBmp10 label byte
	db 4h,10h,0h,0h,0h,0h,0h,0Fh,0C0h,0h,0h,0Fh,0C0h,0h,0h,0Fh
	db 0C0h,0h,0h,3h,0h,0h,3Fh,0FFh,0FFh,0F0h,0Fh,0FFh,0FFh,0C0h,0Fh,0CFh
	db 0CFh,0C0h,0Fh,0C3h,0Fh,0C0h,0Fh,0Fh,0C3h,0C0h,0Fh,0Fh,0C3h,0C0h,0Ch,3Fh
	db 0F0h,0C0h,0Ch,3Fh,0F0h,0C0h,0h,0FFh,0FCh,0h,0h,0FFh,0FCh,0h,0h,30h
	db 30h,0h
TileBmp11 label byte
	db 4h,10h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,3h,0C0h,0h,0h,0Fh,0F0h,0h,0h,3Fh,0FCh,0h,0h,0Ch,0FFh
	db 0FFh,0F0h,0h,3Fh,0FFh,0FCh,0h,0FFh,0FFh,0FCh,0h,0FFh,0FFh,0F0h,3h,30h
	db 0Fh,3Ch,0Ch,30h,3h,0Ch,0Ch,30h,3h,0Ch,0h,0C0h,0Ch,30h,0h,0h
	db 0h,0h
TileBmp12 label byte
	db 4h,10h,0h,0h,0h,0h,0h,0h,0h,0h,0h,3h,0h,0h,0h,3h
	db 0C0h,0h,0h,0C3h,0Ch,0h,0h,0FFh,0FCh,0h,0Fh,0F0h,0FFh,0C0h,0Ch,30h
	db 0C0h,0C0h,0Ch,30h,0C0h,0C0h,0Fh,0FFh,0FFh,0C0h,0h,0C3h,0Ch,0h,3Fh,0FFh
	db 0FFh,0FCh,3Fh,0CFh,3Ch,0F0h,0Fh,0FFh,0FFh,0C0h,3h,0FFh,0FFh,0h,0h,0h
	db 0h,0h
TileBmp13 label byte
	db 4h,10h,0h,3Fh,0FCh,0h,0h,3h,0C0h,0h,0h,0Fh,0F0h,0h,0Fh,0FFh
	db 0FFh,0F0h,30h,0h,0h,0Ch,30h,3h,0C0h,0Ch,30h,0Ch,30h,0Ch,0Fh,0FCh
	db 3Fh,0F0h,0h,0Fh,0F0h,0h,0h,0Ch,30h,0h,0h,0Ch,30h,0h,0h,0Ch
	db 30h,0h,3h,0FCh,3Fh,0C0h,0Ch,3h,0C0h,30h,3h,0FFh,0FFh,0C0h,0h,3h
	db 0C0h,0h
TileBmp14 label byte
	db 4h,10h,0h,0h,0C0h,0h,0h,0h,0C0h,0h,0h,0h,0C0h,0h,0h,3h
	db 30h,0h,0h,3h,30h,0h,0h,3h,30h,0h,0h,0Ch,0Ch,0h,0h,0Ch
	db 0Ch,0h,0h,0Ch,0Ch,0h,0h,0Ch,0Ch,0h,0h,0Ch,0Ch,0h,0h,0Ch
	db 0Ch,0h,0h,30h,0C3h,0h,0h,0C3h,0F0h,0C0h,3h,0Ch,0CCh,30h,3h,0F0h
	db 0C3h,0F0h
TileBmp15 label byte
	db 4h,10h,0h,0h,0h,0h,0Fh,0FFh,0FFh,0F0h,0Ch,0h,0h,30h,0Ch,0Fh
	db 0FCh,30h,0Ch,30h,3Ch,30h,0Ch,30h,0h,30h,0Ch,0Fh,0F0h,30h,0Ch,0h
	db 0Ch,30h,0Ch,3h,0F0h,30h,0Ch,0Ch,0h,30h,0Ch,3h,0C0h,30h,3h,0h
	db 30h,0C0h,3h,3h,0C0h,0C0h,0h,0F0h,0Fh,0h,0h,0Fh,0F0h,0h,0h,0h
	db 0h,0h
TileBmp16 label byte
	db 4h,10h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,30h,0h,0h
	db 0h,0C0h,0h,0h,3h,0h,0h,0h,0Ch,0h,0h,0h,30h,0h,0h,0h
	db 0C0h,0h,0h,3h,0h,0h,0Ch,0Ch,0h,0h,3h,30h,0h,0h,0h,0C0h
	db 0h,0h,3h,30h,0h,0h,0Ch,0Ch,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h
TileBmp17 label byte
	db 4h,10h,88h,88h,88h,88h,33h,33h,33h,33h,33h,33h,33h,33h,11h,11h
	db 11h,11h,11h,11h,11h,11h,0CCh,0CCh,0CCh,0CCh,0CCh,0CCh,0CCh,0CCh,88h,88h
	db 88h,88h,88h,88h,88h,88h,33h,33h,33h,33h,33h,33h,33h,33h,11h,11h
	db 11h,11h,11h,11h,11h,11h,0CCh,0CCh,0CCh,0CCh,0CCh,0CCh,0CCh,0CCh,88h,88h
	db 88h,88h
TileBmp18 label byte
	db 4h,10h,0h,0Fh,0F0h,0h,0h,0Fh,0F0h,0h,0h,0Fh,0F0h,0h,0h,3h
	db 0C0h,0h,3h,0FFh,0FFh,0C0h,0Fh,0FFh,0FFh,0F0h,3Fh,3Fh,0FCh,0FCh,3Ch,0Fh
	db 0F0h,3Ch,3Ch,3h,0C0h,3Ch,3Ch,3h,0C0h,3Ch,0h,0Fh,0F0h,0h,0h,3Fh
	db 0FCh,0h,0h,3Ch,3Ch,0h,0h,3Ch,3Ch,0h,0h,3Ch,3Ch,0h,0h,0FCh
	db 3Fh,0h
TileBmp19 label byte
	db 4h,10h,0h,0h,0h,0h,0Ch,0Fh,0C0h,0C0h,0Ch,0Fh,0C0h,0C0h,0Fh,0Fh
	db 0C3h,0h,3h,0C3h,0Fh,0h,0h,0FFh,0FCh,0h,0h,3Fh,0F0h,0h,0h,0Fh
	db 0C0h,0h,0h,3h,0h,0h,0h,0Fh,0C0h,0h,0h,0Fh,0C0h,0h,0h,3Ch
	db 0F0h,0h,0h,0F0h,3Ch,0h,3h,0C0h,0Fh,0h,0Fh,0h,3h,0C0h,0h,0h
	db 0h,0h
TileBmp1A label byte
	db 4h,10h,0h,0h,0h,0h,0h,0Fh,0C0h,0h,0h,0Fh,0C0h,0h,0h,0Fh
	db 0C0h,0h,0h,3h,0h,0h,0h,0FFh,0FCh,0h,3h,3Fh,0F3h,0h,3h,0Fh
	db 0C3h,0h,3h,3h,3h,0h,3h,0Fh,0C3h,0h,3h,0Fh,0C3h,0h,0h,3Ch
	db 0F0h,0h,0h,30h,30h,0h,0h,30h,30h,0h,0h,0F0h,3Ch,0h,0h,0h
	db 0h,0h
TileBmp1B label byte
	db 4h,10h,0h,0h,0h,0h,0h,0Fh,0F0h,0h,0h,0Fh,0F0h,0h,0h,0Fh
	db 0F0h,0h,0h,3h,0C0h,0h,0h,3Fh,0FCh,0h,3h,0FFh,0FFh,0C0h,0Fh,0CFh
	db 0F3h,0F0h,0Fh,3h,0C0h,0F0h,0Fh,0Fh,0F0h,0F0h,0h,3Fh,0FCh,0h,0h,3Ch
	db 3Ch,0h,0h,3Ch,3Ch,0h,0h,3Ch,3Ch,0h,0h,3Ch,3Ch,0h,0h,3Ch
	db 3Ch,0h
TileBmp1C label byte
	db 4h,10h,80h,0h,80h,0h,80h,0h,80h,0h,80h,0h,80h,0h,88h,88h
	db 88h,88h,0h,80h,0h,80h,0h,80h,0h,80h,0h,80h,0h,80h,88h,88h
	db 88h,88h,80h,0h,80h,0h,80h,0h,80h,0h,80h,0h,80h,0h,88h,88h
	db 88h,88h,0h,80h,0h,80h,0h,80h,0h,80h,0h,80h,0h,80h,88h,88h
	db 88h,88h
TileBmp1D label byte
	db 4h,10h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h
TileBmp1E label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
	db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
	db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
	db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
	db 0FFh,0FFh
TileBmp1F label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp20 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0h,0FCh,0h,0h,3h
	db 0CFh,0C0h,0h,0Fh,0Fh,0h,0h,3Ch,0Fh,0h,0h,3Ch,0Fh,0h,0h,0FCh
	db 0Fh,0h,0h,0FFh,0FFh,0h,0h,0FCh,0Fh,0h,0h,3Ch,0Fh,0h,0h,3Ch
	db 0Fh,0h,0h,3Ch,0Fh,0h,0h,0FCh,3Fh,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp21 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0Fh,0F0h,0h,0h,3Ch
	db 3Ch,0h,0h,0FCh,0Fh,0h,0h,3Ch,0Fh,0h,0h,3Ch,3Ch,0h,0h,3Fh
	db 0F0h,0h,0h,3Ch,3Ch,0h,0h,3Ch,0Fh,0h,0h,3Ch,0Fh,0C0h,0h,0FCh
	db 0Fh,0h,0h,3Ch,3Ch,0h,0h,0Fh,0F0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp22 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0h,0FFh,0C0h,0h,3h
	db 0CFh,0h,0h,0Fh,0Fh,0h,0h,3Fh,3h,0h,0h,3Ch,3h,0h,0h,0FCh
	db 0h,0h,0h,0FCh,0h,0h,0h,3Ch,0h,0h,0h,3Fh,3h,0h,0h,0Fh
	db 3h,0h,0h,3h,0CFh,0h,0h,0h,0FCh,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp23 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3Fh,0C0h,0h,0h,0F0h
	db 0F0h,0h,3h,0F0h,3Ch,0h,0h,0F0h,0Fh,0h,0h,0F0h,0Fh,0h,0h,0F0h
	db 0Fh,0C0h,0h,0F0h,0Fh,0C0h,0h,0F0h,0Fh,0h,0h,0F0h,0Fh,0h,3h,0F0h
	db 3Ch,0h,0h,0F0h,0F0h,0h,0h,3Fh,0C0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp24 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0h,0FFh,0C0h,0h,3h
	db 0CFh,0h,0h,0Fh,3h,0h,0h,3Fh,0h,0h,0h,3Ch,0Ch,0h,0h,0FFh
	db 0FCh,0h,0h,0FCh,3Ch,0h,0h,3Ch,0Ch,0h,0h,3Fh,0h,0h,0h,0Fh
	db 3h,0h,0h,3h,0CFh,0h,0h,0h,0FCh,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp25 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0FFh,0FFh,0C0h,0h,3Ch
	db 0Fh,0h,0h,3Ch,3h,0h,0h,3Ch,0h,0h,0h,3Ch,0h,0h,0h,3Ch
	db 30h,0h,0h,3Fh,0F0h,0h,0h,3Ch,0F0h,0h,0h,3Ch,30h,0h,0h,3Ch
	db 0h,0h,0h,3Ch,0h,0h,0h,0FFh,0C0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp26 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3h,0FFh,0h,0h,0Fh
	db 3Ch,0h,0h,3Ch,3Ch,0h,0h,0FCh,0Ch,0h,0h,0F0h,0h,0h,3h,0F0h
	db 0h,0h,3h,0F0h,0FCh,0h,0h,0F0h,0Fh,0h,0h,0FCh,0Fh,0C0h,0h,3Ch
	db 0Fh,0h,0h,0Fh,3Ch,0h,0h,3h,0F0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp27 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,3h,0FFh,0FFh,0h,0h,0F0h
	db 3h,0h,0h,0F0h,0h,0h,0h,0F3h,0C0h,0h,0h,0FFh,0F0h,0h,0h,0F0h
	db 0FCh,0h,0h,0F0h,3Fh,0h,0h,0F0h,3Fh,0h,0h,0F0h,3Ch,0h,0h,0F0h
	db 3Ch,0h,0h,0F0h,30h,0h,3h,0FCh,3Fh,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp28 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3Fh,0FCh,0h,0h,3h
	db 0C0h,0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,0h,3h
	db 0C0h,0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,0h,3h
	db 0C0h,0h,0h,3h,0C0h,0h,0h,3Fh,0FCh,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp29 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0Fh,0FFh,0C0h,0h,0h
	db 0Fh,0h,0h,0h,0Fh,0h,0h,0h,0Fh,0h,0h,0h,0Fh,0h,0h,0h
	db 0Fh,0h,0h,0C0h,0Fh,0h,0h,0C0h,0Fh,0h,0h,0C0h,0Fh,0h,0h,0F0h
	db 0Fh,0h,0h,0FCh,0F0h,0h,0h,0Fh,0C0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp2A label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0FFh,0FFh,0h,0h,3Ch
	db 3h,0h,0h,3Ch,30h,0h,0h,3Ch,0FCh,0h,0h,3Fh,0CFh,0h,0h,3Ch
	db 0Fh,0h,0h,3Ch,3Ch,0h,0h,3Fh,0F0h,0h,0h,3Ch,0FCh,0h,0h,3Ch
	db 3Fh,0h,0h,3Ch,0Fh,0h,0h,0FFh,0Fh,0C0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp2B label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0FFh,0FCh,0h,0h,3Ch
	db 0h,0h,0h,3Ch,0h,0h,0h,3Ch,0h,0h,0h,3Ch,0h,0h,0h,3Ch
	db 3h,0h,0h,3Ch,3h,0h,0h,3Ch,3h,0h,0h,3Ch,3h,0h,0h,3Ch
	db 0Fh,0h,0h,3Ch,3Fh,0h,0h,0FFh,0FFh,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp2C label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3Fh,0FCh,0h,0h,0F3h
	db 0CFh,0h,3h,0C3h,0C3h,0C0h,0Fh,0C3h,0C3h,0F0h,0Fh,3h,0C0h,0F0h,3Fh,3h
	db 0C0h,0FCh,3Fh,3h,0C0h,0FCh,0Fh,3h,0C0h,0F0h,0Fh,0C3h,0C3h,0F0h,3h,0C3h
	db 0C3h,0C0h,0h,0C3h,0C3h,0h,0Fh,0CFh,0F3h,0F0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp2D label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3Fh,0C0h,0h,0h,0F0h
	db 0F0h,0h,3h,0F0h,3Ch,0h,0h,0F0h,3Fh,0h,0h,0F0h,0Fh,0h,0h,0F0h
	db 0Fh,0C0h,0h,0F0h,0Fh,0C0h,0h,0F0h,0Fh,0h,0h,0F0h,3Fh,0h,0h,0F0h
	db 3Ch,0h,0h,0F0h,30h,0h,3h,0FCh,3Fh,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp2E label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3h,0C0h,0h,0h,0Fh
	db 0F0h,0h,0h,3Ch,3Ch,0h,0h,0FCh,3Fh,0h,0h,0F0h,0Fh,0h,3h,0F0h
	db 0Fh,0C0h,3h,0F0h,0Fh,0C0h,0h,0F0h,0Fh,0h,0h,0FCh,3Fh,0h,0h,3Ch
	db 3Ch,0h,0h,0Fh,0F0h,0h,0h,3h,0C0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp2F label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0Fh,0F0h,0h,0h,3Ch
	db 3Ch,0h,0h,0FCh,0Fh,0h,0h,3Ch,0Fh,0C0h,0h,3Ch,0Fh,0C0h,0h,3Ch
	db 0Fh,0h,0h,3Ch,3Ch,0h,0h,3Ch,0F0h,0h,0h,3Ch,0h,0h,0h,3Ch
	db 0h,0h,0h,3Ch,0h,0h,0h,0FFh,0F0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp30 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FCh,0FFh,0FFh,0FFh,0FCh,0F3h,33h,33h,3Ch,0F3h,33h
	db 33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h
	db 33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h
	db 33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h
	db 33h,3Ch
TileBmp31 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3Fh,0C0h,0h,0h,0F0h
	db 0F0h,0h,3h,0F0h,3Ch,0h,0h,0F0h,3Fh,0h,0h,0F0h,3Fh,0h,0h,0F0h
	db 3Ch,0h,0h,0F3h,0F0h,0h,0h,0F0h,30h,0h,0h,0F0h,3Ch,0h,0h,0F0h
	db 0Fh,0h,0h,0F0h,0Fh,0h,3h,0FCh,0Fh,0C0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp32 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3h,0FFh,0h,0h,0Fh
	db 3Ch,0h,0h,3Ch,0Ch,0h,0h,0FFh,0h,0h,0h,0FFh,0h,0h,0h,3Fh
	db 0C0h,0h,0h,0Fh,0F0h,0h,0h,3h,0FCh,0h,0h,0h,0FFh,0h,0h,0C0h
	db 0FFh,0h,0h,0F3h,0F0h,0h,0h,0FFh,0C0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp33 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,3h,0FFh,0FFh,0C0h,0h,0F3h
	db 0CFh,0h,0h,0C3h,0C3h,0h,0h,0C3h,0C3h,0h,0h,3h,0C0h,0h,0h,3h
	db 0C0h,0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,0h,3h
	db 0C0h,0h,0h,3h,0C0h,0h,0h,0Fh,0F0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp34 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0FCh,0Fh,0C0h,0h,0Ch
	db 0Fh,0h,0h,3Ch,0Fh,0h,0h,0FCh,0Fh,0h,0h,0F0h,0Fh,0h,3h,0F0h
	db 0Fh,0h,3h,0F0h,0Fh,0h,0h,0F0h,0Fh,0h,0h,0FCh,0Fh,0h,0h,3Ch
	db 0Fh,0C0h,0h,3Ch,3Ch,0h,0h,0Fh,0F0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp35 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,3h,0F0h,0F0h,0h,0h,30h
	db 3Ch,0h,0h,0F0h,0Fh,0h,3h,0F0h,0Fh,0C0h,3h,0C0h,3h,0C0h,0Fh,0C0h
	db 3h,0F0h,0Fh,0C0h,3h,0F0h,3h,0C0h,3h,0C0h,3h,0F0h,0Fh,0C0h,0h,0F0h
	db 0Fh,0h,0h,3Ch,3Ch,0h,0h,0Fh,0F0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp36 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0Fh,0C3h,0C3h,0F0h,0h,0C3h
	db 0C3h,0h,3h,0C3h,0C3h,0C0h,0Fh,0C3h,0C3h,0F0h,0Fh,3h,0C0h,0F0h,3Fh,3h
	db 0C0h,0FCh,3Fh,3h,0C0h,0FCh,0Fh,3h,0C0h,0F0h,0Fh,0C3h,0C3h,0F0h,3h,0C3h
	db 0C3h,0C0h,0h,0F3h,0CFh,0h,0h,3Fh,0FCh,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp37 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0Fh,0F0h,3Fh,0C0h,3h,0C0h
	db 0Fh,0h,3h,0F0h,3Ch,0h,0h,0FCh,0F0h,0h,0h,0FFh,0C0h,0h,0h,3Fh
	db 0C0h,0h,0h,0Fh,0F0h,0h,0h,3Fh,0FCh,0h,0h,0F0h,0FCh,0h,3h,0C0h
	db 3Fh,0h,0Fh,0h,0Fh,0h,0Fh,0C0h,3Fh,0C0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp38 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3Ch,3Fh,0C0h,0h,0Ch
	db 0Fh,0h,0h,3Ch,0Fh,0h,0h,0FCh,0Fh,0h,3h,0F0h,0Fh,0h,3h,0F0h
	db 0Fh,0h,0h,0FCh,0Fh,0h,0h,3Ch,0Fh,0h,0h,0Fh,0FFh,0h,0h,0C0h
	db 0Fh,0h,0h,0F0h,3Ch,0h,0h,0FFh,0F0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp39 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,3h,0FFh,0FFh,0h,3h,0C0h
	db 0FCh,0h,3h,0h,0FCh,0h,0h,3h,0F0h,0h,0h,3h,0F0h,0h,0h,0Fh
	db 0C0h,0h,0h,0Fh,0C0h,0h,0h,3Fh,3h,0h,0h,3Fh,3h,0h,0h,0FCh
	db 3h,0h,0h,0FCh,0Fh,0h,3h,0FFh,0FFh,0C0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp3A label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,3h,0h,0h,0h,3h,0h,0h
	db 0h,3h,0h,0h,0h,3h,0h,0h,0h,3h,0h,0h,0h,3h,0h,0h
	db 0h,3h,0h,0h,0h,3h,0h,0h,0h,3h,0h,0h,0h,3h,0h,0h
	db 0h,3h,0h,0h,0h,3h,0h,0h,0h,3h,0h,0h,0h,3h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp3B label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0C0h,0h,0h,0h,0C0h,0h,0h,0h,0C0h,0h
	db 0h,0h,0C0h,0h,0h,0h,0C0h,0h,0h,0h,0C0h,0h,0h,0h,0C0h,0h
	db 0h,0h,0C0h,0h,0h,0h,0C0h,0h,0h,0h,0C0h,0h,0h,0h,0C0h,0h
	db 0h,0h,0C0h,0h,0h,0h,0C0h,0h,0h,0h,0C0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
TileBmp3C label byte
	db 4h,10h,0h,0h,0h,0h,0h,0Fh,0C0h,0h,0h,0Fh,0C0h,0h,0h,0Fh
	db 0C0h,0h,0h,3h,0h,0h,0h,0FFh,0FCh,0h,3h,3Fh,0F3h,0h,0Ch,0Fh
	db 0C0h,0C0h,3h,3h,3h,0h,0h,0CFh,0CCh,0h,0h,0Fh,0C0h,0h,0h,3Ch
	db 0F0h,0h,0h,30h,30h,0h,0h,30h,30h,0h,0h,0F0h,3Ch,0h,0h,0h
	db 0h,0h
TileBmp3D label byte
	db 4h,10h,0h,0h,0h,0h,0h,3Fh,0h,0C0h,0h,3Fh,0h,0C0h,0h,3Fh
	db 0Fh,0FCh,0h,0Ch,0h,0C0h,3h,0FFh,0F0h,0C0h,0Ch,0FFh,0CCh,0C0h,0Ch,3Fh
	db 3h,0C0h,0Ch,0Ch,0h,0C0h,0Ch,3Fh,0h,0h,0h,0F3h,0C0h,0h,0h,0C0h
	db 0C0h,0h,0h,0C0h,0C0h,0h,0h,0C0h,0C0h,0h,3h,0C0h,0F0h,0h,0h,0h
	db 0h,0h
TileBmp3E label byte
	db 4h,10h,0h,0h,0h,0h,0h,0Fh,0C0h,0h,0h,0Fh,0C0h,0Ch,0h,0Fh
	db 0C0h,0Ch,0h,3h,0h,0Ch,0h,0FFh,0FCh,0Ch,33h,3Fh,0F3h,3Ch,0Ch,0Fh
	db 0C0h,0CCh,0h,3h,0h,0Ch,0h,0Fh,0C0h,0Ch,0h,3Ch,0F0h,0Ch,0h,30h
	db 30h,0Ch,0h,30h,30h,0Ch,0h,30h,30h,0Ch,0h,0F0h,3Ch,0Ch,0h,0h
	db 0h,0h
TileBmp3F label byte
	db 4h,10h,0h,0h,0h,0h,0h,3Fh,0h,0h,0h,3Fh,0h,0h,0h,3Fh
	db 0h,0h,0h,0Ch,0h,0h,3h,0FFh,0FCh,0h,0Ch,0FFh,0CCh,0Ch,0Ch,3Fh
	db 0Ch,30h,0Ch,0Ch,0Ch,0C0h,0Ch,3Fh,3h,0h,0Ch,3Fh,0Ch,0C0h,0h,0F3h
	db 0C0h,0h,0h,0C0h,0C0h,0h,0h,0C0h,0C0h,0h,3h,0C0h,0F0h,0h,0h,0h
	db 0h,0h
D_END label byte	; end of the initialised data; BSS buffers and stack follow
STACK_PARA equ (D_END-D_START+1A50h+15)/16	; paragraphs of data, BSS and buffers: SS = DS+this
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA
END
