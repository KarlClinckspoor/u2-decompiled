; EVENTS.ASM: monster attacks and spells, darkness and torches, random events.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 0E70-154E.
;
; The monsters' half of a turn outside MAIN's surface loop, and the special attacks.
;   SpellParalyzeLegs, SpellParalyzeArms, SpellMagicMissile, SpellSleep: a surface/town monster's spell on the player
;   (MAIN 0AD3, by
;         monster tile 34h, 38h, F8h, 3Ch): legs paralyzed, arms paralyzed, magic missile, sleep.
;         Boots, cloak and green idol may save.
;   MinaxCurse Minax's curse (-100 hits) when the player is within 3 squares of her (tile 40h).
;   ThiefStealItem a thief (tile FCh) steals one of the 16 magic items.
;   TownTurnVillage/TownTurnTowne/TownTurnCastle the town turn (location types 1-3), entered by jmp from MAIN 0A4E:
;   every
;         monster acts by its behaviour byte MonsterMood (still, hostile, following, wandering).
;   AlertTownGuards make the town guards hostile after an attack or a theft.
;   DungeonTurnDungeon/DungeonTurnTower the dungeon and tower turn (types 5 and 4): new monsters, their moves and
;         attacks, the torch, the 3D view and food.
;   ReadDungeonCell read a dungeon map cell (used by CMDAL).
; Data: the monster table (MonsterX x, MonsterY y, MonsterHP hit points, MonsterTile tile/kind, MonsterUnder tile
; under it or, in dungeons, its level; MonsterMood behaviour, MonsterStepX/MonsterStepY wander step), hit points
; HitPointsHi/HitPointsLo and food FoodHi-FoodFrac (BCD), the paralysis/sleep counters LegsParalyzed-SleepTurns.
; A dungeon or tower is 16 levels of 16x16 cells, one 256-byte page each in the map buffer;
; a cell's high nibble is the feature (80h = wall), its low 3 bits the monster kind (1-7):
; 1 orc, 2 ghost, 3 carrion creeper, 4 viper, 5 gremlin, 6 minotaur, 7 balron (the shapes are
; pages 1-7 of the MONSTERS file; tools/sprites.py draws them).
; BCD arithmetic uses the 6502 idiom stc/cmc + sbb + das + cmc: CF=1 afterwards = no borrow.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN PlayerX:BYTE, PlayerY:BYTE, DungeonCellPtr:BYTE, DungeonCellPtrHi:BYTE, DeltaX:BYTE, DeltaY:BYTE
	EXTRN Temp1F:BYTE, Temp20:BYTE, Temp21:BYTE, Temp22:BYTE, LookX:BYTE, LookY:BYTE
	EXTRN DungeonLevel:BYTE, LightTurns:BYTE, MapType:BYTE, HitPointsHi:BYTE, HitPointsLo:BYTE, FoodHi:BYTE
	EXTRN FoodLo:BYTE, FoodFrac:BYTE, WornArmour:BYTE, ItemCounts:BYTE, Boots:BYTE, Cloaks:BYTE
	EXTRN GreenIdols:BYTE, MonsterX:BYTE, MonsterY:BYTE, MonsterHP:BYTE, MonsterTile:BYTE, MonsterUnder:BYTE
	EXTRN MonsterMood:BYTE, MonsterStepX:BYTE, MonsterStepY:BYTE, LegsParalyzed:BYTE, ArmsParalyzed:BYTE
	EXTRN SleepTurns:BYTE
	EXTRN MapBufPtr:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN MainLoop:NEAR, MonsterTurn:NEAR, EndTurn:NEAR, PlayerDies:NEAR, MonsterStepToward:NEAR
	EXTRN MoveMonsterToTarget:NEAR
	EXTRN InvertViewArea:NEAR, ClearViewArea:NEAR, DirToPlayer:NEAR, PrintInline:NEAR, GetMapSquare:NEAR
	EXTRN SignOf:NEAR
	EXTRN AbsOf:NEAR, DrawStatusLines:NEAR, Random:NEAR, XorAttackMark:NEAR, Beep:NEAR, PlayAttackSound:NEAR
	EXTRN PlayHurtSound:NEAR, PlaySpellSound:NEAR, UpdateDungeonView:NEAR
	PUBLIC SpellParalyzeLegs, SpellParalyzeArms, SpellMagicMissile, SpellSleep, ThiefStealItem, TownTurnVillage
	PUBLIC TownTurnTowne, TownTurnCastle, TownTurnNextMonster, AlertTownGuards, DungeonTurnDungeon, DungeonTurnTower
	PUBLIC ReadDungeonCell
ASSUME CS:CODE, DS:DATA

;------------------------------------------------------------------------------
; SpellParalyzeLegs: a monster's spell (tile 34h, from MAIN 0ADB): "LEGS PARALYZED!" with a
; screen flash. Magic boots (Boots) save 3 times in 4; otherwise the legs stay
; paralyzed for 0-15 turns (LegsParalyzed; MOVE 2520 refuses steps, MAIN 0C33 counts
; it down). Uses: AX.
;------------------------------------------------------------------------------
SpellParalyzeLegs:	call PrintInline	;@0E70
	db 4Ch,45h,47h,53h,20h,50h,41h,52h,41h,4Ch,49h,5Ah,45h,44h,21h,0Dh	; "LEGS PARALYZED!"	;@0E73
	db 0h	;@0E83
	call InvertViewArea	; invert the screen	;@0E84
	call PlaySpellSound	; spell sound	;@0E87
	call InvertViewArea	; and back	;@0E8A
	cmp byte ptr Boots, 0	; boots	;@0E8D
	je ParalyzeLegs_Hit	;@0E92
	call Random	; random 0-FFh	;@0E94
	cmp al, 40h	;@0E97
	jb ParalyzeLegs_Hit	;@0E99
	call PrintInline	;@0E9B
	db 53h,41h,56h,45h,44h,20h,42h,59h,20h,4Dh,41h,47h,49h,43h,41h,4Ch	; "SAVED BY MAGICAL BOOTS!"	;@0E9E
	db 20h,42h,4Fh,4Fh,54h,53h,21h,8Dh,0h	;@0EAE
	ret	;@0EB7
ParalyzeLegs_Hit:	nop	;@0EB8
	call Random	;@0EB9
	and al, 0Fh	;@0EBC
	mov byte ptr LegsParalyzed, al	; legs paralyzed for 0-15 turns	;@0EBE
	ret	;@0EC1

;------------------------------------------------------------------------------
; SpellParalyzeArms: a monster's spell (tile 38h): "ARMS PARALYZED!". A magic cloak
; (Cloaks) saves 3 times in 4; otherwise ArmsParalyzed = 0-15 turns. Uses: AX.
;------------------------------------------------------------------------------
SpellParalyzeArms:	call PrintInline	;@0EC2
	db 41h,52h,4Dh,53h,20h,50h,41h,52h,41h,4Ch,49h,5Ah,45h,44h,21h,0Dh	; "ARMS PARALYZED!"	;@0EC5
	db 0h	;@0ED5
	call InvertViewArea	; flash	;@0ED6
	call PlaySpellSound	;@0ED9
	call InvertViewArea	;@0EDC
	mov al, byte ptr Cloaks	; cloaks	;@0EDF
	or al, al	;@0EE2
	je ParalyzeArms_Hit	;@0EE4
	call Random	;@0EE6
	cmp al, 40h	;@0EE9
	jb ParalyzeArms_Hit	;@0EEB
	call PrintInline	;@0EED
	db 53h,41h,56h,45h,44h,20h,42h,59h,20h,4Dh,41h,47h,49h,43h,41h,4Ch	; "SAVED BY MAGICAL CLOAK"	;@0EF0
	db 20h,43h,4Ch,4Fh,41h,4Bh,8Dh,0h	;@0F00
	ret	;@0F08
ParalyzeArms_Hit:	call Random	;@0F09
	and al, 0Fh	;@0F0C
	mov byte ptr ArmsParalyzed, al	; arms paralyzed for 0-15 turns	;@0F0E
	ret	;@0F11

;------------------------------------------------------------------------------
; SpellMagicMissile: a monster's spell (tile F8h): "MAGIC MISSILE!". Adds two attacks and
; two hits to this turn's counts (Temp20/Temp21) and 40h to the damage limit
; Temp22; MAIN 0BAF turns those into hit points lost. Uses: AX.
;------------------------------------------------------------------------------
SpellMagicMissile:	call PrintInline	;@0F12
	db 4Dh,41h,47h,49h,43h,20h,4Dh,49h,53h,53h,49h,4Ch,45h,21h,0Dh,0h	; "MAGIC MISSILE!"	;@0F15
	call InvertViewArea	; flash	;@0F25
	call PlaySpellSound	;@0F28
	call InvertViewArea	;@0F2B
	inc byte ptr Temp20	; attacks this turn	;@0F2E
	inc byte ptr Temp20	;@0F32
	inc byte ptr Temp21	; hits this turn	;@0F36
	inc byte ptr Temp21	;@0F3A
	clc	;@0F3E
	mov al, byte ptr Temp22	; damage limit	;@0F3F
	adc al, 40h	;@0F42
	mov byte ptr Temp22, al	;@0F44
	ret	;@0F47

;------------------------------------------------------------------------------
; SpellSleep: a monster's spell (tile 3Ch): "SLEEP SPELL!". The green idol (GreenIdols)
; saves 3 times in 4; otherwise the player sleeps 0-15 turns (SleepTurns; MAIN 08A0
; then lets the turns pass). Uses: AX.
;------------------------------------------------------------------------------
SpellSleep:	call PrintInline	;@0F48
	db 53h,4Ch,45h,45h,50h,20h,53h,50h,45h,4Ch,4Ch,21h,0Dh,0h	; "SLEEP SPELL!"	;@0F4B
	call InvertViewArea	; flash	;@0F59
	call PlaySpellSound	;@0F5C
	call InvertViewArea	;@0F5F
	mov al, byte ptr GreenIdols	; green idols	;@0F62
	or al, al	;@0F65
	je SleepSpell_Hit	;@0F67
	call Random	;@0F69
	cmp al, 40h	;@0F6C
	jb SleepSpell_Hit	;@0F6E
	call PrintInline	;@0F70
	db 53h,41h,56h,45h,44h,20h,42h,59h,20h,49h,44h,4Fh,4Ch,21h,8Dh,0h	; "SAVED BY IDOL!"	;@0F73
	ret	;@0F83
SleepSpell_Hit:	nop	;@0F84
	call Random	;@0F85
	and al, 0Fh	;@0F88
	mov byte ptr SleepTurns, al	; asleep for 0-15 turns	;@0F8A
	ret	;@0F8D

;------------------------------------------------------------------------------
; MinaxCurse: "MINAX CRIES: DIE FOOL!": a hit mark on the player's square and -100
; hit points; dies (PlayerDies) below zero. Called by the town loop (TownTurnNextMonster) every turn
; while Minax (tile 40h) is within 3 squares. Uses: AX, DeltaX/DeltaY.
;------------------------------------------------------------------------------
MinaxCurse:	nop	;@0F8E
	call PrintInline	;@0F8F
	db 4Dh,49h,4Eh,41h,58h,20h,43h,52h,49h,45h,53h,3Ah,20h,44h,49h,45h	; "MINAX CRIES: DIE FOOL!"	;@0F92
	db 20h,46h,4Fh,4Fh,4Ch,21h,8Dh,0h	;@0FA2
	mov al, 0	;@0FAA
	mov byte ptr DeltaX, al	; direction 0,0 = the player's own square	;@0FAC
	mov byte ptr DeltaY, al	;@0FAF
	call XorAttackMark	; hit mark (XOR)	;@0FB2
	call PlayHurtSound	; sound	;@0FB5
	call XorAttackMark	; erase it	;@0FB8
	stc	;@0FBB
	mov al, byte ptr HitPointsHi	; hits, high BCD byte: -100	;@0FBC
	cmc	;@0FBF
	sbb al, 1	;@0FC0
	das	;@0FC2
	cmc	;@0FC3
	mov byte ptr HitPointsHi, al	;@0FC4
	jb MinaxCurse_Done	;@0FC7
	jmp PlayerDies	; the player is dead	;@0FC9
MinaxCurse_Done:	ret	;@0FCC

;------------------------------------------------------------------------------
; ThiefStealItem: a thief (tile FCh) is next to the player (MAIN 0B5F): one time in 4 it
; picks one of the 16 magic items (ItemCounts ring ... TriLithium tri-lithium) at random
; and, if the player has any, takes one: "A THIEF STOLE SOMETHING!".
; Uses: AX, DI.
;------------------------------------------------------------------------------
ThiefStealItem:	nop	;@0FCD
	call Random	;@0FCE
	cmp al, 40h	;@0FD1
	jb ThiefStealItem_Try	;@0FD3
	ret	;@0FD5
ThiefStealItem_Try:	nop	;@0FD6
	call Random	;@0FD7
	and ax, 0Fh	; item 0-15	;@0FDA
	mov di, ax	;@0FDD
	mov al, byte ptr ItemCounts[di]	; how many (BCD)	;@0FDF
	or al, al	;@0FE3
	je ThiefStealItem_Done	;@0FE5
	stc	;@0FE7
	mov al, byte ptr ItemCounts[di]	;@0FE8
	cmc	;@0FEC
	sbb al, 1	;@0FED
	das	;@0FEF
	cmc	;@0FF0
	mov byte ptr ItemCounts[di], al	;@0FF1
	call PrintInline	;@0FF5
	db 41h,20h,54h,48h,49h,45h,46h,20h,53h,54h,4Fh,4Ch,45h,20h,53h,4Fh	; "A THIEF STOLE SOMETHING!"	;@0FF8
	db 4Dh,45h,54h,48h,49h,4Eh,47h,21h,8Dh,0h	;@1008
ThiefStealItem_Done:	ret	;@1012

;------------------------------------------------------------------------------
; TownTurnVillage / TownTurnTowne / TownTurnCastle: the monsters' turn in a village / towne / castle
; (location types 1, 2, 3; jumped to from MAIN 0A4E-0A5C). Three entries into
; the same code. For each monster slot from 31 down to 0 (index in DungeonLevel, as
; the routines it jumps to use DI and Temp29/AmountHi) by its behaviour MonsterMood:
;   0 or 80h+: stays put;  1: hostile, MAIN's surface code MonsterTurn (attack when
;   adjacent, else approach);  2: follows the player (DirToPlayer + INPUT MonsterStepToward);
;   3+: wanders (TownTurn_Wander). Every path comes back to TownTurnNextMonster.
; At the end jmp EndTurn (MAIN: the attacks of this turn, damage, next turn).
;------------------------------------------------------------------------------
TownTurnVillage:	nop	;@1013
TownTurnTowne:	nop	;@1014
TownTurnCastle:	nop	;@1015
	mov bh, 0	;@1016
	mov bl, 1Fh	;@1018
	mov di, bx	; slot 31	;@101A
TownTurn_Loop:	nop	;@101C
	mov bx, di	;@101D
	mov byte ptr DungeonLevel, bl	; the loop index	;@101F
	mov al, byte ptr MonsterTile[di]	; tile, 0 = free slot	;@1023
	or al, al	;@1027
	je TownTurnNextMonster	;@1029
	mov al, byte ptr MonsterMood[di]	; behaviour	;@102B
	or al, al	;@102F
	je TownTurnNextMonster	; 0: still	;@1031
	js TownTurnNextMonster	; 80h+: still	;@1033
	cmp al, 3	;@1035
	jae TownTurn_Wander	; 3+: wander	;@1037
	cmp al, 2	;@1039
	je TownTurn_Follow	; 2: follow	;@103B
	jmp TownTurn_Hostile	; 1: hostile	;@103D

;------------------------------------------------------------------------------
; TownTurnNextMonster: next monster of the town loop. Re-entered from MAIN 0BA8 and INPUT
; 2192/226F when a monster has acted (DI = its slot). If this one is Minax
; (tile 40h) within 3 squares in x and y, she curses (MinaxCurse).
;------------------------------------------------------------------------------
TownTurnNextMonster:	mov al, byte ptr MonsterTile[di]	;@1040
	cmp al, 40h	; Minax	;@1044
	jne TownTurn_Advance	;@1046
	mov al, byte ptr MonsterX[di]	;@1048
	stc	;@104C
	cmc	;@104D
	sbb al, byte ptr PlayerX	;@104E
	call AbsOf	; |dx|	;@1052
	cmp al, 4	;@1055
	jae TownTurn_Advance	;@1057
	mov al, byte ptr MonsterY[di]	;@1059
	stc	;@105D
	cmc	;@105E
	sbb al, byte ptr PlayerY	;@105F
	call AbsOf	; |dy|	;@1063
	cmp al, 4	;@1066
	jae TownTurn_Advance	;@1068
	call MinaxCurse	; "DIE FOOL!"	;@106A
TownTurn_Advance:	mov bh, 0	;@106D
	mov bl, byte ptr DungeonLevel	;@106F
	mov di, bx	;@1073
	dec di	;@1075
	jns TownTurn_Loop	; down to slot 0 inclusive	;@1076
	jmp EndTurn	; MAIN: show this turn's attacks, damage	;@1078
TownTurn_Follow:	nop	; follow: step toward the player	;@107B
	call DirToPlayer	; DeltaX/DeltaY = direction to the player	;@107C
	jmp MonsterStepToward	;@107F
TownTurn_Hostile:	nop	; hostile: MAIN's surface monster code	;@1082
	jmp MonsterTurn	;@1083
; Wander: keep the stored step MonsterStepX/MonsterStepY, change it one time in 4 to a
; random -1/0/+1 each. The new square must be inside 4-3Bh both ways, must not
; share the player's column or row (this tests x and y separately), and must be
; town floor (70h) or grass (08h).
TownTurn_Wander:	nop	;@1086
	mov bh, 0	;@1087
	mov bl, byte ptr DungeonLevel	;@1089
	mov di, bx	;@108D
	mov al, byte ptr MonsterStepX[di]	; wander dx	;@108F
	mov byte ptr DeltaX, al	;@1093
	mov al, byte ptr MonsterStepY[di]	; wander dy	;@1096
	mov byte ptr DeltaY, al	;@109A
	call Random	;@109D
	cmp al, 40h	;@10A0
	jae TownTurn_WanderStep	;@10A2
	call Random	; new random direction	;@10A4
	call SignOf	; sign: -1, 0 or +1	;@10A7
	mov bh, 0	;@10AA
	mov bl, byte ptr DungeonLevel	;@10AC
	mov di, bx	;@10B0
	mov byte ptr MonsterStepX[di], al	;@10B2
	mov byte ptr DeltaX, al	;@10B6
	call Random	;@10B9
	call SignOf	;@10BC
	mov bh, 0	;@10BF
	mov bl, byte ptr DungeonLevel	;@10C1
	mov di, bx	;@10C5
	mov byte ptr MonsterStepY[di], al	;@10C7
	mov byte ptr DeltaY, al	;@10CB
TownTurn_WanderStep:	nop	;@10CE
	mov bh, 0	;@10CF
	mov bl, byte ptr DungeonLevel	;@10D1
	mov di, bx	;@10D5
	clc	;@10D7
	mov al, byte ptr MonsterX[di]	;@10D8
	adc al, byte ptr DeltaX	;@10DC
	and al, 3Fh	;@10E0
	mov byte ptr LookX, al	; new x	;@10E2
	cmp al, 4	;@10E5
	jae TownTurn_CheckXMax	;@10E7
	jmp TownTurnNextMonster	;@10E9
TownTurn_CheckXMax:	cmp al, 3Ch	;@10EC
	jb TownTurn_CheckPlayerX	;@10EE
	jmp TownTurnNextMonster	;@10F0
TownTurn_CheckPlayerX:	cmp al, byte ptr PlayerX	; the player's column	;@10F3
	jne TownTurn_NewY	;@10F7
	jmp TownTurnNextMonster	;@10F9
TownTurn_NewY:	clc	;@10FC
	mov al, byte ptr MonsterY[di]	;@10FD
	adc al, byte ptr DeltaY	;@1101
	and al, 3Fh	;@1105
	mov byte ptr LookY, al	; new y	;@1107
	cmp al, 4	;@110A
	jae TownTurn_CheckYMax	;@110C
	jmp TownTurnNextMonster	;@110E
TownTurn_CheckYMax:	cmp al, 3Ch	;@1111
	jb TownTurn_CheckPlayerY	;@1113
	jmp TownTurnNextMonster	;@1115
TownTurn_CheckPlayerY:	cmp al, byte ptr PlayerY	; the player's row	;@1118
	jne TownTurn_CheckTile	;@111C
	jmp TownTurnNextMonster	;@111E
TownTurn_CheckTile:	call GetMapSquare	; AL = map tile there	;@1121
	cmp al, 70h	; town floor	;@1124
	je TownTurn_WanderMove	;@1126
	cmp al, 8	; grass	;@1128
	je TownTurn_WanderMove	;@112A
	jmp TownTurnNextMonster	;@112C
TownTurn_WanderMove:	mov bh, 0	;@112F
	mov bl, byte ptr DungeonLevel	;@1131
	mov di, bx	;@1135
	jmp MoveMonsterToTarget	; INPUT: move it, back to TownTurnNextMonster	;@1137

;------------------------------------------------------------------------------
; AlertTownGuards: in a town (MapType <> 0), make the guards hostile: behaviour 1 for slots
; 0-7 and for the slot in Temp20 (the monster just attacked or robbed). Called
; by Attack (CMDAL 2BE9) and Steal (CMDMZ 3F91). Uses: AX, BX, DI.
;------------------------------------------------------------------------------
AlertTownGuards:	mov al, byte ptr MapType	;@113A
	or al, al	;@113D
	jne AlertTownGuards_InTown	;@113F
	ret	;@1141
AlertTownGuards_InTown:	mov bh, 0	;@1142
	mov bl, 7	;@1144
	mov di, bx	;@1146
	mov al, 1	; hostile	;@1148
AlertTownGuards_Loop:	mov byte ptr MonsterMood[di], al	;@114A
	dec di	;@114E
	jns AlertTownGuards_Loop	;@114F
	mov bh, 0	;@1151
	mov bl, byte ptr Temp20	; the victim's slot	;@1153
	mov di, bx	;@1157
	mov byte ptr MonsterMood[di], al	;@1159
	ret	;@115D

;------------------------------------------------------------------------------
; DungeonTurnDungeon / DungeonTurnTower: the monsters' turn in a dungeon / tower (location types 5 and
; 4; jumped to from MAIN 0A63/0A6A). First SpawnDungeonMonsters fills free slots with new
; monsters. Then each live monster in slots 31 down to 1 (index in Temp1F)
; steps toward the player (away if its hit points are below 0Fh): x first,
; else y; never onto a wall (80h) or another monster. Only monsters on the
; player's level DungeonLevel move. A step onto the player is an attack (DungeonMonsterAttack).
; Then the torch, the 3D view, 0.10 food and the status lines (DungeonTurn_End), and on
; to the next command (MainLoop). MonsterStepX/MonsterStepY serve as scratch for the new x/y.
;------------------------------------------------------------------------------
DungeonTurnDungeon:	nop	;@115E
DungeonTurnTower:	nop	;@115F
	call SpawnDungeonMonsters	; new monsters	;@1160
	nop	;@1163
	mov bh, 0	;@1164
	mov bl, 1Fh	;@1166
	mov di, bx	;@1168
	mov bx, di	;@116A
	mov byte ptr Temp1F, bl	; slot 31	;@116C
DungeonTurn_Loop:	mov al, byte ptr MonsterTile[di]	; kind, 0 = free slot	;@1170
	or al, al	;@1174
	jne DungeonTurn_Monster	;@1176
DungeonTurn_Next:	dec byte ptr Temp1F	; next slot	;@1178
	mov bh, 0	;@117C
	mov bl, byte ptr Temp1F	;@117E
	mov di, bx	;@1182
	or di, di	;@1184
	jne DungeonTurn_Loop	; slot 0 is not used here	;@1186
	jmp DungeonTurn_End	;@1188
DungeonTurn_Monster:	nop	;@118B
	mov bh, 0	;@118C
	mov bl, byte ptr Temp1F	;@118E
	mov di, bx	;@1192
	call DirToPlayerDungeon	; DeltaX/DeltaY = direction to the player	;@1194
	mov al, byte ptr MonsterHP[di]	; monster hit points	;@1197
	cmp al, 0Fh	;@119B
	jae DungeonTurn_TryX	;@119D
	stc	; weak: flee, negate both	;@119F
	mov al, 0	;@11A0
	cmc	;@11A2
	sbb al, byte ptr DeltaX	;@11A3
	mov byte ptr DeltaX, al	;@11A7
	stc	;@11AA
	mov al, 0	;@11AB
	cmc	;@11AD
	sbb al, byte ptr DeltaY	;@11AE
	mov byte ptr DeltaY, al	;@11B2
DungeonTurn_TryX:	nop	; try the step in x	;@11B5
	mov al, byte ptr DeltaX	;@11B6
	or al, al	;@11B9
	je DungeonTurn_TryY	;@11BB
	clc	;@11BD
	adc al, byte ptr MonsterX[di]	;@11BE
	mov byte ptr LookX, al	;@11C2
	mov al, byte ptr MonsterY[di]	;@11C5
	mov byte ptr LookY, al	;@11C9
	mov al, byte ptr LookX	;@11CC
	cmp al, byte ptr PlayerX	;@11CF
	jne DungeonTurn_CheckXCell	;@11D3
	mov al, byte ptr LookY	;@11D5
	cmp al, byte ptr PlayerY	;@11D8
	jne DungeonTurn_CheckXCell	;@11DC
	jmp DungeonMonsterAttack	; onto the player: attack	;@11DE
DungeonTurn_CheckXCell:	nop	;@11E1
	call ReadCellIfSameLevel	; AL = target cell, or FFh if not on the player's level	;@11E2
	je DungeonTurn_CheckCell	; empty	;@11E5
	cmp al, 0FFh	;@11E7
	je DungeonTurn_TryY	;@11E9
	and al, 7Fh	;@11EB
	jne DungeonTurn_CheckCell	; not a wall	;@11ED
DungeonTurn_TryY:	nop	; try the step in y	;@11EF
	mov al, byte ptr DeltaY	;@11F0
	or al, al	;@11F3
	je DungeonTurn_Blocked	;@11F5
	clc	;@11F7
	adc al, byte ptr MonsterY[di]	;@11F8
	mov byte ptr LookY, al	;@11FC
	mov al, byte ptr MonsterX[di]	;@11FF
	mov byte ptr LookX, al	;@1203
	mov al, byte ptr LookX	;@1206
	cmp al, byte ptr PlayerX	;@1209
	jne DungeonTurn_CheckYCell	;@120D
	mov al, byte ptr LookY	;@120F
	cmp al, byte ptr PlayerY	;@1212
	jne DungeonTurn_CheckYCell	;@1216
	jmp DungeonMonsterAttack	; onto the player: attack	;@1218
DungeonTurn_CheckYCell:	nop	;@121B
	call ReadCellIfSameLevel	;@121C
	je DungeonTurn_CheckCell	;@121F
	cmp al, 0FFh	;@1221
	je DungeonTurn_Blocked	;@1223
	and al, 7Fh	;@1225
	jne DungeonTurn_CheckCell	;@1227
DungeonTurn_Blocked:	jmp DungeonTurn_Next	; no step possible	;@1229
DungeonTurn_CheckCell:	nop	;@122C
	call ReadMonsterCell	; the target cell again	;@122D
	and al, 7	; a monster there?	;@1230
	je DungeonTurn_Step	;@1232
	jmp DungeonTurn_Next	;@1234
; Move: clear the monster bits of the old cell, OR the kind into the new one.
DungeonTurn_Step:	nop	;@1237
	mov al, byte ptr LookX	;@1238
	mov byte ptr MonsterStepX[di], al	; keep the new x/y	;@123B
	mov al, byte ptr LookY	;@123F
	mov byte ptr MonsterStepY[di], al	;@1242
	mov al, byte ptr MonsterX[di]	;@1246
	mov byte ptr LookX, al	;@124A
	mov al, byte ptr MonsterY[di]	;@124D
	mov byte ptr LookY, al	;@1251
	call ReadMonsterCell	; DungeonCellPtr -> the old cell	;@1254
	mov bx, word ptr DungeonCellPtr	;@1257
	mov al, byte ptr [bx+si]	;@125B
	and al, 0F0h	;@125D
	mov bx, word ptr DungeonCellPtr	;@125F
	mov byte ptr [bx+si], al	;@1263
	mov al, byte ptr MonsterStepX[di]	;@1265
	mov byte ptr LookX, al	;@1269
	mov byte ptr MonsterX[di], al	;@126C
	mov al, byte ptr MonsterStepY[di]	;@1270
	mov byte ptr LookY, al	;@1274
	mov byte ptr MonsterY[di], al	;@1277
	call ReadMonsterCell	; DungeonCellPtr -> the new cell	;@127B
	mov bx, word ptr DungeonCellPtr	;@127E
	mov al, byte ptr [bx+si]	;@1282
	or al, byte ptr MonsterTile[di]	;@1284
	mov bx, word ptr DungeonCellPtr	;@1288
	mov byte ptr [bx+si], al	;@128C
	jmp DungeonTurn_Next	;@128E
; End of the dungeon turn: the torch (LightTurns = turns of light left).
DungeonTurn_End:	nop	;@1291
	mov al, byte ptr LightTurns	;@1292
	or al, al	;@1295
	jne DungeonTurn_BurnTorch	;@1297
	call ClearViewArea	; clear the screen	;@1299
	call PrintInline	;@129C
	db 49h,54h,27h,53h,20h,44h,41h,52h,4Bh,21h,8Dh,0h	; "IT'S DARK!"	;@129F
	jmp DungeonTurn_Draw	;@12AB
DungeonTurn_BurnTorch:	dec byte ptr LightTurns	;@12AE
	jne DungeonTurn_Draw	;@12B2
	call PrintInline	;@12B4
	db 54h,4Fh,52h,43h,48h,20h,42h,55h,52h,4Eh,45h,44h,20h,4Fh,55h,54h	; "TORCH BURNED OUT!"	;@12B7
	db 21h,8Dh,0h	;@12C7
	call Beep	; beep	;@12CA
DungeonTurn_Draw:	call UpdateDungeonView	; draw the 3D view	;@12CD
	mov al, 10h	; 0.10 food per dungeon turn	;@12D0
	call EatFood	;@12D2
	call DrawStatusLines	; status lines	;@12D5
	jmp MainLoop	; MAIN: next command	;@12D8

;------------------------------------------------------------------------------
; EatFood: eat food: FoodHi/FoodLo/FoodFrac (BCD, the last byte = hundredths) -= AL
; hundredths (AL in BCD). Dies (PlayerDies) when the food goes below 0.
; In: AL. Uses: AX, Temp20.
;------------------------------------------------------------------------------
EatFood:	mov byte ptr Temp20, al	;@12DB
	stc	;@12DE
	mov al, byte ptr FoodFrac	;@12DF
	cmc	;@12E2
	sbb al, byte ptr Temp20	;@12E3
	das	;@12E7
	cmc	;@12E8
	mov byte ptr FoodFrac, al	;@12E9
	mov al, byte ptr FoodLo	;@12EC
	cmc	;@12EF
	sbb al, 0	;@12F0
	das	;@12F2
	cmc	;@12F3
	mov byte ptr FoodLo, al	;@12F4
	mov al, byte ptr FoodHi	;@12F7
	cmc	;@12FA
	sbb al, 0	;@12FB
	das	;@12FD
	cmc	;@12FE
	mov byte ptr FoodHi, al	;@12FF
	jb EatFood_Done	;@1302
	jmp PlayerDies	; starved: the player is dead	;@1304
EatFood_Done:	ret	;@1307

;------------------------------------------------------------------------------
; DungeonMonsterAttack: dungeon monster Temp1F attacks the player (its step would land on
; him). Nothing happens if it is not on the player's level. One time in 4 the
; kinds 2, 5 and 7 use their special attack instead (DgnAttack_BlowTorch torch blown out,
; DgnAttack_Gremlin gremlin steals food, DgnAttack_StrongMagic strong magic = sleep); otherwise a blow:
; it misses when the random byte is 80h or more or its low 3 bits are below the
; armour worn (WornArmour); a hit costs (random & 77h) + ((level * 4) & 77h) hit
; points, subtracted as BCD.
; Back to the monster loop (DungeonTurn_Next), or death (PlayerDies).
;------------------------------------------------------------------------------
DungeonMonsterAttack:	nop	;@1308
	call Random	;@1309
	cmp al, 40h	;@130C
	jae DgnAttack_Blow	; 3 in 4: an ordinary blow	;@130E
	mov bh, 0	;@1310
	mov bl, byte ptr Temp1F	;@1312
	mov di, bx	;@1316
	mov al, byte ptr DungeonLevel	; the player's level	;@1318
	cmp al, byte ptr MonsterUnder[di]	; the monster's level	;@131B
	je DgnAttack_Special	;@131F
	jmp DungeonTurn_Next	;@1321
DgnAttack_Special:	nop	;@1324
	mov al, byte ptr MonsterTile[di]	; monster kind 1-7	;@1325
	cmp al, 2	;@1329
	jne DgnAttack_TryGremlin	;@132B
	jmp DgnAttack_BlowTorch	;@132D
DgnAttack_TryGremlin:	cmp al, 5	;@1330
	jne DgnAttack_TryBalron	;@1332
	jmp DgnAttack_Gremlin	;@1334
DgnAttack_TryBalron:	cmp al, 7	;@1337
	jne DgnAttack_Blow	;@1339
	jmp DgnAttack_StrongMagic	;@133B
DgnAttack_Blow:	nop	;@133E
	mov bh, 0	;@133F
	mov bl, byte ptr Temp1F	;@1341
	mov di, bx	;@1345
	mov al, byte ptr DungeonLevel	;@1347
	cmp al, byte ptr MonsterUnder[di]	; on the player's level?	;@134A
	je DgnAttack_Roll	;@134E
	jmp DungeonTurn_Next	;@1350
DgnAttack_Roll:	nop	;@1353
	call PlayAttackSound	; attack sound	;@1354
	call Random	;@1357
	js DgnAttack_Miss	; half the time: miss	;@135A
	and al, 7	;@135C
	cmp al, byte ptr WornArmour	; armour worn (0-6)	;@135E
	jae DgnAttack_Hit	;@1362
DgnAttack_Miss:	jmp DungeonTurn_Next	;@1364
DgnAttack_Hit:	nop	;@1367
	call InvertViewArea	; flash	;@1368
	call PlayHurtSound	; hit sound	;@136B
	call InvertViewArea	;@136E
	call Random	;@1371
	and al, 77h	;@1374
	mov byte ptr Temp20, al	;@1376
	mov al, byte ptr DungeonLevel	; level * 4	;@1379
	add al, al	;@137C
	add al, al	;@137E
	and al, 77h	;@1380
	adc al, byte ptr Temp20	; not BCD-adjusted: the das below gets a raw sum	;@1382
	mov byte ptr Temp20, al	; the damage	;@1386
	stc	;@1389
	mov al, byte ptr HitPointsLo	; hits -= damage	;@138A
	cmc	;@138D
	sbb al, byte ptr Temp20	;@138E
	das	;@1392
	cmc	;@1393
	mov byte ptr HitPointsLo, al	;@1394
	mov al, byte ptr HitPointsHi	;@1397
	cmc	;@139A
	sbb al, 0	;@139B
	das	;@139D
	cmc	;@139E
	mov byte ptr HitPointsHi, al	;@139F
	jb DgnAttack_Survived	;@13A2
	jmp PlayerDies	; the player is dead	;@13A4
DgnAttack_Survived:	nop	;@13A7
	jmp DungeonTurn_Next	;@13A8
; Kind 2, the ghost: puts out the torch.
DgnAttack_BlowTorch:	mov al, byte ptr LightTurns	; torch turns left	;@13AB
	or al, al	;@13AE
	je DgnAttack_TorchDone	;@13B0
	call PrintInline	;@13B2
	db 59h,4Fh,55h,52h,20h,54h,4Fh,52h,43h,48h,20h,49h,53h,20h,42h,4Ch	; "YOUR TORCH IS BLOWN OUT!"	;@13B5
	db 4Fh,57h,4Eh,20h,4Fh,55h,54h,21h,8Dh,0h	;@13C5
	call Beep	; beep	;@13CF
	mov al, 0	;@13D2
	mov byte ptr LightTurns, al	;@13D4
DgnAttack_TorchDone:	jmp DungeonTurn_Next	;@13D7
; Kind 5, the gremlin: -100 food.
DgnAttack_Gremlin:	call PrintInline	;@13DA
	db 41h,20h,47h,52h,45h,4Dh,4Ch,49h,4Eh,20h,53h,54h,4Fh,4Ch,45h,20h	; "A GREMLIN STOLE SOME FOOD!"	;@13DD
	db 53h,4Fh,4Dh,45h,20h,46h,4Fh,4Fh,44h,21h,8Dh,0h	;@13ED
	call Beep	; beep	;@13F9
	stc	;@13FC
	mov al, byte ptr FoodHi	; food, high BCD byte: -100	;@13FD
	cmc	;@1400
	sbb al, 1	;@1401
	das	;@1403
	cmc	;@1404
	mov byte ptr FoodHi, al	;@1405
	jae DgnAttack_FoodGone	; below zero	;@1408
	jmp DungeonTurn_Next	;@140A
DgnAttack_FoodGone:	jmp PlayerDies	; the player is dead (a gremlin can kill you)	;@140D
; Kind 7, the balron: sleep for 0-7 turns, no save.
DgnAttack_StrongMagic:	nop	;@1410
	call PrintInline	;@1411
	db 59h,4Fh,55h,20h,46h,45h,45h,4Ch,20h,41h,20h,53h,54h,52h,4Fh,4Eh	; "YOU FEEL A STRONG MAGIC!"	;@1414
	db 47h,20h,4Dh,41h,47h,49h,43h,21h,8Dh,0h	;@1424
	call Beep	; beep	;@142E
	call Random	;@1431
	and al, 7	;@1434
	mov byte ptr SleepTurns, al	; asleep	;@1436
	jmp DungeonTurn_Next	;@1439

;------------------------------------------------------------------------------
; ReadCellIfSameLevel: read the dungeon cell LookX/LookY on the level of monster DI, but
; only if that is the player's level DungeonLevel; else AL = FFh, ZF = 0.
; ReadMonsterCell: the same without the level test. ReadDungeonCell: the same with the level in AL
; (CMDAL uses it for the player's own cells).
; Out: AL = the cell, ZF set if 0 (empty); DungeonCellPtr/DungeonCellPtrHi = its address
; (map buffer + level * 256 + y * 16 + x); SI = 0. Uses: AX, BX, SI.
; Setting only the low byte from y/x relies on the map buffer starting on a
; 256-byte boundary (DS:1800), as on the Apple II.
;------------------------------------------------------------------------------
ReadCellIfSameLevel:	nop	;@143C
	mov al, byte ptr DungeonLevel	; the player's level	;@143D
	cmp al, byte ptr MonsterUnder[di]	; the monster's level	;@1440
	je ReadCellSameLevel_Yes	;@1444
	mov al, 0FFh	;@1446
	or al, al	;@1448
	ret	;@144A
ReadCellSameLevel_Yes:	nop	;@144B
ReadMonsterCell:	nop	;@144C
	mov al, byte ptr MonsterUnder[di]	; level	;@144D
ReadDungeonCell:	nop	;@1451
	mov ah, al	;@1452
	mov al, 0	;@1454
	add ax, word ptr MapBufPtr	; map buffer + level * 256	;@1456
	mov byte ptr DungeonCellPtrHi, ah	; pointer high byte	;@145A
	mov al, byte ptr LookY	;@145E
	add al, al	;@1461
	add al, al	;@1463
	add al, al	;@1465
	add al, al	; y * 16	;@1467
	adc al, byte ptr LookX	; + x	;@1469
	mov byte ptr DungeonCellPtr, al	; pointer low byte	;@146D
	mov bh, 0	;@1470
	mov bl, 0	;@1472
	mov si, bx	;@1474
	mov bx, word ptr DungeonCellPtr	;@1476
	mov al, byte ptr [bx+si]	;@147A
	or al, al	;@147C
	ret	;@147E

;------------------------------------------------------------------------------
; SpawnDungeonMonsters: put new monsters into the free dungeon slots 31-1. Slot n belongs to
; level n/2, so each level has two slots. A new monster gets a random odd x and
; y (1-15); the cell must be empty; then a random kind k = 1-7 (8 gives none),
; allowed only if 2(k-1) <= level: deeper levels have worse monsters. Hit
; points = ((2k + level) * 8) OR 10h. Called every dungeon turn, so free slots
; refill quickly. Uses: AX, BX, SI, DI, Temp1F, LookX/LookY.
;------------------------------------------------------------------------------
SpawnDungeonMonsters:	nop	;@147F
	mov bh, 0	;@1480
	mov bl, 1Fh	;@1482
	mov di, bx	;@1484
SpawnDgnMonsters_Loop:	mov bx, di	;@1486
	mov byte ptr Temp1F, bl	;@1488
	mov al, byte ptr MonsterTile[di]	;@148C
	or al, al	;@1490
	je SpawnDgnMonsters_Try	; a free slot	;@1492
SpawnDgnMonsters_Next:	mov bh, 0	;@1494
	mov bl, byte ptr Temp1F	;@1496
	mov di, bx	;@149A
	dec di	;@149C
	jne SpawnDgnMonsters_Loop	;@149D
	ret	;@149F
SpawnDgnMonsters_Try:	nop	;@14A0
	call Random	;@14A1
	mov bh, 0	;@14A4
	mov bl, byte ptr Temp1F	;@14A6
	mov di, bx	;@14AA
	and al, 7	;@14AC
	add al, al	;@14AE
	or al, 1	; x = 1, 3, ..., 15	;@14B0
	mov byte ptr MonsterX[di], al	;@14B2
	mov byte ptr LookX, al	;@14B6
	call Random	;@14B9
	mov bh, 0	;@14BC
	mov bl, byte ptr Temp1F	;@14BE
	mov di, bx	;@14C2
	and al, 7	;@14C4
	add al, al	;@14C6
	or al, 1	; y = 1, 3, ..., 15	;@14C8
	mov byte ptr MonsterY[di], al	;@14CA
	mov byte ptr LookY, al	;@14CE
	mov ax, di	;@14D1
	clc	;@14D3
	rcr al, 1	;@14D4
	mov byte ptr MonsterUnder[di], al	; level = slot / 2	;@14D6
	call ReadMonsterCell	;@14DA
	jne SpawnDgnMonsters_Next	; cell not empty	;@14DD
	call Random	;@14DF
	mov bh, 0	;@14E2
	mov bl, byte ptr Temp1F	;@14E4
	mov di, bx	;@14E8
	and al, 7	;@14EA
	cmp al, 7	;@14EC
	je SpawnDgnMonsters_Reject	;@14EE
	add al, al	;@14F0
	cmp al, byte ptr MonsterUnder[di]	; 2(k-1) <= level?	;@14F2
	je SpawnDgnMonsters_Put	;@14F6
	jb SpawnDgnMonsters_Put	;@14F8
SpawnDgnMonsters_Reject:	jmp SpawnDgnMonsters_Next	;@14FA
SpawnDgnMonsters_Put:	nop	;@14FC
	clc	;@14FD
	rcr al, 1	;@14FE
	adc al, 1	; kind k = 1-7	;@1500
	mov byte ptr MonsterTile[di], al	;@1502
	add al, al	;@1506
	adc al, byte ptr MonsterUnder[di]	;@1508
	add al, al	;@150C
	add al, al	;@150E
	add al, al	;@1510
	or al, 10h	;@1512
	mov byte ptr MonsterHP[di], al	; hit points	;@1514
	call ReadMonsterCell	;@1518
	mov bx, word ptr DungeonCellPtr	;@151B
	mov al, byte ptr [bx+si]	;@151F
	or al, byte ptr MonsterTile[di]	; put it into the cell	;@1521
	mov bx, word ptr DungeonCellPtr	;@1525
	mov byte ptr [bx+si], al	;@1529
	jmp SpawnDgnMonsters_Next	;@152B

;------------------------------------------------------------------------------
; DirToPlayerDungeon: DeltaX/DeltaY = the sign (-1/0/+1) of the player's x/y minus those of
; monster DI: the direction toward the player in a dungeon (no wrap-around,
; unlike TEXTIO's DirToPlayer). Uses: AL.
;------------------------------------------------------------------------------
DirToPlayerDungeon:	nop	;@152E
	mov al, byte ptr PlayerX	;@152F
	stc	;@1532
	cmc	;@1533
	sbb al, byte ptr MonsterX[di]	;@1534
	call SignOf	; sign	;@1538
	mov byte ptr DeltaX, al	;@153B
	mov al, byte ptr PlayerY	;@153E
	stc	;@1541
	cmc	;@1542
	sbb al, byte ptr MonsterY[di]	;@1543
	call SignOf	;@1547
	mov byte ptr DeltaY, al	;@154A
	ret	;@154D
CODE ENDS
END
