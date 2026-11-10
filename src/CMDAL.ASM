; CMDAL.ASM: commands A-L (attack, board, cast, descend, enter, fire, get, ...).
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 2B65-3B92.
;
; The handlers of the player commands A to L, entered by `jmp bx` from the jump table at CmdJumpTbl
; (MAIN): CmdAttack Attack, CmdBoard Board, CmdCast Cast, CmdDescend Descend, CmdEnter Enter, CmdFire Fire,
; CmdGet Get, CmdHyperspace Hyperspace, CmdIgniteTorch Ignite torch, CmdJump Jump, CmdKlimb Klimb, CmdLaunch Launch.
; Each prints its name inline and leaves by `jmp EndCommand` (end of the turn) or `jmp EndCommandBeep`
; (error beep, then EndCommand). Also here: PlotOverviewDot, one dot of the overview map (called by DUNGEON),
; FindMonsterAhead (find the monster in front of the player in a dungeon), RemoveItemHere (remove the item the
; player stands on), and the shared ladder / level change code (Ladder_LevelInc, Ladder_LevelDec, Ladder_ShowLevel)
; and the
; return to the outdoor map (ExitToSurface) used by Descend, Klimb and the Cast spells.
; Data mostly used: player position PlayerX/PlayerY, the dungeon facing FacingDX/FacingDY, the map
; type MapType (0 outdoors, 1 village, 2 town, 3 castle, 4 tower, 5 dungeon), the dungeon level
; DungeonLevel, the vehicle PlayerTile and the tile underfoot TileHere, the monster table (32 entries:
; X MonsterX, Y MonsterY, HP MonsterHP, tile MonsterTile, tile under / dungeon level MonsterUnder, flags MonsterMood),
; and the player record in PlayerRecord.. (Exp ExpHi/57, Gold GoldHi/59, inventory counts, BCD).
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN PlayerX:BYTE, PlayerY:BYTE, FacingDX:BYTE, FacingDY:BYTE, MapCellPtr:BYTE, DungeonCellPtr:BYTE
	EXTRN OffMapTile:BYTE, PlayerTile:BYTE, TileHere:BYTE, DeltaX:BYTE, DeltaY:BYTE, Temp1F:BYTE
	EXTRN Temp20:BYTE, Temp21:BYTE, Temp22:BYTE, LookX:BYTE, LookY:BYTE, DungeonLevel:BYTE
	EXTRN LightTurns:BYTE, PlayerRecord:BYTE, TimeZone:BYTE, MapType:BYTE, Strength:BYTE, Agility:BYTE
	EXTRN ExpHi:BYTE, ExpLo:BYTE, GoldHi:BYTE, GoldLo:BYTE, SurfaceX:BYTE, SurfaceY:BYTE
	EXTRN ReadyWeapon:BYTE, ReadySpell:BYTE, Torches:BYTE, Keys:BYTE, Tools:BYTE, RocketParked:BYTE
	EXTRN RocketX:BYTE, RocketY:BYTE, Planet:BYTE, WeaponCounts:BYTE, ArmourCounts:BYTE, SpellCounts:BYTE
	EXTRN ItemCounts:BYTE, Wands:BYTE, Staffs:BYTE, Helms:BYTE, Ankhs:BYTE, SkullKeys:BYTE
	EXTRN BrassButtons:BYTE, BlueTassles:BYTE, TriLithium:BYTE, MonsterX:BYTE, MonsterY:BYTE, MonsterHP:BYTE
	EXTRN MonsterTile:BYTE, MonsterUnder:BYTE, MonsterMood:BYTE, ArmsParalyzed:BYTE, KeyNorth:BYTE, KeySouth:BYTE
	EXTRN KeyEast:BYTE, KeyWest:BYTE, TileCache:BYTE, TileCacheShown:BYTE, PlotX:BYTE, PlotY:BYTE
	EXTRN PlaneFlying:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN SpeedDelay:NEAR, EndCommandBeep:NEAR, EndCommand:NEAR, PlayerDies:NEAR, AlertTownGuards:NEAR
	EXTRN ReadDungeonCell:NEAR
	EXTRN LoadMapAndMonsters:NEAR, LoadTalkFile:NEAR, SaveGame:NEAR, ReadDirection:NEAR, FindMonsterInDir:NEAR
	EXTRN LeaveToSurface:NEAR
	EXTRN InvertViewArea:NEAR, PlotPixel:NEAR, ReadKey:NEAR, PrintInline:NEAR, PrintPlayerName:NEAR
	EXTRN PrintNameStr:NEAR
	EXTRN GetMapSquare:NEAR, Random:NEAR, XorAttackMark:NEAR, ReadWriteFile:NEAR, PrintBcdByte:NEAR
	EXTRN UpdateMapView:NEAR
	EXTRN PlayFailSound:NEAR, PlayAttackSound:NEAR, PlayStepSound:NEAR, PlayHitSound:NEAR, PlayWarpSound:NEAR
	EXTRN PlaySpellSound:NEAR
	EXTRN PlaySwingSound:NEAR, SpaceFlight:NEAR, MinaxDead:NEAR
	PUBLIC PlotOverviewDot, CmdAttack, CmdBoard, CmdCast, CmdDescend, CmdEnter
	PUBLIC CmdFire, CmdGet, CmdHyperspace, CmdIgniteTorch, CmdJump, CmdKlimb
	PUBLIC CmdLaunch
ASSUME CS:CODE, DS:DATA
;------------------------------------------------------------------------------
; PlotOverviewDot: plot one dot of a map cell in the overview map drawn by DrawHelmMap (DUNGEON):
; each of the 64x64 map cells is 4x2 pixels, DeltaX/DeltaY are the cell column and
; row there (not a direction). Pixel = (DeltaX*4 + DI, DeltaY*2 + SI), drawn by PlotPixel.
; In: DI = dot column 0-3, SI = dot row 0-1. Out: PlotX/PlotY = the pixel.
; Uses: AL, BX, and whatever PlotPixel uses.
;------------------------------------------------------------------------------
PlotOverviewDot:	mov bx, di	;@2B65
	mov byte ptr PlotX, bl	;@2B67
	mov bx, si	;@2B6B
	mov byte ptr PlotY, bl	;@2B6D
	mov al, byte ptr DeltaX	;@2B71
	add al, al	;@2B74
	add al, al	;@2B76
	adc al, byte ptr PlotX	; x = column*4 + DI	;@2B78
	mov byte ptr PlotX, al	;@2B7C
	mov al, byte ptr DeltaY	;@2B7F
	add al, al	;@2B82
	adc al, byte ptr PlotY	; y = row*2 + SI	;@2B84
	mov byte ptr PlotY, al	;@2B88
	call PlotPixel	; plot the pixel	;@2B8B
	ret	;@2B8E
;------------------------------------------------------------------------------
; CmdAttack: command A, Attack. In a dungeon or tower (MapType >= 4) see Attack_Dungeon. Else
; refused while paralyzed (ArmsParalyzed); asks for a direction (ReadDirection), finds the monster
; there (FindMonsterInDir) and hits if random/2 < Agility (Agility). Damage = (ready weapon
; ReadyWeapon * 8 + Strength Strength) / 4. Monster tile 40h (Minax) teleports when hit and
; ends the game when killed; other kills give gold, Exp and some special loot.
; Leaves by EndCommandBeep / EndCommand.
;------------------------------------------------------------------------------
CmdAttack:	call PrintInline	;@2B8F
	db 41h,54h,54h,41h,43h,4Bh,2Dh,2Dh,0h	;@2B92
	mov al, byte ptr MapType	;@2B9B
	cmp al, 4	; dungeon or tower?	;@2B9E
	jb Attack_Surface	;@2BA0
	jmp Attack_Dungeon	;@2BA2
Attack_Surface:	nop	;@2BA5
	mov al, byte ptr ArmsParalyzed	; paralyzed?	;@2BA6
	or al, al	;@2BA9
	je Attack_GetTarget	;@2BAB
	call PrintInline	;@2BAD
	db 50h,41h,52h,41h,4Ch,49h,5Ah,45h,44h,21h,0h	;@2BB0
	jmp EndCommandBeep	;@2BBB
Attack_GetTarget:	call ReadDirection	; read a direction into DeltaX/DeltaY	;@2BBE
	call PlaySwingSound	; swing sound	;@2BC1
	call FindMonsterInDir	; DI = monster at player+direction, 0 = none	;@2BC4
	mov bx, di	;@2BC7
	mov byte ptr Temp20, bl	;@2BC9
	mov bx, di	;@2BCD
	cmp bl, 0	;@2BCF
	jne Attack_Roll	;@2BD2
	jmp Attack_Miss	;@2BD4
Attack_Roll:	call Random	;@2BD7
	clc	;@2BDA
	rcr al, 1	; random 0-7Fh ...	;@2BDB
	cmp al, byte ptr Agility	; ... below Agility = hit	;@2BDD
	jb Attack_Hit	;@2BE1
	jmp Attack_Miss	;@2BE3
Attack_Hit:	call XorAttackMark	; draw the hit marker (XOR)	;@2BE6
	call AlertTownGuards	; not outdoors: MonsterMood = 1 for monsters 0-7 + target	;@2BE9
	call PrintInline	;@2BEC
	db 2Dh,2Dh,48h,49h,54h,21h,21h,21h,0h	;@2BEF
	call PlayHitSound	;@2BF8
; damage Temp1F = (weapon*8 + Strength) / 4 (the adc adds the carry out of weapon*4)
	mov al, byte ptr ReadyWeapon	;@2BFB
	add al, al	;@2BFE
	add al, al	;@2C00
	add al, al	;@2C02
	adc al, byte ptr Strength	;@2C04
	clc	;@2C08
	rcr al, 1	;@2C09
	clc	;@2C0B
	rcr al, 1	;@2C0C
	mov byte ptr Temp1F, al	;@2C0E
	mov bh, 0	;@2C11
	mov bl, byte ptr Temp20	;@2C13
	mov di, bx	;@2C17
; Attack_Damage: also entered from Fire (Fire_Hit). DI = monster, Temp1F = damage.
Attack_Damage:	stc	;@2C19
	mov al, byte ptr MonsterHP[di]	;@2C1A
	cmc	;@2C1E
	sbb al, byte ptr Temp1F	; HP - damage (SEC/SBC)	;@2C1F
	cmc	;@2C23
	jae Attack_Killed	; borrow: killed	;@2C24
	mov byte ptr MonsterHP[di], al	;@2C26
	call XorAttackMark	; erase the hit marker	;@2C2A
	mov al, byte ptr MonsterTile[di]	;@2C2D
	cmp al, 40h	; Minax?	;@2C31
	je Attack_MinaxFlees	;@2C33
	jmp EndCommand	;@2C35
; Minax survives the hit: flash the screen, then move her to the mirror position
; (X,Y) -> (Y,X), restoring the tile under her at the old place.
Attack_MinaxFlees:	call InvertViewArea	; invert the screen	;@2C38
	call PlayWarpSound	;@2C3B
	call InvertViewArea	; and back	;@2C3E
	mov bh, 0	;@2C41
	mov bl, byte ptr Temp20	;@2C43
	mov di, bx	;@2C47
	mov al, byte ptr MonsterX[di]	;@2C49
	mov byte ptr LookX, al	;@2C4D
	mov al, byte ptr MonsterY[di]	;@2C50
	mov byte ptr LookY, al	;@2C54
	call GetMapSquare	; MapCellPtr -> map byte at (LookX,LookY), SI = 0	;@2C57
	mov al, byte ptr MonsterUnder[di]	;@2C5A
	mov bx, word ptr MapCellPtr	;@2C5E
	mov byte ptr [bx+si], al	; put back the tile under her	;@2C62
	mov al, byte ptr LookX	;@2C64
	mov byte ptr MonsterY[di], al	; new Y = old X	;@2C67
	mov al, byte ptr LookY	;@2C6B
	mov byte ptr MonsterX[di], al	; new X = old Y	;@2C6E
	mov byte ptr LookX, al	;@2C72
	mov al, byte ptr MonsterY[di]	;@2C75
	mov byte ptr LookY, al	;@2C79
	call GetMapSquare	;@2C7C
	mov al, byte ptr MonsterTile[di]	;@2C7F
	mov bx, word ptr MapCellPtr	;@2C83
	mov byte ptr [bx+si], al	; her tile at the new place (MonsterUnder not updated)	;@2C87
	mov al, 84h	;@2C89
	mov byte ptr MonsterMood[di], al	; flags = 84h ?	;@2C8B
	call PrintInline	;@2C8F
	db 8Dh,53h,48h,45h,27h,53h,20h,47h,4Fh,4Eh,45h,21h,21h,21h,0h	;@2C92
	jmp EndCommand	;@2CA1
; Monster killed (outdoors / in a town): put back the tile under it, then special loot
; by its tile: 40h Minax, 60h guard, FCh thief, F0h fighter, F8h wizard.
Attack_Killed:	mov al, byte ptr MonsterX[di]	;@2CA4
	mov byte ptr LookX, al	;@2CA8
	mov al, byte ptr MonsterY[di]	;@2CAB
	mov byte ptr LookY, al	;@2CAF
	call GetMapSquare	;@2CB2
	mov bh, 0	;@2CB5
	mov bl, 0	;@2CB7
	mov si, bx	;@2CB9
	mov al, byte ptr MonsterUnder[di]	;@2CBB
	mov bx, word ptr MapCellPtr	;@2CBF
	mov byte ptr [bx+si], al	; restore the tile under the monster	;@2CC3
	mov al, byte ptr MonsterTile[di]	;@2CC5
	cmp al, 40h	;@2CC9
	jne Attack_TryGuard	;@2CCB
	call MinaxDead	; Minax is dead: the end game	;@2CCD
	jmp EndCommand	;@2CD0
Attack_TryGuard:	nop	;@2CD3
	cmp al, 60h	;@2CD4
	jne Attack_TryThief	;@2CD6
	clc	;@2CD8
	mov al, byte ptr Keys	;@2CD9
	adc al, 2	;@2CDC
	daa	; a guard (tile 60h): Keys + 2 (BCD)	;@2CDE
	mov byte ptr Keys, al	;@2CDF
	jmp Attack_ClearMonster	;@2CE2
Attack_TryThief:	cmp al, 0FCh	;@2CE5
	jne Attack_TryFighter	;@2CE7
	mov bx, di	;@2CE9
	mov byte ptr Temp1F, bl	;@2CEB
	call Random	;@2CEF
	cmp al, 40h	;@2CF2
	jae Attack_ThiefItem	;@2CF4
	clc	;@2CF6
	mov al, byte ptr Tools	;@2CF7
	adc al, 1	;@2CFA
	daa	; tile FCh: 1 in 4, Tools + 1	;@2CFC
	mov byte ptr Tools, al	;@2CFD
Attack_ThiefItem:	call Random	;@2D00
	and al, 0Fh	;@2D03
	je Attack_ThiefDone	;@2D05
	mov ah, 0	;@2D07
	mov di, ax	;@2D09
	clc	;@2D0B
	mov al, byte ptr ItemCounts[di]	;@2D0C
	adc al, 1	;@2D10
	daa	; and a random item 1-15 (15/16)	;@2D12
	mov byte ptr ItemCounts[di], al	;@2D13
Attack_ThiefDone:	mov bh, 0	;@2D17
	mov bl, byte ptr Temp1F	;@2D19
	mov di, bx	;@2D1D
	jmp Attack_ClearMonster	;@2D1F
Attack_TryFighter:	cmp al, 0F0h	;@2D22
	jne Attack_TryWizard	;@2D24
	mov bx, di	;@2D26
	mov byte ptr Temp1F, bl	;@2D28
	call Random	;@2D2C
	cmp al, 40h	;@2D2F
	jae Attack_FighterTorches	;@2D31
	clc	;@2D33
	mov al, byte ptr Helms	;@2D34
	adc al, 1	;@2D37
	daa	; tile F0h: 1 in 4, a helm	;@2D39
	mov byte ptr Helms, al	;@2D3A
Attack_FighterTorches:	mov bh, 0	;@2D3D
	mov bl, byte ptr Temp1F	;@2D3F
	mov di, bx	;@2D43
	call Random	;@2D45
	and al, 3	;@2D48
	adc al, 1	;@2D4A
	clc	;@2D4C
	adc al, byte ptr Torches	;@2D4D
	daa	; and 1-4 torches	;@2D51
	mov byte ptr Torches, al	;@2D52
	mov bh, 0	;@2D55
	mov bl, byte ptr Temp1F	;@2D57
	mov di, bx	;@2D5B
	jmp Attack_ClearMonster	;@2D5D
Attack_TryWizard:	cmp al, 0F8h	;@2D60
	jne Attack_NoLoot	;@2D62
	mov bx, di	;@2D64
	mov byte ptr Temp1F, bl	;@2D66
	call Random	;@2D6A
	and al, 1	;@2D6D
	mov ah, 0	;@2D6F
	mov di, ax	;@2D71
	inc di	;@2D73
	clc	;@2D74
	mov al, byte ptr ItemCounts[di]	;@2D75
	adc al, 1	;@2D79
	daa	; tile F8h: a wand or a staff (item 1 or 2)	;@2D7B
	mov byte ptr ItemCounts[di], al	;@2D7C
	mov bh, 0	;@2D80
	mov bl, byte ptr Temp1F	;@2D82
	mov di, bx	;@2D86
	jmp Attack_ClearMonster	;@2D88
Attack_NoLoot:	nop	;@2D8B
; clear the monster's record, then Gold + 1-17 (BCD, odd) and Exp + 1-4
Attack_ClearMonster:	mov al, 0	;@2D8C
	mov byte ptr MonsterUnder[di], al	;@2D8E
	mov byte ptr MonsterHP[di], al	;@2D92
	mov byte ptr MonsterX[di], al	;@2D96
	mov byte ptr MonsterY[di], al	;@2D9A
	mov byte ptr MonsterTile[di], al	;@2D9E
	call PrintInline	;@2DA2
	db 0Dh,4Bh,49h,4Ch,4Ch,45h,44h,2Dh,2Dh,47h,4Fh,4Ch,44h,2Bh,0h	;@2DA5
	call Random	;@2DB4
	and al, 17h	;@2DB7
	or al, 1	;@2DB9
	mov byte ptr Temp1F, al	;@2DBB
	call PrintBcdByte	; print it as 2 BCD digits	;@2DBE
	clc	;@2DC1
	mov al, byte ptr GoldLo	;@2DC2
	adc al, byte ptr Temp1F	;@2DC5
	daa	;@2DC9
	mov byte ptr GoldLo, al	;@2DCA
	mov al, byte ptr GoldHi	;@2DCD
	adc al, 0	;@2DD0
	daa	;@2DD2
	mov byte ptr GoldHi, al	;@2DD3
	call PrintInline	;@2DD6
	db 2Dh,2Dh,45h,58h,50h,2Eh,2Bh,0h	;@2DD9
	call Random	;@2DE1
	and al, 3	;@2DE4
	adc al, 1	;@2DE6
	mov byte ptr Temp1F, al	;@2DE8
	call PrintBcdByte	;@2DEB
	clc	;@2DEE
	mov al, byte ptr ExpLo	;@2DEF
	adc al, byte ptr Temp1F	;@2DF2
	daa	;@2DF6
	mov byte ptr ExpLo, al	;@2DF7
	mov al, byte ptr ExpHi	;@2DFA
	adc al, 0	;@2DFD
	daa	;@2DFF
	mov byte ptr ExpHi, al	;@2E00
	call XorAttackMark	; erase the hit marker	;@2E03
	jmp EndCommand	;@2E06
; Attack_Miss: also used by Fire (L35F3).
Attack_Miss:	call PrintInline	;@2E09
	db 2Dh,2Dh,4Dh,49h,53h,53h,0h	;@2E0C
	jmp EndCommand	;@2E13
;------------------------------------------------------------------------------
; Attack_Dungeon: Attack in a dungeon or tower: the square in front of the player (position +
; facing FacingDX/FacingDY) on level DungeonLevel. The low 3 bits of the dungeon cell say a
; monster is there; it is looked up in the monster table (X, Y and level in MonsterUnder).
; Hit roll and damage as outdoors. AttackD_Killed (killed) is also used by the Cast spells.
;------------------------------------------------------------------------------
Attack_Dungeon:	nop	;@2E16
	call PlaySwingSound	;@2E17
	mov al, byte ptr PlayerX	;@2E1A
	clc	;@2E1D
	adc al, byte ptr FacingDX	;@2E1E
	mov byte ptr LookX, al	;@2E22
	mov al, byte ptr PlayerY	;@2E25
	clc	;@2E28
	adc al, byte ptr FacingDY	;@2E29
	mov byte ptr LookY, al	;@2E2D
	mov al, byte ptr DungeonLevel	;@2E30
	call ReadDungeonCell	; AL = dungeon cell at (LookX,LookY), level AL	;@2E33
	and al, 7	; monster bits	;@2E36
	jne AttackD_FindMonster	;@2E38
	jmp AttackD_Miss	;@2E3A
AttackD_FindMonster:	mov bh, 0	;@2E3D
	mov bl, 1Fh	;@2E3F
	mov di, bx	;@2E41
	mov bx, di	;@2E43
	mov byte ptr Temp1F, bl	; search monsters 1Fh down	;@2E45
AttackD_Search:	mov al, byte ptr MonsterX[di]	;@2E49
	cmp al, byte ptr LookX	;@2E4D
	jne AttackD_Next	;@2E51
	mov al, byte ptr MonsterY[di]	;@2E53
	cmp al, byte ptr LookY	;@2E57
	jne AttackD_Next	;@2E5B
	mov al, byte ptr MonsterUnder[di]	;@2E5D
	cmp al, byte ptr DungeonLevel	;@2E61
	jne AttackD_Next	;@2E65
	jmp AttackD_Found	;@2E67
; Probably a porting bug: the loop tests AL (the field that did not match), not the
; index, so it stops at the first mismatching zero byte and could run below index 0.
; (6502: DEC/LDX/BNE, where LDX sets the flags.) It also does not check MonsterTile.
AttackD_Next:	dec byte ptr Temp1F	;@2E6A
	mov bh, 0	;@2E6E
	mov bl, byte ptr Temp1F	;@2E70
	mov di, bx	;@2E74
	or al, al	;@2E76
	jne AttackD_Search	;@2E78
	jmp AttackD_Miss	;@2E7A
AttackD_Found:	nop	;@2E7D
	call Random	;@2E7E
	clc	;@2E81
	rcr al, 1	;@2E82
	cmp al, byte ptr Agility	; hit if random/2 < Agility	;@2E84
	jb AttackD_Hit	;@2E88
	jmp AttackD_Miss	;@2E8A
AttackD_Hit:	nop	;@2E8D
	call PrintInline	;@2E8E
	db 48h,49h,54h,21h,0h	;@2E91
	call XorAttackMark	;@2E96
	call PlayHitSound	;@2E99
	call XorAttackMark	;@2E9C
; damage Temp20 = (weapon*8 + Strength) / 4, as outdoors
	mov al, byte ptr ReadyWeapon	;@2E9F
	add al, al	;@2EA2
	add al, al	;@2EA4
	add al, al	;@2EA6
	adc al, byte ptr Strength	;@2EA8
	clc	;@2EAC
	rcr al, 1	;@2EAD
	clc	;@2EAF
	rcr al, 1	;@2EB0
	mov bh, 0	;@2EB2
	mov bl, byte ptr Temp1F	;@2EB4
	mov di, bx	;@2EB8
	mov byte ptr Temp20, al	;@2EBA
	mov al, byte ptr MonsterHP[di]	;@2EBD
	stc	;@2EC1
	cmc	;@2EC2
	sbb al, byte ptr Temp20	; HP - damage (SEC/SBC)	;@2EC3
	cmc	;@2EC7
	jae AttackD_Killed	;@2EC8
	mov byte ptr MonsterHP[di], al	;@2ECA
	jmp EndCommand	;@2ECE
; AttackD_Killed: dungeon monster DI killed (also from Cast: Prayer, Magic missile, Kill).
; Clears HP, tile and level (not X/Y), the monster bits of its cell, then gives
; Gold + 1-17 (BCD, odd) and Exp + 0-7.
AttackD_Killed:	nop	;@2ED1
	mov al, 0	;@2ED2
	mov byte ptr MonsterHP[di], al	;@2ED4
	mov byte ptr MonsterTile[di], al	;@2ED8
	mov byte ptr MonsterUnder[di], al	;@2EDC
	mov al, byte ptr MonsterX[di]	;@2EE0
	mov byte ptr LookX, al	;@2EE4
	mov al, byte ptr MonsterY[di]	;@2EE7
	mov byte ptr LookY, al	;@2EEB
	mov al, byte ptr DungeonLevel	;@2EEE
	call ReadDungeonCell	; DungeonCellPtr -> its cell, SI = 0	;@2EF1
	mov bx, word ptr DungeonCellPtr	;@2EF4
	mov al, byte ptr [bx+si]	;@2EF8
	and al, 0F0h	; clear the monster bits	;@2EFA
	mov bx, word ptr DungeonCellPtr	;@2EFC
	mov byte ptr [bx+si], al	;@2F00
	call PrintInline	;@2F02
	db 8Dh,4Bh,49h,4Ch,4Ch,45h,44h,2Dh,2Dh,47h,4Fh,4Ch,44h,2Bh,0h	;@2F05
	call Random	;@2F14
	and al, 17h	;@2F17
	or al, 1	;@2F19
	mov byte ptr Temp20, al	;@2F1B
	call PrintBcdByte	; print it as 2 BCD digits	;@2F1E
	clc	;@2F21
	mov al, byte ptr GoldLo	;@2F22
	adc al, byte ptr Temp20	;@2F25
	daa	;@2F29
	mov byte ptr GoldLo, al	;@2F2A
	mov al, byte ptr GoldHi	;@2F2D
	adc al, 0	;@2F30
	daa	;@2F32
	mov byte ptr GoldHi, al	;@2F33
	call PrintInline	;@2F36
	db 2Dh,2Dh,45h,58h,50h,2Eh,2Bh,0h	;@2F39
	call Random	;@2F41
	and al, 7	;@2F44
	mov byte ptr Temp20, al	;@2F46
	call PrintBcdByte	;@2F49
	clc	;@2F4C
	mov al, byte ptr ExpLo	;@2F4D
	adc al, byte ptr Temp20	;@2F50
	daa	;@2F54
	mov byte ptr ExpLo, al	;@2F55
	mov al, byte ptr ExpHi	;@2F58
	adc al, 0	;@2F5B
	daa	;@2F5D
	mov byte ptr ExpHi, al	;@2F5E
	jmp EndCommand	;@2F61
AttackD_Miss:	call PrintInline	;@2F64
	db 4Dh,49h,53h,53h,0h	;@2F67
	jmp EndCommand	;@2F6C
;------------------------------------------------------------------------------
; CmdBoard: command B, Board. Not in a dungeon or tower, and only on foot (player
; tile PlayerTile >= 78h), else "THINK AGAIN <name>". The tile underfoot TileHere says
; what: 22h horse, 24h frigate (needs a blue tassle, BlueTassles), 26h plane (needs a
; skull key, SkullKeys), 28h rocket (needs an ankh, Ankhs). The vehicle is taken off
; the map (map byte 8 = grass, or 0 = water for the frigate) and becomes the player
; tile PlayerTile. Leaves by EndCommandBeep / EndCommand.
;------------------------------------------------------------------------------
CmdBoard:	call PrintInline	;@2F6F
	db 42h,4Fh,41h,52h,44h,0h	;@2F72
	mov al, byte ptr MapType	;@2F78
	cmp al, 4	;@2F7B
	jb Board_Check	;@2F7D
Board_ThinkAgain:	call PrintInline	;@2F7F
	db 8Dh,54h,48h,49h,4Eh,4Bh,20h,41h,47h,41h,49h,4Eh,20h,0h	;@2F82
	call PrintPlayerName	; print the player's name	;@2F90
	jmp EndCommandBeep	;@2F93
Board_Check:	nop	;@2F96
	mov al, byte ptr PlayerTile	;@2F97
	cmp al, 78h	; 78h and up = on foot	;@2F9A
	jb Board_ThinkAgain	;@2F9C
	mov al, byte ptr PlayerX	;@2F9E
	mov byte ptr LookX, al	;@2FA1
	mov al, byte ptr PlayerY	;@2FA4
	mov byte ptr LookY, al	;@2FA7
	call GetMapSquare	; MapCellPtr -> map byte under the player	;@2FAA
	mov al, byte ptr TileHere	;@2FAD
	cmp al, 22h	; horse	;@2FB0
	je Board_Horse	;@2FB2
	cmp al, 24h	; frigate	;@2FB4
	je Board_ToFrigate	;@2FB6
	cmp al, 26h	; plane	;@2FB8
	je Board_ToPlane	;@2FBA
	cmp al, 28h	; rocket	;@2FBC
	je Board_ToRocket	;@2FBE
	call PrintInline	;@2FC0
	db 20h,57h,48h,41h,54h,3Fh,0h	;@2FC3
	jmp EndCommandBeep	;@2FCA
Board_ToFrigate:	jmp Board_Frigate	;@2FCD
Board_ToPlane:	jmp Board_Plane	;@2FD0
Board_ToRocket:	jmp Board_Rocket	;@2FD3
Board_Horse:	call PrintInline	;@2FD6
	db 20h,48h,4Fh,52h,53h,45h,0h	;@2FD9
	mov al, 8	;@2FE0
	mov bh, 0	;@2FE2
	mov bl, 0	;@2FE4
	mov di, bx	;@2FE6
	mov bx, word ptr MapCellPtr[di]	;@2FE8
	mov byte ptr [bx], al	; grass where the horse stood	;@2FEC
	mov al, 22h	;@2FEE
	mov byte ptr PlayerTile, al	;@2FF0
	jmp EndCommand	;@2FF3
Board_Frigate:	nop	;@2FF6
	mov al, byte ptr BlueTassles	; blue tassles	;@2FF7
	or al, al	;@2FFA
	jne Board_FrigateOk	;@2FFC
	call PrintInline	;@2FFE
	db 20h,53h,48h,49h,50h,8Dh,54h,48h,45h,20h,43h,52h,45h,57h,20h,4Fh	;@3001
	db 46h,20h,54h,48h,49h,53h,20h,53h,48h,49h,50h,8Dh,57h,49h,4Ch,4Ch	;@3011
	db 20h,4Eh,4Fh,54h,20h,4Ch,45h,54h,20h,59h,4Fh,55h,20h,42h,4Fh,41h	;@3021
	db 52h,44h,21h,0h	;@3031
	jmp EndCommandBeep	;@3035
Board_FrigateOk:	nop	;@3038
	call PrintInline	;@3039
	db 20h,46h,52h,49h,47h,41h,54h,45h,0h	;@303C
	mov al, 0	;@3045
	mov ah, 0	;@3047
	mov si, ax	;@3049
	mov bx, word ptr MapCellPtr	;@304B
	mov byte ptr [bx+si], al	; water where the frigate was	;@304F
	mov al, 24h	;@3051
	mov byte ptr PlayerTile, al	;@3053
	jmp EndCommand	;@3056
Board_Plane:	nop	;@3059
	mov al, byte ptr SkullKeys	; skull keys	;@305A
	or al, al	;@305D
	jne Board_PlaneOk	;@305F
	call PrintInline	;@3061
	db 20h,50h,4Ch,41h,4Eh,45h,8Dh,53h,54h,52h,41h,4Eh,47h,45h,20h,59h	;@3064
	db 4Fh,55h,20h,43h,41h,4Eh,27h,54h,20h,47h,45h,54h,20h,49h,4Eh,21h	;@3074
	db 0h	;@3084
	jmp EndCommandBeep	;@3085
Board_PlaneOk:	nop	;@3088
	call PrintInline	;@3089
	db 20h,50h,4Ch,41h,4Eh,45h,0h	;@308C
	mov al, 8	;@3093
	mov bh, 0	;@3095
	mov bl, 0	;@3097
	mov si, bx	;@3099
	mov bx, word ptr MapCellPtr	;@309B
	mov byte ptr [bx+si], al	;@309F
	mov al, 26h	;@30A1
	mov byte ptr PlayerTile, al	;@30A3
	jmp EndCommand	;@30A6
Board_Rocket:	nop	;@30A9
	call PrintInline	;@30AA
	db 20h,52h,4Fh,43h,4Bh,45h,54h,0h	;@30AD
	mov al, byte ptr Ankhs	; ankhs	;@30B5
	or al, al	;@30B8
	jne Board_RocketOk	;@30BA
	call PrintInline	;@30BC
	db 8Dh,41h,20h,4Dh,45h,54h,41h,4Ch,49h,43h,20h,56h,4Fh,49h,43h,45h	;@30BF
	db 20h,43h,4Fh,4Dh,4Dh,41h,4Eh,44h,53h,3Ah,8Dh,59h,4Fh,55h,20h,4Dh	;@30CF
	db 55h,53h,54h,20h,48h,41h,56h,45h,20h,41h,4Eh,20h,41h,4Eh,4Bh,48h	;@30DF
	db 21h,0h	;@30EF
	jmp EndCommandBeep	;@30F1
Board_RocketOk:	nop	;@30F4
	mov al, 8	;@30F5
	mov bh, 0	;@30F7
	mov bl, 0	;@30F9
	mov si, bx	;@30FB
	mov bx, word ptr MapCellPtr	;@30FD
	mov byte ptr [bx+si], al	;@3101
	mov al, 28h	;@3103
	mov byte ptr PlayerTile, al	;@3105
	jmp EndCommand	;@3108
;------------------------------------------------------------------------------
; CmdCast: command C, Cast the ready spell ReadySpell (0 none, 1 Light, 2 Down ladder,
; 3 Up ladder, 4 Passwall, 5 Surface, 6 Prayer, 7 Magic missile, 8 Blink, 9 Kill;
; names: string ReadySpell+24h of the NameStrTbl table). Needs a wand or a staff (Wands +
; Staffs) and a count of that spell (SpellCounts[spell], used up even when the spell
; then fails). Spells only work in a dungeon or tower (MapType >= 4).
; Leaves by EndCommand (failures play the PlayFailSound sound instead of the EndCommandBeep beep).
;------------------------------------------------------------------------------
CmdCast:	call PrintInline	;@310B
	db 43h,41h,53h,54h,2Dh,0h	;@310E
	jmp Cast_Start	;@3114
; Dead code (3117-3152, nothing reaches it): a developer screen dump, once part of Cast.
; Disassembled: mov ax,B800h / call 3139 / mov ax,BA00h / call 3139 / mov ah,28h /
; mov cx,4000h / mov dx,0 / call ReadWriteFile "PICXXX  " / jmp EndCommand. ReadWriteFile puts the DTA in
; the CGA screen for names starting "PI", so this writes the 16 KB screen to PICXXX.
; 3139: clear offsets 1900h-1F3Fh (the text lines at the bottom) of the bank in AX.
	db 0B8h,0h,0B8h,0E8h,1Ch,0h,0B8h,0h,0BAh,0E8h,16h,0h,0B4h,28h,0B9h,0h	;@3117
	db 40h,0BAh,0h,0h,0E8h,9Ch,21h,50h,49h,43h,58h,58h,58h,20h,20h,0E9h	;@3127
	db 0FAh,0D8h,90h,53h,6h,8Eh,0C0h,0B8h,0h,0h,0BBh,0h,19h,26h,89h,7h	;@3137
	db 83h,0C3h,2h,81h,0FBh,40h,1Fh,75h,0F4h,7h,5Bh,0C3h	;@3147
Cast_Start:	nop	;@3153
	mov al, byte ptr ReadySpell	;@3154
	clc	;@3157
	adc al, 24h	;@3158
	call PrintNameStr	; print the spell's name	;@315A
	mov al, byte ptr Wands	; wands ...	;@315D
	clc	;@3160
	adc al, byte ptr Staffs	; ... + staffs	;@3161
	jne Cast_HaveWand	;@3165
	call PrintInline	;@3167
	db 8Dh,4Eh,45h,45h,44h,20h,57h,41h,4Eh,44h,20h,4Fh,52h,20h,53h,54h	;@316A
	db 41h,46h,46h,21h,0h	;@317A
	call PlayFailSound	;@317F
	jmp EndCommand	;@3182
Cast_HaveWand:	nop	;@3185
	mov al, byte ptr ReadySpell	;@3186
	or al, al	;@3189
	jne Cast_CheckCount	;@318B
	jmp EndCommand	;@318D
Cast_CheckCount:	mov ah, 0	;@3190
	mov di, ax	;@3192
	mov al, byte ptr SpellCounts[di]	; how many of this spell	;@3194
	or al, al	;@3198
	jne Cast_UseSpell	;@319A
	call PrintInline	;@319C
	db 8Dh,4Eh,4Fh,20h,53h,50h,45h,4Ch,4Ch,21h,0h	;@319F
	call PlayFailSound	;@31AA
	jmp EndCommand	;@31AD
Cast_UseSpell:	call PlaySpellSound	; casting sound	;@31B0
	mov bh, 0	;@31B3
	mov bl, byte ptr ReadySpell	;@31B5
	mov di, bx	;@31B9
	stc	;@31BB
	mov al, byte ptr SpellCounts[di]	;@31BC
	cmc	;@31C0
	sbb al, 1	;@31C1
	das	; count - 1 (BCD)	;@31C3
	cmc	;@31C4
	mov byte ptr SpellCounts[di], al	;@31C5
	mov al, byte ptr MapType	;@31C9
	cmp al, 4	;@31CC
	jae Cast_InDungeon	;@31CE
	call PrintInline	;@31D0
	db 2Dh,46h,41h,49h,4Ch,45h,44h,21h,0h	;@31D3
	call PlayFailSound	;@31DC
	jmp EndCommand	;@31DF
Cast_InDungeon:	nop	;@31E2
	mov al, byte ptr ReadySpell	;@31E3
	or al, al	;@31E6
	jne Cast_Dispatch	;@31E8
	jmp EndCommand	;@31EA
Cast_Dispatch:	cmp al, 1	;@31ED
	je Cast_Light	;@31EF
	cmp al, 2	;@31F1
	je Cast_DownLadder	;@31F3
	cmp al, 3	;@31F5
	je Cast_UpLadder	;@31F7
	cmp al, 4	;@31F9
	je Cast_Passwall	;@31FB
	cmp al, 5	;@31FD
	je Cast_ToSurface	;@31FF
	cmp al, 6	;@3201
	je Cast_ToPrayer	;@3203
	cmp al, 7	;@3205
	je Cast_ToMagicMissile	;@3207
	cmp al, 8	;@3209
	jne Cast_ToKill	;@320B
	jmp Cast_Blink	;@320D
Cast_ToSurface:	jmp Cast_Surface	;@3210
Cast_ToPrayer:	jmp Cast_Prayer	;@3213
Cast_ToMagicMissile:	jmp Cast_MagicMissile	;@3216
Cast_ToKill:	jmp Cast_Kill	; 9 and up: Kill	;@3219
; Light: the light counter LightTurns = 96h, as a torch does.
Cast_Light:	mov al, 96h	;@321C
	mov byte ptr LightTurns, al	;@321E
	jmp EndCommand	;@3221
; Down ladder: in a tower one level down (Cast_LevelMinus), in a dungeon one level deeper.
Cast_DownLadder:	mov al, byte ptr MapType	;@3224
	cmp al, 4	;@3227
	je Cast_LevelMinus	;@3229
; Cast_LevelPlus: to level DungeonLevel+1 (at most 0Fh), if the cell at (LookX,LookY) there is
; empty. BUG: LookX/LookY are not set here but left over from the 3D view (UpdateDungeonView):
; the square behind the player. Checked in play: the result depends on the facing, and Up
; Ladder can put the player inside a wall.
Cast_LevelPlus:	mov al, byte ptr DungeonLevel	;@322B
	cmp al, 0Fh	;@322E
	jb Cast_LevelPlusTry	;@3230
Cast_Failed:	call PrintInline	; the spells' common "-FAILED!" exit	;@3232
	db 2Dh,46h,41h,49h,4Ch,45h,44h,21h,0h	;@3235
	call PlayFailSound	;@323E
	jmp EndCommand	;@3241
Cast_LevelPlusTry:	clc	;@3244
	adc al, 1	;@3245
	call ReadDungeonCell	; cell on the level below, Z = empty	;@3247
	jne Cast_Failed	;@324A
	inc byte ptr DungeonLevel	;@324C
	jmp Ladder_ShowLevel	;@3250
; Up ladder: in a tower one level up (Cast_LevelPlus), in a dungeon one level up (Cast_LevelMinus).
Cast_UpLadder:	mov al, byte ptr MapType	;@3253
	cmp al, 4	;@3256
	je Cast_LevelPlus	;@3258
; Cast_LevelMinus: to level DungeonLevel-1 (same leftover LookX/LookY); from level 0 to the surface.
Cast_LevelMinus:	mov al, byte ptr DungeonLevel	;@325A
	or al, al	;@325D
	je Cast_Surface	;@325F
	stc	;@3261
	cmc	;@3262
	sbb al, 1	; SEC/SBC: level - 1	;@3263
	cmc	;@3265
	call ReadDungeonCell	;@3266
	jne Cast_Failed	;@3269
	dec byte ptr DungeonLevel	;@326B
	jmp Ladder_ShowLevel	;@326F
; Passwall: the cell in front (X and Y must be 1-15) must be a wall (bit 7?); it
; becomes 0 (empty).
Cast_Passwall:	clc	;@3272
	mov al, byte ptr PlayerX	;@3273
	adc al, byte ptr FacingDX	;@3276
	and al, 0Fh	;@327A
	je Cast_Failed	;@327C
	mov byte ptr LookX, al	;@327E
	mov al, byte ptr PlayerY	;@3281
	adc al, byte ptr FacingDY	;@3284
	and al, 0Fh	;@3288
	je Cast_Failed	;@328A
	mov byte ptr LookY, al	;@328C
	mov al, byte ptr DungeonLevel	;@328F
	call ReadDungeonCell	;@3292
	jns Cast_Failed	;@3295
	mov al, 0	;@3297
	mov bx, word ptr DungeonCellPtr	;@3299
	mov byte ptr [bx+si], al	;@329D
	jmp EndCommand	;@329F
; Surface: back to the outdoor map.
Cast_Surface:	jmp ExitToSurface	;@32A2
; Prayer: a 50% chance of Kill.
Cast_Prayer:	call Random	;@32A5
	js Cast_Failed	;@32A8
	jmp Cast_Kill	;@32AA
; Magic missile: the monster in front loses Exp-high*2 + 1Eh HP. The SEC of the
; subtract is missing: the carry is left from the adc, so usually 1 more is taken.
Cast_MagicMissile:	call FindMonsterAhead	; DI = monster in front, Z = none	;@32AD
	je Cast_Failed	;@32B0
	mov al, byte ptr ExpHi	;@32B2
	add al, al	;@32B5
	adc al, 1Eh	;@32B7
	mov byte ptr Temp20, al	;@32B9
	mov al, byte ptr MonsterHP[di]	;@32BC
	cmc	;@32C0
	sbb al, byte ptr Temp20	;@32C1
	cmc	;@32C5
	mov byte ptr MonsterHP[di], al	;@32C6
	jb Cast_MissileDone	; no borrow: it lives	;@32CA
	jmp AttackD_Killed	;@32CC
Cast_MissileDone:	jmp EndCommand	;@32CF
; Blink: a random square (odd X and Y, 1-15) on this level; go there if it is empty.
Cast_Blink:	call Random	;@32D2
	and al, 0Fh	;@32D5
	or al, 1	;@32D7
	mov byte ptr LookX, al	;@32D9
	call Random	;@32DC
	and al, 0Fh	;@32DF
	or al, 1	;@32E1
	mov byte ptr LookY, al	;@32E3
	mov al, byte ptr DungeonLevel	;@32E6
	call ReadDungeonCell	;@32E9
	je Cast_BlinkGo	;@32EC
	jmp Cast_Failed	;@32EE
Cast_BlinkGo:	nop	;@32F1
	mov al, byte ptr LookX	;@32F2
	mov byte ptr PlayerX, al	;@32F5
	mov al, byte ptr LookY	;@32F8
	mov byte ptr PlayerY, al	;@32FB
	jmp EndCommand	;@32FE
; Kill: the monster in front dies (AttackD_Killed, with gold and Exp).
Cast_Kill:	call FindMonsterAhead	;@3301
	jne Cast_KillFound	;@3304
	jmp Cast_Failed	;@3306
Cast_KillFound:	jmp AttackD_Killed	;@3309
;------------------------------------------------------------------------------
; FindMonsterAhead: find the live monster (MonsterTile <> 0) on level DungeonLevel at the square in front
; of the player (PlayerX+FacingDX, PlayerY+FacingDY). Searches entries 1Fh down to 1.
; Out: found: DI = AX = index, ZF = 0; none: AL = 0, ZF = 1. Uses: AX, BX, DI.
;------------------------------------------------------------------------------
FindMonsterAhead:	mov bh, 0	;@330C
	mov bl, 1Fh	;@330E
	mov di, bx	;@3310
FindAhead_Loop:	mov al, byte ptr MonsterTile[di]	;@3312
	or al, al	; empty slot?	;@3316
	jne FindAhead_Check	;@3318
FindAhead_Next:	dec di	;@331A
	jne FindAhead_Loop	;@331B
	mov al, 0	;@331D
	or al, al	; ZF = 1: none	;@331F
	ret	;@3321
FindAhead_Check:	mov al, byte ptr MonsterUnder[di]	;@3322
	cmp al, byte ptr DungeonLevel	; on this level?	;@3326
	jne FindAhead_Next	;@332A
	mov al, byte ptr PlayerX	;@332C
	clc	;@332F
	adc al, byte ptr FacingDX	;@3330
	cmp al, byte ptr MonsterX[di]	;@3334
	jne FindAhead_Next	;@3338
	mov al, byte ptr PlayerY	;@333A
	clc	;@333D
	adc al, byte ptr FacingDY	;@333E
	cmp al, byte ptr MonsterY[di]	;@3342
	jne FindAhead_Next	;@3346
	mov ax, di	; found: AX = DI = index	;@3348
	or al, al	; ZF = 0	;@334A
	ret	;@334C
;------------------------------------------------------------------------------
; CmdDescend: command D, Descend a ladder, in a dungeon (MapType = 5) or tower (4), when
; the cell underfoot (TileHere) has the down-ladder bit 20h. In a dungeon one level
; deeper (Ladder_LevelInc), in a tower one floor down (Ladder_LevelDec; from floor 0 to the surface).
;------------------------------------------------------------------------------
CmdDescend:	call PrintInline	;@334D
	db 44h,45h,53h,43h,45h,4Eh,44h,0h	;@3350
	mov al, byte ptr MapType	;@3358
	cmp al, 5	;@335B
	je Descend_Check	;@335D
	cmp al, 4	;@335F
	je Descend_Check	;@3361
Descend_What:	call PrintInline	;@3363
	db 2Dh,57h,48h,41h,54h,3Fh,0h	;@3366
	jmp EndCommandBeep	;@336D
Descend_Check:	mov al, byte ptr TileHere	;@3370
	and al, 20h	; down ladder here?	;@3373
	je Descend_What	;@3375
	mov al, byte ptr MapType	;@3377
	cmp al, 4	;@337A
	jne Ladder_LevelInc	;@337C
	jmp Ladder_LevelDec	;@337E
; Ladder_LevelInc: level DungeonLevel + 1 (deeper in a dungeon, up in a tower); also from Klimb.
Ladder_LevelInc:	nop	;@3381
	inc byte ptr DungeonLevel	;@3382
	jmp Ladder_ShowLevel	;@3386
;------------------------------------------------------------------------------
; CmdEnter: command E, Enter, outdoors only (MapType = 0) and on foot (PlayerTile >= 78h).
; What is entered follows the tile underfoot TileHere: 0Ah village, 0Ch town,
; 0Eh tower, 10h castle, 12h dungeon, 14h sign. Towns: save the outdoor position
; in SurfaceX/SurfaceY, save map, monsters and player (SaveGame), load the town's map, monsters
; (LoadMapAndMonsters) and talk file (LoadTalkFile), start at (1Fh,3Eh). Tower and dungeon: level 0 at
; (5,5) facing east. A sign prints a text that depends on the era TimeZone.
;------------------------------------------------------------------------------
CmdEnter:	call PrintInline	;@3389
	db 45h,4Eh,54h,45h,52h,0h	;@338C
	mov al, byte ptr MapType	;@3392
	or al, al	;@3395
	je Enter_Outdoors	;@3397
	call PrintInline	;@3399
	db 20h,57h,48h,41h,54h,3Fh,0h	;@339C
	jmp EndCommand	;@33A3
Enter_Outdoors:	nop	;@33A6
	mov al, byte ptr PlayerTile	;@33A7
	cmp al, 78h	;@33AA
	jae Enter_Which	;@33AC
	call PrintInline	;@33AE
	db 2Dh,4Fh,4Eh,4Ch,59h,20h,4Fh,4Eh,20h,46h,4Fh,4Fh,54h,21h,0h	;@33B1
	jmp EndCommandBeep	;@33C0
; tile/2 - 5 = 0 village, 1 town, 2 tower, 3 castle, 4 dungeon, 5 sign (SEC/SBC chain)
Enter_Which:	nop	;@33C3
	mov al, byte ptr TileHere	;@33C4
	clc	;@33C7
	rcr al, 1	;@33C8
	stc	;@33CA
	cmc	;@33CB
	sbb al, 5	;@33CC
	cmc	;@33CE
	jne Enter_TryTown	;@33CF
	jmp Enter_Village	;@33D1
Enter_TryTown:	cmc	;@33D4
	sbb al, 1	;@33D5
	cmc	;@33D7
	jne Enter_TryTower	;@33D8
	jmp Enter_Town	;@33DA
Enter_TryTower:	cmc	;@33DD
	sbb al, 1	;@33DE
	cmc	;@33E0
	jne Enter_TryCastle	;@33E1
	jmp Enter_Tower	;@33E3
Enter_TryCastle:	cmc	;@33E6
	sbb al, 1	;@33E7
	cmc	;@33E9
	jne Enter_TryDungeon	;@33EA
	jmp Enter_Castle	;@33EC
Enter_TryDungeon:	cmc	;@33EF
	sbb al, 1	;@33F0
	cmc	;@33F2
	jne Enter_TrySign	;@33F3
	jmp Enter_Dungeon	;@33F5
Enter_TrySign:	cmc	;@33F8
	sbb al, 1	;@33F9
	cmc	;@33FB
	jne Enter_What	;@33FC
	jmp Enter_Sign	;@33FE
Enter_What:	nop	;@3401
	call PrintInline	;@3402
	db 20h,57h,48h,41h,54h,3Fh,0h	;@3405
	jmp EndCommand	;@340C
Enter_Village:	call PrintInline	;@340F
	db 2Dh,56h,49h,4Ch,4Ch,41h,47h,45h,0h	;@3412
	mov al, byte ptr PlayerX	;@341B
	mov byte ptr SurfaceX, al	; remember the outdoor position	;@341E
	mov al, byte ptr PlayerY	;@3421
	mov byte ptr SurfaceY, al	;@3424
	call SaveGame	; save map, monsters, player	;@3427
	mov al, 1Fh	;@342A
	mov byte ptr PlayerX, al	; start at the bottom middle	;@342C
	mov al, 3Eh	;@342F
	mov byte ptr PlayerY, al	;@3431
	mov al, 1	;@3434
	mov byte ptr MapType, al	; 1 = village	;@3436
	call LoadMapAndMonsters	; load MAPXe1 and MONXe1 (e = era digit)	;@3439
	call LoadTalkFile	; load the talk file TLKXe1	;@343C
	mov al, 4	;@343F
	mov byte ptr OffMapTile, al	; tile shown beyond the map edge	;@3441
	jmp EndCommand	;@3444
Enter_Town:	call PrintInline	;@3447
	db 2Dh,54h,4Fh,57h,4Eh,0h	;@344A
	mov al, byte ptr PlayerX	;@3450
	mov byte ptr SurfaceX, al	;@3453
	mov al, byte ptr PlayerY	;@3456
	mov byte ptr SurfaceY, al	;@3459
	call SaveGame	;@345C
	mov al, 1Fh	;@345F
	mov byte ptr PlayerX, al	;@3461
	mov al, 3Eh	;@3464
	mov byte ptr PlayerY, al	;@3466
	mov al, 2	;@3469
	mov byte ptr MapType, al	;@346B
	call LoadMapAndMonsters	;@346E
	call LoadTalkFile	;@3471
	mov al, 4	;@3474
	mov byte ptr OffMapTile, al	;@3476
	jmp EndCommand	;@3479
Enter_Tower:	call PrintInline	;@347C
	db 2Dh,54h,4Fh,57h,45h,52h,0h	;@347F
	mov al, byte ptr PlayerX	;@3486
	mov byte ptr SurfaceX, al	;@3489
	mov al, byte ptr PlayerY	;@348C
	mov byte ptr SurfaceY, al	;@348F
	call SaveGame	;@3492
	mov al, 0	;@3495
	mov byte ptr DungeonLevel, al	; level 0	;@3497
	mov byte ptr FacingDY, al	;@349A
	mov al, 1	;@349D
	mov byte ptr FacingDX, al	; facing (1,0) = east	;@349F
	mov al, 5	;@34A2
	mov byte ptr PlayerX, al	; at (5,5)	;@34A4
	mov byte ptr PlayerY, al	;@34A7
	mov al, 4	;@34AA
	mov byte ptr MapType, al	; 4 = tower	;@34AC
	call LoadMapAndMonsters	;@34AF
	jmp EndCommand	;@34B2
Enter_Castle:	call PrintInline	;@34B5
	db 2Dh,43h,41h,53h,54h,4Ch,45h,0h	;@34B8
	mov al, byte ptr PlayerX	;@34C0
	mov byte ptr SurfaceX, al	;@34C3
	mov al, byte ptr PlayerY	;@34C6
	mov byte ptr SurfaceY, al	;@34C9
	call SaveGame	;@34CC
	mov al, 1Fh	;@34CF
	mov byte ptr PlayerX, al	;@34D1
	mov al, 3Eh	;@34D4
	mov byte ptr PlayerY, al	;@34D6
	mov al, 3	;@34D9
	mov byte ptr MapType, al	;@34DB
	call LoadMapAndMonsters	;@34DE
	call LoadTalkFile	;@34E1
	mov al, 4	;@34E4
	mov byte ptr OffMapTile, al	;@34E6
	jmp EndCommand	;@34E9
Enter_Dungeon:	call PrintInline	;@34EC
	db 2Dh,44h,55h,4Eh,47h,45h,4Fh,4Eh,0h	;@34EF
	mov al, byte ptr PlayerX	;@34F8
	mov byte ptr SurfaceX, al	;@34FB
	mov al, byte ptr PlayerY	;@34FE
	mov byte ptr SurfaceY, al	;@3501
	call SaveGame	;@3504
	mov al, 0	;@3507
	mov byte ptr DungeonLevel, al	;@3509
	mov byte ptr FacingDY, al	;@350C
	mov al, 1	;@350F
	mov byte ptr FacingDX, al	;@3511
	mov al, 5	;@3514
	mov byte ptr PlayerX, al	;@3516
	mov byte ptr PlayerY, al	;@3519
	mov byte ptr MapType, al	; still 5: 5 = dungeon	;@351C
	call LoadMapAndMonsters	;@351F
	jmp EndCommand	;@3522
; The sign: era 0 Legends, 1 Pangea (9,000,000 B.C.), 2 B.C. (1423), 3 A.D. (1990),
; 4 and up the Aftermath (2112).
Enter_Sign:	call PrintInline	;@3525
	db 2Dh,54h,48h,45h,20h,53h,49h,47h,4Eh,20h,52h,45h,41h,44h,53h,3Ah	;@3528
	db 0Dh,0h	;@3538
	mov bh, 0	;@353A
	mov bl, byte ptr TimeZone	; era	;@353C
	mov di, bx	;@3540
	or di, di	;@3542
	je Sign_Legends	;@3544
	dec di	;@3546
	je Sign_Pangea	;@3547
	dec di	;@3549
	je Sign_BC	;@354A
	dec di	;@354C
	je Sign_AD	;@354D
	call PrintInline	;@354F
	db 41h,4Eh,4Fh,53h,3Ah,20h,32h,31h,31h,32h,20h,41h,2Eh,44h,2Eh,0h	;@3552
	jmp EndCommand	;@3562
Sign_Legends:	call PrintInline	;@3565
	db 41h,4Eh,4Fh,53h,3Ah,20h,4Ch,45h,47h,45h,4Eh,44h,53h,21h,0h	;@3568
	jmp EndCommand	;@3577
Sign_Pangea:	call PrintInline	;@357A
	db 41h,4Eh,4Fh,53h,3Ah,20h,39h,2Ch,30h,30h,30h,2Ch,30h,30h,30h,20h	;@357D
	db 42h,2Eh,43h,2Eh,0h	;@358D
	jmp EndCommand	;@3592
Sign_BC:	call PrintInline	;@3595
	db 41h,4Eh,4Fh,53h,3Ah,20h,31h,34h,32h,33h,20h,42h,2Eh,43h,2Eh,0h	;@3598
	jmp EndCommand	;@35A8
Sign_AD:	call PrintInline	;@35AB
	db 41h,4Eh,4Fh,53h,3Ah,20h,31h,39h,39h,30h,20h,41h,2Eh,44h,2Eh,0h	;@35AE
	jmp EndCommand	;@35BE
;------------------------------------------------------------------------------
; CmdFire: command F, Fire the cannons, only from a frigate (PlayerTile = 24h). Asks for
; a direction; the monster on the adjacent square takes random 20h-FFh damage,
; through the Attack damage code at Attack_Damage (so Minax's teleport applies too).
;------------------------------------------------------------------------------
CmdFire:	call PrintInline	;@35C1
	db 46h,49h,52h,45h,0h	;@35C4
	mov al, byte ptr PlayerTile	;@35C9
	cmp al, 24h	; on a frigate?	;@35CC
	je Fire_FromFrigate	;@35CE
	call PrintInline	;@35D0
	db 20h,57h,48h,41h,54h,3Fh,0h	;@35D3
	jmp EndCommandBeep	;@35DA
Fire_FromFrigate:	nop	;@35DD
	call PrintInline	;@35DE
	db 20h,44h,49h,52h,45h,43h,54h,2Dh,0h	;@35E1
	call ReadDirection	; read a direction	;@35EA
	call PlayAttackSound	; cannon sound	;@35ED
	call FindMonsterInDir	; DI = monster there, 0 = none	;@35F0
	mov bx, di	;@35F3
	mov byte ptr Temp20, bl	;@35F5
	mov bx, di	;@35F9
	cmp bl, 0	;@35FB
	jne Fire_Hit	;@35FE
	jmp Attack_Miss	;@3600
Fire_Hit:	call Random	;@3603
	or al, 20h	;@3606
	mov byte ptr Temp1F, al	; damage	;@3608
	call XorAttackMark	; draw the hit marker	;@360B
	call PlayHitSound	;@360E
	mov bh, 0	;@3611
	mov bl, byte ptr Temp20	;@3613
	mov di, bx	;@3617
	jmp Attack_Damage	;@3619
;------------------------------------------------------------------------------
; RemoveItemHere: outside dungeons and towers (MapType < 4) replace the map byte under the
; player by 8 (floor / grass): the item taken by Get is gone. In a dungeon or
; tower it does nothing. Out: MapCellPtr, SI = 0. Uses: AL, BX, SI.
;------------------------------------------------------------------------------
RemoveItemHere:	cmp byte ptr MapType, 4	;@361C
	jae RemoveItem_Done	;@3621
	mov al, byte ptr PlayerX	;@3623
	mov byte ptr LookX, al	;@3626
	mov al, byte ptr PlayerY	;@3629
	mov byte ptr LookY, al	;@362C
	call GetMapSquare	;@362F
	mov al, 8	;@3632
	mov bx, word ptr MapCellPtr	;@3634
	mov byte ptr [bx+si], al	;@3638
RemoveItem_Done:	ret	;@363A
;------------------------------------------------------------------------------
; CmdGet: command G, Get. Outdoors / in towns, from the tile underfoot: 2Ah armour
; (random 1-3: cloth, leather, chain; 1 in 4 empty) or 2Ch a weapon (random 1-7:
; dagger to light sword; 1 in 8 empty). In a dungeon or tower: 40h a chest, which
; is removed and holds Tri-lithium on level 0Fh, else gold (3 in 4), else armour
; (odd levels) or a weapon (even levels). Counts are BCD.
;------------------------------------------------------------------------------
CmdGet:	call PrintInline	;@363B
	db 47h,45h,54h,0h	;@363E
	mov al, byte ptr MapType	;@3642
	cmp al, 4	;@3645
	jb Get_Surface	;@3647
	jmp Get_Dungeon	;@3649
Get_Surface:	nop	;@364C
	mov al, byte ptr TileHere	;@364D
	cmp al, 2Ah	; armour	;@3650
	je Get_Armour	;@3652
	cmp al, 2Ch	; weapon	;@3654
	je Get_Weapon	;@3656
	call PrintInline	;@3658
	db 20h,57h,48h,41h,54h,3Fh,0h	;@365B
	jmp EndCommand	;@3662
Get_Weapon:	call PrintInline	;@3665
	db 20h,57h,45h,41h,50h,4Fh,4Eh,0h	;@3668
	call RemoveItemHere	; take it off the map	;@3670
	call Random	;@3673
	and al, 7	;@3676
	je Get_Empty	;@3678
	mov ah, 0	;@367A
	mov di, ax	;@367C
	clc	;@367E
	mov al, byte ptr WeaponCounts[di]	;@367F
	adc al, 1	;@3683
	daa	; weapons[1-7] + 1	;@3685
	mov byte ptr WeaponCounts[di], al	;@3686
	jmp EndCommand	;@368A
Get_Empty:	call PrintInline	;@368D
	db 20h,45h,4Dh,50h,54h,59h,21h,0h	;@3690
	jmp EndCommand	;@3698
Get_Armour:	call PrintInline	;@369B
	db 20h,41h,52h,4Dh,4Fh,55h,52h,0h	;@369E
	call RemoveItemHere	;@36A6
	call Random	;@36A9
	and al, 3	;@36AC
	je Get_Empty	;@36AE
	mov ah, 0	;@36B0
	mov di, ax	;@36B2
	clc	;@36B4
	mov al, byte ptr ArmourCounts[di]	;@36B5
	adc al, 1	;@36B9
	daa	; armours[1-3] + 1	;@36BB
	mov byte ptr ArmourCounts[di], al	;@36BC
	jmp EndCommand	;@36C0
Get_Dungeon:	nop	;@36C3
	mov al, byte ptr TileHere	;@36C4
	cmp al, 40h	; chest	;@36C7
	je Get_Chest	;@36C9
	call PrintInline	;@36CB
	db 20h,57h,48h,41h,54h,3Fh,0h	;@36CE
	jmp EndCommand	;@36D5
Get_Chest:	nop	;@36D8
	call PrintInline	;@36D9
	db 20h,43h,48h,45h,53h,54h,21h,8Dh,49h,54h,20h,43h,4Fh,4Eh,54h,41h	;@36DC
	db 49h,4Eh,53h,20h,0h	;@36EC
	mov al, byte ptr PlayerX	;@36F1
	mov byte ptr LookX, al	;@36F4
	mov al, byte ptr PlayerY	;@36F7
	mov byte ptr LookY, al	;@36FA
	mov al, byte ptr DungeonLevel	;@36FD
	call ReadDungeonCell	;@3700
	mov al, 0	;@3703
	mov bx, word ptr DungeonCellPtr	;@3705
	mov byte ptr [bx+si], al	; the chest is gone	;@3709
	mov al, byte ptr DungeonLevel	;@370B
	cmp al, 0Fh	; deepest level?	;@370E
	je Get_TriLithium	;@3710
	call Random	;@3712
	cmp al, 40h	;@3715
	jb Get_ChestItem	;@3717
	call PrintInline	;@3719
	db 47h,4Fh,4Ch,44h,21h,0h	;@371C
; gold + (random 0-1Fh + 2*level + carry) AND 77h: both digits 0-7, valid BCD
	call Random	;@3722
	and al, 1Fh	;@3725
	adc al, byte ptr DungeonLevel	;@3727
	adc al, byte ptr DungeonLevel	;@372B
	and al, 77h	;@372F
	clc	;@3731
	adc al, byte ptr GoldLo	;@3732
	daa	;@3736
	mov byte ptr GoldLo, al	;@3737
	mov al, byte ptr GoldHi	;@373A
	adc al, 0	;@373D
	daa	;@373F
	mov byte ptr GoldHi, al	;@3740
	jmp EndCommand	;@3743
Get_ChestItem:	mov al, byte ptr DungeonLevel	;@3746
	clc	;@3749
	rcr al, 1	; odd level?	;@374A
	jae Get_ChestWeapon	;@374C
	jmp Get_Armour	; armour (RemoveItemHere does nothing here)	;@374E
Get_ChestWeapon:	call PrintInline	;@3751
	db 41h,20h,0h	;@3754
	jmp Get_Weapon	; "A" + " WEAPON": printed with two spaces	;@3757
Get_TriLithium:	call PrintInline	;@375A
	db 54h,52h,49h,2Dh,4Ch,49h,54h,48h,49h,55h,4Dh,21h,0h	;@375D
	clc	;@376A
	mov al, byte ptr TriLithium	;@376B
	adc al, 1	;@376E
	daa	; Tri-lithium + 1	;@3770
	mov byte ptr TriLithium, al	;@3771
	jmp EndCommand	;@3774
; 11 unused zero bytes (nothing reaches them)
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h	;@3777
;------------------------------------------------------------------------------
; CmdHyperspace: command H, Hyperspace: nothing on the ground (in space the 'H' key is read
; by the space flight code in SPACE, hyperwarp).
;------------------------------------------------------------------------------
CmdHyperspace:	call PrintInline	;@3782
	db 48h,59h,50h,45h,52h,20h,57h,48h,41h,54h,3Fh,0h	;@3785
	jmp EndCommand	;@3791
;------------------------------------------------------------------------------
; CmdIgniteTorch: command I, Ignite torch: only in a dungeon or tower (elsewhere nothing
; happens). Uses up one torch (Torches, BCD) and sets the light counter LightTurns = 96h.
;------------------------------------------------------------------------------
CmdIgniteTorch:	call PrintInline	;@3794
	db 49h,47h,4Eh,49h,54h,45h,20h,54h,4Fh,52h,43h,48h,0h	;@3797
	mov al, byte ptr MapType	;@37A4
	cmp al, 4	;@37A7
	jae Ignite_InDungeon	;@37A9
	jmp EndCommand	;@37AB
Ignite_InDungeon:	mov al, byte ptr Torches	; torches	;@37AE
	or al, al	;@37B1
	jne Ignite_UseTorch	;@37B3
	call PrintInline	;@37B5
	db 8Dh,4Eh,4Fh,4Eh,45h,20h,4Fh,57h,4Eh,45h,44h,21h,0h	;@37B8
	jmp EndCommandBeep	;@37C5
Ignite_UseTorch:	stc	;@37C8
	mov al, byte ptr Torches	;@37C9
	cmc	;@37CC
	sbb al, 1	;@37CD
	das	; torches - 1 (BCD)	;@37CF
	cmc	;@37D0
	mov byte ptr Torches, al	;@37D1
	mov al, 96h	;@37D4
	mov byte ptr LightTurns, al	;@37D6
	jmp EndCommand	;@37D9
;------------------------------------------------------------------------------
; CmdJump: command J, Jump: prints a text, no effect.
;------------------------------------------------------------------------------
CmdJump:	call PrintInline	;@37DC
	db 4Ah,55h,4Dh,50h,2Eh,2Eh,2Eh,57h,48h,45h,45h,2Eh,2Eh,2Eh,0h	;@37DF
	jmp EndCommand	;@37EE
;------------------------------------------------------------------------------
; CmdKlimb: command K, Klimb a ladder, in a dungeon or tower, when the cell underfoot
; (TileHere) has the up-ladder bit 10h. In a tower one floor up (Ladder_LevelInc), in a dungeon
; one level up (Ladder_LevelDec; from level 0 back to the surface).
;------------------------------------------------------------------------------
CmdKlimb:	call PrintInline	;@37F1
	db 4Bh,4Ch,49h,4Dh,42h,0h	;@37F4
	mov al, byte ptr MapType	;@37FA
	cmp al, 5	;@37FD
	je Klimb_Check	;@37FF
	cmp al, 4	;@3801
	je Klimb_Check	;@3803
Klimb_What:	call PrintInline	;@3805
	db 2Dh,57h,48h,41h,54h,3Fh,0h	;@3808
	jmp EndCommand	;@380F
Klimb_Check:	mov al, byte ptr TileHere	;@3812
	and al, 10h	; up ladder here?	;@3815
	je Klimb_What	;@3817
	mov al, byte ptr MapType	;@3819
	cmp al, 4	;@381C
	jne Ladder_LevelDec	;@381E
	jmp Ladder_LevelInc	;@3820
; Ladder_LevelDec: level DungeonLevel - 1 (also from Descend in a tower); below 0 = the surface.
Ladder_LevelDec:	nop	;@3823
	dec byte ptr DungeonLevel	;@3824
	js ExitToSurface	;@3828
; Ladder_ShowLevel: print "TO LEVEL n" (also the end of the ladder spells).
Ladder_ShowLevel:	call PrintInline	;@382A
	db 8Dh,54h,4Fh,20h,4Ch,45h,56h,45h,4Ch,20h,0h	;@382D
	mov al, byte ptr DungeonLevel	;@3838
	add al, 0	;@383B
	daa	; level 0-15 as BCD 00-15	;@383D
	call PrintBcdByte	;@383E
	jmp EndCommand	;@3841
;------------------------------------------------------------------------------
; ExitToSurface: leave a dungeon or tower for the outdoor map (from Klimb, Descend,
; and the spells Surface and Up / Down ladder). Back to the saved outdoor position
; SurfaceX/SurfaceY, invalidate the map view caches TileCache/TileCacheShown (FFh = redraw all),
; reload the outdoor map and monsters (LoadMapAndMonsters). Away from Earth (Planet <> 0) the
; rocket tile 50h is put back at RocketX/RocketY; on Earth the player record PlayerRecord
; is written to the file PLAYER.
;------------------------------------------------------------------------------
ExitToSurface:	nop	;@3844
	mov al, byte ptr SurfaceX	;@3845
	mov byte ptr PlayerX, al	;@3848
	mov al, byte ptr SurfaceY	;@384B
	mov byte ptr PlayerY, al	;@384E
	mov bx, 0FEh	;@3851
	mov ax, 0FFFFh	;@3854
ExitSurf_ClearView:	mov word ptr TileCache[bx], ax	;@3857
	mov word ptr TileCacheShown[bx], ax	;@385B
	sub bx, 2	;@385F
	jns ExitSurf_ClearView	;@3862
	mov al, 0	;@3864
	mov byte ptr MapType, al	; 0 = outdoors	;@3866
	call LoadMapAndMonsters	;@3869
	mov al, byte ptr SurfaceX	; (again)	;@386C
	mov byte ptr PlayerX, al	;@386F
	mov al, byte ptr SurfaceY	;@3872
	mov byte ptr PlayerY, al	;@3875
	mov al, byte ptr Planet	;@3878
	or al, al	;@387B
	je ExitSurf_SavePlayer	;@387D
	mov al, byte ptr RocketX	;@387F
	mov byte ptr LookX, al	;@3882
	mov al, byte ptr RocketY	;@3885
	mov byte ptr LookY, al	;@3888
	call GetMapSquare	;@388B
	mov al, 50h	; map byte of the rocket	;@388E
	mov bx, word ptr MapCellPtr	;@3890
	mov byte ptr [bx+si], al	;@3894
	jmp EndCommand	;@3896
ExitSurf_SavePlayer:	lea dx, PlayerRecord	;@3899
	mov ah, 28h	; DOS random block write	;@389D
	mov cx, 100h	; 256 bytes	;@389F
	call ReadWriteFile	;@38A2
	db 50h,4Ch,41h,59h,45h,52h,20h,20h	;@38A5
	jmp EndCommand	;@38AD
;------------------------------------------------------------------------------
; CmdLaunch: command L, Launch: the plane (PlayerTile = 26h, see Launch_Plane) or the rocket (28h).
; The rocket needs Tri-lithium (TriLithium, not used up here). Launching from the
; outdoor map of Earth (Planet = 0) parks the rocket's position in RocketX/RocketY
; (RocketParked = 1) and saves (SaveGame); then space flight (SpaceFlight). Back on a map, the
; landing spot scrolls by until a key is pressed: grass (map byte 8) is a landing,
; anything else a crash (PlayerDies, the player dies).
;------------------------------------------------------------------------------
CmdLaunch:	mov al, byte ptr PlayerTile	;@38B0
	cmp al, 26h	; plane	;@38B3
	jne Launch_NotPlane	;@38B5
	jmp Launch_Plane	;@38B7
Launch_NotPlane:	nop	;@38BA
	cmp al, 28h	; rocket	;@38BB
	je Launch_Rocket	;@38BD
	call PrintInline	;@38BF
	db 4Ch,41h,55h,4Eh,43h,48h,20h,57h,48h,41h,54h,3Fh,0h	;@38C2
	jmp EndCommand	;@38CF
Launch_Rocket:	call PrintInline	;@38D2
	db 4Ch,41h,55h,4Eh,43h,48h,2Dh,2Dh,52h,4Fh,43h,4Bh,45h,54h,0h	;@38D5
	mov al, byte ptr TriLithium	; Tri-lithium	;@38E4
	or al, al	;@38E7
	jne Launch_Prepare	;@38E9
	call PrintInline	;@38EB
	db 8Dh,41h,20h,4Dh,45h,54h,41h,4Ch,4Ch,49h,43h,20h,56h,4Fh,49h,43h	;@38EE
	db 45h,20h,53h,41h,59h,53h,3Ah,8Dh,53h,48h,49h,50h,20h,49h,4Eh,43h	;@38FE
	db 41h,50h,41h,42h,4Ch,45h,20h,4Fh,46h,20h,4Ch,41h,55h,4Eh,43h,48h	;@390E
	db 21h,0h	;@391E
	jmp EndCommand	;@3920
Launch_Prepare:	call PrintInline	;@3923
	db 8Dh,50h,52h,45h,50h,41h,52h,45h,20h,46h,4Fh,52h,20h,4Ch,41h,55h	;@3926
	db 4Eh,43h,48h,21h,0h	;@3936
	mov al, byte ptr Planet	; on Earth ...	;@393B
	or al, al	;@393E
	jne Launch_Fly	;@3940
	mov al, byte ptr MapType	; ... and outdoors?	;@3942
	or al, al	;@3945
	jne Launch_Fly	;@3947
	mov al, byte ptr PlayerX	;@3949
	mov byte ptr RocketX, al	; remember where the rocket stood	;@394C
	mov al, byte ptr PlayerY	;@394F
	mov byte ptr RocketY, al	;@3952
	mov al, 1	;@3955
	mov byte ptr RocketParked, al	;@3957
	call SaveGame	; save map, monsters, player	;@395A
Launch_Fly:	nop	;@395D
	call SpaceFlight	; space flight	;@395E
	call LoadMapAndMonsters	; load the map of where we came down	;@3961
	mov di, 0FFh	;@3964
	mov al, 0FFh	;@3967
Launch_ClearView:	mov byte ptr TileCache[di], al	; invalidate the view caches	;@3969
	mov byte ptr TileCacheShown[di], al	;@396D
	dec di	;@3971
	jns Launch_ClearView	;@3972
	mov byte ptr PlayerX, 0	;@3974
	mov byte ptr PlayerY, 0	;@3979
	mov byte ptr OffMapTile, al	; FFh: UpdateMapView draws the landing view	;@397E
	call PrintInline	;@3981
	db 28h,50h,52h,45h,53h,53h,20h,41h,4Eh,59h,20h,4Bh,45h,59h,29h,0h	;@3984
; Descent: the map scrolls by (Y + 2 each frame, X + 1 every 4 frames, both mod 64)
; until a key is pressed.
Launch_Descent:	mov al, byte ptr PlayerY	;@3994
	clc	;@3997
	adc al, 2	;@3998
	and al, 3Fh	;@399A
	mov byte ptr PlayerY, al	;@399C
	and al, 7	;@399F
	jne Launch_DescentDraw	;@39A1
	mov al, byte ptr PlayerX	;@39A3
	clc	;@39A6
	adc al, 1	;@39A7
	and al, 3Fh	;@39A9
	mov byte ptr PlayerX, al	;@39AB
Launch_DescentDraw:	call UpdateMapView	; draw the map view	;@39AE
	mov bx, 1Ch	;@39B1
	call SpeedDelay	; delay (CPU speed dependent)	;@39B4
	call ReadKey	; key? AH = FFh	;@39B7
	cmp ah, 0FFh	;@39BA
	jne Launch_Descent	;@39BD
	mov al, byte ptr PlayerX	;@39BF
	mov byte ptr LookX, al	;@39C2
	mov al, byte ptr PlayerY	;@39C5
	mov byte ptr LookY, al	;@39C8
	call GetMapSquare	; AL = map byte here	;@39CB
	and al, 7Fh	;@39CE
	cmp al, 8	; grass?	;@39D0
	je Launch_Landed	;@39D2
	jmp PlayerDies	; crashed: the player dies	;@39D4
Launch_Landed:	mov al, byte ptr Planet	;@39D7
	or al, al	;@39DA
	jne Launch_LandedAway	;@39DC
	mov al, 0	;@39DE
	mov byte ptr RocketParked, al	; on Earth: no parked rocket	;@39E0
	jmp EndCommand	;@39E3
Launch_LandedAway:	mov al, byte ptr PlayerX	;@39E6
	mov byte ptr RocketX, al	; elsewhere: remember the landing spot	;@39E9
	mov al, byte ptr PlayerY	;@39EC
	mov byte ptr RocketY, al	;@39EF
	mov al, 1	;@39F2
	mov byte ptr RocketParked, al	;@39F4
	jmp EndCommand	;@39F7
;------------------------------------------------------------------------------
; Launch_Plane: Launch the plane; needs a brass button (BrassButtons). It then flies on its own,
; one square per frame in the direction set by the N/S/E/W keys (KeyNorth-KeyWest),
; over any terrain, while PlaneFlying = FFh; 'L' lands, on grass (map byte 8) only. In a
; town, reaching row or column 0 leaves the town (LeaveToSurface).
;------------------------------------------------------------------------------
Launch_Plane:	call PrintInline	;@39FA
	db 4Ch,41h,55h,4Eh,43h,48h,2Dh,2Dh,50h,4Ch,41h,4Eh,45h,0h	;@39FD
	mov al, byte ptr BrassButtons	; brass buttons	;@3A0B
	or al, al	;@3A0E
	jne Plane_TakeOff	;@3A10
	call PrintInline	;@3A12
	db 8Dh,46h,55h,4Eh,4Eh,59h,20h,54h,48h,49h,53h,20h,50h,4Ch,41h,4Eh	;@3A15
	db 45h,20h,49h,53h,8Dh,4Dh,49h,53h,53h,49h,4Eh,47h,20h,41h,20h,42h	;@3A25
	db 52h,41h,53h,53h,20h,42h,55h,54h,54h,4Fh,4Eh,21h,0h	;@3A35
	jmp EndCommandBeep	;@3A42
Plane_TakeOff:	nop	;@3A45
	mov al, 0	;@3A46
	mov byte ptr Temp21, al	; heading dx = 0	;@3A48
	mov al, 0FFh	;@3A4B
	mov byte ptr Temp22, al	; heading dy = -1: north	;@3A4D
	call PrintInline	;@3A50
	db 0Dh,43h,4Dh,44h,3Ah,20h,0h	;@3A53
	mov byte ptr PlaneFlying, 0FFh	; flying	;@3A5A
Plane_Loop:	call PlayStepSound	; engine sound	;@3A5F
	mov bx, 2	;@3A62
	call SpeedDelay	; delay (CPU speed dependent)	;@3A65
	call ReadKey	; key? AH = FFh	;@3A68
	cmp ah, 0FFh	;@3A6B
	jne Plane_Step	;@3A6E
	cmp al, byte ptr KeyNorth	; north key	;@3A70
	jne Plane_TrySouth	;@3A74
	jmp Plane_North	;@3A76
Plane_TrySouth:	cmp al, byte ptr KeySouth	; south	;@3A79
	jne Plane_TryEast	;@3A7D
	jmp Plane_South	;@3A7F
Plane_TryEast:	cmp al, byte ptr KeyEast	; east	;@3A82
	jne Plane_TryWest	;@3A86
	jmp Plane_East	;@3A88
Plane_TryWest:	cmp al, byte ptr KeyWest	; west	;@3A8B
	jne Plane_TryLand	;@3A8F
	jmp Plane_West	;@3A91
Plane_TryLand:	cmp al, 4Ch	; 'L' = land	;@3A94
	jne Plane_Step	;@3A96
	jmp Plane_Land	;@3A98
; one step in the heading, wrapping at 64
Plane_Step:	clc	;@3A9B
	mov al, byte ptr PlayerX	;@3A9C
	adc al, byte ptr Temp21	;@3A9F
	and al, 3Fh	;@3AA3
	mov byte ptr PlayerX, al	;@3AA5
	clc	;@3AA8
	mov al, byte ptr PlayerY	;@3AA9
	adc al, byte ptr Temp22	;@3AAC
	and al, 3Fh	;@3AB0
	mov byte ptr PlayerY, al	;@3AB2
	mov al, byte ptr MapType	;@3AB5
	or al, al	; outdoors?	;@3AB8
	je Plane_Redraw	;@3ABA
	mov al, byte ptr PlayerX	;@3ABC
	or al, al	;@3ABF
	je Plane_LeaveTown	;@3AC1
	mov al, byte ptr PlayerY	;@3AC3
	or al, al	;@3AC6
	je Plane_LeaveTown	;@3AC8
	jmp Plane_Redraw	;@3ACA
Plane_LeaveTown:	mov byte ptr PlaneFlying, 0	;@3ACD
	jmp LeaveToSurface	; at a town's edge: back to the outdoor map	;@3AD2
Plane_Redraw:	nop	;@3AD5
	call UpdateMapView	; draw the map view	;@3AD6
	jmp Plane_Loop	;@3AD9
Plane_North:	mov al, 0	;@3ADB
	mov byte ptr Temp21, al	;@3ADD
	mov al, 0FFh	;@3AE0
	mov byte ptr Temp22, al	;@3AE2
	call PrintInline	;@3AE5
	db 4Eh,4Fh,52h,54h,48h,0Dh,43h,4Dh,44h,3Ah,20h,0h	;@3AE8
	jmp Plane_Step	;@3AF4
Plane_South:	mov al, 0	;@3AF6
	mov byte ptr Temp21, al	;@3AF8
	mov al, 1	;@3AFB
	mov byte ptr Temp22, al	;@3AFD
	call PrintInline	;@3B00
	db 53h,4Fh,55h,54h,48h,0Dh,43h,4Dh,44h,3Ah,20h,0h	;@3B03
	jmp Plane_Step	;@3B0F
Plane_East:	mov al, 1	;@3B11
	mov byte ptr Temp21, al	;@3B13
	mov al, 0	;@3B16
	mov byte ptr Temp22, al	;@3B18
	call PrintInline	;@3B1B
	db 45h,41h,53h,54h,0Dh,43h,4Dh,44h,3Ah,20h,0h	;@3B1E
	jmp Plane_Step	;@3B29
Plane_West:	mov al, 0FFh	;@3B2C
	mov byte ptr Temp21, al	;@3B2E
	mov al, 0	;@3B31
	mov byte ptr Temp22, al	;@3B33
	call PrintInline	;@3B36
	db 57h,45h,53h,54h,0Dh,43h,4Dh,44h,3Ah,20h,0h	;@3B39
	jmp Plane_Step	;@3B44
; 'L': land if the map byte here is 8 (grass; unlike the rocket, bit 7 not masked)
Plane_Land:	mov al, byte ptr PlayerX	;@3B47
	mov byte ptr LookX, al	;@3B4A
	mov al, byte ptr PlayerY	;@3B4D
	mov byte ptr LookY, al	;@3B50
	call GetMapSquare	;@3B53
	cmp al, 8	;@3B56
	jne Plane_NotHere	;@3B58
	call PrintInline	;@3B5A
	db 4Ch,41h,4Eh,44h,20h,50h,4Ch,41h,4Eh,45h,2Eh,0h	;@3B5D
	mov byte ptr PlaneFlying, 0	; not flying	;@3B69
	jmp EndCommand	;@3B6E
Plane_NotHere:	nop	; not here: keep flying	;@3B71
	call PrintInline	;@3B72
	db 4Ch,41h,4Eh,44h,2Dh,2Dh,4Eh,4Fh,54h,20h,48h,45h,52h,45h,21h,21h	;@3B75
	db 21h,21h,21h,0Dh,43h,4Dh,44h,3Ah,20h,0h	;@3B85
	jmp Plane_Step	;@3B8F
CODE ENDS
END
