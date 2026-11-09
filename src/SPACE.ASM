; SPACE.ASM: space flight: fuel, hyperwarp, planets.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 6999-7242.
;
; L6999 is entered from L)aunch (CMDAL 395E) when the player lifts off in the rocket and
; returns when the rocket has landed; the caller then loads the map that L720B and
; D_0049/D_004A select. In between, the screen is a CGA star field seen from the rocket:
; - Launching costs 1 fuel (D_00E5, BCD) and runs the hyperwarp animation (L6DFD) to the
;   coordinates of the planet left (tables L7012/L701C/L7026, indexed by D_006D). Without
;   reflect or power armour (D_0062 < 5) the player then explodes and the game hangs.
; - The space command loop (L6A79): the four direction keys only move the crosshair
;   (cosmetic), H = hyperwarp (1 fuel; asks for Xeno, Yako, Zabo digits 0-9), L = land.
; - After each hyperwarp L7030 finds where the rocket is: the sun at 4,4,4 (death), one of
;   the planets 0-9 (Earth .. Pluto, X) or deep space (D_006D = 0Ah, landing is denied).
; Data: D_04CA/D_04CB/D_04CC = Xeno/Yako/Zabo, D_04CD/D_050D = X and Y of 64 stars,
; D_04C3-D_04C9 star field work bytes, D_047B/D_047C = the point the stars fly away from
; (also the crosshair centre); the CS work variables L6990-L6998 (defined in VIEW3D).
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0031:BYTE, D_0049:BYTE, D_004A:BYTE, D_0062:BYTE, D_006D:BYTE, D_00E5:BYTE
	EXTRN D_026E:BYTE, D_026F:BYTE, D_0270:BYTE, D_0271:BYTE, D_0479:BYTE, D_047A:BYTE
	EXTRN D_047B:BYTE, D_047C:BYTE, D_04C3:BYTE, D_04C4:BYTE, D_04C5:BYTE, D_04C6:BYTE
	EXTRN D_04C7:BYTE, D_04C8:BYTE, D_04C9:BYTE, D_04CA:BYTE, D_04CB:BYTE, D_04CC:BYTE
	EXTRN D_04CD:BYTE, D_050D:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L0711:NEAR, L22BA:BYTE, L22CC:BYTE, L22F7:BYTE, L4A3E:NEAR, L4B4E:NEAR
	EXTRN L4B76:NEAR, L4BAA:NEAR, L4F4D:NEAR, L4FDF:NEAR, L51EB:NEAR, L53B5:NEAR
	EXTRN L53F4:NEAR, L5CD2:NEAR, L6990:BYTE, L6992:BYTE, L6994:BYTE, L6996:BYTE
	EXTRN L6997:BYTE, L6998:BYTE, L7242:NEAR, L7276:NEAR, L7289:NEAR
	PUBLIC L6999
ASSUME CS:CODE, DS:DATA
;------------------------------------------------------------------------------
; L6999: space flight, from launch to landing. Called from L)aunch (CMDAL 395E)
; with D_006D = the planet the rocket lifts off from. Switches to CGA graphics,
; takes 1 fuel, shows FUEL/XENO/YAKO/ZABO, scatters the stars and plays the
; hyperwarp to the planet's own coordinates, then checks the armour and enters
; the space command loop (L6A79). Returns (from the land command, L7185) with
; D_0049/D_004A and the file letter at L22BA set for the map to load; never
; returns if the player explodes or hits the sun.
;------------------------------------------------------------------------------
L6999:	nop	;@6999
	call L4A3E	; CGA graphics mode 4	;@699A
	mov byte ptr cs:L6998, 0FFh	; speaker is off	;@699D
	mov al, 80h	;@69A3
	mov byte ptr D_047B, al	;@69A5
	mov al, 40h	;@69A8
	mov byte ptr D_047C, al	; star centre = 80h,40h, mid view	;@69AA
	mov bh, 0	;@69AD
	mov bl, byte ptr D_006D	;@69AF
	mov di, bx	;@69B3
	mov al, byte ptr cs:L7012[di]	;@69B5
	mov byte ptr D_04CA, al	;@69BA
	mov al, byte ptr cs:L701C[di]	;@69BD
	mov byte ptr D_04CB, al	;@69C2
	mov al, byte ptr cs:L7026[di]	;@69C5
	mov byte ptr D_04CC, al	; start at the planet's coordinates	;@69CA
; fuel = fuel - 1 in BCD (stc/cmc/sbb/das/cmc = 6502 SEC; SED; SBC)
	mov al, byte ptr D_00E5	;@69CD
	stc	;@69D0
	cmc	;@69D1
	sbb al, 1	;@69D2
	das	;@69D4
	cmc	;@69D5
	mov byte ptr D_00E5, al	;@69D6
; the labels at column 30, rows 20-23
	mov al, 28h	;@69D9
	mov byte ptr D_0031, al	;@69DB
	mov bh, 0	;@69DE
	mov bl, 1Eh	;@69E0
	mov di, bx	;@69E2
	mov bh, 0	;@69E4
	mov bl, 14h	;@69E6
	mov si, bx	;@69E8
	call L51EB	;@69EA
	call L4FDF	;@69ED
	db 20h,20h,46h,55h,45h,4Ch,3Dh,0h	;@69F0
	mov bh, 0	;@69F8
	mov bl, 1Eh	;@69FA
	mov di, bx	;@69FC
	mov bh, 0	;@69FE
	mov bl, 15h	;@6A00
	mov si, bx	;@6A02
	call L51EB	;@6A04
	call L4FDF	;@6A07
	db 20h,20h,58h,45h,4Eh,4Fh,3Dh,0h	;@6A0A
	mov bh, 0	;@6A12
	mov bl, 1Eh	;@6A14
	mov di, bx	;@6A16
	mov bh, 0	;@6A18
	mov bl, 16h	;@6A1A
	mov si, bx	;@6A1C
	call L51EB	;@6A1E
	call L4FDF	;@6A21
	db 20h,20h,59h,41h,4Bh,4Fh,3Dh,0h	;@6A24
	mov bh, 0	;@6A2C
	mov bl, 1Eh	;@6A2E
	mov di, bx	;@6A30
	mov bh, 0	;@6A32
	mov bl, 17h	;@6A34
	mov si, bx	;@6A36
	call L51EB	;@6A38
	call L4FDF	;@6A3B
	db 20h,20h,5Ah,41h,42h,4Fh,3Dh,0h	;@6A3E
	mov al, 20h	;@6A46
	mov byte ptr D_0031, al	;@6A48
	call L6FA3	;@6A4B
	call L6D3E	;@6A4E
	call L6DFD	;@6A51
	mov al, byte ptr D_0062	;@6A54
	cmp al, 5	; armour 5 = reflect, 6 = power	;@6A57
	jae L6A79	;@6A59
	call L4FDF	;@6A5B
	db 8Dh,59h,4Fh,55h,20h,48h,41h,56h,45h,20h,45h,58h,50h,4Ch,4Fh,44h	;@6A5E
	db 45h,44h,21h,8Dh,8Dh,0h	;@6A6E
; death in space (also from L7030, the sun): speaker off and hang; the player must reboot
L6A74:	call L7289	;@6A74
L6A77:	jmp L6A77	; endless loop	;@6A77
;------------------------------------------------------------------------------
; L6A79: the space command loop. Shows fuel and coordinates, prints "CMD: " and
; animates the stars until a key is pressed (L4F4D returns AH = FFh then).
; Direction keys (D_026E-D_0271) move the crosshair off centre; H = hyperwarp
; (L6EC5), L = land (L7185); any other key re-centres the crosshair silently.
;------------------------------------------------------------------------------
L6A79:	nop	;@6A79
	call L6FA3	;@6A7A
	call L4FDF	;@6A7D
	db 43h,4Dh,44h,3Ah,20h,0h	;@6A80
L6A86:	call L6B3D	;@6A86
	mov bx, 14h	;@6A89
	call L0711	;@6A8C
	call L4F4D	;@6A8F
	cmp ah, 0FFh	; key pressed?	;@6A92
	jne L6A86	;@6A95
	cmp al, byte ptr D_0271	;@6A97
	jne L6AA0	;@6A9B
	jmp L6AD8	;@6A9D
L6AA0:	cmp al, byte ptr D_0270	;@6AA0
	jne L6AA9	;@6AA4
	jmp L6AF0	;@6AA6
L6AA9:	cmp al, byte ptr D_026E	;@6AA9
	jne L6AB2	;@6AAD
	jmp L6B0A	;@6AAF
L6AB2:	cmp al, byte ptr D_026F	;@6AB2
	jne L6ABB	;@6AB6
	jmp L6B24	;@6AB8
L6ABB:	cmp al, 48h	; 'H'	;@6ABB
	jne L6AC2	;@6ABD
	jmp L6EC5	;@6ABF
L6AC2:	cmp al, 4Ch	; 'L'	;@6AC2
	jne L6AC9	;@6AC4
	jmp L7185	;@6AC6
L6AC9:	call L6CC4	;@6AC9
	mov al, 80h	;@6ACC
	mov byte ptr D_047B, al	;@6ACE
	mov al, 40h	;@6AD1
	mov byte ptr D_047C, al	;@6AD3
	jmp L6A86	;@6AD6
; LEFT/RIGHT/CLIMB/DIVE: erase the crosshair and move the centre to the left, right,
; top or bottom of the view (the stars then stream from there); no other effect
L6AD8:	call L4FDF	;@6AD8
	db 4Ch,45h,46h,54h,8Dh,0h	;@6ADB
	call L6CC4	;@6AE1
	mov al, 20h	;@6AE4
	mov byte ptr D_047B, al	;@6AE6
	mov al, 40h	;@6AE9
	mov byte ptr D_047C, al	;@6AEB
	jmp L6A79	;@6AEE
L6AF0:	call L4FDF	;@6AF0
	db 52h,49h,47h,48h,54h,8Dh,0h	;@6AF3
	call L6CC4	;@6AFA
	mov al, 0DFh	;@6AFD
	mov byte ptr D_047B, al	;@6AFF
	mov al, 40h	;@6B02
	mov byte ptr D_047C, al	;@6B04
	jmp L6A79	;@6B07
L6B0A:	call L4FDF	;@6B0A
	db 43h,4Ch,49h,4Dh,42h,8Dh,0h	;@6B0D
	call L6CC4	;@6B14
	mov al, 10h	;@6B17
	mov byte ptr D_047C, al	;@6B19
	mov al, 80h	;@6B1C
	mov byte ptr D_047B, al	;@6B1E
	jmp L6A79	;@6B21
L6B24:	call L4FDF	;@6B24
	db 44h,49h,56h,45h,8Dh,0h	;@6B27
	call L6CC4	;@6B2D
	mov al, 6Fh	;@6B30
	mov byte ptr D_047C, al	;@6B32
	mov al, 80h	;@6B35
	mov byte ptr D_047B, al	;@6B37
	jmp L6A79	;@6B3A
;------------------------------------------------------------------------------
; L6B3D: one frame of the star field. Draws the crosshair, then moves each of the
; 64 stars (X in D_04CD[], Y in D_050D[], view 256 x 128) away from the centre
; D_047B,D_047C: the step is (distance / 16) + 1 pixels (tables L6CAC for X, L6CBC
; for Y), so near stars crawl and far ones race. A star leaving the view is put
; at a new pseudo-random place (L6C8C). D_04C7 sets the mode:
;   0     no erase: stars leave streaks; engine pitch sweeps (L6990 += L6992)
;   1     erase and redraw; engine pitch sweeps
;   >= 2  erase and redraw; random bleeps (L6994 countdown, L7242)
; and after the 64 stars the frame waits D_04C7 * 16 loop turns (CPU-speed
; dependent), so a larger D_04C7 = slower flight.
; In: D_047B/D_047C, D_04C7. Uses: AX, BX, CX, SI, DI, D_04C3-D_04C6, D_04C9.
;------------------------------------------------------------------------------
L6B3D:	nop	;@6B3D
	call L6D83	;@6B3E
	mov bh, 0	;@6B41
	mov bl, 0	;@6B43
	mov si, bx	;@6B45
; new X: right of the centre (no borrow) -> L6B7F, else move left
L6B47:	mov al, byte ptr D_04CD[si]	;@6B47
	mov byte ptr D_04C3, al	;@6B4B
	stc	;@6B4E
	cmc	;@6B4F
	sbb al, byte ptr D_047B	;@6B50
	cmc	; CF = 1: X >= centre	;@6B54
	jb L6B7F	;@6B55
	xor al, 0FFh	; distance - 1	;@6B57
	clc	;@6B59
	rcr al, 1	;@6B5A
	clc	;@6B5C
	rcr al, 1	;@6B5D
	clc	;@6B5F
	rcr al, 1	;@6B60
	clc	;@6B62
	rcr al, 1	;@6B63
	mov ah, 0	;@6B65
	mov di, ax	;@6B67
	mov al, byte ptr D_04C3	;@6B69
	stc	;@6B6C
	cmc	;@6B6D
	sbb al, byte ptr cs:L6CAC[di]	; X - step	;@6B6E
	cmc	;@6B73
	jb L6B79	;@6B74
	jmp L6C8C	; went past 0: new star	;@6B76
L6B79:	mov byte ptr D_04C5, al	;@6B79
	jmp L6BA0	;@6B7C
L6B7F:	clc	;@6B7F
	rcr al, 1	;@6B80
	clc	;@6B82
	rcr al, 1	;@6B83
	clc	;@6B85
	rcr al, 1	;@6B86
	clc	;@6B88
	rcr al, 1	;@6B89
	mov ah, 0	;@6B8B
	mov di, ax	;@6B8D
	mov al, byte ptr D_04C3	;@6B8F
	clc	;@6B92
	adc al, byte ptr cs:L6CAC[di]	; X + step	;@6B93
	mov byte ptr D_04C5, al	;@6B98
	jae L6BA0	;@6B9B
	jmp L6C8C	; went past 255: new star	;@6B9D
; new Y the same way, with L6CBC; outside 0-127 (sign bit) = new star
L6BA0:	mov al, byte ptr D_050D[si]	;@6BA0
	mov byte ptr D_04C4, al	;@6BA4
	stc	;@6BA7
	cmc	;@6BA8
	sbb al, byte ptr D_047C	;@6BA9
	cmc	;@6BAD
	jb L6BD5	;@6BAE
	xor al, 0FFh	;@6BB0
	clc	;@6BB2
	rcr al, 1	;@6BB3
	clc	;@6BB5
	rcr al, 1	;@6BB6
	clc	;@6BB8
	rcr al, 1	;@6BB9
	clc	;@6BBB
	rcr al, 1	;@6BBC
	mov ah, 0	;@6BBE
	mov di, ax	;@6BC0
	mov al, byte ptr D_04C4	;@6BC2
	stc	;@6BC5
	cmc	;@6BC6
	sbb al, byte ptr cs:L6CBC[di]	;@6BC7
	cmc	;@6BCC
	mov byte ptr D_04C6, al	;@6BCD
	jns L6BF6	;@6BD0
	jmp L6C8C	;@6BD2
L6BD5:	clc	;@6BD5
	rcr al, 1	;@6BD6
	clc	;@6BD8
	rcr al, 1	;@6BD9
	clc	;@6BDB
	rcr al, 1	;@6BDC
	clc	;@6BDE
	rcr al, 1	;@6BDF
	mov ah, 0	;@6BE1
	mov di, ax	;@6BE3
	mov al, byte ptr D_04C4	;@6BE5
	clc	;@6BE8
	adc al, byte ptr cs:L6CBC[di]	;@6BE9
	jns L6BF3	;@6BEE
	jmp L6C8C	;@6BF0
L6BF3:	mov byte ptr D_04C6, al	;@6BF3
; erase the star at its old place (not in mode 0), plot it at D_04C5,D_04C6
L6BF6:	mov bx, si	;@6BF6
	mov byte ptr D_04C9, bl	;@6BF8
	mov al, byte ptr D_04C7	;@6BFC
	or al, al	;@6BFF
	je L6C14	;@6C01
	mov al, byte ptr D_04CD[si]	;@6C03
	mov byte ptr D_0479, al	;@6C07
	mov al, byte ptr D_050D[si]	;@6C0A
	mov byte ptr D_047A, al	;@6C0E
	call L4BAA	; clear pixel	;@6C11
L6C14:	mov bh, 0	;@6C14
	mov bl, byte ptr D_04C9	;@6C16
	mov si, bx	;@6C1A
	mov al, byte ptr D_04C5	;@6C1C
	mov byte ptr D_0479, al	;@6C1F
	mov byte ptr D_04CD[si], al	;@6C22
	mov al, byte ptr D_04C6	;@6C26
	mov byte ptr D_047A, al	;@6C29
	mov byte ptr D_050D[si], al	;@6C2C
	call L4B76	; set pixel	;@6C30
; sound, once per star: modes 0/1 sweep the engine tone, mode >= 2 counts down to a bleep toggle
	cmp byte ptr D_04C7, 2	;@6C33
	jae L6C52	;@6C38
	mov bx, word ptr cs:L6990	;@6C3A
	add bx, word ptr cs:L6992	;@6C3F
	mov word ptr cs:L6990, bx	; tone divisor += step (-1 or +1)	;@6C44
	mov cx, 1	;@6C49
	call L5CD2	; set the tone, short delay	;@6C4C
	jmp L6C5C	;@6C4F
L6C52:	dec word ptr cs:L6994	;@6C52
	jne L6C5C	;@6C57
	call L7242	;@6C59
L6C5C:	mov bh, 0	;@6C5C
	mov bl, byte ptr D_04C9	;@6C5E
	mov si, bx	;@6C62
	inc si	;@6C64
	mov bx, si	;@6C65
	cmp bl, 40h	; all 64 stars done?	;@6C67
	je L6C76	;@6C6A
	mov al, byte ptr D_04C7	;@6C6C
	cmp al, 2	;@6C6F
	jae L6C73	; no effect: jumps to the next line either way	;@6C71
L6C73:	jmp L6B47	;@6C73
; end of frame: wait D_04C7 * 16 turns of an empty loop (CPU-speed dependent)
L6C76:	nop	;@6C76
	mov al, byte ptr D_04C7	;@6C77
	or al, al	;@6C7A
	je L6C8B	;@6C7C
	mov ah, 0	;@6C7E
	mov cx, ax	;@6C80
L6C82:	mov bx, 10h	;@6C82
L6C85:	dec bx	;@6C85
	jne L6C85	;@6C86
	dec cx	;@6C88
	jne L6C82	;@6C89
L6C8B:	ret	;@6C8B
; a star left the view: give it a new random place (X 0-255, Y 0-127) from L6D68.
; Its old place is still in D_04CD/D_050D[SI], so L6BF6 erases it correctly.
L6C8C:	nop	;@6C8C
	mov al, byte ptr D_04CD[si]	;@6C8D
	mov byte ptr D_04C3, al	;@6C91
	mov al, byte ptr D_050D[si]	;@6C94
	mov byte ptr D_04C4, al	;@6C98
	call L6D68	;@6C9B
	mov byte ptr D_04C5, al	;@6C9E
	call L6D68	;@6CA1
	and al, 7Fh	;@6CA4
	mov byte ptr D_04C6, al	;@6CA6
	jmp L6BF6	;@6CA9
; star step in pixels by distance from the centre / 16: X (16 entries), Y (8 entries)
L6CAC label byte
	db 1h,2h,3h,4h,5h,6h,7h,8h,9h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh,10h	;@6CAC
L6CBC label byte
	db 1h,2h,3h,4h,5h,6h,7h,8h	;@6CBC
;------------------------------------------------------------------------------
; L6CC4: erase the crosshair at D_047B,D_047C (the same pixels L6D83 draws):
; a vertical bar Y-3..Y+3 and a horizontal bar X-3..X+3 without its centre.
; Uses: AX, BX, SI, DI, D_0479/D_047A.
;------------------------------------------------------------------------------
L6CC4:	mov al, byte ptr D_047B	;@6CC4
	mov byte ptr D_0479, al	;@6CC7
	mov al, byte ptr D_047C	;@6CCA
	stc	;@6CCD
	cmc	;@6CCE
	sbb al, 3	;@6CCF
	cmc	;@6CD1
	mov byte ptr D_047A, al	;@6CD2
	call L4BAA	;@6CD5
	inc byte ptr D_047A	;@6CD8
	call L4BAA	;@6CDC
	inc byte ptr D_047A	;@6CDF
	call L4BAA	;@6CE3
	inc byte ptr D_047A	;@6CE6
	call L4BAA	;@6CEA
	inc byte ptr D_047A	;@6CED
	call L4BAA	;@6CF1
	inc byte ptr D_047A	;@6CF4
	call L4BAA	;@6CF8
	inc byte ptr D_047A	;@6CFB
	call L4BAA	;@6CFF
	mov al, byte ptr D_047B	;@6D02
	stc	;@6D05
	cmc	;@6D06
	sbb al, 3	;@6D07
	cmc	;@6D09
	mov byte ptr D_0479, al	;@6D0A
	mov al, byte ptr D_047C	;@6D0D
	mov byte ptr D_047A, al	;@6D10
	call L4BAA	;@6D13
	inc byte ptr D_0479	;@6D16
	call L4BAA	;@6D1A
	inc byte ptr D_0479	;@6D1D
	call L4BAA	;@6D21
	inc byte ptr D_0479	;@6D24
	inc byte ptr D_0479	;@6D28
	call L4BAA	;@6D2C
	inc byte ptr D_0479	;@6D2F
	call L4BAA	;@6D33
	inc byte ptr D_0479	;@6D36
	call L4BAA	;@6D3A
	ret	;@6D3D
;------------------------------------------------------------------------------
; L6D3E: restart the star generator (L6D5B) and give all 64 stars a pseudo-random
; place: X 0-255 in D_04CD[], Y 0-127 in D_050D[]. Nothing is drawn.
; Uses: AX, BX, SI.
;------------------------------------------------------------------------------
L6D3E:	call L6D5B	;@6D3E
	mov bh, 0	;@6D41
	mov bl, 3Fh	;@6D43
	mov si, bx	;@6D45
L6D47:	call L6D68	;@6D47
	mov byte ptr D_04CD[si], al	;@6D4A
	call L6D68	;@6D4E
	and al, 7Fh	;@6D51
	mov byte ptr D_050D[si], al	;@6D53
	dec si	;@6D57
	jns L6D47	;@6D58
	ret	;@6D5A
;------------------------------------------------------------------------------
; L6D5B: reset the star generator's seed (L6996 = 3Bh, L6997 = 67h), so the star
; field repeats the same pattern every time. Uses: nothing.
;------------------------------------------------------------------------------
L6D5B:	mov byte ptr cs:L6996, 3Bh	;@6D5B
	mov byte ptr cs:L6997, 67h	;@6D61
	ret	;@6D67
;------------------------------------------------------------------------------
; L6D68: the star field's own pseudo-random generator (not L5217): a two-byte
; additive (Fibonacci-like) sequence, new = L6996 + L6997 + 9 (+ carry), then
; L6997 = old L6996, L6996 = new. Out: AL = new value. Uses: AX.
;------------------------------------------------------------------------------
L6D68:	clc	;@6D68
	mov al, byte ptr cs:L6996	;@6D69
	adc al, 9	;@6D6D
	adc al, byte ptr cs:L6997	;@6D6F
	mov ah, byte ptr cs:L6996	;@6D74
	mov byte ptr cs:L6996, al	;@6D79
	mov byte ptr cs:L6997, ah	;@6D7D
	ret	;@6D82
;------------------------------------------------------------------------------
; L6D83: draw the crosshair at D_047B,D_047C with L4B76 (set pixel): a vertical
; bar Y-3..Y+3 and a horizontal bar X-3..X+3 without its centre pixel.
; Uses: AX, BX, SI, DI, D_0479/D_047A.
;------------------------------------------------------------------------------
L6D83:	mov al, byte ptr D_047B	;@6D83
	mov byte ptr D_0479, al	;@6D86
	mov al, byte ptr D_047C	;@6D89
	stc	;@6D8C
	cmc	;@6D8D
	sbb al, 3	;@6D8E
	cmc	;@6D90
	mov byte ptr D_047A, al	;@6D91
	call L4B76	;@6D94
	inc byte ptr D_047A	;@6D97
	call L4B76	;@6D9B
	inc byte ptr D_047A	;@6D9E
	call L4B76	;@6DA2
	inc byte ptr D_047A	;@6DA5
	call L4B76	;@6DA9
	inc byte ptr D_047A	;@6DAC
	call L4B76	;@6DB0
	inc byte ptr D_047A	;@6DB3
	call L4B76	;@6DB7
	inc byte ptr D_047A	;@6DBA
	call L4B76	;@6DBE
	mov al, byte ptr D_047B	;@6DC1
	stc	;@6DC4
	cmc	;@6DC5
	sbb al, 3	;@6DC6
	cmc	;@6DC8
	mov byte ptr D_0479, al	;@6DC9
	mov al, byte ptr D_047C	;@6DCC
	mov byte ptr D_047A, al	;@6DCF
	call L4B76	;@6DD2
	inc byte ptr D_0479	;@6DD5
	call L4B76	;@6DD9
	inc byte ptr D_0479	;@6DDC
	call L4B76	;@6DE0
	inc byte ptr D_0479	;@6DE3
	inc byte ptr D_0479	;@6DE7
	call L4B76	;@6DEB
	inc byte ptr D_0479	;@6DEE
	call L4B76	;@6DF2
	inc byte ptr D_0479	;@6DF5
	call L4B76	;@6DF9
	ret	;@6DFC
;------------------------------------------------------------------------------
; L6DFD: the hyperwarp itself, to the coordinates already in D_04CA-D_04CC.
; "HYPERWARP ENGAGED!", then three phases of 128, 128 and 63 star frames:
;  1. D_04C7 = 0: streaks; speaker on, tone divisor 2200h falling by 1 per star
;     (rising pitch);
;  2. D_04C7 = 1: the new coordinates are shown; the tone falls back;
;  3. D_04C7 = 2, 4, .. 7Eh: slowing down; random bleeps from now on.
; If the fuel left (D_00E5, BCD) has its two low bits set (low digit 3 or 7):
; "SHIP OFF COURSE!" and random coordinates 0-7 (from L6D68). Finally L7030 tells
; where the rocket is (and kills the player at the sun).
; Out: D_04C7 = 80h, D_04C8 = 0. Uses: all general registers.
;------------------------------------------------------------------------------
L6DFD:	call L4FDF	;@6DFD
	db 48h,59h,50h,45h,52h,57h,41h,52h,50h,20h,45h,4Eh,47h,41h,47h,45h	;@6E00
	db 44h,21h,8Dh,0h	;@6E10
; phase 1: 128 frames of streaks, pitch rising
	mov al, 80h	;@6E14
	mov byte ptr D_04C8, al	;@6E16
	mov al, 0	;@6E19
	mov byte ptr D_04C7, al	;@6E1B
	call L6D5B	;@6E1E
	mov bx, 2200h	;@6E21
	mov word ptr cs:L6990, bx	;@6E24
	mov word ptr cs:L6992, 0FFFFh	;@6E29
	call L7276	; speaker on at divisor BX = 2200h	;@6E30
L6E33:	call L6B3D	;@6E33
	mov bx, 16h	;@6E36
	call L0711	;@6E39
	dec byte ptr D_04C8	;@6E3C
	jne L6E33	;@6E40
; phase 2: show the new coordinates, 128 frames, pitch falling
	mov al, 80h	;@6E42
	mov byte ptr D_04C8, al	;@6E44
	mov al, 1	;@6E47
	mov byte ptr D_04C7, al	;@6E49
	call L6FA3	;@6E4C
	call L6D5B	;@6E4F
	mov word ptr cs:L6992, 1	;@6E52
L6E59:	call L6B3D	;@6E59
	mov bx, 16h	;@6E5C
	call L0711	;@6E5F
	dec byte ptr D_04C8	;@6E62
	jne L6E59	;@6E66
; phase 3: slow down until D_04C7 reaches 80h; the first star turns the engine tone off
	inc byte ptr D_04C7	;@6E68
	mov word ptr cs:L6994, 1	;@6E6C
L6E73:	call L6B3D	;@6E73
	mov bx, 18h	;@6E76
	call L0711	;@6E79
	inc byte ptr D_04C7	;@6E7C
	inc byte ptr D_04C7	;@6E80
	jns L6E73	;@6E84
; off course if fuel bits 0 and 1 are both set
	mov al, byte ptr D_00E5	;@6E86
	clc	;@6E89
	rcr al, 1	;@6E8A
	jae L6EC0	;@6E8C
	clc	;@6E8E
	rcr al, 1	;@6E8F
	jae L6EC0	;@6E91
	call L4FDF	;@6E93
	db 53h,48h,49h,50h,20h,4Fh,46h,46h,20h,43h,4Fh,55h,52h,53h,45h,21h	;@6E96
	db 8Dh,0h	;@6EA6
	call L6D68	;@6EA8
	and al, 7	;@6EAB
	mov byte ptr D_04CA, al	;@6EAD
	call L6D68	;@6EB0
	and al, 7	;@6EB3
	mov byte ptr D_04CB, al	;@6EB5
	call L6D68	;@6EB8
	and al, 7	;@6EBB
	mov byte ptr D_04CC, al	;@6EBD
L6EC0:	nop	;@6EC0
	call L7030	;@6EC1
	ret	;@6EC4
;------------------------------------------------------------------------------
; L6EC5: space command H (hyperwarp), jumped to from the command loop. "NO FUEL!"
; if D_00E5 = 0; else takes 1 fuel (BCD), re-centres the crosshair, asks
; "HYPERWARP TO:" XENO=, YAKO=, ZABO= (one digit 0-9 each, L6F7F), says "PREPARE
; FOR HYPERWARP!", speeds the stars up (D_04C7 down to 2), cruises 64 frames,
; hyperwarps (L6DFD) and goes back to the command loop.
;------------------------------------------------------------------------------
L6EC5:	mov al, byte ptr D_00E5	;@6EC5
	or al, al	;@6EC8
	jne L6EDC	;@6ECA
	call L4FDF	;@6ECC
	db 4Eh,4Fh,20h,46h,55h,45h,4Ch,21h,8Dh,0h	;@6ECF
	jmp L6A79	;@6ED9
L6EDC:	stc	;@6EDC
	cmc	;@6EDD
	sbb al, 1	;@6EDE
	das	; fuel - 1, BCD	;@6EE0
	cmc	;@6EE1
	mov byte ptr D_00E5, al	;@6EE2
	call L6CC4	;@6EE5
	mov al, 80h	;@6EE8
	mov byte ptr D_047B, al	;@6EEA
	mov al, 40h	;@6EED
	mov byte ptr D_047C, al	;@6EEF
	call L4FDF	;@6EF2
	db 48h,59h,50h,45h,52h,57h,41h,52h,50h,20h,54h,4Fh,3Ah,8Dh,58h,45h	;@6EF5
	db 4Eh,4Fh,3Dh,0h	;@6F05
	call L6F7F	;@6F09
	mov byte ptr D_04CA, al	;@6F0C
	call L4FDF	;@6F0F
	db 20h,59h,41h,4Bh,4Fh,3Dh,0h	;@6F12
	call L6F7F	;@6F19
	mov byte ptr D_04CB, al	;@6F1C
	call L4FDF	;@6F1F
	db 20h,5Ah,41h,42h,4Fh,3Dh,0h	;@6F22
	call L6F7F	;@6F29
	mov byte ptr D_04CC, al	;@6F2C
	call L4FDF	;@6F2F
	db 8Dh,50h,52h,45h,50h,41h,52h,45h,20h,46h,4Fh,52h,20h,48h,59h,50h	;@6F32
	db 45h,52h,57h,41h,52h,50h,21h,8Dh,0h	;@6F42
	call L6D5B	;@6F4B
; speed up: D_04C7 (80h after the last hyperwarp) down to 2, one frame each
L6F4E:	call L6B3D	;@6F4E
	mov bx, 1Ah	;@6F51
	call L0711	;@6F54
	dec byte ptr D_04C7	;@6F57
	mov al, byte ptr D_04C7	;@6F5B
	cmp al, 2	;@6F5E
	jne L6F4E	;@6F60
; cruise 64 frames at full speed
	mov al, 40h	;@6F62
	mov byte ptr D_04C8, al	;@6F64
	call L6D5B	;@6F67
L6F6A:	call L6B3D	;@6F6A
	mov bx, 1Ah	;@6F6D
	call L0711	;@6F70
	dec byte ptr D_04C8	;@6F73
	jne L6F6A	;@6F77
	call L6DFD	;@6F79
	jmp L6A79	;@6F7C
;------------------------------------------------------------------------------
; L6F7F: read one coordinate digit, animating the stars while waiting. Keys other
; than '0'-'9' are ignored; the digit is echoed (L53F4).
; Out: AL = 0-9. Uses: AX, BX, CX, SI, DI.
;------------------------------------------------------------------------------
L6F7F:	call L6B3D	;@6F7F
	mov bx, 14h	;@6F82
	call L0711	;@6F85
	call L4F4D	;@6F88
	cmp ah, 0FFh	; key pressed?	;@6F8B
	jne L6F7F	;@6F8E
	cmp al, 30h	;@6F90
	jb L6F7F	;@6F92
	cmp al, 39h	;@6F94
	ja L6F7F	;@6F96
	push ax	;@6F98
	call L53F4	; echo the digit	;@6F99
	pop ax	;@6F9C
	stc	;@6F9D
	cmc	;@6F9E
	sbb al, 30h	; '0'-'9' -> 0-9	;@6F9F
	cmc	;@6FA1
	ret	;@6FA2
;------------------------------------------------------------------------------
; L6FA3: show the fuel (D_00E5) and Xeno/Yako/Zabo (D_04CA-D_04CC) as two digits
; each (L53B5) at column 37, rows 20-23, next to the labels L6999 printed; then
; set the text window right edge to 31 and the cursor to column 0, row 23 (the
; command line). Uses: AX, BX, SI, DI.
;------------------------------------------------------------------------------
L6FA3:	nop	;@6FA3
	mov al, 28h	;@6FA4
	mov byte ptr D_0031, al	;@6FA6
	mov bh, 0	;@6FA9
	mov bl, 25h	;@6FAB
	mov di, bx	;@6FAD
	mov bh, 0	;@6FAF
	mov bl, 14h	;@6FB1
	mov si, bx	;@6FB3
	call L51EB	;@6FB5
	mov al, byte ptr D_00E5	;@6FB8
	call L53B5	;@6FBB
	mov bh, 0	;@6FBE
	mov bl, 25h	;@6FC0
	mov di, bx	;@6FC2
	mov bh, 0	;@6FC4
	mov bl, 15h	;@6FC6
	mov si, bx	;@6FC8
	call L51EB	;@6FCA
	mov al, byte ptr D_04CA	;@6FCD
	call L53B5	;@6FD0
	mov bh, 0	;@6FD3
	mov bl, 25h	;@6FD5
	mov di, bx	;@6FD7
	mov bh, 0	;@6FD9
	mov bl, 16h	;@6FDB
	mov si, bx	;@6FDD
	call L51EB	;@6FDF
	mov al, byte ptr D_04CB	;@6FE2
	call L53B5	;@6FE5
	mov bh, 0	;@6FE8
	mov bl, 25h	;@6FEA
	mov di, bx	;@6FEC
	mov bh, 0	;@6FEE
	mov bl, 17h	;@6FF0
	mov si, bx	;@6FF2
	call L51EB	;@6FF4
	mov al, byte ptr D_04CC	;@6FF7
	call L53B5	;@6FFA
	mov al, 1Fh	;@6FFD
	mov byte ptr D_0031, al	;@6FFF
	mov bh, 0	;@7002
	mov bl, 0	;@7004
	mov di, bx	;@7006
	mov bh, 0	;@7008
	mov bl, 17h	;@700A
	mov si, bx	;@700C
	call L51EB	;@700E
	ret	;@7011
; the planets' Xeno, Yako and Zabo coordinates, indexed by planet number:
;          Earth Mercury Venus Mars Jupiter Saturn Uranus Neptune Pluto X
L7012 label byte
	db 6h,5h,3h,6h,1h,2h,9h,4h,0h,9h	;@7012
L701C label byte
	db 6h,4h,3h,2h,3h,8h,4h,0h,1h,9h	;@701C
L7026 label byte
	db 6h,5h,4h,3h,4h,5h,6h,5h,4h,9h	;@7026
;------------------------------------------------------------------------------
; L7030: find where the rocket is from Xeno/Yako/Zabo (D_04CA-D_04CC).
; 4,4,4 = the sun: "YOU HIT THE SUN!", screen cleared, death (L6A74, no return).
; A planet's coordinates: D_006D = its number, "YOU ARE ORBITING <planet>."
; Anything else: "YOU ARE IN DEEP SPACE.", D_006D = 0Ah.
; Out: D_006D. Uses: AX, BX, DI.
;------------------------------------------------------------------------------
L7030:	nop	;@7030
	mov al, byte ptr D_04CA	;@7031
	cmp al, 4	;@7034
	jne L7063	;@7036
	mov al, byte ptr D_04CB	;@7038
	cmp al, 4	;@703B
	jne L7063	;@703D
	mov al, byte ptr D_04CC	;@703F
	cmp al, 4	;@7042
	jne L7063	;@7044
	call L4FDF	;@7046
	db 8Dh,8Dh,59h,4Fh,55h,20h,48h,49h,54h,20h,54h,48h,45h,20h,53h,55h	;@7049
	db 4Eh,21h,8Dh,0h	;@7059
	call L4B4E	; clear the graphics screen	;@705D
	jmp L6A74	;@7060
; search the planet table from 9 (X) down to 0 (Earth)
L7063:	nop	;@7063
	mov bh, 0	;@7064
	mov bl, 9	;@7066
	mov di, bx	;@7068
L706A:	mov al, byte ptr cs:L7012[di]	;@706A
	cmp al, byte ptr D_04CA	;@706F
	jne L708B	;@7073
	mov al, byte ptr cs:L701C[di]	;@7075
	cmp al, byte ptr D_04CB	;@707A
	jne L708B	;@707E
	mov al, byte ptr cs:L7026[di]	;@7080
	cmp al, byte ptr D_04CC	;@7085
	je L70B1	;@7089
L708B:	dec di	;@708B
	jns L706A	;@708C
	call L4FDF	;@708E
	db 59h,4Fh,55h,20h,41h,52h,45h,20h,49h,4Eh,20h,44h,45h,45h,50h,20h	;@7091
	db 53h,50h,41h,43h,45h,2Eh,8Dh,0h	;@70A1
	mov al, 0Ah	;@70A9
	mov byte ptr D_006D, al	; 0Ah = deep space	;@70AB
	jmp L7184	;@70AE
L70B1:	mov ax, di	;@70B1
	mov byte ptr D_006D, al	;@70B3
	call L4FDF	;@70B6
	db 59h,4Fh,55h,20h,41h,52h,45h,20h,4Fh,52h,42h,49h,54h,49h,4Eh,47h	;@70B9
	db 20h,0h	;@70C9
; print the planet's name (a chain of compares, not a table)
	mov al, byte ptr D_006D	;@70CB
	cmp al, 0	;@70CE
	je L70F5	;@70D0
	cmp al, 1	;@70D2
	je L7103	;@70D4
	cmp al, 2	;@70D6
	je L7113	;@70D8
	cmp al, 3	;@70DA
	je L7121	;@70DC
	cmp al, 4	;@70DE
	je L712E	;@70E0
	cmp al, 5	;@70E2
	je L713E	;@70E4
	cmp al, 6	;@70E6
	je L714D	;@70E8
	cmp al, 7	;@70EA
	je L715C	;@70EC
	cmp al, 8	;@70EE
	je L716C	;@70F0
	jmp L717A	;@70F2
L70F5:	call L4FDF	;@70F5
	db 45h,41h,52h,54h,48h,2Eh,8Dh,0h	;@70F8
	jmp L7184	;@7100
L7103:	call L4FDF	;@7103
	db 4Dh,45h,52h,43h,55h,52h,59h,2Eh,8Dh,0h	;@7106
	jmp L7184	;@7110
L7113:	call L4FDF	;@7113
	db 56h,45h,4Eh,55h,53h,2Eh,8Dh,0h	;@7116
	jmp L7184	;@711E
L7121:	call L4FDF	;@7121
	db 4Dh,41h,52h,53h,2Eh,8Dh,0h	;@7124
	jmp L7184	;@712B
L712E:	call L4FDF	;@712E
	db 4Ah,55h,50h,49h,54h,45h,52h,2Eh,8Dh,0h	;@7131
	jmp L7184	;@713B
L713E:	call L4FDF	;@713E
	db 53h,41h,54h,55h,52h,4Eh,2Eh,8Dh,0h	;@7141
	jmp L7184	;@714A
L714D:	call L4FDF	;@714D
	db 55h,52h,41h,4Eh,55h,53h,2Eh,8Dh,0h	;@7150
	jmp L7184	;@7159
L715C:	call L4FDF	;@715C
	db 4Eh,45h,50h,54h,55h,4Eh,45h,2Eh,8Dh,0h	;@715F
	jmp L7184	;@7169
L716C:	call L4FDF	;@716C
	db 50h,4Ch,55h,54h,4Fh,2Eh,8Dh,0h	;@716F
	jmp L7184	;@7177
L717A:	call L4FDF	;@717A
	db 58h,2Eh,8Dh,0h	; "X." = Planet X	;@717D
	jmp L7184	;@7181
L7184:	ret	;@7184
;------------------------------------------------------------------------------
; L7185: space command L (land), jumped to from the command loop. Re-centres the
; crosshair, "LANDING REQUESTED!", tells where the rocket is (L7030) and, in deep
; space, "REQUEST DENIED!" (back to the command loop). Otherwise selects the map
; file for the caller (CMDAL 3961 loads it with L2290) and returns from L6999:
;   Earth:  letter 'X', D_0049 = 4, D_004A = 0 -> MAPX40, MONX40 (Earth, period 4)
;   others: letter 'G', D_0049 = planet, D_004A = 0 -> MAPG10 .. MAPG90
; The speaker is turned off. The 1989 release patched out two disk-swap prompts
; here (see the dead bytes below).
;------------------------------------------------------------------------------
L7185:	call L6CC4	;@7185
	mov al, 80h	;@7188
	mov byte ptr D_047B, al	;@718A
	mov al, 40h	;@718D
	mov byte ptr D_047C, al	;@718F
	call L4FDF	;@7192
	db 4Ch,41h,4Eh,44h,49h,4Eh,47h,20h,52h,45h,51h,55h,45h,53h,54h,45h	;@7195
	db 44h,21h,8Dh,0h	;@71A5
	call L7030	;@71A9
	mov al, byte ptr D_006D	;@71AC
	cmp al, 0Ah	; deep space?	;@71AF
	jne L71CA	;@71B1
	call L4FDF	;@71B3
	db 52h,45h,51h,55h,45h,53h,54h,20h,44h,45h,4Eh,49h,45h,44h,21h,8Dh	;@71B6
	db 0h	;@71C6
	jmp L6A79	;@71C7
L71CA:	nop	;@71CA
	cmp al, 0	; Earth?	;@71CB
	jne L7207	;@71CD
; Dead bytes: this was "call L4FDF" (E8 0D DE) + "(INSERT PLAYER DISK)"; the 1989
; patch turned E8 0D into "jmp short" over the rest of the string.
	jmp short L71E8	;@71CF
	db 0DEh,28h,49h,4Eh,53h,45h,52h,54h,20h,50h,4Ch,41h,59h,45h,52h,20h	;@71D1
	db 44h,49h,53h,4Bh,29h,8Dh,0h	;@71E1
L71E8:	call L6B3D	;@71E8
	mov bx, 14h	;@71EB
	call L0711	;@71EE
	mov al, 58h	; 'X' = Earth's files	;@71F1
	call L720B	;@71F3
	nop	; patched out (a call, probably the disk-swap wait)	;@71F6
	nop	;@71F7
	nop	;@71F8
	mov al, 0	;@71F9
	mov byte ptr D_004A, al	;@71FB
	mov al, 4	;@71FE
	mov byte ptr D_0049, al	; Earth, time period 4	;@7200
	call L7289	;@7203
	ret	;@7206
; Same patch: "call L4FDF" (E8 D5 DD) + a "(..." prompt (probably another disk request)
; became "jmp short"; the new routine L720B was written into the middle of the old string.
L7207:	jmp short L7222	;@7207
	db 0DDh,28h	; dead: last byte of the old call, '('	;@7209
;------------------------------------------------------------------------------
; L720B: set the letter of the MAP?xx, MON?xx and TLK?xx file names (L22BA,
; L22CC, L22F7 in LOAD): 'X' = Earth, 'G' = the other planets.
; In: AL = letter. Uses: nothing else (self-modifying: writes into LOAD's FCB names).
;------------------------------------------------------------------------------
L720B:	mov byte ptr cs:L22BA, al	;@720B
	mov byte ptr cs:L22CC, al	;@720F
	mov byte ptr cs:L22F7, al	;@7213
	ret	;@7217
	db 0h,2Dh,55h,44h,49h,43h,2Dh,29h,8Dh,0h	; dead: tail of the old prompt "-UDIC-)"	;@7218
L7222:	call L6B3D	;@7222
	mov bx, 14h	;@7225
	call L0711	;@7228
	mov al, 47h	; 'G' = the other planets' files	;@722B
	call L720B	;@722D
	nop	; patched out, as at 71F6	;@7230
	nop	;@7231
	nop	;@7232
	mov al, 0	;@7233
	mov byte ptr D_004A, al	;@7235
	mov al, byte ptr D_006D	;@7238
	mov byte ptr D_0049, al	; first digit = planet number	;@723B
	call L7289	;@723E
	ret	;@7241
CODE ENDS
END
