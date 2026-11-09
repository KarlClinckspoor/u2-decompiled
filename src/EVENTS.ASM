; EVENTS.ASM: monster attacks and spells, darkness and torches, random events.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 0E70-154E.
;
; The monsters' half of a turn outside MAIN's surface loop, and the special attacks.
;   L0E70, L0EC2, L0F12, L0F48: a surface/town monster's spell on the player (MAIN 0AD3, by
;         monster tile 34h, 38h, F8h, 3Ch): legs paralyzed, arms paralyzed, magic missile, sleep.
;         Boots, cloak and green idol may save.
;   L0F8E Minax's curse (-100 hits) when the player is within 3 squares of her (tile 40h).
;   L0FCD a thief (tile FCh) steals one of the 16 magic items.
;   L1013/L1014/L1015 the town turn (location types 1-3), entered by jmp from MAIN 0A4E: every
;         monster acts by its behaviour byte D_01D7 (still, hostile, following, wandering).
;   L113A make the town guards hostile after an attack or a theft.
;   L115E/L115F the dungeon and tower turn (types 5 and 4): new monsters, their moves and
;         attacks, the torch, the 3D view and food.
;   L1451 read a dungeon map cell (used by CMDAL).
; Data: the monster table (D_0137 x, D_0157 y, D_0177 hit points, D_0197 tile/kind, D_01B7 tile
; under it or, in dungeons, its level; D_01D7 behaviour, D_01F7/D_0217 wander step), hit points
; D_0051/D_0052 and food D_0053-D_0055 (BCD), the paralysis/sleep counters D_026B-D_026D.
; A dungeon or tower is 16 levels of 16x16 cells, one 256-byte page each in the map buffer;
; a cell's high nibble is the feature (80h = wall), its low 3 bits the monster kind (1-7).
; BCD arithmetic uses the 6502 idiom stc/cmc + sbb + das + cmc: CF=1 afterwards = no borrow.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0000:BYTE, D_0001:BYTE, D_0008:BYTE, D_0009:BYTE, D_0019:BYTE, D_001A:BYTE
	EXTRN D_001F:BYTE, D_0020:BYTE, D_0021:BYTE, D_0022:BYTE, D_0023:BYTE, D_0024:BYTE
	EXTRN D_0025:BYTE, D_0026:BYTE, D_004A:BYTE, D_0051:BYTE, D_0052:BYTE, D_0053:BYTE
	EXTRN D_0054:BYTE, D_0055:BYTE, D_0062:BYTE, D_00D6:BYTE, D_00D9:BYTE, D_00DA:BYTE
	EXTRN D_00E4:BYTE, D_0137:BYTE, D_0157:BYTE, D_0177:BYTE, D_0197:BYTE, D_01B7:BYTE
	EXTRN D_01D7:BYTE, D_01F7:BYTE, D_0217:BYTE, D_026B:BYTE, D_026C:BYTE, D_026D:BYTE
	EXTRN D_0472:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L086F:NEAR, L0AA7:NEAR, L0BAF:NEAR, L0C62:NEAR, L2122:NEAR, L2201:NEAR
	EXTRN L4B26:NEAR, L4B4E:NEAR, L4F11:NEAR, L4FDF:NEAR, L50B3:NEAR, L50D8:NEAR
	EXTRN L50EF:NEAR, L50F9:NEAR, L5217:NEAR, L523E:NEAR, L5C95:NEAR, L5EAC:NEAR
	EXTRN L5EF2:NEAR, L5FC3:NEAR, L6000:NEAR
	PUBLIC L0E70, L0EC2, L0F12, L0F48, L0FCD, L1013
	PUBLIC L1014, L1015, L1040, L113A, L115E, L115F
	PUBLIC L1451
ASSUME CS:CODE, DS:DATA

;------------------------------------------------------------------------------
; L0E70: a monster's spell (tile 34h, from MAIN 0ADB): "LEGS PARALYZED!" with a
; screen flash. Magic boots (D_00D9) save 3 times in 4; otherwise the legs stay
; paralyzed for 0-15 turns (D_026B; MOVE 2520 refuses steps, MAIN 0C33 counts
; it down). Uses: AX.
;------------------------------------------------------------------------------
L0E70:	call L4FDF	;@0E70
	db 4Ch,45h,47h,53h,20h,50h,41h,52h,41h,4Ch,49h,5Ah,45h,44h,21h,0Dh	; "LEGS PARALYZED!"	;@0E73
	db 0h	;@0E83
	call L4B26	; invert the screen	;@0E84
	call L5FC3	; spell sound	;@0E87
	call L4B26	; and back	;@0E8A
	cmp byte ptr D_00D9, 0	; boots	;@0E8D
	je L0EB8	;@0E92
	call L5217	; random 0-FFh	;@0E94
	cmp al, 40h	;@0E97
	jb L0EB8	;@0E99
	call L4FDF	;@0E9B
	db 53h,41h,56h,45h,44h,20h,42h,59h,20h,4Dh,41h,47h,49h,43h,41h,4Ch	; "SAVED BY MAGICAL BOOTS!"	;@0E9E
	db 20h,42h,4Fh,4Fh,54h,53h,21h,8Dh,0h	;@0EAE
	ret	;@0EB7
L0EB8:	nop	;@0EB8
	call L5217	;@0EB9
	and al, 0Fh	;@0EBC
	mov byte ptr D_026B, al	; legs paralyzed for 0-15 turns	;@0EBE
	ret	;@0EC1

;------------------------------------------------------------------------------
; L0EC2: a monster's spell (tile 38h): "ARMS PARALYZED!". A magic cloak
; (D_00DA) saves 3 times in 4; otherwise D_026C = 0-15 turns. Uses: AX.
;------------------------------------------------------------------------------
L0EC2:	call L4FDF	;@0EC2
	db 41h,52h,4Dh,53h,20h,50h,41h,52h,41h,4Ch,49h,5Ah,45h,44h,21h,0Dh	; "ARMS PARALYZED!"	;@0EC5
	db 0h	;@0ED5
	call L4B26	; flash	;@0ED6
	call L5FC3	;@0ED9
	call L4B26	;@0EDC
	mov al, byte ptr D_00DA	; cloaks	;@0EDF
	or al, al	;@0EE2
	je L0F09	;@0EE4
	call L5217	;@0EE6
	cmp al, 40h	;@0EE9
	jb L0F09	;@0EEB
	call L4FDF	;@0EED
	db 53h,41h,56h,45h,44h,20h,42h,59h,20h,4Dh,41h,47h,49h,43h,41h,4Ch	; "SAVED BY MAGICAL CLOAK"	;@0EF0
	db 20h,43h,4Ch,4Fh,41h,4Bh,8Dh,0h	;@0F00
	ret	;@0F08
L0F09:	call L5217	;@0F09
	and al, 0Fh	;@0F0C
	mov byte ptr D_026C, al	; arms paralyzed for 0-15 turns	;@0F0E
	ret	;@0F11

;------------------------------------------------------------------------------
; L0F12: a monster's spell (tile F8h): "MAGIC MISSILE!". Adds two attacks and
; two hits to this turn's counts (D_0020/D_0021) and 40h to the damage limit
; D_0022; MAIN 0BAF turns those into hit points lost. Uses: AX.
;------------------------------------------------------------------------------
L0F12:	call L4FDF	;@0F12
	db 4Dh,41h,47h,49h,43h,20h,4Dh,49h,53h,53h,49h,4Ch,45h,21h,0Dh,0h	; "MAGIC MISSILE!"	;@0F15
	call L4B26	; flash	;@0F25
	call L5FC3	;@0F28
	call L4B26	;@0F2B
	inc byte ptr D_0020	; attacks this turn	;@0F2E
	inc byte ptr D_0020	;@0F32
	inc byte ptr D_0021	; hits this turn	;@0F36
	inc byte ptr D_0021	;@0F3A
	clc	;@0F3E
	mov al, byte ptr D_0022	; damage limit	;@0F3F
	adc al, 40h	;@0F42
	mov byte ptr D_0022, al	;@0F44
	ret	;@0F47

;------------------------------------------------------------------------------
; L0F48: a monster's spell (tile 3Ch): "SLEEP SPELL!". The green idol (D_00E4)
; saves 3 times in 4; otherwise the player sleeps 0-15 turns (D_026D; MAIN 08A0
; then lets the turns pass). Uses: AX.
;------------------------------------------------------------------------------
L0F48:	call L4FDF	;@0F48
	db 53h,4Ch,45h,45h,50h,20h,53h,50h,45h,4Ch,4Ch,21h,0Dh,0h	; "SLEEP SPELL!"	;@0F4B
	call L4B26	; flash	;@0F59
	call L5FC3	;@0F5C
	call L4B26	;@0F5F
	mov al, byte ptr D_00E4	; green idols	;@0F62
	or al, al	;@0F65
	je L0F84	;@0F67
	call L5217	;@0F69
	cmp al, 40h	;@0F6C
	jb L0F84	;@0F6E
	call L4FDF	;@0F70
	db 53h,41h,56h,45h,44h,20h,42h,59h,20h,49h,44h,4Fh,4Ch,21h,8Dh,0h	; "SAVED BY IDOL!"	;@0F73
	ret	;@0F83
L0F84:	nop	;@0F84
	call L5217	;@0F85
	and al, 0Fh	;@0F88
	mov byte ptr D_026D, al	; asleep for 0-15 turns	;@0F8A
	ret	;@0F8D

;------------------------------------------------------------------------------
; L0F8E: "MINAX CRIES: DIE FOOL!": a hit mark on the player's square and -100
; hit points; dies (L0C62) below zero. Called by the town loop (L1040) every turn
; while Minax (tile 40h) is within 3 squares. Uses: AX, D_0019/D_001A.
;------------------------------------------------------------------------------
L0F8E:	nop	;@0F8E
	call L4FDF	;@0F8F
	db 4Dh,49h,4Eh,41h,58h,20h,43h,52h,49h,45h,53h,3Ah,20h,44h,49h,45h	; "MINAX CRIES: DIE FOOL!"	;@0F92
	db 20h,46h,4Fh,4Fh,4Ch,21h,8Dh,0h	;@0FA2
	mov al, 0	;@0FAA
	mov byte ptr D_0019, al	; direction 0,0 = the player's own square	;@0FAC
	mov byte ptr D_001A, al	;@0FAF
	call L523E	; hit mark (XOR)	;@0FB2
	call L5EF2	; sound	;@0FB5
	call L523E	; erase it	;@0FB8
	stc	;@0FBB
	mov al, byte ptr D_0051	; hits, high BCD byte: -100	;@0FBC
	cmc	;@0FBF
	sbb al, 1	;@0FC0
	das	;@0FC2
	cmc	;@0FC3
	mov byte ptr D_0051, al	;@0FC4
	jb L0FCC	;@0FC7
	jmp L0C62	; the player is dead	;@0FC9
L0FCC:	ret	;@0FCC

;------------------------------------------------------------------------------
; L0FCD: a thief (tile FCh) is next to the player (MAIN 0B5F): one time in 4 it
; picks one of the 16 magic items (D_00D6 ring ... D_00E5 tri-lithium) at random
; and, if the player has any, takes one: "A THIEF STOLE SOMETHING!".
; Uses: AX, DI.
;------------------------------------------------------------------------------
L0FCD:	nop	;@0FCD
	call L5217	;@0FCE
	cmp al, 40h	;@0FD1
	jb L0FD6	;@0FD3
	ret	;@0FD5
L0FD6:	nop	;@0FD6
	call L5217	;@0FD7
	and ax, 0Fh	; item 0-15	;@0FDA
	mov di, ax	;@0FDD
	mov al, byte ptr D_00D6[di]	; how many (BCD)	;@0FDF
	or al, al	;@0FE3
	je L1012	;@0FE5
	stc	;@0FE7
	mov al, byte ptr D_00D6[di]	;@0FE8
	cmc	;@0FEC
	sbb al, 1	;@0FED
	das	;@0FEF
	cmc	;@0FF0
	mov byte ptr D_00D6[di], al	;@0FF1
	call L4FDF	;@0FF5
	db 41h,20h,54h,48h,49h,45h,46h,20h,53h,54h,4Fh,4Ch,45h,20h,53h,4Fh	; "A THIEF STOLE SOMETHING!"	;@0FF8
	db 4Dh,45h,54h,48h,49h,4Eh,47h,21h,8Dh,0h	;@1008
L1012:	ret	;@1012

;------------------------------------------------------------------------------
; L1013 / L1014 / L1015: the monsters' turn in a village / towne / castle
; (location types 1, 2, 3; jumped to from MAIN 0A4E-0A5C). Three entries into
; the same code. For each monster slot from 31 down to 0 (index in D_0025, as
; the routines it jumps to use DI and D_0029/D_0027) by its behaviour D_01D7:
;   0 or 80h+: stays put;  1: hostile, MAIN's surface code L0AA7 (attack when
;   adjacent, else approach);  2: follows the player (L4F11 + INPUT L2122);
;   3+: wanders (L1086). Every path comes back to L1040.
; At the end jmp L0BAF (MAIN: the attacks of this turn, damage, next turn).
;------------------------------------------------------------------------------
L1013:	nop	;@1013
L1014:	nop	;@1014
L1015:	nop	;@1015
	mov bh, 0	;@1016
	mov bl, 1Fh	;@1018
	mov di, bx	; slot 31	;@101A
L101C:	nop	;@101C
	mov bx, di	;@101D
	mov byte ptr D_0025, bl	; the loop index	;@101F
	mov al, byte ptr D_0197[di]	; tile, 0 = free slot	;@1023
	or al, al	;@1027
	je L1040	;@1029
	mov al, byte ptr D_01D7[di]	; behaviour	;@102B
	or al, al	;@102F
	je L1040	; 0: still	;@1031
	js L1040	; 80h+: still	;@1033
	cmp al, 3	;@1035
	jae L1086	; 3+: wander	;@1037
	cmp al, 2	;@1039
	je L107B	; 2: follow	;@103B
	jmp L1082	; 1: hostile	;@103D

;------------------------------------------------------------------------------
; L1040: next monster of the town loop. Re-entered from MAIN 0BA8 and INPUT
; 2192/226F when a monster has acted (DI = its slot). If this one is Minax
; (tile 40h) within 3 squares in x and y, she curses (L0F8E).
;------------------------------------------------------------------------------
L1040:	mov al, byte ptr D_0197[di]	;@1040
	cmp al, 40h	; Minax	;@1044
	jne L106D	;@1046
	mov al, byte ptr D_0137[di]	;@1048
	stc	;@104C
	cmc	;@104D
	sbb al, byte ptr D_0000	;@104E
	call L50EF	; |dx|	;@1052
	cmp al, 4	;@1055
	jae L106D	;@1057
	mov al, byte ptr D_0157[di]	;@1059
	stc	;@105D
	cmc	;@105E
	sbb al, byte ptr D_0001	;@105F
	call L50EF	; |dy|	;@1063
	cmp al, 4	;@1066
	jae L106D	;@1068
	call L0F8E	; "DIE FOOL!"	;@106A
L106D:	mov bh, 0	;@106D
	mov bl, byte ptr D_0025	;@106F
	mov di, bx	;@1073
	dec di	;@1075
	jns L101C	; down to slot 0 inclusive	;@1076
	jmp L0BAF	; MAIN: show this turn's attacks, damage	;@1078
L107B:	nop	; follow: step toward the player	;@107B
	call L4F11	; D_0019/D_001A = direction to the player	;@107C
	jmp L2122	;@107F
L1082:	nop	; hostile: MAIN's surface monster code	;@1082
	jmp L0AA7	;@1083
; Wander: keep the stored step D_01F7/D_0217, change it one time in 4 to a
; random -1/0/+1 each. The new square must be inside 4-3Bh both ways, must not
; share the player's column or row (this tests x and y separately), and must be
; town floor (70h) or grass (08h).
L1086:	nop	;@1086
	mov bh, 0	;@1087
	mov bl, byte ptr D_0025	;@1089
	mov di, bx	;@108D
	mov al, byte ptr D_01F7[di]	; wander dx	;@108F
	mov byte ptr D_0019, al	;@1093
	mov al, byte ptr D_0217[di]	; wander dy	;@1096
	mov byte ptr D_001A, al	;@109A
	call L5217	;@109D
	cmp al, 40h	;@10A0
	jae L10CE	;@10A2
	call L5217	; new random direction	;@10A4
	call L50D8	; sign: -1, 0 or +1	;@10A7
	mov bh, 0	;@10AA
	mov bl, byte ptr D_0025	;@10AC
	mov di, bx	;@10B0
	mov byte ptr D_01F7[di], al	;@10B2
	mov byte ptr D_0019, al	;@10B6
	call L5217	;@10B9
	call L50D8	;@10BC
	mov bh, 0	;@10BF
	mov bl, byte ptr D_0025	;@10C1
	mov di, bx	;@10C5
	mov byte ptr D_0217[di], al	;@10C7
	mov byte ptr D_001A, al	;@10CB
L10CE:	nop	;@10CE
	mov bh, 0	;@10CF
	mov bl, byte ptr D_0025	;@10D1
	mov di, bx	;@10D5
	clc	;@10D7
	mov al, byte ptr D_0137[di]	;@10D8
	adc al, byte ptr D_0019	;@10DC
	and al, 3Fh	;@10E0
	mov byte ptr D_0023, al	; new x	;@10E2
	cmp al, 4	;@10E5
	jae L10EC	;@10E7
	jmp L1040	;@10E9
L10EC:	cmp al, 3Ch	;@10EC
	jb L10F3	;@10EE
	jmp L1040	;@10F0
L10F3:	cmp al, byte ptr D_0000	; the player's column	;@10F3
	jne L10FC	;@10F7
	jmp L1040	;@10F9
L10FC:	clc	;@10FC
	mov al, byte ptr D_0157[di]	;@10FD
	adc al, byte ptr D_001A	;@1101
	and al, 3Fh	;@1105
	mov byte ptr D_0024, al	; new y	;@1107
	cmp al, 4	;@110A
	jae L1111	;@110C
	jmp L1040	;@110E
L1111:	cmp al, 3Ch	;@1111
	jb L1118	;@1113
	jmp L1040	;@1115
L1118:	cmp al, byte ptr D_0001	; the player's row	;@1118
	jne L1121	;@111C
	jmp L1040	;@111E
L1121:	call L50B3	; AL = map tile there	;@1121
	cmp al, 70h	; town floor	;@1124
	je L112F	;@1126
	cmp al, 8	; grass	;@1128
	je L112F	;@112A
	jmp L1040	;@112C
L112F:	mov bh, 0	;@112F
	mov bl, byte ptr D_0025	;@1131
	mov di, bx	;@1135
	jmp L2201	; INPUT: move it, back to L1040	;@1137

;------------------------------------------------------------------------------
; L113A: in a town (D_004A <> 0), make the guards hostile: behaviour 1 for slots
; 0-7 and for the slot in D_0020 (the monster just attacked or robbed). Called
; by Attack (CMDAL 2BE9) and Steal (CMDMZ 3F91). Uses: AX, BX, DI.
;------------------------------------------------------------------------------
L113A:	mov al, byte ptr D_004A	;@113A
	or al, al	;@113D
	jne L1142	;@113F
	ret	;@1141
L1142:	mov bh, 0	;@1142
	mov bl, 7	;@1144
	mov di, bx	;@1146
	mov al, 1	; hostile	;@1148
L114A:	mov byte ptr D_01D7[di], al	;@114A
	dec di	;@114E
	jns L114A	;@114F
	mov bh, 0	;@1151
	mov bl, byte ptr D_0020	; the victim's slot	;@1153
	mov di, bx	;@1157
	mov byte ptr D_01D7[di], al	;@1159
	ret	;@115D

;------------------------------------------------------------------------------
; L115E / L115F: the monsters' turn in a dungeon / tower (location types 5 and
; 4; jumped to from MAIN 0A63/0A6A). First L147F fills free slots with new
; monsters. Then each live monster in slots 31 down to 1 (index in D_001F)
; steps toward the player (away if its hit points are below 0Fh): x first,
; else y; never onto a wall (80h) or another monster. Only monsters on the
; player's level D_0025 move. A step onto the player is an attack (L1308).
; Then the torch, the 3D view, 0.10 food and the status lines (L1291), and on
; to the next command (L086F). D_01F7/D_0217 serve as scratch for the new x/y.
;------------------------------------------------------------------------------
L115E:	nop	;@115E
L115F:	nop	;@115F
	call L147F	; new monsters	;@1160
	nop	;@1163
	mov bh, 0	;@1164
	mov bl, 1Fh	;@1166
	mov di, bx	;@1168
	mov bx, di	;@116A
	mov byte ptr D_001F, bl	; slot 31	;@116C
L1170:	mov al, byte ptr D_0197[di]	; kind, 0 = free slot	;@1170
	or al, al	;@1174
	jne L118B	;@1176
L1178:	dec byte ptr D_001F	; next slot	;@1178
	mov bh, 0	;@117C
	mov bl, byte ptr D_001F	;@117E
	mov di, bx	;@1182
	or di, di	;@1184
	jne L1170	; slot 0 is not used here	;@1186
	jmp L1291	;@1188
L118B:	nop	;@118B
	mov bh, 0	;@118C
	mov bl, byte ptr D_001F	;@118E
	mov di, bx	;@1192
	call L152E	; D_0019/D_001A = direction to the player	;@1194
	mov al, byte ptr D_0177[di]	; monster hit points	;@1197
	cmp al, 0Fh	;@119B
	jae L11B5	;@119D
	stc	; weak: flee, negate both	;@119F
	mov al, 0	;@11A0
	cmc	;@11A2
	sbb al, byte ptr D_0019	;@11A3
	mov byte ptr D_0019, al	;@11A7
	stc	;@11AA
	mov al, 0	;@11AB
	cmc	;@11AD
	sbb al, byte ptr D_001A	;@11AE
	mov byte ptr D_001A, al	;@11B2
L11B5:	nop	; try the step in x	;@11B5
	mov al, byte ptr D_0019	;@11B6
	or al, al	;@11B9
	je L11EF	;@11BB
	clc	;@11BD
	adc al, byte ptr D_0137[di]	;@11BE
	mov byte ptr D_0023, al	;@11C2
	mov al, byte ptr D_0157[di]	;@11C5
	mov byte ptr D_0024, al	;@11C9
	mov al, byte ptr D_0023	;@11CC
	cmp al, byte ptr D_0000	;@11CF
	jne L11E1	;@11D3
	mov al, byte ptr D_0024	;@11D5
	cmp al, byte ptr D_0001	;@11D8
	jne L11E1	;@11DC
	jmp L1308	; onto the player: attack	;@11DE
L11E1:	nop	;@11E1
	call L143C	; AL = target cell, or FFh if not on the player's level	;@11E2
	je L122C	; empty	;@11E5
	cmp al, 0FFh	;@11E7
	je L11EF	;@11E9
	and al, 7Fh	;@11EB
	jne L122C	; not a wall	;@11ED
L11EF:	nop	; try the step in y	;@11EF
	mov al, byte ptr D_001A	;@11F0
	or al, al	;@11F3
	je L1229	;@11F5
	clc	;@11F7
	adc al, byte ptr D_0157[di]	;@11F8
	mov byte ptr D_0024, al	;@11FC
	mov al, byte ptr D_0137[di]	;@11FF
	mov byte ptr D_0023, al	;@1203
	mov al, byte ptr D_0023	;@1206
	cmp al, byte ptr D_0000	;@1209
	jne L121B	;@120D
	mov al, byte ptr D_0024	;@120F
	cmp al, byte ptr D_0001	;@1212
	jne L121B	;@1216
	jmp L1308	; onto the player: attack	;@1218
L121B:	nop	;@121B
	call L143C	;@121C
	je L122C	;@121F
	cmp al, 0FFh	;@1221
	je L1229	;@1223
	and al, 7Fh	;@1225
	jne L122C	;@1227
L1229:	jmp L1178	; no step possible	;@1229
L122C:	nop	;@122C
	call L144C	; the target cell again	;@122D
	and al, 7	; a monster there?	;@1230
	je L1237	;@1232
	jmp L1178	;@1234
; Move: clear the monster bits of the old cell, OR the kind into the new one.
L1237:	nop	;@1237
	mov al, byte ptr D_0023	;@1238
	mov byte ptr D_01F7[di], al	; keep the new x/y	;@123B
	mov al, byte ptr D_0024	;@123F
	mov byte ptr D_0217[di], al	;@1242
	mov al, byte ptr D_0137[di]	;@1246
	mov byte ptr D_0023, al	;@124A
	mov al, byte ptr D_0157[di]	;@124D
	mov byte ptr D_0024, al	;@1251
	call L144C	; D_0008 -> the old cell	;@1254
	mov bx, word ptr D_0008	;@1257
	mov al, byte ptr [bx+si]	;@125B
	and al, 0F0h	;@125D
	mov bx, word ptr D_0008	;@125F
	mov byte ptr [bx+si], al	;@1263
	mov al, byte ptr D_01F7[di]	;@1265
	mov byte ptr D_0023, al	;@1269
	mov byte ptr D_0137[di], al	;@126C
	mov al, byte ptr D_0217[di]	;@1270
	mov byte ptr D_0024, al	;@1274
	mov byte ptr D_0157[di], al	;@1277
	call L144C	; D_0008 -> the new cell	;@127B
	mov bx, word ptr D_0008	;@127E
	mov al, byte ptr [bx+si]	;@1282
	or al, byte ptr D_0197[di]	;@1284
	mov bx, word ptr D_0008	;@1288
	mov byte ptr [bx+si], al	;@128C
	jmp L1178	;@128E
; End of the dungeon turn: the torch (D_0026 = turns of light left).
L1291:	nop	;@1291
	mov al, byte ptr D_0026	;@1292
	or al, al	;@1295
	jne L12AE	;@1297
	call L4B4E	; clear the screen	;@1299
	call L4FDF	;@129C
	db 49h,54h,27h,53h,20h,44h,41h,52h,4Bh,21h,8Dh,0h	; "IT'S DARK!"	;@129F
	jmp L12CD	;@12AB
L12AE:	dec byte ptr D_0026	;@12AE
	jne L12CD	;@12B2
	call L4FDF	;@12B4
	db 54h,4Fh,52h,43h,48h,20h,42h,55h,52h,4Eh,45h,44h,20h,4Fh,55h,54h	; "TORCH BURNED OUT!"	;@12B7
	db 21h,8Dh,0h	;@12C7
	call L5C95	; beep	;@12CA
L12CD:	call L6000	; draw the 3D view	;@12CD
	mov al, 10h	; 0.10 food per dungeon turn	;@12D0
	call L12DB	;@12D2
	call L50F9	; status lines	;@12D5
	jmp L086F	; MAIN: next command	;@12D8

;------------------------------------------------------------------------------
; L12DB: eat food: D_0053/D_0054/D_0055 (BCD, the last byte = hundredths) -= AL
; hundredths (AL in BCD). Dies (L0C62) when the food goes below 0.
; In: AL. Uses: AX, D_0020.
;------------------------------------------------------------------------------
L12DB:	mov byte ptr D_0020, al	;@12DB
	stc	;@12DE
	mov al, byte ptr D_0055	;@12DF
	cmc	;@12E2
	sbb al, byte ptr D_0020	;@12E3
	das	;@12E7
	cmc	;@12E8
	mov byte ptr D_0055, al	;@12E9
	mov al, byte ptr D_0054	;@12EC
	cmc	;@12EF
	sbb al, 0	;@12F0
	das	;@12F2
	cmc	;@12F3
	mov byte ptr D_0054, al	;@12F4
	mov al, byte ptr D_0053	;@12F7
	cmc	;@12FA
	sbb al, 0	;@12FB
	das	;@12FD
	cmc	;@12FE
	mov byte ptr D_0053, al	;@12FF
	jb L1307	;@1302
	jmp L0C62	; starved: the player is dead	;@1304
L1307:	ret	;@1307

;------------------------------------------------------------------------------
; L1308: dungeon monster D_001F attacks the player (its step would land on
; him). Nothing happens if it is not on the player's level. One time in 4 the
; kinds 2, 5 and 7 use their special attack instead (L13AB torch blown out,
; L13DA gremlin steals food, L1410 strong magic = sleep); otherwise a blow:
; it misses when the random byte is 80h or more or its low 3 bits are below the
; armour worn (D_0062); a hit costs (random & 77h) + ((level * 4) & 77h) hit
; points, subtracted as BCD.
; Back to the monster loop (L1178), or death (L0C62).
;------------------------------------------------------------------------------
L1308:	nop	;@1308
	call L5217	;@1309
	cmp al, 40h	;@130C
	jae L133E	; 3 in 4: an ordinary blow	;@130E
	mov bh, 0	;@1310
	mov bl, byte ptr D_001F	;@1312
	mov di, bx	;@1316
	mov al, byte ptr D_0025	; the player's level	;@1318
	cmp al, byte ptr D_01B7[di]	; the monster's level	;@131B
	je L1324	;@131F
	jmp L1178	;@1321
L1324:	nop	;@1324
	mov al, byte ptr D_0197[di]	; monster kind 1-7	;@1325
	cmp al, 2	;@1329
	jne L1330	;@132B
	jmp L13AB	;@132D
L1330:	cmp al, 5	;@1330
	jne L1337	;@1332
	jmp L13DA	;@1334
L1337:	cmp al, 7	;@1337
	jne L133E	;@1339
	jmp L1410	;@133B
L133E:	nop	;@133E
	mov bh, 0	;@133F
	mov bl, byte ptr D_001F	;@1341
	mov di, bx	;@1345
	mov al, byte ptr D_0025	;@1347
	cmp al, byte ptr D_01B7[di]	; on the player's level?	;@134A
	je L1353	;@134E
	jmp L1178	;@1350
L1353:	nop	;@1353
	call L5EAC	; attack sound	;@1354
	call L5217	;@1357
	js L1364	; half the time: miss	;@135A
	and al, 7	;@135C
	cmp al, byte ptr D_0062	; armour worn (0-6)	;@135E
	jae L1367	;@1362
L1364:	jmp L1178	;@1364
L1367:	nop	;@1367
	call L4B26	; flash	;@1368
	call L5EF2	; hit sound	;@136B
	call L4B26	;@136E
	call L5217	;@1371
	and al, 77h	;@1374
	mov byte ptr D_0020, al	;@1376
	mov al, byte ptr D_0025	; level * 4	;@1379
	add al, al	;@137C
	add al, al	;@137E
	and al, 77h	;@1380
	adc al, byte ptr D_0020	; not BCD-adjusted: the das below gets a raw sum	;@1382
	mov byte ptr D_0020, al	; the damage	;@1386
	stc	;@1389
	mov al, byte ptr D_0052	; hits -= damage	;@138A
	cmc	;@138D
	sbb al, byte ptr D_0020	;@138E
	das	;@1392
	cmc	;@1393
	mov byte ptr D_0052, al	;@1394
	mov al, byte ptr D_0051	;@1397
	cmc	;@139A
	sbb al, 0	;@139B
	das	;@139D
	cmc	;@139E
	mov byte ptr D_0051, al	;@139F
	jb L13A7	;@13A2
	jmp L0C62	; the player is dead	;@13A4
L13A7:	nop	;@13A7
	jmp L1178	;@13A8
; Kind 2: puts out the torch.
L13AB:	mov al, byte ptr D_0026	; torch turns left	;@13AB
	or al, al	;@13AE
	je L13D7	;@13B0
	call L4FDF	;@13B2
	db 59h,4Fh,55h,52h,20h,54h,4Fh,52h,43h,48h,20h,49h,53h,20h,42h,4Ch	; "YOUR TORCH IS BLOWN OUT!"	;@13B5
	db 4Fh,57h,4Eh,20h,4Fh,55h,54h,21h,8Dh,0h	;@13C5
	call L5C95	; beep	;@13CF
	mov al, 0	;@13D2
	mov byte ptr D_0026, al	;@13D4
L13D7:	jmp L1178	;@13D7
; Kind 5, the gremlin: -100 food.
L13DA:	call L4FDF	;@13DA
	db 41h,20h,47h,52h,45h,4Dh,4Ch,49h,4Eh,20h,53h,54h,4Fh,4Ch,45h,20h	; "A GREMLIN STOLE SOME FOOD!"	;@13DD
	db 53h,4Fh,4Dh,45h,20h,46h,4Fh,4Fh,44h,21h,8Dh,0h	;@13ED
	call L5C95	; beep	;@13F9
	stc	;@13FC
	mov al, byte ptr D_0053	; food, high BCD byte: -100	;@13FD
	cmc	;@1400
	sbb al, 1	;@1401
	das	;@1403
	cmc	;@1404
	mov byte ptr D_0053, al	;@1405
	jae L140D	; below zero	;@1408
	jmp L1178	;@140A
L140D:	jmp L0C62	; the player is dead (a gremlin can kill you)	;@140D
; Kind 7: sleep for 0-7 turns, no save.
L1410:	nop	;@1410
	call L4FDF	;@1411
	db 59h,4Fh,55h,20h,46h,45h,45h,4Ch,20h,41h,20h,53h,54h,52h,4Fh,4Eh	; "YOU FEEL A STRONG MAGIC!"	;@1414
	db 47h,20h,4Dh,41h,47h,49h,43h,21h,8Dh,0h	;@1424
	call L5C95	; beep	;@142E
	call L5217	;@1431
	and al, 7	;@1434
	mov byte ptr D_026D, al	; asleep	;@1436
	jmp L1178	;@1439

;------------------------------------------------------------------------------
; L143C: read the dungeon cell D_0023/D_0024 on the level of monster DI, but
; only if that is the player's level D_0025; else AL = FFh, ZF = 0.
; L144C: the same without the level test. L1451: the same with the level in AL
; (CMDAL uses it for the player's own cells).
; Out: AL = the cell, ZF set if 0 (empty); D_0008/D_0009 = its address
; (map buffer + level * 256 + y * 16 + x); SI = 0. Uses: AX, BX, SI.
; Setting only the low byte from y/x relies on the map buffer starting on a
; 256-byte boundary (DS:1800), as on the Apple II.
;------------------------------------------------------------------------------
L143C:	nop	;@143C
	mov al, byte ptr D_0025	; the player's level	;@143D
	cmp al, byte ptr D_01B7[di]	; the monster's level	;@1440
	je L144B	;@1444
	mov al, 0FFh	;@1446
	or al, al	;@1448
	ret	;@144A
L144B:	nop	;@144B
L144C:	nop	;@144C
	mov al, byte ptr D_01B7[di]	; level	;@144D
L1451:	nop	;@1451
	mov ah, al	;@1452
	mov al, 0	;@1454
	add ax, word ptr D_0472	; map buffer + level * 256	;@1456
	mov byte ptr D_0009, ah	; pointer high byte	;@145A
	mov al, byte ptr D_0024	;@145E
	add al, al	;@1461
	add al, al	;@1463
	add al, al	;@1465
	add al, al	; y * 16	;@1467
	adc al, byte ptr D_0023	; + x	;@1469
	mov byte ptr D_0008, al	; pointer low byte	;@146D
	mov bh, 0	;@1470
	mov bl, 0	;@1472
	mov si, bx	;@1474
	mov bx, word ptr D_0008	;@1476
	mov al, byte ptr [bx+si]	;@147A
	or al, al	;@147C
	ret	;@147E

;------------------------------------------------------------------------------
; L147F: put new monsters into the free dungeon slots 31-1. Slot n belongs to
; level n/2, so each level has two slots. A new monster gets a random odd x and
; y (1-15); the cell must be empty; then a random kind k = 1-7 (8 gives none),
; allowed only if 2(k-1) <= level: deeper levels have worse monsters. Hit
; points = ((2k + level) * 8) OR 10h. Called every dungeon turn, so free slots
; refill quickly. Uses: AX, BX, SI, DI, D_001F, D_0023/D_0024.
;------------------------------------------------------------------------------
L147F:	nop	;@147F
	mov bh, 0	;@1480
	mov bl, 1Fh	;@1482
	mov di, bx	;@1484
L1486:	mov bx, di	;@1486
	mov byte ptr D_001F, bl	;@1488
	mov al, byte ptr D_0197[di]	;@148C
	or al, al	;@1490
	je L14A0	; a free slot	;@1492
L1494:	mov bh, 0	;@1494
	mov bl, byte ptr D_001F	;@1496
	mov di, bx	;@149A
	dec di	;@149C
	jne L1486	;@149D
	ret	;@149F
L14A0:	nop	;@14A0
	call L5217	;@14A1
	mov bh, 0	;@14A4
	mov bl, byte ptr D_001F	;@14A6
	mov di, bx	;@14AA
	and al, 7	;@14AC
	add al, al	;@14AE
	or al, 1	; x = 1, 3, ..., 15	;@14B0
	mov byte ptr D_0137[di], al	;@14B2
	mov byte ptr D_0023, al	;@14B6
	call L5217	;@14B9
	mov bh, 0	;@14BC
	mov bl, byte ptr D_001F	;@14BE
	mov di, bx	;@14C2
	and al, 7	;@14C4
	add al, al	;@14C6
	or al, 1	; y = 1, 3, ..., 15	;@14C8
	mov byte ptr D_0157[di], al	;@14CA
	mov byte ptr D_0024, al	;@14CE
	mov ax, di	;@14D1
	clc	;@14D3
	rcr al, 1	;@14D4
	mov byte ptr D_01B7[di], al	; level = slot / 2	;@14D6
	call L144C	;@14DA
	jne L1494	; cell not empty	;@14DD
	call L5217	;@14DF
	mov bh, 0	;@14E2
	mov bl, byte ptr D_001F	;@14E4
	mov di, bx	;@14E8
	and al, 7	;@14EA
	cmp al, 7	;@14EC
	je L14FA	;@14EE
	add al, al	;@14F0
	cmp al, byte ptr D_01B7[di]	; 2(k-1) <= level?	;@14F2
	je L14FC	;@14F6
	jb L14FC	;@14F8
L14FA:	jmp L1494	;@14FA
L14FC:	nop	;@14FC
	clc	;@14FD
	rcr al, 1	;@14FE
	adc al, 1	; kind k = 1-7	;@1500
	mov byte ptr D_0197[di], al	;@1502
	add al, al	;@1506
	adc al, byte ptr D_01B7[di]	;@1508
	add al, al	;@150C
	add al, al	;@150E
	add al, al	;@1510
	or al, 10h	;@1512
	mov byte ptr D_0177[di], al	; hit points	;@1514
	call L144C	;@1518
	mov bx, word ptr D_0008	;@151B
	mov al, byte ptr [bx+si]	;@151F
	or al, byte ptr D_0197[di]	; put it into the cell	;@1521
	mov bx, word ptr D_0008	;@1525
	mov byte ptr [bx+si], al	;@1529
	jmp L1494	;@152B

;------------------------------------------------------------------------------
; L152E: D_0019/D_001A = the sign (-1/0/+1) of the player's x/y minus those of
; monster DI: the direction toward the player in a dungeon (no wrap-around,
; unlike TEXTIO's L4F11). Uses: AL.
;------------------------------------------------------------------------------
L152E:	nop	;@152E
	mov al, byte ptr D_0000	;@152F
	stc	;@1532
	cmc	;@1533
	sbb al, byte ptr D_0137[di]	;@1534
	call L50D8	; sign	;@1538
	mov byte ptr D_0019, al	;@153B
	mov al, byte ptr D_0001	;@153E
	stc	;@1541
	cmc	;@1542
	sbb al, byte ptr D_0157[di]	;@1543
	call L50D8	;@1547
	mov byte ptr D_001A, al	;@154A
	ret	;@154D
CODE ENDS
END
