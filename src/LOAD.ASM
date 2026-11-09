; LOAD.ASM: loading the map, monster, talk and player files.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 2290-2362.
;
; The per-location files are named <kind><letter><zone><type>, e.g. MAPX03, MONX11, TLKX21:
;   letter = 'X' on Earth, 'G' on the other planets (SPACE 720B patches the three letter bytes
;            L22BA/L22CC/L22F7 here in CS),
;   zone   = D_0049 as an ASCII digit (time zone on Earth, planet number elsewhere),
;   type   = D_004A as an ASCII digit (0 surface, 1 village, 2 towne, 3 castle, 4 tower,
;            5 dungeon; set by Enter in CMDAL 33C3).
; The digits are patched into the inline file names right before each call L52CA (self-modifying).
; Entry points:
;   L2290 load MAPxzt (map buffer, 1000h bytes) and MONxzt (monster table D_0137, 100h bytes)
;   L22D5 load TLKxzt (talk buffer, 100h bytes)
;   L22FD save the game: MAPXzt, MONXzt and PLAYER (player record D_0036, 100h bytes); Earth only
; L52CA takes AH = FCB function (27h random block read, 28h random block write), CX = byte count
; (record size 1), DX = buffer; it saves and restores all registers, so AH/CX carry over between
; consecutive calls.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0000:BYTE, D_0001:BYTE, D_0036:BYTE, D_0049:BYTE, D_004A:BYTE, D_005A:BYTE
	EXTRN D_005B:BYTE, D_006D:BYTE, D_0137:BYTE, D_0472:BYTE, D_0476:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L4F4D:NEAR, L52CA:NEAR
	PUBLIC L2290, L22BA, L22CC, L22D5, L22F7, L22FD
ASSUME CS:CODE, DS:DATA

;------------------------------------------------------------------------------
; L2290: load the map and monsters of the current location: MAP<l><zone><type>
; (1000h bytes into the map buffer at D_0472) and MON<l><zone><type> (100h bytes
; into the monster table D_0137..D_0236), zone = D_0049, type = D_004A. Then one
; poll of the keyboard (L4F4D) to throw away a pending key.
; In: D_0049, D_004A, letter byte at L22BA/L22CC. Out: map and monsters loaded.
; Uses: AX, CX, DX (L52CA keeps the rest). L52CA asks for the disk until it can open the file.
;------------------------------------------------------------------------------
L2290:	clc	;@2290
	mov al, byte ptr D_0049	;@2291
	adc al, 30h	; zone -> ASCII digit	;@2294
	mov byte ptr cs:L22BB, al	; patch "MAPxZ.." (self-modifying)	;@2296
	mov byte ptr cs:L22CD, al	; patch "MONxZ.."	;@229A
	mov al, byte ptr D_004A	;@229E
	adc al, 30h	; location type -> ASCII digit	;@22A1
	mov byte ptr cs:L22BC, al	; patch "MAPxzT."	;@22A3
	mov byte ptr cs:L22CE, al	; patch "MONxzT."	;@22A7
	mov ah, 27h	; FCB random block read	;@22AB
	mov cx, 1000h	; 64x64 map	;@22AD
	mov dx, word ptr D_0472	; map buffer	;@22B0
	call L52CA	;@22B4
	db 4Dh,41h,50h	; "MAP"	;@22B7
L22BA label byte
	db 58h	; 'X' or 'G' (patched by SPACE 720B)	;@22BA
L22BB label byte
	db 46h	; zone digit (patched)	;@22BB
L22BC label byte
	db 46h,20h,20h	; type digit (patched), 2 spaces	;@22BC
	mov cx, 100h	; AH is still 27h	;@22BF
	lea dx, D_0137	; monster table	;@22C2
	call L52CA	;@22C6
	db 4Dh,4Fh,4Eh	; "MON"	;@22C9
L22CC label byte
	db 58h	; 'X' or 'G' (patched by SPACE 720B)	;@22CC
L22CD label byte
	db 46h	; zone digit (patched)	;@22CD
L22CE label byte
	db 46h,20h,20h	; type digit (patched), 2 spaces	;@22CE
	call L4F4D	; poll the keyboard: drops one waiting key	;@22D1
	ret	;@22D4

;------------------------------------------------------------------------------
; L22D5: load the talk file TLK<l><zone><type> (100h bytes) into the talk buffer
; at D_0476. Called after L2290 when entering a village, towne or castle.
; In: D_0049, D_004A, letter at L22F7. Uses: AX, CX, DX.
;------------------------------------------------------------------------------
L22D5:	clc	;@22D5
	mov al, byte ptr D_0049	;@22D6
	adc al, 30h	;@22D9
	mov byte ptr cs:L22F8, al	; patch the zone digit (self-modifying)	;@22DB
	mov al, byte ptr D_004A	;@22DF
	adc al, 30h	;@22E2
	mov byte ptr cs:L22F9, al	; patch the type digit	;@22E4
	mov ah, 27h	; FCB random block read	;@22E8
	mov cx, 100h	;@22EA
	mov dx, word ptr D_0476	; talk buffer	;@22ED
	call L52CA	;@22F1
	db 54h,4Ch,4Bh	; "TLK"	;@22F4
L22F7 label byte
	db 58h	; 'X' or 'G' (patched by SPACE 720B)	;@22F7
L22F8 label byte
	db 46h	; zone digit (patched)	;@22F8
L22F9 label byte
	db 46h,20h,20h	; type digit (patched), 2 spaces	;@22F9
	ret	;@22FC

;------------------------------------------------------------------------------
; L22FD: save the game, on Earth only (D_006D = 0; elsewhere it returns at once).
; Remembers the current position as the surface position D_005A/D_005B, then
; writes MAPX<zone><type> (1000h), MONX<zone><type> (100h, monster table) and
; PLAYER (100h, player record from D_0036). The letter is a fixed 'X' here.
; Called before entering a location, before a time door and by Q)uit.
; In: D_0049, D_004A, D_0000/D_0001. Uses: AX, CX, DX.
;------------------------------------------------------------------------------
L22FD:	mov al, byte ptr D_006D	; planet: 0 = Earth	;@22FD
	or al, al	;@2300
	je L2305	;@2302
	ret	;@2304
L2305:	clc	;@2305
	mov al, byte ptr D_0049	;@2306
	adc al, 30h	;@2309
	mov byte ptr cs:L233C, al	; patch the zone digits (self-modifying)	;@230B
	mov byte ptr cs:L234E, al	;@230F
	mov al, byte ptr D_004A	;@2313
	adc al, 30h	;@2316
	mov byte ptr cs:L233D, al	; patch the type digits	;@2318
	mov byte ptr cs:L234F, al	;@231C
	mov al, byte ptr D_0000	; position -> surface position	;@2320
	mov byte ptr D_005A, al	;@2323
	mov al, byte ptr D_0001	;@2326
	mov byte ptr D_005B, al	;@2329
	mov ah, 28h	; FCB random block write	;@232C
	mov cx, 1000h	;@232E
	mov dx, word ptr D_0472	; map buffer	;@2331
	call L52CA	;@2335
	db 4Dh,41h,50h,58h	; "MAPX"	;@2338
L233C label byte
	db 46h	; zone digit (patched)	;@233C
L233D label byte
	db 46h,20h,20h	; type digit (patched), 2 spaces	;@233D
	mov cx, 100h	; AH is still 28h	;@2340
	lea dx, D_0137	; monster table	;@2343
	call L52CA	;@2347
	db 4Dh,4Fh,4Eh,58h	; "MONX"	;@234A
L234E label byte
	db 46h	; zone digit (patched)	;@234E
L234F label byte
	db 46h,20h,20h	; type digit (patched), 2 spaces	;@234F
	lea dx, D_0036	; player record; AH = 28h, CX = 100h still	;@2352
	call L52CA	;@2356
	db 50h,4Ch,41h,59h,45h,52h,20h,20h	; "PLAYER  "	;@2359
	ret	;@2361
CODE ENDS
END
