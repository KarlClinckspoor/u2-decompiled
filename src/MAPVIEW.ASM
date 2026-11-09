; MAPVIEW.ASM: drawing the outdoor and town map window.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 5AB1-5C90.
;
; UpdateMapView (the only entry point) updates the map window: 20 x 10 tiles of the 64x64 map around
; the player (PlayerX, PlayerY), who is in column 9, row 5. Two versions of the same loop: maps
; that wrap round (OffMapTile = FFh: the outdoor maps) and maps with an edge, outside of which
; every square shows the tile OffMapTile (towns, castles).
; Map bytes are tile number * 4; the window caches hold tile number * 2 (a word index into the
; pointer table TilePtrTbl). TileCache = the new window, TileCacheShown = what is on the screen. A cell that
; did not change gets bit 7 set in TileCache and DrawMapWindow skips it, except water (0; unless
; PlaneFlying = FFh) and the force field (2Eh), which are animated and always redrawn.
; Also leaves the tiles under and around the player in TileHere-TileWest for the movement code
; and puts the player's icon PlayerTile in the centre cell.
; Scratch: FacingDX/FacingDY (top-left map square), WorkX/WorkY (column/row counters),
; MapCellPtr/MapCellPtrHi (map address), the CS byte MapViewCol (defined in CHARGEN).
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN PlayerX:BYTE, PlayerY:BYTE, FacingDX:BYTE, FacingDY:BYTE, WorkX:BYTE, WorkY:BYTE
	EXTRN MapCellPtr:BYTE, MapCellPtrHi:BYTE, OffMapTile:BYTE, PlayerTile:BYTE, TileHere:BYTE, TileNorth:BYTE
	EXTRN TileSouth:BYTE, TileEast:BYTE, TileWest:BYTE, TileCache:BYTE, TileCacheNorth:BYTE, TileCacheWest:BYTE
	EXTRN TileCacheCentre:BYTE, TileCacheEast:BYTE, TileCacheSouth:BYTE, TileCacheShown:BYTE, MapBufPtr:BYTE
	EXTRN PlaneFlying:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA
MapBufPtrHi equ byte ptr MapBufPtr+1

CODE SEGMENT BYTE PUBLIC
	EXTRN DrawMapWindow:NEAR, MapViewCol:BYTE
	PUBLIC UpdateMapView
ASSUME CS:CODE, DS:DATA
;------------------------------------------------------------------------------
; UpdateMapView: update the map window around the player and draw what changed.
; Fills TileCache (20 x 10 cells, see the module header), sets TileHere = tile
; under the player, TileNorth/TileSouth/TileEast/TileWest = tiles north/south/east/west
; (cache values, bit 7 possibly set: callers mask it), puts the icon PlayerTile in
; the centre cell, draws with DrawMapWindow and copies TileCache (without bit 7) to TileCacheShown.
; In: PlayerX/PlayerY (player), OffMapTile, PlayerTile, MapBufPtr (map buffer), PlaneFlying.
; Out: TileHere-TileWest, TileCache, TileCacheShown. Uses: AX, BX, SI, DI, FacingDX-MapCellPtrHi.
;------------------------------------------------------------------------------
UpdateMapView:	cmp byte ptr OffMapTile, 0FFh	;@5AB1
	jne MapView_Edged	;@5AB6
	jmp MapView_Wrap		; FFh: the map wraps round	;@5AB8
; map with an edge: top-left square = (x-9, y-5); stc/cmc/sbb/cmc = 6502 SEC/SBC
MapView_Edged:	stc	;@5ABB
	mov al, byte ptr PlayerY	;@5ABC
	cmc	;@5ABF
	sbb al, 5	;@5AC0
	cmc	;@5AC2
	mov byte ptr FacingDY, al	;@5AC3
	stc	;@5AC6
	mov al, byte ptr PlayerX	;@5AC7
	cmc	;@5ACA
	sbb al, 9	;@5ACB
	cmc	;@5ACD
	mov byte ptr FacingDX, al	;@5ACE
	mov al, 0	;@5AD1
	mov byte ptr WorkY, al	;@5AD3
	mov byte ptr WorkX, al	;@5AD6
	mov ah, 0	;@5AD9
	mov si, ax		; SI = 0	;@5ADB
	mov ah, 0	;@5ADD
	mov di, ax		; DI = cell index into TileCache/TileCacheShown	;@5ADF
MapView_Loop:	clc	;@5AE1
	mov al, byte ptr WorkX	;@5AE2
	adc al, byte ptr FacingDX	;@5AE5
	cmp al, 40h		; map x outside 0-63 (negative = above 7Fh)?	;@5AE9
	jae MapView_Outside	;@5AEB
	clc	;@5AED
	mov al, byte ptr WorkY	;@5AEE
	adc al, byte ptr FacingDY	;@5AF1
	cmp al, 40h	;@5AF5
	jb MapView_Inside	;@5AF7
MapView_Outside:	mov al, byte ptr OffMapTile		; outside the map: the border tile	;@5AF9
	jmp MapView_Compare	;@5AFC
; address = map buffer + 64*y + x: rotate y's low 2 bits into the top of AL
MapView_Inside:	mov byte ptr MapCellPtrHi, al	;@5AFF
	mov al, 0	;@5B02
	clc	;@5B04
	rcr byte ptr MapCellPtrHi, 1	;@5B05
	rcr al, 1	;@5B09
	clc	;@5B0B
	rcr byte ptr MapCellPtrHi, 1	;@5B0C
	rcr al, 1	;@5B10
	adc al, byte ptr WorkX	;@5B12
	adc al, byte ptr FacingDX	;@5B16
	mov byte ptr MapCellPtr, al	;@5B1A
	clc	;@5B1D
	mov al, byte ptr MapCellPtrHi	;@5B1E
	adc al, byte ptr MapBufPtrHi		; + high byte of the map buffer address	;@5B21
	mov byte ptr MapCellPtrHi, al	;@5B25
	mov bx, word ptr MapCellPtr	;@5B28
	mov al, byte ptr [bx+si]	;@5B2C
	clc	;@5B2E
	rcr al, 1	;@5B2F
	and al, 0FEh		; map byte / 2 = tile number * 2	;@5B31
; unchanged since the last draw? then mark it (bit 7), except animated water and force field
MapView_Compare:	cmp al, byte ptr TileCacheShown[di]	;@5B33
	jne MapView_Store	;@5B37
	cmp al, 0	;@5B39
	jne MapView_NotWater	;@5B3B
	cmp byte ptr PlaneFlying, 0FFh	;@5B3D
	jne MapView_Store	;@5B42
	jmp MapView_Unchanged	;@5B44
MapView_NotWater:	cmp al, 2Eh		; tile 23, the force field	;@5B47
	je MapView_Store	;@5B49
MapView_Unchanged:	or al, 80h	;@5B4B
MapView_Store:	mov byte ptr TileCache[di], al	;@5B4D
	inc di	;@5B51
	inc byte ptr WorkX	;@5B52
	mov al, byte ptr WorkX	;@5B56
	cmp al, 14h		; 20 columns	;@5B59
	jne MapView_Loop	;@5B5B
	mov bx, si	;@5B5D
	mov byte ptr WorkX, bl	;@5B5F
	inc byte ptr WorkY	;@5B63
	mov al, byte ptr WorkY	;@5B67
	cmp al, 0Ah		; 10 rows	;@5B6A
	je MapView_Neighbours	;@5B6C
	jmp MapView_Loop	;@5B6E
; cells 6Dh (centre: column 9, row 5), 59h (north), 81h (south), 6Ch (west), 6Eh (east)
MapView_Neighbours:	mov al, byte ptr TileCacheCentre	;@5B71
	mov byte ptr TileHere, al	;@5B74
	mov al, byte ptr TileCacheNorth	;@5B77
	mov byte ptr TileNorth, al	;@5B7A
	mov al, byte ptr TileCacheSouth	;@5B7D
	mov byte ptr TileSouth, al	;@5B80
	mov al, byte ptr TileCacheWest	;@5B83
	mov byte ptr TileWest, al	;@5B86
	mov al, byte ptr TileCacheEast	;@5B89
	mov byte ptr TileEast, al	;@5B8C
	mov al, byte ptr PlayerTile		; the player's icon goes in the centre (always drawn)	;@5B8F
	mov byte ptr TileCacheCentre, al	;@5B92
	jmp MapView_Draw	;@5B95
; map that wraps round: as above, but coordinates are taken mod 64 and MapViewCol holds the x
MapView_Wrap:	stc	;@5B98
	mov al, byte ptr PlayerY	;@5B99
	cmc	;@5B9C
	sbb al, 5	;@5B9D
	cmc	;@5B9F
	and al, 3Fh	;@5BA0
	mov byte ptr FacingDY, al	;@5BA2
	stc	;@5BA5
	mov al, byte ptr PlayerX	;@5BA6
	cmc	;@5BA9
	sbb al, 9	;@5BAA
	cmc	;@5BAC
	and al, 3Fh	;@5BAD
	mov byte ptr FacingDX, al	;@5BAF
	mov al, 0	;@5BB2
	mov byte ptr WorkY, al	;@5BB4
	mov byte ptr WorkX, al	;@5BB7
	mov ah, 0	;@5BBA
	mov si, ax	;@5BBC
	mov ah, 0	;@5BBE
	mov di, ax	;@5BC0
MapView_WrapLoop:	clc	;@5BC2
	mov al, byte ptr WorkX	;@5BC3
	adc al, byte ptr FacingDX	;@5BC6
	and al, 3Fh	;@5BCA
	mov byte ptr cs:MapViewCol, al	; map x, kept in a CS byte (self-modified)	;@5BCC
	clc	;@5BD0
	mov al, byte ptr WorkY	;@5BD1
	adc al, byte ptr FacingDY	;@5BD4
	and al, 3Fh	;@5BD8
	mov byte ptr MapCellPtrHi, al	;@5BDA
	mov al, 0	;@5BDD
	clc	;@5BDF
	rcr byte ptr MapCellPtrHi, 1	;@5BE0
	rcr al, 1	;@5BE4
	clc	;@5BE6
	rcr byte ptr MapCellPtrHi, 1	;@5BE7
	rcr al, 1	;@5BEB
	adc al, byte ptr cs:MapViewCol	;@5BED
	mov byte ptr MapCellPtr, al	;@5BF2
	clc	;@5BF5
	mov al, byte ptr MapCellPtrHi	;@5BF6
	adc al, byte ptr MapBufPtrHi	;@5BF9
	mov byte ptr MapCellPtrHi, al	;@5BFD
	mov bx, word ptr MapCellPtr	;@5C00
	mov al, byte ptr [bx+si]	;@5C04
	clc	;@5C06
	rcr al, 1	;@5C07
	and al, 0FEh	;@5C09
	cmp al, byte ptr TileCacheShown[di]	;@5C0B
	jne MapView_WrapStore	;@5C0F
	cmp al, 0	;@5C11
	jne MapView_WrapNotWater	;@5C13
	cmp byte ptr PlaneFlying, 0FFh	;@5C15
	jne MapView_WrapStore	;@5C1A
	jmp MapView_WrapUnchanged	;@5C1C
MapView_WrapNotWater:	cmp al, 2Eh	;@5C1F
	je MapView_WrapStore	;@5C21
MapView_WrapUnchanged:	or al, 80h	;@5C23
MapView_WrapStore:	mov byte ptr TileCache[di], al	;@5C25
	inc di	;@5C29
	inc byte ptr WorkX	;@5C2A
	mov al, byte ptr WorkX	;@5C2E
	cmp al, 14h	;@5C31
	jne MapView_WrapLoop	;@5C33
	mov bx, si	;@5C35
	mov byte ptr WorkX, bl	;@5C37
	inc byte ptr WorkY	;@5C3B
	mov al, byte ptr WorkY	;@5C3F
	cmp al, 0Ah	;@5C42
	je MapView_WrapNeighbours	;@5C44
	jmp MapView_WrapLoop	;@5C46
MapView_WrapNeighbours:	mov al, byte ptr TileCacheCentre	;@5C49
	mov byte ptr TileHere, al	;@5C4C
	mov al, byte ptr TileCacheNorth	;@5C4F
	mov byte ptr TileNorth, al	;@5C52
	mov al, byte ptr TileCacheSouth	;@5C55
	mov byte ptr TileSouth, al	;@5C58
	mov al, byte ptr TileCacheWest	;@5C5B
	mov byte ptr TileWest, al	;@5C5E
	mov al, byte ptr TileCacheEast	;@5C61
	mov byte ptr TileEast, al	;@5C64
	mov al, byte ptr PlayerTile	;@5C67
	mov byte ptr TileCacheCentre, al	;@5C6A
; both versions: draw the changed cells, then remember what is on the screen
MapView_Draw:	call DrawMapWindow	;@5C6D
	mov bh, 0	;@5C70
	mov bl, 0	;@5C72
	mov di, bx	;@5C74
MapView_SaveLoop:	mov al, byte ptr TileCache[di]	;@5C76
	and al, 7Fh	;@5C7A
	mov byte ptr TileCacheShown[di], al	;@5C7C
	inc di	;@5C80
	mov bx, di	;@5C81
	cmp bl, 0F0h		; copies 240 bytes, though the window has 200 cells	;@5C83
	jne MapView_SaveLoop	;@5C86
	ret	;@5C88
; zero padding up to 5C90 (SOUND)
	db 0h,0h,0h,0h,0h,0h,0h	;@5C89
CODE ENDS
END
