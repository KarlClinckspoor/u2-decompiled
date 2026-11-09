; START.ASM: startup, title screen and demonstration, delay loops.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 0100-0730.
;
; The program entry (L0100) and everything before the game proper:
;   L0100  startup: segments, stack, random seed from the BIOS tick count, delay table
;   L013E  title sequence (text mode): "ORIGIN PROUDLY PRESENTS", "PART ][ ...", then the
;          dragon picture PICDRA in CGA mode; Escape at any wait goes to the menu
;   L0242  main menu: D = demonstration, P = play (L0764 in MAIN), C = create a character
;          (L5400 in CHARGEN)
;   L03AF  demonstration: five CGA pictures (PICOUT, PICTWN, PICDNG, PICSPA, PICMIN) with two
;          caption lines each, then back to the title; once seen it repeats until Escape
;   L0688/L068F  title waits that Escape interrupts
;   L06AC/L06ED/L0711  the speed-scaled delay loops used all over the game
; Data used: the cursor D_002E (column) / D_002F (row), the random seed D_023F-D_0244, the
; speed setting D_0074 (part of the PLAYER record) and the delay tables D_0554, D_0558, D_0580,
; D_0239 (demonstration seen). Text strings are inline after `call L4FDF` (PrintInline), file
; names inline after `call L52CA` (LoadFile; AH=27h read, CX bytes, DX offset, PIC files go to
; the CGA memory B800:DX).
; Dead code left by the 1989 patch: 04A9 (a "PICCAS" scene, jumped over) and 06B3 (the tail
; of the old speed calibration).
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_002E:BYTE, D_002F:BYTE, D_0074:BYTE, D_0239:BYTE, D_023F:BYTE, D_0240:BYTE
	EXTRN D_0241:BYTE, D_0242:BYTE, D_0243:BYTE, D_0244:BYTE, D_0554:BYTE, D_0558:BYTE
	EXTRN D_0580:BYTE, STACK_PARA:ABS
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L0764:NEAR, L4A1C:NEAR, L4A3E:NEAR, L4B4E:NEAR, L4F4D:NEAR, L4FDF:NEAR
	EXTRN L5003:NEAR, L51EB:NEAR, L52CA:NEAR, L538F:NEAR, L5400:NEAR
	PUBLIC L0100, L06AC, L06ED, L0711
ASSUME CS:CODE, DS:DATA
ORG 100h

;------------------------------------------------------------------------------
; L0100: program entry (also called by CHARGEN at 5A61 to restart after a new
; character was made). Sets DS = DATA, SS = DATA+STACK_PARA (just above the
; data, BSS and buffers), SP = 100h; seeds the 6-byte random seed
; D_023F-D_0244 from the low byte of the BIOS tick count; clears the text
; screen; resets the speed setting and the delay table; falls into the title.
; Out: does not return.
;------------------------------------------------------------------------------
L0100:	mov ax, DATA	;@0100
	mov ds, ax	;@0103
	add ax, STACK_PARA	;@0105
	mov ss, ax	;@0108
	mov sp, 100h	;@010A
	mov ax, 40h	; BIOS data segment	;@010D
	mov es, ax	;@0110
	mov al, byte ptr es:[6Ch]	; timer tick count, low byte	;@0112
	mov byte ptr D_023F, al	;@0116
	mov byte ptr D_0240, al	;@0119
	mov byte ptr D_0241, al	;@011C
	mov byte ptr D_0242, al	;@011F
	mov byte ptr D_0243, al	;@0122
	mov byte ptr D_0244, al	;@0125
	inc byte ptr D_023F	; make the first two bytes differ	;@0128
	inc byte ptr D_0240	;@012C
	call L4A1C	; 40-column text mode, clear	;@0130
	mov al, 0	;@0133
	mov byte ptr D_0239, al	; demonstration not seen yet	;@0135
	call L06AC	; speed setting D_0074 = 0FFh	;@0138
	call L06ED	; delay table from it	;@013B

;------------------------------------------------------------------------------
; L013E: the title sequence; the demonstration jumps back here when it ends.
; Two text screens, each held by L0688 (Escape goes to the menu L0242), then
; the dragon picture PICDRA in CGA mode 4. Afterwards the menu, or straight
; into the demonstration again once it has been seen (D_0239 <> 0).
; Cursor: L51EB takes DI = column, SI = row.
;------------------------------------------------------------------------------
L013E:	nop	;@013E
	call L4A1C	;@013F
	mov di, 10h	;@0142
	mov si, 0Ah	;@0145
	call L51EB	; cursor to column 16, row 10	;@0148
	call L4FDF	;@014B
	db 4Fh,52h,49h,47h,49h,4Eh,0h	; "ORIGIN"	;@014E
	mov di, 0Bh	;@0155
	mov si, 0Ch	;@0158
	call L51EB	;@015B
	call L4FDF	;@015E
	db 50h,52h,4Fh,55h,44h,4Ch,59h,20h,50h,52h,45h,53h,45h,4Eh,54h,53h	; "PROUDLY PRESENTS"	;@0161
	db 0h	;@0171
	call L0688	; wait (Escape: menu)	;@0172
	call L4F4D	; one more key check	;@0175
	cmp ax, 0FF1Bh	; Escape?	;@0178
	jne L0180	;@017B
	jmp L0242	;@017D
L0180:	nop	;@0180
	call L4A1C	;@0181
	mov di, 10h	;@0184
	mov si, 8	;@0187
	call L51EB	;@018A
	call L4FDF	;@018D
	db 50h,41h,52h,54h,20h,5Dh,5Bh,0h	; "PART ][" (Apple II spelling of II)	;@0190
	mov di, 9	;@0198
	mov si, 0Ah	;@019B
	call L51EB	;@019E
	call L4FDF	;@01A1
	db 4Fh,46h,20h,54h,48h,45h,20h,23h,31h,20h,42h,45h,53h,54h,20h,53h	; "OF THE #1 BEST SELLING"	;@01A4
	db 45h,4Ch,4Ch,49h,4Eh,47h,0h	;@01B4
	mov di, 7	;@01BB
	mov si, 0Ch	;@01BE
	call L51EB	;@01C1
	call L4FDF	;@01C4
	db 46h,41h,4Eh,54h,41h,53h,59h,20h,52h,4Fh,4Ch,45h,2Dh,50h,4Ch,41h	; "FANTASY ROLE-PLAYING GAME"	;@01C7
	db 59h,49h,4Eh,47h,20h,47h,41h,4Dh,45h,0h	;@01D7
	mov di, 0Ch	;@01E1
	mov si, 0Eh	;@01E4
	call L51EB	;@01E7
	call L4FDF	;@01EA
	db 42h,59h,20h,4Ch,4Fh,52h,44h,20h,42h,52h,49h,54h,49h,53h,48h,0h	; "BY LORD BRITISH"	;@01ED
	call L0688	;@01FD
	call L4F4D	;@0200
	cmp ax, 0FF1Bh	;@0203
	jne L020B	;@0206
	jmp L0242	;@0208
;
; The dragon: CGA mode 4, the 16 KB picture PICDRA read straight into B800:0000.
;
L020B:	nop	;@020B
	call L4A3E	; CGA 320x200 mode 4	;@020C
	mov ah, 27h	; read	;@020F
	mov cx, 4000h	; 16 KB	;@0211
	mov dx, 0	; to B800:0000 (PIC files go to video memory)	;@0214
	call L52CA	;@0217
	db 50h,49h,43h,44h,52h,41h,20h,20h	; "PICDRA  "	;@021A
	call L0688	;@0222
;
; Hold the picture a bit longer: 5 x (busy loop of 2C00h + delay table entry 4).
; Escape is not checked here.
;
	mov si, 5	;@0225
L0228:	mov di, 2C00h	; CPU-speed dependent	;@0228
L022B:	dec di	;@022B
	jne L022B	;@022C
	mov bx, 8	; delay table entry 4 (byte offset 8)	;@022E
	call L0711	;@0231
	dec si	;@0234
	jne L0228	;@0235
	nop	;@0237
	cmp byte ptr D_0239, 0	; demonstration seen?	;@0238
	je L0242	; no: menu	;@023D
	jmp L03AF	; yes: run it again	;@023F

;------------------------------------------------------------------------------
; L0242: the main menu (text mode). Reached from the title (Escape or end) and
; from any title/demonstration wait interrupted by Escape. Prints the title
; and the choices, then waits for D, P or C (anything else redraws the menu):
;   D -> L03AF demonstration, P -> L0764 play (MAIN), C -> L5400 create a
;   character (CHARGEN; it ends with call L0100, a restart, so the play that
;   follows here is not reached that way).
; Note: SP is not reset here; the Escape path through L0696 leaves one return
; address on the stack each time (harmless until it happens ~120 times).
;------------------------------------------------------------------------------
L0242:	nop	;@0242
	call L4A1C	;@0243
	mov byte ptr D_002F, 1	; row	;@0246
	mov al, 0Fh	;@024B
	mov byte ptr D_002E, al	; column	;@024D
	call L4FDF	;@0250
	db 55h,4Ch,54h,49h,4Dh,41h,20h,5Dh,5Bh,0h	; "ULTIMA ]["	;@0253
	mov byte ptr D_002F, 3	;@025D
	mov al, 10h	;@0262
	mov byte ptr D_002E, al	;@0264
	call L4FDF	;@0267
	db 52h,45h,56h,45h,4Eh,47h,45h,0h	; "REVENGE"	;@026A
	mov byte ptr D_002F, 5	;@0272
	mov al, 10h	;@0277
	mov byte ptr D_002E, al	;@0279
	call L4FDF	;@027C
	db 4Fh,46h,20h,20h,54h,48h,45h,0h	; "OF  THE"	;@027F
	mov byte ptr D_002F, 7	;@0287
	mov al, 0Eh	;@028C
	mov byte ptr D_002E, al	;@028E
	call L4FDF	;@0291
	db 45h,4Eh,43h,48h,41h,4Eh,54h,52h,45h,53h,53h,0h	; "ENCHANTRESS"	;@0294
	mov al, 16h	;@02A0
	mov byte ptr D_002F, al	;@02A2
	mov al, 6	;@02A5
	mov byte ptr D_002E, al	;@02A7
	call L4FDF	;@02AA
; "(C)-1983,1989 BY LORD BRITISH"
	db 28h,43h,29h,2Dh,31h,39h,38h,33h,2Ch,31h,39h,38h,39h,20h,42h,59h	;@02AD
	db 20h,4Ch,4Fh,52h,44h,20h,42h,52h,49h,54h,49h,53h,48h,0h	;@02BD
	mov byte ptr D_002F, 17h	;@02CB
	mov al, 0Fh	;@02D0
	mov byte ptr D_002E, al	;@02D2
	call L4FDF	;@02D5
	db 41h,4Eh,44h,20h,4Fh,52h,49h,47h,49h,4Eh,0h	; "AND ORIGIN"	;@02D8
	mov al, 0Bh	;@02E3
	mov byte ptr D_002F, al	;@02E5
	mov al, 5	;@02E8
	mov byte ptr D_002E, al	;@02EA
	call L4FDF	;@02ED
	db 54h,59h,50h,45h,20h,2Dh,0h	; "TYPE -"	;@02F0
	mov byte ptr D_002F, 0Dh	;@02F7
	mov al, 6	;@02FC
	mov byte ptr D_002E, al	;@02FE
	call L4FDF	;@0301
	db 27h,44h,27h,20h,2Dh,20h,46h,4Fh,52h,20h,41h,20h,44h,45h,4Dh,4Fh	; "'D' - FOR A DEMONSTRATION"	;@0304
	db 4Eh,53h,54h,52h,41h,54h,49h,4Fh,4Eh,0h	;@0314
	mov byte ptr D_002F, 0Fh	;@031E
	mov al, 6	;@0323
	mov byte ptr D_002E, al	;@0325
	call L4FDF	;@0328
; "'P' - PLAY A GAME OF ULTIMA ]["
	db 27h,50h,27h,20h,2Dh,20h,50h,4Ch,41h,59h,20h,41h,20h,47h,41h,4Dh	;@032B
	db 45h,20h,4Fh,46h,20h,55h,4Ch,54h,49h,4Dh,41h,20h,5Dh,5Bh,0h	;@033B
	mov byte ptr D_002F, 11h	;@034A
	mov al, 6	;@034F
	mov byte ptr D_002E, al	;@0351
	call L4FDF	;@0354
; "'C' - CREATE A NEW CHARACTER"
	db 27h,43h,27h,20h,2Dh,20h,43h,52h,45h,41h,54h,45h,20h,41h,20h,4Eh	;@0357
	db 45h,57h,20h,43h,48h,41h,52h,41h,43h,54h,45h,52h,0h	;@0367
	mov byte ptr D_002F, 13h	;@0374
	mov al, 5	;@0379
	mov byte ptr D_002E, al	;@037B
	call L4FDF	;@037E
	db 43h,48h,4Fh,49h,43h,45h,3Ah,0h	; "CHOICE:"	;@0381
	mov di, 30h	; not used afterwards (left-over)	;@0389
L038C:	call L4F4D	; wait for a key: AH = FFh when one was read	;@038C
	cmp ah, 0FFh	;@038F
	jne L038C	;@0392
	call L5003	; echo it (AL is upper case)	;@0394
	cmp al, 44h	; 'D'	;@0397
	jne L039E	;@0399
	jmp L03AF	;@039B
L039E:	cmp al, 50h	; 'P'	;@039E
	je L03AC	;@03A0
	cmp al, 43h	; 'C'	;@03A2
	je L03A9	;@03A4
	jmp L0242	;@03A6
L03A9:	call L5400	; create a character (normally ends by restarting at L0100)	;@03A9
L03AC:	call L0764	; play; never returns (the main loop resets SP)	;@03AC

;------------------------------------------------------------------------------
; L03AF: the demonstration. Five CGA pictures, each read into B800:0000 and
; captioned on text rows 23 and 24, each held by L068F (Escape: menu L0242),
; then the captions (L538F) and the picture (L4B4E) are cleared. Sets D_0239,
; so the title sequence comes back here by itself. Ends with jmp L013E.
;------------------------------------------------------------------------------
L03AF:	nop	;@03AF
	call L4A3E	; CGA mode 4 (clears the screen)	;@03B0
	mov al, 1	;@03B3
	mov byte ptr D_0239, al	; demonstration seen: repeat it after the title	;@03B5
	mov ah, 27h	;@03B8
	mov cx, 4000h	;@03BA
	mov dx, 0	;@03BD
	call L52CA	;@03C0
	db 50h,49h,43h,4Fh,55h,54h,20h,20h	; "PICOUT  " (outdoors)	;@03C3
	mov byte ptr D_002F, 17h	;@03CB
	mov byte ptr D_002E, 0	;@03D0
	call L4FDF	;@03D5
	db 20h,20h,20h,20h,20h,20h,20h,20h,42h,41h,54h,54h,4Ch,45h,20h,53h	; "BATTLE STRANGE CREATURES"	;@03D8
	db 54h,52h,41h,4Eh,47h,45h,20h,43h,52h,45h,41h,54h,55h,52h,45h,53h	;@03E8
	db 0h	;@03F8
	mov byte ptr D_002E, 0	;@03F9
	mov byte ptr D_002F, 18h	;@03FE
	call L4FDF	;@0403
; "ACROSS THE FACE OF THE EARTH"
	db 20h,20h,20h,20h,20h,20h,41h,43h,52h,4Fh,53h,53h,20h,54h,48h,45h	;@0406
	db 20h,46h,41h,43h,45h,20h,4Fh,46h,20h,54h,48h,45h,20h,45h,41h,52h	;@0416
	db 54h,48h,0h	;@0426
	call L068F	;@0429
	call L538F	; clear text rows 23-24	;@042C
	call L4B4E	; clear both CGA banks	;@042F
	mov ah, 27h	;@0432
	mov cx, 4000h	;@0434
	mov dx, 0	;@0437
	call L52CA	;@043A
	db 50h,49h,43h,54h,57h,4Eh,20h,20h	; "PICTWN  " (town)	;@043D
	mov byte ptr D_002E, 0	;@0445
	mov byte ptr D_002F, 17h	;@044A
	call L4FDF	;@044F
; "SEARCH FOR CLUES IN CARELESS WORDS"
	db 20h,20h,20h,53h,45h,41h,52h,43h,48h,20h,46h,4Fh,52h,20h,43h,4Ch	;@0452
	db 55h,45h,53h,20h,49h,4Eh,20h,43h,41h,52h,45h,4Ch,45h,53h,53h,20h	;@0462
	db 57h,4Fh,52h,44h,53h,0h	;@0472
	mov byte ptr D_002E, 2	;@0478
	mov byte ptr D_002F, 18h	;@047D
	call L4FDF	;@0482
	db 20h,20h,20h,20h,20h,20h,53h,50h,4Fh,4Bh,45h,4Eh,20h,41h,54h,20h	; "SPOKEN AT THE LOCAL PUB"	;@0485
	db 54h,48h,45h,20h,4Ch,4Fh,43h,41h,4Ch,20h,50h,55h,42h,0h	;@0495
	call L068F	;@04A3
	jmp L0519	; skip the dead PICCAS scene	;@04A6
;
; Dead code (nothing jumps here): the castle scene of the 1983 version, cut by
; the jmp above; the release has no PICCAS file. Decoded: call L538F; call
; L4B4E; load "PICCAS  "; captions "PLEAD WITH MEDIEVAL KINGS" / "FOR
; ASSISTANCE"; call L068F.
;
	db 0E8h,0E3h,4Eh,0E8h,9Fh,46h,0B4h,27h,0B9h,0h,40h,0BAh,0h,0h,0E8h,10h	;@04A9
	db 4Eh,50h,49h,43h,43h,41h,53h,20h,20h,0C6h,6h,2Eh,0h,0h,0C6h,6h	;@04B9
	db 2Fh,0h,17h,0E8h,10h,4Bh,20h,20h,20h,20h,20h,20h,20h,20h,50h,4Ch	;@04C9
	db 45h,41h,44h,20h,57h,49h,54h,48h,20h,4Dh,45h,44h,49h,45h,56h,41h	;@04D9
	db 4Ch,20h,4Bh,49h,4Eh,47h,53h,0h,0C6h,6h,2Eh,0h,4h,0C6h,6h,2Fh	;@04E9
	db 0h,18h,0E8h,0E1h,4Ah,20h,20h,20h,20h,20h,20h,20h,20h,20h,46h,4Fh	;@04F9
	db 52h,20h,41h,53h,53h,49h,53h,54h,41h,4Eh,43h,45h,0h,0E8h,76h,1h	;@0509
L0519:	call L538F	;@0519
	call L4B4E	;@051C
	mov ah, 27h	;@051F
	mov cx, 4000h	;@0521
	mov dx, 0	;@0524
	call L52CA	;@0527
	db 50h,49h,43h,44h,4Eh,47h,20h,20h	; "PICDNG  " (dungeon)	;@052A
	mov byte ptr D_002E, 0	;@0532
	mov byte ptr D_002F, 17h	;@0537
	call L4FDF	;@053C
; "TRAVERSE DEEP DARK DEADLY DUNGEONS"
	db 20h,20h,20h,54h,52h,41h,56h,45h,52h,53h,45h,20h,44h,45h,45h,50h	;@053F
	db 20h,44h,41h,52h,4Bh,20h,44h,45h,41h,44h,4Ch,59h,20h,44h,55h,4Eh	;@054F
	db 47h,45h,4Fh,4Eh,53h,0h	;@055F
	mov byte ptr D_002E, 1	;@0565
	mov byte ptr D_002F, 18h	;@056A
	call L4FDF	;@056F
	db 20h,20h,20h,20h,20h,20h,41h,4Eh,44h,20h,54h,41h,4Ch,4Ch,20h,54h	; "AND TALL TERRIFYING TOWERS"	;@0572
	db 45h,52h,52h,49h,46h,59h,49h,4Eh,47h,20h,54h,4Fh,57h,45h,52h,53h	;@0582
	db 0h	;@0592
	call L068F	;@0593
	call L538F	;@0596
	call L4B4E	;@0599
	mov ah, 27h	;@059C
	mov cx, 4000h	;@059E
	mov dx, 0	;@05A1
	call L52CA	;@05A4
	db 50h,49h,43h,53h,50h,41h,20h,20h	; "PICSPA  " (space)	;@05A7
	mov byte ptr D_002E, 0	;@05AF
	mov byte ptr D_002F, 17h	;@05B4
	call L4FDF	;@05B9
; "TRAVEL THROUGHOUT THE GALAXY"
	db 20h,20h,20h,20h,20h,20h,54h,52h,41h,56h,45h,4Ch,20h,54h,48h,52h	;@05BC
	db 4Fh,55h,47h,48h,4Fh,55h,54h,20h,54h,48h,45h,20h,47h,41h,4Ch,41h	;@05CC
	db 58h,59h,0h	;@05DC
	mov byte ptr D_002E, 1	;@05DF
	mov byte ptr D_002F, 18h	;@05E4
	call L4FDF	;@05E9
; "TO THE PLANETS OF OUR SOLAR SYSTEM"
	db 20h,20h,54h,4Fh,20h,54h,48h,45h,20h,50h,4Ch,41h,4Eh,45h,54h,53h	;@05EC
	db 20h,4Fh,46h,20h,4Fh,55h,52h,20h,53h,4Fh,4Ch,41h,52h,20h,53h,59h	;@05FC
	db 53h,54h,45h,4Dh,0h	;@060C
	call L068F	;@0611
	call L538F	;@0614
	call L4B4E	;@0617
	mov ah, 27h	;@061A
	mov cx, 4000h	;@061C
	mov dx, 0	;@061F
	call L52CA	;@0622
	db 50h,49h,43h,4Dh,49h,4Eh,20h,20h	; "PICMIN  " (Minax)	;@0625
	mov byte ptr D_002E, 0	;@062D
	mov byte ptr D_002F, 17h	;@0632
	call L4FDF	;@0637
; "AND CONQUER TIME ITSELF TO BATTLE"
	db 20h,20h,20h,41h,4Eh,44h,20h,43h,4Fh,4Eh,51h,55h,45h,52h,20h,54h	;@063A
	db 49h,4Dh,45h,20h,49h,54h,53h,45h,4Ch,46h,20h,54h,4Fh,20h,42h,41h	;@064A
	db 54h,54h,4Ch,45h,0h	;@065A
	mov byte ptr D_002E, 8	;@065F
	mov byte ptr D_002F, 18h	;@0664
	call L4FDF	;@0669
	db 4Dh,49h,4Eh,41h,58h,20h,54h,48h,45h,20h,45h,4Eh,43h,48h,41h,4Eh	; "MINAX THE ENCHANTRESS"	;@066C
	db 54h,52h,45h,53h,53h,0h	;@067C
	call L068F	;@0682
	jmp L013E	; and round again	;@0685

;------------------------------------------------------------------------------
; L0688: title wait: up to 6000h key polls (see L0696). Escape does not return
; here but jumps to the menu L0242.
; In: none. Out: DX = 0. Uses: AX, BX, DX.
;------------------------------------------------------------------------------
L0688:	mov dx, 6000h	;@0688
	call L0696	;@068B
	ret	;@068E

;------------------------------------------------------------------------------
; L068F: demonstration wait: like L0688 with A000h key polls.
;------------------------------------------------------------------------------
L068F:	mov dx, 0A000h	;@068F
	call L0696	;@0692
	ret	;@0695

;------------------------------------------------------------------------------
; L0696: wait loop of L0688/L068F: DX times (delay table entry 5, then read a
; key). Other keys are read and ignored. On Escape it drops its own return
; address and jumps to the menu L0242, so the return address of the caller of
; L0688/L068F stays on the stack. With the 1989 speed setting the delay is 0,
; so the length of the wait depends on the CPU speed.
; In: DX = number of polls. Out: DX = 0. Uses: AX, BX, DX.
;------------------------------------------------------------------------------
L0696:	mov bx, 0Ah	; delay table entry 5 (byte offset 0Ah)	;@0696
	call L0711	;@0699
	call L4F4D	;@069C
	cmp ax, 0FF1Bh	; Escape?	;@069F
	jne L06A8	;@06A2
	pop ax	; drop the return address into L0688/L068F	;@06A4
	jmp L0242	;@06A5
L06A8:	dec dx	;@06A8
	jne L0696	;@06A9
	ret	;@06AB

;------------------------------------------------------------------------------
; L06AC: set the speed setting D_0074 to 0FFh. The 1989 patch put this over
; the old speed calibration (whose tail follows as dead bytes). 0FFh is below
; the base value D_0554 (068Ah), so L06ED makes every delay 0 (fastest);
; Ctrl-Left / Ctrl-Right (TEXTIO 4F89) change D_0074 in steps of 200h.
; Also called by MAIN at game start when the PLAYER file has D_0074 = 0.
; Probable bug (TEXTIO 4F8E, by reading, not tested): Ctrl-Right subtracts
; 200h and keeps the result unless it is below D_0554, so from 00FFh it stores
; 0FEFFh; L06ED then overflows its div (divide error, the program ends).
; In: none. Out: D_0074 = 00FFh. Uses: nothing else.
;------------------------------------------------------------------------------
L06AC:	mov word ptr D_0074, 0FFh	;@06AC
	ret	;@06B2
;
; Dead bytes: the tail of the 1983 calibration that L06AC replaced. Decoded
; (06B4-06EC): save the BIOS tick count in D_0550/D_0552, D_0074 = 0, wait for
; the next tick (int 1Ah; restart at 06AC at midnight), then count loops of
; 100 x `dec ax` in D_0074 until 20 ticks (about 1.1 s) have passed. So
; D_0074 was the CPU speed: delay loops ran per 20 ticks.
;
	db 5h,89h,16h,50h,5h,0C7h,6h,74h,0h,0h,0h,0B4h,0h,0CDh,1Ah,3Ch	;@06B3
	db 0h,75h,0E6h,3Bh,16h,50h,5h,74h,0F2h,0B4h,0h,0CDh,1Ah,3Ch,0h,75h	;@06C3
	db 0D8h,0B8h,64h,0h,48h,75h,0FDh,83h,6h,74h,0h,1h,2Bh,16h,50h,5h	;@06D3
	db 2Bh,0Eh,52h,5h,83h,0FAh,14h,72h,0E0h,0C3h	;@06E3

;------------------------------------------------------------------------------
; L06ED: compute the delay table from the speed setting: for each of the 20
; entries (byte offsets 26h down to 0)
;   D_0580[bx] = (D_0074 - D_0554) * D_0558[bx] / D_0554, or 0 when
;   D_0074 < D_0554
; i.e. the delays grow with how much faster than the base machine the CPU is.
; The upper limit 3A00h kept by the Ctrl-Left key is about the largest value for
; which the biggest factor (2000h) does not overflow the div.
; Also called by the key reader L4F4D (at 4FB3) after a speed key.
; In: D_0074. Out: D_0580 filled. Uses: AX, BX, DX (DX is clobbered by mul/div,
; also for the callers of L4F4D).
;------------------------------------------------------------------------------
L06ED:	mov bx, 26h	; last entry (20 words)	;@06ED
L06F0:	mov ax, word ptr D_0074	;@06F0
	sub ax, word ptr D_0554	;@06F3
	jae L06FF	;@06F7
	mov ax, 0	; slower than the base: no delay	;@06F9
	jmp L0707	;@06FC
L06FF:	mul word ptr D_0558[bx]	;@06FF
	div word ptr D_0554	;@0703
L0707:	mov word ptr D_0580[bx], ax	;@0707
	sub bx, 2	;@070B
	jae L06F0	;@070E
	ret	;@0710

;------------------------------------------------------------------------------
; L0711: delay. Runs D_0580[bx] times a 12-iteration busy loop (none when the
; entry is 0, or 8000h and above).
; In: BX = byte offset of the delay table entry (2 * entry number).
; Out: nothing. Uses: AX, BX.
; Entries used here and in MAIN: 0 (command prompt key poll), 4 (title
; dragon), 5 (title/demonstration waits); other modules use others (CMDAL's
; launch: byte offset 1Ch = entry 0Eh).
;------------------------------------------------------------------------------
L0711:	mov bx, word ptr D_0580[bx]	;@0711
L0715:	dec bx	;@0715
	js L0720	;@0716
	mov ax, 0Ch	;@0718
L071B:	dec ax	;@071B
	jne L071B	;@071C
	jmp L0715	;@071E
L0720:	ret	;@0720
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h	; zeros up to the jump table at 0730 (padding?)	;@0721
CODE ENDS
END L0100
