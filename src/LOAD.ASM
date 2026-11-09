; LOAD.ASM: loading the map, monster, talk and player files.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 2290-2362.
;
; The per-location files are named <kind><letter><zone><type>, e.g. MAPX03, MONX11, TLKX21:
;   letter = 'X' on Earth, 'G' on the other planets (SPACE 720B patches the three letter bytes
;            FcbMapLetter/FcbMonLetter/FcbTlkLetter here in CS),
;   zone   = TimeZone as an ASCII digit (time zone on Earth, planet number elsewhere),
;   type   = MapType as an ASCII digit (0 surface, 1 village, 2 towne, 3 castle, 4 tower,
;            5 dungeon; set by Enter in CMDAL 33C3).
; The digits are patched into the inline file names right before each call ReadWriteFile (self-modifying).
; Entry points:
;   LoadMapAndMonsters load MAPxzt (map buffer, 1000h bytes) and MONxzt (monster table MonsterX, 100h bytes)
;   LoadTalkFile load TLKxzt (talk buffer, 100h bytes)
;   SaveGame save the game: MAPXzt, MONXzt and PLAYER (player record PlayerRecord, 100h bytes); Earth only
; ReadWriteFile takes AH = FCB function (27h random block read, 28h random block write), CX = byte count
; (record size 1), DX = buffer; it saves and restores all registers, so AH/CX carry over between
; consecutive calls.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN PlayerX:BYTE, PlayerY:BYTE, PlayerRecord:BYTE, TimeZone:BYTE, MapType:BYTE, SurfaceX:BYTE
	EXTRN SurfaceY:BYTE, Planet:BYTE, MonsterX:BYTE, MapBufPtr:BYTE, TalkBufPtr:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN ReadKey:NEAR, ReadWriteFile:NEAR
	PUBLIC LoadMapAndMonsters, FcbMapLetter, FcbMonLetter, LoadTalkFile, FcbTlkLetter, SaveGame
ASSUME CS:CODE, DS:DATA

;------------------------------------------------------------------------------
; LoadMapAndMonsters: load the map and monsters of the current location: MAP<l><zone><type>
; (1000h bytes into the map buffer at MapBufPtr) and MON<l><zone><type> (100h bytes
; into the monster table MonsterX..D_0236), zone = TimeZone, type = MapType. Then one
; poll of the keyboard (ReadKey) to throw away a pending key.
; In: TimeZone, MapType, letter byte at FcbMapLetter/FcbMonLetter. Out: map and monsters loaded.
; Uses: AX, CX, DX (ReadWriteFile keeps the rest). ReadWriteFile asks for the disk until it can open the file.
;------------------------------------------------------------------------------
LoadMapAndMonsters:	clc	;@2290
	mov al, byte ptr TimeZone	;@2291
	adc al, 30h	; zone -> ASCII digit	;@2294
	mov byte ptr cs:FcbMapZone, al	; patch "MAPxZ.." (self-modifying)	;@2296
	mov byte ptr cs:FcbMonZone, al	; patch "MONxZ.."	;@229A
	mov al, byte ptr MapType	;@229E
	adc al, 30h	; location type -> ASCII digit	;@22A1
	mov byte ptr cs:FcbMapType, al	; patch "MAPxzT."	;@22A3
	mov byte ptr cs:FcbMonType, al	; patch "MONxzT."	;@22A7
	mov ah, 27h	; FCB random block read	;@22AB
	mov cx, 1000h	; 64x64 map	;@22AD
	mov dx, word ptr MapBufPtr	; map buffer	;@22B0
	call ReadWriteFile	;@22B4
	db 4Dh,41h,50h	; "MAP"	;@22B7
FcbMapLetter label byte
	db 58h	; 'X' or 'G' (patched by SPACE 720B)	;@22BA
FcbMapZone label byte
	db 46h	; zone digit (patched)	;@22BB
FcbMapType label byte
	db 46h,20h,20h	; type digit (patched), 2 spaces	;@22BC
	mov cx, 100h	; AH is still 27h	;@22BF
	lea dx, MonsterX	; monster table	;@22C2
	call ReadWriteFile	;@22C6
	db 4Dh,4Fh,4Eh	; "MON"	;@22C9
FcbMonLetter label byte
	db 58h	; 'X' or 'G' (patched by SPACE 720B)	;@22CC
FcbMonZone label byte
	db 46h	; zone digit (patched)	;@22CD
FcbMonType label byte
	db 46h,20h,20h	; type digit (patched), 2 spaces	;@22CE
	call ReadKey	; poll the keyboard: drops one waiting key	;@22D1
	ret	;@22D4

;------------------------------------------------------------------------------
; LoadTalkFile: load the talk file TLK<l><zone><type> (100h bytes) into the talk buffer
; at TalkBufPtr. Called after LoadMapAndMonsters when entering a village, towne or castle.
; In: TimeZone, MapType, letter at FcbTlkLetter. Uses: AX, CX, DX.
;------------------------------------------------------------------------------
LoadTalkFile:	clc	;@22D5
	mov al, byte ptr TimeZone	;@22D6
	adc al, 30h	;@22D9
	mov byte ptr cs:FcbTlkZone, al	; patch the zone digit (self-modifying)	;@22DB
	mov al, byte ptr MapType	;@22DF
	adc al, 30h	;@22E2
	mov byte ptr cs:FcbTlkType, al	; patch the type digit	;@22E4
	mov ah, 27h	; FCB random block read	;@22E8
	mov cx, 100h	;@22EA
	mov dx, word ptr TalkBufPtr	; talk buffer	;@22ED
	call ReadWriteFile	;@22F1
	db 54h,4Ch,4Bh	; "TLK"	;@22F4
FcbTlkLetter label byte
	db 58h	; 'X' or 'G' (patched by SPACE 720B)	;@22F7
FcbTlkZone label byte
	db 46h	; zone digit (patched)	;@22F8
FcbTlkType label byte
	db 46h,20h,20h	; type digit (patched), 2 spaces	;@22F9
	ret	;@22FC

;------------------------------------------------------------------------------
; SaveGame: save the game, on Earth only (Planet = 0; elsewhere it returns at once).
; Remembers the current position as the surface position SurfaceX/SurfaceY, then
; writes MAPX<zone><type> (1000h), MONX<zone><type> (100h, monster table) and
; PLAYER (100h, player record from PlayerRecord). The letter is a fixed 'X' here.
; Called before entering a location, before a time door and by Q)uit.
; In: TimeZone, MapType, PlayerX/PlayerY. Uses: AX, CX, DX.
;------------------------------------------------------------------------------
SaveGame:	mov al, byte ptr Planet	; planet: 0 = Earth	;@22FD
	or al, al	;@2300
	je SaveGame_Write	;@2302
	ret	;@2304
SaveGame_Write:	clc	;@2305
	mov al, byte ptr TimeZone	;@2306
	adc al, 30h	;@2309
	mov byte ptr cs:FcbSaveMapZone, al	; patch the zone digits (self-modifying)	;@230B
	mov byte ptr cs:FcbSaveMonZone, al	;@230F
	mov al, byte ptr MapType	;@2313
	adc al, 30h	;@2316
	mov byte ptr cs:FcbSaveMapType, al	; patch the type digits	;@2318
	mov byte ptr cs:FcbSaveMonType, al	;@231C
	mov al, byte ptr PlayerX	; position -> surface position	;@2320
	mov byte ptr SurfaceX, al	;@2323
	mov al, byte ptr PlayerY	;@2326
	mov byte ptr SurfaceY, al	;@2329
	mov ah, 28h	; FCB random block write	;@232C
	mov cx, 1000h	;@232E
	mov dx, word ptr MapBufPtr	; map buffer	;@2331
	call ReadWriteFile	;@2335
	db 4Dh,41h,50h,58h	; "MAPX"	;@2338
FcbSaveMapZone label byte
	db 46h	; zone digit (patched)	;@233C
FcbSaveMapType label byte
	db 46h,20h,20h	; type digit (patched), 2 spaces	;@233D
	mov cx, 100h	; AH is still 28h	;@2340
	lea dx, MonsterX	; monster table	;@2343
	call ReadWriteFile	;@2347
	db 4Dh,4Fh,4Eh,58h	; "MONX"	;@234A
FcbSaveMonZone label byte
	db 46h	; zone digit (patched)	;@234E
FcbSaveMonType label byte
	db 46h,20h,20h	; type digit (patched), 2 spaces	;@234F
	lea dx, PlayerRecord	; player record; AH = 28h, CX = 100h still	;@2352
	call ReadWriteFile	;@2356
	db 50h,4Ch,41h,59h,45h,52h,20h,20h	; "PLAYER  "	;@2359
	ret	;@2361
CODE ENDS
END
