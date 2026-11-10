; SPACE.ASM: space flight: fuel, hyperwarp, planets.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 6999-7242.
;
; SpaceFlight is entered from L)aunch (CMDAL 395E) when the player lifts off in the rocket and
; returns when the rocket has landed; the caller then loads the map that SetMapFileLetter and
; TimeZone/MapType select. In between, the screen is a CGA star field seen from the rocket:
; - Launching costs 1 fuel (TriLithium, BCD) and runs the hyperwarp animation (Hyperwarp) to the
;   coordinates of the planet left (tables PlanetXenoTbl/PlanetYakoTbl/PlanetZaboTbl, indexed by Planet). Without
;   reflect or power armour (WornArmour < 5) the player then explodes and the game hangs.
; - The space command loop (SpaceCmdLoop): the four direction keys only move the crosshair
;   (cosmetic), H = hyperwarp (1 fuel; asks for Xeno, Yako, Zabo digits 0-9), L = land.
; - After each hyperwarp FindOrbit finds where the rocket is: the sun at 4,4,4 (death), one of
;   the planets 0-9 (Earth .. Pluto, X) or deep space (Planet = 0Ah, landing is denied).
; Data: Xeno/Yako/Zabo = Xeno/Yako/Zabo, StarXs/StarYs = X and Y of 64 stars,
; StarCurX-StarIndex star field work bytes, LineEndX/LineEndY = the point the stars fly away from
; (also the crosshair centre); the CS work variables SpaceToneDivisor-SpeakerIsOff (defined in VIEW3D).
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN TextRightCol:BYTE, TimeZone:BYTE, MapType:BYTE, WornArmour:BYTE, Planet:BYTE, TriLithium:BYTE
	EXTRN KeyNorth:BYTE, KeySouth:BYTE, KeyEast:BYTE, KeyWest:BYTE, PlotX:BYTE, PlotY:BYTE
	EXTRN LineEndX:BYTE, LineEndY:BYTE, StarCurX:BYTE, StarCurY:BYTE, StarNewX:BYTE, StarNewY:BYTE
	EXTRN StarMode:BYTE, WarpFrames:BYTE, StarIndex:BYTE, Xeno:BYTE, Yako:BYTE, Zabo:BYTE
	EXTRN StarXs:BYTE, StarYs:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN SpeedDelay:NEAR, FcbMapLetter:BYTE, FcbMonLetter:BYTE, FcbTlkLetter:BYTE, SetGraphicsMode:NEAR
	EXTRN ClearViewArea:NEAR
	EXTRN PlotPixel:NEAR, ErasePixel:NEAR, ReadKey:NEAR, PrintInline:NEAR, SetCursor:NEAR, PrintBcdByte:NEAR
	EXTRN PutChar:NEAR, HoldTone:NEAR, SpaceToneDivisor:BYTE, SpaceToneStep:BYTE, BleepCountdown:BYTE
	EXTRN StarRndSeed:BYTE
	EXTRN StarRndSeed2:BYTE, SpeakerIsOff:BYTE, ToggleSpaceBleep:NEAR, SpaceSpeakerOn:NEAR, SpaceSpeakerOff:NEAR
	PUBLIC SpaceFlight
ASSUME CS:CODE, DS:DATA
;------------------------------------------------------------------------------
; SpaceFlight: space flight, from launch to landing. Called from L)aunch (CMDAL 395E)
; with Planet = the planet the rocket lifts off from. Switches to CGA graphics,
; takes 1 fuel, shows FUEL/XENO/YAKO/ZABO, scatters the stars and plays the
; hyperwarp to the planet's own coordinates, then checks the armour and enters
; the space command loop (SpaceCmdLoop). Returns (from the land command, SpaceCmdLand) with
; TimeZone/MapType and the file letter at FcbMapLetter set for the map to load; never
; returns if the player explodes or hits the sun.
;------------------------------------------------------------------------------
SpaceFlight:	nop	;@6999
	call SetGraphicsMode	; CGA graphics mode 4	;@699A
	mov byte ptr cs:SpeakerIsOff, 0FFh	; speaker is off	;@699D
	mov al, 80h	;@69A3
	mov byte ptr LineEndX, al	;@69A5
	mov al, 40h	;@69A8
	mov byte ptr LineEndY, al	; star centre = 80h,40h, mid view	;@69AA
	mov bh, 0	;@69AD
	mov bl, byte ptr Planet	;@69AF
	mov di, bx	;@69B3
	mov al, byte ptr cs:PlanetXenoTbl[di]	;@69B5
	mov byte ptr Xeno, al	;@69BA
	mov al, byte ptr cs:PlanetYakoTbl[di]	;@69BD
	mov byte ptr Yako, al	;@69C2
	mov al, byte ptr cs:PlanetZaboTbl[di]	;@69C5
	mov byte ptr Zabo, al	; start at the planet's coordinates	;@69CA
; fuel = fuel - 1 in BCD (stc/cmc/sbb/das/cmc = 6502 SEC; SED; SBC)
	mov al, byte ptr TriLithium	;@69CD
	stc	;@69D0
	cmc	;@69D1
	sbb al, 1	;@69D2
	das	;@69D4
	cmc	;@69D5
	mov byte ptr TriLithium, al	;@69D6
; the labels at column 30, rows 20-23
	mov al, 28h	;@69D9
	mov byte ptr TextRightCol, al	;@69DB
	mov bh, 0	;@69DE
	mov bl, 1Eh	;@69E0
	mov di, bx	;@69E2
	mov bh, 0	;@69E4
	mov bl, 14h	;@69E6
	mov si, bx	;@69E8
	call SetCursor	;@69EA
	call PrintInline	;@69ED
	db 20h,20h,46h,55h,45h,4Ch,3Dh,0h	;@69F0
	mov bh, 0	;@69F8
	mov bl, 1Eh	;@69FA
	mov di, bx	;@69FC
	mov bh, 0	;@69FE
	mov bl, 15h	;@6A00
	mov si, bx	;@6A02
	call SetCursor	;@6A04
	call PrintInline	;@6A07
	db 20h,20h,58h,45h,4Eh,4Fh,3Dh,0h	;@6A0A
	mov bh, 0	;@6A12
	mov bl, 1Eh	;@6A14
	mov di, bx	;@6A16
	mov bh, 0	;@6A18
	mov bl, 16h	;@6A1A
	mov si, bx	;@6A1C
	call SetCursor	;@6A1E
	call PrintInline	;@6A21
	db 20h,20h,59h,41h,4Bh,4Fh,3Dh,0h	;@6A24
	mov bh, 0	;@6A2C
	mov bl, 1Eh	;@6A2E
	mov di, bx	;@6A30
	mov bh, 0	;@6A32
	mov bl, 17h	;@6A34
	mov si, bx	;@6A36
	call SetCursor	;@6A38
	call PrintInline	;@6A3B
	db 20h,20h,5Ah,41h,42h,4Fh,3Dh,0h	;@6A3E
	mov al, 20h	;@6A46
	mov byte ptr TextRightCol, al	;@6A48
	call ShowFuelCoords	;@6A4B
	call ScatterStars	;@6A4E
	call Hyperwarp	;@6A51
	mov al, byte ptr WornArmour	;@6A54
	cmp al, 5	; armour 5 = reflect, 6 = power	;@6A57
	jae SpaceCmdLoop	;@6A59
	call PrintInline	;@6A5B
	db 8Dh,59h,4Fh,55h,20h,48h,41h,56h,45h,20h,45h,58h,50h,4Ch,4Fh,44h	;@6A5E
	db 45h,44h,21h,8Dh,8Dh,0h	;@6A6E
; death in space (also from FindOrbit, the sun): speaker off and hang; the player must reboot
Space_Die:	call SpaceSpeakerOff	;@6A74
Space_Hang:	jmp Space_Hang	; endless loop	;@6A77
;------------------------------------------------------------------------------
; SpaceCmdLoop: the space command loop. Shows fuel and coordinates, prints "CMD: " and
; animates the stars until a key is pressed (ReadKey returns AH = FFh then).
; Direction keys (KeyNorth-KeyWest) move the crosshair off centre; H = hyperwarp
; (SpaceCmdHyperwarp), L = land (SpaceCmdLand); any other key re-centres the crosshair silently.
;------------------------------------------------------------------------------
SpaceCmdLoop:	nop	;@6A79
	call ShowFuelCoords	;@6A7A
	call PrintInline	;@6A7D
	db 43h,4Dh,44h,3Ah,20h,0h	;@6A80
SpaceCmd_Poll:	call MoveStars	;@6A86
	mov bx, 14h	;@6A89
	call SpeedDelay	;@6A8C
	call ReadKey	;@6A8F
	cmp ah, 0FFh	; key pressed?	;@6A92
	jne SpaceCmd_Poll	;@6A95
	cmp al, byte ptr KeyWest	;@6A97
	jne SpaceCmd_KeyEast	;@6A9B
	jmp SpaceCmd_Left	;@6A9D
SpaceCmd_KeyEast:	cmp al, byte ptr KeyEast	;@6AA0
	jne SpaceCmd_KeyNorth	;@6AA4
	jmp SpaceCmd_Right	;@6AA6
SpaceCmd_KeyNorth:	cmp al, byte ptr KeyNorth	;@6AA9
	jne SpaceCmd_KeySouth	;@6AAD
	jmp SpaceCmd_Climb	;@6AAF
SpaceCmd_KeySouth:	cmp al, byte ptr KeySouth	;@6AB2
	jne SpaceCmd_KeyH	;@6AB6
	jmp SpaceCmd_Dive	;@6AB8
SpaceCmd_KeyH:	cmp al, 48h	; 'H'	;@6ABB
	jne SpaceCmd_KeyL	;@6ABD
	jmp SpaceCmdHyperwarp	;@6ABF
SpaceCmd_KeyL:	cmp al, 4Ch	; 'L'	;@6AC2
	jne SpaceCmd_Recenter	;@6AC4
	jmp SpaceCmdLand	;@6AC6
SpaceCmd_Recenter:	call EraseCrosshair	;@6AC9
	mov al, 80h	;@6ACC
	mov byte ptr LineEndX, al	;@6ACE
	mov al, 40h	;@6AD1
	mov byte ptr LineEndY, al	;@6AD3
	jmp SpaceCmd_Poll	;@6AD6
; LEFT/RIGHT/CLIMB/DIVE: erase the crosshair and move the centre to the left, right,
; top or bottom of the view (the stars then stream from there); no other effect
SpaceCmd_Left:	call PrintInline	;@6AD8
	db 4Ch,45h,46h,54h,8Dh,0h	;@6ADB
	call EraseCrosshair	;@6AE1
	mov al, 20h	;@6AE4
	mov byte ptr LineEndX, al	;@6AE6
	mov al, 40h	;@6AE9
	mov byte ptr LineEndY, al	;@6AEB
	jmp SpaceCmdLoop	;@6AEE
SpaceCmd_Right:	call PrintInline	;@6AF0
	db 52h,49h,47h,48h,54h,8Dh,0h	;@6AF3
	call EraseCrosshair	;@6AFA
	mov al, 0DFh	;@6AFD
	mov byte ptr LineEndX, al	;@6AFF
	mov al, 40h	;@6B02
	mov byte ptr LineEndY, al	;@6B04
	jmp SpaceCmdLoop	;@6B07
SpaceCmd_Climb:	call PrintInline	;@6B0A
	db 43h,4Ch,49h,4Dh,42h,8Dh,0h	;@6B0D
	call EraseCrosshair	;@6B14
	mov al, 10h	;@6B17
	mov byte ptr LineEndY, al	;@6B19
	mov al, 80h	;@6B1C
	mov byte ptr LineEndX, al	;@6B1E
	jmp SpaceCmdLoop	;@6B21
SpaceCmd_Dive:	call PrintInline	;@6B24
	db 44h,49h,56h,45h,8Dh,0h	;@6B27
	call EraseCrosshair	;@6B2D
	mov al, 6Fh	;@6B30
	mov byte ptr LineEndY, al	;@6B32
	mov al, 80h	;@6B35
	mov byte ptr LineEndX, al	;@6B37
	jmp SpaceCmdLoop	;@6B3A
;------------------------------------------------------------------------------
; MoveStars: one frame of the star field. Draws the crosshair, then moves each of the
; 64 stars (X in StarXs[], Y in StarYs[], view 256 x 128) away from the centre
; LineEndX,LineEndY: the step is (distance / 16) + 1 pixels (tables StarStepXTbl for X, StarStepYTbl
; for Y), so near stars crawl and far ones race. A star leaving the view is put
; at a new pseudo-random place (MoveStars_NewStar). StarMode sets the mode:
;   0     no erase: stars leave streaks; engine pitch sweeps (SpaceToneDivisor += SpaceToneStep)
;   1     erase and redraw; engine pitch sweeps
;   >= 2  erase and redraw; random bleeps (BleepCountdown countdown, ToggleSpaceBleep)
; and after the 64 stars the frame waits StarMode * 16 loop turns (CPU-speed
; dependent), so a larger StarMode = slower flight.
; In: LineEndX/LineEndY, StarMode. Uses: AX, BX, CX, SI, DI, StarCurX-StarNewY, StarIndex.
;------------------------------------------------------------------------------
MoveStars:	nop	;@6B3D
	call DrawCrosshair	;@6B3E
	mov bh, 0	;@6B41
	mov bl, 0	;@6B43
	mov si, bx	;@6B45
; new X: right of the centre (no borrow) -> MoveStars_RightX, else move left
MoveStars_Loop:	mov al, byte ptr StarXs[si]	;@6B47
	mov byte ptr StarCurX, al	;@6B4B
	stc	;@6B4E
	cmc	;@6B4F
	sbb al, byte ptr LineEndX	;@6B50
	cmc	; CF = 1: X >= centre	;@6B54
	jb MoveStars_RightX	;@6B55
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
	mov al, byte ptr StarCurX	;@6B69
	stc	;@6B6C
	cmc	;@6B6D
	sbb al, byte ptr cs:StarStepXTbl[di]	; X - step	;@6B6E
	cmc	;@6B73
	jb MoveStars_StoreLeftX	;@6B74
	jmp MoveStars_NewStar	; went past 0: new star	;@6B76
MoveStars_StoreLeftX:	mov byte ptr StarNewX, al	;@6B79
	jmp MoveStars_Y	;@6B7C
MoveStars_RightX:	clc	;@6B7F
	rcr al, 1	;@6B80
	clc	;@6B82
	rcr al, 1	;@6B83
	clc	;@6B85
	rcr al, 1	;@6B86
	clc	;@6B88
	rcr al, 1	;@6B89
	mov ah, 0	;@6B8B
	mov di, ax	;@6B8D
	mov al, byte ptr StarCurX	;@6B8F
	clc	;@6B92
	adc al, byte ptr cs:StarStepXTbl[di]	; X + step	;@6B93
	mov byte ptr StarNewX, al	;@6B98
	jae MoveStars_Y	;@6B9B
	jmp MoveStars_NewStar	; went past 255: new star	;@6B9D
; new Y the same way, with StarStepYTbl; outside 0-127 (sign bit) = new star
MoveStars_Y:	mov al, byte ptr StarYs[si]	;@6BA0
	mov byte ptr StarCurY, al	;@6BA4
	stc	;@6BA7
	cmc	;@6BA8
	sbb al, byte ptr LineEndY	;@6BA9
	cmc	;@6BAD
	jb MoveStars_BelowY	;@6BAE
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
	mov al, byte ptr StarCurY	;@6BC2
	stc	;@6BC5
	cmc	;@6BC6
	sbb al, byte ptr cs:StarStepYTbl[di]	;@6BC7
	cmc	;@6BCC
	mov byte ptr StarNewY, al	;@6BCD
	jns MoveStars_Plot	;@6BD0
	jmp MoveStars_NewStar	;@6BD2
MoveStars_BelowY:	clc	;@6BD5
	rcr al, 1	;@6BD6
	clc	;@6BD8
	rcr al, 1	;@6BD9
	clc	;@6BDB
	rcr al, 1	;@6BDC
	clc	;@6BDE
	rcr al, 1	;@6BDF
	mov ah, 0	;@6BE1
	mov di, ax	;@6BE3
	mov al, byte ptr StarCurY	;@6BE5
	clc	;@6BE8
	adc al, byte ptr cs:StarStepYTbl[di]	;@6BE9
	jns MoveStars_StoreBelowY	;@6BEE
	jmp MoveStars_NewStar	;@6BF0
MoveStars_StoreBelowY:	mov byte ptr StarNewY, al	;@6BF3
; erase the star at its old place (not in mode 0), plot it at StarNewX,StarNewY
MoveStars_Plot:	mov bx, si	;@6BF6
	mov byte ptr StarIndex, bl	;@6BF8
	mov al, byte ptr StarMode	;@6BFC
	or al, al	;@6BFF
	je MoveStars_PlotNew	;@6C01
	mov al, byte ptr StarXs[si]	;@6C03
	mov byte ptr PlotX, al	;@6C07
	mov al, byte ptr StarYs[si]	;@6C0A
	mov byte ptr PlotY, al	;@6C0E
	call ErasePixel	; clear pixel	;@6C11
MoveStars_PlotNew:	mov bh, 0	;@6C14
	mov bl, byte ptr StarIndex	;@6C16
	mov si, bx	;@6C1A
	mov al, byte ptr StarNewX	;@6C1C
	mov byte ptr PlotX, al	;@6C1F
	mov byte ptr StarXs[si], al	;@6C22
	mov al, byte ptr StarNewY	;@6C26
	mov byte ptr PlotY, al	;@6C29
	mov byte ptr StarYs[si], al	;@6C2C
	call PlotPixel	; set pixel	;@6C30
; sound, once per star: modes 0/1 sweep the engine tone, mode >= 2 counts down to a bleep toggle
	cmp byte ptr StarMode, 2	;@6C33
	jae MoveStars_Bleep	;@6C38
	mov bx, word ptr cs:SpaceToneDivisor	;@6C3A
	add bx, word ptr cs:SpaceToneStep	;@6C3F
	mov word ptr cs:SpaceToneDivisor, bx	; tone divisor += step (-1 or +1)	;@6C44
	mov cx, 1	;@6C49
	call HoldTone	; set the tone, short delay	;@6C4C
	jmp MoveStars_Next	;@6C4F
MoveStars_Bleep:	dec word ptr cs:BleepCountdown	;@6C52
	jne MoveStars_Next	;@6C57
	call ToggleSpaceBleep	;@6C59
MoveStars_Next:	mov bh, 0	;@6C5C
	mov bl, byte ptr StarIndex	;@6C5E
	mov si, bx	;@6C62
	inc si	;@6C64
	mov bx, si	;@6C65
	cmp bl, 40h	; all 64 stars done?	;@6C67
	je MoveStars_Delay	;@6C6A
	mov al, byte ptr StarMode	;@6C6C
	cmp al, 2	;@6C6F
	jae MoveStars_NextStar	; no effect: jumps to the next line either way	;@6C71
MoveStars_NextStar:	jmp MoveStars_Loop	;@6C73
; end of frame: wait StarMode * 16 turns of an empty loop (CPU-speed dependent)
MoveStars_Delay:	nop	;@6C76
	mov al, byte ptr StarMode	;@6C77
	or al, al	;@6C7A
	je MoveStars_Done	;@6C7C
	mov ah, 0	;@6C7E
	mov cx, ax	;@6C80
MoveStars_DelayOuter:	mov bx, 10h	;@6C82
MoveStars_DelayInner:	dec bx	;@6C85
	jne MoveStars_DelayInner	;@6C86
	dec cx	;@6C88
	jne MoveStars_DelayOuter	;@6C89
MoveStars_Done:	ret	;@6C8B
; a star left the view: give it a new random place (X 0-255, Y 0-127) from StarRnd.
; Its old place is still in StarXs/StarYs[SI], so MoveStars_Plot erases it correctly.
MoveStars_NewStar:	nop	;@6C8C
	mov al, byte ptr StarXs[si]	;@6C8D
	mov byte ptr StarCurX, al	;@6C91
	mov al, byte ptr StarYs[si]	;@6C94
	mov byte ptr StarCurY, al	;@6C98
	call StarRnd	;@6C9B
	mov byte ptr StarNewX, al	;@6C9E
	call StarRnd	;@6CA1
	and al, 7Fh	;@6CA4
	mov byte ptr StarNewY, al	;@6CA6
	jmp MoveStars_Plot	;@6CA9
; star step in pixels by distance from the centre / 16: X (16 entries), Y (8 entries)
StarStepXTbl label byte
	db 1h,2h,3h,4h,5h,6h,7h,8h,9h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh,10h	;@6CAC
StarStepYTbl label byte
	db 1h,2h,3h,4h,5h,6h,7h,8h	;@6CBC
;------------------------------------------------------------------------------
; EraseCrosshair: erase the crosshair at LineEndX,LineEndY (the same pixels DrawCrosshair draws):
; a vertical bar Y-3..Y+3 and a horizontal bar X-3..X+3 without its centre.
; Uses: AX, BX, SI, DI, PlotX/PlotY.
;------------------------------------------------------------------------------
EraseCrosshair:	mov al, byte ptr LineEndX	;@6CC4
	mov byte ptr PlotX, al	;@6CC7
	mov al, byte ptr LineEndY	;@6CCA
	stc	;@6CCD
	cmc	;@6CCE
	sbb al, 3	;@6CCF
	cmc	;@6CD1
	mov byte ptr PlotY, al	;@6CD2
	call ErasePixel	;@6CD5
	inc byte ptr PlotY	;@6CD8
	call ErasePixel	;@6CDC
	inc byte ptr PlotY	;@6CDF
	call ErasePixel	;@6CE3
	inc byte ptr PlotY	;@6CE6
	call ErasePixel	;@6CEA
	inc byte ptr PlotY	;@6CED
	call ErasePixel	;@6CF1
	inc byte ptr PlotY	;@6CF4
	call ErasePixel	;@6CF8
	inc byte ptr PlotY	;@6CFB
	call ErasePixel	;@6CFF
	mov al, byte ptr LineEndX	;@6D02
	stc	;@6D05
	cmc	;@6D06
	sbb al, 3	;@6D07
	cmc	;@6D09
	mov byte ptr PlotX, al	;@6D0A
	mov al, byte ptr LineEndY	;@6D0D
	mov byte ptr PlotY, al	;@6D10
	call ErasePixel	;@6D13
	inc byte ptr PlotX	;@6D16
	call ErasePixel	;@6D1A
	inc byte ptr PlotX	;@6D1D
	call ErasePixel	;@6D21
	inc byte ptr PlotX	;@6D24
	inc byte ptr PlotX	;@6D28
	call ErasePixel	;@6D2C
	inc byte ptr PlotX	;@6D2F
	call ErasePixel	;@6D33
	inc byte ptr PlotX	;@6D36
	call ErasePixel	;@6D3A
	ret	;@6D3D
;------------------------------------------------------------------------------
; ScatterStars: restart the star generator (ResetStarRnd) and give all 64 stars a pseudo-random
; place: X 0-255 in StarXs[], Y 0-127 in StarYs[]. Nothing is drawn.
; Uses: AX, BX, SI.
;------------------------------------------------------------------------------
ScatterStars:	call ResetStarRnd	;@6D3E
	mov bh, 0	;@6D41
	mov bl, 3Fh	;@6D43
	mov si, bx	;@6D45
ScatterStars_Loop:	call StarRnd	;@6D47
	mov byte ptr StarXs[si], al	;@6D4A
	call StarRnd	;@6D4E
	and al, 7Fh	;@6D51
	mov byte ptr StarYs[si], al	;@6D53
	dec si	;@6D57
	jns ScatterStars_Loop	;@6D58
	ret	;@6D5A
;------------------------------------------------------------------------------
; ResetStarRnd: reset the star generator's seed (StarRndSeed = 3Bh, StarRndSeed2 = 67h), so the star
; field repeats the same pattern every time. Uses: nothing.
;------------------------------------------------------------------------------
ResetStarRnd:	mov byte ptr cs:StarRndSeed, 3Bh	;@6D5B
	mov byte ptr cs:StarRndSeed2, 67h	;@6D61
	ret	;@6D67
;------------------------------------------------------------------------------
; StarRnd: the star field's own pseudo-random generator (not Random): a two-byte
; additive (Fibonacci-like) sequence, new = StarRndSeed + StarRndSeed2 + 9 (+ carry), then
; StarRndSeed2 = old StarRndSeed, StarRndSeed = new. Out: AL = new value. Uses: AX.
;------------------------------------------------------------------------------
StarRnd:	clc	;@6D68
	mov al, byte ptr cs:StarRndSeed	;@6D69
	adc al, 9	;@6D6D
	adc al, byte ptr cs:StarRndSeed2	;@6D6F
	mov ah, byte ptr cs:StarRndSeed	;@6D74
	mov byte ptr cs:StarRndSeed, al	;@6D79
	mov byte ptr cs:StarRndSeed2, ah	;@6D7D
	ret	;@6D82
;------------------------------------------------------------------------------
; DrawCrosshair: draw the crosshair at LineEndX,LineEndY with PlotPixel (set pixel): a vertical
; bar Y-3..Y+3 and a horizontal bar X-3..X+3 without its centre pixel.
; Uses: AX, BX, SI, DI, PlotX/PlotY.
;------------------------------------------------------------------------------
DrawCrosshair:	mov al, byte ptr LineEndX	;@6D83
	mov byte ptr PlotX, al	;@6D86
	mov al, byte ptr LineEndY	;@6D89
	stc	;@6D8C
	cmc	;@6D8D
	sbb al, 3	;@6D8E
	cmc	;@6D90
	mov byte ptr PlotY, al	;@6D91
	call PlotPixel	;@6D94
	inc byte ptr PlotY	;@6D97
	call PlotPixel	;@6D9B
	inc byte ptr PlotY	;@6D9E
	call PlotPixel	;@6DA2
	inc byte ptr PlotY	;@6DA5
	call PlotPixel	;@6DA9
	inc byte ptr PlotY	;@6DAC
	call PlotPixel	;@6DB0
	inc byte ptr PlotY	;@6DB3
	call PlotPixel	;@6DB7
	inc byte ptr PlotY	;@6DBA
	call PlotPixel	;@6DBE
	mov al, byte ptr LineEndX	;@6DC1
	stc	;@6DC4
	cmc	;@6DC5
	sbb al, 3	;@6DC6
	cmc	;@6DC8
	mov byte ptr PlotX, al	;@6DC9
	mov al, byte ptr LineEndY	;@6DCC
	mov byte ptr PlotY, al	;@6DCF
	call PlotPixel	;@6DD2
	inc byte ptr PlotX	;@6DD5
	call PlotPixel	;@6DD9
	inc byte ptr PlotX	;@6DDC
	call PlotPixel	;@6DE0
	inc byte ptr PlotX	;@6DE3
	inc byte ptr PlotX	;@6DE7
	call PlotPixel	;@6DEB
	inc byte ptr PlotX	;@6DEE
	call PlotPixel	;@6DF2
	inc byte ptr PlotX	;@6DF5
	call PlotPixel	;@6DF9
	ret	;@6DFC
;------------------------------------------------------------------------------
; Hyperwarp: the hyperwarp itself, to the coordinates already in Xeno-Zabo.
; "HYPERWARP ENGAGED!", then three phases of 128, 128 and 63 star frames:
;  1. StarMode = 0: streaks; speaker on, tone divisor 2200h falling by 1 per star
;     (rising pitch);
;  2. StarMode = 1: the new coordinates are shown; the tone falls back;
;  3. StarMode = 2, 4, .. 7Eh: slowing down; random bleeps from now on.
; If the fuel left (TriLithium, BCD) has its two low bits set (low digit 3 or 7):
; "SHIP OFF COURSE!" and random coordinates 0-7 (from StarRnd). Finally FindOrbit tells
; where the rocket is (and kills the player at the sun).
; Out: StarMode = 80h, WarpFrames = 0. Uses: all general registers.
;------------------------------------------------------------------------------
Hyperwarp:	call PrintInline	;@6DFD
	db 48h,59h,50h,45h,52h,57h,41h,52h,50h,20h,45h,4Eh,47h,41h,47h,45h	;@6E00
	db 44h,21h,8Dh,0h	;@6E10
; phase 1: 128 frames of streaks, pitch rising
	mov al, 80h	;@6E14
	mov byte ptr WarpFrames, al	;@6E16
	mov al, 0	;@6E19
	mov byte ptr StarMode, al	;@6E1B
	call ResetStarRnd	;@6E1E
	mov bx, 2200h	;@6E21
	mov word ptr cs:SpaceToneDivisor, bx	;@6E24
	mov word ptr cs:SpaceToneStep, 0FFFFh	;@6E29
	call SpaceSpeakerOn	; speaker on at divisor BX = 2200h	;@6E30
Hyperwarp_Streaks:	call MoveStars	;@6E33
	mov bx, 16h	;@6E36
	call SpeedDelay	;@6E39
	dec byte ptr WarpFrames	;@6E3C
	jne Hyperwarp_Streaks	;@6E40
; phase 2: show the new coordinates, 128 frames, pitch falling
	mov al, 80h	;@6E42
	mov byte ptr WarpFrames, al	;@6E44
	mov al, 1	;@6E47
	mov byte ptr StarMode, al	;@6E49
	call ShowFuelCoords	;@6E4C
	call ResetStarRnd	;@6E4F
	mov word ptr cs:SpaceToneStep, 1	;@6E52
Hyperwarp_Arrive:	call MoveStars	;@6E59
	mov bx, 16h	;@6E5C
	call SpeedDelay	;@6E5F
	dec byte ptr WarpFrames	;@6E62
	jne Hyperwarp_Arrive	;@6E66
; phase 3: slow down until StarMode reaches 80h; the first star turns the engine tone off
	inc byte ptr StarMode	;@6E68
	mov word ptr cs:BleepCountdown, 1	;@6E6C
Hyperwarp_SlowDown:	call MoveStars	;@6E73
	mov bx, 18h	;@6E76
	call SpeedDelay	;@6E79
	inc byte ptr StarMode	;@6E7C
	inc byte ptr StarMode	;@6E80
	jns Hyperwarp_SlowDown	;@6E84
; off course if fuel bits 0 and 1 are both set
	mov al, byte ptr TriLithium	;@6E86
	clc	;@6E89
	rcr al, 1	;@6E8A
	jae Hyperwarp_WhereAmI	;@6E8C
	clc	;@6E8E
	rcr al, 1	;@6E8F
	jae Hyperwarp_WhereAmI	;@6E91
	call PrintInline	;@6E93
	db 53h,48h,49h,50h,20h,4Fh,46h,46h,20h,43h,4Fh,55h,52h,53h,45h,21h	;@6E96
	db 8Dh,0h	;@6EA6
	call StarRnd	;@6EA8
	and al, 7	;@6EAB
	mov byte ptr Xeno, al	;@6EAD
	call StarRnd	;@6EB0
	and al, 7	;@6EB3
	mov byte ptr Yako, al	;@6EB5
	call StarRnd	;@6EB8
	and al, 7	;@6EBB
	mov byte ptr Zabo, al	;@6EBD
Hyperwarp_WhereAmI:	nop	;@6EC0
	call FindOrbit	;@6EC1
	ret	;@6EC4
;------------------------------------------------------------------------------
; SpaceCmdHyperwarp: space command H (hyperwarp), jumped to from the command loop. "NO FUEL!"
; if TriLithium = 0; else takes 1 fuel (BCD), re-centres the crosshair, asks
; "HYPERWARP TO:" XENO=, YAKO=, ZABO= (one digit 0-9 each, ReadCoordDigit), says "PREPARE
; FOR HYPERWARP!", speeds the stars up (StarMode down to 2), cruises 64 frames,
; hyperwarps (Hyperwarp) and goes back to the command loop.
;------------------------------------------------------------------------------
SpaceCmdHyperwarp:	mov al, byte ptr TriLithium	;@6EC5
	or al, al	;@6EC8
	jne SpaceHyper_Go	;@6ECA
	call PrintInline	;@6ECC
	db 4Eh,4Fh,20h,46h,55h,45h,4Ch,21h,8Dh,0h	;@6ECF
	jmp SpaceCmdLoop	;@6ED9
SpaceHyper_Go:	stc	;@6EDC
	cmc	;@6EDD
	sbb al, 1	;@6EDE
	das	; fuel - 1, BCD	;@6EE0
	cmc	;@6EE1
	mov byte ptr TriLithium, al	;@6EE2
	call EraseCrosshair	;@6EE5
	mov al, 80h	;@6EE8
	mov byte ptr LineEndX, al	;@6EEA
	mov al, 40h	;@6EED
	mov byte ptr LineEndY, al	;@6EEF
	call PrintInline	;@6EF2
	db 48h,59h,50h,45h,52h,57h,41h,52h,50h,20h,54h,4Fh,3Ah,8Dh,58h,45h	;@6EF5
	db 4Eh,4Fh,3Dh,0h	;@6F05
	call ReadCoordDigit	;@6F09
	mov byte ptr Xeno, al	;@6F0C
	call PrintInline	;@6F0F
	db 20h,59h,41h,4Bh,4Fh,3Dh,0h	;@6F12
	call ReadCoordDigit	;@6F19
	mov byte ptr Yako, al	;@6F1C
	call PrintInline	;@6F1F
	db 20h,5Ah,41h,42h,4Fh,3Dh,0h	;@6F22
	call ReadCoordDigit	;@6F29
	mov byte ptr Zabo, al	;@6F2C
	call PrintInline	;@6F2F
	db 8Dh,50h,52h,45h,50h,41h,52h,45h,20h,46h,4Fh,52h,20h,48h,59h,50h	;@6F32
	db 45h,52h,57h,41h,52h,50h,21h,8Dh,0h	;@6F42
	call ResetStarRnd	;@6F4B
; speed up: StarMode (80h after the last hyperwarp) down to 2, one frame each
SpaceHyper_SpeedUp:	call MoveStars	;@6F4E
	mov bx, 1Ah	;@6F51
	call SpeedDelay	;@6F54
	dec byte ptr StarMode	;@6F57
	mov al, byte ptr StarMode	;@6F5B
	cmp al, 2	;@6F5E
	jne SpaceHyper_SpeedUp	;@6F60
; cruise 64 frames at full speed
	mov al, 40h	;@6F62
	mov byte ptr WarpFrames, al	;@6F64
	call ResetStarRnd	;@6F67
SpaceHyper_Cruise:	call MoveStars	;@6F6A
	mov bx, 1Ah	;@6F6D
	call SpeedDelay	;@6F70
	dec byte ptr WarpFrames	;@6F73
	jne SpaceHyper_Cruise	;@6F77
	call Hyperwarp	;@6F79
	jmp SpaceCmdLoop	;@6F7C
;------------------------------------------------------------------------------
; ReadCoordDigit: read one coordinate digit, animating the stars while waiting. Keys other
; than '0'-'9' are ignored; the digit is echoed (PutChar).
; Out: AL = 0-9. Uses: AX, BX, CX, SI, DI.
;------------------------------------------------------------------------------
ReadCoordDigit:	call MoveStars	;@6F7F
	mov bx, 14h	;@6F82
	call SpeedDelay	;@6F85
	call ReadKey	;@6F88
	cmp ah, 0FFh	; key pressed?	;@6F8B
	jne ReadCoordDigit	;@6F8E
	cmp al, 30h	;@6F90
	jb ReadCoordDigit	;@6F92
	cmp al, 39h	;@6F94
	ja ReadCoordDigit	;@6F96
	push ax	;@6F98
	call PutChar	; echo the digit	;@6F99
	pop ax	;@6F9C
	stc	;@6F9D
	cmc	;@6F9E
	sbb al, 30h	; '0'-'9' -> 0-9	;@6F9F
	cmc	;@6FA1
	ret	;@6FA2
;------------------------------------------------------------------------------
; ShowFuelCoords: show the fuel (TriLithium) and Xeno/Yako/Zabo (Xeno-Zabo) as two digits
; each (PrintBcdByte) at column 37, rows 20-23, next to the labels SpaceFlight printed; then
; set the text window right edge to 31 and the cursor to column 0, row 23 (the
; command line). Uses: AX, BX, SI, DI.
;------------------------------------------------------------------------------
ShowFuelCoords:	nop	;@6FA3
	mov al, 28h	;@6FA4
	mov byte ptr TextRightCol, al	;@6FA6
	mov bh, 0	;@6FA9
	mov bl, 25h	;@6FAB
	mov di, bx	;@6FAD
	mov bh, 0	;@6FAF
	mov bl, 14h	;@6FB1
	mov si, bx	;@6FB3
	call SetCursor	;@6FB5
	mov al, byte ptr TriLithium	;@6FB8
	call PrintBcdByte	;@6FBB
	mov bh, 0	;@6FBE
	mov bl, 25h	;@6FC0
	mov di, bx	;@6FC2
	mov bh, 0	;@6FC4
	mov bl, 15h	;@6FC6
	mov si, bx	;@6FC8
	call SetCursor	;@6FCA
	mov al, byte ptr Xeno	;@6FCD
	call PrintBcdByte	;@6FD0
	mov bh, 0	;@6FD3
	mov bl, 25h	;@6FD5
	mov di, bx	;@6FD7
	mov bh, 0	;@6FD9
	mov bl, 16h	;@6FDB
	mov si, bx	;@6FDD
	call SetCursor	;@6FDF
	mov al, byte ptr Yako	;@6FE2
	call PrintBcdByte	;@6FE5
	mov bh, 0	;@6FE8
	mov bl, 25h	;@6FEA
	mov di, bx	;@6FEC
	mov bh, 0	;@6FEE
	mov bl, 17h	;@6FF0
	mov si, bx	;@6FF2
	call SetCursor	;@6FF4
	mov al, byte ptr Zabo	;@6FF7
	call PrintBcdByte	;@6FFA
	mov al, 1Fh	;@6FFD
	mov byte ptr TextRightCol, al	;@6FFF
	mov bh, 0	;@7002
	mov bl, 0	;@7004
	mov di, bx	;@7006
	mov bh, 0	;@7008
	mov bl, 17h	;@700A
	mov si, bx	;@700C
	call SetCursor	;@700E
	ret	;@7011
; the planets' Xeno, Yako and Zabo coordinates, indexed by planet number:
;          Earth Mercury Venus Mars Jupiter Saturn Uranus Neptune Pluto X
PlanetXenoTbl label byte
	db 6h,5h,3h,6h,1h,2h,9h,4h,0h,9h	;@7012
PlanetYakoTbl label byte
	db 6h,4h,3h,2h,3h,8h,4h,0h,1h,9h	;@701C
PlanetZaboTbl label byte
	db 6h,5h,4h,3h,4h,5h,6h,5h,4h,9h	;@7026
;------------------------------------------------------------------------------
; FindOrbit: find where the rocket is from Xeno/Yako/Zabo (Xeno-Zabo).
; 4,4,4 = the sun: "YOU HIT THE SUN!", screen cleared, death (Space_Die, no return).
; A planet's coordinates: Planet = its number, "YOU ARE ORBITING <planet>."
; Anything else: "YOU ARE IN DEEP SPACE.", Planet = 0Ah.
; Out: Planet. Uses: AX, BX, DI.
;------------------------------------------------------------------------------
FindOrbit:	nop	;@7030
	mov al, byte ptr Xeno	;@7031
	cmp al, 4	;@7034
	jne FindOrbit_Search	;@7036
	mov al, byte ptr Yako	;@7038
	cmp al, 4	;@703B
	jne FindOrbit_Search	;@703D
	mov al, byte ptr Zabo	;@703F
	cmp al, 4	;@7042
	jne FindOrbit_Search	;@7044
	call PrintInline	;@7046
	db 8Dh,8Dh,59h,4Fh,55h,20h,48h,49h,54h,20h,54h,48h,45h,20h,53h,55h	;@7049
	db 4Eh,21h,8Dh,0h	;@7059
	call ClearViewArea	; clear the graphics screen	;@705D
	jmp Space_Die	;@7060
; search the planet table from 9 (X) down to 0 (Earth)
FindOrbit_Search:	nop	;@7063
	mov bh, 0	;@7064
	mov bl, 9	;@7066
	mov di, bx	;@7068
FindOrbit_Loop:	mov al, byte ptr cs:PlanetXenoTbl[di]	;@706A
	cmp al, byte ptr Xeno	;@706F
	jne FindOrbit_Next	;@7073
	mov al, byte ptr cs:PlanetYakoTbl[di]	;@7075
	cmp al, byte ptr Yako	;@707A
	jne FindOrbit_Next	;@707E
	mov al, byte ptr cs:PlanetZaboTbl[di]	;@7080
	cmp al, byte ptr Zabo	;@7085
	je FindOrbit_Found	;@7089
FindOrbit_Next:	dec di	;@708B
	jns FindOrbit_Loop	;@708C
	call PrintInline	;@708E
	db 59h,4Fh,55h,20h,41h,52h,45h,20h,49h,4Eh,20h,44h,45h,45h,50h,20h	;@7091
	db 53h,50h,41h,43h,45h,2Eh,8Dh,0h	;@70A1
	mov al, 0Ah	;@70A9
	mov byte ptr Planet, al	; 0Ah = deep space	;@70AB
	jmp FindOrbit_Done	;@70AE
FindOrbit_Found:	mov ax, di	;@70B1
	mov byte ptr Planet, al	;@70B3
	call PrintInline	;@70B6
	db 59h,4Fh,55h,20h,41h,52h,45h,20h,4Fh,52h,42h,49h,54h,49h,4Eh,47h	;@70B9
	db 20h,0h	;@70C9
; print the planet's name (a chain of compares, not a table)
	mov al, byte ptr Planet	;@70CB
	cmp al, 0	;@70CE
	je FindOrbit_Earth	;@70D0
	cmp al, 1	;@70D2
	je FindOrbit_Mercury	;@70D4
	cmp al, 2	;@70D6
	je FindOrbit_Venus	;@70D8
	cmp al, 3	;@70DA
	je FindOrbit_Mars	;@70DC
	cmp al, 4	;@70DE
	je FindOrbit_Jupiter	;@70E0
	cmp al, 5	;@70E2
	je FindOrbit_Saturn	;@70E4
	cmp al, 6	;@70E6
	je FindOrbit_Uranus	;@70E8
	cmp al, 7	;@70EA
	je FindOrbit_Neptune	;@70EC
	cmp al, 8	;@70EE
	je FindOrbit_Pluto	;@70F0
	jmp FindOrbit_PlanetX	;@70F2
FindOrbit_Earth:	call PrintInline	;@70F5
	db 45h,41h,52h,54h,48h,2Eh,8Dh,0h	;@70F8
	jmp FindOrbit_Done	;@7100
FindOrbit_Mercury:	call PrintInline	;@7103
	db 4Dh,45h,52h,43h,55h,52h,59h,2Eh,8Dh,0h	;@7106
	jmp FindOrbit_Done	;@7110
FindOrbit_Venus:	call PrintInline	;@7113
	db 56h,45h,4Eh,55h,53h,2Eh,8Dh,0h	;@7116
	jmp FindOrbit_Done	;@711E
FindOrbit_Mars:	call PrintInline	;@7121
	db 4Dh,41h,52h,53h,2Eh,8Dh,0h	;@7124
	jmp FindOrbit_Done	;@712B
FindOrbit_Jupiter:	call PrintInline	;@712E
	db 4Ah,55h,50h,49h,54h,45h,52h,2Eh,8Dh,0h	;@7131
	jmp FindOrbit_Done	;@713B
FindOrbit_Saturn:	call PrintInline	;@713E
	db 53h,41h,54h,55h,52h,4Eh,2Eh,8Dh,0h	;@7141
	jmp FindOrbit_Done	;@714A
FindOrbit_Uranus:	call PrintInline	;@714D
	db 55h,52h,41h,4Eh,55h,53h,2Eh,8Dh,0h	;@7150
	jmp FindOrbit_Done	;@7159
FindOrbit_Neptune:	call PrintInline	;@715C
	db 4Eh,45h,50h,54h,55h,4Eh,45h,2Eh,8Dh,0h	;@715F
	jmp FindOrbit_Done	;@7169
FindOrbit_Pluto:	call PrintInline	;@716C
	db 50h,4Ch,55h,54h,4Fh,2Eh,8Dh,0h	;@716F
	jmp FindOrbit_Done	;@7177
FindOrbit_PlanetX:	call PrintInline	;@717A
	db 58h,2Eh,8Dh,0h	; "X." = Planet X	;@717D
	jmp FindOrbit_Done	;@7181
FindOrbit_Done:	ret	;@7184
;------------------------------------------------------------------------------
; SpaceCmdLand: space command L (land), jumped to from the command loop. Re-centres the
; crosshair, "LANDING REQUESTED!", tells where the rocket is (FindOrbit) and, in deep
; space, "REQUEST DENIED!" (back to the command loop). Otherwise selects the map
; file for the caller (CMDAL 3961 loads it with LoadMapAndMonsters) and returns from SpaceFlight:
;   Earth:  letter 'X', TimeZone = 4, MapType = 0 -> MAPX40, MONX40 (Earth, period 4)
;   others: letter 'G', TimeZone = planet, MapType = 0 -> MAPG10 .. MAPG90
; The speaker is turned off. The 1989 release patched out two disk-swap prompts
; here (see the dead bytes below).
;------------------------------------------------------------------------------
SpaceCmdLand:	call EraseCrosshair	;@7185
	mov al, 80h	;@7188
	mov byte ptr LineEndX, al	;@718A
	mov al, 40h	;@718D
	mov byte ptr LineEndY, al	;@718F
	call PrintInline	;@7192
	db 4Ch,41h,4Eh,44h,49h,4Eh,47h,20h,52h,45h,51h,55h,45h,53h,54h,45h	;@7195
	db 44h,21h,8Dh,0h	;@71A5
	call FindOrbit	;@71A9
	mov al, byte ptr Planet	;@71AC
	cmp al, 0Ah	; deep space?	;@71AF
	jne SpaceLand_Where	;@71B1
	call PrintInline	;@71B3
	db 52h,45h,51h,55h,45h,53h,54h,20h,44h,45h,4Eh,49h,45h,44h,21h,8Dh	;@71B6
	db 0h	;@71C6
	jmp SpaceCmdLoop	;@71C7
SpaceLand_Where:	nop	;@71CA
	cmp al, 0	; Earth?	;@71CB
	jne SpaceLand_Other	;@71CD
; Dead bytes: this was "call PrintInline" (E8 0D DE) + "(INSERT PLAYER DISK)"; the 1989
; patch turned E8 0D into "jmp short" over the rest of the string.
	jmp short SpaceLand_Earth	;@71CF
	db 0DEh,28h,49h,4Eh,53h,45h,52h,54h,20h,50h,4Ch,41h,59h,45h,52h,20h	;@71D1
	db 44h,49h,53h,4Bh,29h,8Dh,0h	;@71E1
SpaceLand_Earth:	call MoveStars	;@71E8
	mov bx, 14h	;@71EB
	call SpeedDelay	;@71EE
	mov al, 58h	; 'X' = Earth's files	;@71F1
	call SetMapFileLetter	;@71F3
	nop	; patched out (a call, probably the disk-swap wait)	;@71F6
	nop	;@71F7
	nop	;@71F8
	mov al, 0	;@71F9
	mov byte ptr MapType, al	;@71FB
	mov al, 4	;@71FE
	mov byte ptr TimeZone, al	; Earth, time period 4	;@7200
	call SpaceSpeakerOff	;@7203
	ret	;@7206
; Same patch: "call PrintInline" (E8 D5 DD) + a "(..." prompt (probably another disk request)
; became "jmp short"; the new routine SetMapFileLetter was written into the middle of the old string.
SpaceLand_Other:	jmp short SpaceLand_Planet	;@7207
	db 0DDh,28h	; dead: last byte of the old call, '('	;@7209
;------------------------------------------------------------------------------
; SetMapFileLetter: set the letter of the MAP?xx, MON?xx and TLK?xx file names (FcbMapLetter,
; FcbMonLetter, FcbTlkLetter in LOAD): 'X' = Earth, 'G' = the other planets.
; In: AL = letter. Uses: nothing else (self-modifying: writes into LOAD's FCB names).
;------------------------------------------------------------------------------
SetMapFileLetter:	mov byte ptr cs:FcbMapLetter, al	;@720B
	mov byte ptr cs:FcbMonLetter, al	;@720F
	mov byte ptr cs:FcbTlkLetter, al	;@7213
	ret	;@7217
	db 0h,2Dh,55h,44h,49h,43h,2Dh,29h,8Dh,0h	; dead: tail of the old prompt "-UDIC-)"	;@7218
SpaceLand_Planet:	call MoveStars	;@7222
	mov bx, 14h	;@7225
	call SpeedDelay	;@7228
	mov al, 47h	; 'G' = the other planets' files	;@722B
	call SetMapFileLetter	;@722D
	nop	; patched out, as at 71F6	;@7230
	nop	;@7231
	nop	;@7232
	mov al, 0	;@7233
	mov byte ptr MapType, al	;@7235
	mov al, byte ptr Planet	;@7238
	mov byte ptr TimeZone, al	; first digit = planet number	;@723B
	call SpaceSpeakerOff	;@723E
	ret	;@7241
CODE ENDS
END
