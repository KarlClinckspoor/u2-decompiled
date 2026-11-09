; CMDAL.ASM: commands A-L (attack, board, cast, descend, enter, fire, get, ...).
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 2B65-3B92.
;
; The handlers of the player commands A to L, entered by `jmp bx` from the jump table at L0730
; (MAIN): L2B8F Attack, L2F6F Board, L310B Cast, L334D Descend, L3389 Enter, L35C1 Fire,
; L363B Get, L3782 Hyperspace, L3794 Ignite torch, L37DC Jump, L37F1 Klimb, L38B0 Launch.
; Each prints its name inline and leaves by `jmp L0A33` (end of the turn) or `jmp L0A30`
; (error beep, then L0A33). Also here: L2B65, one dot of the overview map (called by DUNGEON),
; L330C (find the monster in front of the player in a dungeon), L361C (remove the item the
; player stands on), and the shared ladder / level change code (L3381, L3823, L382A) and the
; return to the outdoor map (L3844) used by Descend, Klimb and the Cast spells.
; Data mostly used: player position D_0000/D_0001, the dungeon facing D_0002/D_0003, the map
; type D_004A (0 outdoors, 1 village, 2 town, 3 castle, 4 tower, 5 dungeon), the dungeon level
; D_0025, the vehicle D_0013 and the tile underfoot D_0014, the monster table (32 entries:
; X D_0137, Y D_0157, HP D_0177, tile D_0197, tile under / dungeon level D_01B7, flags D_01D7),
; and the player record in D_0036.. (Exp D_0056/57, Gold D_0058/59, inventory counts, BCD).
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0000:BYTE, D_0001:BYTE, D_0002:BYTE, D_0003:BYTE, D_0006:BYTE, D_0008:BYTE
	EXTRN D_0012:BYTE, D_0013:BYTE, D_0014:BYTE, D_0019:BYTE, D_001A:BYTE, D_001F:BYTE
	EXTRN D_0020:BYTE, D_0021:BYTE, D_0022:BYTE, D_0023:BYTE, D_0024:BYTE, D_0025:BYTE
	EXTRN D_0026:BYTE, D_0036:BYTE, D_0049:BYTE, D_004A:BYTE, D_004B:BYTE, D_004C:BYTE
	EXTRN D_0056:BYTE, D_0057:BYTE, D_0058:BYTE, D_0059:BYTE, D_005A:BYTE, D_005B:BYTE
	EXTRN D_0061:BYTE, D_0063:BYTE, D_0064:BYTE, D_0065:BYTE, D_0066:BYTE, D_0069:BYTE
	EXTRN D_006A:BYTE, D_006B:BYTE, D_006D:BYTE, D_0076:BYTE, D_0096:BYTE, D_00B6:BYTE
	EXTRN D_00D6:BYTE, D_00D7:BYTE, D_00D8:BYTE, D_00DB:BYTE, D_00DD:BYTE, D_00DF:BYTE
	EXTRN D_00E1:BYTE, D_00E2:BYTE, D_00E5:BYTE, D_0137:BYTE, D_0157:BYTE, D_0177:BYTE
	EXTRN D_0197:BYTE, D_01B7:BYTE, D_01D7:BYTE, D_026C:BYTE, D_026E:BYTE, D_026F:BYTE
	EXTRN D_0270:BYTE, D_0271:BYTE, D_0272:BYTE, D_0372:BYTE, D_0479:BYTE, D_047A:BYTE
	EXTRN D_054E:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L0711:NEAR, L0A30:NEAR, L0A33:NEAR, L0C62:NEAR, L113A:NEAR, L1451:NEAR
	EXTRN L2290:NEAR, L22D5:NEAR, L22FD:NEAR, L2362:NEAR, L23E6:NEAR, L243E:NEAR
	EXTRN L4B26:NEAR, L4B76:NEAR, L4F4D:NEAR, L4FDF:NEAR, L507A:NEAR, L508C:NEAR
	EXTRN L50B3:NEAR, L5217:NEAR, L523E:NEAR, L52CA:NEAR, L53B5:NEAR, L5AB1:NEAR
	EXTRN L5E83:NEAR, L5EAC:NEAR, L5EC7:NEAR, L5ED7:NEAR, L5FA6:NEAR, L5FC3:NEAR
	EXTRN L5FE0:NEAR, L6999:NEAR, L72A0:NEAR
	PUBLIC L2B65, L2B8F, L2F6F, L310B, L334D, L3389
	PUBLIC L35C1, L363B, L3782, L3794, L37DC, L37F1
	PUBLIC L38B0
ASSUME CS:CODE, DS:DATA
;------------------------------------------------------------------------------
; L2B65: plot one dot of a map cell in the overview map drawn by L29D2 (DUNGEON):
; each of the 64x64 map cells is 4x2 pixels, D_0019/D_001A are the cell column and
; row there (not a direction). Pixel = (D_0019*4 + DI, D_001A*2 + SI), drawn by L4B76.
; In: DI = dot column 0-3, SI = dot row 0-1. Out: D_0479/D_047A = the pixel.
; Uses: AL, BX, and whatever L4B76 uses.
;------------------------------------------------------------------------------
L2B65:	mov bx, di	;@2B65
	mov byte ptr D_0479, bl	;@2B67
	mov bx, si	;@2B6B
	mov byte ptr D_047A, bl	;@2B6D
	mov al, byte ptr D_0019	;@2B71
	add al, al	;@2B74
	add al, al	;@2B76
	adc al, byte ptr D_0479	; x = column*4 + DI	;@2B78
	mov byte ptr D_0479, al	;@2B7C
	mov al, byte ptr D_001A	;@2B7F
	add al, al	;@2B82
	adc al, byte ptr D_047A	; y = row*2 + SI	;@2B84
	mov byte ptr D_047A, al	;@2B88
	call L4B76	; plot the pixel	;@2B8B
	ret	;@2B8E
;------------------------------------------------------------------------------
; L2B8F: command A, Attack. In a dungeon or tower (D_004A >= 4) see L2E16. Else
; refused while paralyzed (D_026C); asks for a direction (L2362), finds the monster
; there (L23E6) and hits if random/2 < Agility (D_004C). Damage = (ready weapon
; D_0061 * 8 + Strength D_004B) / 4. Monster tile 40h (Minax) teleports when hit and
; ends the game when killed; other kills give gold, Exp and some special loot.
; Leaves by L0A30 / L0A33.
;------------------------------------------------------------------------------
L2B8F:	call L4FDF	;@2B8F
	db 41h,54h,54h,41h,43h,4Bh,2Dh,2Dh,0h	;@2B92
	mov al, byte ptr D_004A	;@2B9B
	cmp al, 4	; dungeon or tower?	;@2B9E
	jb L2BA5	;@2BA0
	jmp L2E16	;@2BA2
L2BA5:	nop	;@2BA5
	mov al, byte ptr D_026C	; paralyzed?	;@2BA6
	or al, al	;@2BA9
	je L2BBE	;@2BAB
	call L4FDF	;@2BAD
	db 50h,41h,52h,41h,4Ch,49h,5Ah,45h,44h,21h,0h	;@2BB0
	jmp L0A30	;@2BBB
L2BBE:	call L2362	; read a direction into D_0019/D_001A	;@2BBE
	call L5FE0	; swing sound	;@2BC1
	call L23E6	; DI = monster at player+direction, 0 = none	;@2BC4
	mov bx, di	;@2BC7
	mov byte ptr D_0020, bl	;@2BC9
	mov bx, di	;@2BCD
	cmp bl, 0	;@2BCF
	jne L2BD7	;@2BD2
	jmp L2E09	;@2BD4
L2BD7:	call L5217	;@2BD7
	clc	;@2BDA
	rcr al, 1	; random 0-7Fh ...	;@2BDB
	cmp al, byte ptr D_004C	; ... below Agility = hit	;@2BDD
	jb L2BE6	;@2BE1
	jmp L2E09	;@2BE3
L2BE6:	call L523E	; draw the hit marker (XOR)	;@2BE6
	call L113A	; not outdoors: D_01D7 = 1 for monsters 0-7 + target	;@2BE9
	call L4FDF	;@2BEC
	db 2Dh,2Dh,48h,49h,54h,21h,21h,21h,0h	;@2BEF
	call L5ED7	;@2BF8
; damage D_001F = (weapon*8 + Strength) / 4 (the adc adds the carry out of weapon*4)
	mov al, byte ptr D_0061	;@2BFB
	add al, al	;@2BFE
	add al, al	;@2C00
	add al, al	;@2C02
	adc al, byte ptr D_004B	;@2C04
	clc	;@2C08
	rcr al, 1	;@2C09
	clc	;@2C0B
	rcr al, 1	;@2C0C
	mov byte ptr D_001F, al	;@2C0E
	mov bh, 0	;@2C11
	mov bl, byte ptr D_0020	;@2C13
	mov di, bx	;@2C17
; L2C19: also entered from Fire (L3603). DI = monster, D_001F = damage.
L2C19:	stc	;@2C19
	mov al, byte ptr D_0177[di]	;@2C1A
	cmc	;@2C1E
	sbb al, byte ptr D_001F	; HP - damage (SEC/SBC)	;@2C1F
	cmc	;@2C23
	jae L2CA4	; borrow: killed	;@2C24
	mov byte ptr D_0177[di], al	;@2C26
	call L523E	; erase the hit marker	;@2C2A
	mov al, byte ptr D_0197[di]	;@2C2D
	cmp al, 40h	; Minax?	;@2C31
	je L2C38	;@2C33
	jmp L0A33	;@2C35
; Minax survives the hit: flash the screen, then move her to the mirror position
; (X,Y) -> (Y,X), restoring the tile under her at the old place.
L2C38:	call L4B26	; invert the screen	;@2C38
	call L5FA6	;@2C3B
	call L4B26	; and back	;@2C3E
	mov bh, 0	;@2C41
	mov bl, byte ptr D_0020	;@2C43
	mov di, bx	;@2C47
	mov al, byte ptr D_0137[di]	;@2C49
	mov byte ptr D_0023, al	;@2C4D
	mov al, byte ptr D_0157[di]	;@2C50
	mov byte ptr D_0024, al	;@2C54
	call L50B3	; D_0006 -> map byte at (D_0023,D_0024), SI = 0	;@2C57
	mov al, byte ptr D_01B7[di]	;@2C5A
	mov bx, word ptr D_0006	;@2C5E
	mov byte ptr [bx+si], al	; put back the tile under her	;@2C62
	mov al, byte ptr D_0023	;@2C64
	mov byte ptr D_0157[di], al	; new Y = old X	;@2C67
	mov al, byte ptr D_0024	;@2C6B
	mov byte ptr D_0137[di], al	; new X = old Y	;@2C6E
	mov byte ptr D_0023, al	;@2C72
	mov al, byte ptr D_0157[di]	;@2C75
	mov byte ptr D_0024, al	;@2C79
	call L50B3	;@2C7C
	mov al, byte ptr D_0197[di]	;@2C7F
	mov bx, word ptr D_0006	;@2C83
	mov byte ptr [bx+si], al	; her tile at the new place (D_01B7 not updated)	;@2C87
	mov al, 84h	;@2C89
	mov byte ptr D_01D7[di], al	; flags = 84h ?	;@2C8B
	call L4FDF	;@2C8F
	db 8Dh,53h,48h,45h,27h,53h,20h,47h,4Fh,4Eh,45h,21h,21h,21h,0h	;@2C92
	jmp L0A33	;@2CA1
; Monster killed (outdoors / in a town): put back the tile under it, then special loot
; by its tile: 40h Minax, 60h, FCh, F0h, F8h (which monsters these are is not known).
L2CA4:	mov al, byte ptr D_0137[di]	;@2CA4
	mov byte ptr D_0023, al	;@2CA8
	mov al, byte ptr D_0157[di]	;@2CAB
	mov byte ptr D_0024, al	;@2CAF
	call L50B3	;@2CB2
	mov bh, 0	;@2CB5
	mov bl, 0	;@2CB7
	mov si, bx	;@2CB9
	mov al, byte ptr D_01B7[di]	;@2CBB
	mov bx, word ptr D_0006	;@2CBF
	mov byte ptr [bx+si], al	; restore the tile under the monster	;@2CC3
	mov al, byte ptr D_0197[di]	;@2CC5
	cmp al, 40h	;@2CC9
	jne L2CD3	;@2CCB
	call L72A0	; Minax is dead: the end game	;@2CCD
	jmp L0A33	;@2CD0
L2CD3:	nop	;@2CD3
	cmp al, 60h	;@2CD4
	jne L2CE5	;@2CD6
	clc	;@2CD8
	mov al, byte ptr D_0065	;@2CD9
	adc al, 2	;@2CDC
	daa	; tile 60h: Keys + 2 (BCD)	;@2CDE
	mov byte ptr D_0065, al	;@2CDF
	jmp L2D8C	;@2CE2
L2CE5:	cmp al, 0FCh	;@2CE5
	jne L2D22	;@2CE7
	mov bx, di	;@2CE9
	mov byte ptr D_001F, bl	;@2CEB
	call L5217	;@2CEF
	cmp al, 40h	;@2CF2
	jae L2D00	;@2CF4
	clc	;@2CF6
	mov al, byte ptr D_0066	;@2CF7
	adc al, 1	;@2CFA
	daa	; tile FCh: 1 in 4, Tools + 1	;@2CFC
	mov byte ptr D_0066, al	;@2CFD
L2D00:	call L5217	;@2D00
	and al, 0Fh	;@2D03
	je L2D17	;@2D05
	mov ah, 0	;@2D07
	mov di, ax	;@2D09
	clc	;@2D0B
	mov al, byte ptr D_00D6[di]	;@2D0C
	adc al, 1	;@2D10
	daa	; and a random item 1-15 (15/16)	;@2D12
	mov byte ptr D_00D6[di], al	;@2D13
L2D17:	mov bh, 0	;@2D17
	mov bl, byte ptr D_001F	;@2D19
	mov di, bx	;@2D1D
	jmp L2D8C	;@2D1F
L2D22:	cmp al, 0F0h	;@2D22
	jne L2D60	;@2D24
	mov bx, di	;@2D26
	mov byte ptr D_001F, bl	;@2D28
	call L5217	;@2D2C
	cmp al, 40h	;@2D2F
	jae L2D3D	;@2D31
	clc	;@2D33
	mov al, byte ptr D_00DB	;@2D34
	adc al, 1	;@2D37
	daa	; tile F0h: 1 in 4, a helm	;@2D39
	mov byte ptr D_00DB, al	;@2D3A
L2D3D:	mov bh, 0	;@2D3D
	mov bl, byte ptr D_001F	;@2D3F
	mov di, bx	;@2D43
	call L5217	;@2D45
	and al, 3	;@2D48
	adc al, 1	;@2D4A
	clc	;@2D4C
	adc al, byte ptr D_0064	;@2D4D
	daa	; and 1-4 torches	;@2D51
	mov byte ptr D_0064, al	;@2D52
	mov bh, 0	;@2D55
	mov bl, byte ptr D_001F	;@2D57
	mov di, bx	;@2D5B
	jmp L2D8C	;@2D5D
L2D60:	cmp al, 0F8h	;@2D60
	jne L2D8B	;@2D62
	mov bx, di	;@2D64
	mov byte ptr D_001F, bl	;@2D66
	call L5217	;@2D6A
	and al, 1	;@2D6D
	mov ah, 0	;@2D6F
	mov di, ax	;@2D71
	inc di	;@2D73
	clc	;@2D74
	mov al, byte ptr D_00D6[di]	;@2D75
	adc al, 1	;@2D79
	daa	; tile F8h: a wand or a staff (item 1 or 2)	;@2D7B
	mov byte ptr D_00D6[di], al	;@2D7C
	mov bh, 0	;@2D80
	mov bl, byte ptr D_001F	;@2D82
	mov di, bx	;@2D86
	jmp L2D8C	;@2D88
L2D8B:	nop	;@2D8B
; clear the monster's record, then Gold + 1-17 (BCD, odd) and Exp + 1-4
L2D8C:	mov al, 0	;@2D8C
	mov byte ptr D_01B7[di], al	;@2D8E
	mov byte ptr D_0177[di], al	;@2D92
	mov byte ptr D_0137[di], al	;@2D96
	mov byte ptr D_0157[di], al	;@2D9A
	mov byte ptr D_0197[di], al	;@2D9E
	call L4FDF	;@2DA2
	db 0Dh,4Bh,49h,4Ch,4Ch,45h,44h,2Dh,2Dh,47h,4Fh,4Ch,44h,2Bh,0h	;@2DA5
	call L5217	;@2DB4
	and al, 17h	;@2DB7
	or al, 1	;@2DB9
	mov byte ptr D_001F, al	;@2DBB
	call L53B5	; print it as 2 BCD digits	;@2DBE
	clc	;@2DC1
	mov al, byte ptr D_0059	;@2DC2
	adc al, byte ptr D_001F	;@2DC5
	daa	;@2DC9
	mov byte ptr D_0059, al	;@2DCA
	mov al, byte ptr D_0058	;@2DCD
	adc al, 0	;@2DD0
	daa	;@2DD2
	mov byte ptr D_0058, al	;@2DD3
	call L4FDF	;@2DD6
	db 2Dh,2Dh,45h,58h,50h,2Eh,2Bh,0h	;@2DD9
	call L5217	;@2DE1
	and al, 3	;@2DE4
	adc al, 1	;@2DE6
	mov byte ptr D_001F, al	;@2DE8
	call L53B5	;@2DEB
	clc	;@2DEE
	mov al, byte ptr D_0057	;@2DEF
	adc al, byte ptr D_001F	;@2DF2
	daa	;@2DF6
	mov byte ptr D_0057, al	;@2DF7
	mov al, byte ptr D_0056	;@2DFA
	adc al, 0	;@2DFD
	daa	;@2DFF
	mov byte ptr D_0056, al	;@2E00
	call L523E	; erase the hit marker	;@2E03
	jmp L0A33	;@2E06
; L2E09: also used by Fire (L35F3).
L2E09:	call L4FDF	;@2E09
	db 2Dh,2Dh,4Dh,49h,53h,53h,0h	;@2E0C
	jmp L0A33	;@2E13
;------------------------------------------------------------------------------
; L2E16: Attack in a dungeon or tower: the square in front of the player (position +
; facing D_0002/D_0003) on level D_0025. The low 3 bits of the dungeon cell say a
; monster is there; it is looked up in the monster table (X, Y and level in D_01B7).
; Hit roll and damage as outdoors. L2ED1 (killed) is also used by the Cast spells.
;------------------------------------------------------------------------------
L2E16:	nop	;@2E16
	call L5FE0	;@2E17
	mov al, byte ptr D_0000	;@2E1A
	clc	;@2E1D
	adc al, byte ptr D_0002	;@2E1E
	mov byte ptr D_0023, al	;@2E22
	mov al, byte ptr D_0001	;@2E25
	clc	;@2E28
	adc al, byte ptr D_0003	;@2E29
	mov byte ptr D_0024, al	;@2E2D
	mov al, byte ptr D_0025	;@2E30
	call L1451	; AL = dungeon cell at (D_0023,D_0024), level AL	;@2E33
	and al, 7	; monster bits	;@2E36
	jne L2E3D	;@2E38
	jmp L2F64	;@2E3A
L2E3D:	mov bh, 0	;@2E3D
	mov bl, 1Fh	;@2E3F
	mov di, bx	;@2E41
	mov bx, di	;@2E43
	mov byte ptr D_001F, bl	; search monsters 1Fh down	;@2E45
L2E49:	mov al, byte ptr D_0137[di]	;@2E49
	cmp al, byte ptr D_0023	;@2E4D
	jne L2E6A	;@2E51
	mov al, byte ptr D_0157[di]	;@2E53
	cmp al, byte ptr D_0024	;@2E57
	jne L2E6A	;@2E5B
	mov al, byte ptr D_01B7[di]	;@2E5D
	cmp al, byte ptr D_0025	;@2E61
	jne L2E6A	;@2E65
	jmp L2E7D	;@2E67
; Probably a porting bug: the loop tests AL (the field that did not match), not the
; index, so it stops at the first mismatching zero byte and could run below index 0.
; (6502: DEC/LDX/BNE, where LDX sets the flags.) It also does not check D_0197.
L2E6A:	dec byte ptr D_001F	;@2E6A
	mov bh, 0	;@2E6E
	mov bl, byte ptr D_001F	;@2E70
	mov di, bx	;@2E74
	or al, al	;@2E76
	jne L2E49	;@2E78
	jmp L2F64	;@2E7A
L2E7D:	nop	;@2E7D
	call L5217	;@2E7E
	clc	;@2E81
	rcr al, 1	;@2E82
	cmp al, byte ptr D_004C	; hit if random/2 < Agility	;@2E84
	jb L2E8D	;@2E88
	jmp L2F64	;@2E8A
L2E8D:	nop	;@2E8D
	call L4FDF	;@2E8E
	db 48h,49h,54h,21h,0h	;@2E91
	call L523E	;@2E96
	call L5ED7	;@2E99
	call L523E	;@2E9C
; damage D_0020 = (weapon*8 + Strength) / 4, as outdoors
	mov al, byte ptr D_0061	;@2E9F
	add al, al	;@2EA2
	add al, al	;@2EA4
	add al, al	;@2EA6
	adc al, byte ptr D_004B	;@2EA8
	clc	;@2EAC
	rcr al, 1	;@2EAD
	clc	;@2EAF
	rcr al, 1	;@2EB0
	mov bh, 0	;@2EB2
	mov bl, byte ptr D_001F	;@2EB4
	mov di, bx	;@2EB8
	mov byte ptr D_0020, al	;@2EBA
	mov al, byte ptr D_0177[di]	;@2EBD
	stc	;@2EC1
	cmc	;@2EC2
	sbb al, byte ptr D_0020	; HP - damage (SEC/SBC)	;@2EC3
	cmc	;@2EC7
	jae L2ED1	;@2EC8
	mov byte ptr D_0177[di], al	;@2ECA
	jmp L0A33	;@2ECE
; L2ED1: dungeon monster DI killed (also from Cast: Prayer, Magic missile, Kill).
; Clears HP, tile and level (not X/Y), the monster bits of its cell, then gives
; Gold + 1-17 (BCD, odd) and Exp + 0-7.
L2ED1:	nop	;@2ED1
	mov al, 0	;@2ED2
	mov byte ptr D_0177[di], al	;@2ED4
	mov byte ptr D_0197[di], al	;@2ED8
	mov byte ptr D_01B7[di], al	;@2EDC
	mov al, byte ptr D_0137[di]	;@2EE0
	mov byte ptr D_0023, al	;@2EE4
	mov al, byte ptr D_0157[di]	;@2EE7
	mov byte ptr D_0024, al	;@2EEB
	mov al, byte ptr D_0025	;@2EEE
	call L1451	; D_0008 -> its cell, SI = 0	;@2EF1
	mov bx, word ptr D_0008	;@2EF4
	mov al, byte ptr [bx+si]	;@2EF8
	and al, 0F0h	; clear the monster bits	;@2EFA
	mov bx, word ptr D_0008	;@2EFC
	mov byte ptr [bx+si], al	;@2F00
	call L4FDF	;@2F02
	db 8Dh,4Bh,49h,4Ch,4Ch,45h,44h,2Dh,2Dh,47h,4Fh,4Ch,44h,2Bh,0h	;@2F05
	call L5217	;@2F14
	and al, 17h	;@2F17
	or al, 1	;@2F19
	mov byte ptr D_0020, al	;@2F1B
	call L53B5	; print it as 2 BCD digits	;@2F1E
	clc	;@2F21
	mov al, byte ptr D_0059	;@2F22
	adc al, byte ptr D_0020	;@2F25
	daa	;@2F29
	mov byte ptr D_0059, al	;@2F2A
	mov al, byte ptr D_0058	;@2F2D
	adc al, 0	;@2F30
	daa	;@2F32
	mov byte ptr D_0058, al	;@2F33
	call L4FDF	;@2F36
	db 2Dh,2Dh,45h,58h,50h,2Eh,2Bh,0h	;@2F39
	call L5217	;@2F41
	and al, 7	;@2F44
	mov byte ptr D_0020, al	;@2F46
	call L53B5	;@2F49
	clc	;@2F4C
	mov al, byte ptr D_0057	;@2F4D
	adc al, byte ptr D_0020	;@2F50
	daa	;@2F54
	mov byte ptr D_0057, al	;@2F55
	mov al, byte ptr D_0056	;@2F58
	adc al, 0	;@2F5B
	daa	;@2F5D
	mov byte ptr D_0056, al	;@2F5E
	jmp L0A33	;@2F61
L2F64:	call L4FDF	;@2F64
	db 4Dh,49h,53h,53h,0h	;@2F67
	jmp L0A33	;@2F6C
;------------------------------------------------------------------------------
; L2F6F: command B, Board. Not in a dungeon or tower, and only on foot (player
; tile D_0013 >= 78h), else "THINK AGAIN <name>". The tile underfoot D_0014 says
; what: 22h horse, 24h frigate (needs a blue tassle, D_00E2), 26h plane (needs a
; skull key, D_00DF), 28h rocket (needs an ankh, D_00DD). The vehicle is taken off
; the map (map byte 8 = grass, or 0 = water for the frigate) and becomes the player
; tile D_0013. Leaves by L0A30 / L0A33.
;------------------------------------------------------------------------------
L2F6F:	call L4FDF	;@2F6F
	db 42h,4Fh,41h,52h,44h,0h	;@2F72
	mov al, byte ptr D_004A	;@2F78
	cmp al, 4	;@2F7B
	jb L2F96	;@2F7D
L2F7F:	call L4FDF	;@2F7F
	db 8Dh,54h,48h,49h,4Eh,4Bh,20h,41h,47h,41h,49h,4Eh,20h,0h	;@2F82
	call L507A	; print the player's name	;@2F90
	jmp L0A30	;@2F93
L2F96:	nop	;@2F96
	mov al, byte ptr D_0013	;@2F97
	cmp al, 78h	; 78h and up = on foot	;@2F9A
	jb L2F7F	;@2F9C
	mov al, byte ptr D_0000	;@2F9E
	mov byte ptr D_0023, al	;@2FA1
	mov al, byte ptr D_0001	;@2FA4
	mov byte ptr D_0024, al	;@2FA7
	call L50B3	; D_0006 -> map byte under the player	;@2FAA
	mov al, byte ptr D_0014	;@2FAD
	cmp al, 22h	; horse	;@2FB0
	je L2FD6	;@2FB2
	cmp al, 24h	; frigate	;@2FB4
	je L2FCD	;@2FB6
	cmp al, 26h	; plane	;@2FB8
	je L2FD0	;@2FBA
	cmp al, 28h	; rocket	;@2FBC
	je L2FD3	;@2FBE
	call L4FDF	;@2FC0
	db 20h,57h,48h,41h,54h,3Fh,0h	;@2FC3
	jmp L0A30	;@2FCA
L2FCD:	jmp L2FF6	;@2FCD
L2FD0:	jmp L3059	;@2FD0
L2FD3:	jmp L30A9	;@2FD3
L2FD6:	call L4FDF	;@2FD6
	db 20h,48h,4Fh,52h,53h,45h,0h	;@2FD9
	mov al, 8	;@2FE0
	mov bh, 0	;@2FE2
	mov bl, 0	;@2FE4
	mov di, bx	;@2FE6
	mov bx, word ptr D_0006[di]	;@2FE8
	mov byte ptr [bx], al	; grass where the horse stood	;@2FEC
	mov al, 22h	;@2FEE
	mov byte ptr D_0013, al	;@2FF0
	jmp L0A33	;@2FF3
L2FF6:	nop	;@2FF6
	mov al, byte ptr D_00E2	; blue tassles	;@2FF7
	or al, al	;@2FFA
	jne L3038	;@2FFC
	call L4FDF	;@2FFE
	db 20h,53h,48h,49h,50h,8Dh,54h,48h,45h,20h,43h,52h,45h,57h,20h,4Fh	;@3001
	db 46h,20h,54h,48h,49h,53h,20h,53h,48h,49h,50h,8Dh,57h,49h,4Ch,4Ch	;@3011
	db 20h,4Eh,4Fh,54h,20h,4Ch,45h,54h,20h,59h,4Fh,55h,20h,42h,4Fh,41h	;@3021
	db 52h,44h,21h,0h	;@3031
	jmp L0A30	;@3035
L3038:	nop	;@3038
	call L4FDF	;@3039
	db 20h,46h,52h,49h,47h,41h,54h,45h,0h	;@303C
	mov al, 0	;@3045
	mov ah, 0	;@3047
	mov si, ax	;@3049
	mov bx, word ptr D_0006	;@304B
	mov byte ptr [bx+si], al	; water where the frigate was	;@304F
	mov al, 24h	;@3051
	mov byte ptr D_0013, al	;@3053
	jmp L0A33	;@3056
L3059:	nop	;@3059
	mov al, byte ptr D_00DF	; skull keys	;@305A
	or al, al	;@305D
	jne L3088	;@305F
	call L4FDF	;@3061
	db 20h,50h,4Ch,41h,4Eh,45h,8Dh,53h,54h,52h,41h,4Eh,47h,45h,20h,59h	;@3064
	db 4Fh,55h,20h,43h,41h,4Eh,27h,54h,20h,47h,45h,54h,20h,49h,4Eh,21h	;@3074
	db 0h	;@3084
	jmp L0A30	;@3085
L3088:	nop	;@3088
	call L4FDF	;@3089
	db 20h,50h,4Ch,41h,4Eh,45h,0h	;@308C
	mov al, 8	;@3093
	mov bh, 0	;@3095
	mov bl, 0	;@3097
	mov si, bx	;@3099
	mov bx, word ptr D_0006	;@309B
	mov byte ptr [bx+si], al	;@309F
	mov al, 26h	;@30A1
	mov byte ptr D_0013, al	;@30A3
	jmp L0A33	;@30A6
L30A9:	nop	;@30A9
	call L4FDF	;@30AA
	db 20h,52h,4Fh,43h,4Bh,45h,54h,0h	;@30AD
	mov al, byte ptr D_00DD	; ankhs	;@30B5
	or al, al	;@30B8
	jne L30F4	;@30BA
	call L4FDF	;@30BC
	db 8Dh,41h,20h,4Dh,45h,54h,41h,4Ch,49h,43h,20h,56h,4Fh,49h,43h,45h	;@30BF
	db 20h,43h,4Fh,4Dh,4Dh,41h,4Eh,44h,53h,3Ah,8Dh,59h,4Fh,55h,20h,4Dh	;@30CF
	db 55h,53h,54h,20h,48h,41h,56h,45h,20h,41h,4Eh,20h,41h,4Eh,4Bh,48h	;@30DF
	db 21h,0h	;@30EF
	jmp L0A30	;@30F1
L30F4:	nop	;@30F4
	mov al, 8	;@30F5
	mov bh, 0	;@30F7
	mov bl, 0	;@30F9
	mov si, bx	;@30FB
	mov bx, word ptr D_0006	;@30FD
	mov byte ptr [bx+si], al	;@3101
	mov al, 28h	;@3103
	mov byte ptr D_0013, al	;@3105
	jmp L0A33	;@3108
;------------------------------------------------------------------------------
; L310B: command C, Cast the ready spell D_0063 (0 none, 1 Light, 2 Down ladder,
; 3 Up ladder, 4 Passwall, 5 Surface, 6 Prayer, 7 Magic missile, 8 Blink, 9 Kill;
; names: string D_0063+24h of the L4C60 table). Needs a wand or a staff (D_00D7 +
; D_00D8) and a count of that spell (D_00B6[spell], used up even when the spell
; then fails). Spells only work in a dungeon or tower (D_004A >= 4).
; Leaves by L0A33 (failures play the L5E83 sound instead of the L0A30 beep).
;------------------------------------------------------------------------------
L310B:	call L4FDF	;@310B
	db 43h,41h,53h,54h,2Dh,0h	;@310E
	jmp L3153	;@3114
; Dead code (3117-3152, nothing reaches it): a developer screen dump, once part of Cast.
; Disassembled: mov ax,B800h / call 3139 / mov ax,BA00h / call 3139 / mov ah,28h /
; mov cx,4000h / mov dx,0 / call L52CA "PICXXX  " / jmp L0A33. L52CA puts the DTA in
; the CGA screen for names starting "PI", so this writes the 16 KB screen to PICXXX.
; 3139: clear offsets 1900h-1F3Fh (the text lines at the bottom) of the bank in AX.
	db 0B8h,0h,0B8h,0E8h,1Ch,0h,0B8h,0h,0BAh,0E8h,16h,0h,0B4h,28h,0B9h,0h	;@3117
	db 40h,0BAh,0h,0h,0E8h,9Ch,21h,50h,49h,43h,58h,58h,58h,20h,20h,0E9h	;@3127
	db 0FAh,0D8h,90h,53h,6h,8Eh,0C0h,0B8h,0h,0h,0BBh,0h,19h,26h,89h,7h	;@3137
	db 83h,0C3h,2h,81h,0FBh,40h,1Fh,75h,0F4h,7h,5Bh,0C3h	;@3147
L3153:	nop	;@3153
	mov al, byte ptr D_0063	;@3154
	clc	;@3157
	adc al, 24h	;@3158
	call L508C	; print the spell's name	;@315A
	mov al, byte ptr D_00D7	; wands ...	;@315D
	clc	;@3160
	adc al, byte ptr D_00D8	; ... + staffs	;@3161
	jne L3185	;@3165
	call L4FDF	;@3167
	db 8Dh,4Eh,45h,45h,44h,20h,57h,41h,4Eh,44h,20h,4Fh,52h,20h,53h,54h	;@316A
	db 41h,46h,46h,21h,0h	;@317A
	call L5E83	;@317F
	jmp L0A33	;@3182
L3185:	nop	;@3185
	mov al, byte ptr D_0063	;@3186
	or al, al	;@3189
	jne L3190	;@318B
	jmp L0A33	;@318D
L3190:	mov ah, 0	;@3190
	mov di, ax	;@3192
	mov al, byte ptr D_00B6[di]	; how many of this spell	;@3194
	or al, al	;@3198
	jne L31B0	;@319A
	call L4FDF	;@319C
	db 8Dh,4Eh,4Fh,20h,53h,50h,45h,4Ch,4Ch,21h,0h	;@319F
	call L5E83	;@31AA
	jmp L0A33	;@31AD
L31B0:	call L5FC3	; casting sound	;@31B0
	mov bh, 0	;@31B3
	mov bl, byte ptr D_0063	;@31B5
	mov di, bx	;@31B9
	stc	;@31BB
	mov al, byte ptr D_00B6[di]	;@31BC
	cmc	;@31C0
	sbb al, 1	;@31C1
	das	; count - 1 (BCD)	;@31C3
	cmc	;@31C4
	mov byte ptr D_00B6[di], al	;@31C5
	mov al, byte ptr D_004A	;@31C9
	cmp al, 4	;@31CC
	jae L31E2	;@31CE
	call L4FDF	;@31D0
	db 2Dh,46h,41h,49h,4Ch,45h,44h,21h,0h	;@31D3
	call L5E83	;@31DC
	jmp L0A33	;@31DF
L31E2:	nop	;@31E2
	mov al, byte ptr D_0063	;@31E3
	or al, al	;@31E6
	jne L31ED	;@31E8
	jmp L0A33	;@31EA
L31ED:	cmp al, 1	;@31ED
	je L321C	;@31EF
	cmp al, 2	;@31F1
	je L3224	;@31F3
	cmp al, 3	;@31F5
	je L3253	;@31F7
	cmp al, 4	;@31F9
	je L3272	;@31FB
	cmp al, 5	;@31FD
	je L3210	;@31FF
	cmp al, 6	;@3201
	je L3213	;@3203
	cmp al, 7	;@3205
	je L3216	;@3207
	cmp al, 8	;@3209
	jne L3219	;@320B
	jmp L32D2	;@320D
L3210:	jmp L32A2	;@3210
L3213:	jmp L32A5	;@3213
L3216:	jmp L32AD	;@3216
L3219:	jmp L3301	; 9 and up: Kill	;@3219
; Light: the light counter D_0026 = 96h, as a torch does.
L321C:	mov al, 96h	;@321C
	mov byte ptr D_0026, al	;@321E
	jmp L0A33	;@3221
; Down ladder: in a tower one level down (L325A), in a dungeon one level deeper.
L3224:	mov al, byte ptr D_004A	;@3224
	cmp al, 4	;@3227
	je L325A	;@3229
; L322B: to level D_0025+1 (at most 0Fh), if the cell at (D_0023,D_0024) there is
; empty. D_0023/D_0024 are not set here but left over from earlier code (after the
; 3D view: the square behind the player): probably a bug.
L322B:	mov al, byte ptr D_0025	;@322B
	cmp al, 0Fh	;@322E
	jb L3244	;@3230
L3232:	call L4FDF	; the spells' common "-FAILED!" exit	;@3232
	db 2Dh,46h,41h,49h,4Ch,45h,44h,21h,0h	;@3235
	call L5E83	;@323E
	jmp L0A33	;@3241
L3244:	clc	;@3244
	adc al, 1	;@3245
	call L1451	; cell on the level below, Z = empty	;@3247
	jne L3232	;@324A
	inc byte ptr D_0025	;@324C
	jmp L382A	;@3250
; Up ladder: in a tower one level up (L322B), in a dungeon one level up (L325A).
L3253:	mov al, byte ptr D_004A	;@3253
	cmp al, 4	;@3256
	je L322B	;@3258
; L325A: to level D_0025-1 (same leftover D_0023/D_0024); from level 0 to the surface.
L325A:	mov al, byte ptr D_0025	;@325A
	or al, al	;@325D
	je L32A2	;@325F
	stc	;@3261
	cmc	;@3262
	sbb al, 1	; SEC/SBC: level - 1	;@3263
	cmc	;@3265
	call L1451	;@3266
	jne L3232	;@3269
	dec byte ptr D_0025	;@326B
	jmp L382A	;@326F
; Passwall: the cell in front (X and Y must be 1-15) must be a wall (bit 7?); it
; becomes 0 (empty).
L3272:	clc	;@3272
	mov al, byte ptr D_0000	;@3273
	adc al, byte ptr D_0002	;@3276
	and al, 0Fh	;@327A
	je L3232	;@327C
	mov byte ptr D_0023, al	;@327E
	mov al, byte ptr D_0001	;@3281
	adc al, byte ptr D_0003	;@3284
	and al, 0Fh	;@3288
	je L3232	;@328A
	mov byte ptr D_0024, al	;@328C
	mov al, byte ptr D_0025	;@328F
	call L1451	;@3292
	jns L3232	;@3295
	mov al, 0	;@3297
	mov bx, word ptr D_0008	;@3299
	mov byte ptr [bx+si], al	;@329D
	jmp L0A33	;@329F
; Surface: back to the outdoor map.
L32A2:	jmp L3844	;@32A2
; Prayer: a 50% chance of Kill.
L32A5:	call L5217	;@32A5
	js L3232	;@32A8
	jmp L3301	;@32AA
; Magic missile: the monster in front loses Exp-high*2 + 1Eh HP. The SEC of the
; subtract is missing: the carry is left from the adc, so usually 1 more is taken.
L32AD:	call L330C	; DI = monster in front, Z = none	;@32AD
	je L3232	;@32B0
	mov al, byte ptr D_0056	;@32B2
	add al, al	;@32B5
	adc al, 1Eh	;@32B7
	mov byte ptr D_0020, al	;@32B9
	mov al, byte ptr D_0177[di]	;@32BC
	cmc	;@32C0
	sbb al, byte ptr D_0020	;@32C1
	cmc	;@32C5
	mov byte ptr D_0177[di], al	;@32C6
	jb L32CF	; no borrow: it lives	;@32CA
	jmp L2ED1	;@32CC
L32CF:	jmp L0A33	;@32CF
; Blink: a random square (odd X and Y, 1-15) on this level; go there if it is empty.
L32D2:	call L5217	;@32D2
	and al, 0Fh	;@32D5
	or al, 1	;@32D7
	mov byte ptr D_0023, al	;@32D9
	call L5217	;@32DC
	and al, 0Fh	;@32DF
	or al, 1	;@32E1
	mov byte ptr D_0024, al	;@32E3
	mov al, byte ptr D_0025	;@32E6
	call L1451	;@32E9
	je L32F1	;@32EC
	jmp L3232	;@32EE
L32F1:	nop	;@32F1
	mov al, byte ptr D_0023	;@32F2
	mov byte ptr D_0000, al	;@32F5
	mov al, byte ptr D_0024	;@32F8
	mov byte ptr D_0001, al	;@32FB
	jmp L0A33	;@32FE
; Kill: the monster in front dies (L2ED1, with gold and Exp).
L3301:	call L330C	;@3301
	jne L3309	;@3304
	jmp L3232	;@3306
L3309:	jmp L2ED1	;@3309
;------------------------------------------------------------------------------
; L330C: find the live monster (D_0197 <> 0) on level D_0025 at the square in front
; of the player (D_0000+D_0002, D_0001+D_0003). Searches entries 1Fh down to 1.
; Out: found: DI = AX = index, ZF = 0; none: AL = 0, ZF = 1. Uses: AX, BX, DI.
;------------------------------------------------------------------------------
L330C:	mov bh, 0	;@330C
	mov bl, 1Fh	;@330E
	mov di, bx	;@3310
L3312:	mov al, byte ptr D_0197[di]	;@3312
	or al, al	; empty slot?	;@3316
	jne L3322	;@3318
L331A:	dec di	;@331A
	jne L3312	;@331B
	mov al, 0	;@331D
	or al, al	; ZF = 1: none	;@331F
	ret	;@3321
L3322:	mov al, byte ptr D_01B7[di]	;@3322
	cmp al, byte ptr D_0025	; on this level?	;@3326
	jne L331A	;@332A
	mov al, byte ptr D_0000	;@332C
	clc	;@332F
	adc al, byte ptr D_0002	;@3330
	cmp al, byte ptr D_0137[di]	;@3334
	jne L331A	;@3338
	mov al, byte ptr D_0001	;@333A
	clc	;@333D
	adc al, byte ptr D_0003	;@333E
	cmp al, byte ptr D_0157[di]	;@3342
	jne L331A	;@3346
	mov ax, di	; found: AX = DI = index	;@3348
	or al, al	; ZF = 0	;@334A
	ret	;@334C
;------------------------------------------------------------------------------
; L334D: command D, Descend a ladder, in a dungeon (D_004A = 5) or tower (4), when
; the cell underfoot (D_0014) has the down-ladder bit 20h. In a dungeon one level
; deeper (L3381), in a tower one floor down (L3823; from floor 0 to the surface).
;------------------------------------------------------------------------------
L334D:	call L4FDF	;@334D
	db 44h,45h,53h,43h,45h,4Eh,44h,0h	;@3350
	mov al, byte ptr D_004A	;@3358
	cmp al, 5	;@335B
	je L3370	;@335D
	cmp al, 4	;@335F
	je L3370	;@3361
L3363:	call L4FDF	;@3363
	db 2Dh,57h,48h,41h,54h,3Fh,0h	;@3366
	jmp L0A30	;@336D
L3370:	mov al, byte ptr D_0014	;@3370
	and al, 20h	; down ladder here?	;@3373
	je L3363	;@3375
	mov al, byte ptr D_004A	;@3377
	cmp al, 4	;@337A
	jne L3381	;@337C
	jmp L3823	;@337E
; L3381: level D_0025 + 1 (deeper in a dungeon, up in a tower); also from Klimb.
L3381:	nop	;@3381
	inc byte ptr D_0025	;@3382
	jmp L382A	;@3386
;------------------------------------------------------------------------------
; L3389: command E, Enter, outdoors only (D_004A = 0) and on foot (D_0013 >= 78h).
; What is entered follows the tile underfoot D_0014: 0Ah village, 0Ch town,
; 0Eh tower, 10h castle, 12h dungeon, 14h sign. Towns: save the outdoor position
; in D_005A/D_005B, save map, monsters and player (L22FD), load the town's map, monsters
; (L2290) and talk file (L22D5), start at (1Fh,3Eh). Tower and dungeon: level 0 at
; (5,5) facing east. A sign prints a text that depends on the era D_0049.
;------------------------------------------------------------------------------
L3389:	call L4FDF	;@3389
	db 45h,4Eh,54h,45h,52h,0h	;@338C
	mov al, byte ptr D_004A	;@3392
	or al, al	;@3395
	je L33A6	;@3397
	call L4FDF	;@3399
	db 20h,57h,48h,41h,54h,3Fh,0h	;@339C
	jmp L0A33	;@33A3
L33A6:	nop	;@33A6
	mov al, byte ptr D_0013	;@33A7
	cmp al, 78h	;@33AA
	jae L33C3	;@33AC
	call L4FDF	;@33AE
	db 2Dh,4Fh,4Eh,4Ch,59h,20h,4Fh,4Eh,20h,46h,4Fh,4Fh,54h,21h,0h	;@33B1
	jmp L0A30	;@33C0
; tile/2 - 5 = 0 village, 1 town, 2 tower, 3 castle, 4 dungeon, 5 sign (SEC/SBC chain)
L33C3:	nop	;@33C3
	mov al, byte ptr D_0014	;@33C4
	clc	;@33C7
	rcr al, 1	;@33C8
	stc	;@33CA
	cmc	;@33CB
	sbb al, 5	;@33CC
	cmc	;@33CE
	jne L33D4	;@33CF
	jmp L340F	;@33D1
L33D4:	cmc	;@33D4
	sbb al, 1	;@33D5
	cmc	;@33D7
	jne L33DD	;@33D8
	jmp L3447	;@33DA
L33DD:	cmc	;@33DD
	sbb al, 1	;@33DE
	cmc	;@33E0
	jne L33E6	;@33E1
	jmp L347C	;@33E3
L33E6:	cmc	;@33E6
	sbb al, 1	;@33E7
	cmc	;@33E9
	jne L33EF	;@33EA
	jmp L34B5	;@33EC
L33EF:	cmc	;@33EF
	sbb al, 1	;@33F0
	cmc	;@33F2
	jne L33F8	;@33F3
	jmp L34EC	;@33F5
L33F8:	cmc	;@33F8
	sbb al, 1	;@33F9
	cmc	;@33FB
	jne L3401	;@33FC
	jmp L3525	;@33FE
L3401:	nop	;@3401
	call L4FDF	;@3402
	db 20h,57h,48h,41h,54h,3Fh,0h	;@3405
	jmp L0A33	;@340C
L340F:	call L4FDF	;@340F
	db 2Dh,56h,49h,4Ch,4Ch,41h,47h,45h,0h	;@3412
	mov al, byte ptr D_0000	;@341B
	mov byte ptr D_005A, al	; remember the outdoor position	;@341E
	mov al, byte ptr D_0001	;@3421
	mov byte ptr D_005B, al	;@3424
	call L22FD	; save map, monsters, player	;@3427
	mov al, 1Fh	;@342A
	mov byte ptr D_0000, al	; start at the bottom middle	;@342C
	mov al, 3Eh	;@342F
	mov byte ptr D_0001, al	;@3431
	mov al, 1	;@3434
	mov byte ptr D_004A, al	; 1 = village	;@3436
	call L2290	; load MAPXe1 and MONXe1 (e = era digit)	;@3439
	call L22D5	; load the talk file TLKXe1	;@343C
	mov al, 4	;@343F
	mov byte ptr D_0012, al	; tile shown beyond the map edge	;@3441
	jmp L0A33	;@3444
L3447:	call L4FDF	;@3447
	db 2Dh,54h,4Fh,57h,4Eh,0h	;@344A
	mov al, byte ptr D_0000	;@3450
	mov byte ptr D_005A, al	;@3453
	mov al, byte ptr D_0001	;@3456
	mov byte ptr D_005B, al	;@3459
	call L22FD	;@345C
	mov al, 1Fh	;@345F
	mov byte ptr D_0000, al	;@3461
	mov al, 3Eh	;@3464
	mov byte ptr D_0001, al	;@3466
	mov al, 2	;@3469
	mov byte ptr D_004A, al	;@346B
	call L2290	;@346E
	call L22D5	;@3471
	mov al, 4	;@3474
	mov byte ptr D_0012, al	;@3476
	jmp L0A33	;@3479
L347C:	call L4FDF	;@347C
	db 2Dh,54h,4Fh,57h,45h,52h,0h	;@347F
	mov al, byte ptr D_0000	;@3486
	mov byte ptr D_005A, al	;@3489
	mov al, byte ptr D_0001	;@348C
	mov byte ptr D_005B, al	;@348F
	call L22FD	;@3492
	mov al, 0	;@3495
	mov byte ptr D_0025, al	; level 0	;@3497
	mov byte ptr D_0003, al	;@349A
	mov al, 1	;@349D
	mov byte ptr D_0002, al	; facing (1,0) = east	;@349F
	mov al, 5	;@34A2
	mov byte ptr D_0000, al	; at (5,5)	;@34A4
	mov byte ptr D_0001, al	;@34A7
	mov al, 4	;@34AA
	mov byte ptr D_004A, al	; 4 = tower	;@34AC
	call L2290	;@34AF
	jmp L0A33	;@34B2
L34B5:	call L4FDF	;@34B5
	db 2Dh,43h,41h,53h,54h,4Ch,45h,0h	;@34B8
	mov al, byte ptr D_0000	;@34C0
	mov byte ptr D_005A, al	;@34C3
	mov al, byte ptr D_0001	;@34C6
	mov byte ptr D_005B, al	;@34C9
	call L22FD	;@34CC
	mov al, 1Fh	;@34CF
	mov byte ptr D_0000, al	;@34D1
	mov al, 3Eh	;@34D4
	mov byte ptr D_0001, al	;@34D6
	mov al, 3	;@34D9
	mov byte ptr D_004A, al	;@34DB
	call L2290	;@34DE
	call L22D5	;@34E1
	mov al, 4	;@34E4
	mov byte ptr D_0012, al	;@34E6
	jmp L0A33	;@34E9
L34EC:	call L4FDF	;@34EC
	db 2Dh,44h,55h,4Eh,47h,45h,4Fh,4Eh,0h	;@34EF
	mov al, byte ptr D_0000	;@34F8
	mov byte ptr D_005A, al	;@34FB
	mov al, byte ptr D_0001	;@34FE
	mov byte ptr D_005B, al	;@3501
	call L22FD	;@3504
	mov al, 0	;@3507
	mov byte ptr D_0025, al	;@3509
	mov byte ptr D_0003, al	;@350C
	mov al, 1	;@350F
	mov byte ptr D_0002, al	;@3511
	mov al, 5	;@3514
	mov byte ptr D_0000, al	;@3516
	mov byte ptr D_0001, al	;@3519
	mov byte ptr D_004A, al	; still 5: 5 = dungeon	;@351C
	call L2290	;@351F
	jmp L0A33	;@3522
; The sign: era 0 Legends, 1 Pangea (9,000,000 B.C.), 2 B.C. (1423), 3 A.D. (1990),
; 4 and up the Aftermath (2112).
L3525:	call L4FDF	;@3525
	db 2Dh,54h,48h,45h,20h,53h,49h,47h,4Eh,20h,52h,45h,41h,44h,53h,3Ah	;@3528
	db 0Dh,0h	;@3538
	mov bh, 0	;@353A
	mov bl, byte ptr D_0049	; era	;@353C
	mov di, bx	;@3540
	or di, di	;@3542
	je L3565	;@3544
	dec di	;@3546
	je L357A	;@3547
	dec di	;@3549
	je L3595	;@354A
	dec di	;@354C
	je L35AB	;@354D
	call L4FDF	;@354F
	db 41h,4Eh,4Fh,53h,3Ah,20h,32h,31h,31h,32h,20h,41h,2Eh,44h,2Eh,0h	;@3552
	jmp L0A33	;@3562
L3565:	call L4FDF	;@3565
	db 41h,4Eh,4Fh,53h,3Ah,20h,4Ch,45h,47h,45h,4Eh,44h,53h,21h,0h	;@3568
	jmp L0A33	;@3577
L357A:	call L4FDF	;@357A
	db 41h,4Eh,4Fh,53h,3Ah,20h,39h,2Ch,30h,30h,30h,2Ch,30h,30h,30h,20h	;@357D
	db 42h,2Eh,43h,2Eh,0h	;@358D
	jmp L0A33	;@3592
L3595:	call L4FDF	;@3595
	db 41h,4Eh,4Fh,53h,3Ah,20h,31h,34h,32h,33h,20h,42h,2Eh,43h,2Eh,0h	;@3598
	jmp L0A33	;@35A8
L35AB:	call L4FDF	;@35AB
	db 41h,4Eh,4Fh,53h,3Ah,20h,31h,39h,39h,30h,20h,41h,2Eh,44h,2Eh,0h	;@35AE
	jmp L0A33	;@35BE
;------------------------------------------------------------------------------
; L35C1: command F, Fire the cannons, only from a frigate (D_0013 = 24h). Asks for
; a direction; the monster on the adjacent square takes random 20h-FFh damage,
; through the Attack damage code at L2C19 (so Minax's teleport applies too).
;------------------------------------------------------------------------------
L35C1:	call L4FDF	;@35C1
	db 46h,49h,52h,45h,0h	;@35C4
	mov al, byte ptr D_0013	;@35C9
	cmp al, 24h	; on a frigate?	;@35CC
	je L35DD	;@35CE
	call L4FDF	;@35D0
	db 20h,57h,48h,41h,54h,3Fh,0h	;@35D3
	jmp L0A30	;@35DA
L35DD:	nop	;@35DD
	call L4FDF	;@35DE
	db 20h,44h,49h,52h,45h,43h,54h,2Dh,0h	;@35E1
	call L2362	; read a direction	;@35EA
	call L5EAC	; cannon sound	;@35ED
	call L23E6	; DI = monster there, 0 = none	;@35F0
	mov bx, di	;@35F3
	mov byte ptr D_0020, bl	;@35F5
	mov bx, di	;@35F9
	cmp bl, 0	;@35FB
	jne L3603	;@35FE
	jmp L2E09	;@3600
L3603:	call L5217	;@3603
	or al, 20h	;@3606
	mov byte ptr D_001F, al	; damage	;@3608
	call L523E	; draw the hit marker	;@360B
	call L5ED7	;@360E
	mov bh, 0	;@3611
	mov bl, byte ptr D_0020	;@3613
	mov di, bx	;@3617
	jmp L2C19	;@3619
;------------------------------------------------------------------------------
; L361C: outside dungeons and towers (D_004A < 4) replace the map byte under the
; player by 8 (floor / grass): the item taken by Get is gone. In a dungeon or
; tower it does nothing. Out: D_0006, SI = 0. Uses: AL, BX, SI.
;------------------------------------------------------------------------------
L361C:	cmp byte ptr D_004A, 4	;@361C
	jae L363A	;@3621
	mov al, byte ptr D_0000	;@3623
	mov byte ptr D_0023, al	;@3626
	mov al, byte ptr D_0001	;@3629
	mov byte ptr D_0024, al	;@362C
	call L50B3	;@362F
	mov al, 8	;@3632
	mov bx, word ptr D_0006	;@3634
	mov byte ptr [bx+si], al	;@3638
L363A:	ret	;@363A
;------------------------------------------------------------------------------
; L363B: command G, Get. Outdoors / in towns, from the tile underfoot: 2Ah armour
; (random 1-3: cloth, leather, chain; 1 in 4 empty) or 2Ch a weapon (random 1-7:
; dagger to light sword; 1 in 8 empty). In a dungeon or tower: 40h a chest, which
; is removed and holds Tri-lithium on level 0Fh, else gold (3 in 4), else armour
; (odd levels) or a weapon (even levels). Counts are BCD.
;------------------------------------------------------------------------------
L363B:	call L4FDF	;@363B
	db 47h,45h,54h,0h	;@363E
	mov al, byte ptr D_004A	;@3642
	cmp al, 4	;@3645
	jb L364C	;@3647
	jmp L36C3	;@3649
L364C:	nop	;@364C
	mov al, byte ptr D_0014	;@364D
	cmp al, 2Ah	; armour	;@3650
	je L369B	;@3652
	cmp al, 2Ch	; weapon	;@3654
	je L3665	;@3656
	call L4FDF	;@3658
	db 20h,57h,48h,41h,54h,3Fh,0h	;@365B
	jmp L0A33	;@3662
L3665:	call L4FDF	;@3665
	db 20h,57h,45h,41h,50h,4Fh,4Eh,0h	;@3668
	call L361C	; take it off the map	;@3670
	call L5217	;@3673
	and al, 7	;@3676
	je L368D	;@3678
	mov ah, 0	;@367A
	mov di, ax	;@367C
	clc	;@367E
	mov al, byte ptr D_0076[di]	;@367F
	adc al, 1	;@3683
	daa	; weapons[1-7] + 1	;@3685
	mov byte ptr D_0076[di], al	;@3686
	jmp L0A33	;@368A
L368D:	call L4FDF	;@368D
	db 20h,45h,4Dh,50h,54h,59h,21h,0h	;@3690
	jmp L0A33	;@3698
L369B:	call L4FDF	;@369B
	db 20h,41h,52h,4Dh,4Fh,55h,52h,0h	;@369E
	call L361C	;@36A6
	call L5217	;@36A9
	and al, 3	;@36AC
	je L368D	;@36AE
	mov ah, 0	;@36B0
	mov di, ax	;@36B2
	clc	;@36B4
	mov al, byte ptr D_0096[di]	;@36B5
	adc al, 1	;@36B9
	daa	; armours[1-3] + 1	;@36BB
	mov byte ptr D_0096[di], al	;@36BC
	jmp L0A33	;@36C0
L36C3:	nop	;@36C3
	mov al, byte ptr D_0014	;@36C4
	cmp al, 40h	; chest	;@36C7
	je L36D8	;@36C9
	call L4FDF	;@36CB
	db 20h,57h,48h,41h,54h,3Fh,0h	;@36CE
	jmp L0A33	;@36D5
L36D8:	nop	;@36D8
	call L4FDF	;@36D9
	db 20h,43h,48h,45h,53h,54h,21h,8Dh,49h,54h,20h,43h,4Fh,4Eh,54h,41h	;@36DC
	db 49h,4Eh,53h,20h,0h	;@36EC
	mov al, byte ptr D_0000	;@36F1
	mov byte ptr D_0023, al	;@36F4
	mov al, byte ptr D_0001	;@36F7
	mov byte ptr D_0024, al	;@36FA
	mov al, byte ptr D_0025	;@36FD
	call L1451	;@3700
	mov al, 0	;@3703
	mov bx, word ptr D_0008	;@3705
	mov byte ptr [bx+si], al	; the chest is gone	;@3709
	mov al, byte ptr D_0025	;@370B
	cmp al, 0Fh	; deepest level?	;@370E
	je L375A	;@3710
	call L5217	;@3712
	cmp al, 40h	;@3715
	jb L3746	;@3717
	call L4FDF	;@3719
	db 47h,4Fh,4Ch,44h,21h,0h	;@371C
; gold + (random 0-1Fh + 2*level + carry) AND 77h: both digits 0-7, valid BCD
	call L5217	;@3722
	and al, 1Fh	;@3725
	adc al, byte ptr D_0025	;@3727
	adc al, byte ptr D_0025	;@372B
	and al, 77h	;@372F
	clc	;@3731
	adc al, byte ptr D_0059	;@3732
	daa	;@3736
	mov byte ptr D_0059, al	;@3737
	mov al, byte ptr D_0058	;@373A
	adc al, 0	;@373D
	daa	;@373F
	mov byte ptr D_0058, al	;@3740
	jmp L0A33	;@3743
L3746:	mov al, byte ptr D_0025	;@3746
	clc	;@3749
	rcr al, 1	; odd level?	;@374A
	jae L3751	;@374C
	jmp L369B	; armour (L361C does nothing here)	;@374E
L3751:	call L4FDF	;@3751
	db 41h,20h,0h	;@3754
	jmp L3665	; "A" + " WEAPON": printed with two spaces	;@3757
L375A:	call L4FDF	;@375A
	db 54h,52h,49h,2Dh,4Ch,49h,54h,48h,49h,55h,4Dh,21h,0h	;@375D
	clc	;@376A
	mov al, byte ptr D_00E5	;@376B
	adc al, 1	;@376E
	daa	; Tri-lithium + 1	;@3770
	mov byte ptr D_00E5, al	;@3771
	jmp L0A33	;@3774
; 11 unused zero bytes (nothing reaches them)
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h	;@3777
;------------------------------------------------------------------------------
; L3782: command H, Hyperspace: nothing on the ground (in space the 'H' key is read
; by the space flight code in SPACE, hyperwarp).
;------------------------------------------------------------------------------
L3782:	call L4FDF	;@3782
	db 48h,59h,50h,45h,52h,20h,57h,48h,41h,54h,3Fh,0h	;@3785
	jmp L0A33	;@3791
;------------------------------------------------------------------------------
; L3794: command I, Ignite torch: only in a dungeon or tower (elsewhere nothing
; happens). Uses up one torch (D_0064, BCD) and sets the light counter D_0026 = 96h.
;------------------------------------------------------------------------------
L3794:	call L4FDF	;@3794
	db 49h,47h,4Eh,49h,54h,45h,20h,54h,4Fh,52h,43h,48h,0h	;@3797
	mov al, byte ptr D_004A	;@37A4
	cmp al, 4	;@37A7
	jae L37AE	;@37A9
	jmp L0A33	;@37AB
L37AE:	mov al, byte ptr D_0064	; torches	;@37AE
	or al, al	;@37B1
	jne L37C8	;@37B3
	call L4FDF	;@37B5
	db 8Dh,4Eh,4Fh,4Eh,45h,20h,4Fh,57h,4Eh,45h,44h,21h,0h	;@37B8
	jmp L0A30	;@37C5
L37C8:	stc	;@37C8
	mov al, byte ptr D_0064	;@37C9
	cmc	;@37CC
	sbb al, 1	;@37CD
	das	; torches - 1 (BCD)	;@37CF
	cmc	;@37D0
	mov byte ptr D_0064, al	;@37D1
	mov al, 96h	;@37D4
	mov byte ptr D_0026, al	;@37D6
	jmp L0A33	;@37D9
;------------------------------------------------------------------------------
; L37DC: command J, Jump: prints a text, no effect.
;------------------------------------------------------------------------------
L37DC:	call L4FDF	;@37DC
	db 4Ah,55h,4Dh,50h,2Eh,2Eh,2Eh,57h,48h,45h,45h,2Eh,2Eh,2Eh,0h	;@37DF
	jmp L0A33	;@37EE
;------------------------------------------------------------------------------
; L37F1: command K, Klimb a ladder, in a dungeon or tower, when the cell underfoot
; (D_0014) has the up-ladder bit 10h. In a tower one floor up (L3381), in a dungeon
; one level up (L3823; from level 0 back to the surface).
;------------------------------------------------------------------------------
L37F1:	call L4FDF	;@37F1
	db 4Bh,4Ch,49h,4Dh,42h,0h	;@37F4
	mov al, byte ptr D_004A	;@37FA
	cmp al, 5	;@37FD
	je L3812	;@37FF
	cmp al, 4	;@3801
	je L3812	;@3803
L3805:	call L4FDF	;@3805
	db 2Dh,57h,48h,41h,54h,3Fh,0h	;@3808
	jmp L0A33	;@380F
L3812:	mov al, byte ptr D_0014	;@3812
	and al, 10h	; up ladder here?	;@3815
	je L3805	;@3817
	mov al, byte ptr D_004A	;@3819
	cmp al, 4	;@381C
	jne L3823	;@381E
	jmp L3381	;@3820
; L3823: level D_0025 - 1 (also from Descend in a tower); below 0 = the surface.
L3823:	nop	;@3823
	dec byte ptr D_0025	;@3824
	js L3844	;@3828
; L382A: print "TO LEVEL n" (also the end of the ladder spells).
L382A:	call L4FDF	;@382A
	db 8Dh,54h,4Fh,20h,4Ch,45h,56h,45h,4Ch,20h,0h	;@382D
	mov al, byte ptr D_0025	;@3838
	add al, 0	;@383B
	daa	; level 0-15 as BCD 00-15	;@383D
	call L53B5	;@383E
	jmp L0A33	;@3841
;------------------------------------------------------------------------------
; L3844: leave a dungeon or tower for the outdoor map (from Klimb, Descend,
; and the spells Surface and Up / Down ladder). Back to the saved outdoor position
; D_005A/D_005B, invalidate the map view caches D_0272/D_0372 (FFh = redraw all),
; reload the outdoor map and monsters (L2290). Away from Earth (D_006D <> 0) the
; rocket tile 50h is put back at D_006A/D_006B; on Earth the player record D_0036
; is written to the file PLAYER.
;------------------------------------------------------------------------------
L3844:	nop	;@3844
	mov al, byte ptr D_005A	;@3845
	mov byte ptr D_0000, al	;@3848
	mov al, byte ptr D_005B	;@384B
	mov byte ptr D_0001, al	;@384E
	mov bx, 0FEh	;@3851
	mov ax, 0FFFFh	;@3854
L3857:	mov word ptr D_0272[bx], ax	;@3857
	mov word ptr D_0372[bx], ax	;@385B
	sub bx, 2	;@385F
	jns L3857	;@3862
	mov al, 0	;@3864
	mov byte ptr D_004A, al	; 0 = outdoors	;@3866
	call L2290	;@3869
	mov al, byte ptr D_005A	; (again)	;@386C
	mov byte ptr D_0000, al	;@386F
	mov al, byte ptr D_005B	;@3872
	mov byte ptr D_0001, al	;@3875
	mov al, byte ptr D_006D	;@3878
	or al, al	;@387B
	je L3899	;@387D
	mov al, byte ptr D_006A	;@387F
	mov byte ptr D_0023, al	;@3882
	mov al, byte ptr D_006B	;@3885
	mov byte ptr D_0024, al	;@3888
	call L50B3	;@388B
	mov al, 50h	; map byte of the rocket	;@388E
	mov bx, word ptr D_0006	;@3890
	mov byte ptr [bx+si], al	;@3894
	jmp L0A33	;@3896
L3899:	lea dx, D_0036	;@3899
	mov ah, 28h	; DOS random block write	;@389D
	mov cx, 100h	; 256 bytes	;@389F
	call L52CA	;@38A2
	db 50h,4Ch,41h,59h,45h,52h,20h,20h	;@38A5
	jmp L0A33	;@38AD
;------------------------------------------------------------------------------
; L38B0: command L, Launch: the plane (D_0013 = 26h, see L39FA) or the rocket (28h).
; The rocket needs Tri-lithium (D_00E5, not used up here). Launching from the
; outdoor map of Earth (D_006D = 0) parks the rocket's position in D_006A/D_006B
; (D_0069 = 1) and saves (L22FD); then space flight (L6999). Back on a map, the
; landing spot scrolls by until a key is pressed: grass (map byte 8) is a landing,
; anything else a crash (L0C62, the player dies).
;------------------------------------------------------------------------------
L38B0:	mov al, byte ptr D_0013	;@38B0
	cmp al, 26h	; plane	;@38B3
	jne L38BA	;@38B5
	jmp L39FA	;@38B7
L38BA:	nop	;@38BA
	cmp al, 28h	; rocket	;@38BB
	je L38D2	;@38BD
	call L4FDF	;@38BF
	db 4Ch,41h,55h,4Eh,43h,48h,20h,57h,48h,41h,54h,3Fh,0h	;@38C2
	jmp L0A33	;@38CF
L38D2:	call L4FDF	;@38D2
	db 4Ch,41h,55h,4Eh,43h,48h,2Dh,2Dh,52h,4Fh,43h,4Bh,45h,54h,0h	;@38D5
	mov al, byte ptr D_00E5	; Tri-lithium	;@38E4
	or al, al	;@38E7
	jne L3923	;@38E9
	call L4FDF	;@38EB
	db 8Dh,41h,20h,4Dh,45h,54h,41h,4Ch,4Ch,49h,43h,20h,56h,4Fh,49h,43h	;@38EE
	db 45h,20h,53h,41h,59h,53h,3Ah,8Dh,53h,48h,49h,50h,20h,49h,4Eh,43h	;@38FE
	db 41h,50h,41h,42h,4Ch,45h,20h,4Fh,46h,20h,4Ch,41h,55h,4Eh,43h,48h	;@390E
	db 21h,0h	;@391E
	jmp L0A33	;@3920
L3923:	call L4FDF	;@3923
	db 8Dh,50h,52h,45h,50h,41h,52h,45h,20h,46h,4Fh,52h,20h,4Ch,41h,55h	;@3926
	db 4Eh,43h,48h,21h,0h	;@3936
	mov al, byte ptr D_006D	; on Earth ...	;@393B
	or al, al	;@393E
	jne L395D	;@3940
	mov al, byte ptr D_004A	; ... and outdoors?	;@3942
	or al, al	;@3945
	jne L395D	;@3947
	mov al, byte ptr D_0000	;@3949
	mov byte ptr D_006A, al	; remember where the rocket stood	;@394C
	mov al, byte ptr D_0001	;@394F
	mov byte ptr D_006B, al	;@3952
	mov al, 1	;@3955
	mov byte ptr D_0069, al	;@3957
	call L22FD	; save map, monsters, player	;@395A
L395D:	nop	;@395D
	call L6999	; space flight	;@395E
	call L2290	; load the map of where we came down	;@3961
	mov di, 0FFh	;@3964
	mov al, 0FFh	;@3967
L3969:	mov byte ptr D_0272[di], al	; invalidate the view caches	;@3969
	mov byte ptr D_0372[di], al	;@396D
	dec di	;@3971
	jns L3969	;@3972
	mov byte ptr D_0000, 0	;@3974
	mov byte ptr D_0001, 0	;@3979
	mov byte ptr D_0012, al	; FFh: L5AB1 draws the landing view	;@397E
	call L4FDF	;@3981
	db 28h,50h,52h,45h,53h,53h,20h,41h,4Eh,59h,20h,4Bh,45h,59h,29h,0h	;@3984
; Descent: the map scrolls by (Y + 2 each frame, X + 1 every 4 frames, both mod 64)
; until a key is pressed.
L3994:	mov al, byte ptr D_0001	;@3994
	clc	;@3997
	adc al, 2	;@3998
	and al, 3Fh	;@399A
	mov byte ptr D_0001, al	;@399C
	and al, 7	;@399F
	jne L39AE	;@39A1
	mov al, byte ptr D_0000	;@39A3
	clc	;@39A6
	adc al, 1	;@39A7
	and al, 3Fh	;@39A9
	mov byte ptr D_0000, al	;@39AB
L39AE:	call L5AB1	; draw the map view	;@39AE
	mov bx, 1Ch	;@39B1
	call L0711	; delay (CPU speed dependent)	;@39B4
	call L4F4D	; key? AH = FFh	;@39B7
	cmp ah, 0FFh	;@39BA
	jne L3994	;@39BD
	mov al, byte ptr D_0000	;@39BF
	mov byte ptr D_0023, al	;@39C2
	mov al, byte ptr D_0001	;@39C5
	mov byte ptr D_0024, al	;@39C8
	call L50B3	; AL = map byte here	;@39CB
	and al, 7Fh	;@39CE
	cmp al, 8	; grass?	;@39D0
	je L39D7	;@39D2
	jmp L0C62	; crashed: the player dies	;@39D4
L39D7:	mov al, byte ptr D_006D	;@39D7
	or al, al	;@39DA
	jne L39E6	;@39DC
	mov al, 0	;@39DE
	mov byte ptr D_0069, al	; on Earth: no parked rocket	;@39E0
	jmp L0A33	;@39E3
L39E6:	mov al, byte ptr D_0000	;@39E6
	mov byte ptr D_006A, al	; elsewhere: remember the landing spot	;@39E9
	mov al, byte ptr D_0001	;@39EC
	mov byte ptr D_006B, al	;@39EF
	mov al, 1	;@39F2
	mov byte ptr D_0069, al	;@39F4
	jmp L0A33	;@39F7
;------------------------------------------------------------------------------
; L39FA: Launch the plane; needs a brass button (D_00E1). It then flies on its own,
; one square per frame in the direction set by the N/S/E/W keys (D_026E-D_0271),
; over any terrain, while D_054E = FFh; 'L' lands, on grass (map byte 8) only. In a
; town, reaching row or column 0 leaves the town (L243E).
;------------------------------------------------------------------------------
L39FA:	call L4FDF	;@39FA
	db 4Ch,41h,55h,4Eh,43h,48h,2Dh,2Dh,50h,4Ch,41h,4Eh,45h,0h	;@39FD
	mov al, byte ptr D_00E1	; brass buttons	;@3A0B
	or al, al	;@3A0E
	jne L3A45	;@3A10
	call L4FDF	;@3A12
	db 8Dh,46h,55h,4Eh,4Eh,59h,20h,54h,48h,49h,53h,20h,50h,4Ch,41h,4Eh	;@3A15
	db 45h,20h,49h,53h,8Dh,4Dh,49h,53h,53h,49h,4Eh,47h,20h,41h,20h,42h	;@3A25
	db 52h,41h,53h,53h,20h,42h,55h,54h,54h,4Fh,4Eh,21h,0h	;@3A35
	jmp L0A30	;@3A42
L3A45:	nop	;@3A45
	mov al, 0	;@3A46
	mov byte ptr D_0021, al	; heading dx = 0	;@3A48
	mov al, 0FFh	;@3A4B
	mov byte ptr D_0022, al	; heading dy = -1: north	;@3A4D
	call L4FDF	;@3A50
	db 0Dh,43h,4Dh,44h,3Ah,20h,0h	;@3A53
	mov byte ptr D_054E, 0FFh	; flying	;@3A5A
L3A5F:	call L5EC7	; engine sound	;@3A5F
	mov bx, 2	;@3A62
	call L0711	; delay (CPU speed dependent)	;@3A65
	call L4F4D	; key? AH = FFh	;@3A68
	cmp ah, 0FFh	;@3A6B
	jne L3A9B	;@3A6E
	cmp al, byte ptr D_026E	; north key	;@3A70
	jne L3A79	;@3A74
	jmp L3ADB	;@3A76
L3A79:	cmp al, byte ptr D_026F	; south	;@3A79
	jne L3A82	;@3A7D
	jmp L3AF6	;@3A7F
L3A82:	cmp al, byte ptr D_0270	; east	;@3A82
	jne L3A8B	;@3A86
	jmp L3B11	;@3A88
L3A8B:	cmp al, byte ptr D_0271	; west	;@3A8B
	jne L3A94	;@3A8F
	jmp L3B2C	;@3A91
L3A94:	cmp al, 4Ch	; 'L' = land	;@3A94
	jne L3A9B	;@3A96
	jmp L3B47	;@3A98
; one step in the heading, wrapping at 64
L3A9B:	clc	;@3A9B
	mov al, byte ptr D_0000	;@3A9C
	adc al, byte ptr D_0021	;@3A9F
	and al, 3Fh	;@3AA3
	mov byte ptr D_0000, al	;@3AA5
	clc	;@3AA8
	mov al, byte ptr D_0001	;@3AA9
	adc al, byte ptr D_0022	;@3AAC
	and al, 3Fh	;@3AB0
	mov byte ptr D_0001, al	;@3AB2
	mov al, byte ptr D_004A	;@3AB5
	or al, al	; outdoors?	;@3AB8
	je L3AD5	;@3ABA
	mov al, byte ptr D_0000	;@3ABC
	or al, al	;@3ABF
	je L3ACD	;@3AC1
	mov al, byte ptr D_0001	;@3AC3
	or al, al	;@3AC6
	je L3ACD	;@3AC8
	jmp L3AD5	;@3ACA
L3ACD:	mov byte ptr D_054E, 0	;@3ACD
	jmp L243E	; at a town's edge: back to the outdoor map	;@3AD2
L3AD5:	nop	;@3AD5
	call L5AB1	; draw the map view	;@3AD6
	jmp L3A5F	;@3AD9
L3ADB:	mov al, 0	;@3ADB
	mov byte ptr D_0021, al	;@3ADD
	mov al, 0FFh	;@3AE0
	mov byte ptr D_0022, al	;@3AE2
	call L4FDF	;@3AE5
	db 4Eh,4Fh,52h,54h,48h,0Dh,43h,4Dh,44h,3Ah,20h,0h	;@3AE8
	jmp L3A9B	;@3AF4
L3AF6:	mov al, 0	;@3AF6
	mov byte ptr D_0021, al	;@3AF8
	mov al, 1	;@3AFB
	mov byte ptr D_0022, al	;@3AFD
	call L4FDF	;@3B00
	db 53h,4Fh,55h,54h,48h,0Dh,43h,4Dh,44h,3Ah,20h,0h	;@3B03
	jmp L3A9B	;@3B0F
L3B11:	mov al, 1	;@3B11
	mov byte ptr D_0021, al	;@3B13
	mov al, 0	;@3B16
	mov byte ptr D_0022, al	;@3B18
	call L4FDF	;@3B1B
	db 45h,41h,53h,54h,0Dh,43h,4Dh,44h,3Ah,20h,0h	;@3B1E
	jmp L3A9B	;@3B29
L3B2C:	mov al, 0FFh	;@3B2C
	mov byte ptr D_0021, al	;@3B2E
	mov al, 0	;@3B31
	mov byte ptr D_0022, al	;@3B33
	call L4FDF	;@3B36
	db 57h,45h,53h,54h,0Dh,43h,4Dh,44h,3Ah,20h,0h	;@3B39
	jmp L3A9B	;@3B44
; 'L': land if the map byte here is 8 (grass; unlike the rocket, bit 7 not masked)
L3B47:	mov al, byte ptr D_0000	;@3B47
	mov byte ptr D_0023, al	;@3B4A
	mov al, byte ptr D_0001	;@3B4D
	mov byte ptr D_0024, al	;@3B50
	call L50B3	;@3B53
	cmp al, 8	;@3B56
	jne L3B71	;@3B58
	call L4FDF	;@3B5A
	db 4Ch,41h,4Eh,44h,20h,50h,4Ch,41h,4Eh,45h,2Eh,0h	;@3B5D
	mov byte ptr D_054E, 0	; not flying	;@3B69
	jmp L0A33	;@3B6E
L3B71:	nop	; not here: keep flying	;@3B71
	call L4FDF	;@3B72
	db 4Ch,41h,4Eh,44h,2Dh,2Dh,4Eh,4Fh,54h,20h,48h,45h,52h,45h,21h,21h	;@3B75
	db 21h,21h,21h,0Dh,43h,4Dh,44h,3Ah,20h,0h	;@3B85
	jmp L3A9B	;@3B8F
CODE ENDS
END
