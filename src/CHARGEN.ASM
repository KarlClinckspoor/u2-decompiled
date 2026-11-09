; CHARGEN.ASM: character generation.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 5400-5AB1.
;
; Character creation: "C" on the title menu (START calls CreateCharacter at 03A9; it never returns).
; CreateCharacter reads the PLAYER file (100h bytes) into the player record at PlayerRecord. If the record is
; not blank (first name byte non-zero) it prints NOT A BLANK PLAYER DISK and hangs. Otherwise
; it draws the character sketch and asks for:
;  - the six attributes, two decimal digits each (ReadTwoDigits gives BCD): at least 10 each and 90
;    points in all, checked and subtracted by SpendAttrPoints (any error starts everything over);
;  - sex, race and type; each adds a bonus to one attribute (BCD, daa):
;      M)ale +5 strength, F)emale +10 charisma,
;      1 human +5 intelligence, 2 elf +5 agility, 3 dwarf +5 strength, 4 hobbit +10 wisdom,
;      1 fighter +15 strength, 2 cleric +10 wisdom, 3 wizard +10 intelligence, 4 thief +10 agility
;    (the manual says hobbit +5 and fighter +10; nothing but "female" touches charisma);
;  - the name (up to 12 characters, Backspace starts the name over), then SATISFACTORY (Y/N).
; Y sets the starting values (position 20,20, hits/food/gold 400), writes the record back to
; PLAYER and restarts the program (call ProgramEntry); N starts the whole sketch over (CreateChar_Sketch).
; Two "insert disk" prompts of the floppy version are still here as dead bytes (5414, 5A1E).
; Data: player record PlayerRecord-D_0135: name PlayerRecord (16 bytes), sex PlayerSex ('M'/'F'), type
; PlayerClass (0-3), race PlayerRace (0-3), TimeZone, attributes Strength-Intelligence (BCD: strength, agility,
; stamina, charisma, wisdom, intelligence), hits HitPointsHi, food FoodHi, gold GoldHi (high BCD
; bytes), saved position SurfaceX/SurfaceY. Temp29 = points left (BCD), Temp2A = value typed.
; MapViewCol at the end is not chargen: a CS work byte of MAPVIEW (5BCC) in the padding.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN Temp29:BYTE, Temp2A:BYTE, PlayerRecord:BYTE, PlayerSex:BYTE, PlayerClass:BYTE, PlayerRace:BYTE
	EXTRN TimeZone:BYTE, Strength:BYTE, Agility:BYTE, Stamina:BYTE, Charisma:BYTE, Wisdom:BYTE
	EXTRN Intelligence:BYTE, HitPointsHi:BYTE, FoodHi:BYTE, GoldHi:BYTE, SurfaceX:BYTE, SurfaceY:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN ProgramEntry:NEAR, SetTextMode:NEAR, PrintInline:NEAR, PrintChar:NEAR, ReadTwoDigits:NEAR, SetCursor:NEAR
	EXTRN ReadWriteFile:NEAR, PrintBcdByte:NEAR, WaitKey:NEAR, SetTextNormal:NEAR, SetTextWarning:NEAR
	PUBLIC CreateCharacter, MapViewCol
ASSUME CS:CODE, DS:DATA
;------------------------------------------------------------------------------
; CreateCharacter: create a character (title menu "C"). Reads PLAYER into the player record PlayerRecord;
; refuses (and hangs) unless it is blank, then runs the whole character sketch (see the
; module header) and writes PLAYER. Does not return: restarts the program through ProgramEntry
; after saving, or hangs at CreateChar_Hang. Text output: SetCursor = cursor at row SI, col DI.
; In: nothing. Out: never returns. Uses: everything.
;------------------------------------------------------------------------------
CreateCharacter:	call SetTextMode	; clear the screen (text mode)	;@5400
	mov bh, 0	;@5403
	mov bl, 6	;@5405
	mov di, bx	;@5407
	mov bh, 0	;@5409
	mov bl, 0Ch	;@540B
	mov si, bx	;@540D
	call SetCursor	; cursor: row 12, col 6	;@540F
	jmp short CreateChar_ReadPlayer	; skip the dead "insert disk" prompt below	;@5412
; Dead bytes: the floppy version's prompt. FB = last byte of a "call PrintInline" whose first two
; bytes became the jmp short above; then "(INSERT A BLANK PLAYER DISK)", 0, and
; call ReadKey / cmp ax,0FF1Bh / jne: wait for Escape.
	db 0FBh,28h,49h,4Eh,53h,45h,52h,54h,20h,41h,20h,42h,4Ch,41h,4Eh,4Bh	;@5414
	db 20h,50h,4Ch,41h,59h,45h,52h,20h,44h,49h,53h,4Bh,29h,0Dh,0h,0E8h	;@5424
	db 17h,0FBh,3Dh,1Bh,0FFh,75h,0F8h	;@5434
; Read the PLAYER file into the player record. A blank disk has a zero name byte.
CreateChar_ReadPlayer:	mov ah, 27h	; FCB random block read	;@543B
	mov cx, 100h	; 100h bytes	;@543D
	lea dx, PlayerRecord	; into the player record	;@5440
	call ReadWriteFile	; file "PLAYER"	;@5444
	db 50h,4Ch,41h,59h,45h,52h,20h,20h	;@5447
	cmp byte ptr PlayerRecord, 0	; name empty = blank player disk?	;@544F
	je CreateChar_Sketch	;@5454
; Not blank: complain and hang (the player has to reboot).
	call SetTextMode	;@5456
	mov bh, 0	;@5459
	mov bl, 0Bh	;@545B
	mov si, bx	;@545D
	mov bh, 0	;@545F
	mov bl, 0Eh	;@5461
	mov di, bx	;@5463
	call SetCursor	; cursor: row 11, col 14	;@5465
	call PrintInline	; print "NOT A BLANK"	;@5468
	db 4Eh,4Fh,54h,20h,41h,20h,42h,4Ch,41h,4Eh,4Bh,0h	;@546B
	mov bh, 0	;@5477
	mov bl, 0Dh	;@5479
	mov si, bx	;@547B
	mov bh, 0	;@547D
	mov bl, 0Eh	;@547F
	mov di, bx	;@5481
	call SetCursor	; cursor: row 13, col 14	;@5483
	call PrintInline	; print "PLAYER DISK"	;@5486
	db 50h,4Ch,41h,59h,45h,52h,20h,44h,49h,53h,4Bh,0h	;@5489
	jmp CreateChar_Hang	; hang	;@5495
; The character sketch. Also the restart point for "N" at SATISFACTORY and for
; attribute errors (SpendAttrPoints_Error).
CreateChar_Sketch:	call SetTextMode	; clear the screen	;@5498
	call PrintInline	; print "          PLAYER GENERATION :"	;@549B
	db 20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,50h,4Ch,41h,59h,45h,52h	;@549E
	db 20h,47h,45h,4Eh,45h,52h,41h,54h,49h,4Fh,4Eh,20h,3Ah,0h	;@54AE
	call PrintInline	;@54BC
	db 0Dh,0Ah,20h,20h,20h,20h,20h,50h,4Fh,49h,4Eh,54h,53h,20h,4Ch,45h	;@54BF
	db 46h,54h,20h,54h,4Fh,20h,44h,49h,53h,54h,52h,49h,42h,55h,54h,45h	;@54CF
	db 20h,3Ah,20h,0h	;@54DF
	call SetTextWarning	; highlighted text	;@54E3
	mov al, 90h	; 90 points (BCD)	;@54E6
	mov byte ptr Temp29, al	;@54E8
	call PrintBcdByte	;@54EB
	call SetTextNormal	; normal text	;@54EE
; The sketch: STRENGTH ... INTELLIGENCE on rows 4-9 (values at col 26), M/F- row 11,
; RACE- row 12, TYPE- row 13, NAME- row 14, SATISFACTORY (Y/N)- row 16, and the list of
; races and types below.
	call PrintInline	; print the character sketch	;@54F1
	db 0Dh,0Ah,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,53h,54h,52h	;@54F4
	db 45h,4Eh,47h,54h,48h,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,0Dh,20h,20h,20h	;@5504
	db 20h,20h,20h,20h,20h,20h,20h,20h,41h,47h,49h,4Ch,49h,54h,59h,2Eh	;@5514
	db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,0Dh,20h,20h,20h,20h,20h,20h,20h,20h	;@5524
	db 20h,20h,20h,53h,54h,41h,4Dh,49h,4Eh,41h,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh	;@5534
	db 2Eh,2Eh,0Dh,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,43h,48h	;@5544
	db 41h,52h,49h,53h,4Dh,41h,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,0Dh,20h,20h	;@5554
	db 20h,20h,20h,20h,20h,20h,20h,20h,20h,57h,49h,53h,44h,4Fh,4Dh,2Eh	;@5564
	db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,0Dh,20h,20h,20h,20h,20h,20h,20h	;@5574
	db 20h,20h,20h,20h,49h,4Eh,54h,45h,4Ch,4Ch,49h,47h,45h,4Eh,43h,45h	;@5584
	db 2Eh,2Eh,2Eh,0Dh,0Ah,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h	;@5594
	db 20h,20h,20h,20h,20h,4Dh,2Fh,46h,2Dh,0Dh,20h,20h,20h,20h,20h,20h	;@55A4
	db 20h,20h,20h,20h,20h,20h,20h,20h,20h,52h,41h,43h,45h,2Dh,0Dh,20h	;@55B4
	db 20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,54h,59h	;@55C4
	db 50h,45h,2Dh,0Dh,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h	;@55D4
	db 20h,20h,20h,4Eh,41h,4Dh,45h,2Dh,0Dh,0Ah,20h,20h,20h,20h,20h,20h	;@55E4
	db 20h,20h,20h,20h,53h,41h,54h,49h,53h,46h,41h,43h,54h,4Fh,52h,59h	;@55F4
	db 20h,28h,59h,2Fh,4Eh,29h,2Dh,0Dh,0Ah,20h,20h,20h,20h,20h,20h,20h	;@5604
	db 20h,52h,41h,43h,45h,53h,3Ah,20h,20h,20h,20h,20h,20h,20h,20h,20h	;@5614
	db 54h,59h,50h,45h,53h,3Ah,0Dh,20h,20h,20h,20h,20h,20h,20h,20h,20h	;@5624
	db 31h,2Dh,48h,55h,4Dh,41h,4Eh,20h,20h,20h,20h,20h,20h,20h,20h,31h	;@5634
	db 2Dh,46h,49h,47h,48h,54h,45h,52h,0Dh,20h,20h,20h,20h,20h,20h,20h	;@5644
	db 20h,20h,32h,2Dh,45h,4Ch,46h,20h,20h,20h,20h,20h,20h,20h,20h,20h	;@5654
	db 20h,32h,2Dh,43h,4Ch,45h,52h,49h,43h,0Dh,20h,20h,20h,20h,20h,20h	;@5664
	db 20h,20h,20h,33h,2Dh,44h,57h,41h,52h,46h,20h,20h,20h,20h,20h,20h	;@5674
	db 20h,20h,33h,2Dh,57h,49h,5Ah,41h,52h,44h,0Dh,20h,20h,20h,20h,20h	;@5684
	db 20h,20h,20h,20h,34h,2Dh,48h,4Fh,42h,42h,49h,54h,20h,20h,20h,20h	;@5694
	db 20h,20h,20h,34h,2Dh,54h,48h,49h,45h,46h,0h	;@56A4
; The six attributes: two digits each (ReadTwoDigits, BCD), each checked and taken from the
; points left by SpendAttrPoints. Rows 4-9 = strength, agility, stamina, charisma, wisdom, intelligence.
	mov bh, 0	;@56AF
	mov bl, 4	;@56B1
	mov si, bx	;@56B3
	mov bh, 0	;@56B5
	mov bl, 1Ah	;@56B7
	mov di, bx	;@56B9
	call SetCursor	; cursor: row 4, col 26	;@56BB
	call ReadTwoDigits	; two digits -> BCD	;@56BE
	mov byte ptr Strength, al	;@56C1
	call SpendAttrPoints	; check, take from the points left	;@56C4
	mov bh, 0	;@56C7
	mov bl, 5	;@56C9
	mov si, bx	;@56CB
	mov bh, 0	;@56CD
	mov bl, 1Ah	;@56CF
	mov di, bx	;@56D1
	call SetCursor	; cursor: row 5, col 26	;@56D3
	call ReadTwoDigits	;@56D6
	mov byte ptr Agility, al	;@56D9
	call SpendAttrPoints	;@56DC
	mov bh, 0	;@56DF
	mov bl, 1Ah	;@56E1
	mov di, bx	;@56E3
	mov bh, 0	;@56E5
	mov bl, 6	;@56E7
	mov si, bx	;@56E9
	call SetCursor	; cursor: row 6, col 26	;@56EB
	call ReadTwoDigits	;@56EE
	mov byte ptr Stamina, al	;@56F1
	call SpendAttrPoints	;@56F4
	mov bh, 0	;@56F7
	mov bl, 7	;@56F9
	mov si, bx	;@56FB
	mov bh, 0	;@56FD
	mov bl, 1Ah	;@56FF
	mov di, bx	;@5701
	call SetCursor	; cursor: row 7, col 26	;@5703
	call ReadTwoDigits	;@5706
	mov byte ptr Charisma, al	;@5709
	call SpendAttrPoints	;@570C
	mov bh, 0	;@570F
	mov bl, 1Ah	;@5711
	mov di, bx	;@5713
	mov bh, 0	;@5715
	mov bl, 8	;@5717
	mov si, bx	;@5719
	call SetCursor	; cursor: row 8, col 26	;@571B
	call ReadTwoDigits	;@571E
	mov byte ptr Wisdom, al	;@5721
	call SpendAttrPoints	;@5724
	mov bh, 0	;@5727
	mov bl, 1Ah	;@5729
	mov di, bx	;@572B
	mov bh, 0	;@572D
	mov bl, 9	;@572F
	mov si, bx	;@5731
	call SetCursor	; cursor: row 9, col 26	;@5733
	call ReadTwoDigits	;@5736
	mov byte ptr Intelligence, al	;@5739
	call SpendAttrPoints	;@573C
; Sex: M or F (ReadKey gives upper case); other keys are ignored.
	mov bh, 0	;@573F
	mov bl, 14h	;@5741
	mov di, bx	;@5743
	mov bh, 0	;@5745
	mov bl, 0Bh	;@5747
	mov si, bx	;@5749
	call SetCursor	; cursor: row 11, col 20	;@574B
CreateChar_AskSex:	call WaitKey	; wait for a key	;@574E
	mov byte ptr PlayerSex, al	;@5751
	cmp al, 4Dh	; 'M'	;@5754
	jne CreateChar_NotMale	;@5756
	call PrintInline	; print "MALE"	;@5758
	db 4Dh,41h,4Ch,45h,0h	;@575B
	mov al, byte ptr Strength	;@5760
	add al, 5	; male: strength +5 (BCD)	;@5763
	daa	;@5765
	mov byte ptr Strength, al	;@5766
	mov bh, 0	;@5769
	mov bl, 1Ah	;@576B
	mov di, bx	;@576D
	mov bh, 0	;@576F
	mov bl, 4	;@5771
	mov si, bx	;@5773
	call SetCursor	; cursor: row 4, col 26	;@5775
	mov al, byte ptr Strength	;@5778
	call PrintBcdByte	;@577B
	jmp CreateChar_AskRace	;@577E
CreateChar_NotMale:	cmp al, 46h	; 'F'	;@5781
	jne CreateChar_AskSex	;@5783
	call PrintInline	; print "FEMALE"	;@5785
	db 46h,45h,4Dh,41h,4Ch,45h,0h	;@5788
	mov al, byte ptr Charisma	;@578F
	add al, 10h	; female: charisma +10 (BCD)	;@5792
	daa	;@5794
	mov byte ptr Charisma, al	;@5795
	mov bh, 0	;@5798
	mov bl, 1Ah	;@579A
	mov di, bx	;@579C
	mov bh, 0	;@579E
	mov bl, 7	;@57A0
	mov si, bx	;@57A2
	call SetCursor	; cursor: row 7, col 26	;@57A4
	mov al, byte ptr Charisma	;@57A7
	call PrintBcdByte	;@57AA
; Race: 1-4. The key is kept in PlayerRace as ASCII here and made 0-3 at CreateChar_AskType.
CreateChar_AskRace:	mov bh, 0	;@57AD
	mov bl, 14h	;@57AF
	mov di, bx	;@57B1
	mov bh, 0	;@57B3
	mov bl, 0Ch	;@57B5
	mov si, bx	;@57B7
	call SetCursor	; cursor: row 12, col 20	;@57B9
	call WaitKey	;@57BC
	mov byte ptr PlayerRace, al	;@57BF
	cmp al, 31h	; '1' human	;@57C2
	jne L57F0	;@57C4
	call PrintInline	; print "HUMAN"	;@57C6
	db 48h,55h,4Dh,41h,4Eh,0h	;@57C9
	mov al, byte ptr Intelligence	;@57CF
	add al, 5	; intelligence +5	;@57D2
	daa	;@57D4
	mov byte ptr Intelligence, al	;@57D5
	mov bh, 0	;@57D8
	mov bl, 1Ah	;@57DA
	mov di, bx	;@57DC
	mov bh, 0	;@57DE
	mov bl, 9	;@57E0
	mov si, bx	;@57E2
	call SetCursor	; cursor: row 9, col 26	;@57E4
	mov al, byte ptr Intelligence	;@57E7
	call PrintBcdByte	;@57EA
	jmp CreateChar_AskType	;@57ED
L57F0:	cmp al, 32h	; '2' elf	;@57F0
	jne L581C	;@57F2
	call PrintInline	; print "ELF"	;@57F4
	db 45h,4Ch,46h,0h	;@57F7
	mov al, byte ptr Agility	;@57FB
	add al, 5	; agility +5	;@57FE
	daa	;@5800
	mov byte ptr Agility, al	;@5801
	mov bh, 0	;@5804
	mov bl, 1Ah	;@5806
	mov di, bx	;@5808
	mov bh, 0	;@580A
	mov bl, 5	;@580C
	mov si, bx	;@580E
	call SetCursor	; cursor: row 5, col 26	;@5810
	mov al, byte ptr Agility	;@5813
	call PrintBcdByte	;@5816
	jmp CreateChar_AskType	;@5819
L581C:	cmp al, 33h	; '3' dwarf	;@581C
	jne L584A	;@581E
	call PrintInline	; print "DWARF"	;@5820
	db 44h,57h,41h,52h,46h,0h	;@5823
	mov al, byte ptr Strength	;@5829
	add al, 5	; strength +5	;@582C
	daa	;@582E
	mov byte ptr Strength, al	;@582F
	mov bh, 0	;@5832
	mov bl, 1Ah	;@5834
	mov di, bx	;@5836
	mov bh, 0	;@5838
	mov bl, 4	;@583A
	mov si, bx	;@583C
	call SetCursor	; cursor: row 4, col 26	;@583E
	mov al, byte ptr Strength	;@5841
	call PrintBcdByte	;@5844
	jmp CreateChar_AskType	;@5847
L584A:	cmp al, 34h	; '4' hobbit	;@584A
	je CreateChar_Hobbit	;@584C
	jmp CreateChar_AskRace	; any other key: ask again	;@584E
CreateChar_Hobbit:	call PrintInline	; print "HOBBIT"	;@5851
	db 48h,4Fh,42h,42h,49h,54h,0h	;@5854
	mov al, byte ptr Wisdom	;@585B
	add al, 10h	; wisdom +10 (the manual says +5)	;@585E
	daa	;@5860
	mov byte ptr Wisdom, al	;@5861
	mov bh, 0	;@5864
	mov bl, 1Ah	;@5866
	mov di, bx	;@5868
	mov bh, 0	;@586A
	mov bl, 8	;@586C
	mov si, bx	;@586E
	call SetCursor	; cursor: row 8, col 26	;@5870
	mov al, byte ptr Wisdom	;@5873
	call PrintBcdByte	;@5876
; Type: 1-4. First turn the race key into 0-3. BUG: this is also the loop head for a
; wrong key at the TYPE prompt (jmp CreateChar_AskType at 5929), so each wrong key takes another 31h
; off PlayerRace and the race (printed by Ztats as string 44h+race) becomes garbage.
CreateChar_AskType:	clc	;@5879
	mov al, byte ptr PlayerRace	;@587A
	sub al, 31h	; '1'-'4' -> 0-3 (again on each retry, see above)	;@587D
	mov byte ptr PlayerRace, al	;@587F
	mov bh, 0	;@5882
	mov bl, 0Dh	;@5884
	mov si, bx	;@5886
	mov bh, 0	;@5888
	mov bl, 14h	;@588A
	mov di, bx	;@588C
	call SetCursor	; cursor: row 13, col 20	;@588E
	call WaitKey	;@5891
	mov byte ptr PlayerClass, al	;@5894
	cmp al, 31h	; '1' fighter	;@5897
	jne L58C7	;@5899
	call PrintInline	; print "FIGHTER"	;@589B
	db 46h,49h,47h,48h,54h,45h,52h,0h	;@589E
	mov al, byte ptr Strength	;@58A6
	add al, 15h	; strength +15 (the manual says +10)	;@58A9
	daa	;@58AB
	mov byte ptr Strength, al	;@58AC
	mov bh, 0	;@58AF
	mov bl, 1Ah	;@58B1
	mov di, bx	;@58B3
	mov bh, 0	;@58B5
	mov bl, 4	;@58B7
	mov si, bx	;@58B9
	call SetCursor	; cursor: row 4, col 26	;@58BB
	mov al, byte ptr Strength	;@58BE
	call PrintBcdByte	;@58C1
	jmp CreateChar_TypeDone	;@58C4
L58C7:	cmp al, 32h	; '2' cleric	;@58C7
	jne L58F6	;@58C9
	call PrintInline	; print "CLERIC"	;@58CB
	db 43h,4Ch,45h,52h,49h,43h,0h	;@58CE
	mov al, byte ptr Wisdom	;@58D5
	add al, 10h	; wisdom +10	;@58D8
	daa	;@58DA
	mov byte ptr Wisdom, al	;@58DB
	mov bh, 0	;@58DE
	mov bl, 1Ah	;@58E0
	mov di, bx	;@58E2
	mov bh, 0	;@58E4
	mov bl, 8	;@58E6
	mov si, bx	;@58E8
	call SetCursor	; cursor: row 8, col 26	;@58EA
	mov al, byte ptr Wisdom	;@58ED
	call PrintBcdByte	;@58F0
	jmp CreateChar_TypeDone	;@58F3
L58F6:	cmp al, 33h	; '3' wizard	;@58F6
	jne L5925	;@58F8
	call PrintInline	; print "WIZARD"	;@58FA
	db 57h,49h,5Ah,41h,52h,44h,0h	;@58FD
	mov al, byte ptr Intelligence	;@5904
	add al, 10h	; intelligence +10	;@5907
	daa	;@5909
	mov byte ptr Intelligence, al	;@590A
	mov bh, 0	;@590D
	mov bl, 1Ah	;@590F
	mov di, bx	;@5911
	mov bh, 0	;@5913
	mov bl, 9	;@5915
	mov si, bx	;@5917
	call SetCursor	; cursor: row 9, col 26	;@5919
	mov al, byte ptr Intelligence	;@591C
	call PrintBcdByte	;@591F
	jmp CreateChar_TypeDone	;@5922
L5925:	cmp al, 34h	; '4' thief	;@5925
	je CreateChar_Thief	;@5927
	jmp CreateChar_AskType	; any other key: ask again (via the race conversion!)	;@5929
CreateChar_Thief:	call PrintInline	; print "THIEF"	;@592C
	db 54h,48h,49h,45h,46h,0h	;@592F
	mov al, byte ptr Agility	;@5935
	add al, 10h	; agility +10	;@5938
	daa	;@593A
	mov byte ptr Agility, al	;@593B
	mov bh, 0	;@593E
	mov bl, 1Ah	;@5940
	mov di, bx	;@5942
	mov bh, 0	;@5944
	mov bl, 5	;@5946
	mov si, bx	;@5948
	call SetCursor	; cursor: row 5, col 26	;@594A
	mov al, byte ptr Agility	;@594D
	call PrintBcdByte	;@5950
; Type key -> 0-3.
CreateChar_TypeDone:	clc	;@5953
	mov al, byte ptr PlayerClass	;@5954
	sub al, 31h	; '1'-'4' -> 0-3	;@5957
	mov byte ptr PlayerClass, al	;@5959
; Name: blank the field and the name bytes, then read up to 12 characters. Backspace
; starts the name over. The clear loop does PlayerRecord+0Eh down to PlayerRecord+1 only (6502 style
; dex/bne); byte 0 is left alone, the first key overwrites it.
CreateChar_AskName:	mov bh, 0	;@595C
	mov bl, 0Eh	;@595E
	mov si, bx	;@5960
	mov bh, 0	;@5962
	mov bl, 14h	;@5964
	mov di, bx	;@5966
	call SetCursor	; cursor: row 14, col 20	;@5968
	call PrintInline	; print 15 blanks over the name field	;@596B
	db 20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,0h	;@596E
	mov bh, 0	;@597E
	mov bl, 14h	;@5980
	mov di, bx	;@5982
	mov bh, 0	;@5984
	mov bl, 0Eh	;@5986
	mov si, bx	;@5988
	call SetCursor	; cursor: row 14, col 20	;@598A
	mov bh, 0	;@598D
	mov bl, 0Eh	; clear PlayerRecord[0Eh..1]	;@598F
	mov di, bx	;@5991
	mov al, 0	;@5993
CreateChar_ClearName:	mov byte ptr PlayerRecord[di], al	;@5995
	dec di	;@5999
	jne CreateChar_ClearName	;@599A
	mov bh, 0	;@599C
	mov bl, 0	;@599E
	mov di, bx	;@59A0
CreateChar_NameKey:	call WaitKey	;@59A2
	cmp al, 8	; Backspace: start the name over	;@59A5
	je CreateChar_AskName	;@59A7
	cmp al, 0Dh	; Enter: done	;@59A9
	je CreateChar_AskOK	;@59AB
	call PrintChar	; echo the key	;@59AD
	mov byte ptr PlayerRecord[di], al	;@59B0
	inc di	;@59B4
	mov bx, di	;@59B5
	cmp bl, 0Ch	; 12 characters at most	;@59B7
	jb CreateChar_NameKey	;@59BA
; SATISFACTORY (Y/N)
CreateChar_AskOK:	mov bh, 0	;@59BC
	mov bl, 10h	;@59BE
	mov si, bx	;@59C0
	mov bh, 0	;@59C2
	mov bl, 1Dh	;@59C4
	mov di, bx	;@59C6
	call SetCursor	; cursor: row 16, col 29	;@59C8
	call WaitKey	;@59CB
	call PrintChar	;@59CE
	cmp al, 4Eh	; 'N': start over	;@59D1
	jne CreateChar_NotNo	;@59D3
	jmp CreateChar_Sketch	;@59D5
CreateChar_NotNo:	cmp al, 59h	; 'Y'	;@59D8
	jne CreateChar_AskOK	;@59DA
; Y: starting values, then write the record to PLAYER.
	mov al, 14h	; saved position X = 20	;@59DC
	mov byte ptr SurfaceX, al	;@59DE
	mov al, 14h	; saved position Y = 20	;@59E1
	mov byte ptr SurfaceY, al	;@59E3
	mov al, 2	; TimeZone = 2 (map group / time zone?)	;@59E6
	mov byte ptr TimeZone, al	;@59E8
	mov al, 4	; hits, food, gold = 400 (high BCD bytes)	;@59EB
	mov byte ptr HitPointsHi, al	;@59ED
	mov byte ptr FoodHi, al	;@59F0
	mov byte ptr GoldHi, al	;@59F3
	mov ah, 28h	; FCB random block write	;@59F6
	mov cx, 100h	; 100h bytes	;@59F8
	lea dx, PlayerRecord	;@59FB
	call ReadWriteFile	; file "PLAYER"	;@59FF
	db 50h,4Ch,41h,59h,45h,52h,20h,20h	;@5A02
; Clear the screen and restart the game program. The jmp short skips the floppy
; version's "TO PLAY ULTIMA ][ / INSERT PROGRAM MASTER" prompt (dead bytes at 5A1E: the
; tail F5 of a call PrintInline, the text, set cursor row 13 col 9, call PrintInline "INSERT PROGRAM
; MASTER", then wait for Escape with call ReadKey / cmp ax,0FF1Bh / jne).
	call SetTextMode	;@5A0A
	mov bh, 0	;@5A0D
	mov bl, 0Bh	;@5A0F
	mov si, bx	;@5A11
	mov bh, 0	;@5A13
	mov bl, 0Bh	;@5A15
	mov di, bx	;@5A17
	call SetCursor	; cursor: row 11, col 11	;@5A19
	jmp short CreateChar_Restart	; skip the dead prompt below	;@5A1C
	db 0F5h,54h,4Fh,20h,50h,4Ch,41h,59h,20h,55h,4Ch,54h,49h,4Dh,41h,20h	;@5A1E
	db 5Dh,5Bh,0h,0B7h,0h,0B3h,0Dh,8Bh,0F3h,0B7h,0h,0B3h,9h,8Bh,0FBh,0E8h	;@5A2E
	db 0ABh,0F7h,0E8h,9Ch,0F5h,49h,4Eh,53h,45h,52h,54h,20h,50h,52h,4Fh,47h	;@5A3E
	db 52h,41h,4Dh,20h,4Dh,41h,53h,54h,45h,52h,0h,0E8h,0F1h,0F4h,3Dh,1Bh	;@5A4E
	db 0FFh,75h,0F8h	;@5A5E
CreateChar_Restart:	call ProgramEntry	; restart the program from its entry point	;@5A61
CreateChar_Hang:	jmp CreateChar_Hang	; hang forever	;@5A64
;------------------------------------------------------------------------------
; SpendAttrPoints: take an attribute value from the points left. The value must be at least 10 and
; at most the points left: then Temp29 -= value (BCD) and the new total is shown
; highlighted at row 2, col 33. Otherwise beep three times, drop the return address and
; start the character over (jmp CreateChar_Sketch).
; In: AL = value (BCD), Temp29 = points left. Out: Temp29, Temp2A = value.
; Uses: AX, BX, SI, DI.
;------------------------------------------------------------------------------
SpendAttrPoints:	mov byte ptr Temp2A, al	;@5A66
	cmp al, 0Ah	; less than 10?	;@5A69
	jb SpendAttrPoints_Error	;@5A6B
	mov al, byte ptr Temp29	;@5A6D
	sub al, byte ptr Temp2A	; points left - value (BCD)	;@5A70
	das	;@5A74
	jb SpendAttrPoints_Error	; more than the points left?	;@5A75
	call SetTextWarning	; highlighted text	;@5A77
	mov byte ptr Temp29, al	;@5A7A
	mov bh, 0	;@5A7D
	mov bl, 2	;@5A7F
	mov si, bx	;@5A81
	mov bh, 0	;@5A83
	mov bl, 21h	;@5A85
	mov di, bx	;@5A87
	call SetCursor	; cursor: row 2, col 33	;@5A89
	mov al, byte ptr Temp29	;@5A8C
	call PrintBcdByte	;@5A8F
	call SetTextNormal	; normal text	;@5A92
	ret	;@5A95
SpendAttrPoints_Error:	call PrintInline	; print "<BEL><BEL><BEL>"	;@5A96
	db 7h,7h,7h,0h	;@5A99
	pop ax	; drop the return address	;@5A9D
	jmp CreateChar_Sketch	; start over	;@5A9E
; Padding up to the end of the module.
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h	;@5AA1
;------------------------------------------------------------------------------
; MapViewCol: CS work byte of MAPVIEW (written at 5BCC, read at 5BED): the map column of the
; tile being drawn, (WorkX + FacingDX) and 3Fh. It sits in the padding of this module.
;------------------------------------------------------------------------------
MapViewCol label byte
	db 0h	;@5AB0
CODE ENDS
END
