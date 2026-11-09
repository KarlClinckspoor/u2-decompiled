; DUNGEON.ASM: the dungeon and tower loop: advance, turn, retreat, traps.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 26F9-2B65.
;
; Overview: three unrelated pieces that happen to sit together in the original.
; - L26F9 moves the time door on Earth's surface (called every surface turn from MAIN 0C30): every
;   8 turns the door (tile C0h) leaves its spot and appears at the next of the four spots of the
;   current time period, from the table L2798. MOVE 26B7 uses the same table when the player
;   steps into the door.
; - L27C0 is the dungeon and tower command loop (MAIN 087A jumps here when D_004A >= 4): sleep,
;   "CMD:" with a time-out (PASS), then the arrow keys ADVANCE / TURN LEFT / TURN RIGHT /
;   RETREAT (with traps on advance), space = PASS, any other key to the letter commands (L09FB).
; - L29D2 draws the whole 64x64 map as a 256x128-pixel picture, 4x2 pixels per tile, for
;   V)iew with the magic helm (CMDMZ 43CC).
; Data: D_0000/D_0001 (position), D_0002/D_0003 (facing in the dungeon), D_0015/D_0016 (tiles
; ahead/behind, from VIEW3D), D_0025 (dungeon level), D_0066 (tools), D_026D (sleep turns),
; D_026E-D_0271 (direction keys), D_0049/D_006D-D_0070 (time period and time door state).
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0000:BYTE, D_0001:BYTE, D_0002:BYTE, D_0003:BYTE, D_0006:BYTE, D_0015:BYTE
	EXTRN D_0016:BYTE, D_0019:BYTE, D_001A:BYTE, D_001F:BYTE, D_0023:BYTE, D_0024:BYTE
	EXTRN D_0025:BYTE, D_0026:BYTE, D_0027:BYTE, D_0049:BYTE, D_0066:BYTE, D_006D:BYTE
	EXTRN D_006E:BYTE, D_006F:BYTE, D_0070:BYTE, D_026D:BYTE, D_026E:BYTE, D_026F:BYTE
	EXTRN D_0270:BYTE, D_0271:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L0711:NEAR, L09FB:NEAR, L0A30:NEAR, L0A33:NEAR, L0C62:NEAR, L2B65:NEAR
	EXTRN L4B4E:NEAR, L4F4D:NEAR, L4FDF:NEAR, L50B3:NEAR, L5217:NEAR, L5E3B:NEAR
	EXTRN L5EF2:NEAR
	PUBLIC L26F9, L2798, L27C0, L29D2
ASSUME CS:CODE, DS:DATA

;------------------------------------------------------------------------------
; L26F9: move the time door, once per surface turn (MAIN 0C30, D_004A = 0).
; Only on Earth (D_006D = 0). The countdown D_006F runs 8 turns; then the door
; tile C0h at spot D_006E of period D_0049 is replaced by the tile it covered
; (D_0070), D_006E steps to the next spot (0, 2, 4, 6: byte offsets of the x,y
; pairs in L2798) and, if the tile there is plain terrain (< 14h: water, marsh,
; grass, woods, mountains), it is saved in D_0070 and the door put on it.
; Otherwise (a monster or another object there) the door skips this round
; (perhaps what the manual means by "it will not reappear while you stand on it").
; In: D_0049, D_006D-D_0070. Out: map changed; AL = x, DI = y of the new door
; (unused by the caller). Uses: AX, BX, SI, DI, D_001F, D_0023/D_0024, D_0006.
;------------------------------------------------------------------------------
L26F9:	mov al, byte ptr D_006D	;@26F9
	cmp al, 0	; on Earth?	;@26FC
	je L2701	;@26FE
	ret	;@2700
L2701:	dec byte ptr D_006F	; door's turns left	;@2701
	je L2708	;@2705
	ret	;@2707
; take the door away from its current spot
L2708:	clc	;@2708
	mov al, byte ptr D_0049	;@2709
	add al, al	;@270C
	add al, al	;@270E
	add al, al	;@2710
	mov byte ptr D_001F, al	; period * 8 = row of L2798	;@2712
	adc al, byte ptr D_006E	;@2715
	mov ah, 0	;@2719
	mov di, ax	;@271B
	mov al, byte ptr cs:L2798[di]	;@271D
	mov byte ptr D_0023, al	; x	;@2722
	inc di	;@2725
	mov al, byte ptr cs:L2798[di]	;@2726
	mov byte ptr D_0024, al	; y	;@272B
	call L50B3	; AL = map tile at D_0023,D_0024	;@272E
	cmp al, 0C0h	; still a time door?	;@2731
	jne L2744	;@2733
	mov bh, 0	;@2735
	mov bl, 0	;@2737
	mov si, bx	;@2739
	mov al, byte ptr D_0070	;@273B
	mov bx, word ptr D_0006	;@273E
	mov byte ptr [bx+si], al	; put back the tile it covered	;@2742
; next spot
L2744:	mov al, 8	;@2744
	mov byte ptr D_006F, al	; 8 turns until the next move	;@2746
	inc byte ptr D_006E	;@2749
	inc byte ptr D_006E	;@274D
	mov al, byte ptr D_006E	;@2751
	and al, 7	; spots 0, 2, 4, 6	;@2754
	mov byte ptr D_006E, al	;@2756
	clc	;@2759
	adc al, byte ptr D_001F	;@275A
	mov ah, 0	;@275E
	mov di, ax	;@2760
	mov al, byte ptr cs:L2798[di]	;@2762
	mov byte ptr D_0023, al	;@2767
	inc di	;@276A
	mov al, byte ptr cs:L2798[di]	;@276B
	mov byte ptr D_0024, al	;@2770
	call L50B3	;@2773
	cmp al, 14h	; plain terrain?	;@2776
	jb L277B	;@2778
	ret	;@277A
L277B:	mov byte ptr D_0070, al	; remember the tile under the door	;@277B
	mov bh, 0	;@277E
	mov bl, 0	;@2780
	mov si, bx	;@2782
	mov al, 0C0h	;@2784
	mov bx, word ptr D_0006	;@2786
	mov byte ptr [bx+si], al	; place the time door	;@278A
	mov al, byte ptr D_0023	;@278C
	mov bh, 0	;@278F
	mov bl, byte ptr D_0024	;@2791
	mov di, bx	;@2795
	ret	;@2797

; L2798: time door spots, x,y pairs (map coordinates 0-3Fh), four per time period
; (8 bytes per period, D_0049 = 0-4, probably in the manual's order Legends, Pangea,
; B.C., A.D., Aftermath: period 0's doors sit side by side at the bottom of the map,
; as the manual says of Legends). Door n (D_006E/2) leads to the n-th other period
; (MOVE 26B7), where the player arrives at door n's spot of that period.
;   0: 1D,38 1F,38 21,38 23,38   1: 22,08 2F,1C 24,38 14,25   2: 10,10 30,18 2A,18 13,34
;   3: 38,34 1C,0C 21,17 14,34   4: 12,17 32,22 34,18 08,0B
L2798 label byte
	db 1Dh,38h,1Fh,38h,21h,38h,23h,38h,22h,8h,2Fh,1Ch,24h,38h,14h,25h	;@2798
	db 10h,10h,30h,18h,2Ah,18h,13h,34h,38h,34h,1Ch,0Ch,21h,17h,14h,34h	;@27A8
	db 12h,17h,32h,22h,34h,18h,8h,0Bh	;@27B8
;------------------------------------------------------------------------------
; L27C0: the dungeon and tower command loop, jumped to by MAIN 087A (after the
; stack is reset) when D_004A >= 4. Asleep (D_026D > 0): print "CMD: " and 20
; 'Z's slowly, one sleep turn less, end the turn. Awake: print "CMD: " and wait
; for a key with a time-out, after which the turn passes ("PASS"). The four
; direction keys (D_026E-D_0271, the arrows) are ADVANCE / RETREAT / TURN
; LEFT / TURN RIGHT, space is PASS, anything else goes to the letter command
; dispatcher L09FB. Every path ends at L0A33 (end of turn) or L0A30 (with the
; error sound). Does not return.
;------------------------------------------------------------------------------
L27C0:	nop	;@27C0
	mov al, byte ptr D_026D	;@27C1
	or al, al	; asleep?	;@27C4
	je L27F1	;@27C6
	call L4FDF	; "CMD: "	;@27C8
	db 43h,4Dh,44h,3Ah,20h,0h	;@27CB
	mov al, 14h	;@27D1
	mov byte ptr D_0027, al	; 20 'Z's	;@27D3
L27D6:	call L4FDF	; "Z"	;@27D6
	db 5Ah,0h	;@27D9
	mov bh, 0	;@27DB
	mov bl, 0FFh	;@27DD
	mov di, bx	;@27DF
L27E1:	dec di	; short CPU-speed dependent delay	;@27E1
	jne L27E1	;@27E2
	dec byte ptr D_0027	;@27E4
	jne L27D6	;@27E8
	dec byte ptr D_026D	; one sleep turn less	;@27EA
	jmp L0A33	;@27EE
; awake: wait for a key. DI counts the inner loop, SI = 2 rounds. DI is a word
; (6502 Y register originally): the first round runs 255 times but the second
; 65536 times, so the time-out is far longer than the 2 x 256 probably meant.
L27F1:	nop	;@27F1
	call L4FDF	; "CMD: "	;@27F2
	db 43h,4Dh,44h,3Ah,20h,0h	;@27F5
	mov bh, 0	;@27FB
	mov bl, 0FFh	;@27FD
	mov di, bx	;@27FF
	mov bh, 0	;@2801
	mov bl, 2	;@2803
	mov si, bx	;@2805
L2807:	mov bx, 0	;@2807
	call L0711	; calibrated delay (D_0580[0])	;@280A
	call L4F4D	; key? (AH = 0FFh if one was read)	;@280D
	cmp ah, 0FFh	;@2810
	je L2832	;@2813
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
	jne L2807	;@2822
	dec si	;@2824
	jne L2807	;@2825
	call L4FDF	; time-out: "PASS"	;@2827
	db 50h,41h,53h,53h,0h	;@282A
	jmp L0A33	;@282F
; a key: AL = its code
L2832:	nop	;@2832
	cmp al, byte ptr D_026E	; north key (up arrow) = advance	;@2833
	jne L283C	;@2837
	jmp L2861	;@2839
L283C:	cmp al, byte ptr D_0271	; west key (left arrow) = turn left	;@283C
	jne L2845	;@2840
	jmp L2912	;@2842
L2845:	cmp al, byte ptr D_0270	; east key (right arrow) = turn right	;@2845
	jne L284E	;@2849
	jmp L2944	;@284B
L284E:	cmp al, byte ptr D_026F	; south key (down arrow) = retreat	;@284E
	jne L2857	;@2852
	jmp L2977	;@2854
L2857:	cmp al, 20h	; space = pass	;@2857
	jne L285E	;@2859
	jmp L29BC	;@285B
L285E:	jmp L09FB	; letter commands A-Z	;@285E

;------------------------------------------------------------------------------
; L2861: ADVANCE. Blocked if the tile ahead (D_0015, from VIEW3D) has any of
; its low 4 bits set or is 80h (walls, doors?). Else steps by the facing
; D_0002/D_0003 (wrapping at 64) and, if a random byte < the dungeon level
; D_0025, springs a trap (never on level 0): the screen is cleared, sounds,
; and without tools (D_0066) the player dies (L0C62); with them one tool is
; used up.
;------------------------------------------------------------------------------
L2861:	nop	;@2861
	call L4FDF	; "ADVANCE"	;@2862
	db 41h,44h,56h,41h,4Eh,43h,45h,0h	;@2865
	mov al, byte ptr D_0015	;@286D
	and al, 0Fh	;@2870
	je L2884	;@2872
L2874:	call L4FDF	; "-BLOCKED!"	;@2874
	db 2Dh,42h,4Ch,4Fh,43h,4Bh,45h,44h,21h,0h	;@2877
	jmp L0A30	;@2881
L2884:	mov al, byte ptr D_0015	;@2884
	cmp al, 80h	;@2887
	je L2874	;@2889
	clc	;@288B
	mov al, byte ptr D_0000	;@288C
	adc al, byte ptr D_0002	; x += facing dx	;@288F
	and al, 3Fh	;@2893
	mov byte ptr D_0000, al	;@2895
	clc	;@2898
	mov al, byte ptr D_0001	;@2899
	adc al, byte ptr D_0003	; y += facing dy	;@289C
	and al, 3Fh	;@28A0
	mov byte ptr D_0001, al	;@28A2
	call L5217	;@28A5
	cmp al, byte ptr D_0025	; random < dungeon level: trap	;@28A8
	jb L28B1	;@28AC
	jmp L0A33	;@28AE
L28B1:	nop	;@28B1
	call L4B4E	; clear the graphics screen	;@28B2
	mov al, 0	;@28B5
	mov byte ptr D_0026, al	;@28B7
	call L4FDF	; "ARGH! A TRAP!"	;@28BA
	db 8Dh,41h,52h,47h,48h,21h,20h,41h,20h,54h,52h,41h,50h,21h,8Dh,0h	;@28BD
	call L5E3B	; sounds	;@28CD
	call L5EF2	;@28D0
	call L5EF2	;@28D3
	call L5EF2	;@28D6
	call L5EF2	;@28D9
	mov al, byte ptr D_0066	;@28DC
	or al, al	; any tools?	;@28DF
	jne L28E6	;@28E1
	jmp L0C62	; no: dead	;@28E3
L28E6:	call L4FDF	; "ESCAPED! BY USE OF TOOLS!"	;@28E6
	db 45h,53h,43h,41h,50h,45h,44h,21h,20h,42h,59h,20h,55h,53h,45h,20h	;@28E9
	db 4Fh,46h,20h,54h,4Fh,4Fh,4Ch,53h,21h,0h	;@28F9
	stc	;@2903
	mov al, byte ptr D_0066	;@2904
	cmc	;@2907
	sbb al, 1	;@2908
	das	; tools -= 1 (BCD; stc/cmc/sbb = 6502 SEC/SBC)	;@290A
	cmc	;@290B
	mov byte ptr D_0066, al	;@290C
	jmp L0A33	;@290F

;------------------------------------------------------------------------------
; L2912: TURN LEFT. The facing D_0002/D_0003 (dx, dy: 0, 1 or 0FFh) is turned
; a quarter anticlockwise: (dx, dy) -> (dy, -dx).
;------------------------------------------------------------------------------
L2912:	nop	;@2912
	call L4FDF	; "TURN LEFT"	;@2913
	db 54h,55h,52h,4Eh,20h,4Ch,45h,46h,54h,0h	;@2916
	mov al, byte ptr D_0003	;@2920
	cmp al, 0	;@2923
	je L2932	;@2925
	mov byte ptr D_0002, al	; facing north/south: dx = dy, dy = 0	;@2927
	mov al, 0	;@292A
	mov byte ptr D_0003, al	;@292C
	jmp L0A33	;@292F
L2932:	stc	;@2932
	cmc	;@2933
	sbb al, byte ptr D_0002	; facing east/west: dy = 0 - dx, dx = 0	;@2934
	cmc	;@2938
	mov byte ptr D_0003, al	;@2939
	mov al, 0	;@293C
	mov byte ptr D_0002, al	;@293E
	jmp L0A33	;@2941

;------------------------------------------------------------------------------
; L2944: TURN RIGHT: (dx, dy) -> (-dy, dx).
;------------------------------------------------------------------------------
L2944:	nop	;@2944
	call L4FDF	; "TURN RIGHT"	;@2945
	db 54h,55h,52h,4Eh,20h,52h,49h,47h,48h,54h,0h	;@2948
	mov al, byte ptr D_0002	;@2953
	or al, al	;@2956
	je L2965	;@2958
	mov byte ptr D_0003, al	; facing east/west: dy = dx, dx = 0	;@295A
	mov al, 0	;@295D
	mov byte ptr D_0002, al	;@295F
	jmp L0A33	;@2962
L2965:	stc	;@2965
	cmc	;@2966
	sbb al, byte ptr D_0003	; facing north/south: dx = 0 - dy, dy = 0	;@2967
	cmc	;@296B
	mov byte ptr D_0002, al	;@296C
	mov al, 0	;@296F
	mov byte ptr D_0003, al	;@2971
	jmp L0A33	;@2974

;------------------------------------------------------------------------------
; L2977: RETREAT. Blocked if the tile behind (D_0016) has bit 7 or any of the
; low 4 bits set (stricter than ADVANCE's test). Else steps back against the
; facing, wrapping at 64. No trap check.
;------------------------------------------------------------------------------
L2977:	nop	;@2977
	call L4FDF	; "RETREAT"	;@2978
	db 52h,45h,54h,52h,45h,41h,54h,0h	;@297B
	mov al, byte ptr D_0016	;@2983
	and al, 8Fh	;@2986
	je L299A	;@2988
	call L4FDF	; "-BLOCKED!"	;@298A
	db 2Dh,42h,4Ch,4Fh,43h,4Bh,45h,44h,21h,0h	;@298D
	jmp L0A30	;@2997
L299A:	nop	;@299A
	mov al, byte ptr D_0000	;@299B
	stc	;@299E
	cmc	;@299F
	sbb al, byte ptr D_0002	; x -= dx	;@29A0
	cmc	;@29A4
	and al, 3Fh	;@29A5
	mov byte ptr D_0000, al	;@29A7
	mov al, byte ptr D_0001	;@29AA
	stc	;@29AD
	cmc	;@29AE
	sbb al, byte ptr D_0003	; y -= dy	;@29AF
	cmc	;@29B3
	and al, 3Fh	;@29B4
	mov byte ptr D_0001, al	;@29B6
	jmp L0A33	;@29B9

; L29BC: space = PASS
L29BC:	call L4FDF	; "PASS"	;@29BC
	db 50h,41h,53h,53h,0h	;@29BF
	jmp L0A33	;@29C4
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h	; padding (never executed)	;@29C7
; L29D0/L29D1: CS variables, origin (x, y) of the helm picture. Always 0: L29D2
; clears them and nothing else writes them (a left-over of a scrolling view?).
L29D0 label byte
	db 0h	;@29D0
L29D1 label byte
	db 0h	;@29D1

;------------------------------------------------------------------------------
; L29D2: draw the whole 64x64 map (outdoor or town) as a picture for V)iew
; with the magic helm (CMDMZ 43CC): clears the screen, then for every tile
; (D_0019 = x, D_001A = y, 0-3Fh) plots a 4x2-pixel pattern at (4x, 2y)
; through L2B65 (DI = pixel column 0-3, SI = row 0-1 within the cell):
;   0 water: nothing                        4 marsh: 2 dots, top row
;   8 grass: 2 dots (diagonal)              0Ch woods: columns 1 and 3
;   10h mountains, 78h-0EFh: solid           70h (?): columns 0 and 2
;   anything else (towns, signs, ...): a 2x2 square in the middle
; In: map buffer. Out: picture drawn. Uses: AX, BX, SI, DI, D_0019/D_001A,
; D_0023/D_0024, D_0006.
;------------------------------------------------------------------------------
L29D2:	nop	;@29D2
	mov al, 0	;@29D3
	mov byte ptr cs:L29D0, al	; origin = 0, 0	;@29D5
	mov byte ptr cs:L29D1, al	;@29D9
	mov byte ptr D_0019, al	;@29DD
	mov byte ptr D_001A, al	;@29E0
	call L4B4E	; clear the graphics screen	;@29E3
L29E6:	mov al, byte ptr cs:L29D0	;@29E6
	clc	;@29EA
	adc al, byte ptr D_0019	;@29EB
	and al, 3Fh	;@29EF
	mov byte ptr D_0023, al	;@29F1
	mov al, byte ptr cs:L29D1	;@29F4
	clc	;@29F8
	adc al, byte ptr D_001A	;@29F9
	and al, 3Fh	;@29FD
	mov byte ptr D_0024, al	;@29FF
	call L50B3	; AL = tile, ZF if 0 (water)	;@2A02
	jne L2A0A	;@2A05
	jmp L2B46	;@2A07
L2A0A:	cmp al, 10h	; mountains: solid	;@2A0A
	je L2A2F	;@2A0C
	cmp al, 78h	;@2A0E
	jb L2A16	;@2A10
	cmp al, 0F0h	; 78h-0EFh: solid	;@2A12
	jb L2A2F	;@2A14
L2A16:	cmp al, 8	; grass	;@2A16
	je L2A89	;@2A18
	cmp al, 0Ch	; woods	;@2A1A
	je L2A6B	;@2A1C
	cmp al, 4	; marsh	;@2A1E
	je L2A29	;@2A20
	cmp al, 70h	;@2A22
	je L2A2C	;@2A24
	jmp L2B0A	; others: middle square	;@2A26
L2A29:	jmp L2AAA	;@2A29
L2A2C:	jmp L2ACB	;@2A2C
; solid: (0,0) (0,1) (2,1) (2,0), then falls into the woods and grass patterns
L2A2F:	mov bh, 0	;@2A2F
	mov bl, 0	;@2A31
	mov di, bx	;@2A33
	mov bh, 0	;@2A35
	mov bl, 0	;@2A37
	mov si, bx	;@2A39
	call L2B65	;@2A3B
	mov bh, 0	;@2A3E
	mov bl, 0	;@2A40
	mov di, bx	;@2A42
	mov bh, 0	;@2A44
	mov bl, 1	;@2A46
	mov si, bx	;@2A48
	call L2B65	;@2A4A
	mov bh, 0	;@2A4D
	mov bl, 2	;@2A4F
	mov di, bx	;@2A51
	mov bh, 0	;@2A53
	mov bl, 1	;@2A55
	mov si, bx	;@2A57
	call L2B65	;@2A59
	mov bh, 0	;@2A5C
	mov bl, 2	;@2A5E
	mov di, bx	;@2A60
	mov bh, 0	;@2A62
	mov bl, 0	;@2A64
	mov si, bx	;@2A66
	call L2B65	;@2A68
; woods: (1,1) (3,0), then the grass dots
L2A6B:	mov bh, 0	;@2A6B
	mov bl, 1	;@2A6D
	mov di, bx	;@2A6F
	mov bh, 0	;@2A71
	mov bl, 1	;@2A73
	mov si, bx	;@2A75
	call L2B65	;@2A77
	mov bh, 0	;@2A7A
	mov bl, 3	;@2A7C
	mov di, bx	;@2A7E
	mov bh, 0	;@2A80
	mov bl, 0	;@2A82
	mov si, bx	;@2A84
	call L2B65	;@2A86
; grass: (1,0) (3,1)
L2A89:	mov bh, 0	;@2A89
	mov bl, 1	;@2A8B
	mov di, bx	;@2A8D
	mov bh, 0	;@2A8F
	mov bl, 0	;@2A91
	mov si, bx	;@2A93
	call L2B65	;@2A95
	mov bh, 0	;@2A98
	mov bl, 3	;@2A9A
	mov di, bx	;@2A9C
	mov bh, 0	;@2A9E
	mov bl, 1	;@2AA0
	mov si, bx	;@2AA2
	call L2B65	;@2AA4
	jmp L2B46	;@2AA7
; marsh: (1,0) (3,0)
L2AAA:	mov bh, 0	;@2AAA
	mov bl, 1	;@2AAC
	mov di, bx	;@2AAE
	mov bh, 0	;@2AB0
	mov bl, 0	;@2AB2
	mov si, bx	;@2AB4
	call L2B65	;@2AB6
	mov bh, 0	;@2AB9
	mov bl, 3	;@2ABB
	mov di, bx	;@2ABD
	mov bh, 0	;@2ABF
	mov bl, 0	;@2AC1
	mov si, bx	;@2AC3
	call L2B65	;@2AC5
	jmp L2B46	;@2AC8
; tile 70h: (0,0) (0,1) (2,0) (2,1)
L2ACB:	mov bh, 0	;@2ACB
	mov bl, 0	;@2ACD
	mov di, bx	;@2ACF
	mov bh, 0	;@2AD1
	mov bl, 0	;@2AD3
	mov si, bx	;@2AD5
	call L2B65	;@2AD7
	mov bh, 0	;@2ADA
	mov bl, 0	;@2ADC
	mov di, bx	;@2ADE
	mov bh, 0	;@2AE0
	mov bl, 1	;@2AE2
	mov si, bx	;@2AE4
	call L2B65	;@2AE6
	mov bh, 0	;@2AE9
	mov bl, 2	;@2AEB
	mov di, bx	;@2AED
	mov bh, 0	;@2AEF
	mov bl, 0	;@2AF1
	mov si, bx	;@2AF3
	call L2B65	;@2AF5
	mov bh, 0	;@2AF8
	mov bl, 2	;@2AFA
	mov di, bx	;@2AFC
	mov bh, 0	;@2AFE
	mov bl, 1	;@2B00
	mov si, bx	;@2B02
	call L2B65	;@2B04
	jmp L2B46	;@2B07
; anything else: (1,0) (2,0) (2,1) (1,1)
L2B0A:	mov bh, 0	;@2B0A
	mov bl, 1	;@2B0C
	mov di, bx	;@2B0E
	mov bh, 0	;@2B10
	mov bl, 0	;@2B12
	mov si, bx	;@2B14
	call L2B65	;@2B16
	mov bh, 0	;@2B19
	mov bl, 2	;@2B1B
	mov di, bx	;@2B1D
	mov bh, 0	;@2B1F
	mov bl, 0	;@2B21
	mov si, bx	;@2B23
	call L2B65	;@2B25
	mov bh, 0	;@2B28
	mov bl, 2	;@2B2A
	mov di, bx	;@2B2C
	mov bh, 0	;@2B2E
	mov bl, 1	;@2B30
	mov si, bx	;@2B32
	call L2B65	;@2B34
	mov bh, 0	;@2B37
	mov bl, 1	;@2B39
	mov di, bx	;@2B3B
	mov bh, 0	;@2B3D
	mov bl, 1	;@2B3F
	mov si, bx	;@2B41
	call L2B65	;@2B43
; next tile: x = 0-3Fh within a row, then y = 0-3Fh
L2B46:	inc byte ptr D_0019	;@2B46
	mov al, byte ptr D_0019	;@2B4A
	and al, 3Fh	;@2B4D
	mov byte ptr D_0019, al	;@2B4F
	or al, al	;@2B52
	je L2B59	; end of the row	;@2B54
L2B56:	jmp L29E6	;@2B56
L2B59:	inc byte ptr D_001A	;@2B59
	mov al, byte ptr D_001A	;@2B5D
	cmp al, 40h	;@2B60
	jb L2B56	;@2B62
	ret	;@2B64
CODE ENDS
END
