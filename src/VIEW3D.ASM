; VIEW3D.ASM: the 3D dungeon and tower view, line drawing.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 6000-6999.
;
; The first-person wireframe view of dungeons and towers. L6000 (called by EVENTS at 12CD
; after every turn underground) looks up the cells under, ahead of and behind the player
; (D_0014/D_0015/D_0016) and, while a light burns (D_0026 = light turns left), draws the view:
;  - L6078 collects the cells of the 8 rows ahead (depth 0 = the player's cell): left of,
;    on and right of the line of sight, high nibble in D_048F[d], D_0497[d], D_049F[d], and
;    the low 3 bits of the centre cell (a monster) in D_04AF[d];
;  - L6144 clears the screen and draws depth by depth: front wall (L6425) with a door
;    (L648D), left/right walls (L6377/L63CE) with doors (L64E2/L653F) or side openings
;    (L6291/L6304), ladders down/up (L6594/L660C + pole L6684) and chests (L66CB), until a
;    wall blocks the view; D_0482 = the current depth;
;  - L68ED draws the nearest monster from its shape in the monster buffer (D_0474).
; Every line goes through L67B3 (Bresenham line from D_0479/D_047A to D_047B/D_047C, pixels
; by L4B76 in SCREEN, offset by D_04BF/D_04C1). All screen coordinates come from one CS
; table, L620D (layout at the table). The view is 256x128 pixels.
; Map: dungeon level D_0025 is page D_0025 of the map buffer (D_0472), 16x16 cells,
; offset Y*16+X (L68C0). Cell high nibble, as drawn here and tested by the commands:
;   80h wall, C0h door, E0h secret door (drawn as a wall, passable), 20h ladder down
;   (D)escend), 10h ladder up (K)limb), 40h chest (G)et); low bits: a monster (and 7 here).
; Position D_0000/D_0001, facing (dx, dy) in D_0002/D_0003 (signed bytes).
; The CS variables at 6990-6998 belong to space flight (SPACE, ENDGAME), not to the view.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0000:BYTE, D_0001:BYTE, D_0002:BYTE, D_0003:BYTE, D_0004:BYTE, D_0005:BYTE
	EXTRN D_0014:BYTE, D_0015:BYTE, D_0016:BYTE, D_0023:BYTE, D_0024:BYTE, D_0025:BYTE
	EXTRN D_0026:BYTE, D_0472:BYTE, D_0474:BYTE, D_0479:BYTE, D_047A:BYTE, D_047B:BYTE
	EXTRN D_047C:BYTE, D_047D:BYTE, D_047E:BYTE, D_047F:BYTE, D_0480:BYTE, D_0481:BYTE
	EXTRN D_0482:BYTE, D_0483:BYTE, D_0484:BYTE, D_0487:BYTE, D_0488:BYTE, D_0489:BYTE
	EXTRN D_048A:BYTE, D_048F:BYTE, D_0497:BYTE, D_049F:BYTE, D_04AF:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L4B4E:NEAR, L4B76:NEAR, L4BE0:NEAR
	PUBLIC L6000, L6990, L6992, L6994, L6996, L6997
	PUBLIC L6998
ASSUME CS:CODE, DS:DATA
;------------------------------------------------------------------------------
; L6000: after a turn underground: if a light burns (D_0026 <> 0), collect the cells ahead
; (L6078), draw the view (L6144) and the nearest monster (L68ED). Always: D_0014 = cell
; under the player, D_0015 = the cell ahead, D_0016 = the cell behind (full bytes).
; In: D_0000/D_0001 position, D_0002/D_0003 facing, D_0025 level, D_0026.
; Out: D_0014-D_0016, D_0023/D_0024. Uses: AX, BX, SI, DI, BP, the line variables.
;------------------------------------------------------------------------------
L6000:	nop	;@6000
	mov al, byte ptr D_0002	; facing dx	;@6001
	mov byte ptr D_0483, al	;@6004
	mov al, byte ptr D_0003	; facing dy	;@6007
	mov byte ptr D_0484, al	;@600A
	cmp byte ptr D_0026, 0	; light burning?	;@600D
	je L601D	;@6012
	call L6078	;@6014
	call L6144	;@6017
	call L68ED	;@601A
; D_0483/D_0484 again (the line drawing used them), then the three cells.
L601D:	mov al, byte ptr D_0002	;@601D
	mov byte ptr D_0483, al	;@6020
	mov al, byte ptr D_0003	;@6023
	mov byte ptr D_0484, al	;@6026
	mov al, byte ptr D_0000	;@6029
	mov byte ptr D_0023, al	;@602C
	mov al, byte ptr D_0001	;@602F
	mov byte ptr D_0024, al	;@6032
	call L68C0	; cell under the player	;@6035
	mov byte ptr D_0014, al	;@6038
	mov al, byte ptr D_0000	;@603B
	clc	;@603E
	adc al, byte ptr D_0483	;@603F
	mov byte ptr D_0023, al	;@6043
	mov al, byte ptr D_0001	;@6046
	clc	;@6049
	adc al, byte ptr D_0484	;@604A
	mov byte ptr D_0024, al	;@604E
	call L68C0	; cell ahead	;@6051
	mov byte ptr D_0015, al	;@6054
	mov al, byte ptr D_0000	;@6057
	stc	; stc/cmc/sbb = plain subtract	;@605A
	cmc	;@605B
	sbb al, byte ptr D_0483	;@605C
	cmc	;@6060
	mov byte ptr D_0023, al	;@6061
	mov al, byte ptr D_0001	;@6064
	stc	;@6067
	cmc	;@6068
	sbb al, byte ptr D_0484	;@6069
	cmc	;@606D
	mov byte ptr D_0024, al	;@606E
	call L68C0	; cell behind	;@6071
	mov byte ptr D_0016, al	;@6074
	ret	;@6077
;------------------------------------------------------------------------------
; L6078: collect the cells ahead. Three walkers start at the player: left (D_0479/D_047A)
; = position + (dy, -dx), centre (D_047B/D_047C) = position, right (D_047D/D_047E) =
; position - (dy, -dx), with the facing (dx, dy) in D_0483/D_0484; for d = 0..7 each reads
; its cell (coordinates and 3Fh) and steps one cell forward. Stores the high nibbles in
; D_048F[d] (left), D_0497[d] (centre), D_049F[d] (right) and the centre cell and 7 (the
; monster) in D_04AF[d].
; In: D_0000/D_0001, D_0483/D_0484, D_0025. Out: the four arrays. Uses: AX, BX, SI, DI.
;------------------------------------------------------------------------------
L6078:	clc	;@6078
	mov al, byte ptr D_0000	;@6079
	mov byte ptr D_047B, al	;@607C
	adc al, byte ptr D_0484	;@607F
	mov byte ptr D_0479, al	; left walker X = X + dy	;@6083
	stc	;@6086
	mov al, byte ptr D_0001	;@6087
	mov byte ptr D_047C, al	;@608A
	cmc	;@608D
	sbb al, byte ptr D_0483	;@608E
	cmc	;@6092
	mov byte ptr D_047A, al	; left walker Y = Y - dx	;@6093
	stc	;@6096
	mov al, byte ptr D_0000	;@6097
	cmc	;@609A
	sbb al, byte ptr D_0484	;@609B
	cmc	;@609F
	mov byte ptr D_047D, al	; right walker X = X - dy	;@60A0
	clc	;@60A3
	mov al, byte ptr D_0001	;@60A4
	adc al, byte ptr D_0483	;@60A7
	mov byte ptr D_047E, al	; right walker Y = Y + dx	;@60AB
	mov bh, 0	;@60AE
	mov bl, 0	;@60B0
	mov di, bx	;@60B2
; d = DI = 0..7
L60B4:	mov al, byte ptr D_0479	;@60B4
	and al, 3Fh	;@60B7
	mov byte ptr D_0023, al	;@60B9
	clc	;@60BC
	adc al, byte ptr D_0483	;@60BD
	mov byte ptr D_0479, al	; step forward	;@60C1
	mov al, byte ptr D_047A	;@60C4
	and al, 3Fh	;@60C7
	mov byte ptr D_0024, al	;@60C9
	clc	;@60CC
	adc al, byte ptr D_0484	;@60CD
	mov byte ptr D_047A, al	;@60D1
	call L68C0	;@60D4
	and al, 0F0h	; left cell, high nibble	;@60D7
	mov byte ptr D_048F[di], al	;@60D9
	mov al, byte ptr D_047B	;@60DD
	and al, 3Fh	;@60E0
	mov byte ptr D_0023, al	;@60E2
	clc	;@60E5
	adc al, byte ptr D_0483	;@60E6
	mov byte ptr D_047B, al	;@60EA
	mov al, byte ptr D_047C	;@60ED
	and al, 3Fh	;@60F0
	mov byte ptr D_0024, al	;@60F2
	clc	;@60F5
	adc al, byte ptr D_0484	;@60F6
	mov byte ptr D_047C, al	;@60FA
	call L68C0	;@60FD
	and al, 0F0h	; centre cell, high nibble	;@6100
	mov byte ptr D_0497[di], al	;@6102
	call L68C0	;@6106
	and al, 7	; centre cell, low bits = monster	;@6109
	mov byte ptr D_04AF[di], al	;@610B
	mov al, byte ptr D_047D	;@610F
	and al, 3Fh	;@6112
	mov byte ptr D_0023, al	;@6114
	clc	;@6117
	adc al, byte ptr D_0483	;@6118
	mov byte ptr D_047D, al	;@611C
	mov al, byte ptr D_047E	;@611F
	and al, 3Fh	;@6122
	mov byte ptr D_0024, al	;@6124
	clc	;@6127
	adc al, byte ptr D_0484	;@6128
	mov byte ptr D_047E, al	;@612C
	call L68C0	;@612F
	and al, 0F0h	; right cell, high nibble	;@6132
	mov byte ptr D_049F[di], al	;@6134
	inc di	;@6138
	mov bx, di	;@6139
	cmp bl, 8	; 8 rows	;@613B
	jae L6143	;@613E
	jmp L60B4	;@6140
L6143:	ret	;@6143
;------------------------------------------------------------------------------
; L6144: draw the walls. Clears the screen, draws the frame (depth 0 rectangle), then for
; d = D_0482 = 0, 1, ...: if the cell ahead at depth d is a wall, draw its face (and a door
; in it) and stop; else draw a ladder or chest in it, the left and right walls (or the
; side openings) of depth d, and go on (at most to depth 6).
; In: the arrays from L6078. Out: D_0482 = the last depth drawn (L68ED uses it).
; Uses: AX, BX, DI and the line variables.
;------------------------------------------------------------------------------
L6144:	call L4B4E	; clear the screen (both CGA banks)	;@6144
	mov al, 0	;@6147
	mov byte ptr D_0482, al	;@6149
	call L6425	; frame of the view	;@614C
; Next depth: DI = d.
L614F:	mov bh, 0	;@614F
	mov bl, byte ptr D_0482	;@6151
	mov di, bx	;@6155
	mov al, byte ptr D_0497[di]	;@6157
	or al, al	;@615B
	jns L6192	; bit 7: wall ahead?	;@615D
	call L6425	; its face	;@615F
	mov al, byte ptr D_0497[di]	;@6162
	and al, 40h	; 40h: door?	;@6166
	jne L616D	;@6168
	jmp L620C	;@616A
L616D:	mov al, byte ptr D_0497[di]	;@616D
	and al, 20h	; 20h too: secret door, looks like a wall	;@6171
	je L6178	;@6173
	jmp L620C	;@6175
L6178:	call L648D	; door in it	;@6178
	mov al, byte ptr D_0482	;@617B
	or al, al	; a door in the player's own cell: look on through it	;@617E
	je L6185	;@6180
	jmp L620C	;@6182
L6185:	inc byte ptr D_0482	;@6185
	mov al, byte ptr D_0482	;@6189
	cmp al, 8	; limit 8 on this path (7 below)	;@618C
	jae L620C	;@618E
	jmp L614F	;@6190
; Open cell: ladder down, ladder up or chest in it.
L6192:	mov al, byte ptr D_0497[di]	;@6192
	and al, 20h	; 20h: ladder down	;@6196
	je L619D	;@6198
	call L6594	;@619A
L619D:	mov al, byte ptr D_0497[di]	;@619D
	and al, 10h	; 10h: ladder up	;@61A1
	je L61AB	;@61A3
	call L660C	;@61A5
	jmp L61B6	;@61A8
L61AB:	mov al, byte ptr D_0497[di]	;@61AB
	and al, 40h	; 40h: chest	;@61AF
	je L61B6	;@61B1
	call L66CB	;@61B3
; Left side: wall (and door in it) or opening.
L61B6:	mov al, byte ptr D_048F[di]	;@61B6
	or al, al	; left wall?	;@61BA
	jns L61D7	;@61BC
	call L6377	; its edges	;@61BE
	mov al, byte ptr D_048F[di]	;@61C1
	and al, 40h	;@61C5
	je L61DA	;@61C7
	mov al, byte ptr D_048F[di]	;@61C9
	and al, 20h	;@61CD
	jne L61DA	;@61CF
	call L64E2	; door (40h without 20h)	;@61D1
	jmp L61DA	;@61D4
L61D7:	call L6291	; left side open	;@61D7
; Right side.
L61DA:	mov al, byte ptr D_049F[di]	;@61DA
	or al, al	; right wall?	;@61DE
	jns L61FB	;@61E0
	call L63CE	;@61E2
	mov al, byte ptr D_049F[di]	;@61E5
	and al, 40h	;@61E9
	je L61FE	;@61EB
	mov al, byte ptr D_049F[di]	;@61ED
	and al, 20h	;@61F1
	jne L61FE	;@61F3
	call L653F	;@61F5
	jmp L61FE	;@61F8
L61FB:	call L6304	; right side open	;@61FB
L61FE:	inc byte ptr D_0482	;@61FE
	mov al, byte ptr D_0482	;@6202
	cmp al, 7	; at most depth 6	;@6205
	jae L620C	;@6207
	jmp L614F	;@6209
L620C:	ret	;@620C
;------------------------------------------------------------------------------
; L620D: the screen coordinates of the view, one table of byte rows indexed by the depth
; d (0 = the player's cell). Several rows are also read at d+1, d+2, d+3 through the labels
; inside the table (L620E = L620D+1 ...). X runs 0-FFh, Y 0-7Fh; the right half mirrors the
; left (x' = FFh-x), the bottom half the top (y' = 7Fh-y).
;   +00h (10 bytes) XL: left edge of the depth-d rectangle   (L620E/L620F/L6210 = +01h..+03h)
;   +0Ah (10 bytes) XR: right edge = FFh-XL                    (L6218/L6219/L621A = +0Bh..+0Dh)
;   +14h YT: top edge                                          (L6222 = +15h)
;   +1Ch YB: bottom edge = 7Fh-YT                              (L622A = +1Dh)
;   +24h, +2Ch: x of the near and far jamb of a door in the left wall (L6232, L623A = d+1:
;         x of the near/far corners of a ladder hole, left side)
;   +34h, +3Ch: the same for the right wall (L6242, L624A = d+1, ladder hole right side)
;   +44h: y of the near jamb foot of a side door; the chest front bottom
;   +4Ch: y of the far jamb foot of a side door; the chest back edge
;   +54h: y of the far jamb top of a side door (the near jamb top is YT[d+1])
;   +5Ch, +64h: y of the near/far edge of a ladder hole in the ceiling (+5Ch = pole top)
;   +6Ch, +74h: y of the near/far edge of a ladder hole in the floor (+6Ch = pole foot)
;   +7Ch: y of the chest front top. The table ends at +84h (6291).
;------------------------------------------------------------------------------
L620D label byte
	db 0h	;@620D
L620E label byte
	db 40h	;@620E
L620F label byte
	db 60h	;@620F
L6210 label byte
	db 70h,78h,7Ch,7Eh,7Fh,7Fh,7Fh	;@6210
L6217 label byte
	db 0FFh	;@6217
L6218 label byte
	db 0BFh	;@6218
L6219 label byte
	db 9Fh	;@6219
L621A label byte
	db 8Fh,87h,83h,81h,80h,80h,80h	;@621A
L6221 label byte
	db 0h	;@6221
L6222 label byte
	db 20h,30h,38h,3Ch,3Eh,3Fh,3Fh	;@6222
L6229 label byte
	db 7Fh	;@6229
L622A label byte
	db 5Fh,4Fh,47h,43h,41h,40h,40h	;@622A
L6231 label byte
	db 10h	;@6231
L6232 label byte
	db 48h,64h,72h,79h,7Ch,7Fh,7Fh	;@6232
L6239 label byte
	db 30h	;@6239
L623A label byte
	db 58h,6Ch,76h,7Bh,7Ch,7Fh,7Fh	;@623A
L6241 label byte
	db 0EFh	;@6241
L6242 label byte
	db 0B7h,9Bh,8Dh,86h,83h,80h,80h	;@6242
L6249 label byte
	db 0CFh	;@6249
L624A label byte
	db 0A7h,93h,89h,84h,83h,80h,80h	;@624A
L6251 label byte
	db 77h,5Bh,4Dh,46h,42h,40h,40h,40h	;@6251
L6259 label byte
	db 67h,53h,49h,44h,42h,40h,40h,40h	;@6259
L6261 label byte
	db 2Ah,35h,3Bh,3Dh,3Eh,3Fh,3Fh,3Fh	;@6261
L6269 label byte
	db 8h,24h,32h,39h,3Ch,3Eh,3Fh,3Fh	;@6269
L6271 label byte
	db 18h,2Ch,36h,3Ah,3Dh,3Eh,3Fh,3Fh	;@6271
L6279 label byte
	db 77h,5Bh,4Dh,46h,43h,41h,40h,40h	;@6279
L6281 label byte
	db 67h,53h,49h,45h,42h,41h,40h,40h	;@6281
L6289 label byte
	db 6Fh,57h,4Bh,45h,42h,40h,40h,40h	;@6289
;------------------------------------------------------------------------------
; L6291: left side open at depth d: the near corner edge (x = XL[d]) and the face of the
; wall across the side passage (rectangle edge at depth d+1).
; In: D_0482 = d. Out: DI = d. Uses: AX, BX, DI and the line variables (also L6304-L66CB).
;------------------------------------------------------------------------------
L6291:	mov bh, 0	;@6291
	mov bl, byte ptr D_0482	;@6293
	mov di, bx	;@6297
	mov al, byte ptr cs:L620D[di]	;@6299
	mov byte ptr D_0479, al	;@629E
	mov byte ptr D_047B, al	;@62A1
	mov al, byte ptr cs:L6221[di]	;@62A4
	mov byte ptr D_047A, al	;@62A9
	mov al, byte ptr cs:L6229[di]	;@62AC
	mov byte ptr D_047C, al	;@62B1
	call L67B3	;@62B4
	mov bh, 0	;@62B7
	mov bl, byte ptr D_0482	;@62B9
	mov di, bx	;@62BD
	mov al, byte ptr cs:L6222[di]	;@62BF
	mov byte ptr D_047A, al	;@62C4
	mov byte ptr D_047C, al	;@62C7
	mov al, byte ptr cs:L620E[di]	;@62CA
	mov byte ptr D_047B, al	;@62CF
	call L67B3	;@62D2
	mov bh, 0	;@62D5
	mov bl, byte ptr D_0482	;@62D7
	mov di, bx	;@62DB
	mov al, byte ptr cs:L622A[di]	;@62DD
	mov byte ptr D_047C, al	;@62E2
	call L67B3	;@62E5
	mov bh, 0	;@62E8
	mov bl, byte ptr D_0482	;@62EA
	mov di, bx	;@62EE
	mov al, byte ptr cs:L620D[di]	;@62F0
	mov byte ptr D_047B, al	;@62F5
	call L67B3	;@62F8
	mov bh, 0	;@62FB
	mov bl, byte ptr D_0482	;@62FD
	mov di, bx	;@6301
	ret	;@6303
;------------------------------------------------------------------------------
; L6304: right side open at depth d (mirror of L6291).
; In: D_0482 = d. Out: DI = d.
;------------------------------------------------------------------------------
L6304:	mov bh, 0	;@6304
	mov bl, byte ptr D_0482	;@6306
	mov di, bx	;@630A
	mov al, byte ptr cs:L6217[di]	;@630C
	mov byte ptr D_0479, al	;@6311
	mov byte ptr D_047B, al	;@6314
	mov al, byte ptr cs:L6221[di]	;@6317
	mov byte ptr D_047A, al	;@631C
	mov al, byte ptr cs:L6229[di]	;@631F
	mov byte ptr D_047C, al	;@6324
	call L67B3	;@6327
	mov bh, 0	;@632A
	mov bl, byte ptr D_0482	;@632C
	mov di, bx	;@6330
	mov al, byte ptr cs:L6222[di]	;@6332
	mov byte ptr D_047A, al	;@6337
	mov byte ptr D_047C, al	;@633A
	mov al, byte ptr cs:L6218[di]	;@633D
	mov byte ptr D_047B, al	;@6342
	call L67B3	;@6345
	mov bh, 0	;@6348
	mov bl, byte ptr D_0482	;@634A
	mov di, bx	;@634E
	mov al, byte ptr cs:L622A[di]	;@6350
	mov byte ptr D_047C, al	;@6355
	call L67B3	;@6358
	mov bh, 0	;@635B
	mov bl, byte ptr D_0482	;@635D
	mov di, bx	;@6361
	mov al, byte ptr cs:L6217[di]	;@6363
	mov byte ptr D_047B, al	;@6368
	call L67B3	;@636B
	mov bh, 0	;@636E
	mov bl, byte ptr D_0482	;@6370
	mov di, bx	;@6374
	ret	;@6376
;------------------------------------------------------------------------------
; L6377: left wall at depth d: its top and bottom edges, from depth d to depth d+1.
; In: D_0482 = d. Out: DI = d.
;------------------------------------------------------------------------------
L6377:	mov bh, 0	;@6377
	mov bl, byte ptr D_0482	;@6379
	mov di, bx	;@637D
	mov al, byte ptr cs:L620D[di]	;@637F
	mov byte ptr D_0479, al	;@6384
	mov al, byte ptr cs:L620E[di]	;@6387
	mov byte ptr D_047B, al	;@638C
	mov al, byte ptr cs:L6221[di]	;@638F
	mov byte ptr D_047A, al	;@6394
	mov al, byte ptr cs:L6222[di]	;@6397
	mov byte ptr D_047C, al	;@639C
	call L67B3	;@639F
	mov bh, 0	;@63A2
	mov bl, byte ptr D_0482	;@63A4
	mov di, bx	;@63A8
	mov al, byte ptr cs:L620D[di]	;@63AA
	mov byte ptr D_047B, al	;@63AF
	mov al, byte ptr cs:L6229[di]	;@63B2
	mov byte ptr D_047C, al	;@63B7
	mov al, byte ptr cs:L622A[di]	;@63BA
	mov byte ptr D_047A, al	;@63BF
	call L67B3	;@63C2
	mov bh, 0	;@63C5
	mov bl, byte ptr D_0482	;@63C7
	mov di, bx	;@63CB
	ret	;@63CD
;------------------------------------------------------------------------------
; L63CE: right wall at depth d (mirror of L6377).
; In: D_0482 = d. Out: DI = d.
;------------------------------------------------------------------------------
L63CE:	mov bh, 0	;@63CE
	mov bl, byte ptr D_0482	;@63D0
	mov di, bx	;@63D4
	mov al, byte ptr cs:L6217[di]	;@63D6
	mov byte ptr D_0479, al	;@63DB
	mov al, byte ptr cs:L6218[di]	;@63DE
	mov byte ptr D_047B, al	;@63E3
	mov al, byte ptr cs:L6221[di]	;@63E6
	mov byte ptr D_047A, al	;@63EB
	mov al, byte ptr cs:L6222[di]	;@63EE
	mov byte ptr D_047C, al	;@63F3
	call L67B3	;@63F6
	mov bh, 0	;@63F9
	mov bl, byte ptr D_0482	;@63FB
	mov di, bx	;@63FF
	mov al, byte ptr cs:L6217[di]	;@6401
	mov byte ptr D_047B, al	;@6406
	mov al, byte ptr cs:L6229[di]	;@6409
	mov byte ptr D_047C, al	;@640E
	mov al, byte ptr cs:L622A[di]	;@6411
	mov byte ptr D_047A, al	;@6416
	call L67B3	;@6419
	mov bh, 0	;@641C
	mov bl, byte ptr D_0482	;@641E
	mov di, bx	;@6422
	ret	;@6424
;------------------------------------------------------------------------------
; L6425: the rectangle of depth d: the face of a wall ahead at depth d; for d = 0, the frame
; of the view. Corners (XL, YT), (XR, YT), (XR, YB), (XL, YB).
; In: D_0482 = d. Out: DI = d.
;------------------------------------------------------------------------------
L6425:	mov bh, 0	;@6425
	mov bl, byte ptr D_0482	;@6427
	mov di, bx	;@642B
	mov al, byte ptr cs:L620D[di]	;@642D
	mov byte ptr D_0479, al	;@6432
	mov al, byte ptr cs:L6221[di]	;@6435
	mov byte ptr D_047A, al	;@643A
	mov byte ptr D_047C, al	;@643D
	mov al, byte ptr cs:L6217[di]	;@6440
	mov byte ptr D_047B, al	;@6445
	call L67B3	;@6448
	mov bh, 0	;@644B
	mov bl, byte ptr D_0482	;@644D
	mov di, bx	;@6451
	mov al, byte ptr cs:L6229[di]	;@6453
	mov byte ptr D_047C, al	;@6458
	call L67B3	;@645B
	mov bh, 0	;@645E
	mov bl, byte ptr D_0482	;@6460
	mov di, bx	;@6464
	mov al, byte ptr cs:L620D[di]	;@6466
	mov byte ptr D_047B, al	;@646B
	call L67B3	;@646E
	mov bh, 0	;@6471
	mov bl, byte ptr D_0482	;@6473
	mov di, bx	;@6477
	mov al, byte ptr cs:L6221[di]	;@6479
	mov byte ptr D_047C, al	;@647E
	call L67B3	;@6481
	mov bh, 0	;@6484
	mov bl, byte ptr D_0482	;@6486
	mov di, bx	;@648A
	ret	;@648C
;------------------------------------------------------------------------------
; L648D: a door in the wall ahead at depth d: two jambs at XL/XR of depth d+1 from the floor
; line YB[d] up to YT[d+1], and the lintel between them.
; In: D_0482 = d. Out: DI = d.
;------------------------------------------------------------------------------
L648D:	mov bh, 0	;@648D
	mov bl, byte ptr D_0482	;@648F
	mov di, bx	;@6493
	mov al, byte ptr cs:L620E[di]	;@6495
	mov byte ptr D_0479, al	;@649A
	mov byte ptr D_047B, al	;@649D
	mov al, byte ptr cs:L6229[di]	;@64A0
	mov byte ptr D_047A, al	;@64A5
	mov al, byte ptr cs:L6222[di]	;@64A8
	mov byte ptr D_047C, al	;@64AD
	call L67B3	;@64B0
	mov bh, 0	;@64B3
	mov bl, byte ptr D_0482	;@64B5
	mov di, bx	;@64B9
	mov al, byte ptr cs:L6218[di]	;@64BB
	mov byte ptr D_047B, al	;@64C0
	call L67B3	;@64C3
	mov bh, 0	;@64C6
	mov bl, byte ptr D_0482	;@64C8
	mov di, bx	;@64CC
	mov al, byte ptr cs:L6229[di]	;@64CE
	mov byte ptr D_047C, al	;@64D3
	call L67B3	;@64D6
	mov bh, 0	;@64D9
	mov bl, byte ptr D_0482	;@64DB
	mov di, bx	;@64DF
	ret	;@64E1
;------------------------------------------------------------------------------
; L64E2: a door in the left wall at depth d: near jamb (+24h) up to YT[d+1], the slanted
; top to the far jamb (+2Ch, top +54h), the far jamb down to +4Ch. Open at the bottom.
; In: D_0482 = d. Out: DI = d.
;------------------------------------------------------------------------------
L64E2:	mov bh, 0	;@64E2
	mov bl, byte ptr D_0482	;@64E4
	mov di, bx	;@64E8
	mov al, byte ptr cs:L6231[di]	;@64EA
	mov byte ptr D_0479, al	;@64EF
	mov byte ptr D_047B, al	;@64F2
	mov al, byte ptr cs:L6251[di]	;@64F5
	mov byte ptr D_047A, al	;@64FA
	mov al, byte ptr cs:L6222[di]	;@64FD
	mov byte ptr D_047C, al	;@6502
	call L67B3	;@6505
	mov bh, 0	;@6508
	mov bl, byte ptr D_0482	;@650A
	mov di, bx	;@650E
	mov al, byte ptr cs:L6239[di]	;@6510
	mov byte ptr D_047B, al	;@6515
	mov al, byte ptr cs:L6261[di]	;@6518
	mov byte ptr D_047C, al	;@651D
	call L67B3	;@6520
	mov bh, 0	;@6523
	mov bl, byte ptr D_0482	;@6525
	mov di, bx	;@6529
	mov al, byte ptr cs:L6259[di]	;@652B
	mov byte ptr D_047C, al	;@6530
	call L67B3	;@6533
	mov bh, 0	;@6536
	mov bl, byte ptr D_0482	;@6538
	mov di, bx	;@653C
	ret	;@653E
;------------------------------------------------------------------------------
; L653F: a door in the right wall at depth d (mirror of L64E2).
; In: D_0482 = d. Out: DI clobbered (L4B76); the caller reloads it.
;------------------------------------------------------------------------------
L653F:	mov bh, 0	;@653F
	mov bl, byte ptr D_0482	;@6541
	mov di, bx	;@6545
	mov al, byte ptr cs:L6241[di]	;@6547
	mov byte ptr D_0479, al	;@654C
	mov byte ptr D_047B, al	;@654F
	mov al, byte ptr cs:L6251[di]	;@6552
	mov byte ptr D_047A, al	;@6557
	mov al, byte ptr cs:L6222[di]	;@655A
	mov byte ptr D_047C, al	;@655F
	call L67B3	;@6562
	mov bh, 0	;@6565
	mov bl, byte ptr D_0482	;@6567
	mov di, bx	;@656B
	mov al, byte ptr cs:L6249[di]	;@656D
	mov byte ptr D_047B, al	;@6572
	mov al, byte ptr cs:L6261[di]	;@6575
	mov byte ptr D_047C, al	;@657A
	call L67B3	;@657D
	mov bh, 0	;@6580
	mov bl, byte ptr D_0482	;@6582
	mov di, bx	;@6586
	mov al, byte ptr cs:L6259[di]	;@6588
	mov byte ptr D_047C, al	;@658D
	call L67B3	;@6590
	ret	;@6593
;------------------------------------------------------------------------------
; L6594: a ladder down in the cell at depth d: the hole in the floor (a trapezoid between
; rows +6Ch and +74h) and the pole (L6684).
; In: D_0482 = d. Out: DI = d.
;------------------------------------------------------------------------------
L6594:	mov bh, 0	;@6594
	mov bl, byte ptr D_0482	;@6596
	mov di, bx	;@659A
	mov al, byte ptr cs:L6232[di]	;@659C
	mov byte ptr D_0479, al	;@65A1
	mov al, byte ptr cs:L623A[di]	;@65A4
	mov byte ptr D_047B, al	;@65A9
	mov al, byte ptr cs:L6279[di]	;@65AC
	mov byte ptr D_047A, al	;@65B1
	mov al, byte ptr cs:L6281[di]	;@65B4
	mov byte ptr D_047C, al	;@65B9
	call L67B3	;@65BC
	mov bh, 0	;@65BF
	mov bl, byte ptr D_0482	;@65C1
	mov di, bx	;@65C5
	mov al, byte ptr cs:L624A[di]	;@65C7
	mov byte ptr D_047B, al	;@65CC
	call L67B3	;@65CF
	mov bh, 0	;@65D2
	mov bl, byte ptr D_0482	;@65D4
	mov di, bx	;@65D8
	mov al, byte ptr cs:L6242[di]	;@65DA
	mov byte ptr D_047B, al	;@65DF
	mov al, byte ptr cs:L6279[di]	;@65E2
	mov byte ptr D_047C, al	;@65E7
	call L67B3	;@65EA
	mov bh, 0	;@65ED
	mov bl, byte ptr D_0482	;@65EF
	mov di, bx	;@65F3
	mov al, byte ptr cs:L6232[di]	;@65F5
	mov byte ptr D_047B, al	;@65FA
	call L67B3	;@65FD
	call L6684	;@6600
	mov bh, 0	;@6603
	mov bl, byte ptr D_0482	;@6605
	mov di, bx	;@6609
	ret	;@660B
;------------------------------------------------------------------------------
; L660C: a ladder up in the cell at depth d: the hole in the ceiling (rows +5Ch and +64h)
; and the pole (L6684).
; In: D_0482 = d. Out: DI = d.
;------------------------------------------------------------------------------
L660C:	mov bh, 0	;@660C
	mov bl, byte ptr D_0482	;@660E
	mov di, bx	;@6612
	mov al, byte ptr cs:L6232[di]	;@6614
	mov byte ptr D_0479, al	;@6619
	mov al, byte ptr cs:L623A[di]	;@661C
	mov byte ptr D_047B, al	;@6621
	mov al, byte ptr cs:L6269[di]	;@6624
	mov byte ptr D_047A, al	;@6629
	mov al, byte ptr cs:L6271[di]	;@662C
	mov byte ptr D_047C, al	;@6631
	call L67B3	;@6634
	mov bh, 0	;@6637
	mov bl, byte ptr D_0482	;@6639
	mov di, bx	;@663D
	mov al, byte ptr cs:L624A[di]	;@663F
	mov byte ptr D_047B, al	;@6644
	call L67B3	;@6647
	mov bh, 0	;@664A
	mov bl, byte ptr D_0482	;@664C
	mov di, bx	;@6650
	mov al, byte ptr cs:L6242[di]	;@6652
	mov byte ptr D_047B, al	;@6657
	mov al, byte ptr cs:L6269[di]	;@665A
	mov byte ptr D_047C, al	;@665F
	call L67B3	;@6662
	mov bh, 0	;@6665
	mov bl, byte ptr D_0482	;@6667
	mov di, bx	;@666B
	mov al, byte ptr cs:L6232[di]	;@666D
	mov byte ptr D_047B, al	;@6672
	call L67B3	;@6675
	call L6684	;@6678
	mov bh, 0	;@667B
	mov bl, byte ptr D_0482	;@667D
	mov di, bx	;@6681
	ret	;@6683
;------------------------------------------------------------------------------
; L6684: the ladder pole at depth d: two vertical lines at x = 7Fh and 80h from y = +5Ch
; (ceiling) to +6Ch (floor).
; In: D_0482 = d. Out: DI = d.
;------------------------------------------------------------------------------
L6684:	mov bh, 0	;@6684
	mov bl, byte ptr D_0482	;@6686
	mov di, bx	;@668A
	mov al, 7Fh	;@668C
	mov byte ptr D_0479, al	;@668E
	mov byte ptr D_047B, al	;@6691
	mov al, byte ptr cs:L6269[di]	;@6694
	mov byte ptr D_047A, al	;@6699
	mov al, byte ptr cs:L6279[di]	;@669C
	mov byte ptr D_047C, al	;@66A1
	call L67B3	;@66A4
	mov bh, 0	;@66A7
	mov bl, byte ptr D_0482	;@66A9
	mov di, bx	;@66AD
	mov al, 80h	;@66AF
	mov byte ptr D_0479, al	;@66B1
	mov byte ptr D_047B, al	;@66B4
	mov al, byte ptr cs:L6269[di]	;@66B7
	mov byte ptr D_047A, al	;@66BC
	mov al, byte ptr cs:L6279[di]	;@66BF
	mov byte ptr D_047C, al	;@66C4
	call L67B3	;@66C7
	ret	;@66CA
;------------------------------------------------------------------------------
; L66CB: a chest in the cell at depth d, a box in oblique view: the front face from
; (XL[d+2], +7Ch) to (XR[d+3], +44h), the top face going back to the edge at y = +4Ch
; between XL[d+3] and XR[d+2]. Unlike the others it does not load DI itself: it relies on
; DI = d from the caller (L6144).
; In: DI = D_0482 = d. Out: DI = d.
;------------------------------------------------------------------------------
L66CB:	nop	;@66CB
	mov al, byte ptr cs:L620F[di]	;@66CC
	mov byte ptr D_0479, al	;@66D1
	mov al, byte ptr cs:L6289[di]	;@66D4
	mov byte ptr D_047A, al	;@66D9
	mov byte ptr D_047C, al	;@66DC
	mov al, byte ptr cs:L621A[di]	;@66DF
	mov byte ptr D_047B, al	;@66E4
	call L67B3	;@66E7
	mov bh, 0	;@66EA
	mov bl, byte ptr D_0482	;@66EC
	mov di, bx	;@66F0
	mov al, byte ptr cs:L6251[di]	;@66F2
	mov byte ptr D_047C, al	;@66F7
	call L67B3	;@66FA
	mov bh, 0	;@66FD
	mov bl, byte ptr D_0482	;@66FF
	mov di, bx	;@6703
	mov al, byte ptr cs:L620F[di]	;@6705
	mov byte ptr D_047B, al	;@670A
	call L67B3	;@670D
	mov bh, 0	;@6710
	mov bl, byte ptr D_0482	;@6712
	mov di, bx	;@6716
	mov al, byte ptr cs:L6289[di]	;@6718
	mov byte ptr D_047C, al	;@671D
	call L67B3	;@6720
	mov bh, 0	;@6723
	mov bl, byte ptr D_0482	;@6725
	mov di, bx	;@6729
	mov al, byte ptr cs:L6210[di]	;@672B
	mov byte ptr D_047B, al	;@6730
	mov al, byte ptr cs:L6259[di]	;@6733
	mov byte ptr D_047C, al	;@6738
	call L67B3	;@673B
	mov bh, 0	;@673E
	mov bl, byte ptr D_0482	;@6740
	mov di, bx	;@6744
	mov al, byte ptr cs:L6219[di]	;@6746
	mov byte ptr D_047B, al	;@674B
	call L67B3	;@674E
	mov bh, 0	;@6751
	mov bl, byte ptr D_0482	;@6753
	mov di, bx	;@6757
	mov al, byte ptr cs:L6289[di]	;@6759
	mov byte ptr D_047C, al	;@675E
	call L67B3	;@6761
	mov bh, 0	;@6764
	mov bl, byte ptr D_0482	;@6766
	mov di, bx	;@676A
	mov al, byte ptr cs:L621A[di]	;@676C
	mov byte ptr D_047B, al	;@6771
	mov al, byte ptr cs:L6251[di]	;@6774
	mov byte ptr D_047C, al	;@6779
	call L67B3	;@677C
	mov bh, 0	;@677F
	mov bl, byte ptr D_0482	;@6781
	mov di, bx	;@6785
	mov al, byte ptr cs:L621A[di]	;@6787
	mov byte ptr D_0479, al	;@678C
	mov al, byte ptr cs:L6289[di]	;@678F
	mov byte ptr D_047A, al	;@6794
	mov al, byte ptr cs:L6219[di]	;@6797
	mov byte ptr D_047B, al	;@679C
	mov al, byte ptr cs:L6259[di]	;@679F
	mov byte ptr D_047C, al	;@67A4
	call L67B3	;@67A7
	mov bh, 0	;@67AA
	mov bl, byte ptr D_0482	;@67AC
	mov di, bx	;@67B0
	ret	;@67B2
;------------------------------------------------------------------------------
; L67B3: draw a line from (D_0479, D_047A) to (D_047B, D_047C) (Bresenham, 8-bit). Plots
; with L4B76 (OR) after each step, so the start pixel itself is not plotted (the previous
; line of a polyline ends there) and nothing is drawn when both ends are equal. Ends with
; D_0479/D_047A = the end point, so the next line can continue from it.
; Work: D_0483/D_0484 = |dx|/|dy|, D_047D/D_047E = x/y step (+1 or FFh), D_0480 = count,
; D_0481 = error term.
; In: D_0479-D_047C. Out: D_0479/D_047A = D_047B/D_047C. Uses: AX, BX, SI, DI (L4B76).
;------------------------------------------------------------------------------
L67B3:	nop	;@67B3
	mov al, byte ptr D_047B	;@67B4
	cmp al, byte ptr D_0479	;@67B7
	jne L67C7	; start = end: nothing to draw	;@67BB
	mov al, byte ptr D_047C	;@67BD
	cmp al, byte ptr D_047A	;@67C0
	jne L67C7	;@67C4
	ret	;@67C6
L67C7:	stc	;@67C7
	mov al, byte ptr D_047B	;@67C8
	cmc	;@67CB
	sbb al, byte ptr D_0479	;@67CC
	cmc	;@67D0
	mov byte ptr D_0483, al	; x1-x0, CF = no borrow (6502 SBC)	;@67D1
	jb L67E7	;@67D4
	xor al, 0FFh	;@67D6
	mov byte ptr D_0483, al	;@67D8
	inc byte ptr D_0483	; negate: |dx|	;@67DB
	mov al, 0FFh	; x step -1	;@67DF
	mov byte ptr D_047D, al	;@67E1
	jmp L67EC	;@67E4
L67E7:	mov al, 1	; x step +1	;@67E7
	mov byte ptr D_047D, al	;@67E9
L67EC:	stc	;@67EC
	mov al, byte ptr D_047C	;@67ED
	cmc	;@67F0
	sbb al, byte ptr D_047A	;@67F1
	cmc	;@67F5
	mov byte ptr D_0484, al	; y1-y0	;@67F6
	jb L680C	;@67F9
	xor al, 0FFh	;@67FB
	mov byte ptr D_0484, al	;@67FD
	inc byte ptr D_0484	; negate: |dy|	;@6800
	mov al, 0FFh	; y step -1	;@6804
	mov byte ptr D_047E, al	;@6806
	jmp L6811	;@6809
L680C:	mov al, 1	; y step +1	;@680C
	mov byte ptr D_047E, al	;@680E
L6811:	mov al, byte ptr D_0483	;@6811
	cmp al, byte ptr D_0484	;@6814
	jae L681D	;@6818
	jmp L6860	;@681A
; |dx| >= |dy|: step x every time, y when the error term overflows |dx|.
L681D:	mov al, byte ptr D_0483	;@681D
	mov byte ptr D_0480, al	;@6820
	clc	;@6823
	rcr al, 1	; error term = count/2	;@6824
	mov byte ptr D_0481, al	;@6826
L6829:	clc	;@6829
	mov al, byte ptr D_0481	;@682A
	adc al, byte ptr D_0484	;@682D
	mov byte ptr D_0481, al	;@6831
	stc	;@6834
	cmc	;@6835
	sbb al, byte ptr D_0483	; error - |dx|: no borrow = overflow	;@6836
	cmc	;@683A
	jae L684B	;@683B
	mov byte ptr D_0481, al	;@683D
	clc	;@6840
	mov al, byte ptr D_047A	;@6841
	adc al, byte ptr D_047E	;@6844
	mov byte ptr D_047A, al	;@6848
L684B:	clc	;@684B
	mov al, byte ptr D_0479	;@684C
	adc al, byte ptr D_047D	;@684F
	mov byte ptr D_0479, al	;@6853
	call L4B76	; plot	;@6856
	dec byte ptr D_0480	;@6859
	jne L6829	;@685D
	ret	;@685F
; |dy| > |dx|: step y every time, x when the error term overflows |dy|.
L6860:	mov al, byte ptr D_0484	;@6860
	mov byte ptr D_0480, al	;@6863
	clc	;@6866
	rcr al, 1	;@6867
	mov byte ptr D_0481, al	;@6869
L686C:	clc	;@686C
	mov al, byte ptr D_0481	;@686D
	adc al, byte ptr D_0483	;@6870
	mov byte ptr D_0481, al	;@6874
	stc	;@6877
	cmc	;@6878
	sbb al, byte ptr D_0484	; error - |dy|: no borrow = overflow	;@6879
	cmc	;@687D
	jae L688E	;@687E
	mov byte ptr D_0481, al	;@6880
	clc	;@6883
	mov al, byte ptr D_0479	;@6884
	adc al, byte ptr D_047D	;@6887
	mov byte ptr D_0479, al	;@688B
L688E:	clc	;@688E
	mov al, byte ptr D_047A	;@688F
	adc al, byte ptr D_047E	;@6892
	mov byte ptr D_047A, al	;@6896
	call L4B76	; plot	;@6899
	dec byte ptr D_0480	;@689C
	jne L686C	;@68A0
	ret	;@68A2
;------------------------------------------------------------------------------
; L68A3: plot one 4x4-pixel block of a monster shape at (D_0004*4, D_0005*4) with the
; colour pattern D_047F (0-7, byte from the CS table L48D4), through L4BE0 (overwrites).
; In: D_0004, D_0005, D_047F. Uses: AX, BX, BP.
;------------------------------------------------------------------------------
L68A3:	nop	;@68A3
	mov ah, 0	;@68A4
	mov al, byte ptr D_047F	; colour pattern	;@68A6
	mov bp, ax	;@68A9
	mov al, byte ptr D_0004	; X in 4-pixel units	;@68AB
	shl ax, 1	;@68AE
	shl ax, 1	;@68B0
	mov bh, 0	;@68B2
	mov bl, byte ptr D_0005	; Y in 4-pixel units	;@68B4
	shl bx, 1	;@68B8
	shl bx, 1	;@68BA
	call L4BE0	;@68BC
	ret	;@68BF
;------------------------------------------------------------------------------
; L68C0: read a dungeon cell. Address = D_0472 (map buffer) + D_0025*100h + D_0024*16 +
; D_0023, kept in the word D_0487 (D_0488 = high byte). The low byte ignores the low byte of
; D_0472 (it is 00h) and only works for X, Y < 16 (callers mask with 3Fh, though).
; In: D_0023 = X, D_0024 = Y, D_0025 = level. Out: AL = cell, D_0487.
; Uses: AX, BX, SI (= 0).
;------------------------------------------------------------------------------
L68C0:	mov ah, byte ptr D_0025	; level = page of the map buffer	;@68C0
	mov al, 0	;@68C4
	add ax, word ptr D_0472	;@68C6
	mov byte ptr D_0488, ah	;@68CA
	mov al, byte ptr D_0024	;@68CE
	add al, al	;@68D1
	add al, al	;@68D3
	add al, al	;@68D5
	add al, al	;@68D7
	adc al, byte ptr D_0023	; Y*16+X (CF from the shift is 0 for Y < 16)	;@68D9
	mov byte ptr D_0487, al	;@68DD
	mov bh, 0	;@68E0
	mov bl, 0	;@68E2
	mov si, bx	;@68E4
	mov bx, word ptr D_0487	; cell pointer (6502 (zp),y idiom with SI = 0)	;@68E6
	mov al, byte ptr [bx+si]	;@68EA
	ret	;@68EC
;------------------------------------------------------------------------------
; L68ED: draw the nearest monster in the line of sight. For d = 1 up to the last depth
; drawn, the first d with D_04AF[d] <> 0 is drawn and the routine returns. The shape is
; in the monster buffer (D_0474): at d = 1 the page D_04AF[d] (the monster's own shape);
; farther away the type is dropped and a generic smaller shape at offset L697E[d] of
; page 0 is used. A shape is a list of byte pairs (X, pattern*32 + Y) ending with X = 0;
; each pair is one 4x4 block (L68A3).
; In: D_0482 (from L6144), D_04AF. Out: D_0482 + 1. Uses: AX, BX, SI, DI, BP, D_0004/D_0005.
;------------------------------------------------------------------------------
L68ED:	nop	;@68ED
	inc byte ptr D_0482	; last depth + 1 = limit	;@68EE
	mov bh, 0	;@68F2
	mov bl, 0	;@68F4
	mov di, bx	;@68F6
; Next depth.
L68F8:	inc di	;@68F8
	mov bx, di	;@68F9
	cmp bl, byte ptr D_0482	;@68FB
	jb L6902	;@68FF
	ret	;@6901
L6902:	mov ah, byte ptr D_04AF[di]	;@6902
	or ah, ah	; monster at depth d?	;@6906
	je L68F8	;@6908
	cmp di, 1	; next to the player: its own shape	;@690A
	je L692C	;@690D
	mov ax, word ptr D_0474	; farther: AH = page of the buffer, the type is lost	;@690F
	mov byte ptr D_048A, ah	;@6912
	mov al, byte ptr cs:L697E[di]	; generic shape for this depth	;@6916
	mov byte ptr D_0489, al	;@691B
	mov al, byte ptr D_048A	;@691E
	mov bh, 0	;@6921
	mov bl, byte ptr D_0489	;@6923
	mov di, bx	;@6927
	jmp L693A	;@6929
L692C:	clc	;@692C
	add ax, word ptr D_0474	; AH = type: page D_04AF[d] (AL junk, low byte of D_0474 is 0)	;@692D
	mov byte ptr D_048A, ah	;@6931
	mov byte ptr D_0489, 0	;@6935
; Shape loop: D_0489 (word) points to the next pair.
L693A:	mov bh, 0	;@693A
	mov bl, 0	;@693C
	mov si, bx	;@693E
	mov bx, word ptr D_0489	;@6940
	mov al, byte ptr [bx+si]	;@6944
	or al, al	; X = 0: end of the shape, done	;@6946
	jne L694B	;@6948
	ret	;@694A
L694B:	mov byte ptr D_0004, al	;@694B
	inc word ptr D_0489	;@694E
	mov bx, word ptr D_0489	;@6952
	mov al, byte ptr [bx+si]	;@6956
	and al, 1Fh	; Y = low 5 bits	;@6958
	mov byte ptr D_0005, al	;@695A
	mov bx, word ptr D_0489	;@695D
	mov al, byte ptr [bx+si]	;@6961
	clc	;@6963
	rcr al, 1	;@6964
	clc	;@6966
	rcr al, 1	;@6967
	clc	;@6969
	rcr al, 1	;@696A
	clc	;@696C
	rcr al, 1	;@696D
	clc	;@696F
	rcr al, 1	; pattern = high 3 bits	;@6970
	mov byte ptr D_047F, al	;@6972
	inc word ptr D_0489	;@6975
	call L68A3	;@6979
	jmp L693A	;@697C
;------------------------------------------------------------------------------
; L697E: offset of the generic monster shape in page 0 of the monster buffer, by depth
; (0 for depths 0/1, unused): 80h, C0h, E0h ... smaller shapes farther away. Padding
; follows.
;------------------------------------------------------------------------------
L697E label byte
	db 0h,0h,80h,0C0h,0E0h,0F0h,0F8h,0FCh,0h,0h,0h,0h,0h,0h,0h,0h	;@697E
	db 0h,0h	;@698E
;------------------------------------------------------------------------------
; L6990-L6998: CS variables of space flight (they only sit in this module):
; L6990 (word) = pitch of the hyperwarp sound (divisor for L5CD2), L6992 (word) = its step
; per star move (FFFFh or 1), L6994 (word) = star moves until the next bleep toggle (L7242),
; L6996/L6997 = state of the star-field random generator (L6D68, reset to 3Bh/67h by
; L6D5B), L6998 = speaker state (FFh = off, 0 = on).
;------------------------------------------------------------------------------
L6990 label byte
	db 0h,0h	;@6990
L6992 label byte
	db 0h,0h	;@6992
L6994 label byte
	db 0h,0h	;@6994
L6996 label byte
	db 0h	;@6996
L6997 label byte
	db 0h	;@6997
L6998 label byte
	db 0h	;@6998
CODE ENDS
END
