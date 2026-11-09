; ENDGAME.ASM: the end of Minax and the end of the game.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 7242-740B.
;
; Two unrelated pieces:
; - 7242-729B: the PC speaker helpers of space flight (SPACE.ASM calls them): L7276 turns the
;   speaker on, L7289 turns it off, L7242 toggles the random "computer bleeps" heard while
;   cruising. The CS byte L6998 (in VIEW3D) remembers the state: FFh = speaker off, 0 = on;
;   the CS word L6994 counts the star moves until the next toggle.
; - L72A0: the end of the game, called from the attack code (CMDAL 2CCD) when the monster
;   just killed is Minax (type 40h). It wrecks the map, loads MAPX30, prints the victory text
;   and then flies over the map forever; it never returns (the player has to reboot).
; Data: D_0000/D_0001 (player position), D_0012/D_0013, the map buffer at D_0472.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0000:BYTE, D_0001:BYTE, D_0006:BYTE, D_0012:BYTE, D_0013:BYTE, D_001F:BYTE
	EXTRN D_0020:BYTE, D_0023:BYTE, D_0024:BYTE, D_0031:BYTE, D_0472:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L0711:NEAR, L4FDF:NEAR, L50B3:NEAR, L5217:NEAR, L52CA:NEAR, L5AB1:NEAR
	EXTRN L5CB2:NEAR, L5CD2:NEAR, L5CE4:NEAR, L5ED7:NEAR, L5FA6:NEAR, L6994:BYTE
	EXTRN L6998:BYTE
	PUBLIC L7242, L7276, L7289, L72A0
ASSUME CS:CODE, DS:DATA
;------------------------------------------------------------------------------
; L7242: toggle the space "bleeps". Called by the star field (L6B3D in SPACE) each
; time the countdown L6994 runs out while cruising. If the speaker is on, turn it
; off for E0h star moves; if it is off, turn it on at a random pitch (divisor
; 0100h-2000h) for 18h star moves.
; In: L6998 (speaker state). Out: L6994 reloaded. Uses: AX, BX, CX.
;------------------------------------------------------------------------------
L7242:	nop	;@7242
	cmp byte ptr cs:L6998, 0FFh	; speaker off?	;@7243
	je L7258	;@7249
	call L7289	;@724B
	mov word ptr cs:L6994, 0E0h	; silent for E0h star moves	;@724E
	jmp L7275	;@7255
L7258:	call L5217	;@7258
	mov ah, al	;@725B
	and ax, 1F00h	;@725D
	add ax, 100h	; BX = random divisor 0100h-2000h	;@7260
	mov bx, ax	;@7263
	mov cx, 1	;@7265
	call L7276	;@7268
	call L5CD2	; set the pitch, short delay	;@726B
	mov word ptr cs:L6994, 18h	; bleep for 18h star moves	;@726E
L7275:	ret	;@7275
;------------------------------------------------------------------------------
; L7276: turn the PC speaker on (tone divisor BX, via L5CB2) unless it is on
; already. In: BX = PIT divisor. Out: L6998 = 0 (on). Uses: AX.
;------------------------------------------------------------------------------
L7276:	nop	;@7276
	cmp byte ptr cs:L6998, 0FFh	;@7277
	jne L7288	;@727D
	call L5CB2	;@727F
	mov byte ptr cs:L6998, 0	;@7282
L7288:	ret	;@7288
;------------------------------------------------------------------------------
; L7289: turn the PC speaker off (L5CE4) unless it is off already.
; Out: L6998 = FFh (off). Uses: AX.
;------------------------------------------------------------------------------
L7289:	nop	;@7289
	cmp byte ptr cs:L6998, 0	;@728A
	jne L729B	;@7290
	call L5CE4	;@7292
	mov byte ptr cs:L6998, 0FFh	;@7295
L729B:	ret	;@729B
	db 0h,0h,0h,0h	; unused padding	;@729C
;------------------------------------------------------------------------------
; L72A0: Minax is dead: the end of the game. Called from the attack code (CMDAL
; 2CCD) when the killed monster's type is 40h. Never returns.
; 1. "MINAX IS DEAD!! ALL HER WORKS SHALL DIE!"
; 2. 64 times: a sound (L5ED7), 64 random cells of the 64x64 map set to tile 74h,
;    redraw the map window.
; 3. "YOU FEEL A STRANGE FORCE!", sounds, load MAPX30 (Earth, time period 3?) into
;    the map buffer, then the victory text (the game's font draws "][" as the
;    roman II, so "ULTIMA ][" = Ultima II).
; 4. Put the player (as tile 28h, the rocket) at 0,0 of a wrapping map and scroll
;    over it diagonally forever.
;------------------------------------------------------------------------------
L72A0:	nop	;@72A0
	mov byte ptr D_0031, 28h	; text window right edge = column 40	;@72A1
	call L4FDF	;@72A6
	db 8Dh,8Dh,20h,20h,20h,20h,20h,4Dh,49h,4Eh,41h,58h,20h,49h,53h,20h	;@72A9
	db 44h,45h,41h,44h,21h,21h,8Dh,41h,4Ch,4Ch,20h,48h,45h,52h,20h,57h	;@72B9
	db 4Fh,52h,4Bh,53h,20h,53h,48h,41h,4Ch,4Ch,20h,44h,49h,45h,21h,8Dh	;@72C9
	db 0h	;@72D9
; 64 rounds (D_001F) of 64 random cells (D_0020) each
	mov al, 40h	;@72DA
	mov byte ptr D_001F, al	;@72DC
L72DF:	call L5ED7	;@72DF
	mov al, 40h	;@72E2
	mov byte ptr D_0020, al	;@72E4
L72E7:	call L5217	;@72E7
	and al, 3Fh	;@72EA
	mov byte ptr D_0023, al	; random x 0-63	;@72EC
	call L5217	;@72EF
	and al, 3Fh	;@72F2
	mov byte ptr D_0024, al	; random y 0-63	;@72F4
	call L50B3	; D_0006 -> map cell, SI = 0	;@72F7
	mov al, 74h	; tile 74h (what it shows: ?)	;@72FA
	mov bx, word ptr D_0006	;@72FC
	mov byte ptr [bx+si], al	;@7300
	dec byte ptr D_0020	;@7302
	jne L72E7	;@7306
	call L5AB1	; redraw the map window	;@7308
	mov bx, 0Eh	;@730B
	call L0711	; delay	;@730E
	dec byte ptr D_001F	;@7311
	jne L72DF	;@7315
	call L4FDF	;@7317
	db 8Dh,59h,4Fh,55h,20h,46h,45h,45h,4Ch,20h,41h,20h,53h,54h,52h,41h	;@731A
	db 4Eh,47h,45h,20h,46h,4Fh,52h,43h,45h,21h,0h	;@732A
	call L5FA6	;@7335
	mov ah, 27h	; FCB random block read	;@7338
	mov cx, 1000h	; 4 KB, the whole 64x64 map	;@733A
	mov dx, word ptr D_0472	; into the map buffer	;@733D
	call L52CA	;@7341
	db 4Dh,41h,50h,58h,33h,30h,20h,20h	;@7344
	call L5FA6	;@734C
	call L4FDF	;@734F
	db 8Dh,8Dh,59h,4Fh,55h,20h,48h,41h,56h,45h,20h,53h,41h,56h,45h,44h	;@7352
	db 20h,54h,48h,45h,20h,55h,4Eh,49h,56h,45h,52h,53h,45h,2Ch,8Dh,41h	;@7362
	db 4Eh,44h,20h,43h,4Fh,4Dh,50h,4Ch,45h,54h,45h,44h,20h,55h,4Ch,54h	;@7372
	db 49h,4Dh,41h,20h,5Dh,5Bh,21h,20h,53h,45h,45h,4Bh,8Dh,4Eh,4Fh,57h	;@7382
	db 20h,54h,4Fh,20h,43h,4Fh,4Eh,51h,55h,45h,52h,20h,57h,49h,43h,4Bh	;@7392
	db 45h,44h,20h,45h,58h,4Fh,44h,55h,53h,2Ch,8Dh,0h	;@73A2
	call L4FDF	;@73AE
	db 46h,4Fh,55h,4Eh,44h,20h,49h,4Eh,20h,55h,4Ch,54h,49h,4Dh,41h,20h	;@73B1
	db 5Dh,49h,5Bh,2Dh,44h,20h,5Dh,49h,49h,5Bh,2Dh,50h,21h,0h	;@73C1
	mov al, 0FFh	;@73CF
	mov byte ptr D_0012, al	; FFh = the map wraps around	;@73D1
	mov al, 28h	;@73D4
	mov byte ptr D_0013, al	; player shown as tile 28h (rocket)	;@73D6
	mov al, 0	;@73D9
	mov byte ptr D_0000, al	;@73DB
	mov byte ptr D_0001, al	;@73DE
; Forever: y+1 every frame, x+1 every 4th frame (when y's low two bits are 0), both
; modulo 64; redraw the map around the player and wait.
L73E1:	clc	;@73E1
	mov al, byte ptr D_0001	;@73E2
	adc al, 1	;@73E5
	and al, 3Fh	;@73E7
	mov byte ptr D_0001, al	;@73E9
	clc	;@73EC
	rcr al, 1	;@73ED
	jb L7400	;@73EF
	clc	;@73F1
	rcr al, 1	;@73F2
	jb L7400	;@73F4
	mov al, byte ptr D_0000	;@73F6
	adc al, 1	; CF = 0 here: x+1	;@73F9
	and al, 3Fh	;@73FB
	mov byte ptr D_0000, al	;@73FD
L7400:	call L5AB1	;@7400
	mov bx, 6	;@7403
	call L0711	; delay	;@7406
	jmp L73E1	;@7409
CODE ENDS
END
