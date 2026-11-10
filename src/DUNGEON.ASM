; DUNGEON.ASM: the dungeon and tower loop: advance, turn, retreat, traps.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 26F9-2B65.
;
; Overview: three unrelated pieces that happen to sit together in the original.
; - MoveTimeDoor moves the time door on Earth's surface (called every surface turn from MAIN 0C30): every
;   8 turns the door (tile C0h) leaves its spot and appears at the next of the four spots of the
;   current time period, from the table TimeDoorTbl. MOVE 26B7 uses the same table when the player
;   steps into the door.
; - DungeonLoop is the dungeon and tower command loop (MAIN 087A jumps here when MapType >= 4): sleep,
;   "CMD:" with a time-out (PASS), then the arrow keys ADVANCE / TURN LEFT / TURN RIGHT /
;   RETREAT (with traps on advance), space = PASS, any other key to the letter commands (DispatchCommand).
; - DrawHelmMap draws the whole 64x64 map as a 256x128-pixel picture, 4x2 pixels per tile, for
;   V)iew with the magic helm (CMDMZ 43CC).
; Data: PlayerX/PlayerY (position), FacingDX/FacingDY (facing in the dungeon), TileNorth/TileSouth (tiles
; ahead/behind, from VIEW3D), DungeonLevel (dungeon level), Tools (tools), SleepTurns (sleep turns),
; KeyNorth-KeyWest (direction keys), TimeZone/Planet-TimeDoorUnder (time period and time door state).
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN PlayerX:BYTE, PlayerY:BYTE, FacingDX:BYTE, FacingDY:BYTE, MapCellPtr:BYTE, TileNorth:BYTE
	EXTRN TileSouth:BYTE, DeltaX:BYTE, DeltaY:BYTE, Temp1F:BYTE, LookX:BYTE, LookY:BYTE
	EXTRN DungeonLevel:BYTE, LightTurns:BYTE, AmountHi:BYTE, TimeZone:BYTE, Tools:BYTE, Planet:BYTE
	EXTRN TimeDoorSpot:BYTE, TimeDoorTimer:BYTE, TimeDoorUnder:BYTE, SleepTurns:BYTE, KeyNorth:BYTE, KeySouth:BYTE
	EXTRN KeyEast:BYTE, KeyWest:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN SpeedDelay:NEAR, DispatchCommand:NEAR, EndCommandBeep:NEAR, EndCommand:NEAR, PlayerDies:NEAR
	EXTRN PlotOverviewDot:NEAR
	EXTRN ClearViewArea:NEAR, ReadKey:NEAR, PrintInline:NEAR, GetMapSquare:NEAR, Random:NEAR, PlayTrapSound:NEAR
	EXTRN PlayHurtSound:NEAR
	PUBLIC MoveTimeDoor, TimeDoorTbl, DungeonLoop, DrawHelmMap
ASSUME CS:CODE, DS:DATA

;------------------------------------------------------------------------------
; MoveTimeDoor: move the time door, once per surface turn (MAIN 0C30, MapType = 0).
; Only on Earth (Planet = 0). The countdown TimeDoorTimer runs 8 turns; then the door
; tile C0h at spot TimeDoorSpot of period TimeZone is replaced by the tile it covered
; (TimeDoorUnder), TimeDoorSpot steps to the next spot (0, 2, 4, 6: byte offsets of the x,y
; pairs in TimeDoorTbl) and, if the tile there is plain terrain (< 14h: water, marsh,
; grass, woods, mountains), it is saved in TimeDoorUnder and the door put on it.
; Otherwise (a monster or another object there) the door skips this round
; (perhaps what the manual means by "it will not reappear while you stand on it").
; In: TimeZone, Planet-TimeDoorUnder. Out: map changed; AL = x, DI = y of the new door
; (unused by the caller). Uses: AX, BX, SI, DI, Temp1F, LookX/LookY, MapCellPtr.
;------------------------------------------------------------------------------
MoveTimeDoor:	mov al, byte ptr Planet	;@26F9
	cmp al, 0	; on Earth?	;@26FC
	je TimeDoor_Countdown	;@26FE
	ret	;@2700
TimeDoor_Countdown:	dec byte ptr TimeDoorTimer	; door's turns left	;@2701
	je TimeDoor_Remove	;@2705
	ret	;@2707
; take the door away from its current spot
TimeDoor_Remove:	clc	;@2708
	mov al, byte ptr TimeZone	;@2709
	add al, al	;@270C
	add al, al	;@270E
	add al, al	;@2710
	mov byte ptr Temp1F, al	; period * 8 = row of TimeDoorTbl	;@2712
	adc al, byte ptr TimeDoorSpot	;@2715
	mov ah, 0	;@2719
	mov di, ax	;@271B
	mov al, byte ptr cs:TimeDoorTbl[di]	;@271D
	mov byte ptr LookX, al	; x	;@2722
	inc di	;@2725
	mov al, byte ptr cs:TimeDoorTbl[di]	;@2726
	mov byte ptr LookY, al	; y	;@272B
	call GetMapSquare	; AL = map tile at LookX,LookY	;@272E
	cmp al, 0C0h	; still a time door?	;@2731
	jne TimeDoor_NextSpot	;@2733
	mov bh, 0	;@2735
	mov bl, 0	;@2737
	mov si, bx	;@2739
	mov al, byte ptr TimeDoorUnder	;@273B
	mov bx, word ptr MapCellPtr	;@273E
	mov byte ptr [bx+si], al	; put back the tile it covered	;@2742
; next spot
TimeDoor_NextSpot:	mov al, 8	;@2744
	mov byte ptr TimeDoorTimer, al	; 8 turns until the next move	;@2746
	inc byte ptr TimeDoorSpot	;@2749
	inc byte ptr TimeDoorSpot	;@274D
	mov al, byte ptr TimeDoorSpot	;@2751
	and al, 7	; spots 0, 2, 4, 6	;@2754
	mov byte ptr TimeDoorSpot, al	;@2756
	clc	;@2759
	adc al, byte ptr Temp1F	;@275A
	mov ah, 0	;@275E
	mov di, ax	;@2760
	mov al, byte ptr cs:TimeDoorTbl[di]	;@2762
	mov byte ptr LookX, al	;@2767
	inc di	;@276A
	mov al, byte ptr cs:TimeDoorTbl[di]	;@276B
	mov byte ptr LookY, al	;@2770
	call GetMapSquare	;@2773
	cmp al, 14h	; plain terrain?	;@2776
	jb TimeDoor_Place	;@2778
	ret	;@277A
TimeDoor_Place:	mov byte ptr TimeDoorUnder, al	; remember the tile under the door	;@277B
	mov bh, 0	;@277E
	mov bl, 0	;@2780
	mov si, bx	;@2782
	mov al, 0C0h	;@2784
	mov bx, word ptr MapCellPtr	;@2786
	mov byte ptr [bx+si], al	; place the time door	;@278A
	mov al, byte ptr LookX	;@278C
	mov bh, 0	;@278F
	mov bl, byte ptr LookY	;@2791
	mov di, bx	;@2795
	ret	;@2797

; TimeDoorTbl: time door spots, x,y pairs (map coordinates 0-3Fh), four per time period
; (8 bytes per period, TimeZone = 0-4, probably in the manual's order Legends, Pangea,
; B.C., A.D., Aftermath: period 0's doors sit side by side at the bottom of the map,
; as the manual says of Legends). Door n (TimeDoorSpot/2) leads to the n-th other period
; (MOVE 26B7), where the player arrives at door n's spot of that period.
;   0: 1D,38 1F,38 21,38 23,38   1: 22,08 2F,1C 24,38 14,25   2: 10,10 30,18 2A,18 13,34
;   3: 38,34 1C,0C 21,17 14,34   4: 12,17 32,22 34,18 08,0B
TimeDoorTbl label byte
	db 1Dh,38h,1Fh,38h,21h,38h,23h,38h,22h,8h,2Fh,1Ch,24h,38h,14h,25h	;@2798
	db 10h,10h,30h,18h,2Ah,18h,13h,34h,38h,34h,1Ch,0Ch,21h,17h,14h,34h	;@27A8
	db 12h,17h,32h,22h,34h,18h,8h,0Bh	;@27B8
;------------------------------------------------------------------------------
; DungeonLoop: the dungeon and tower command loop, jumped to by MAIN 087A (after the
; stack is reset) when MapType >= 4. Asleep (SleepTurns > 0): print "CMD: " and 20
; 'Z's slowly, one sleep turn less, end the turn. Awake: print "CMD: " and wait
; for a key with a time-out, after which the turn passes ("PASS"). The four
; direction keys (KeyNorth-KeyWest, the arrows) are ADVANCE / RETREAT / TURN
; LEFT / TURN RIGHT, space is PASS, anything else goes to the letter command
; dispatcher DispatchCommand. Every path ends at EndCommand (end of turn) or EndCommandBeep (with the
; error sound). Does not return.
;------------------------------------------------------------------------------
DungeonLoop:	nop	;@27C0
	mov al, byte ptr SleepTurns	;@27C1
	or al, al	; asleep?	;@27C4
	je Dungeon_ReadCmd	;@27C6
	call PrintInline	; "CMD: "	;@27C8
	db 43h,4Dh,44h,3Ah,20h,0h	;@27CB
	mov al, 14h	;@27D1
	mov byte ptr AmountHi, al	; 20 'Z's	;@27D3
Dungeon_SleepZ:	call PrintInline	; "Z"	;@27D6
	db 5Ah,0h	;@27D9
	mov bh, 0	;@27DB
	mov bl, 0FFh	;@27DD
	mov di, bx	;@27DF
Dungeon_SleepDelay:	dec di	; short CPU-speed dependent delay	;@27E1
	jne Dungeon_SleepDelay	;@27E2
	dec byte ptr AmountHi	;@27E4
	jne Dungeon_SleepZ	;@27E8
	dec byte ptr SleepTurns	; one sleep turn less	;@27EA
	jmp EndCommand	;@27EE
; awake: wait for a key. DI counts the inner loop, SI = 2 rounds. DI is a word
; (6502 Y register originally): the first round runs 255 times but the second
; 65536 times, so the time-out is far longer than the 2 x 256 probably meant.
Dungeon_ReadCmd:	nop	;@27F1
	call PrintInline	; "CMD: "	;@27F2
	db 43h,4Dh,44h,3Ah,20h,0h	;@27F5
	mov bh, 0	;@27FB
	mov bl, 0FFh	;@27FD
	mov di, bx	;@27FF
	mov bh, 0	;@2801
	mov bl, 2	;@2803
	mov si, bx	;@2805
Dungeon_WaitKey:	mov bx, 0	;@2807
	call SpeedDelay	; calibrated delay (DelayTbl[0])	;@280A
	call ReadKey	; key? (AH = 0FFh if one was read)	;@280D
	cmp ah, 0FFh	;@2810
	je Dungeon_GotKey	;@2813
; six push/pop pairs: padding for the delay
	push ax	;@2815
	pop ax	;@2816
	push ax	;@2817
	pop ax	;@2818
	push ax	;@2819
	pop ax	;@281A
	push ax	;@281B
	pop ax	;@281C
	push ax	;@281D
	pop ax	;@281E
	push ax	;@281F
	pop ax	;@2820
	dec di	;@2821
	jne Dungeon_WaitKey	;@2822
	dec si	;@2824
	jne Dungeon_WaitKey	;@2825
	call PrintInline	; time-out: "PASS"	;@2827
	db 50h,41h,53h,53h,0h	;@282A
	jmp EndCommand	;@282F
; a key: AL = its code
Dungeon_GotKey:	nop	;@2832
	cmp al, byte ptr KeyNorth	; north key (up arrow) = advance	;@2833
	jne Dungeon_KeyWest	;@2837
	jmp DungeonAdvance	;@2839
Dungeon_KeyWest:	cmp al, byte ptr KeyWest	; west key (left arrow) = turn left	;@283C
	jne Dungeon_KeyEast	;@2840
	jmp DungeonTurnLeft	;@2842
Dungeon_KeyEast:	cmp al, byte ptr KeyEast	; east key (right arrow) = turn right	;@2845
	jne Dungeon_KeySouth	;@2849
	jmp DungeonTurnRight	;@284B
Dungeon_KeySouth:	cmp al, byte ptr KeySouth	; south key (down arrow) = retreat	;@284E
	jne Dungeon_KeySpace	;@2852
	jmp DungeonRetreat	;@2854
Dungeon_KeySpace:	cmp al, 20h	; space = pass	;@2857
	jne Dungeon_LetterCmd	;@2859
	jmp DungeonPass	;@285B
Dungeon_LetterCmd:	jmp DispatchCommand	; letter commands A-Z	;@285E

;------------------------------------------------------------------------------
; DungeonAdvance: ADVANCE. Blocked if the tile ahead (TileNorth, from VIEW3D) has any of
; its low 4 bits set or is 80h (walls, doors?). Else steps by the facing
; FacingDX/FacingDY (wrapping at 64) and, if a random byte < the dungeon level
; DungeonLevel, springs a trap (never on level 0): the screen is cleared, sounds,
; and without tools (Tools) the player dies (PlayerDies); with them one tool is
; used up.
;------------------------------------------------------------------------------
DungeonAdvance:	nop	;@2861
	call PrintInline	; "ADVANCE"	;@2862
	db 41h,44h,56h,41h,4Eh,43h,45h,0h	;@2865
	mov al, byte ptr TileNorth	;@286D
	and al, 0Fh	;@2870
	je Advance_Check80	;@2872
Advance_Blocked:	call PrintInline	; "-BLOCKED!"	;@2874
	db 2Dh,42h,4Ch,4Fh,43h,4Bh,45h,44h,21h,0h	;@2877
	jmp EndCommandBeep	;@2881
Advance_Check80:	mov al, byte ptr TileNorth	;@2884
	cmp al, 80h	;@2887
	je Advance_Blocked	;@2889
	clc	;@288B
	mov al, byte ptr PlayerX	;@288C
	adc al, byte ptr FacingDX	; x += facing dx	;@288F
	and al, 3Fh	;@2893
	mov byte ptr PlayerX, al	;@2895
	clc	;@2898
	mov al, byte ptr PlayerY	;@2899
	adc al, byte ptr FacingDY	; y += facing dy	;@289C
	and al, 3Fh	;@28A0
	mov byte ptr PlayerY, al	;@28A2
	call Random	;@28A5
	cmp al, byte ptr DungeonLevel	; random < dungeon level: trap	;@28A8
	jb Advance_Trap	;@28AC
	jmp EndCommand	;@28AE
Advance_Trap:	nop	;@28B1
	call ClearViewArea	; clear the graphics screen	;@28B2
	mov al, 0	;@28B5
	mov byte ptr LightTurns, al	;@28B7
	call PrintInline	; "ARGH! A TRAP!"	;@28BA
	db 8Dh,41h,52h,47h,48h,21h,20h,41h,20h,54h,52h,41h,50h,21h,8Dh,0h	;@28BD
	call PlayTrapSound	; sounds	;@28CD
	call PlayHurtSound	;@28D0
	call PlayHurtSound	;@28D3
	call PlayHurtSound	;@28D6
	call PlayHurtSound	;@28D9
	mov al, byte ptr Tools	;@28DC
	or al, al	; any tools?	;@28DF
	jne Trap_UseTools	;@28E1
	jmp PlayerDies	; no: dead	;@28E3
Trap_UseTools:	call PrintInline	; "ESCAPED! BY USE OF TOOLS!"	;@28E6
	db 45h,53h,43h,41h,50h,45h,44h,21h,20h,42h,59h,20h,55h,53h,45h,20h	;@28E9
	db 4Fh,46h,20h,54h,4Fh,4Fh,4Ch,53h,21h,0h	;@28F9
	stc	;@2903
	mov al, byte ptr Tools	;@2904
	cmc	;@2907
	sbb al, 1	;@2908
	das	; tools -= 1 (BCD; stc/cmc/sbb = 6502 SEC/SBC)	;@290A
	cmc	;@290B
	mov byte ptr Tools, al	;@290C
	jmp EndCommand	;@290F

;------------------------------------------------------------------------------
; DungeonTurnLeft: TURN LEFT. The facing FacingDX/FacingDY (dx, dy: 0, 1 or 0FFh) is turned
; a quarter anticlockwise: (dx, dy) -> (dy, -dx).
;------------------------------------------------------------------------------
DungeonTurnLeft:	nop	;@2912
	call PrintInline	; "TURN LEFT"	;@2913
	db 54h,55h,52h,4Eh,20h,4Ch,45h,46h,54h,0h	;@2916
	mov al, byte ptr FacingDY	;@2920
	cmp al, 0	;@2923
	je TurnLeft_FromEW	;@2925
	mov byte ptr FacingDX, al	; facing north/south: dx = dy, dy = 0	;@2927
	mov al, 0	;@292A
	mov byte ptr FacingDY, al	;@292C
	jmp EndCommand	;@292F
TurnLeft_FromEW:	stc	;@2932
	cmc	;@2933
	sbb al, byte ptr FacingDX	; facing east/west: dy = 0 - dx, dx = 0	;@2934
	cmc	;@2938
	mov byte ptr FacingDY, al	;@2939
	mov al, 0	;@293C
	mov byte ptr FacingDX, al	;@293E
	jmp EndCommand	;@2941

;------------------------------------------------------------------------------
; DungeonTurnRight: TURN RIGHT: (dx, dy) -> (-dy, dx).
;------------------------------------------------------------------------------
DungeonTurnRight:	nop	;@2944
	call PrintInline	; "TURN RIGHT"	;@2945
	db 54h,55h,52h,4Eh,20h,52h,49h,47h,48h,54h,0h	;@2948
	mov al, byte ptr FacingDX	;@2953
	or al, al	;@2956
	je TurnRight_FromNS	;@2958
	mov byte ptr FacingDY, al	; facing east/west: dy = dx, dx = 0	;@295A
	mov al, 0	;@295D
	mov byte ptr FacingDX, al	;@295F
	jmp EndCommand	;@2962
TurnRight_FromNS:	stc	;@2965
	cmc	;@2966
	sbb al, byte ptr FacingDY	; facing north/south: dx = 0 - dy, dy = 0	;@2967
	cmc	;@296B
	mov byte ptr FacingDX, al	;@296C
	mov al, 0	;@296F
	mov byte ptr FacingDY, al	;@2971
	jmp EndCommand	;@2974

;------------------------------------------------------------------------------
; DungeonRetreat: RETREAT. Blocked if the tile behind (TileSouth) has bit 7 or any of the
; low 4 bits set (stricter than ADVANCE's test). Else steps back against the
; facing, wrapping at 64. No trap check.
;------------------------------------------------------------------------------
DungeonRetreat:	nop	;@2977
	call PrintInline	; "RETREAT"	;@2978
	db 52h,45h,54h,52h,45h,41h,54h,0h	;@297B
	mov al, byte ptr TileSouth	;@2983
	and al, 8Fh	;@2986
	je Retreat_Step	;@2988
	call PrintInline	; "-BLOCKED!"	;@298A
	db 2Dh,42h,4Ch,4Fh,43h,4Bh,45h,44h,21h,0h	;@298D
	jmp EndCommandBeep	;@2997
Retreat_Step:	nop	;@299A
	mov al, byte ptr PlayerX	;@299B
	stc	;@299E
	cmc	;@299F
	sbb al, byte ptr FacingDX	; x -= dx	;@29A0
	cmc	;@29A4
	and al, 3Fh	;@29A5
	mov byte ptr PlayerX, al	;@29A7
	mov al, byte ptr PlayerY	;@29AA
	stc	;@29AD
	cmc	;@29AE
	sbb al, byte ptr FacingDY	; y -= dy	;@29AF
	cmc	;@29B3
	and al, 3Fh	;@29B4
	mov byte ptr PlayerY, al	;@29B6
	jmp EndCommand	;@29B9

; DungeonPass: space = PASS
DungeonPass:	call PrintInline	; "PASS"	;@29BC
	db 50h,41h,53h,53h,0h	;@29BF
	jmp EndCommand	;@29C4
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h	; padding (never executed)	;@29C7
; HelmOriginX/HelmOriginY: CS variables, origin (x, y) of the helm picture. Always 0: DrawHelmMap
; clears them and nothing else writes them (a left-over of a scrolling view?).
HelmOriginX label byte
	db 0h	;@29D0
HelmOriginY label byte
	db 0h	;@29D1

;------------------------------------------------------------------------------
; DrawHelmMap: draw the whole 64x64 map (outdoor or town) as a picture for V)iew
; with the magic helm (CMDMZ 43CC): clears the screen, then for every tile
; (DeltaX = x, DeltaY = y, 0-3Fh) plots a 4x2-pixel pattern at (4x, 2y)
; through PlotOverviewDot (DI = pixel column 0-3, SI = row 0-1 within the cell):
;   0 water: nothing                        4 marsh: 2 dots, top row
;   8 grass: 2 dots (diagonal)              0Ch woods: columns 1 and 3
;   10h mountains, 78h-0EFh: solid           70h (?): columns 0 and 2
;   anything else (towns, signs, ...): a 2x2 square in the middle
; In: map buffer. Out: picture drawn. Uses: AX, BX, SI, DI, DeltaX/DeltaY,
; LookX/LookY, MapCellPtr.
;------------------------------------------------------------------------------
DrawHelmMap:	nop	;@29D2
	mov al, 0	;@29D3
	mov byte ptr cs:HelmOriginX, al	; origin = 0, 0	;@29D5
	mov byte ptr cs:HelmOriginY, al	;@29D9
	mov byte ptr DeltaX, al	;@29DD
	mov byte ptr DeltaY, al	;@29E0
	call ClearViewArea	; clear the graphics screen	;@29E3
HelmMap_Loop:	mov al, byte ptr cs:HelmOriginX	;@29E6
	clc	;@29EA
	adc al, byte ptr DeltaX	;@29EB
	and al, 3Fh	;@29EF
	mov byte ptr LookX, al	;@29F1
	mov al, byte ptr cs:HelmOriginY	;@29F4
	clc	;@29F8
	adc al, byte ptr DeltaY	;@29F9
	and al, 3Fh	;@29FD
	mov byte ptr LookY, al	;@29FF
	call GetMapSquare	; AL = tile, ZF if 0 (water)	;@2A02
	jne HelmMap_Classify	;@2A05
	jmp HelmMap_Next	;@2A07
HelmMap_Classify:	cmp al, 10h	; mountains: solid	;@2A0A
	je HelmMap_Solid	;@2A0C
	cmp al, 78h	;@2A0E
	jb HelmMap_CheckGrass	;@2A10
	cmp al, 0F0h	; 78h-0EFh: solid	;@2A12
	jb HelmMap_Solid	;@2A14
HelmMap_CheckGrass:	cmp al, 8	; grass	;@2A16
	je HelmMap_Grass	;@2A18
	cmp al, 0Ch	; woods	;@2A1A
	je HelmMap_Woods	;@2A1C
	cmp al, 4	; marsh	;@2A1E
	je HelmMap_ToMarsh	;@2A20
	cmp al, 70h	;@2A22
	je HelmMap_ToTownFloor	;@2A24
	jmp HelmMap_Other	; others: middle square	;@2A26
HelmMap_ToMarsh:	jmp HelmMap_Marsh	;@2A29
HelmMap_ToTownFloor:	jmp HelmMap_TownFloor	;@2A2C
; solid: (0,0) (0,1) (2,1) (2,0), then falls into the woods and grass patterns
HelmMap_Solid:	mov bh, 0	;@2A2F
	mov bl, 0	;@2A31
	mov di, bx	;@2A33
	mov bh, 0	;@2A35
	mov bl, 0	;@2A37
	mov si, bx	;@2A39
	call PlotOverviewDot	;@2A3B
	mov bh, 0	;@2A3E
	mov bl, 0	;@2A40
	mov di, bx	;@2A42
	mov bh, 0	;@2A44
	mov bl, 1	;@2A46
	mov si, bx	;@2A48
	call PlotOverviewDot	;@2A4A
	mov bh, 0	;@2A4D
	mov bl, 2	;@2A4F
	mov di, bx	;@2A51
	mov bh, 0	;@2A53
	mov bl, 1	;@2A55
	mov si, bx	;@2A57
	call PlotOverviewDot	;@2A59
	mov bh, 0	;@2A5C
	mov bl, 2	;@2A5E
	mov di, bx	;@2A60
	mov bh, 0	;@2A62
	mov bl, 0	;@2A64
	mov si, bx	;@2A66
	call PlotOverviewDot	;@2A68
; woods: (1,1) (3,0), then the grass dots
HelmMap_Woods:	mov bh, 0	;@2A6B
	mov bl, 1	;@2A6D
	mov di, bx	;@2A6F
	mov bh, 0	;@2A71
	mov bl, 1	;@2A73
	mov si, bx	;@2A75
	call PlotOverviewDot	;@2A77
	mov bh, 0	;@2A7A
	mov bl, 3	;@2A7C
	mov di, bx	;@2A7E
	mov bh, 0	;@2A80
	mov bl, 0	;@2A82
	mov si, bx	;@2A84
	call PlotOverviewDot	;@2A86
; grass: (1,0) (3,1)
HelmMap_Grass:	mov bh, 0	;@2A89
	mov bl, 1	;@2A8B
	mov di, bx	;@2A8D
	mov bh, 0	;@2A8F
	mov bl, 0	;@2A91
	mov si, bx	;@2A93
	call PlotOverviewDot	;@2A95
	mov bh, 0	;@2A98
	mov bl, 3	;@2A9A
	mov di, bx	;@2A9C
	mov bh, 0	;@2A9E
	mov bl, 1	;@2AA0
	mov si, bx	;@2AA2
	call PlotOverviewDot	;@2AA4
	jmp HelmMap_Next	;@2AA7
; marsh: (1,0) (3,0)
HelmMap_Marsh:	mov bh, 0	;@2AAA
	mov bl, 1	;@2AAC
	mov di, bx	;@2AAE
	mov bh, 0	;@2AB0
	mov bl, 0	;@2AB2
	mov si, bx	;@2AB4
	call PlotOverviewDot	;@2AB6
	mov bh, 0	;@2AB9
	mov bl, 3	;@2ABB
	mov di, bx	;@2ABD
	mov bh, 0	;@2ABF
	mov bl, 0	;@2AC1
	mov si, bx	;@2AC3
	call PlotOverviewDot	;@2AC5
	jmp HelmMap_Next	;@2AC8
; tile 70h: (0,0) (0,1) (2,0) (2,1)
HelmMap_TownFloor:	mov bh, 0	;@2ACB
	mov bl, 0	;@2ACD
	mov di, bx	;@2ACF
	mov bh, 0	;@2AD1
	mov bl, 0	;@2AD3
	mov si, bx	;@2AD5
	call PlotOverviewDot	;@2AD7
	mov bh, 0	;@2ADA
	mov bl, 0	;@2ADC
	mov di, bx	;@2ADE
	mov bh, 0	;@2AE0
	mov bl, 1	;@2AE2
	mov si, bx	;@2AE4
	call PlotOverviewDot	;@2AE6
	mov bh, 0	;@2AE9
	mov bl, 2	;@2AEB
	mov di, bx	;@2AED
	mov bh, 0	;@2AEF
	mov bl, 0	;@2AF1
	mov si, bx	;@2AF3
	call PlotOverviewDot	;@2AF5
	mov bh, 0	;@2AF8
	mov bl, 2	;@2AFA
	mov di, bx	;@2AFC
	mov bh, 0	;@2AFE
	mov bl, 1	;@2B00
	mov si, bx	;@2B02
	call PlotOverviewDot	;@2B04
	jmp HelmMap_Next	;@2B07
; anything else: (1,0) (2,0) (2,1) (1,1)
HelmMap_Other:	mov bh, 0	;@2B0A
	mov bl, 1	;@2B0C
	mov di, bx	;@2B0E
	mov bh, 0	;@2B10
	mov bl, 0	;@2B12
	mov si, bx	;@2B14
	call PlotOverviewDot	;@2B16
	mov bh, 0	;@2B19
	mov bl, 2	;@2B1B
	mov di, bx	;@2B1D
	mov bh, 0	;@2B1F
	mov bl, 0	;@2B21
	mov si, bx	;@2B23
	call PlotOverviewDot	;@2B25
	mov bh, 0	;@2B28
	mov bl, 2	;@2B2A
	mov di, bx	;@2B2C
	mov bh, 0	;@2B2E
	mov bl, 1	;@2B30
	mov si, bx	;@2B32
	call PlotOverviewDot	;@2B34
	mov bh, 0	;@2B37
	mov bl, 1	;@2B39
	mov di, bx	;@2B3B
	mov bh, 0	;@2B3D
	mov bl, 1	;@2B3F
	mov si, bx	;@2B41
	call PlotOverviewDot	;@2B43
; next tile: x = 0-3Fh within a row, then y = 0-3Fh
HelmMap_Next:	inc byte ptr DeltaX	;@2B46
	mov al, byte ptr DeltaX	;@2B4A
	and al, 3Fh	;@2B4D
	mov byte ptr DeltaX, al	;@2B4F
	or al, al	;@2B52
	je HelmMap_NextRow	; end of the row	;@2B54
HelmMap_Continue:	jmp HelmMap_Loop	;@2B56
HelmMap_NextRow:	inc byte ptr DeltaY	;@2B59
	mov al, byte ptr DeltaY	;@2B5D
	cmp al, 40h	;@2B60
	jb HelmMap_Continue	;@2B62
	ret	;@2B64
CODE ENDS
END
