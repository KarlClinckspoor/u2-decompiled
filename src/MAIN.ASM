; MAIN.ASM: command jump table (A-Z), game start, the outdoor main loop and movement.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 0730-0E70.
;
; The heart of the game on a map (outdoors and in villages, towns and castles):
;   CmdJumpTbl  the command jump table, one word per letter A-Z (manual: Attack ... Ztatus)
;   GameStart  game start ('P' in the menu): read PLAYER, MONSTERS, the map and its monsters, set
;          up the map window and the status lines
;   MainLoop  the main loop: "CMD: " prompt, key (or idle "PASS" after a while), the four
;          arrow-key moves, Space = pass, A-Z through the jump table. Dungeons and towers
;          (MapType >= 4) go to the DUNGEON loop DungeonLoop instead.
;   EndCommandBeep/EndCommand  end of every command (EndCommandBeep beeps first): the monsters' turn, dispatched
;          on the map type MapType; outdoors here (OutdoorMonsters), else EVENTS
;          (TownTurnVillage/DungeonTurnDungeon/DungeonTurnTower)
;   MonsterTurn  one monster: ranged spells, then move towards the player (MonsterStepToward) or attack
;   EndTurn  end of the turn: show the attacks, apply the damage, count down the
;          paralysis/sleep/negate timers, back to MainLoop
;   PlayerDies  the player's death ("... IS DEAD!", hangs)
;   SpawnMonster  outdoors: maybe spawn a new monster in a free slot
; Data mostly used: the position PlayerX/PlayerY, the map type MapType, the player figure
; PlayerTile and the tiles around it TileHere-TileWest, the BCD hit points HitPointsHi/HitPointsLo and food
; FoodHi-FoodFrac, the timers TimeStopTurns-SleepTurns, the 32-slot monster table (MonsterX X, MonsterY Y,
; MonsterHP hit points, MonsterTile map code (0 = free), MonsterUnder terrain under it), and the
; per-turn counters Temp20 (attacks), Temp21 (hits), Temp22 (damage), which double as the
; idle timer at the prompt.
; Dead code: 0778 "(INSERT PLAYER DISK)" (jumped over by the 1989 patch).
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN PlayerX:BYTE, PlayerY:BYTE, MapCellPtr:BYTE, OffMapTile:BYTE, PlayerTile:BYTE, TileHere:BYTE
	EXTRN TileNorth:BYTE, TileSouth:BYTE, TileEast:BYTE, TileWest:BYTE, DeltaX:BYTE, DeltaY:BYTE
	EXTRN Temp1F:BYTE, Temp20:BYTE, Temp21:BYTE, Temp22:BYTE, LookX:BYTE, LookY:BYTE
	EXTRN LightTurns:BYTE, AmountHi:BYTE, Temp29:BYTE, PlayerRecord:BYTE, PlayerClass:BYTE, MapType:BYTE
	EXTRN HitPointsHi:BYTE, HitPointsLo:BYTE, FoodHi:BYTE, FoodLo:BYTE, FoodFrac:BYTE, ExpHi:BYTE
	EXTRN ExpLo:BYTE, GoldHi:BYTE, GoldLo:BYTE, SurfaceX:BYTE, SurfaceY:BYTE, LastKey:BYTE
	EXTRN SpawnCounter:BYTE, WornArmour:BYTE, RocketParked:BYTE, RocketX:BYTE, RocketY:BYTE, SpeedSetting:BYTE
	EXTRN MonsterX:BYTE, MonsterY:BYTE, MonsterHP:BYTE, MonsterTile:BYTE, MonsterUnder:BYTE, TimeStopTurns:BYTE
	EXTRN LegsParalyzed:BYTE, ArmsParalyzed:BYTE, SleepTurns:BYTE, KeyNorth:BYTE, KeySouth:BYTE, KeyEast:BYTE
	EXTRN KeyWest:BYTE, TileCache:BYTE, TileCacheShown:BYTE, MonsterBufPtr:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN SetDefaultSpeed:NEAR, CalcDelayTbl:NEAR, SpeedDelay:NEAR, SpellParalyzeLegs:NEAR, SpellParalyzeArms:NEAR
	EXTRN SpellMagicMissile:NEAR
	EXTRN SpellSleep:NEAR, ThiefStealItem:NEAR, TownTurnVillage:NEAR, TownTurnTowne:NEAR, TownTurnCastle:NEAR
	EXTRN TownTurnNextMonster:NEAR
	EXTRN DungeonTurnDungeon:NEAR, DungeonTurnTower:NEAR, MonsterStepToward:NEAR, IllegalCommand:NEAR
	EXTRN DieOfStarvation:NEAR, LoadMapAndMonsters:NEAR
	EXTRN CheckStep:NEAR, MoveTimeDoor:NEAR, DungeonLoop:NEAR, CmdAttack:NEAR, CmdBoard:NEAR, CmdCast:NEAR
	EXTRN CmdDescend:NEAR, CmdEnter:NEAR, CmdFire:NEAR, CmdGet:NEAR, CmdHyperspace:NEAR, CmdIgniteTorch:NEAR
	EXTRN CmdJump:NEAR, CmdKlimb:NEAR, CmdLaunch:NEAR, CmdMagic:NEAR, CmdNegateTime:NEAR, CmdOffer:NEAR
	EXTRN CmdPass:NEAR, CmdQuit:NEAR, CmdReady:NEAR, CmdSteal:NEAR, CmdTransact:NEAR, CmdUnlock:NEAR
	EXTRN CmdView:NEAR, CmdWear:NEAR, CmdXit:NEAR, CmdYell:NEAR, CmdZtats:NEAR, SetTextMode:NEAR
	EXTRN SetGraphicsMode:NEAR, AnimateWater:NEAR, AnimateForceField:NEAR, DirToPlayer:NEAR, DistToPlayer:NEAR
	EXTRN ReadKey:NEAR
	EXTRN PrintInline:NEAR, PrintPlayerName:NEAR, GetMapSquare:NEAR, AbsOf:NEAR, DrawStatusLines:NEAR
	EXTRN SetCursor:NEAR
	EXTRN Random:NEAR, XorPlayerMark:NEAR, ReadWriteFile:NEAR, PutChar:NEAR, UpdateMapView:NEAR, Beep:NEAR
	EXTRN PlayAttackSound:NEAR, PlayStepSound:NEAR, PlayHurtSound:NEAR
	PUBLIC GameStart, MainLoop, DispatchCommand, EndCommandBeep, EndCommand, OutdoorMonsters_Next
	PUBLIC MonsterTurn, EndTurn, PlayerDies
ASSUME CS:CODE, DS:DATA

;------------------------------------------------------------------------------
; CmdJumpTbl: command jump table, one handler per letter A-Z (index (key-'A')*2,
; read at 0A29, `jmp bx` at 0A2E). Names as in the manual. The handlers (CMDAL,
; CMDMZ) print their name and end with jmp EndCommand / EndCommandBeep.
;------------------------------------------------------------------------------
CmdJumpTbl:	dw CmdAttack	; A Attack	;@0730
	dw CmdBoard	; B Board	;@0732
	dw CmdCast	; C Cast	;@0734
	dw CmdDescend	; D Descend	;@0736
	dw CmdEnter	; E Enter	;@0738
	dw CmdFire	; F Fire	;@073A
	dw CmdGet	; G Get	;@073C
	dw CmdHyperspace	; H Hyperspace	;@073E
	dw CmdIgniteTorch	; I Ignite (a torch)	;@0740
	dw CmdJump	; J Jump	;@0742
	dw CmdKlimb	; K Klimb	;@0744
	dw CmdLaunch	; L Launch	;@0746
	dw CmdMagic	; M Magic	;@0748
	dw CmdNegateTime	; N Negate	;@074A
	dw CmdOffer	; O Offer	;@074C
	dw CmdPass	; P Pass	;@074E
	dw CmdQuit	; Q Quit (save)	;@0750
	dw CmdReady	; R Ready	;@0752
	dw CmdSteal	; S Steal	;@0754
	dw CmdTransact	; T Transact	;@0756
	dw CmdUnlock	; U Unlock	;@0758
	dw CmdView	; V View	;@075A
	dw CmdWear	; W Wear	;@075C
	dw CmdXit	; X Xit	;@075E
	dw CmdYell	; Y Yell	;@0760
	dw CmdZtats	; Z Ztatus	;@0762

;------------------------------------------------------------------------------
; GameStart: game start ('P' in the menu, START 03AC). Reads
; the 256-byte PLAYER record to PlayerRecord (an empty name means "NO CHARACTER ON
; DISK": wait for Escape and try again, forever), resets the delay table from
; the saved speed SpeedSetting, reads MONSTERS (800h bytes) to the buffer at MonsterBufPtr,
; then the map and monster files of the saved place (LoadMapAndMonsters), CGA mode, the
; player on foot (figure 78h + 2 * class) at the saved surface position
; SurfaceX/SurfaceY, timers cleared, the parked rocket (RocketParked) put back on the
; map, the map window drawn and the status lines shown. Falls into MainLoop.
; Out: does not return.
;------------------------------------------------------------------------------
GameStart:	call SetTextMode	; text mode, clear	;@0764
	mov bh, 0	;@0767
	mov bl, 0Ch	;@0769
	mov si, bx	;@076B
	mov bh, 0	;@076D
	mov bl, 0Ah	;@076F
	mov di, bx	;@0771
	call SetCursor	; cursor to column 10, row 12	;@0773
	jmp short GameStart_LoadPlayer	; 1989 patch over a `call PrintInline` (E8 66 48): 48h left	;@0776
;
; Dead (jumped over): the rest of `call PrintInline` "(INSERT PLAYER DISK)", then
; wait for Escape (call ReadKey; cmp ax,0FF1Bh; jne 078E).
;
	db 48h,28h,49h,4Eh,53h,45h,52h,54h,20h,50h,4Ch,41h,59h,45h,52h,20h	;@0778
	db 44h,49h,53h,4Bh,29h,0h,0E8h,0BCh,47h,3Dh,1Bh,0FFh,75h,0F8h	;@0788
GameStart_LoadPlayer:	mov cx, 100h	; 256 bytes	;@0796
	lea dx, PlayerRecord	; the player record (starts with the name)	;@0799
	mov ah, 27h	; read	;@079D
	call ReadWriteFile	;@079F
	db 50h,4Ch,41h,59h,45h,52h,20h,20h	; "PLAYER  "	;@07A2
	mov al, byte ptr PlayerRecord	; empty name: no character	;@07AA
	or al, al	;@07AD
	jne GameStart_Speed	;@07AF
	call SetTextMode	;@07B1
	mov bh, 0	;@07B4
	mov bl, 0Ch	;@07B6
	mov si, bx	;@07B8
	mov bh, 0	;@07BA
	mov bl, 0Ah	;@07BC
	mov di, bx	;@07BE
	call SetCursor	;@07C0
	call PrintInline	;@07C3
	db 4Eh,4Fh,20h,43h,48h,41h,52h,41h,43h,54h,45h,52h,20h,4Fh,4Eh,20h	; "NO CHARACTER ON DISK"	;@07C6
	db 44h,49h,53h,4Bh,0h	;@07D6
GameStart_NoCharWait:	call ReadKey	;@07DB
	cmp ax, 0FF1Bh	; Escape: read PLAYER again	;@07DE
	jne GameStart_NoCharWait	;@07E1
	jmp GameStart	;@07E3
;
; SpeedSetting (speed setting) is part of the PLAYER record; 0 = never set.
;
GameStart_Speed:	cmp word ptr SpeedSetting, 0	;@07E6
	jne GameStart_Setup	;@07EB
	call SetDefaultSpeed	; default 0FFh	;@07ED
GameStart_Setup:	call CalcDelayTbl	; delay table from the saved speed	;@07F0
	mov cx, 800h	;@07F3
	mov dx, word ptr MonsterBufPtr	; monster buffer	;@07F6
	mov ah, 27h	;@07FA
	call ReadWriteFile	;@07FC
	db 4Dh,4Fh,4Eh,53h,54h,45h,52h,53h	; "MONSTERS"	;@07FF
	call LoadMapAndMonsters	; map MAPxx and monster table MONxx (MonsterX) of the saved place	;@0807
	call SetGraphicsMode	; CGA mode 4	;@080A
	mov al, byte ptr PlayerClass	; class 0-3 (fighter, cleric, wizard, thief)	;@080D
	add al, al	;@0810
	clc	;@0812
	adc al, 78h	;@0813
	mov byte ptr PlayerTile, al	; player figure 78h + 2 * class: on foot	;@0815
	mov al, 0	;@0818
	mov byte ptr TimeStopTurns, al	; negate timer	;@081A
	mov byte ptr LegsParalyzed, al	; legs paralysed	;@081D
	mov byte ptr ArmsParalyzed, al	; arms paralysed	;@0820
	mov byte ptr SleepTurns, al	; asleep	;@0823
	mov al, byte ptr SurfaceX	;@0826
	mov byte ptr PlayerX, al	; X = saved surface X	;@0829
	mov al, byte ptr SurfaceY	;@082C
	mov byte ptr PlayerY, al	; Y = saved surface Y	;@082F
	mov al, byte ptr RocketParked	; a rocket parked somewhere?	;@0832
	or al, al	;@0835
	je GameStart_ClearCache	;@0837
	mov al, byte ptr RocketX	;@0839
	mov byte ptr LookX, al	;@083C
	mov al, byte ptr RocketY	;@083F
	mov byte ptr LookY, al	;@0842
	call GetMapSquare	; MapCellPtr -> map cell at (LookX, LookY), SI = 0	;@0845
	mov al, 50h	; rocket (map code 50h = figure 28h)	;@0848
	mov bx, word ptr MapCellPtr	;@084A
	mov byte ptr [bx+si], al	;@084E
;
; Fill both tile caches of the map window with 0FFh so UpdateMapView redraws every
; tile. (Entries FEh..0; entry FFh is left alone, CMDAL 3964 does all 256.)
;
GameStart_ClearCache:	nop	;@0850
	mov bh, 0	;@0851
	mov bl, 0FFh	;@0853
	mov di, bx	;@0855
	mov al, 0FFh	;@0857
GameStart_CacheLoop:	dec di	;@0859
	mov byte ptr TileCache[di], al	;@085A
	mov byte ptr TileCacheShown[di], al	;@085E
	jne GameStart_CacheLoop	;@0862
	call UpdateMapView	; draw the map window	;@0864
	mov al, 0FFh	;@0867
	mov byte ptr OffMapTile, al	; map wraps around (surface)	;@0869
	call DrawStatusLines	; status lines: H.P., FOOD, EXP., GOLD	;@086C

;------------------------------------------------------------------------------
; MainLoop: the main loop, top: one player command per pass. Also jumped to from
; EVENTS (12D8). Resets SP. In a tower or dungeon (MapType >= 4) the DUNGEON
; loop DungeonLoop takes over. Prints "CMD: ", animates the water tiles, then:
; asleep (SleepTurns) -> 20 'Z's and the turn is lost; otherwise wait for a key
; (MainLoop_WaitKey).
;------------------------------------------------------------------------------
MainLoop:	nop	;@086F
	mov sp, 100h	; forget any pending returns	;@0870
	mov al, byte ptr MapType	; map type: 0 surface, 1 village, 2 town, 3 castle, 4 tower, 5 dungeon	;@0873
	cmp al, 4	;@0876
	jb MainLoop_Prompt	;@0878
	jmp DungeonLoop	;@087A
MainLoop_Prompt:	nop	;@087D
	call PrintInline	;@087E
	db 43h,4Dh,44h,3Ah,20h,0h	; "CMD: "	;@0881
;
; AnimateWater scrolls the bitmap of the first tile (water) by one row, AnimateForceField that of
; tile record 23 (ForceFieldTilePtr); here 4 rows and 1 row. Seen at the next map redraw.
;
	call AnimateWater	;@0887
	call AnimateWater	;@088A
	call AnimateWater	;@088D
	call AnimateWater	;@0890
	call AnimateForceField	;@0893
	mov al, 0	;@0896
	mov byte ptr Temp21, al	; idle timer, low (counts key polls)	;@0898
	mov al, 0C0h	;@089B
	mov byte ptr Temp22, al	; idle timer, high: 40h x 256 polls until "PASS"	;@089D
	mov al, byte ptr SleepTurns	; asleep?	;@08A0
	or al, al	;@08A3
	je MainLoop_WaitKey	;@08A5
	mov al, 14h	;@08A7
	mov byte ptr AmountHi, al	; 20 'Z's	;@08A9
MainLoop_Sleep:	call PrintInline	;@08AC
	db 5Ah,0h	; "Z"	;@08AF
	mov bh, 0	;@08B1
	mov bl, 0FFh	;@08B3
	mov di, bx	;@08B5
MainLoop_SleepDelay:	dec di	; short busy loop, CPU-speed dependent	;@08B7
	nop	;@08B8
	nop	;@08B9
	nop	;@08BA
	nop	;@08BB
	nop	;@08BC
	jne MainLoop_SleepDelay	;@08BD
	dec byte ptr AmountHi	;@08BF
	jne MainLoop_Sleep	;@08C3
	jmp EndCommand	; the monsters move	;@08C5
;
; Wait for a key. Every 256 polls: plane engine sound (when flying, PlayerTile =
; 26h), redraw the map window (animated tiles), scroll the tiles again. After
; 40h x 256 polls without a key the turn passes by itself ("PASS").
;
MainLoop_WaitKey:	mov bx, 0	; delay table entry 0	;@08C8
	call SpeedDelay	;@08CB
	call ReadKey	; AH = FFh: key in AL (upper case)	;@08CE
	cmp ah, 0FFh	;@08D1
	je MainLoop_GotKey	;@08D4
	inc byte ptr Temp21	;@08D6
	jne MainLoop_WaitKey	;@08DA
	mov al, byte ptr PlayerTile	;@08DC
	cmp al, 26h	; plane?	;@08DF
	jne MainLoop_Animate	;@08E1
	call PlayStepSound	; engine sound	;@08E3
MainLoop_Animate:	nop	;@08E6
	call UpdateMapView	;@08E7
	call AnimateWater	;@08EA
	call AnimateWater	;@08ED
	call AnimateWater	;@08F0
	call AnimateWater	;@08F3
	call AnimateForceField	;@08F6
	inc byte ptr Temp22	;@08F9
	jne MainLoop_WaitKey	;@08FD
	mov al, 0	;@08FF
	mov byte ptr LightTurns, al	; idle pass resets the horse half-turn	;@0901
	call PrintInline	;@0904
	db 50h,41h,53h,53h,0h	; "PASS"	;@0907
;
; MainLoop_PassTurn: a turn passes without moving: food -= 0.1 (BCD FoodHi FoodLo . FoodFrac;
; 6502 style: stc/cmc + sbb = SBC with carry, das after each byte). Running out
; of food is death (DieOfStarvation -> PlayerDies).
;
MainLoop_PassTurn:	stc	;@090C
	mov al, byte ptr FoodFrac	; food, hundredths	;@090D
	cmc	;@0910
	sbb al, 0Ah	; minus 10 hundredths (das fixes it to BCD)	;@0911
	das	;@0913
	cmc	; CF = 1: no borrow (6502 carry)	;@0914
	mov byte ptr FoodFrac, al	;@0915
	mov al, byte ptr FoodLo	; food, low two digits	;@0918
	cmc	;@091B
	sbb al, 0	;@091C
	das	;@091E
	cmc	;@091F
	mov byte ptr FoodLo, al	;@0920
	mov al, byte ptr FoodHi	; food, high two digits	;@0923
	cmc	;@0926
	sbb al, 0	;@0927
	das	;@0929
	cmc	;@092A
	mov byte ptr FoodHi, al	;@092B
	jb L0933	; no borrow: still food left	;@092E
	jmp DieOfStarvation	; starved: PlayerDies	;@0930
L0933:	jmp EndCommand	;@0933
;
; MainLoop_GotKey: a key was pressed. Space = pass, then the four direction keys
; KeyNorth-KeyWest (what ReadKey makes of the arrow keys: N 0Eh, S 19h, E 05h,
; W 17h). A move changes PlayerX/PlayerY first and lets CheckStep (MOVE) judge the
; tile entered (AL = TileNorth-TileWest, the tile in that direction): AL = 0 means
; the move is allowed, otherwise it is undone ("--INVALID MOVE!").
;
MainLoop_GotKey:	mov byte ptr LastKey, al	; the last key (only used here)	;@0936
	mov al, byte ptr LastKey	;@0939
	cmp al, 20h	; Space = pass	;@093C
	jne MainLoop_North	;@093E
	mov al, 0	;@0940
	mov byte ptr LightTurns, al	;@0942
	call PrintInline	;@0945
	db 50h,41h,53h,53h,0h	; "PASS"	;@0948
	jmp MainLoop_PassTurn	;@094D
MainLoop_North:	cmp al, byte ptr KeyNorth	; north (up arrow)	;@094F
	jne MainLoop_South	;@0953
	dec byte ptr PlayerY	;@0955
	call PrintInline	;@0959
	db 4Eh,4Fh,52h,54h,48h,0h	; "NORTH"	;@095C
	mov al, byte ptr TileNorth	; tile north of the player	;@0962
	call CheckStep	;@0965
	cmp al, 0	;@0968
	je L0973	;@096A
	inc byte ptr PlayerY	; blocked: undo	;@096C
	jmp MainLoop_InvalidMove	;@0970
L0973:	jmp MainLoop_MoveDone	;@0973
MainLoop_South:	cmp al, byte ptr KeySouth	; south (down arrow)	;@0976
	jne MainLoop_West	;@097A
	inc byte ptr PlayerY	;@097C
	call PrintInline	;@0980
	db 53h,4Fh,55h,54h,48h,0h	; "SOUTH"	;@0983
	mov al, byte ptr TileSouth	;@0989
	call CheckStep	;@098C
	cmp al, 0	;@098F
	je L099A	;@0991
	dec byte ptr PlayerY	;@0993
	jmp MainLoop_InvalidMove	;@0997
L099A:	jmp MainLoop_MoveDone	;@099A
MainLoop_West:	cmp al, byte ptr KeyWest	; west (left arrow)	;@099D
	jne MainLoop_East	;@09A1
	dec byte ptr PlayerX	;@09A3
	call PrintInline	;@09A7
	db 57h,45h,53h,54h,0h	; "WEST"	;@09AA
	mov al, byte ptr TileWest	;@09AF
	call CheckStep	;@09B2
	cmp al, 0	;@09B5
	je L09C0	;@09B7
	inc byte ptr PlayerX	;@09B9
	jmp MainLoop_InvalidMove	;@09BD
L09C0:	jmp MainLoop_MoveDone	;@09C0
MainLoop_East:	cmp al, byte ptr KeyEast	; east (right arrow)	;@09C3
	jne MainLoop_Command	;@09C7
	inc byte ptr PlayerX	;@09C9
	call PrintInline	;@09CD
	db 45h,41h,53h,54h,0h	; "EAST"	;@09D0
	mov al, byte ptr TileEast	;@09D5
	call CheckStep	;@09D8
	cmp al, 0	;@09DB
	je L09E6	;@09DD
	dec byte ptr PlayerX	;@09DF
	jmp MainLoop_InvalidMove	;@09E3
L09E6:	jmp MainLoop_MoveDone	;@09E6
;
; A successful move flips LightTurns. On horseback the slow monsters only move
; when LightTurns is 0 (see 0A83): the horse is twice as fast.
;
MainLoop_MoveDone:	mov al, byte ptr LightTurns	;@09E9
	xor al, 0FFh	;@09EC
	mov byte ptr LightTurns, al	;@09EE
	jmp EndCommand	;@09F1
MainLoop_Command:	push ax	;@09F4
	mov al, 0	;@09F5
	mov byte ptr LightTurns, al	; any command resets the horse half-turn	;@09F7
	pop ax	;@09FA
;
; DispatchCommand: dispatch a command key A-Z through CmdJumpTbl (also entered from the
; DUNGEON loop at 285E). Others: "-ILLEGAL COMMAND!" (IllegalCommand).
; In: AL = key (upper case).
;
DispatchCommand:	cmp al, 41h	; 'A'	;@09FB
	jae L0A18	;@09FD
	jmp IllegalCommand	;@09FF
MainLoop_InvalidMove:	call PrintInline	;@0A02
	db 2Dh,2Dh,49h,4Eh,56h,41h,4Ch,49h,44h,20h,4Dh,4Fh,56h,45h,21h,0h	; "--INVALID MOVE!"	;@0A05
	jmp EndCommandBeep	;@0A15
L0A18:	cmp al, 5Ah	; 'Z'	;@0A18
	jbe DispatchCommand_Go	;@0A1A
	jmp IllegalCommand	;@0A1C
DispatchCommand_Go:	stc	;@0A1F
	cmc	;@0A20
	sbb al, 41h	; AL - 'A' (6502 SEC/SBC, carry clear = no borrow in)	;@0A21
	add al, al	;@0A23
	mov ah, 0	;@0A25
	mov si, ax	;@0A27
	mov bx, word ptr cs:CmdJumpTbl[si]	;@0A29
	jmp bx	; the only indirect jump in the program	;@0A2E

;------------------------------------------------------------------------------
; EndCommandBeep: end of a command that failed: error beep (Beep), then EndCommand.
; EndCommand: end of a command: new line, clear the turn counters Temp20-Temp22,
; then the monsters' turn according to the map type MapType: outdoors OutdoorMonsters
; below; village/town/castle TownTurnVillage/TownTurnTowne/TownTurnCastle and tower/dungeon
; DungeonTurnTower/DungeonTurnDungeon
; in EVENTS (they come back through MonsterTurn, EndTurn, MainLoop).
; Jumped to from nearly every command handler (about 130 places).
;------------------------------------------------------------------------------
EndCommandBeep:	call Beep	; error beep	;@0A30
EndCommand:	mov al, 0Dh	;@0A33
	call PutChar	; print CR	;@0A35
	mov al, 0	;@0A38
	mov byte ptr Temp22, al	; damage this turn	;@0A3A
	mov byte ptr Temp20, al	; attacks this turn	;@0A3D
	mov byte ptr Temp21, al	; hits this turn	;@0A40
	mov al, byte ptr MapType	;@0A43
	or al, al	;@0A46
	je OutdoorMonsters	;@0A48
	cmp al, 1	;@0A4A
	jne L0A51	;@0A4C
	jmp TownTurnVillage	;@0A4E
L0A51:	cmp al, 2	;@0A51
	jne L0A58	;@0A53
	jmp TownTurnTowne	;@0A55
L0A58:	cmp al, 3	;@0A58
	jne L0A5F	;@0A5A
	jmp TownTurnCastle	;@0A5C
L0A5F:	cmp al, 4	;@0A5F
	jne L0A66	;@0A61
	jmp DungeonTurnTower	;@0A63
L0A66:	cmp al, 5	;@0A66
	jne OutdoorMonsters	;@0A68
	jmp DungeonTurnDungeon	;@0A6A

;------------------------------------------------------------------------------
; OutdoorMonsters: the outdoor monsters' turn: monster slots 1Fh down to 1 (slot 0 is
; never used here). Free slots (MonsterTile = 0) are skipped. On horseback
; (PlayerTile = 22h) on the half-turns where LightTurns is negative, all but the fast
; monsters (map codes 48h, 3Ch, 2Ch) skip their move. Then SpawnMonster may spawn a
; new monster.
;------------------------------------------------------------------------------
OutdoorMonsters:	nop	;@0A6D
	mov bh, 0	;@0A6E
	mov bl, 1Fh	;@0A70
	mov di, bx	;@0A72
OutdoorMonsters_Loop:	mov al, byte ptr MonsterTile[di]	; map code of the monster, 0 = free slot	;@0A74
	or al, al	;@0A78
	je OutdoorMonsters_Next	;@0A7A
	mov al, byte ptr PlayerTile	;@0A7C
	cmp al, 22h	; on horseback?	;@0A7F
	jne MonsterTurn	;@0A81
	mov al, byte ptr LightTurns	;@0A83
	or al, al	;@0A86
	jns MonsterTurn	;@0A88
	mov al, byte ptr MonsterTile[di]	;@0A8A
	cmp al, 48h	;@0A8E
	je MonsterTurn	;@0A90
	cmp al, 3Ch	;@0A92
	je MonsterTurn	;@0A94
	cmp al, 2Ch	;@0A96
	je MonsterTurn	;@0A98
	mov al, byte ptr PlayerTile	; the same test again: always 22h here	;@0A9A
	cmp al, 22h	;@0A9D
	jne MonsterTurn	;@0A9F
OutdoorMonsters_Next:	dec di	; next monster (also entered from INPUT 2196/2272)	;@0AA1
	jne OutdoorMonsters_Loop	;@0AA2
	jmp SpawnMonster	;@0AA4

;------------------------------------------------------------------------------
; MonsterTurn: one monster's turn (also entered from EVENTS 1083 for town monsters).
; In: DI = monster slot. Within 2 squares (raw difference, no wrap) and with a
; 1 in 8 chance it casts by type (map code): 34h "LEGS PARALYZED!" (SpellParalyzeLegs),
; 38h "ARMS PARALYZED!" (SpellParalyzeArms), 0F8h "MAGIC MISSILE!" (SpellMagicMissile), 3Ch "SLEEP
; SPELL!" (SpellSleep). Then it steps one square towards the player (away from him
; when its hit points MonsterHP are below 0Fh): if that square is the player's it
; attacks (MonsterAttack), else MonsterStepToward (INPUT) moves it, which ends with jmp OutdoorMonsters_Next.
; Uses: DeltaX/DeltaY (deltas), Temp29 (slot), AmountHi.
;------------------------------------------------------------------------------
MonsterTurn:	call DistToPlayer	; DeltaX/DeltaY = player X/Y - monster X/Y	;@0AA7
	mov bx, di	;@0AAA
	mov byte ptr Temp29, bl	; save the slot	;@0AAC
	mov al, byte ptr DeltaX	;@0AB0
	call AbsOf	; absolute value	;@0AB3
	cmp al, 3	;@0AB6
	jae MonsterTurn_Step	;@0AB8
	mov al, byte ptr DeltaY	;@0ABA
	call AbsOf	;@0ABD
	cmp al, 3	;@0AC0
	jae MonsterTurn_Step	;@0AC2
	call Random	; random 0-FFh	;@0AC4
	mov bh, 0	;@0AC7
	mov bl, byte ptr Temp29	;@0AC9
	mov di, bx	;@0ACD
	cmp al, 20h	; 1 in 8	;@0ACF
	jae MonsterTurn_Step	;@0AD1
	mov al, byte ptr MonsterTile[di]	;@0AD3
	cmp al, 34h	;@0AD7
	jne L0AE1	;@0AD9
	call SpellParalyzeLegs	; legs paralysed (magical boots save)	;@0ADB
	jmp MonsterTurn_Step	;@0ADE
L0AE1:	cmp al, 38h	;@0AE1
	jne L0AEB	;@0AE3
	call SpellParalyzeArms	; arms paralysed (magical cloak saves)	;@0AE5
	jmp MonsterTurn_Step	;@0AE8
L0AEB:	cmp al, 0F8h	;@0AEB
	jne L0AF5	;@0AED
	call SpellMagicMissile	; magic missile: adds 2 attacks, 2 hits, 40h damage	;@0AEF
	jmp MonsterTurn_Step	;@0AF2
L0AF5:	cmp al, 3Ch	;@0AF5
	jne MonsterTurn_Step	;@0AF7
	call SpellSleep	; sleep spell (the idol saves)	;@0AF9
MonsterTurn_Step:	mov bh, 0	;@0AFC
	mov bl, byte ptr Temp29	;@0AFE
	mov di, bx	;@0B02
	call DirToPlayer	; DeltaX/DeltaY = direction to the player, -1/0/1 (with wrap)	;@0B04
	mov al, byte ptr MonsterHP[di]	; hit points	;@0B07
	cmp al, 0Fh	;@0B0B
	jae MonsterTurn_Target	;@0B0D
	stc	; weak: flee, negate the direction (0 - D)	;@0B0F
	mov al, 0	;@0B10
	cmc	;@0B12
	sbb al, byte ptr DeltaX	;@0B13
	mov byte ptr DeltaX, al	;@0B17
	stc	;@0B1A
	mov al, 0	;@0B1B
	cmc	;@0B1D
	sbb al, byte ptr DeltaY	;@0B1E
	mov byte ptr DeltaY, al	;@0B22
MonsterTurn_Target:	clc	;@0B25
	mov al, byte ptr MonsterX[di]	; monster X + DX = player X?	;@0B26
	adc al, byte ptr DeltaX	;@0B2A
	and al, 3Fh	;@0B2E
	cmp al, byte ptr PlayerX	;@0B30
	je L0B39	;@0B34
	jmp MonsterStepToward	; no: move it	;@0B36
L0B39:	clc	;@0B39
	mov al, byte ptr MonsterY[di]	; monster Y + DY = player Y?	;@0B3A
	adc al, byte ptr DeltaY	;@0B3E
	and al, 3Fh	;@0B42
	cmp al, byte ptr PlayerY	;@0B44
	je MonsterAttack	;@0B48
	jmp MonsterStepToward	;@0B4A
;
; MonsterAttack: the monster attacks. A thief (0FCh) may steal first (ThiefStealItem). Misses
; when the random number has bit 7 set, or when its low 3 bits are below the
; armour worn WornArmour. A hit adds (hit points / 4) + 1 to the damage Temp22,
; doubled when TileHere (the tile under the player) is 6 (woods?).
;
MonsterAttack:	inc byte ptr Temp20	; attacks this turn	;@0B4D
	mov bx, di	;@0B51
	mov byte ptr AmountHi, bl	;@0B53
	mov al, byte ptr MonsterTile[di]	;@0B57
	cmp al, 0FCh	; thief?	;@0B5B
	jne MonsterAttack_Roll	;@0B5D
	call ThiefStealItem	; steal	;@0B5F
MonsterAttack_Roll:	call Random	;@0B62
	mov bh, 0	;@0B65
	mov bl, byte ptr AmountHi	;@0B67
	mov di, bx	;@0B6B
	cmp al, 0	;@0B6D
	js MonsterAttack_Done	; miss (1 in 2)	;@0B6F
	and al, 7	;@0B71
	cmp al, byte ptr WornArmour	; armour worn	;@0B73
	jb MonsterAttack_Done	; miss	;@0B77
	inc byte ptr Temp21	; hits this turn	;@0B79
	mov al, byte ptr MonsterHP[di]	;@0B7D
	clc	;@0B81
	rcr al, 1	;@0B82
	clc	;@0B84
	rcr al, 1	; hit points / 4	;@0B85
	stc	; + 1	;@0B87
	adc al, byte ptr Temp22	;@0B88
	mov bh, 0	;@0B8C
	mov bl, byte ptr TileHere	; 6502 LDX $14 / CPX #6	;@0B8E
	mov si, bx	;@0B92
	mov bx, si	;@0B94
	cmp bl, 6	;@0B96
	jne L0B9D	;@0B99
	add al, al	;@0B9B
L0B9D:	mov byte ptr Temp22, al	;@0B9D
MonsterAttack_Done:	nop	;@0BA0
	mov al, byte ptr MapType	;@0BA1
	or al, al	;@0BA4
	je L0BAB	;@0BA6
	jmp TownTurnNextMonster	; not outdoors: back to the EVENTS monster loop	;@0BA8
L0BAB:	nop	;@0BAB
	jmp OutdoorMonsters_Next	;@0BAC

;------------------------------------------------------------------------------
; EndTurn: end of the turn (also entered from EVENTS 1078, and from the spawn
; code). Redraw the map window; for each attack Temp20 an attack sound, the
; first Temp21 of them also flash the player square (XorPlayerMark twice, XOR?) with
; the hit sound; then apply the damage Temp22: hit points (BCD HitPointsHi HitPointsLo)
; -= (random AND Temp22 AND 77h) + 1, a BCD number of at most 78. In a
; village/town/castle (or tower/dungeon) also MapType hundreds more (hence the
; deadly guards?). Hit points below 0: PlayerDies. Then the status lines, the
; off-map tile, the time doors (outdoors) and the four timers count down.
;------------------------------------------------------------------------------
EndTurn:	call UpdateMapView	;@0BAF
EndTurn_AttackLoop:	mov al, byte ptr Temp20	;@0BB2
	or al, al	;@0BB5
	je EndTurn_Damage	;@0BB7
	call PlayAttackSound	; attack sound	;@0BB9
	dec byte ptr Temp20	;@0BBC
	dec byte ptr Temp21	;@0BC0
	js EndTurn_AttackLoop	; no hits left: a miss	;@0BC4
	call XorPlayerMark	; mark the player square	;@0BC6
	call PlayHurtSound	; hit sound	;@0BC9
	call XorPlayerMark	; and unmark it	;@0BCC
	jmp EndTurn_AttackLoop	;@0BCF
EndTurn_Damage:	mov al, byte ptr Temp22	;@0BD1
	or al, al	;@0BD4
	je EndTurn_Status	;@0BD6
	call Random	;@0BD8
	and al, byte ptr Temp22	;@0BDB
	and al, 77h	; keeps both BCD digits <= 7	;@0BDF
	clc	;@0BE1
	adc al, 1	;@0BE2
	mov byte ptr Temp22, al	;@0BE4
	stc	;@0BE7
	mov al, byte ptr HitPointsLo	; hit points, low two digits	;@0BE8
	cmc	;@0BEB
	sbb al, byte ptr Temp22	;@0BEC
	das	;@0BF0
	cmc	;@0BF1
	mov byte ptr HitPointsLo, al	;@0BF2
	mov al, byte ptr HitPointsHi	; hit points, high two digits	;@0BF5
	cmc	;@0BF8
	sbb al, 0	;@0BF9
	das	;@0BFB
	cmc	;@0BFC
	mov byte ptr HitPointsHi, al	;@0BFD
	jae PlayerDies	; borrow: dead	;@0C00
	mov al, byte ptr MapType	;@0C02
	or al, al	;@0C05
	je EndTurn_Status	;@0C07
	mov byte ptr Temp22, al	;@0C09
	stc	;@0C0C
	mov al, byte ptr HitPointsHi	; hundreds -= map type (1-5)	;@0C0D
	cmc	;@0C10
	sbb al, byte ptr Temp22	;@0C11
	das	;@0C15
	cmc	;@0C16
	mov byte ptr HitPointsHi, al	;@0C17
	jae PlayerDies	;@0C1A
EndTurn_Status:	call DrawStatusLines	; status lines	;@0C1C
	mov al, 4	;@0C1F
	mov byte ptr OffMapTile, al	; off-map tile: 4 (grass) around a town	;@0C21
	mov al, byte ptr MapType	;@0C24
	or al, al	;@0C27
	jne EndTurn_Timers	;@0C29
	mov al, 0FFh	;@0C2B
	mov byte ptr OffMapTile, al	; outdoors: the map wraps	;@0C2D
	call MoveTimeDoor	; every 8 turns move the time door (DUNGEON)	;@0C30
;
; Count down the timers (each stops at 0).
;
EndTurn_Timers:	mov al, byte ptr LegsParalyzed	; legs paralysed	;@0C33
	or al, al	;@0C36
	je L0C3E	;@0C38
	dec byte ptr LegsParalyzed	;@0C3A
L0C3E:	mov al, byte ptr ArmsParalyzed	; arms paralysed	;@0C3E
	or al, al	;@0C41
	je L0C49	;@0C43
	dec byte ptr ArmsParalyzed	;@0C45
L0C49:	mov al, byte ptr SleepTurns	; asleep	;@0C49
	or al, al	;@0C4C
	je L0C54	;@0C4E
	dec byte ptr SleepTurns	;@0C50
L0C54:	mov al, byte ptr TimeStopTurns	; time stopped (Negate)	;@0C54
	or al, al	;@0C57
	je EndTurn_Next	;@0C59
	dec byte ptr TimeStopTurns	;@0C5B
EndTurn_Next:	jmp MainLoop	; next command	;@0C5F

;------------------------------------------------------------------------------
; PlayerDies: the player dies (no hit points, no food, ...; jumped to from EVENTS,
; INPUT, MOVE, DUNGEON, CMDAL). Hit points, food, experience and gold become
; 0, the status lines show it, then "<name> IS DEAD!" and the program hangs
; in an endless loop (the player must reboot).
;------------------------------------------------------------------------------
PlayerDies:	mov al, 0	;@0C62
	mov byte ptr HitPointsHi, al	;@0C64
	mov byte ptr HitPointsLo, al	;@0C67
	mov byte ptr FoodHi, al	;@0C6A
	mov byte ptr FoodLo, al	;@0C6D
	mov byte ptr FoodFrac, al	;@0C70
	mov byte ptr ExpHi, al	;@0C73
	mov byte ptr ExpLo, al	;@0C76
	mov byte ptr GoldHi, al	;@0C79
	mov byte ptr GoldLo, al	;@0C7C
	call DrawStatusLines	;@0C7F
	call PrintInline	;@0C82
	db 8Dh,8Dh,8Dh,0h	; three CRs	;@0C85
	call PrintPlayerName	; the player's name	;@0C89
	call PrintInline	;@0C8C
	db 20h,49h,53h,20h,44h,45h,41h,44h,21h,8Dh,0h	; " IS DEAD!", CR	;@0C8F
PlayerDies_Hang:	jmp PlayerDies_Hang	; hang forever	;@0C9A

;------------------------------------------------------------------------------
; SpawnMonster: outdoors, after the monsters moved: maybe spawn one. Takes the
; highest free slot (1Fh..1; none free: EndTurn), a random X (0-3Eh, else no
; spawn) and Y (0-3Fh, a negative random number: no spawn), notes the terrain
; there in MonsterUnder and picks the type from the lowest set bit of the counter
; SpawnCounter (saved with the player), so the types come in a fixed rotation:
;   bit 0: 30h (hit points 10h)   bit 1: 0FCh thief (20h)   bit 2: 34h (40h)
;   bit 3: 2Ch on water (40h)     bit 4: 0F0h (80h)         bit 5: 48h on water (A0h)
;   bit 6: 38h (C0h)              bit 7: 0F8h wizard (E0h)  none: 3Ch (FFh)
; (Map code / 2 is the figure: 0F0h/0F8h/0FCh look like a fighter/wizard/thief
; player figure 78h/7Ch/7Eh, 48h like a frigate 24h: pirates?)
; The land types need grass (terrain code 8), the water ones water (0); on the
; wrong terrain SpawnCounter is put back and nothing spawns this turn. The monster's
; map code is written into the map and into MonsterTile, its hit points into MonsterHP.
; A square holding a monster has its code, not 8 or 0, so it is refused; the
; player's own square is not checked (he is not in the map), so a monster can
; appear on top of him.
;------------------------------------------------------------------------------
SpawnMonster:	mov bh, 0	;@0C9C
	mov bl, 1Fh	;@0C9E
	mov di, bx	;@0CA0
SpawnMonster_FindSlot:	mov al, byte ptr MonsterTile[di]	;@0CA2
	or al, al	;@0CA6
	je SpawnMonster_Found	; free slot found	;@0CA8
	dec di	;@0CAA
	jne SpawnMonster_FindSlot	;@0CAB
	jmp EndTurn	;@0CAD
SpawnMonster_Found:	mov bx, di	;@0CB0
	mov byte ptr Temp1F, bl	; the new monster's slot	;@0CB2
	call Random	;@0CB6
	cmp al, 3Fh	;@0CB9
	jb SpawnMonster_X	;@0CBB
	jmp EndTurn	; most of the time: no spawn	;@0CBD
SpawnMonster_X:	mov bh, 0	;@0CC0
	mov bl, byte ptr Temp1F	;@0CC2
	mov di, bx	;@0CC6
	mov byte ptr MonsterX[di], al	; X	;@0CC8
	mov byte ptr LookX, al	;@0CCC
	call Random	;@0CCF
	js L0CD9	;@0CD2
	and al, 3Fh	;@0CD4
	jmp SpawnMonster_Y	;@0CD6
L0CD9:	jmp EndTurn	;@0CD9
SpawnMonster_Y:	mov bh, 0	;@0CDC
	mov bl, byte ptr Temp1F	;@0CDE
	mov di, bx	;@0CE2
	mov byte ptr MonsterY[di], al	; Y	;@0CE4
	mov byte ptr LookY, al	;@0CE8
	call GetMapSquare	; AL = map code at (X, Y), MapCellPtr -> the cell, SI = 0	;@0CEB
	mov bh, 0	;@0CEE
	mov bl, byte ptr Temp1F	;@0CF0
	mov di, bx	;@0CF4
	mov byte ptr MonsterUnder[di], al	; terrain under the monster	;@0CF6
	inc byte ptr SpawnCounter	;@0CFA
	mov al, byte ptr SpawnCounter	;@0CFE
;
; Find the lowest set bit of SpawnCounter (rcr into the carry, bit by bit).
;
	clc	;@0D01
	rcr al, 1	;@0D02
	jae L0D09	;@0D04
	jmp SpawnMonster_30	;@0D06
L0D09:	clc	;@0D09
	rcr al, 1	;@0D0A
	jae L0D11	;@0D0C
	jmp SpawnMonster_Thief	;@0D0E
L0D11:	clc	;@0D11
	rcr al, 1	;@0D12
	jae L0D19	;@0D14
	jmp SpawnMonster_34	;@0D16
L0D19:	clc	;@0D19
	rcr al, 1	;@0D1A
	jae L0D21	;@0D1C
	jmp SpawnMonster_2C	;@0D1E
L0D21:	clc	;@0D21
	rcr al, 1	;@0D22
	jae L0D29	;@0D24
	jmp SpawnMonster_Fighter	;@0D26
L0D29:	clc	;@0D29
	rcr al, 1	;@0D2A
	jae L0D31	;@0D2C
	jmp L0DCB	;@0D2E
L0D31:	clc	;@0D31
	rcr al, 1	;@0D32
	jae L0D39	;@0D34
	jmp L0DCE	;@0D36
L0D39:	clc	;@0D39
	rcr al, 1	;@0D3A
	jae L0D41	;@0D3C
	jmp L0DD1	;@0D3E
L0D41:	jmp SpawnMonster_3C	; SpawnCounter = 0	;@0D41
;
; One block per type: right terrain? then write the map code to the map
; (MapCellPtr = the cell, SI = 0) and to MonsterTile, the hit points to MonsterHP, done
; (EndTurn). Wrong terrain: SpawnMonster_Refused.
;
SpawnMonster_30:	mov al, byte ptr MonsterUnder[di]	;@0D44
	cmp al, 8	; grass?	;@0D48
	je L0D4F	;@0D4A
	jmp SpawnMonster_Refused	;@0D4C
L0D4F:	mov al, 30h	;@0D4F
	mov bx, word ptr MapCellPtr	;@0D51
	mov byte ptr [bx+si], al	;@0D55
	mov byte ptr MonsterTile[di], al	;@0D57
	mov al, 10h	;@0D5B
	mov byte ptr MonsterHP[di], al	;@0D5D
	jmp EndTurn	;@0D61
SpawnMonster_Thief:	mov al, byte ptr MonsterUnder[di]	;@0D64
	cmp al, 8	;@0D68
	je L0D6F	;@0D6A
	jmp SpawnMonster_Refused	;@0D6C
L0D6F:	mov al, 0FCh	; thief	;@0D6F
	mov bx, word ptr MapCellPtr	;@0D71
	mov byte ptr [bx+si], al	;@0D75
	mov byte ptr MonsterTile[di], al	;@0D77
	mov al, 20h	;@0D7B
	mov byte ptr MonsterHP[di], al	;@0D7D
	jmp EndTurn	;@0D81
SpawnMonster_34:	mov al, byte ptr MonsterUnder[di]	;@0D84
	cmp al, 8	;@0D88
	je L0D8F	;@0D8A
	jmp SpawnMonster_Refused	;@0D8C
L0D8F:	mov al, 34h	;@0D8F
	mov bx, word ptr MapCellPtr	;@0D91
	mov byte ptr [bx+si], al	;@0D95
	mov byte ptr MonsterTile[di], al	;@0D97
	mov al, 40h	;@0D9B
	mov byte ptr MonsterHP[di], al	;@0D9D
	jmp EndTurn	;@0DA1
SpawnMonster_2C:	mov al, byte ptr MonsterUnder[di]	;@0DA4
	cmp al, 0	; water?	;@0DA8
	je L0DAF	;@0DAA
	jmp SpawnMonster_Refused	;@0DAC
L0DAF:	mov al, 2Ch	;@0DAF
	mov bx, word ptr MapCellPtr	;@0DB1
	mov byte ptr [bx+si], al	;@0DB5
	mov byte ptr MonsterTile[di], al	;@0DB7
	mov al, 40h	;@0DBB
	mov byte ptr MonsterHP[di], al	;@0DBD
	jmp EndTurn	;@0DC1
SpawnMonster_Refused:	dec byte ptr SpawnCounter	; wrong terrain: try this type again next time	;@0DC4
	jmp EndTurn	;@0DC8
L0DCB:	jmp SpawnMonster_Pirate	; bit 5	;@0DCB
L0DCE:	jmp SpawnMonster_38	; bit 6	;@0DCE
L0DD1:	jmp SpawnMonster_Wizard	; bit 7	;@0DD1
SpawnMonster_Fighter:	mov al, byte ptr MonsterUnder[di]	;@0DD4
	cmp al, 8	;@0DD8
	je L0DDE	;@0DDA
	jmp SpawnMonster_Refused	;@0DDC
L0DDE:	mov al, 0F0h	; fighter figure	;@0DDE
	mov bx, word ptr MapCellPtr	;@0DE0
	mov byte ptr [bx+si], al	;@0DE4
	mov byte ptr MonsterTile[di], al	;@0DE6
	mov al, 80h	;@0DEA
	mov byte ptr MonsterHP[di], al	;@0DEC
	jmp EndTurn	;@0DF0
SpawnMonster_Pirate:	mov al, byte ptr MonsterUnder[di]	;@0DF3
	cmp al, 0	; water?	;@0DF7
	je L0DFD	;@0DF9
	jmp SpawnMonster_Refused	;@0DFB
L0DFD:	mov al, 48h	; frigate figure (pirates?)	;@0DFD
	mov bx, word ptr MapCellPtr	;@0DFF
	mov byte ptr [bx+si], al	;@0E03
	mov byte ptr MonsterTile[di], al	;@0E05
	mov al, 0A0h	;@0E09
	mov byte ptr MonsterHP[di], al	;@0E0B
	jmp EndTurn	;@0E0F
SpawnMonster_38:	mov al, byte ptr MonsterUnder[di]	;@0E12
	cmp al, 8	;@0E16
	je L0E1C	;@0E18
	jmp SpawnMonster_Refused	;@0E1A
L0E1C:	mov al, 38h	;@0E1C
	mov bx, word ptr MapCellPtr	;@0E1E
	mov byte ptr [bx+si], al	;@0E22
	mov byte ptr MonsterTile[di], al	;@0E24
	mov al, 0C0h	;@0E28
	mov byte ptr MonsterHP[di], al	;@0E2A
	jmp EndTurn	;@0E2E
SpawnMonster_Wizard:	mov al, byte ptr MonsterUnder[di]	;@0E31
	cmp al, 8	;@0E35
	je L0E3B	;@0E37
	jmp SpawnMonster_Refused	;@0E39
L0E3B:	mov al, 0F8h	; wizard (casts magic missiles)	;@0E3B
	mov bx, word ptr MapCellPtr	;@0E3D
	mov byte ptr [bx+si], al	;@0E41
	mov byte ptr MonsterTile[di], al	;@0E43
	mov al, 0E0h	;@0E47
	mov byte ptr MonsterHP[di], al	;@0E49
	jmp EndTurn	;@0E4D
SpawnMonster_3C:	mov al, byte ptr MonsterUnder[di]	;@0E50
	cmp al, 8	;@0E54
	je L0E5B	;@0E56
	jmp SpawnMonster_Refused	;@0E58
L0E5B:	mov al, 3Ch	;@0E5B
	mov bx, word ptr MapCellPtr	;@0E5D
	mov byte ptr [bx+si], al	;@0E61
	mov byte ptr MonsterTile[di], al	;@0E63
	mov al, 0FFh	;@0E67
	mov byte ptr MonsterHP[di], al	;@0E69
	jmp EndTurn	;@0E6D
CODE ENDS
END
