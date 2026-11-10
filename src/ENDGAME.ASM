; ENDGAME.ASM: the end of Minax and the end of the game.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 7242-740B.
;
; Two unrelated pieces:
; - 7242-729B: the PC speaker helpers of space flight (SPACE.ASM calls them): SpaceSpeakerOn turns the
;   speaker on, SpaceSpeakerOff turns it off, ToggleSpaceBleep toggles the random "computer bleeps" heard while
;   cruising. The CS byte SpeakerIsOff (in VIEW3D) remembers the state: FFh = speaker off, 0 = on;
;   the CS word BleepCountdown counts the star moves until the next toggle.
; - MinaxDead: the end of the game, called from the attack code (CMDAL 2CCD) when the monster
;   just killed is Minax (type 40h). It wrecks the map, loads MAPX30, prints the victory text
;   and then flies over the map forever; it never returns (the player has to reboot).
; Data: PlayerX/PlayerY (player position), OffMapTile/PlayerTile, the map buffer at MapBufPtr.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN PlayerX:BYTE, PlayerY:BYTE, MapCellPtr:BYTE, OffMapTile:BYTE, PlayerTile:BYTE, Temp1F:BYTE
	EXTRN Temp20:BYTE, LookX:BYTE, LookY:BYTE, TextRightCol:BYTE, MapBufPtr:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN SpeedDelay:NEAR, PrintInline:NEAR, GetMapSquare:NEAR, Random:NEAR, ReadWriteFile:NEAR, UpdateMapView:NEAR
	EXTRN StartTone:NEAR, HoldTone:NEAR, StopTone:NEAR, PlayHitSound:NEAR, PlayWarpSound:NEAR, BleepCountdown:BYTE
	EXTRN SpeakerIsOff:BYTE
	PUBLIC ToggleSpaceBleep, SpaceSpeakerOn, SpaceSpeakerOff, MinaxDead
ASSUME CS:CODE, DS:DATA
;------------------------------------------------------------------------------
; ToggleSpaceBleep: toggle the space "bleeps". Called by the star field (MoveStars in SPACE) each
; time the countdown BleepCountdown runs out while cruising. If the speaker is on, turn it
; off for E0h star moves; if it is off, turn it on at a random pitch (divisor
; 0100h-2000h) for 18h star moves.
; In: SpeakerIsOff (speaker state). Out: BleepCountdown reloaded. Uses: AX, BX, CX.
;------------------------------------------------------------------------------
ToggleSpaceBleep:	nop	;@7242
	cmp byte ptr cs:SpeakerIsOff, 0FFh	; speaker off?	;@7243
	je ToggleBleep_On	;@7249
	call SpaceSpeakerOff	;@724B
	mov word ptr cs:BleepCountdown, 0E0h	; silent for E0h star moves	;@724E
	jmp ToggleBleep_Done	;@7255
ToggleBleep_On:	call Random	;@7258
	mov ah, al	;@725B
	and ax, 1F00h	;@725D
	add ax, 100h	; BX = random divisor 0100h-2000h	;@7260
	mov bx, ax	;@7263
	mov cx, 1	;@7265
	call SpaceSpeakerOn	;@7268
	call HoldTone	; set the pitch, short delay	;@726B
	mov word ptr cs:BleepCountdown, 18h	; bleep for 18h star moves	;@726E
ToggleBleep_Done:	ret	;@7275
;------------------------------------------------------------------------------
; SpaceSpeakerOn: turn the PC speaker on (tone divisor BX, via StartTone) unless it is on
; already. In: BX = PIT divisor. Out: SpeakerIsOff = 0 (on). Uses: AX.
;------------------------------------------------------------------------------
SpaceSpeakerOn:	nop	;@7276
	cmp byte ptr cs:SpeakerIsOff, 0FFh	;@7277
	jne SpaceSpeakerOn_Done	;@727D
	call StartTone	;@727F
	mov byte ptr cs:SpeakerIsOff, 0	;@7282
SpaceSpeakerOn_Done:	ret	;@7288
;------------------------------------------------------------------------------
; SpaceSpeakerOff: turn the PC speaker off (StopTone) unless it is off already.
; Out: SpeakerIsOff = FFh (off). Uses: AX.
;------------------------------------------------------------------------------
SpaceSpeakerOff:	nop	;@7289
	cmp byte ptr cs:SpeakerIsOff, 0	;@728A
	jne SpaceSpeakerOff_Done	;@7290
	call StopTone	;@7292
	mov byte ptr cs:SpeakerIsOff, 0FFh	;@7295
SpaceSpeakerOff_Done:	ret	;@729B
	db 0h,0h,0h,0h	; unused padding	;@729C
;------------------------------------------------------------------------------
; MinaxDead: Minax is dead: the end of the game. Called from the attack code (CMDAL
; 2CCD) when the killed monster's type is 40h. Never returns.
; 1. "MINAX IS DEAD!! ALL HER WORKS SHALL DIE!"
; 2. 64 times: a sound (PlayHitSound), 64 random cells of the 64x64 map set to tile 74h,
;    redraw the map window.
; 3. "YOU FEEL A STRANGE FORCE!", sounds, load MAPX30 (Earth, time period 3?) into
;    the map buffer, then the victory text (the game's font draws "][" as the
;    roman II, so "ULTIMA ][" = Ultima II).
; 4. Put the player (as tile 28h, the rocket) at 0,0 of a wrapping map and scroll
;    over it diagonally forever.
;------------------------------------------------------------------------------
MinaxDead:	nop	;@72A0
	mov byte ptr TextRightCol, 28h	; text window right edge = column 40	;@72A1
	call PrintInline	;@72A6
	db 8Dh,8Dh,20h,20h,20h,20h,20h,4Dh,49h,4Eh,41h,58h,20h,49h,53h,20h	;@72A9
	db 44h,45h,41h,44h,21h,21h,8Dh,41h,4Ch,4Ch,20h,48h,45h,52h,20h,57h	;@72B9
	db 4Fh,52h,4Bh,53h,20h,53h,48h,41h,4Ch,4Ch,20h,44h,49h,45h,21h,8Dh	;@72C9
	db 0h	;@72D9
; 64 rounds (Temp1F) of 64 random cells (Temp20) each
	mov al, 40h	;@72DA
	mov byte ptr Temp1F, al	;@72DC
MinaxDead_Round:	call PlayHitSound	;@72DF
	mov al, 40h	;@72E2
	mov byte ptr Temp20, al	;@72E4
MinaxDead_Wreck:	call Random	;@72E7
	and al, 3Fh	;@72EA
	mov byte ptr LookX, al	; random x 0-63	;@72EC
	call Random	;@72EF
	and al, 3Fh	;@72F2
	mov byte ptr LookY, al	; random y 0-63	;@72F4
	call GetMapSquare	; MapCellPtr -> map cell, SI = 0	;@72F7
	mov al, 74h	; tile 74h (what it shows: ?)	;@72FA
	mov bx, word ptr MapCellPtr	;@72FC
	mov byte ptr [bx+si], al	;@7300
	dec byte ptr Temp20	;@7302
	jne MinaxDead_Wreck	;@7306
	call UpdateMapView	; redraw the map window	;@7308
	mov bx, 0Eh	;@730B
	call SpeedDelay	; delay	;@730E
	dec byte ptr Temp1F	;@7311
	jne MinaxDead_Round	;@7315
	call PrintInline	;@7317
	db 8Dh,59h,4Fh,55h,20h,46h,45h,45h,4Ch,20h,41h,20h,53h,54h,52h,41h	;@731A
	db 4Eh,47h,45h,20h,46h,4Fh,52h,43h,45h,21h,0h	;@732A
	call PlayWarpSound	;@7335
	mov ah, 27h	; FCB random block read	;@7338
	mov cx, 1000h	; 4 KB, the whole 64x64 map	;@733A
	mov dx, word ptr MapBufPtr	; into the map buffer	;@733D
	call ReadWriteFile	;@7341
	db 4Dh,41h,50h,58h,33h,30h,20h,20h	;@7344
	call PlayWarpSound	;@734C
	call PrintInline	;@734F
	db 8Dh,8Dh,59h,4Fh,55h,20h,48h,41h,56h,45h,20h,53h,41h,56h,45h,44h	;@7352
	db 20h,54h,48h,45h,20h,55h,4Eh,49h,56h,45h,52h,53h,45h,2Ch,8Dh,41h	;@7362
	db 4Eh,44h,20h,43h,4Fh,4Dh,50h,4Ch,45h,54h,45h,44h,20h,55h,4Ch,54h	;@7372
	db 49h,4Dh,41h,20h,5Dh,5Bh,21h,20h,53h,45h,45h,4Bh,8Dh,4Eh,4Fh,57h	;@7382
	db 20h,54h,4Fh,20h,43h,4Fh,4Eh,51h,55h,45h,52h,20h,57h,49h,43h,4Bh	;@7392
	db 45h,44h,20h,45h,58h,4Fh,44h,55h,53h,2Ch,8Dh,0h	;@73A2
	call PrintInline	;@73AE
	db 46h,4Fh,55h,4Eh,44h,20h,49h,4Eh,20h,55h,4Ch,54h,49h,4Dh,41h,20h	;@73B1
	db 5Dh,49h,5Bh,2Dh,44h,20h,5Dh,49h,49h,5Bh,2Dh,50h,21h,0h	;@73C1
	mov al, 0FFh	;@73CF
	mov byte ptr OffMapTile, al	; FFh = the map wraps around	;@73D1
	mov al, 28h	;@73D4
	mov byte ptr PlayerTile, al	; player shown as tile 28h (rocket)	;@73D6
	mov al, 0	;@73D9
	mov byte ptr PlayerX, al	;@73DB
	mov byte ptr PlayerY, al	;@73DE
; Forever: y+1 every frame, x+1 every 4th frame (when y's low two bits are 0), both
; modulo 64; redraw the map around the player and wait.
MinaxDead_FlyLoop:	clc	;@73E1
	mov al, byte ptr PlayerY	;@73E2
	adc al, 1	;@73E5
	and al, 3Fh	;@73E7
	mov byte ptr PlayerY, al	;@73E9
	clc	;@73EC
	rcr al, 1	;@73ED
	jb MinaxDead_Draw	;@73EF
	clc	;@73F1
	rcr al, 1	;@73F2
	jb MinaxDead_Draw	;@73F4
	mov al, byte ptr PlayerX	;@73F6
	adc al, 1	; CF = 0 here: x+1	;@73F9
	and al, 3Fh	;@73FB
	mov byte ptr PlayerX, al	;@73FD
MinaxDead_Draw:	call UpdateMapView	;@7400
	mov bx, 6	;@7403
	call SpeedDelay	; delay	;@7406
	jmp MinaxDead_FlyLoop	;@7409
CODE ENDS
END
