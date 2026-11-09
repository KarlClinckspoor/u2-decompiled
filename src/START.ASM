; START.ASM: startup, title screen and demonstration, delay loops.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 0100-0730.
;
; The program entry (ProgramEntry) and everything before the game proper:
;   ProgramEntry  startup: segments, stack, random seed from the BIOS tick count, delay table
;   TitleScreen  title sequence (text mode): "ORIGIN PROUDLY PRESENTS", "PART ][ ...", then the
;          dragon picture PICDRA in CGA mode; Escape at any wait goes to the menu
;   MainMenu  main menu: D = demonstration, P = play (GameStart in MAIN), C = create a character
;          (CreateCharacter in CHARGEN)
;   DemoShow  demonstration: five CGA pictures (PICOUT, PICTWN, PICDNG, PICSPA, PICMIN) with two
;          caption lines each, then back to the title; once seen it repeats until Escape
;   TitleWait/DemoWait  title waits that Escape interrupts
;   SetDefaultSpeed/CalcDelayTbl/SpeedDelay  the speed-scaled delay loops used all over the game
; Data used: the cursor CursorCol (column) / CursorRow (row), the random seed RandSeed-RandSeed5, the
; speed setting SpeedSetting (part of the PLAYER record) and the delay tables SpeedMin, DelayFactorTbl, DelayTbl,
; DemoSeen (demonstration seen). Text strings are inline after `call PrintInline` (PrintInline), file
; names inline after `call ReadWriteFile` (LoadFile; AH=27h read, CX bytes, DX offset, PIC files go to
; the CGA memory B800:DX).
; Dead code left by the 1989 patch: 04A9 (a "PICCAS" scene, jumped over) and 06B3 (the tail
; of the old speed calibration).
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN CursorCol:BYTE, CursorRow:BYTE, SpeedSetting:BYTE, DemoSeen:BYTE, RandSeed:BYTE, RandSeed1:BYTE
	EXTRN RandSeed2:BYTE, RandSeed3:BYTE, RandSeed4:BYTE, RandSeed5:BYTE, SpeedMin:BYTE, DelayFactorTbl:BYTE
	EXTRN DelayTbl:BYTE, STACK_PARA:ABS
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN GameStart:NEAR, SetTextMode:NEAR, SetGraphicsMode:NEAR, ClearViewArea:NEAR, ReadKey:NEAR, PrintInline:NEAR
	EXTRN PrintChar:NEAR, SetCursor:NEAR, ReadWriteFile:NEAR, ClearBottomLines:NEAR, CreateCharacter:NEAR
	PUBLIC ProgramEntry, SetDefaultSpeed, CalcDelayTbl, SpeedDelay
ASSUME CS:CODE, DS:DATA
ORG 100h

;------------------------------------------------------------------------------
; ProgramEntry: program entry (also called by CHARGEN at 5A61 to restart after a new
; character was made). Sets DS = DATA, SS = DATA+STACK_PARA (just above the
; data, BSS and buffers), SP = 100h; seeds the 6-byte random seed
; RandSeed-RandSeed5 from the low byte of the BIOS tick count; clears the text
; screen; resets the speed setting and the delay table; falls into the title.
; Out: does not return.
;------------------------------------------------------------------------------
ProgramEntry:	mov ax, DATA	;@0100
	mov ds, ax	;@0103
	add ax, STACK_PARA	;@0105
	mov ss, ax	;@0108
	mov sp, 100h	;@010A
	mov ax, 40h	; BIOS data segment	;@010D
	mov es, ax	;@0110
	mov al, byte ptr es:[6Ch]	; timer tick count, low byte	;@0112
	mov byte ptr RandSeed, al	;@0116
	mov byte ptr RandSeed1, al	;@0119
	mov byte ptr RandSeed2, al	;@011C
	mov byte ptr RandSeed3, al	;@011F
	mov byte ptr RandSeed4, al	;@0122
	mov byte ptr RandSeed5, al	;@0125
	inc byte ptr RandSeed	; make the first two bytes differ	;@0128
	inc byte ptr RandSeed1	;@012C
	call SetTextMode	; 40-column text mode, clear	;@0130
	mov al, 0	;@0133
	mov byte ptr DemoSeen, al	; demonstration not seen yet	;@0135
	call SetDefaultSpeed	; speed setting SpeedSetting = 0FFh	;@0138
	call CalcDelayTbl	; delay table from it	;@013B

;------------------------------------------------------------------------------
; TitleScreen: the title sequence; the demonstration jumps back here when it ends.
; Two text screens, each held by TitleWait (Escape goes to the menu MainMenu), then
; the dragon picture PICDRA in CGA mode 4. Afterwards the menu, or straight
; into the demonstration again once it has been seen (DemoSeen <> 0).
; Cursor: SetCursor takes DI = column, SI = row.
;------------------------------------------------------------------------------
TitleScreen:	nop	;@013E
	call SetTextMode	;@013F
	mov di, 10h	;@0142
	mov si, 0Ah	;@0145
	call SetCursor	; cursor to column 16, row 10	;@0148
	call PrintInline	;@014B
	db 4Fh,52h,49h,47h,49h,4Eh,0h	; "ORIGIN"	;@014E
	mov di, 0Bh	;@0155
	mov si, 0Ch	;@0158
	call SetCursor	;@015B
	call PrintInline	;@015E
	db 50h,52h,4Fh,55h,44h,4Ch,59h,20h,50h,52h,45h,53h,45h,4Eh,54h,53h	; "PROUDLY PRESENTS"	;@0161
	db 0h	;@0171
	call TitleWait	; wait (Escape: menu)	;@0172
	call ReadKey	; one more key check	;@0175
	cmp ax, 0FF1Bh	; Escape?	;@0178
	jne Title_Part2	;@017B
	jmp MainMenu	;@017D
Title_Part2:	nop	;@0180
	call SetTextMode	;@0181
	mov di, 10h	;@0184
	mov si, 8	;@0187
	call SetCursor	;@018A
	call PrintInline	;@018D
	db 50h,41h,52h,54h,20h,5Dh,5Bh,0h	; "PART ][" (Apple II spelling of II)	;@0190
	mov di, 9	;@0198
	mov si, 0Ah	;@019B
	call SetCursor	;@019E
	call PrintInline	;@01A1
	db 4Fh,46h,20h,54h,48h,45h,20h,23h,31h,20h,42h,45h,53h,54h,20h,53h	; "OF THE #1 BEST SELLING"	;@01A4
	db 45h,4Ch,4Ch,49h,4Eh,47h,0h	;@01B4
	mov di, 7	;@01BB
	mov si, 0Ch	;@01BE
	call SetCursor	;@01C1
	call PrintInline	;@01C4
	db 46h,41h,4Eh,54h,41h,53h,59h,20h,52h,4Fh,4Ch,45h,2Dh,50h,4Ch,41h	; "FANTASY ROLE-PLAYING GAME"	;@01C7
	db 59h,49h,4Eh,47h,20h,47h,41h,4Dh,45h,0h	;@01D7
	mov di, 0Ch	;@01E1
	mov si, 0Eh	;@01E4
	call SetCursor	;@01E7
	call PrintInline	;@01EA
	db 42h,59h,20h,4Ch,4Fh,52h,44h,20h,42h,52h,49h,54h,49h,53h,48h,0h	; "BY LORD BRITISH"	;@01ED
	call TitleWait	;@01FD
	call ReadKey	;@0200
	cmp ax, 0FF1Bh	;@0203
	jne Title_Dragon	;@0206
	jmp MainMenu	;@0208
;
; The dragon: CGA mode 4, the 16 KB picture PICDRA read straight into B800:0000.
;
Title_Dragon:	nop	;@020B
	call SetGraphicsMode	; CGA 320x200 mode 4	;@020C
	mov ah, 27h	; read	;@020F
	mov cx, 4000h	; 16 KB	;@0211
	mov dx, 0	; to B800:0000 (PIC files go to video memory)	;@0214
	call ReadWriteFile	;@0217
	db 50h,49h,43h,44h,52h,41h,20h,20h	; "PICDRA  "	;@021A
	call TitleWait	;@0222
;
; Hold the picture a bit longer: 5 x (busy loop of 2C00h + delay table entry 4).
; Escape is not checked here.
;
	mov si, 5	;@0225
Title_DragonHold:	mov di, 2C00h	; CPU-speed dependent	;@0228
Title_DragonBusy:	dec di	;@022B
	jne Title_DragonBusy	;@022C
	mov bx, 8	; delay table entry 4 (byte offset 8)	;@022E
	call SpeedDelay	;@0231
	dec si	;@0234
	jne Title_DragonHold	;@0235
	nop	;@0237
	cmp byte ptr DemoSeen, 0	; demonstration seen?	;@0238
	je MainMenu	; no: menu	;@023D
	jmp DemoShow	; yes: run it again	;@023F

;------------------------------------------------------------------------------
; MainMenu: the main menu (text mode). Reached from the title (Escape or end) and
; from any title/demonstration wait interrupted by Escape. Prints the title
; and the choices, then waits for D, P or C (anything else redraws the menu):
;   D -> DemoShow demonstration, P -> GameStart play (MAIN), C -> CreateCharacter create a
;   character (CHARGEN; it ends with call ProgramEntry, a restart, so the play that
;   follows here is not reached that way).
; Note: SP is not reset here; the Escape path through WaitForEscape leaves one return
; address on the stack each time (harmless until it happens ~120 times).
;------------------------------------------------------------------------------
MainMenu:	nop	;@0242
	call SetTextMode	;@0243
	mov byte ptr CursorRow, 1	; row	;@0246
	mov al, 0Fh	;@024B
	mov byte ptr CursorCol, al	; column	;@024D
	call PrintInline	;@0250
	db 55h,4Ch,54h,49h,4Dh,41h,20h,5Dh,5Bh,0h	; "ULTIMA ]["	;@0253
	mov byte ptr CursorRow, 3	;@025D
	mov al, 10h	;@0262
	mov byte ptr CursorCol, al	;@0264
	call PrintInline	;@0267
	db 52h,45h,56h,45h,4Eh,47h,45h,0h	; "REVENGE"	;@026A
	mov byte ptr CursorRow, 5	;@0272
	mov al, 10h	;@0277
	mov byte ptr CursorCol, al	;@0279
	call PrintInline	;@027C
	db 4Fh,46h,20h,20h,54h,48h,45h,0h	; "OF  THE"	;@027F
	mov byte ptr CursorRow, 7	;@0287
	mov al, 0Eh	;@028C
	mov byte ptr CursorCol, al	;@028E
	call PrintInline	;@0291
	db 45h,4Eh,43h,48h,41h,4Eh,54h,52h,45h,53h,53h,0h	; "ENCHANTRESS"	;@0294
	mov al, 16h	;@02A0
	mov byte ptr CursorRow, al	;@02A2
	mov al, 6	;@02A5
	mov byte ptr CursorCol, al	;@02A7
	call PrintInline	;@02AA
; "(C)-1983,1989 BY LORD BRITISH"
	db 28h,43h,29h,2Dh,31h,39h,38h,33h,2Ch,31h,39h,38h,39h,20h,42h,59h	;@02AD
	db 20h,4Ch,4Fh,52h,44h,20h,42h,52h,49h,54h,49h,53h,48h,0h	;@02BD
	mov byte ptr CursorRow, 17h	;@02CB
	mov al, 0Fh	;@02D0
	mov byte ptr CursorCol, al	;@02D2
	call PrintInline	;@02D5
	db 41h,4Eh,44h,20h,4Fh,52h,49h,47h,49h,4Eh,0h	; "AND ORIGIN"	;@02D8
	mov al, 0Bh	;@02E3
	mov byte ptr CursorRow, al	;@02E5
	mov al, 5	;@02E8
	mov byte ptr CursorCol, al	;@02EA
	call PrintInline	;@02ED
	db 54h,59h,50h,45h,20h,2Dh,0h	; "TYPE -"	;@02F0
	mov byte ptr CursorRow, 0Dh	;@02F7
	mov al, 6	;@02FC
	mov byte ptr CursorCol, al	;@02FE
	call PrintInline	;@0301
	db 27h,44h,27h,20h,2Dh,20h,46h,4Fh,52h,20h,41h,20h,44h,45h,4Dh,4Fh	; "'D' - FOR A DEMONSTRATION"	;@0304
	db 4Eh,53h,54h,52h,41h,54h,49h,4Fh,4Eh,0h	;@0314
	mov byte ptr CursorRow, 0Fh	;@031E
	mov al, 6	;@0323
	mov byte ptr CursorCol, al	;@0325
	call PrintInline	;@0328
; "'P' - PLAY A GAME OF ULTIMA ]["
	db 27h,50h,27h,20h,2Dh,20h,50h,4Ch,41h,59h,20h,41h,20h,47h,41h,4Dh	;@032B
	db 45h,20h,4Fh,46h,20h,55h,4Ch,54h,49h,4Dh,41h,20h,5Dh,5Bh,0h	;@033B
	mov byte ptr CursorRow, 11h	;@034A
	mov al, 6	;@034F
	mov byte ptr CursorCol, al	;@0351
	call PrintInline	;@0354
; "'C' - CREATE A NEW CHARACTER"
	db 27h,43h,27h,20h,2Dh,20h,43h,52h,45h,41h,54h,45h,20h,41h,20h,4Eh	;@0357
	db 45h,57h,20h,43h,48h,41h,52h,41h,43h,54h,45h,52h,0h	;@0367
	mov byte ptr CursorRow, 13h	;@0374
	mov al, 5	;@0379
	mov byte ptr CursorCol, al	;@037B
	call PrintInline	;@037E
	db 43h,48h,4Fh,49h,43h,45h,3Ah,0h	; "CHOICE:"	;@0381
	mov di, 30h	; not used afterwards (left-over)	;@0389
Menu_WaitKey:	call ReadKey	; wait for a key: AH = FFh when one was read	;@038C
	cmp ah, 0FFh	;@038F
	jne Menu_WaitKey	;@0392
	call PrintChar	; echo it (AL is upper case)	;@0394
	cmp al, 44h	; 'D'	;@0397
	jne L039E	;@0399
	jmp DemoShow	;@039B
L039E:	cmp al, 50h	; 'P'	;@039E
	je Menu_Play	;@03A0
	cmp al, 43h	; 'C'	;@03A2
	je Menu_Create	;@03A4
	jmp MainMenu	;@03A6
Menu_Create:	call CreateCharacter	; create a character (normally ends by restarting at ProgramEntry)	;@03A9
Menu_Play:	call GameStart	; play; never returns (the main loop resets SP)	;@03AC

;------------------------------------------------------------------------------
; DemoShow: the demonstration. Five CGA pictures, each read into B800:0000 and
; captioned on text rows 23 and 24, each held by DemoWait (Escape: menu MainMenu),
; then the captions (ClearBottomLines) and the picture (ClearViewArea) are cleared. Sets DemoSeen,
; so the title sequence comes back here by itself. Ends with jmp TitleScreen.
;------------------------------------------------------------------------------
DemoShow:	nop	;@03AF
	call SetGraphicsMode	; CGA mode 4 (clears the screen)	;@03B0
	mov al, 1	;@03B3
	mov byte ptr DemoSeen, al	; demonstration seen: repeat it after the title	;@03B5
	mov ah, 27h	;@03B8
	mov cx, 4000h	;@03BA
	mov dx, 0	;@03BD
	call ReadWriteFile	;@03C0
	db 50h,49h,43h,4Fh,55h,54h,20h,20h	; "PICOUT  " (outdoors)	;@03C3
	mov byte ptr CursorRow, 17h	;@03CB
	mov byte ptr CursorCol, 0	;@03D0
	call PrintInline	;@03D5
	db 20h,20h,20h,20h,20h,20h,20h,20h,42h,41h,54h,54h,4Ch,45h,20h,53h	; "BATTLE STRANGE CREATURES"	;@03D8
	db 54h,52h,41h,4Eh,47h,45h,20h,43h,52h,45h,41h,54h,55h,52h,45h,53h	;@03E8
	db 0h	;@03F8
	mov byte ptr CursorCol, 0	;@03F9
	mov byte ptr CursorRow, 18h	;@03FE
	call PrintInline	;@0403
; "ACROSS THE FACE OF THE EARTH"
	db 20h,20h,20h,20h,20h,20h,41h,43h,52h,4Fh,53h,53h,20h,54h,48h,45h	;@0406
	db 20h,46h,41h,43h,45h,20h,4Fh,46h,20h,54h,48h,45h,20h,45h,41h,52h	;@0416
	db 54h,48h,0h	;@0426
	call DemoWait	;@0429
	call ClearBottomLines	; clear text rows 23-24	;@042C
	call ClearViewArea	; clear both CGA banks	;@042F
	mov ah, 27h	;@0432
	mov cx, 4000h	;@0434
	mov dx, 0	;@0437
	call ReadWriteFile	;@043A
	db 50h,49h,43h,54h,57h,4Eh,20h,20h	; "PICTWN  " (town)	;@043D
	mov byte ptr CursorCol, 0	;@0445
	mov byte ptr CursorRow, 17h	;@044A
	call PrintInline	;@044F
; "SEARCH FOR CLUES IN CARELESS WORDS"
	db 20h,20h,20h,53h,45h,41h,52h,43h,48h,20h,46h,4Fh,52h,20h,43h,4Ch	;@0452
	db 55h,45h,53h,20h,49h,4Eh,20h,43h,41h,52h,45h,4Ch,45h,53h,53h,20h	;@0462
	db 57h,4Fh,52h,44h,53h,0h	;@0472
	mov byte ptr CursorCol, 2	;@0478
	mov byte ptr CursorRow, 18h	;@047D
	call PrintInline	;@0482
	db 20h,20h,20h,20h,20h,20h,53h,50h,4Fh,4Bh,45h,4Eh,20h,41h,54h,20h	; "SPOKEN AT THE LOCAL PUB"	;@0485
	db 54h,48h,45h,20h,4Ch,4Fh,43h,41h,4Ch,20h,50h,55h,42h,0h	;@0495
	call DemoWait	;@04A3
	jmp Demo_Dungeon	; skip the dead PICCAS scene	;@04A6
;
; Dead code (nothing jumps here): the castle scene of the 1983 version, cut by
; the jmp above; the release has no PICCAS file. Decoded: call ClearBottomLines; call
; ClearViewArea; load "PICCAS  "; captions "PLEAD WITH MEDIEVAL KINGS" / "FOR
; ASSISTANCE"; call DemoWait.
;
	db 0E8h,0E3h,4Eh,0E8h,9Fh,46h,0B4h,27h,0B9h,0h,40h,0BAh,0h,0h,0E8h,10h	;@04A9
	db 4Eh,50h,49h,43h,43h,41h,53h,20h,20h,0C6h,6h,2Eh,0h,0h,0C6h,6h	;@04B9
	db 2Fh,0h,17h,0E8h,10h,4Bh,20h,20h,20h,20h,20h,20h,20h,20h,50h,4Ch	;@04C9
	db 45h,41h,44h,20h,57h,49h,54h,48h,20h,4Dh,45h,44h,49h,45h,56h,41h	;@04D9
	db 4Ch,20h,4Bh,49h,4Eh,47h,53h,0h,0C6h,6h,2Eh,0h,4h,0C6h,6h,2Fh	;@04E9
	db 0h,18h,0E8h,0E1h,4Ah,20h,20h,20h,20h,20h,20h,20h,20h,20h,46h,4Fh	;@04F9
	db 52h,20h,41h,53h,53h,49h,53h,54h,41h,4Eh,43h,45h,0h,0E8h,76h,1h	;@0509
Demo_Dungeon:	call ClearBottomLines	;@0519
	call ClearViewArea	;@051C
	mov ah, 27h	;@051F
	mov cx, 4000h	;@0521
	mov dx, 0	;@0524
	call ReadWriteFile	;@0527
	db 50h,49h,43h,44h,4Eh,47h,20h,20h	; "PICDNG  " (dungeon)	;@052A
	mov byte ptr CursorCol, 0	;@0532
	mov byte ptr CursorRow, 17h	;@0537
	call PrintInline	;@053C
; "TRAVERSE DEEP DARK DEADLY DUNGEONS"
	db 20h,20h,20h,54h,52h,41h,56h,45h,52h,53h,45h,20h,44h,45h,45h,50h	;@053F
	db 20h,44h,41h,52h,4Bh,20h,44h,45h,41h,44h,4Ch,59h,20h,44h,55h,4Eh	;@054F
	db 47h,45h,4Fh,4Eh,53h,0h	;@055F
	mov byte ptr CursorCol, 1	;@0565
	mov byte ptr CursorRow, 18h	;@056A
	call PrintInline	;@056F
	db 20h,20h,20h,20h,20h,20h,41h,4Eh,44h,20h,54h,41h,4Ch,4Ch,20h,54h	; "AND TALL TERRIFYING TOWERS"	;@0572
	db 45h,52h,52h,49h,46h,59h,49h,4Eh,47h,20h,54h,4Fh,57h,45h,52h,53h	;@0582
	db 0h	;@0592
	call DemoWait	;@0593
	call ClearBottomLines	;@0596
	call ClearViewArea	;@0599
	mov ah, 27h	;@059C
	mov cx, 4000h	;@059E
	mov dx, 0	;@05A1
	call ReadWriteFile	;@05A4
	db 50h,49h,43h,53h,50h,41h,20h,20h	; "PICSPA  " (space)	;@05A7
	mov byte ptr CursorCol, 0	;@05AF
	mov byte ptr CursorRow, 17h	;@05B4
	call PrintInline	;@05B9
; "TRAVEL THROUGHOUT THE GALAXY"
	db 20h,20h,20h,20h,20h,20h,54h,52h,41h,56h,45h,4Ch,20h,54h,48h,52h	;@05BC
	db 4Fh,55h,47h,48h,4Fh,55h,54h,20h,54h,48h,45h,20h,47h,41h,4Ch,41h	;@05CC
	db 58h,59h,0h	;@05DC
	mov byte ptr CursorCol, 1	;@05DF
	mov byte ptr CursorRow, 18h	;@05E4
	call PrintInline	;@05E9
; "TO THE PLANETS OF OUR SOLAR SYSTEM"
	db 20h,20h,54h,4Fh,20h,54h,48h,45h,20h,50h,4Ch,41h,4Eh,45h,54h,53h	;@05EC
	db 20h,4Fh,46h,20h,4Fh,55h,52h,20h,53h,4Fh,4Ch,41h,52h,20h,53h,59h	;@05FC
	db 53h,54h,45h,4Dh,0h	;@060C
	call DemoWait	;@0611
	call ClearBottomLines	;@0614
	call ClearViewArea	;@0617
	mov ah, 27h	;@061A
	mov cx, 4000h	;@061C
	mov dx, 0	;@061F
	call ReadWriteFile	;@0622
	db 50h,49h,43h,4Dh,49h,4Eh,20h,20h	; "PICMIN  " (Minax)	;@0625
	mov byte ptr CursorCol, 0	;@062D
	mov byte ptr CursorRow, 17h	;@0632
	call PrintInline	;@0637
; "AND CONQUER TIME ITSELF TO BATTLE"
	db 20h,20h,20h,41h,4Eh,44h,20h,43h,4Fh,4Eh,51h,55h,45h,52h,20h,54h	;@063A
	db 49h,4Dh,45h,20h,49h,54h,53h,45h,4Ch,46h,20h,54h,4Fh,20h,42h,41h	;@064A
	db 54h,54h,4Ch,45h,0h	;@065A
	mov byte ptr CursorCol, 8	;@065F
	mov byte ptr CursorRow, 18h	;@0664
	call PrintInline	;@0669
	db 4Dh,49h,4Eh,41h,58h,20h,54h,48h,45h,20h,45h,4Eh,43h,48h,41h,4Eh	; "MINAX THE ENCHANTRESS"	;@066C
	db 54h,52h,45h,53h,53h,0h	;@067C
	call DemoWait	;@0682
	jmp TitleScreen	; and round again	;@0685

;------------------------------------------------------------------------------
; TitleWait: title wait: up to 6000h key polls (see WaitForEscape). Escape does not return
; here but jumps to the menu MainMenu.
; In: none. Out: DX = 0. Uses: AX, BX, DX.
;------------------------------------------------------------------------------
TitleWait:	mov dx, 6000h	;@0688
	call WaitForEscape	;@068B
	ret	;@068E

;------------------------------------------------------------------------------
; DemoWait: demonstration wait: like TitleWait with A000h key polls.
;------------------------------------------------------------------------------
DemoWait:	mov dx, 0A000h	;@068F
	call WaitForEscape	;@0692
	ret	;@0695

;------------------------------------------------------------------------------
; WaitForEscape: wait loop of TitleWait/DemoWait: DX times (delay table entry 5, then read a
; key). Other keys are read and ignored. On Escape it drops its own return
; address and jumps to the menu MainMenu, so the return address of the caller of
; TitleWait/DemoWait stays on the stack. With the 1989 speed setting the delay is 0,
; so the length of the wait depends on the CPU speed.
; In: DX = number of polls. Out: DX = 0. Uses: AX, BX, DX.
;------------------------------------------------------------------------------
WaitForEscape:	mov bx, 0Ah	; delay table entry 5 (byte offset 0Ah)	;@0696
	call SpeedDelay	;@0699
	call ReadKey	;@069C
	cmp ax, 0FF1Bh	; Escape?	;@069F
	jne L06A8	;@06A2
	pop ax	; drop the return address into TitleWait/DemoWait	;@06A4
	jmp MainMenu	;@06A5
L06A8:	dec dx	;@06A8
	jne WaitForEscape	;@06A9
	ret	;@06AB

;------------------------------------------------------------------------------
; SetDefaultSpeed: set the speed setting SpeedSetting to 0FFh. The 1989 patch put this over
; the old speed calibration (whose tail follows as dead bytes). 0FFh is below
; the base value SpeedMin (068Ah), so CalcDelayTbl makes every delay 0 (fastest);
; Ctrl-Left / Ctrl-Right (TEXTIO 4F89) change SpeedSetting in steps of 200h.
; Also called by MAIN at game start when the PLAYER file has SpeedSetting = 0.
; Probable bug (TEXTIO 4F8E, by reading, not tested): Ctrl-Right subtracts
; 200h and keeps the result unless it is below SpeedMin, so from 00FFh it stores
; 0FEFFh; CalcDelayTbl then overflows its div (divide error, the program ends).
; In: none. Out: SpeedSetting = 00FFh. Uses: nothing else.
;------------------------------------------------------------------------------
SetDefaultSpeed:	mov word ptr SpeedSetting, 0FFh	;@06AC
	ret	;@06B2
;
; Dead bytes: the tail of the 1983 calibration that SetDefaultSpeed replaced. Decoded
; (06B4-06EC): save the BIOS tick count in D_0550/D_0552, SpeedSetting = 0, wait for
; the next tick (int 1Ah; restart at 06AC at midnight), then count loops of
; 100 x `dec ax` in SpeedSetting until 20 ticks (about 1.1 s) have passed. So
; SpeedSetting was the CPU speed: delay loops ran per 20 ticks.
;
	db 5h,89h,16h,50h,5h,0C7h,6h,74h,0h,0h,0h,0B4h,0h,0CDh,1Ah,3Ch	;@06B3
	db 0h,75h,0E6h,3Bh,16h,50h,5h,74h,0F2h,0B4h,0h,0CDh,1Ah,3Ch,0h,75h	;@06C3
	db 0D8h,0B8h,64h,0h,48h,75h,0FDh,83h,6h,74h,0h,1h,2Bh,16h,50h,5h	;@06D3
	db 2Bh,0Eh,52h,5h,83h,0FAh,14h,72h,0E0h,0C3h	;@06E3

;------------------------------------------------------------------------------
; CalcDelayTbl: compute the delay table from the speed setting: for each of the 20
; entries (byte offsets 26h down to 0)
;   DelayTbl[bx] = (SpeedSetting - SpeedMin) * DelayFactorTbl[bx] / SpeedMin, or 0 when
;   SpeedSetting < SpeedMin
; i.e. the delays grow with how much faster than the base machine the CPU is.
; The upper limit 3A00h kept by the Ctrl-Left key is about the largest value for
; which the biggest factor (2000h) does not overflow the div.
; Also called by the key reader ReadKey (at 4FB3) after a speed key.
; In: SpeedSetting. Out: DelayTbl filled. Uses: AX, BX, DX (DX is clobbered by mul/div,
; also for the callers of ReadKey).
;------------------------------------------------------------------------------
CalcDelayTbl:	mov bx, 26h	; last entry (20 words)	;@06ED
CalcDelayTbl_Loop:	mov ax, word ptr SpeedSetting	;@06F0
	sub ax, word ptr SpeedMin	;@06F3
	jae CalcDelayTbl_Scale	;@06F7
	mov ax, 0	; slower than the base: no delay	;@06F9
	jmp L0707	;@06FC
CalcDelayTbl_Scale:	mul word ptr DelayFactorTbl[bx]	;@06FF
	div word ptr SpeedMin	;@0703
L0707:	mov word ptr DelayTbl[bx], ax	;@0707
	sub bx, 2	;@070B
	jae CalcDelayTbl_Loop	;@070E
	ret	;@0710

;------------------------------------------------------------------------------
; SpeedDelay: delay. Runs DelayTbl[bx] times a 12-iteration busy loop (none when the
; entry is 0, or 8000h and above).
; In: BX = byte offset of the delay table entry (2 * entry number).
; Out: nothing. Uses: AX, BX.
; Entries used here and in MAIN: 0 (command prompt key poll), 4 (title
; dragon), 5 (title/demonstration waits); other modules use others (CMDAL's
; launch: byte offset 1Ch = entry 0Eh).
;------------------------------------------------------------------------------
SpeedDelay:	mov bx, word ptr DelayTbl[bx]	;@0711
SpeedDelay_Loop:	dec bx	;@0715
	js SpeedDelay_Done	;@0716
	mov ax, 0Ch	;@0718
SpeedDelay_Inner:	dec ax	;@071B
	jne SpeedDelay_Inner	;@071C
	jmp SpeedDelay_Loop	;@071E
SpeedDelay_Done:	ret	;@0720
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h	; zeros up to the jump table at 0730 (padding?)	;@0721
CODE ENDS
END ProgramEntry
