; INPUT.ASM: number and money entry, "illegal command".
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 2028-2290.
;
; Despite the name, about half of this module is monster movement. Entry points:
;   L2028 read a digit 0-9 (shops, Magic, Ready, Wear)
;   L2052 pay the price D_0027/D_0028 in gold, or abort the command ("YOU DONT HAVE THAT MUCH!")
;   L20AB compute a shop price from an item number, Intelligence and Charisma (BCD Fibonacci)
;   L2122 move a monster one square toward/away from the player (surface and towns);
;         L2199 tells whether a monster may enter a tile, L2201 does the move
;   L2275 "-ILLEGAL COMMAND!"; L228D death by starvation
; Data: the monster table, 8 arrays of 32 bytes loaded from the MONxxx file: D_0137 x, D_0157 y,
; D_0177 hit points, D_0197 tile (0 = free slot), D_01B7 the map tile under the monster, D_01D7
; town behaviour, D_01F7/D_0217 wander direction. Gold D_0058/D_0059 (BCD). Monster tiles and
; terrain here are full map bytes: 00 water, 04 marsh, 08 grass, 0Ch woods, 10h mountains,
; 5Ch force field, 70h town floor.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0000:BYTE, D_0001:BYTE, D_0006:BYTE, D_0019:BYTE, D_001A:BYTE, D_001F:BYTE
	EXTRN D_0020:BYTE, D_0023:BYTE, D_0024:BYTE, D_0027:BYTE, D_0028:BYTE, D_0029:BYTE
	EXTRN D_002A:BYTE, D_004A:BYTE, D_004E:BYTE, D_0050:BYTE, D_0058:BYTE, D_0059:BYTE
	EXTRN D_0137:BYTE, D_0157:BYTE, D_0177:BYTE, D_0197:BYTE, D_01B7:BYTE, D_026A:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L0A30:NEAR, L0AA1:NEAR, L0C62:NEAR, L1040:NEAR, L4F4D:NEAR, L4FDF:NEAR
	EXTRN L50B3:NEAR, L53F4:NEAR
	PUBLIC L2028, L2052, L20AB, L2122, L2201, L2275
	PUBLIC L228D
ASSUME CS:CODE, DS:DATA

;------------------------------------------------------------------------------
; L2028: wait for a digit key '0'-'9' (other keys are ignored), echo it and a
; CR (8Dh). Out: AL = DI = the value 0-9, AH = 0, ZF set if 0. Uses: AX, DI.
;------------------------------------------------------------------------------
L2028:	nop	;@2028
	call L4F4D	; poll the keyboard: AH = FFh if a key came	;@2029
	cmp ah, 0FFh	;@202C
	jne L2028	;@202F
	cmp al, 30h	; '0'	;@2031
	jb L2028	;@2033
	cmp al, 39h	; '9'	;@2035
	ja L2028	;@2037
	stc	;@2039
	cmc	;@203A
	sbb al, 30h	; ASCII -> 0-9	;@203B
	cmc	;@203D
	mov ah, 0	;@203E
	mov di, ax	;@2040
	clc	;@2042
	adc al, 30h	;@2043
	call L53F4	; echo the digit	;@2045
	mov al, 8Dh	; CR	;@2048
	call L53F4	;@204A
	mov ax, di	;@204D
	cmp al, 0	;@204F
	ret	;@2051

;------------------------------------------------------------------------------
; L2052: pay a price: gold D_0058/D_0059 -= D_0027/D_0028 (4-digit BCD, high
; byte first). If the gold is not enough, the subtraction is undone, the caller
; is dropped and "YOU DONT HAVE THAT MUCH!" ends the turn (L0A30).
; Out: AL = 0 (paid). Uses: AX.
;------------------------------------------------------------------------------
L2052:	nop	;@2052
	stc	;@2053
	mov al, byte ptr D_0059	; gold, low BCD byte	;@2054
	cmc	;@2057
	sbb al, byte ptr D_0028	; price, low	;@2058
	das	;@205C
	cmc	;@205D
	mov byte ptr D_0059, al	;@205E
	mov al, byte ptr D_0058	; gold, high BCD byte	;@2061
	cmc	;@2064
	sbb al, byte ptr D_0027	; price, high	;@2065
	das	;@2069
	cmc	;@206A
	mov byte ptr D_0058, al	;@206B
	jb L20A7	; no borrow: paid	;@206E
	clc	; too poor: add the price back	;@2070
	mov al, byte ptr D_0059	;@2071
	adc al, byte ptr D_0028	;@2074
	daa	;@2078
	mov byte ptr D_0059, al	;@2079
	mov al, byte ptr D_0058	;@207C
	adc al, byte ptr D_0027	;@207F
	daa	;@2083
	mov byte ptr D_0058, al	;@2084
	pop ax	; forget the caller	;@2087
	call L4FDF	;@2088
	db 59h,4Fh,55h,20h,44h,4Fh,4Eh,54h,20h,48h,41h,56h,45h,20h,54h,48h	; "YOU DONT HAVE THAT MUCH!"	;@208B
	db 41h,54h,20h,4Dh,55h,43h,48h,21h,0h	;@209B
	jmp L0A30	; beep, end of turn	;@20A4
L20A7:	nop	;@20A7
	mov al, 0	;@20A8
	ret	;@20AA

;------------------------------------------------------------------------------
; L20AB: compute a shop price. The price runs through the BCD Fibonacci-like
; series 4, 8, 12, 20, 32, 52, 84, ... (each term = the sum of the two before):
; n = AL + 8 - (number of significant bits of Intelligence + Charisma) steps.
; Better Intelligence and Charisma make things cheaper.
; In: AL = item / price class. Out: D_0027/D_0028 = price (BCD, high/low).
; Uses: AX, BX, SI, DI, D_0020, D_0029/D_002A (the previous term). If n comes
; out 0 the loop runs 65536 times (not expected to happen).
;------------------------------------------------------------------------------
L20AB:	nop	;@20AB
	clc	;@20AC
	adc al, 8	;@20AD
	mov byte ptr D_0020, al	; AL + 8	;@20AF
	mov al, 0	;@20B2
	mov byte ptr D_0027, al	; price = 0004	;@20B4
	mov byte ptr D_0029, al	; previous = 0004	;@20B7
	mov al, 4	;@20BA
	mov byte ptr D_0028, al	;@20BC
	mov byte ptr D_002A, al	;@20BF
	mov al, byte ptr D_0050	; Intelligence	;@20C2
	adc al, byte ptr D_004E	; + Charisma (CF is 0 here)	;@20C5
	mov bh, 0	;@20C9
	mov bl, 0	;@20CB
	mov si, bx	;@20CD
L20CF:	inc si	; SI = number of significant bits of AL	;@20CF
	clc	;@20D0
	rcr al, 1	;@20D1
	or al, al	;@20D3
	jne L20CF	;@20D5
	mov al, byte ptr D_0020	;@20D7
	mov bx, si	;@20DA
	mov byte ptr D_0020, bl	;@20DC
	stc	;@20E0
	cmc	;@20E1
	sbb al, byte ptr D_0020	; n = AL + 8 - bits	;@20E2
	cmc	;@20E6
	mov ah, 0	;@20E7
	mov di, ax	;@20E9
; (price, previous) := (price + previous, price), n times, in BCD.
L20EB:	clc	;@20EB
	mov al, byte ptr D_002A	;@20EC
	adc al, byte ptr D_0028	;@20EF
	daa	;@20F3
	mov bh, 0	;@20F4
	mov bl, byte ptr D_0028	;@20F6
	mov si, bx	;@20FA
	mov bx, si	;@20FC
	mov byte ptr D_002A, bl	; previous low = old price low	;@20FE
	mov byte ptr D_0028, al	; price low = sum	;@2102
	mov al, byte ptr D_0029	;@2105
	adc al, byte ptr D_0027	; high bytes, with the carry	;@2108
	daa	;@210C
	mov bh, 0	;@210D
	mov bl, byte ptr D_0027	;@210F
	mov si, bx	;@2113
	mov bx, si	;@2115
	mov byte ptr D_0029, bl	;@2117
	mov byte ptr D_0027, al	;@211B
	dec di	;@211E
	jne L20EB	;@211F
	ret	;@2121

;------------------------------------------------------------------------------
; L2122: move monster DI one square in the direction D_0019/D_001A (-1/0/+1,
; set by the caller toward the player, or away when the monster flees). First
; the monster heals 1 hit point if it has fewer than 10h. Tries the diagonal,
; then the vertical step (if dy <> 0), then the horizontal one, each checked by
; L2199; the first that is allowed is done by L2201. Coordinates wrap at 64.
; Jumped to (not called) from MAIN's surface monster loop and EVENTS' town loop;
; goes back to the loop at L218B (L1040 in towns, L0AA1 on the surface).
;------------------------------------------------------------------------------
L2122:	mov al, byte ptr D_0177[di]	; monster hit points	;@2122
	cmp al, 10h	;@2126
	jae L212E	;@2128
	inc byte ptr D_0177[di]	; heal 1	;@212A
L212E:	clc	;@212E
	mov al, byte ptr D_0137[di]	;@212F
	adc al, byte ptr D_0019	;@2133
	and al, 3Fh	;@2137
	mov byte ptr D_0023, al	; x + dx	;@2139
	clc	;@213C
	mov al, byte ptr D_0157[di]	;@213D
	adc al, byte ptr D_001A	;@2141
	and al, 3Fh	;@2145
	mov byte ptr D_0024, al	; y + dy	;@2147
	call L50B3	; AL = map tile there	;@214A
	call L2199	;@214D
	jne L2155	;@2150
	jmp L2201	;@2152
L2155:	mov al, byte ptr D_001A	; diagonal blocked: try (x, y + dy)	;@2155
	cmp al, 0	;@2158
	je L216E	;@215A
	mov al, byte ptr D_0137[di]	;@215C
	mov byte ptr D_0023, al	;@2160
	call L50B3	;@2163
	call L2199	;@2166
	jne L216E	;@2169
	jmp L2201	;@216B
L216E:	clc	; then (x + dx, y)	;@216E
	mov al, byte ptr D_0137[di]	;@216F
	adc al, byte ptr D_0019	;@2173
	and al, 3Fh	;@2177
	mov byte ptr D_0023, al	;@2179
	mov al, byte ptr D_0157[di]	;@217C
	mov byte ptr D_0024, al	;@2180
	call L50B3	;@2183
	call L2199	;@2186
	je L2201	;@2189
; Done with this monster: back to the loop that called.
L218B:	mov al, byte ptr D_004A	;@218B
	cmp al, 0	;@218E
	je L2195	;@2190
	jmp L1040	; town loop (EVENTS)	;@2192
L2195:	nop	;@2195
	jmp L0AA1	; surface loop (MAIN)	;@2196

;------------------------------------------------------------------------------
; L2199: may monster DI enter the tile AL at D_0023/D_0024?
; No monster moves while time is negated (D_026A). Monster tiles 2Ch and 48h
; (sea monsters; 48h is the frigate's tile) only move on water. Other monsters
; below tile 78h may cross force fields (5Ch). Otherwise: not water, marsh or
; mountains; yes on grass and woods (below 14h) and town floor (70h). In towns
; the row and column 0 are closed.
; Out: AL = 0, ZF = 1: yes; AL = FFh, ZF = 0: no. Uses: AL, D_001F.
;------------------------------------------------------------------------------
L2199:	mov byte ptr D_001F, al	; the target tile	;@2199
	mov al, byte ptr D_026A	; time-stop turns (N)egate	;@219C
	cmp al, 0	;@219F
	je L21A6	;@21A1
	jmp L21FC	;@21A3
L21A6:	mov al, byte ptr D_0197[di]	; the monster's tile	;@21A6
	cmp al, 2Ch	;@21AA
	je L21D8	;@21AC
	cmp al, 48h	;@21AE
	je L21D8	;@21B0
	cmp al, 78h	;@21B2
	jae L21BD	;@21B4
	mov al, byte ptr D_001F	;@21B6
	cmp al, 5Ch	; force field	;@21B9
	je L21E2	;@21BB
L21BD:	nop	;@21BD
	mov al, byte ptr D_001F	;@21BE
	cmp al, 10h	; mountains	;@21C1
	je L21FC	;@21C3
	cmp al, 4	; marsh	;@21C5
	je L21FC	;@21C7
	cmp al, 0	; water	;@21C9
	je L21FC	;@21CB
	cmp al, 14h	; grass, woods	;@21CD
	jb L21E2	;@21CF
	cmp al, 70h	; town floor	;@21D1
	je L21E2	;@21D3
	jmp L21FC	;@21D5
L21D8:	mov al, byte ptr D_001F	; sea monster: water only	;@21D8
	cmp al, 0	;@21DB
	jne L21FC	;@21DD
	jmp L21E2	;@21DF
L21E2:	mov al, byte ptr D_004A	; in a town, not onto row or column 0	;@21E2
	cmp al, 0	;@21E5
	je L21F7	;@21E7
	mov al, byte ptr D_0023	;@21E9
	cmp al, 0	;@21EC
	je L21FC	;@21EE
	mov al, byte ptr D_0024	;@21F0
	cmp al, 0	;@21F3
	je L21FC	;@21F5
L21F7:	mov al, 0	; yes	;@21F7
	cmp al, 0	;@21F9
	ret	;@21FB
L21FC:	mov al, 0FFh	; no	;@21FC
	cmp al, 0	;@21FE
	ret	;@2200

;------------------------------------------------------------------------------
; L2201: move monster DI to D_0023/D_0024 (unless that is the player's square):
; the old square gets back the tile the monster stood on (D_01B7), the monster
; takes the new position, remembers the tile there and is drawn into the map.
; Then back to the monster loop (L218B: L1040 in towns, L0AA1 on the surface).
; Also jumped to from the town wander code (EVENTS 1137).
;------------------------------------------------------------------------------
L2201:	mov al, byte ptr D_0000	;@2201
	cmp al, byte ptr D_0023	;@2204
	jne L2216	;@2208
	mov al, byte ptr D_0001	;@220A
	cmp al, byte ptr D_0024	;@220D
	jne L2216	;@2211
	jmp L218B	; that is the player: stay	;@2213
L2216:	mov al, byte ptr D_0023	;@2216
	mov byte ptr D_0027, al	; keep the new x/y	;@2219
	mov al, byte ptr D_0024	;@221C
	mov byte ptr D_0028, al	;@221F
	mov al, byte ptr D_0137[di]	;@2222
	mov byte ptr D_0023, al	;@2226
	mov al, byte ptr D_0157[di]	;@2229
	mov byte ptr D_0024, al	;@222D
	call L50B3	; D_0006 -> the old map cell	;@2230
	mov al, byte ptr D_01B7[di]	; the tile under the monster	;@2233
	mov bh, 0	;@2237
	mov bl, 0	;@2239
	mov si, bx	;@223B
	mov bx, word ptr D_0006	;@223D
	mov byte ptr [bx+si], al	; restore it	;@2241
	mov al, byte ptr D_0027	;@2243
	mov byte ptr D_0023, al	;@2246
	mov byte ptr D_0137[di], al	; new x	;@2249
	mov al, byte ptr D_0028	;@224D
	mov byte ptr D_0024, al	;@2250
	mov byte ptr D_0157[di], al	; new y	;@2253
	call L50B3	; AL = the tile at the new square	;@2257
	mov byte ptr D_01B7[di], al	;@225A
	mov al, byte ptr D_0197[di]	;@225E
	mov bx, word ptr D_0006	;@2262
	mov byte ptr [bx+si], al	; put the monster on the map	;@2266
	mov al, byte ptr D_004A	;@2268
	cmp al, 0	;@226B
	je L2272	;@226D
	jmp L1040	; town loop (EVENTS)	;@226F
L2272:	jmp L0AA1	; surface loop (MAIN)	;@2272

;------------------------------------------------------------------------------
; L2275: "-ILLEGAL COMMAND!" for keys that are not commands (MAIN 09FF, 0A1C),
; then beep and end the turn (L0A30).
;------------------------------------------------------------------------------
L2275:	call L4FDF	;@2275
	db 2Dh,49h,4Ch,4Ch,45h,47h,41h,4Ch,20h,43h,4Fh,4Dh,4Dh,41h,4Eh,44h	; "-ILLEGAL COMMAND!"	;@2278
	db 21h,0h	;@2288
	jmp L0A30	;@228A

;------------------------------------------------------------------------------
; L228D: the food has run out (MAIN 0930, MOVE 25BD/264B): the player dies (L0C62).
;------------------------------------------------------------------------------
L228D:	jmp L0C62	;@228D
CODE ENDS
END
