; VIEW3D.ASM: the 3D dungeon and tower view, line drawing.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 6000-6999.
;
; The first-person wireframe view of dungeons and towers. UpdateDungeonView (called by EVENTS at 12CD
; after every turn underground) looks up the cells under, ahead of and behind the player
; (TileHere/TileNorth/TileSouth) and, while a light burns (LightTurns = light turns left), draws the view:
;  - GetViewCells collects the cells of the 8 rows ahead (depth 0 = the player's cell): left of,
;    on and right of the line of sight, high nibble in ViewLeftCells[d], ViewAheadCells[d], ViewRightCells[d], and
;    the low 3 bits of the centre cell (a monster) in ViewMonsters[d];
;  - DrawViewWalls clears the screen and draws depth by depth: front wall (DrawDepthRect) with a door
;    (DrawFrontDoor), left/right walls (DrawLeftWall/DrawRightWall) with doors (DrawLeftDoor/DrawRightDoor) or side
;    openings
;    (DrawLeftOpening/DrawRightOpening), ladders down/up (DrawLadderDown/DrawLadderUp + pole DrawLadderPole) and
;    chests (DrawChest), until a
;    wall blocks the view; ViewDepth = the current depth;
;  - DrawViewMonster draws the nearest monster from its shape in the monster buffer (MonsterBufPtr).
; Every line goes through DrawViewLine (Bresenham line from PlotX/PlotY to LineEndX/LineEndY, pixels
; by PlotPixel in SCREEN, offset by PlotOriginX/PlotOriginY). All screen coordinates come from one CS
; table, ViewCoordTbl (layout at the table). The view is 256x128 pixels.
; Map: dungeon level DungeonLevel is page DungeonLevel of the map buffer (MapBufPtr), 16x16 cells,
; offset Y*16+X (GetDungeonCell). Cell high nibble, as drawn here and tested by the commands:
;   80h wall, C0h door, E0h secret door (drawn as a wall, passable), 20h ladder down
;   (D)escend), 10h ladder up (K)limb), 40h chest (G)et); low bits: a monster (and 7 here).
; Position PlayerX/PlayerY, facing (dx, dy) in FacingDX/FacingDY (signed bytes).
; The CS variables at 6990-6998 belong to space flight (SPACE, ENDGAME), not to the view.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN PlayerX:BYTE, PlayerY:BYTE, FacingDX:BYTE, FacingDY:BYTE, WorkX:BYTE, WorkY:BYTE
	EXTRN TileHere:BYTE, TileNorth:BYTE, TileSouth:BYTE, LookX:BYTE, LookY:BYTE, DungeonLevel:BYTE
	EXTRN LightTurns:BYTE, MapBufPtr:BYTE, MonsterBufPtr:BYTE, PlotX:BYTE, PlotY:BYTE, LineEndX:BYTE
	EXTRN LineEndY:BYTE, LineStepX:BYTE, LineStepY:BYTE, BlockColor:BYTE, LineCount:BYTE, LineErr:BYTE
	EXTRN ViewDepth:BYTE, LineDX:BYTE, LineDY:BYTE, CellPtr:BYTE, CellPtrHi:BYTE, ShapePtr:BYTE
	EXTRN ShapePtrHi:BYTE, ViewLeftCells:BYTE, ViewAheadCells:BYTE, ViewRightCells:BYTE, ViewMonsters:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN ClearViewArea:NEAR, PlotPixel:NEAR, FillBlock4x4:NEAR
	PUBLIC UpdateDungeonView, SpaceToneDivisor, SpaceToneStep, BleepCountdown, StarRndSeed, StarRndSeed2
	PUBLIC SpeakerIsOff
ASSUME CS:CODE, DS:DATA
;------------------------------------------------------------------------------
; UpdateDungeonView: after a turn underground: if a light burns (LightTurns <> 0), collect the cells ahead
; (GetViewCells), draw the view (DrawViewWalls) and the nearest monster (DrawViewMonster). Always: TileHere = cell
; under the player, TileNorth = the cell ahead, TileSouth = the cell behind (full bytes).
; In: PlayerX/PlayerY position, FacingDX/FacingDY facing, DungeonLevel level, LightTurns.
; Out: TileHere-TileSouth, LookX/LookY. Uses: AX, BX, SI, DI, BP, the line variables.
;------------------------------------------------------------------------------
UpdateDungeonView:	nop	;@6000
	mov al, byte ptr FacingDX	; facing dx	;@6001
	mov byte ptr LineDX, al	;@6004
	mov al, byte ptr FacingDY	; facing dy	;@6007
	mov byte ptr LineDY, al	;@600A
	cmp byte ptr LightTurns, 0	; light burning?	;@600D
	je UpdView_NearCells	;@6012
	call GetViewCells	;@6014
	call DrawViewWalls	;@6017
	call DrawViewMonster	;@601A
; LineDX/LineDY again (the line drawing used them), then the three cells.
UpdView_NearCells:	mov al, byte ptr FacingDX	;@601D
	mov byte ptr LineDX, al	;@6020
	mov al, byte ptr FacingDY	;@6023
	mov byte ptr LineDY, al	;@6026
	mov al, byte ptr PlayerX	;@6029
	mov byte ptr LookX, al	;@602C
	mov al, byte ptr PlayerY	;@602F
	mov byte ptr LookY, al	;@6032
	call GetDungeonCell	; cell under the player	;@6035
	mov byte ptr TileHere, al	;@6038
	mov al, byte ptr PlayerX	;@603B
	clc	;@603E
	adc al, byte ptr LineDX	;@603F
	mov byte ptr LookX, al	;@6043
	mov al, byte ptr PlayerY	;@6046
	clc	;@6049
	adc al, byte ptr LineDY	;@604A
	mov byte ptr LookY, al	;@604E
	call GetDungeonCell	; cell ahead	;@6051
	mov byte ptr TileNorth, al	;@6054
	mov al, byte ptr PlayerX	;@6057
	stc	; stc/cmc/sbb = plain subtract	;@605A
	cmc	;@605B
	sbb al, byte ptr LineDX	;@605C
	cmc	;@6060
	mov byte ptr LookX, al	;@6061
	mov al, byte ptr PlayerY	;@6064
	stc	;@6067
	cmc	;@6068
	sbb al, byte ptr LineDY	;@6069
	cmc	;@606D
	mov byte ptr LookY, al	;@606E
	call GetDungeonCell	; cell behind	;@6071
	mov byte ptr TileSouth, al	;@6074
	ret	;@6077
;------------------------------------------------------------------------------
; GetViewCells: collect the cells ahead. Three walkers start at the player: left (PlotX/PlotY)
; = position + (dy, -dx), centre (LineEndX/LineEndY) = position, right (LineStepX/LineStepY) =
; position - (dy, -dx), with the facing (dx, dy) in LineDX/LineDY; for d = 0..7 each reads
; its cell (coordinates and 3Fh) and steps one cell forward. Stores the high nibbles in
; ViewLeftCells[d] (left), ViewAheadCells[d] (centre), ViewRightCells[d] (right) and the centre cell and 7 (the
; monster) in ViewMonsters[d].
; In: PlayerX/PlayerY, LineDX/LineDY, DungeonLevel. Out: the four arrays. Uses: AX, BX, SI, DI.
;------------------------------------------------------------------------------
GetViewCells:	clc	;@6078
	mov al, byte ptr PlayerX	;@6079
	mov byte ptr LineEndX, al	;@607C
	adc al, byte ptr LineDY	;@607F
	mov byte ptr PlotX, al	; left walker X = X + dy	;@6083
	stc	;@6086
	mov al, byte ptr PlayerY	;@6087
	mov byte ptr LineEndY, al	;@608A
	cmc	;@608D
	sbb al, byte ptr LineDX	;@608E
	cmc	;@6092
	mov byte ptr PlotY, al	; left walker Y = Y - dx	;@6093
	stc	;@6096
	mov al, byte ptr PlayerX	;@6097
	cmc	;@609A
	sbb al, byte ptr LineDY	;@609B
	cmc	;@609F
	mov byte ptr LineStepX, al	; right walker X = X - dy	;@60A0
	clc	;@60A3
	mov al, byte ptr PlayerY	;@60A4
	adc al, byte ptr LineDX	;@60A7
	mov byte ptr LineStepY, al	; right walker Y = Y + dx	;@60AB
	mov bh, 0	;@60AE
	mov bl, 0	;@60B0
	mov di, bx	;@60B2
; d = DI = 0..7
GetViewCells_Loop:	mov al, byte ptr PlotX	;@60B4
	and al, 3Fh	;@60B7
	mov byte ptr LookX, al	;@60B9
	clc	;@60BC
	adc al, byte ptr LineDX	;@60BD
	mov byte ptr PlotX, al	; step forward	;@60C1
	mov al, byte ptr PlotY	;@60C4
	and al, 3Fh	;@60C7
	mov byte ptr LookY, al	;@60C9
	clc	;@60CC
	adc al, byte ptr LineDY	;@60CD
	mov byte ptr PlotY, al	;@60D1
	call GetDungeonCell	;@60D4
	and al, 0F0h	; left cell, high nibble	;@60D7
	mov byte ptr ViewLeftCells[di], al	;@60D9
	mov al, byte ptr LineEndX	;@60DD
	and al, 3Fh	;@60E0
	mov byte ptr LookX, al	;@60E2
	clc	;@60E5
	adc al, byte ptr LineDX	;@60E6
	mov byte ptr LineEndX, al	;@60EA
	mov al, byte ptr LineEndY	;@60ED
	and al, 3Fh	;@60F0
	mov byte ptr LookY, al	;@60F2
	clc	;@60F5
	adc al, byte ptr LineDY	;@60F6
	mov byte ptr LineEndY, al	;@60FA
	call GetDungeonCell	;@60FD
	and al, 0F0h	; centre cell, high nibble	;@6100
	mov byte ptr ViewAheadCells[di], al	;@6102
	call GetDungeonCell	;@6106
	and al, 7	; centre cell, low bits = monster	;@6109
	mov byte ptr ViewMonsters[di], al	;@610B
	mov al, byte ptr LineStepX	;@610F
	and al, 3Fh	;@6112
	mov byte ptr LookX, al	;@6114
	clc	;@6117
	adc al, byte ptr LineDX	;@6118
	mov byte ptr LineStepX, al	;@611C
	mov al, byte ptr LineStepY	;@611F
	and al, 3Fh	;@6122
	mov byte ptr LookY, al	;@6124
	clc	;@6127
	adc al, byte ptr LineDY	;@6128
	mov byte ptr LineStepY, al	;@612C
	call GetDungeonCell	;@612F
	and al, 0F0h	; right cell, high nibble	;@6132
	mov byte ptr ViewRightCells[di], al	;@6134
	inc di	;@6138
	mov bx, di	;@6139
	cmp bl, 8	; 8 rows	;@613B
	jae L6143	;@613E
	jmp GetViewCells_Loop	;@6140
L6143:	ret	;@6143
;------------------------------------------------------------------------------
; DrawViewWalls: draw the walls. Clears the screen, draws the frame (depth 0 rectangle), then for
; d = ViewDepth = 0, 1, ...: if the cell ahead at depth d is a wall, draw its face (and a door
; in it) and stop; else draw a ladder or chest in it, the left and right walls (or the
; side openings) of depth d, and go on (at most to depth 6).
; In: the arrays from GetViewCells. Out: ViewDepth = the last depth drawn (DrawViewMonster uses it).
; Uses: AX, BX, DI and the line variables.
;------------------------------------------------------------------------------
DrawViewWalls:	call ClearViewArea	; clear the screen (both CGA banks)	;@6144
	mov al, 0	;@6147
	mov byte ptr ViewDepth, al	;@6149
	call DrawDepthRect	; frame of the view	;@614C
; Next depth: DI = d.
DrawWalls_Loop:	mov bh, 0	;@614F
	mov bl, byte ptr ViewDepth	;@6151
	mov di, bx	;@6155
	mov al, byte ptr ViewAheadCells[di]	;@6157
	or al, al	;@615B
	jns DrawWalls_OpenCell	; bit 7: wall ahead?	;@615D
	call DrawDepthRect	; its face	;@615F
	mov al, byte ptr ViewAheadCells[di]	;@6162
	and al, 40h	; 40h: door?	;@6166
	jne L616D	;@6168
	jmp DrawWalls_Done	;@616A
L616D:	mov al, byte ptr ViewAheadCells[di]	;@616D
	and al, 20h	; 20h too: secret door, looks like a wall	;@6171
	je L6178	;@6173
	jmp DrawWalls_Done	;@6175
L6178:	call DrawFrontDoor	; door in it	;@6178
	mov al, byte ptr ViewDepth	;@617B
	or al, al	; a door in the player's own cell: look on through it	;@617E
	je L6185	;@6180
	jmp DrawWalls_Done	;@6182
L6185:	inc byte ptr ViewDepth	;@6185
	mov al, byte ptr ViewDepth	;@6189
	cmp al, 8	; limit 8 on this path (7 below)	;@618C
	jae DrawWalls_Done	;@618E
	jmp DrawWalls_Loop	;@6190
; Open cell: ladder down, ladder up or chest in it.
DrawWalls_OpenCell:	mov al, byte ptr ViewAheadCells[di]	;@6192
	and al, 20h	; 20h: ladder down	;@6196
	je L619D	;@6198
	call DrawLadderDown	;@619A
L619D:	mov al, byte ptr ViewAheadCells[di]	;@619D
	and al, 10h	; 10h: ladder up	;@61A1
	je L61AB	;@61A3
	call DrawLadderUp	;@61A5
	jmp DrawWalls_LeftSide	;@61A8
L61AB:	mov al, byte ptr ViewAheadCells[di]	;@61AB
	and al, 40h	; 40h: chest	;@61AF
	je DrawWalls_LeftSide	;@61B1
	call DrawChest	;@61B3
; Left side: wall (and door in it) or opening.
DrawWalls_LeftSide:	mov al, byte ptr ViewLeftCells[di]	;@61B6
	or al, al	; left wall?	;@61BA
	jns L61D7	;@61BC
	call DrawLeftWall	; its edges	;@61BE
	mov al, byte ptr ViewLeftCells[di]	;@61C1
	and al, 40h	;@61C5
	je DrawWalls_RightSide	;@61C7
	mov al, byte ptr ViewLeftCells[di]	;@61C9
	and al, 20h	;@61CD
	jne DrawWalls_RightSide	;@61CF
	call DrawLeftDoor	; door (40h without 20h)	;@61D1
	jmp DrawWalls_RightSide	;@61D4
L61D7:	call DrawLeftOpening	; left side open	;@61D7
; Right side.
DrawWalls_RightSide:	mov al, byte ptr ViewRightCells[di]	;@61DA
	or al, al	; right wall?	;@61DE
	jns L61FB	;@61E0
	call DrawRightWall	;@61E2
	mov al, byte ptr ViewRightCells[di]	;@61E5
	and al, 40h	;@61E9
	je DrawWalls_Next	;@61EB
	mov al, byte ptr ViewRightCells[di]	;@61ED
	and al, 20h	;@61F1
	jne DrawWalls_Next	;@61F3
	call DrawRightDoor	;@61F5
	jmp DrawWalls_Next	;@61F8
L61FB:	call DrawRightOpening	; right side open	;@61FB
DrawWalls_Next:	inc byte ptr ViewDepth	;@61FE
	mov al, byte ptr ViewDepth	;@6202
	cmp al, 7	; at most depth 6	;@6205
	jae DrawWalls_Done	;@6207
	jmp DrawWalls_Loop	;@6209
DrawWalls_Done:	ret	;@620C
;------------------------------------------------------------------------------
; ViewCoordTbl: the screen coordinates of the 3D view, one byte row per kind of point, each
; indexed by the depth d (0 = the player's cell). Several rows are also read at d+1, d+2, d+3
; (written ROW[di+1] ...). X runs 0-FFh, Y 0-7Fh; the right half mirrors the left (x' = FFh-x),
; the bottom half the top (y' = 7Fh-y). XL and XR have 10 entries (d+3 for d up to 6), the
; others 8. The table runs from 620D to 6291 in the original.
;------------------------------------------------------------------------------
ViewCoordTbl label byte
; ViewXL (+00h): x of the left edge of the depth-d rectangle
ViewXL label byte
	db 0h,40h,60h,70h,78h,7Ch,7Eh,7Fh,7Fh,7Fh	;@620D
; ViewXR (+0Ah): x of the right edge (FFh-XL)
ViewXR label byte
	db 0FFh,0BFh,9Fh,8Fh,87h,83h,81h,80h,80h,80h	;@6217
; ViewYT (+14h): y of the top edge
ViewYT label byte
	db 0h,20h,30h,38h,3Ch,3Eh,3Fh,3Fh	;@6221
; ViewYB (+1Ch): y of the bottom edge (7Fh-YT)
ViewYB label byte
	db 7Fh,5Fh,4Fh,47h,43h,41h,40h,40h	;@6229
; ViewLNearX (+24h): x of the near jamb of a left-wall door; [d+1]: ladder hole, near left corner
ViewLNearX label byte
	db 10h,48h,64h,72h,79h,7Ch,7Fh,7Fh	;@6231
; ViewLFarX (+2Ch): x of the far jamb of a left-wall door; [d+1]: ladder hole, far left corner
ViewLFarX label byte
	db 30h,58h,6Ch,76h,7Bh,7Ch,7Fh,7Fh	;@6239
; ViewRNearX (+34h): the same for the right wall: near jamb; [d+1]: ladder hole, near right
ViewRNearX label byte
	db 0EFh,0B7h,9Bh,8Dh,86h,83h,80h,80h	;@6241
; ViewRFarX (+3Ch): far jamb of a right-wall door; [d+1]: ladder hole, far right corner
ViewRFarX label byte
	db 0CFh,0A7h,93h,89h,84h,83h,80h,80h	;@6249
; ViewFootNearY (+44h): y of the near jamb foot of a side door; the chest front bottom
ViewFootNearY label byte
	db 77h,5Bh,4Dh,46h,42h,40h,40h,40h	;@6251
; ViewFootFarY (+4Ch): y of the far jamb foot of a side door; the chest back edge
ViewFootFarY label byte
	db 67h,53h,49h,44h,42h,40h,40h,40h	;@6259
; ViewDoorTopY (+54h): y of the far jamb top of a side door (the near one is YT[d+1])
ViewDoorTopY label byte
	db 2Ah,35h,3Bh,3Dh,3Eh,3Fh,3Fh,3Fh	;@6261
; ViewCeilNearY (+5Ch): y of the near edge of a ladder hole in the ceiling; the pole top
ViewCeilNearY label byte
	db 8h,24h,32h,39h,3Ch,3Eh,3Fh,3Fh	;@6269
; ViewCeilFarY (+64h): y of the far edge of a ladder hole in the ceiling
ViewCeilFarY label byte
	db 18h,2Ch,36h,3Ah,3Dh,3Eh,3Fh,3Fh	;@6271
; ViewFloorNearY (+6Ch): y of the near edge of a ladder hole in the floor; the pole foot
ViewFloorNearY label byte
	db 77h,5Bh,4Dh,46h,43h,41h,40h,40h	;@6279
; ViewFloorFarY (+74h): y of the far edge of a ladder hole in the floor
ViewFloorFarY label byte
	db 67h,53h,49h,45h,42h,41h,40h,40h	;@6281
; ViewChestTopY (+7Ch): y of the chest front top
ViewChestTopY label byte
	db 6Fh,57h,4Bh,45h,42h,40h,40h,40h	;@6289
;------------------------------------------------------------------------------
; DrawLeftOpening: left side open at depth d: the near corner edge (x = XL[d]) and the face of the
; wall across the side passage (rectangle edge at depth d+1).
; In: ViewDepth = d. Out: DI = d. Uses: AX, BX, DI and the line variables (also DrawRightOpening-DrawChest).
;------------------------------------------------------------------------------
DrawLeftOpening:	mov bh, 0	;@6291
	mov bl, byte ptr ViewDepth	;@6293
	mov di, bx	;@6297
	mov al, byte ptr cs:ViewXL[di]	;@6299
	mov byte ptr PlotX, al	;@629E
	mov byte ptr LineEndX, al	;@62A1
	mov al, byte ptr cs:ViewYT[di]	;@62A4
	mov byte ptr PlotY, al	;@62A9
	mov al, byte ptr cs:ViewYB[di]	;@62AC
	mov byte ptr LineEndY, al	;@62B1
	call DrawViewLine	;@62B4
	mov bh, 0	;@62B7
	mov bl, byte ptr ViewDepth	;@62B9
	mov di, bx	;@62BD
	mov al, byte ptr cs:ViewYT[di+1]	;@62BF
	mov byte ptr PlotY, al	;@62C4
	mov byte ptr LineEndY, al	;@62C7
	mov al, byte ptr cs:ViewXL[di+1]	;@62CA
	mov byte ptr LineEndX, al	;@62CF
	call DrawViewLine	;@62D2
	mov bh, 0	;@62D5
	mov bl, byte ptr ViewDepth	;@62D7
	mov di, bx	;@62DB
	mov al, byte ptr cs:ViewYB[di+1]	;@62DD
	mov byte ptr LineEndY, al	;@62E2
	call DrawViewLine	;@62E5
	mov bh, 0	;@62E8
	mov bl, byte ptr ViewDepth	;@62EA
	mov di, bx	;@62EE
	mov al, byte ptr cs:ViewXL[di]	;@62F0
	mov byte ptr LineEndX, al	;@62F5
	call DrawViewLine	;@62F8
	mov bh, 0	;@62FB
	mov bl, byte ptr ViewDepth	;@62FD
	mov di, bx	;@6301
	ret	;@6303
;------------------------------------------------------------------------------
; DrawRightOpening: right side open at depth d (mirror of DrawLeftOpening).
; In: ViewDepth = d. Out: DI = d.
;------------------------------------------------------------------------------
DrawRightOpening:	mov bh, 0	;@6304
	mov bl, byte ptr ViewDepth	;@6306
	mov di, bx	;@630A
	mov al, byte ptr cs:ViewXR[di]	;@630C
	mov byte ptr PlotX, al	;@6311
	mov byte ptr LineEndX, al	;@6314
	mov al, byte ptr cs:ViewYT[di]	;@6317
	mov byte ptr PlotY, al	;@631C
	mov al, byte ptr cs:ViewYB[di]	;@631F
	mov byte ptr LineEndY, al	;@6324
	call DrawViewLine	;@6327
	mov bh, 0	;@632A
	mov bl, byte ptr ViewDepth	;@632C
	mov di, bx	;@6330
	mov al, byte ptr cs:ViewYT[di+1]	;@6332
	mov byte ptr PlotY, al	;@6337
	mov byte ptr LineEndY, al	;@633A
	mov al, byte ptr cs:ViewXR[di+1]	;@633D
	mov byte ptr LineEndX, al	;@6342
	call DrawViewLine	;@6345
	mov bh, 0	;@6348
	mov bl, byte ptr ViewDepth	;@634A
	mov di, bx	;@634E
	mov al, byte ptr cs:ViewYB[di+1]	;@6350
	mov byte ptr LineEndY, al	;@6355
	call DrawViewLine	;@6358
	mov bh, 0	;@635B
	mov bl, byte ptr ViewDepth	;@635D
	mov di, bx	;@6361
	mov al, byte ptr cs:ViewXR[di]	;@6363
	mov byte ptr LineEndX, al	;@6368
	call DrawViewLine	;@636B
	mov bh, 0	;@636E
	mov bl, byte ptr ViewDepth	;@6370
	mov di, bx	;@6374
	ret	;@6376
;------------------------------------------------------------------------------
; DrawLeftWall: left wall at depth d: its top and bottom edges, from depth d to depth d+1.
; In: ViewDepth = d. Out: DI = d.
;------------------------------------------------------------------------------
DrawLeftWall:	mov bh, 0	;@6377
	mov bl, byte ptr ViewDepth	;@6379
	mov di, bx	;@637D
	mov al, byte ptr cs:ViewXL[di]	;@637F
	mov byte ptr PlotX, al	;@6384
	mov al, byte ptr cs:ViewXL[di+1]	;@6387
	mov byte ptr LineEndX, al	;@638C
	mov al, byte ptr cs:ViewYT[di]	;@638F
	mov byte ptr PlotY, al	;@6394
	mov al, byte ptr cs:ViewYT[di+1]	;@6397
	mov byte ptr LineEndY, al	;@639C
	call DrawViewLine	;@639F
	mov bh, 0	;@63A2
	mov bl, byte ptr ViewDepth	;@63A4
	mov di, bx	;@63A8
	mov al, byte ptr cs:ViewXL[di]	;@63AA
	mov byte ptr LineEndX, al	;@63AF
	mov al, byte ptr cs:ViewYB[di]	;@63B2
	mov byte ptr LineEndY, al	;@63B7
	mov al, byte ptr cs:ViewYB[di+1]	;@63BA
	mov byte ptr PlotY, al	;@63BF
	call DrawViewLine	;@63C2
	mov bh, 0	;@63C5
	mov bl, byte ptr ViewDepth	;@63C7
	mov di, bx	;@63CB
	ret	;@63CD
;------------------------------------------------------------------------------
; DrawRightWall: right wall at depth d (mirror of DrawLeftWall).
; In: ViewDepth = d. Out: DI = d.
;------------------------------------------------------------------------------
DrawRightWall:	mov bh, 0	;@63CE
	mov bl, byte ptr ViewDepth	;@63D0
	mov di, bx	;@63D4
	mov al, byte ptr cs:ViewXR[di]	;@63D6
	mov byte ptr PlotX, al	;@63DB
	mov al, byte ptr cs:ViewXR[di+1]	;@63DE
	mov byte ptr LineEndX, al	;@63E3
	mov al, byte ptr cs:ViewYT[di]	;@63E6
	mov byte ptr PlotY, al	;@63EB
	mov al, byte ptr cs:ViewYT[di+1]	;@63EE
	mov byte ptr LineEndY, al	;@63F3
	call DrawViewLine	;@63F6
	mov bh, 0	;@63F9
	mov bl, byte ptr ViewDepth	;@63FB
	mov di, bx	;@63FF
	mov al, byte ptr cs:ViewXR[di]	;@6401
	mov byte ptr LineEndX, al	;@6406
	mov al, byte ptr cs:ViewYB[di]	;@6409
	mov byte ptr LineEndY, al	;@640E
	mov al, byte ptr cs:ViewYB[di+1]	;@6411
	mov byte ptr PlotY, al	;@6416
	call DrawViewLine	;@6419
	mov bh, 0	;@641C
	mov bl, byte ptr ViewDepth	;@641E
	mov di, bx	;@6422
	ret	;@6424
;------------------------------------------------------------------------------
; DrawDepthRect: the rectangle of depth d: the face of a wall ahead at depth d; for d = 0, the frame
; of the view. Corners (XL, YT), (XR, YT), (XR, YB), (XL, YB).
; In: ViewDepth = d. Out: DI = d.
;------------------------------------------------------------------------------
DrawDepthRect:	mov bh, 0	;@6425
	mov bl, byte ptr ViewDepth	;@6427
	mov di, bx	;@642B
	mov al, byte ptr cs:ViewXL[di]	;@642D
	mov byte ptr PlotX, al	;@6432
	mov al, byte ptr cs:ViewYT[di]	;@6435
	mov byte ptr PlotY, al	;@643A
	mov byte ptr LineEndY, al	;@643D
	mov al, byte ptr cs:ViewXR[di]	;@6440
	mov byte ptr LineEndX, al	;@6445
	call DrawViewLine	;@6448
	mov bh, 0	;@644B
	mov bl, byte ptr ViewDepth	;@644D
	mov di, bx	;@6451
	mov al, byte ptr cs:ViewYB[di]	;@6453
	mov byte ptr LineEndY, al	;@6458
	call DrawViewLine	;@645B
	mov bh, 0	;@645E
	mov bl, byte ptr ViewDepth	;@6460
	mov di, bx	;@6464
	mov al, byte ptr cs:ViewXL[di]	;@6466
	mov byte ptr LineEndX, al	;@646B
	call DrawViewLine	;@646E
	mov bh, 0	;@6471
	mov bl, byte ptr ViewDepth	;@6473
	mov di, bx	;@6477
	mov al, byte ptr cs:ViewYT[di]	;@6479
	mov byte ptr LineEndY, al	;@647E
	call DrawViewLine	;@6481
	mov bh, 0	;@6484
	mov bl, byte ptr ViewDepth	;@6486
	mov di, bx	;@648A
	ret	;@648C
;------------------------------------------------------------------------------
; DrawFrontDoor: a door in the wall ahead at depth d: two jambs at XL/XR of depth d+1 from the floor
; line YB[d] up to YT[d+1], and the lintel between them.
; In: ViewDepth = d. Out: DI = d.
;------------------------------------------------------------------------------
DrawFrontDoor:	mov bh, 0	;@648D
	mov bl, byte ptr ViewDepth	;@648F
	mov di, bx	;@6493
	mov al, byte ptr cs:ViewXL[di+1]	;@6495
	mov byte ptr PlotX, al	;@649A
	mov byte ptr LineEndX, al	;@649D
	mov al, byte ptr cs:ViewYB[di]	;@64A0
	mov byte ptr PlotY, al	;@64A5
	mov al, byte ptr cs:ViewYT[di+1]	;@64A8
	mov byte ptr LineEndY, al	;@64AD
	call DrawViewLine	;@64B0
	mov bh, 0	;@64B3
	mov bl, byte ptr ViewDepth	;@64B5
	mov di, bx	;@64B9
	mov al, byte ptr cs:ViewXR[di+1]	;@64BB
	mov byte ptr LineEndX, al	;@64C0
	call DrawViewLine	;@64C3
	mov bh, 0	;@64C6
	mov bl, byte ptr ViewDepth	;@64C8
	mov di, bx	;@64CC
	mov al, byte ptr cs:ViewYB[di]	;@64CE
	mov byte ptr LineEndY, al	;@64D3
	call DrawViewLine	;@64D6
	mov bh, 0	;@64D9
	mov bl, byte ptr ViewDepth	;@64DB
	mov di, bx	;@64DF
	ret	;@64E1
;------------------------------------------------------------------------------
; DrawLeftDoor: a door in the left wall at depth d: near jamb (x LNearX, from FootNearY) up to
; YT[d+1], the slanted top to the far jamb (x LFarX, top DoorTopY), the far jamb down to FootFarY. Open at the bottom.
; In: ViewDepth = d. Out: DI = d.
;------------------------------------------------------------------------------
DrawLeftDoor:	mov bh, 0	;@64E2
	mov bl, byte ptr ViewDepth	;@64E4
	mov di, bx	;@64E8
	mov al, byte ptr cs:ViewLNearX[di]	;@64EA
	mov byte ptr PlotX, al	;@64EF
	mov byte ptr LineEndX, al	;@64F2
	mov al, byte ptr cs:ViewFootNearY[di]	;@64F5
	mov byte ptr PlotY, al	;@64FA
	mov al, byte ptr cs:ViewYT[di+1]	;@64FD
	mov byte ptr LineEndY, al	;@6502
	call DrawViewLine	;@6505
	mov bh, 0	;@6508
	mov bl, byte ptr ViewDepth	;@650A
	mov di, bx	;@650E
	mov al, byte ptr cs:ViewLFarX[di]	;@6510
	mov byte ptr LineEndX, al	;@6515
	mov al, byte ptr cs:ViewDoorTopY[di]	;@6518
	mov byte ptr LineEndY, al	;@651D
	call DrawViewLine	;@6520
	mov bh, 0	;@6523
	mov bl, byte ptr ViewDepth	;@6525
	mov di, bx	;@6529
	mov al, byte ptr cs:ViewFootFarY[di]	;@652B
	mov byte ptr LineEndY, al	;@6530
	call DrawViewLine	;@6533
	mov bh, 0	;@6536
	mov bl, byte ptr ViewDepth	;@6538
	mov di, bx	;@653C
	ret	;@653E
;------------------------------------------------------------------------------
; DrawRightDoor: a door in the right wall at depth d (mirror of DrawLeftDoor).
; In: ViewDepth = d. Out: DI clobbered (PlotPixel); the caller reloads it.
;------------------------------------------------------------------------------
DrawRightDoor:	mov bh, 0	;@653F
	mov bl, byte ptr ViewDepth	;@6541
	mov di, bx	;@6545
	mov al, byte ptr cs:ViewRNearX[di]	;@6547
	mov byte ptr PlotX, al	;@654C
	mov byte ptr LineEndX, al	;@654F
	mov al, byte ptr cs:ViewFootNearY[di]	;@6552
	mov byte ptr PlotY, al	;@6557
	mov al, byte ptr cs:ViewYT[di+1]	;@655A
	mov byte ptr LineEndY, al	;@655F
	call DrawViewLine	;@6562
	mov bh, 0	;@6565
	mov bl, byte ptr ViewDepth	;@6567
	mov di, bx	;@656B
	mov al, byte ptr cs:ViewRFarX[di]	;@656D
	mov byte ptr LineEndX, al	;@6572
	mov al, byte ptr cs:ViewDoorTopY[di]	;@6575
	mov byte ptr LineEndY, al	;@657A
	call DrawViewLine	;@657D
	mov bh, 0	;@6580
	mov bl, byte ptr ViewDepth	;@6582
	mov di, bx	;@6586
	mov al, byte ptr cs:ViewFootFarY[di]	;@6588
	mov byte ptr LineEndY, al	;@658D
	call DrawViewLine	;@6590
	ret	;@6593
;------------------------------------------------------------------------------
; DrawLadderDown: a ladder down in the cell at depth d: the hole in the floor (a trapezoid between
; rows FloorNearY and FloorFarY, x from the four Near/FarX rows at d+1) and the pole (DrawLadderPole).
; In: ViewDepth = d. Out: DI = d.
;------------------------------------------------------------------------------
DrawLadderDown:	mov bh, 0	;@6594
	mov bl, byte ptr ViewDepth	;@6596
	mov di, bx	;@659A
	mov al, byte ptr cs:ViewLNearX[di+1]	;@659C
	mov byte ptr PlotX, al	;@65A1
	mov al, byte ptr cs:ViewLFarX[di+1]	;@65A4
	mov byte ptr LineEndX, al	;@65A9
	mov al, byte ptr cs:ViewFloorNearY[di]	;@65AC
	mov byte ptr PlotY, al	;@65B1
	mov al, byte ptr cs:ViewFloorFarY[di]	;@65B4
	mov byte ptr LineEndY, al	;@65B9
	call DrawViewLine	;@65BC
	mov bh, 0	;@65BF
	mov bl, byte ptr ViewDepth	;@65C1
	mov di, bx	;@65C5
	mov al, byte ptr cs:ViewRFarX[di+1]	;@65C7
	mov byte ptr LineEndX, al	;@65CC
	call DrawViewLine	;@65CF
	mov bh, 0	;@65D2
	mov bl, byte ptr ViewDepth	;@65D4
	mov di, bx	;@65D8
	mov al, byte ptr cs:ViewRNearX[di+1]	;@65DA
	mov byte ptr LineEndX, al	;@65DF
	mov al, byte ptr cs:ViewFloorNearY[di]	;@65E2
	mov byte ptr LineEndY, al	;@65E7
	call DrawViewLine	;@65EA
	mov bh, 0	;@65ED
	mov bl, byte ptr ViewDepth	;@65EF
	mov di, bx	;@65F3
	mov al, byte ptr cs:ViewLNearX[di+1]	;@65F5
	mov byte ptr LineEndX, al	;@65FA
	call DrawViewLine	;@65FD
	call DrawLadderPole	;@6600
	mov bh, 0	;@6603
	mov bl, byte ptr ViewDepth	;@6605
	mov di, bx	;@6609
	ret	;@660B
;------------------------------------------------------------------------------
; DrawLadderUp: a ladder up in the cell at depth d: the hole in the ceiling (rows CeilNearY and CeilFarY)
; and the pole (DrawLadderPole).
; In: ViewDepth = d. Out: DI = d.
;------------------------------------------------------------------------------
DrawLadderUp:	mov bh, 0	;@660C
	mov bl, byte ptr ViewDepth	;@660E
	mov di, bx	;@6612
	mov al, byte ptr cs:ViewLNearX[di+1]	;@6614
	mov byte ptr PlotX, al	;@6619
	mov al, byte ptr cs:ViewLFarX[di+1]	;@661C
	mov byte ptr LineEndX, al	;@6621
	mov al, byte ptr cs:ViewCeilNearY[di]	;@6624
	mov byte ptr PlotY, al	;@6629
	mov al, byte ptr cs:ViewCeilFarY[di]	;@662C
	mov byte ptr LineEndY, al	;@6631
	call DrawViewLine	;@6634
	mov bh, 0	;@6637
	mov bl, byte ptr ViewDepth	;@6639
	mov di, bx	;@663D
	mov al, byte ptr cs:ViewRFarX[di+1]	;@663F
	mov byte ptr LineEndX, al	;@6644
	call DrawViewLine	;@6647
	mov bh, 0	;@664A
	mov bl, byte ptr ViewDepth	;@664C
	mov di, bx	;@6650
	mov al, byte ptr cs:ViewRNearX[di+1]	;@6652
	mov byte ptr LineEndX, al	;@6657
	mov al, byte ptr cs:ViewCeilNearY[di]	;@665A
	mov byte ptr LineEndY, al	;@665F
	call DrawViewLine	;@6662
	mov bh, 0	;@6665
	mov bl, byte ptr ViewDepth	;@6667
	mov di, bx	;@666B
	mov al, byte ptr cs:ViewLNearX[di+1]	;@666D
	mov byte ptr LineEndX, al	;@6672
	call DrawViewLine	;@6675
	call DrawLadderPole	;@6678
	mov bh, 0	;@667B
	mov bl, byte ptr ViewDepth	;@667D
	mov di, bx	;@6681
	ret	;@6683
;------------------------------------------------------------------------------
; DrawLadderPole: the ladder pole at depth d: two vertical lines at x = 7Fh and 80h from y = CeilNearY
; (ceiling) to FloorNearY (floor).
; In: ViewDepth = d. Out: DI = d.
;------------------------------------------------------------------------------
DrawLadderPole:	mov bh, 0	;@6684
	mov bl, byte ptr ViewDepth	;@6686
	mov di, bx	;@668A
	mov al, 7Fh	;@668C
	mov byte ptr PlotX, al	;@668E
	mov byte ptr LineEndX, al	;@6691
	mov al, byte ptr cs:ViewCeilNearY[di]	;@6694
	mov byte ptr PlotY, al	;@6699
	mov al, byte ptr cs:ViewFloorNearY[di]	;@669C
	mov byte ptr LineEndY, al	;@66A1
	call DrawViewLine	;@66A4
	mov bh, 0	;@66A7
	mov bl, byte ptr ViewDepth	;@66A9
	mov di, bx	;@66AD
	mov al, 80h	;@66AF
	mov byte ptr PlotX, al	;@66B1
	mov byte ptr LineEndX, al	;@66B4
	mov al, byte ptr cs:ViewCeilNearY[di]	;@66B7
	mov byte ptr PlotY, al	;@66BC
	mov al, byte ptr cs:ViewFloorNearY[di]	;@66BF
	mov byte ptr LineEndY, al	;@66C4
	call DrawViewLine	;@66C7
	ret	;@66CA
;------------------------------------------------------------------------------
; DrawChest: a chest in the cell at depth d, a box in oblique view: the front face from
; (XL[d+2], ChestTopY) to (XR[d+3], FootNearY), the top face going back to the edge at y = FootFarY
; between XL[d+3] and XR[d+2]. Unlike the others it does not load DI itself: it relies on
; DI = d from the caller (DrawViewWalls).
; In: DI = ViewDepth = d. Out: DI = d.
;------------------------------------------------------------------------------
DrawChest:	nop	;@66CB
	mov al, byte ptr cs:ViewXL[di+2]	;@66CC
	mov byte ptr PlotX, al	;@66D1
	mov al, byte ptr cs:ViewChestTopY[di]	;@66D4
	mov byte ptr PlotY, al	;@66D9
	mov byte ptr LineEndY, al	;@66DC
	mov al, byte ptr cs:ViewXR[di+3]	;@66DF
	mov byte ptr LineEndX, al	;@66E4
	call DrawViewLine	;@66E7
	mov bh, 0	;@66EA
	mov bl, byte ptr ViewDepth	;@66EC
	mov di, bx	;@66F0
	mov al, byte ptr cs:ViewFootNearY[di]	;@66F2
	mov byte ptr LineEndY, al	;@66F7
	call DrawViewLine	;@66FA
	mov bh, 0	;@66FD
	mov bl, byte ptr ViewDepth	;@66FF
	mov di, bx	;@6703
	mov al, byte ptr cs:ViewXL[di+2]	;@6705
	mov byte ptr LineEndX, al	;@670A
	call DrawViewLine	;@670D
	mov bh, 0	;@6710
	mov bl, byte ptr ViewDepth	;@6712
	mov di, bx	;@6716
	mov al, byte ptr cs:ViewChestTopY[di]	;@6718
	mov byte ptr LineEndY, al	;@671D
	call DrawViewLine	;@6720
	mov bh, 0	;@6723
	mov bl, byte ptr ViewDepth	;@6725
	mov di, bx	;@6729
	mov al, byte ptr cs:ViewXL[di+3]	;@672B
	mov byte ptr LineEndX, al	;@6730
	mov al, byte ptr cs:ViewFootFarY[di]	;@6733
	mov byte ptr LineEndY, al	;@6738
	call DrawViewLine	;@673B
	mov bh, 0	;@673E
	mov bl, byte ptr ViewDepth	;@6740
	mov di, bx	;@6744
	mov al, byte ptr cs:ViewXR[di+2]	;@6746
	mov byte ptr LineEndX, al	;@674B
	call DrawViewLine	;@674E
	mov bh, 0	;@6751
	mov bl, byte ptr ViewDepth	;@6753
	mov di, bx	;@6757
	mov al, byte ptr cs:ViewChestTopY[di]	;@6759
	mov byte ptr LineEndY, al	;@675E
	call DrawViewLine	;@6761
	mov bh, 0	;@6764
	mov bl, byte ptr ViewDepth	;@6766
	mov di, bx	;@676A
	mov al, byte ptr cs:ViewXR[di+3]	;@676C
	mov byte ptr LineEndX, al	;@6771
	mov al, byte ptr cs:ViewFootNearY[di]	;@6774
	mov byte ptr LineEndY, al	;@6779
	call DrawViewLine	;@677C
	mov bh, 0	;@677F
	mov bl, byte ptr ViewDepth	;@6781
	mov di, bx	;@6785
	mov al, byte ptr cs:ViewXR[di+3]	;@6787
	mov byte ptr PlotX, al	;@678C
	mov al, byte ptr cs:ViewChestTopY[di]	;@678F
	mov byte ptr PlotY, al	;@6794
	mov al, byte ptr cs:ViewXR[di+2]	;@6797
	mov byte ptr LineEndX, al	;@679C
	mov al, byte ptr cs:ViewFootFarY[di]	;@679F
	mov byte ptr LineEndY, al	;@67A4
	call DrawViewLine	;@67A7
	mov bh, 0	;@67AA
	mov bl, byte ptr ViewDepth	;@67AC
	mov di, bx	;@67B0
	ret	;@67B2
;------------------------------------------------------------------------------
; DrawViewLine: draw a line from (PlotX, PlotY) to (LineEndX, LineEndY) (Bresenham, 8-bit). Plots
; with PlotPixel (OR) after each step, so the start pixel itself is not plotted (the previous
; line of a polyline ends there) and nothing is drawn when both ends are equal. Ends with
; PlotX/PlotY = the end point, so the next line can continue from it.
; Work: LineDX/LineDY = |dx|/|dy|, LineStepX/LineStepY = x/y step (+1 or FFh), LineCount = count,
; LineErr = error term.
; In: PlotX-LineEndY. Out: PlotX/PlotY = LineEndX/LineEndY. Uses: AX, BX, SI, DI (PlotPixel).
;------------------------------------------------------------------------------
DrawViewLine:	nop	;@67B3
	mov al, byte ptr LineEndX	;@67B4
	cmp al, byte ptr PlotX	;@67B7
	jne DrawViewLine_Setup	; start = end: nothing to draw	;@67BB
	mov al, byte ptr LineEndY	;@67BD
	cmp al, byte ptr PlotY	;@67C0
	jne DrawViewLine_Setup	;@67C4
	ret	;@67C6
DrawViewLine_Setup:	stc	;@67C7
	mov al, byte ptr LineEndX	;@67C8
	cmc	;@67CB
	sbb al, byte ptr PlotX	;@67CC
	cmc	;@67D0
	mov byte ptr LineDX, al	; x1-x0, CF = no borrow (6502 SBC)	;@67D1
	jb L67E7	;@67D4
	xor al, 0FFh	;@67D6
	mov byte ptr LineDX, al	;@67D8
	inc byte ptr LineDX	; negate: |dx|	;@67DB
	mov al, 0FFh	; x step -1	;@67DF
	mov byte ptr LineStepX, al	;@67E1
	jmp L67EC	;@67E4
L67E7:	mov al, 1	; x step +1	;@67E7
	mov byte ptr LineStepX, al	;@67E9
L67EC:	stc	;@67EC
	mov al, byte ptr LineEndY	;@67ED
	cmc	;@67F0
	sbb al, byte ptr PlotY	;@67F1
	cmc	;@67F5
	mov byte ptr LineDY, al	; y1-y0	;@67F6
	jb L680C	;@67F9
	xor al, 0FFh	;@67FB
	mov byte ptr LineDY, al	;@67FD
	inc byte ptr LineDY	; negate: |dy|	;@6800
	mov al, 0FFh	; y step -1	;@6804
	mov byte ptr LineStepY, al	;@6806
	jmp L6811	;@6809
L680C:	mov al, 1	; y step +1	;@680C
	mov byte ptr LineStepY, al	;@680E
L6811:	mov al, byte ptr LineDX	;@6811
	cmp al, byte ptr LineDY	;@6814
	jae DrawViewLine_XMajor	;@6818
	jmp DrawViewLine_YMajor	;@681A
; |dx| >= |dy|: step x every time, y when the error term overflows |dx|.
DrawViewLine_XMajor:	mov al, byte ptr LineDX	;@681D
	mov byte ptr LineCount, al	;@6820
	clc	;@6823
	rcr al, 1	; error term = count/2	;@6824
	mov byte ptr LineErr, al	;@6826
DrawViewLine_XLoop:	clc	;@6829
	mov al, byte ptr LineErr	;@682A
	adc al, byte ptr LineDY	;@682D
	mov byte ptr LineErr, al	;@6831
	stc	;@6834
	cmc	;@6835
	sbb al, byte ptr LineDX	; error - |dx|: no borrow = overflow	;@6836
	cmc	;@683A
	jae L684B	;@683B
	mov byte ptr LineErr, al	;@683D
	clc	;@6840
	mov al, byte ptr PlotY	;@6841
	adc al, byte ptr LineStepY	;@6844
	mov byte ptr PlotY, al	;@6848
L684B:	clc	;@684B
	mov al, byte ptr PlotX	;@684C
	adc al, byte ptr LineStepX	;@684F
	mov byte ptr PlotX, al	;@6853
	call PlotPixel	; plot	;@6856
	dec byte ptr LineCount	;@6859
	jne DrawViewLine_XLoop	;@685D
	ret	;@685F
; |dy| > |dx|: step y every time, x when the error term overflows |dy|.
DrawViewLine_YMajor:	mov al, byte ptr LineDY	;@6860
	mov byte ptr LineCount, al	;@6863
	clc	;@6866
	rcr al, 1	;@6867
	mov byte ptr LineErr, al	;@6869
DrawViewLine_YLoop:	clc	;@686C
	mov al, byte ptr LineErr	;@686D
	adc al, byte ptr LineDX	;@6870
	mov byte ptr LineErr, al	;@6874
	stc	;@6877
	cmc	;@6878
	sbb al, byte ptr LineDY	; error - |dy|: no borrow = overflow	;@6879
	cmc	;@687D
	jae L688E	;@687E
	mov byte ptr LineErr, al	;@6880
	clc	;@6883
	mov al, byte ptr PlotX	;@6884
	adc al, byte ptr LineStepX	;@6887
	mov byte ptr PlotX, al	;@688B
L688E:	clc	;@688E
	mov al, byte ptr PlotY	;@688F
	adc al, byte ptr LineStepY	;@6892
	mov byte ptr PlotY, al	;@6896
	call PlotPixel	; plot	;@6899
	dec byte ptr LineCount	;@689C
	jne DrawViewLine_YLoop	;@68A0
	ret	;@68A2
;------------------------------------------------------------------------------
; PlotShapeBlock: plot one 4x4-pixel block of a monster shape at (WorkX*4, WorkY*4) with the
; colour pattern BlockColor (0-7, byte from the CS table FillPatternTbl), through FillBlock4x4 (overwrites).
; In: WorkX, WorkY, BlockColor. Uses: AX, BX, BP.
;------------------------------------------------------------------------------
PlotShapeBlock:	nop	;@68A3
	mov ah, 0	;@68A4
	mov al, byte ptr BlockColor	; colour pattern	;@68A6
	mov bp, ax	;@68A9
	mov al, byte ptr WorkX	; X in 4-pixel units	;@68AB
	shl ax, 1	;@68AE
	shl ax, 1	;@68B0
	mov bh, 0	;@68B2
	mov bl, byte ptr WorkY	; Y in 4-pixel units	;@68B4
	shl bx, 1	;@68B8
	shl bx, 1	;@68BA
	call FillBlock4x4	;@68BC
	ret	;@68BF
;------------------------------------------------------------------------------
; GetDungeonCell: read a dungeon cell. Address = MapBufPtr (map buffer) + DungeonLevel*100h + LookY*16 +
; LookX, kept in the word CellPtr (CellPtrHi = high byte). The low byte ignores the low byte of
; MapBufPtr (it is 00h) and only works for X, Y < 16 (callers mask with 3Fh, though).
; In: LookX = X, LookY = Y, DungeonLevel = level. Out: AL = cell, CellPtr.
; Uses: AX, BX, SI (= 0).
;------------------------------------------------------------------------------
GetDungeonCell:	mov ah, byte ptr DungeonLevel	; level = page of the map buffer	;@68C0
	mov al, 0	;@68C4
	add ax, word ptr MapBufPtr	;@68C6
	mov byte ptr CellPtrHi, ah	;@68CA
	mov al, byte ptr LookY	;@68CE
	add al, al	;@68D1
	add al, al	;@68D3
	add al, al	;@68D5
	add al, al	;@68D7
	adc al, byte ptr LookX	; Y*16+X (CF from the shift is 0 for Y < 16)	;@68D9
	mov byte ptr CellPtr, al	;@68DD
	mov bh, 0	;@68E0
	mov bl, 0	;@68E2
	mov si, bx	;@68E4
	mov bx, word ptr CellPtr	; cell pointer (6502 (zp),y idiom with SI = 0)	;@68E6
	mov al, byte ptr [bx+si]	;@68EA
	ret	;@68EC
;------------------------------------------------------------------------------
; DrawViewMonster: draw the nearest monster in the line of sight. For d = 1 up to the last depth
; drawn, the first d with ViewMonsters[d] <> 0 is drawn and the routine returns. The shape is
; in the monster buffer (MonsterBufPtr): at d = 1 the page ViewMonsters[d] (the monster's own shape);
; farther away the type is dropped and a generic smaller shape at offset MonsterShapeOfsTbl[d] of
; page 0 is used. A shape is a list of byte pairs (X, pattern*32 + Y) ending with X = 0;
; each pair is one 4x4 block (PlotShapeBlock).
; In: ViewDepth (from DrawViewWalls), ViewMonsters. Out: ViewDepth + 1. Uses: AX, BX, SI, DI, BP, WorkX/WorkY.
;------------------------------------------------------------------------------
DrawViewMonster:	nop	;@68ED
	inc byte ptr ViewDepth	; last depth + 1 = limit	;@68EE
	mov bh, 0	;@68F2
	mov bl, 0	;@68F4
	mov di, bx	;@68F6
; Next depth.
DrawMonster_NextDepth:	inc di	;@68F8
	mov bx, di	;@68F9
	cmp bl, byte ptr ViewDepth	;@68FB
	jb L6902	;@68FF
	ret	;@6901
L6902:	mov ah, byte ptr ViewMonsters[di]	;@6902
	or ah, ah	; monster at depth d?	;@6906
	je DrawMonster_NextDepth	;@6908
	cmp di, 1	; next to the player: its own shape	;@690A
	je DrawMonster_Near	;@690D
	mov ax, word ptr MonsterBufPtr	; farther: AH = page of the buffer, the type is lost	;@690F
	mov byte ptr ShapePtrHi, ah	;@6912
	mov al, byte ptr cs:MonsterShapeOfsTbl[di]	; generic shape for this depth	;@6916
	mov byte ptr ShapePtr, al	;@691B
	mov al, byte ptr ShapePtrHi	;@691E
	mov bh, 0	;@6921
	mov bl, byte ptr ShapePtr	;@6923
	mov di, bx	;@6927
	jmp DrawMonster_Loop	;@6929
DrawMonster_Near:	clc	;@692C
; AH = type: page ViewMonsters[d] (AL junk, low byte of MonsterBufPtr is 0)
	add ax, word ptr MonsterBufPtr	;@692D
	mov byte ptr ShapePtrHi, ah	;@6931
	mov byte ptr ShapePtr, 0	;@6935
; Shape loop: ShapePtr (word) points to the next pair.
DrawMonster_Loop:	mov bh, 0	;@693A
	mov bl, 0	;@693C
	mov si, bx	;@693E
	mov bx, word ptr ShapePtr	;@6940
	mov al, byte ptr [bx+si]	;@6944
	or al, al	; X = 0: end of the shape, done	;@6946
	jne L694B	;@6948
	ret	;@694A
L694B:	mov byte ptr WorkX, al	;@694B
	inc word ptr ShapePtr	;@694E
	mov bx, word ptr ShapePtr	;@6952
	mov al, byte ptr [bx+si]	;@6956
	and al, 1Fh	; Y = low 5 bits	;@6958
	mov byte ptr WorkY, al	;@695A
	mov bx, word ptr ShapePtr	;@695D
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
	mov byte ptr BlockColor, al	;@6972
	inc word ptr ShapePtr	;@6975
	call PlotShapeBlock	;@6979
	jmp DrawMonster_Loop	;@697C
;------------------------------------------------------------------------------
; MonsterShapeOfsTbl: offset of the generic monster shape in page 0 of the monster buffer, by depth
; (0 for depths 0/1, unused): 80h, C0h, E0h ... smaller shapes farther away. Padding
; follows.
;------------------------------------------------------------------------------
MonsterShapeOfsTbl label byte
	db 0h,0h,80h,0C0h,0E0h,0F0h,0F8h,0FCh,0h,0h,0h,0h,0h,0h,0h,0h	;@697E
	db 0h,0h	;@698E
;------------------------------------------------------------------------------
; SpaceToneDivisor-SpeakerIsOff: CS variables of space flight (they only sit in this module):
; SpaceToneDivisor (word) = pitch of the hyperwarp sound (divisor for HoldTone), SpaceToneStep (word) = its step
; per star move (FFFFh or 1), BleepCountdown (word) = star moves until the next bleep toggle (ToggleSpaceBleep),
; StarRndSeed/StarRndSeed2 = state of the star-field random generator (StarRnd, reset to 3Bh/67h by
; ResetStarRnd), SpeakerIsOff = speaker state (FFh = off, 0 = on).
;------------------------------------------------------------------------------
SpaceToneDivisor label byte
	db 0h,0h	;@6990
SpaceToneStep label byte
	db 0h,0h	;@6992
BleepCountdown label byte
	db 0h,0h	;@6994
StarRndSeed label byte
	db 0h	;@6996
StarRndSeed2 label byte
	db 0h	;@6997
SpeakerIsOff label byte
	db 0h	;@6998
CODE ENDS
END
