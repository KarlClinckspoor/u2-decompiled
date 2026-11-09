; INPUT.ASM: number and money entry, "illegal command", monster movement.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 2028-2290.
;
; Despite the name, about half of this module is monster movement. Entry points:
;   ReadDigit read a digit 0-9 (shops, Magic, Ready, Wear)
;   PayPrice pay the price AmountHi/AmountLo in gold, or abort the command ("YOU DONT HAVE THAT MUCH!")
;   CalcPrice compute a shop price from an item number, Intelligence and Charisma (BCD Fibonacci)
;   MonsterStepToward move a monster one square toward/away from the player (surface and towns);
;         MonsterCanEnter tells whether a monster may enter a tile, MoveMonsterToTarget does the move
;   IllegalCommand "-ILLEGAL COMMAND!"; DieOfStarvation death by starvation
; Data: the monster table, 8 arrays of 32 bytes loaded from the MONxxx file: MonsterX x, MonsterY y,
; MonsterHP hit points, MonsterTile tile (0 = free slot), MonsterUnder the map tile under the monster, MonsterMood
; town behaviour, MonsterStepX/MonsterStepY wander direction. Gold GoldHi/GoldLo (BCD). Monster tiles and
; terrain here are full map bytes: 00 water, 04 marsh, 08 grass, 0Ch woods, 10h mountains,
; 5Ch force field, 70h town floor.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN PlayerX:BYTE, PlayerY:BYTE, MapCellPtr:BYTE, DeltaX:BYTE, DeltaY:BYTE, Temp1F:BYTE
	EXTRN Temp20:BYTE, LookX:BYTE, LookY:BYTE, AmountHi:BYTE, AmountLo:BYTE, Temp29:BYTE
	EXTRN Temp2A:BYTE, MapType:BYTE, Charisma:BYTE, Intelligence:BYTE, GoldHi:BYTE, GoldLo:BYTE
	EXTRN MonsterX:BYTE, MonsterY:BYTE, MonsterHP:BYTE, MonsterTile:BYTE, MonsterUnder:BYTE, TimeStopTurns:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN EndCommandBeep:NEAR, OutdoorMonsters_Next:NEAR, PlayerDies:NEAR, TownTurnNextMonster:NEAR, ReadKey:NEAR
	EXTRN PrintInline:NEAR
	EXTRN GetMapSquare:NEAR, PutChar:NEAR
	PUBLIC ReadDigit, PayPrice, CalcPrice, MonsterStepToward, MoveMonsterToTarget, IllegalCommand
	PUBLIC DieOfStarvation
ASSUME CS:CODE, DS:DATA

;------------------------------------------------------------------------------
; ReadDigit: wait for a digit key '0'-'9' (other keys are ignored), echo it and a
; CR (8Dh). Out: AL = DI = the value 0-9, AH = 0, ZF set if 0. Uses: AX, DI.
;------------------------------------------------------------------------------
ReadDigit:	nop	;@2028
	call ReadKey	; poll the keyboard: AH = FFh if a key came	;@2029
	cmp ah, 0FFh	;@202C
	jne ReadDigit	;@202F
	cmp al, 30h	; '0'	;@2031
	jb ReadDigit	;@2033
	cmp al, 39h	; '9'	;@2035
	ja ReadDigit	;@2037
	stc	;@2039
	cmc	;@203A
	sbb al, 30h	; ASCII -> 0-9	;@203B
	cmc	;@203D
	mov ah, 0	;@203E
	mov di, ax	;@2040
	clc	;@2042
	adc al, 30h	;@2043
	call PutChar	; echo the digit	;@2045
	mov al, 8Dh	; CR	;@2048
	call PutChar	;@204A
	mov ax, di	;@204D
	cmp al, 0	;@204F
	ret	;@2051

;------------------------------------------------------------------------------
; PayPrice: pay a price: gold GoldHi/GoldLo -= AmountHi/AmountLo (4-digit BCD, high
; byte first). If the gold is not enough, the subtraction is undone, the caller
; is dropped and "YOU DONT HAVE THAT MUCH!" ends the turn (EndCommandBeep).
; Out: AL = 0 (paid). Uses: AX.
;------------------------------------------------------------------------------
PayPrice:	nop	;@2052
	stc	;@2053
	mov al, byte ptr GoldLo	; gold, low BCD byte	;@2054
	cmc	;@2057
	sbb al, byte ptr AmountLo	; price, low	;@2058
	das	;@205C
	cmc	;@205D
	mov byte ptr GoldLo, al	;@205E
	mov al, byte ptr GoldHi	; gold, high BCD byte	;@2061
	cmc	;@2064
	sbb al, byte ptr AmountHi	; price, high	;@2065
	das	;@2069
	cmc	;@206A
	mov byte ptr GoldHi, al	;@206B
	jb PayPrice_Ok	; no borrow: paid	;@206E
	clc	; too poor: add the price back	;@2070
	mov al, byte ptr GoldLo	;@2071
	adc al, byte ptr AmountLo	;@2074
	daa	;@2078
	mov byte ptr GoldLo, al	;@2079
	mov al, byte ptr GoldHi	;@207C
	adc al, byte ptr AmountHi	;@207F
	daa	;@2083
	mov byte ptr GoldHi, al	;@2084
	pop ax	; forget the caller	;@2087
	call PrintInline	;@2088
	db 59h,4Fh,55h,20h,44h,4Fh,4Eh,54h,20h,48h,41h,56h,45h,20h,54h,48h	; "YOU DONT HAVE THAT MUCH!"	;@208B
	db 41h,54h,20h,4Dh,55h,43h,48h,21h,0h	;@209B
	jmp EndCommandBeep	; beep, end of turn	;@20A4
PayPrice_Ok:	nop	;@20A7
	mov al, 0	;@20A8
	ret	;@20AA

;------------------------------------------------------------------------------
; CalcPrice: compute a shop price. The price runs through the BCD Fibonacci-like
; series 4, 8, 12, 20, 32, 52, 84, ... (each term = the sum of the two before):
; n = AL + 8 - (number of significant bits of Intelligence + Charisma) steps.
; Better Intelligence and Charisma make things cheaper.
; In: AL = item / price class. Out: AmountHi/AmountLo = price (BCD, high/low).
; Uses: AX, BX, SI, DI, Temp20, Temp29/Temp2A (the previous term). If n comes
; out 0 the loop runs 65536 times (not expected to happen).
;------------------------------------------------------------------------------
CalcPrice:	nop	;@20AB
	clc	;@20AC
	adc al, 8	;@20AD
	mov byte ptr Temp20, al	; AL + 8	;@20AF
	mov al, 0	;@20B2
	mov byte ptr AmountHi, al	; price = 0004	;@20B4
	mov byte ptr Temp29, al	; previous = 0004	;@20B7
	mov al, 4	;@20BA
	mov byte ptr AmountLo, al	;@20BC
	mov byte ptr Temp2A, al	;@20BF
	mov al, byte ptr Intelligence	; Intelligence	;@20C2
	adc al, byte ptr Charisma	; + Charisma (CF is 0 here)	;@20C5
	mov bh, 0	;@20C9
	mov bl, 0	;@20CB
	mov si, bx	;@20CD
CalcPrice_BitLoop:	inc si	; SI = number of significant bits of AL	;@20CF
	clc	;@20D0
	rcr al, 1	;@20D1
	or al, al	;@20D3
	jne CalcPrice_BitLoop	;@20D5
	mov al, byte ptr Temp20	;@20D7
	mov bx, si	;@20DA
	mov byte ptr Temp20, bl	;@20DC
	stc	;@20E0
	cmc	;@20E1
	sbb al, byte ptr Temp20	; n = AL + 8 - bits	;@20E2
	cmc	;@20E6
	mov ah, 0	;@20E7
	mov di, ax	;@20E9
; (price, previous) := (price + previous, price), n times, in BCD.
CalcPrice_FibLoop:	clc	;@20EB
	mov al, byte ptr Temp2A	;@20EC
	adc al, byte ptr AmountLo	;@20EF
	daa	;@20F3
	mov bh, 0	;@20F4
	mov bl, byte ptr AmountLo	;@20F6
	mov si, bx	;@20FA
	mov bx, si	;@20FC
	mov byte ptr Temp2A, bl	; previous low = old price low	;@20FE
	mov byte ptr AmountLo, al	; price low = sum	;@2102
	mov al, byte ptr Temp29	;@2105
	adc al, byte ptr AmountHi	; high bytes, with the carry	;@2108
	daa	;@210C
	mov bh, 0	;@210D
	mov bl, byte ptr AmountHi	;@210F
	mov si, bx	;@2113
	mov bx, si	;@2115
	mov byte ptr Temp29, bl	;@2117
	mov byte ptr AmountHi, al	;@211B
	dec di	;@211E
	jne CalcPrice_FibLoop	;@211F
	ret	;@2121

;------------------------------------------------------------------------------
; MonsterStepToward: move monster DI one square in the direction DeltaX/DeltaY (-1/0/+1,
; set by the caller toward the player, or away when the monster flees). First
; the monster heals 1 hit point if it has fewer than 10h. Tries the diagonal,
; then the vertical step (if dy <> 0), then the horizontal one, each checked by
; MonsterCanEnter; the first that is allowed is done by MoveMonsterToTarget. Coordinates wrap at 64.
; Jumped to (not called) from MAIN's surface monster loop and EVENTS' town loop;
; goes back to the loop at MonsterStep_Done (TownTurnNextMonster in towns, OutdoorMonsters_Next on the surface).
;------------------------------------------------------------------------------
MonsterStepToward:	mov al, byte ptr MonsterHP[di]	; monster hit points	;@2122
	cmp al, 10h	;@2126
	jae L212E	;@2128
	inc byte ptr MonsterHP[di]	; heal 1	;@212A
L212E:	clc	;@212E
	mov al, byte ptr MonsterX[di]	;@212F
	adc al, byte ptr DeltaX	;@2133
	and al, 3Fh	;@2137
	mov byte ptr LookX, al	; x + dx	;@2139
	clc	;@213C
	mov al, byte ptr MonsterY[di]	;@213D
	adc al, byte ptr DeltaY	;@2141
	and al, 3Fh	;@2145
	mov byte ptr LookY, al	; y + dy	;@2147
	call GetMapSquare	; AL = map tile there	;@214A
	call MonsterCanEnter	;@214D
	jne MonsterStep_TryY	;@2150
	jmp MoveMonsterToTarget	;@2152
MonsterStep_TryY:	mov al, byte ptr DeltaY	; diagonal blocked: try (x, y + dy)	;@2155
	cmp al, 0	;@2158
	je MonsterStep_TryX	;@215A
	mov al, byte ptr MonsterX[di]	;@215C
	mov byte ptr LookX, al	;@2160
	call GetMapSquare	;@2163
	call MonsterCanEnter	;@2166
	jne MonsterStep_TryX	;@2169
	jmp MoveMonsterToTarget	;@216B
MonsterStep_TryX:	clc	; then (x + dx, y)	;@216E
	mov al, byte ptr MonsterX[di]	;@216F
	adc al, byte ptr DeltaX	;@2173
	and al, 3Fh	;@2177
	mov byte ptr LookX, al	;@2179
	mov al, byte ptr MonsterY[di]	;@217C
	mov byte ptr LookY, al	;@2180
	call GetMapSquare	;@2183
	call MonsterCanEnter	;@2186
	je MoveMonsterToTarget	;@2189
; Done with this monster: back to the loop that called.
MonsterStep_Done:	mov al, byte ptr MapType	;@218B
	cmp al, 0	;@218E
	je L2195	;@2190
	jmp TownTurnNextMonster	; town loop (EVENTS)	;@2192
L2195:	nop	;@2195
	jmp OutdoorMonsters_Next	; surface loop (MAIN)	;@2196

;------------------------------------------------------------------------------
; MonsterCanEnter: may monster DI enter the tile AL at LookX/LookY?
; No monster moves while time is negated (TimeStopTurns). Monster tiles 2Ch and 48h
; (the sea serpent, and the pirate ship drawn with the frigate's tile) only move on water. Other monsters
; below tile 78h may cross force fields (5Ch). Otherwise: not water, marsh or
; mountains; yes on grass and woods (below 14h) and town floor (70h). In towns
; the row and column 0 are closed.
; Out: AL = 0, ZF = 1: yes; AL = FFh, ZF = 0: no. Uses: AL, Temp1F.
;------------------------------------------------------------------------------
MonsterCanEnter:	mov byte ptr Temp1F, al	; the target tile	;@2199
	mov al, byte ptr TimeStopTurns	; time-stop turns (N)egate	;@219C
	cmp al, 0	;@219F
	je MonsterCanEnter_Kind	;@21A1
	jmp MonsterCanEnter_No	;@21A3
MonsterCanEnter_Kind:	mov al, byte ptr MonsterTile[di]	; the monster's tile	;@21A6
	cmp al, 2Ch	;@21AA
	je MonsterCanEnter_Sea	;@21AC
	cmp al, 48h	;@21AE
	je MonsterCanEnter_Sea	;@21B0
	cmp al, 78h	;@21B2
	jae MonsterCanEnter_Land	;@21B4
	mov al, byte ptr Temp1F	;@21B6
	cmp al, 5Ch	; force field	;@21B9
	je MonsterCanEnter_Edge	;@21BB
MonsterCanEnter_Land:	nop	;@21BD
	mov al, byte ptr Temp1F	;@21BE
	cmp al, 10h	; mountains	;@21C1
	je MonsterCanEnter_No	;@21C3
	cmp al, 4	; marsh	;@21C5
	je MonsterCanEnter_No	;@21C7
	cmp al, 0	; water	;@21C9
	je MonsterCanEnter_No	;@21CB
	cmp al, 14h	; grass, woods	;@21CD
	jb MonsterCanEnter_Edge	;@21CF
	cmp al, 70h	; town floor	;@21D1
	je MonsterCanEnter_Edge	;@21D3
	jmp MonsterCanEnter_No	;@21D5
MonsterCanEnter_Sea:	mov al, byte ptr Temp1F	; sea monster: water only	;@21D8
	cmp al, 0	;@21DB
	jne MonsterCanEnter_No	;@21DD
	jmp MonsterCanEnter_Edge	;@21DF
MonsterCanEnter_Edge:	mov al, byte ptr MapType	; in a town, not onto row or column 0	;@21E2
	cmp al, 0	;@21E5
	je MonsterCanEnter_Yes	;@21E7
	mov al, byte ptr LookX	;@21E9
	cmp al, 0	;@21EC
	je MonsterCanEnter_No	;@21EE
	mov al, byte ptr LookY	;@21F0
	cmp al, 0	;@21F3
	je MonsterCanEnter_No	;@21F5
MonsterCanEnter_Yes:	mov al, 0	; yes	;@21F7
	cmp al, 0	;@21F9
	ret	;@21FB
MonsterCanEnter_No:	mov al, 0FFh	; no	;@21FC
	cmp al, 0	;@21FE
	ret	;@2200

;------------------------------------------------------------------------------
; MoveMonsterToTarget: move monster DI to LookX/LookY (unless that is the player's square):
; the old square gets back the tile the monster stood on (MonsterUnder), the monster
; takes the new position, remembers the tile there and is drawn into the map.
; Then back to the monster loop (MonsterStep_Done: TownTurnNextMonster in towns, OutdoorMonsters_Next on the surface).
; Also jumped to from the town wander code (EVENTS 1137).
;------------------------------------------------------------------------------
MoveMonsterToTarget:	mov al, byte ptr PlayerX	;@2201
	cmp al, byte ptr LookX	;@2204
	jne MoveMonsterToTarget_Do	;@2208
	mov al, byte ptr PlayerY	;@220A
	cmp al, byte ptr LookY	;@220D
	jne MoveMonsterToTarget_Do	;@2211
	jmp MonsterStep_Done	; that is the player: stay	;@2213
MoveMonsterToTarget_Do:	mov al, byte ptr LookX	;@2216
	mov byte ptr AmountHi, al	; keep the new x/y	;@2219
	mov al, byte ptr LookY	;@221C
	mov byte ptr AmountLo, al	;@221F
	mov al, byte ptr MonsterX[di]	;@2222
	mov byte ptr LookX, al	;@2226
	mov al, byte ptr MonsterY[di]	;@2229
	mov byte ptr LookY, al	;@222D
	call GetMapSquare	; MapCellPtr -> the old map cell	;@2230
	mov al, byte ptr MonsterUnder[di]	; the tile under the monster	;@2233
	mov bh, 0	;@2237
	mov bl, 0	;@2239
	mov si, bx	;@223B
	mov bx, word ptr MapCellPtr	;@223D
	mov byte ptr [bx+si], al	; restore it	;@2241
	mov al, byte ptr AmountHi	;@2243
	mov byte ptr LookX, al	;@2246
	mov byte ptr MonsterX[di], al	; new x	;@2249
	mov al, byte ptr AmountLo	;@224D
	mov byte ptr LookY, al	;@2250
	mov byte ptr MonsterY[di], al	; new y	;@2253
	call GetMapSquare	; AL = the tile at the new square	;@2257
	mov byte ptr MonsterUnder[di], al	;@225A
	mov al, byte ptr MonsterTile[di]	;@225E
	mov bx, word ptr MapCellPtr	;@2262
	mov byte ptr [bx+si], al	; put the monster on the map	;@2266
	mov al, byte ptr MapType	;@2268
	cmp al, 0	;@226B
	je L2272	;@226D
	jmp TownTurnNextMonster	; town loop (EVENTS)	;@226F
L2272:	jmp OutdoorMonsters_Next	; surface loop (MAIN)	;@2272

;------------------------------------------------------------------------------
; IllegalCommand: "-ILLEGAL COMMAND!" for keys that are not commands (MAIN 09FF, 0A1C),
; then beep and end the turn (EndCommandBeep).
;------------------------------------------------------------------------------
IllegalCommand:	call PrintInline	;@2275
	db 2Dh,49h,4Ch,4Ch,45h,47h,41h,4Ch,20h,43h,4Fh,4Dh,4Dh,41h,4Eh,44h	; "-ILLEGAL COMMAND!"	;@2278
	db 21h,0h	;@2288
	jmp EndCommandBeep	;@228A

;------------------------------------------------------------------------------
; DieOfStarvation: the food has run out (MAIN 0930, MOVE 25BD/264B): the player dies (PlayerDies).
;------------------------------------------------------------------------------
DieOfStarvation:	jmp PlayerDies	;@228D
CODE ENDS
END
