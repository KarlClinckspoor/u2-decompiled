; TEXTIO.ASM: terrain names; keyboard, text output, numbers, random numbers, file I/O.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 4C60-5400.
;
; The support library for text, keys, numbers, randomness and files.
; Text is written through the BIOS (int 10h AH=9) at the cursor CursorCol/CursorRow in the colour /
; attribute TextAttr, in both text and graphics mode; the message window is rows 20-23 between
; columns TextLeftCol and TextRightCol and scrolls up when the cursor passes row 23.
; Entry points: PrintInline (print the inline text after the call), PrintChar (print AL), PrintNameStr (print
; string n of the name table NameStrTbl), PrintBcdByte/PrintBcdWord (print BCD numbers), DrawStatusLines (status lines),
; ReadKey (poll the keyboard), WaitKey (wait for a key), ReadTwoDigits (read 2 digits), SetCursor (set the
; cursor), Random (random number), GetMapSquare (map byte at LookX/LookY), ReadWriteFile (read or write a
; file whose name follows the call), XorAttackMark (XOR the attack mark next to the player),
; DirToPlayer/DistToPlayer/SignOf/AbsOf (direction and sign helpers).
; Data: cursor CursorCol/CursorRow, TextRightCol/TextLeftCol (window edges), TextAttr (text attribute), GraphicsMode
; (video mode), random seed RandSeed-RandSeed5, FCB at Fcb, player record at PlayerRecord.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN PlayerX:BYTE, PlayerY:BYTE, MapCellPtr:BYTE, DeltaX:BYTE, DeltaY:BYTE, LookX:BYTE
	EXTRN LookY:BYTE, AmountHi:BYTE, InlineTextPtr:BYTE, CursorCol:BYTE, CursorRow:BYTE, TextRightCol:BYTE
	EXTRN PlayerRecord:BYTE, PlayerSex:BYTE, HitPointsHi:BYTE, HitPointsLo:BYTE, FoodHi:BYTE, FoodLo:BYTE
	EXTRN ExpHi:BYTE, ExpLo:BYTE, GoldHi:BYTE, GoldLo:BYTE, SpeedSetting:BYTE, MonsterX:BYTE
	EXTRN MonsterY:BYTE, TextAttr:BYTE, RandSeed:BYTE, RandSeed1:BYTE, RandSeed4:BYTE, RandSeed5:BYTE
	EXTRN Fcb:BYTE, FcbName:BYTE, FcbExt:BYTE, FcbExt1:BYTE, FcbExt2:BYTE, FcbRecSize:BYTE
	EXTRN MapBufPtr:BYTE, GraphicsMode:BYTE, SoundOff:BYTE, TextLeftCol:BYTE, SpeedMin:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN CalcDelayTbl:NEAR, XorBitmapCS:NEAR
	PUBLIC DirToPlayer, DistToPlayer, ReadKey, PrintInline, PrintChar, PrintSex
	PUBLIC PrintPlayerName, PrintNameStr, GetMapSquare, SignOf, AbsOf, DrawStatusLines
	PUBLIC PrintBcdWord, ReadTwoDigits, SetCursor, UpdateBiosCursor, Random, XorAttackMark
	PUBLIC XorPlayerMark, ReadWriteFile, ClearBottomLines, PrintBcdByte, WaitKey, SetTextNormal
	PUBLIC SetTextWarning, PutChar
ASSUME CS:CODE, DS:DATA
; NameStrTbl: the name table printed by PrintNameStr: a 0 byte, then zero-terminated strings numbered from 1:
; 1-18 terrain ("IN THE WATER." ... "ON COBBLE."), 19-28 weapons (HANDS ... QUICK SWORD),
; 29-35 armour (SKIN ... POWER), 36-45 spells (NONE ... KILL), 46-53 items (RING ... ANKH),
; 54-61 special items (RED GEM ... TRI-LITHIUM), 62-67 attributes (STRENGTH ... INTELL.),
; 68-71 races (HUMAN ... HOBBIT), 72-75 classes (FIGHTER ... THIEF).
NameStrTbl label byte
	db 0h,49h,4Eh,20h,54h,48h,45h,20h,57h,41h,54h,45h,52h,2Eh,0h,49h	;@4C60
	db 4Eh,20h,41h,20h,4Dh,41h,52h,53h,48h,2Eh,0h,4Fh,4Eh,20h,47h,52h	;@4C70
	db 41h,53h,53h,2Eh,0h,49h,4Eh,20h,57h,4Fh,4Fh,44h,53h,2Eh,0h,49h	;@4C80
	db 4Eh,20h,54h,48h,45h,20h,4Dh,54h,53h,2Eh,0h,4Eh,45h,41h,52h,20h	;@4C90
	db 41h,20h,56h,49h,4Ch,4Ch,41h,47h,45h,2Eh,0h,4Eh,45h,41h,52h,20h	;@4CA0
	db 41h,20h,54h,4Fh,57h,4Eh,45h,2Eh,0h,4Eh,45h,41h,52h,20h,41h,20h	;@4CB0
	db 54h,4Fh,57h,45h,52h,2Eh,0h,4Eh,45h,41h,52h,20h,41h,20h,43h,41h	;@4CC0
	db 53h,54h,4Ch,45h,2Eh,0h,4Eh,45h,41h,52h,20h,41h,20h,44h,55h,4Eh	;@4CD0
	db 47h,45h,4Fh,4Eh,2Eh,0h,4Eh,45h,41h,52h,20h,41h,20h,53h,49h,47h	;@4CE0
	db 4Eh,2Eh,0h,4Eh,45h,41h,52h,20h,41h,20h,48h,4Fh,52h,53h,45h,2Eh	;@4CF0
	db 0h,4Eh,45h,41h,52h,20h,41h,20h,46h,52h,49h,47h,41h,54h,45h,2Eh	;@4D00
	db 0h,4Eh,45h,41h,52h,20h,41h,20h,50h,4Ch,41h,4Eh,45h,2Eh,0h,4Eh	;@4D10
	db 45h,41h,52h,20h,41h,20h,52h,4Fh,43h,4Bh,45h,54h,2Eh,0h,4Eh,45h	;@4D20
	db 41h,52h,20h,41h,52h,4Dh,4Fh,55h,52h,2Eh,0h,4Eh,45h,41h,52h,20h	;@4D30
	db 41h,20h,48h,4Fh,4Ch,45h,2Eh,0h,4Fh,4Eh,20h,43h,4Fh,42h,42h,4Ch	;@4D40
	db 45h,2Eh,0h,48h,41h,4Eh,44h,53h,0h,44h,41h,47h,47h,45h,52h,0h	;@4D50
	db 4Dh,41h,43h,45h,0h,41h,58h,45h,0h,42h,4Fh,57h,0h,53h,57h,4Fh	;@4D60
	db 52h,44h,0h,47h,52h,45h,41h,54h,20h,53h,57h,4Fh,52h,44h,0h,4Ch	;@4D70
	db 49h,47h,48h,54h,20h,53h,57h,4Fh,52h,44h,0h,50h,48h,41h,53h,45h	;@4D80
	db 52h,0h,51h,55h,49h,43h,4Bh,20h,53h,57h,4Fh,52h,44h,0h,53h,4Bh	;@4D90
	db 49h,4Eh,0h,43h,4Ch,4Fh,54h,48h,0h,4Ch,45h,41h,54h,48h,45h,52h	;@4DA0
	db 0h,43h,48h,41h,49h,4Eh,0h,50h,4Ch,41h,54h,45h,0h,52h,45h,46h	;@4DB0
	db 4Ch,45h,43h,54h,0h,50h,4Fh,57h,45h,52h,0h,4Eh,4Fh,4Eh,45h,0h	;@4DC0
	db 4Ch,49h,47h,48h,54h,0h,44h,4Fh,57h,4Eh,20h,4Ch,41h,44h,44h,45h	;@4DD0
	db 52h,0h,55h,50h,20h,4Ch,41h,44h,44h,45h,52h,0h,50h,41h,53h,53h	;@4DE0
	db 57h,41h,4Ch,4Ch,0h,53h,55h,52h,46h,41h,43h,45h,0h,50h,52h,41h	;@4DF0
	db 59h,45h,52h,0h,4Dh,41h,47h,49h,43h,20h,4Dh,49h,53h,53h,49h,4Ch	;@4E00
	db 45h,0h,42h,4Ch,49h,4Eh,4Bh,0h,4Bh,49h,4Ch,4Ch,0h,52h,49h,4Eh	;@4E10
	db 47h,0h,57h,41h,4Eh,44h,0h,53h,54h,41h,46h,46h,0h,42h,4Fh,4Fh	;@4E20
	db 54h,53h,0h,43h,4Ch,4Fh,41h,4Bh,0h,48h,45h,4Ch,4Dh,0h,47h,45h	;@4E30
	db 4Dh,0h,41h,4Eh,4Bh,48h,0h,52h,45h,44h,20h,47h,45h,4Dh,0h,53h	;@4E40
	db 4Bh,55h,4Ch,4Ch,20h,4Bh,45h,59h,0h,47h,52h,45h,45h,4Eh,20h,47h	;@4E50
	db 45h,4Dh,0h,42h,52h,41h,53h,53h,20h,42h,55h,54h,54h,4Fh,4Eh,0h	;@4E60
	db 42h,4Ch,55h,45h,20h,54h,41h,53h,53h,4Ch,45h,0h,53h,54h,52h,41h	;@4E70
	db 4Eh,47h,45h,20h,43h,4Fh,49h,4Eh,0h,47h,52h,45h,45h,4Eh,20h,49h	;@4E80
	db 44h,4Fh,4Ch,0h,54h,52h,49h,2Dh,4Ch,49h,54h,48h,49h,55h,4Dh,0h	;@4E90
	db 53h,54h,52h,45h,4Eh,47h,54h,48h,0h,41h,47h,49h,4Ch,49h,54h,59h	;@4EA0
	db 0h,53h,54h,41h,4Dh,49h,4Eh,41h,0h,43h,48h,41h,52h,49h,53h,4Dh	;@4EB0
	db 41h,0h,57h,49h,53h,44h,4Fh,4Dh,0h,49h,4Eh,54h,45h,4Ch,4Ch,2Eh	;@4EC0
	db 0h,48h,55h,4Dh,41h,4Eh,0h,45h,4Ch,46h,0h,44h,57h,41h,52h,46h	;@4ED0
	db 0h,48h,4Fh,42h,42h,49h,54h,0h,46h,49h,47h,48h,54h,45h,52h,0h	;@4EE0
	db 43h,4Ch,45h,52h,49h,43h,0h,57h,49h,5Ah,41h,52h,44h,0h,54h,48h	;@4EF0
	db 49h,45h,46h,0h	;@4F00
; FileFunc/FileByteCount/FileDtaOfs: ReadWriteFile's saved arguments (written through CS): DOS FCB function (AH),
; record count (CX), DTA offset (DX).
FileFunc label byte
	db 0h	;@4F04
FileByteCount label byte
	db 0h,0h	;@4F05
FileDtaOfs label byte
	db 0h,0h	;@4F07
; ArrowScanTbl: (scan code, key) pairs for the arrow keys, read by ReadKey as ArrowScanTbl[bx] / ArrowKeyTbl[bx]:
; Up 48h -> 0Eh (north), Down 50h -> 19h (south), Right 4Dh -> 05h (east), Left 4Bh -> 17h
; (west): the direction keys KeyNorth-KeyWest.
ArrowScanTbl label byte
	db 48h	;@4F09
ArrowKeyTbl label byte
	db 0Eh,50h,19h,4Dh,5h,4Bh,17h	;@4F0A
;------------------------------------------------------------------------------
; DirToPlayer: direction from monster DI to the player on the wrapping 64x64 map:
; DeltaX = sign(PlayerX - MonsterX[DI]), DeltaY = sign(PlayerY - MonsterY[DI]), each
; 0, 1 or FFh. The difference is shifted left 2 first, so bit 5 becomes the
; sign: the shorter way round the map wins. (stc before sub does nothing: a
; leftover of 6502 SEC/SBC.)
; In: DI = monster index. Out: DeltaX, DeltaY, AL = DeltaY. Uses: AL.
;------------------------------------------------------------------------------
DirToPlayer:	stc	;@4F11
	mov al, byte ptr PlayerX	;@4F12
	sub al, byte ptr MonsterX[di]	;@4F15
	add al, al	;@4F19
	add al, al	;@4F1B
	call SignOf	;@4F1D
	mov byte ptr DeltaX, al	;@4F20
	stc	;@4F23
	mov al, byte ptr PlayerY	;@4F24
	sub al, byte ptr MonsterY[di]	;@4F27
	add al, al	;@4F2B
	add al, al	;@4F2D
	call SignOf	;@4F2F
	mov byte ptr DeltaY, al	;@4F32
	ret	;@4F35
;------------------------------------------------------------------------------
; DistToPlayer: distance from monster DI to the player, not wrapped and not reduced
; to a sign: DeltaX = PlayerX - MonsterX[DI], DeltaY = PlayerY - MonsterY[DI].
; In: DI = monster index. Out: DeltaX, DeltaY, AL = DeltaY. Uses: AL.
;------------------------------------------------------------------------------
DistToPlayer:	stc	;@4F36
	mov al, byte ptr PlayerX	;@4F37
	sub al, byte ptr MonsterX[di]	;@4F3A
	mov byte ptr DeltaX, al	;@4F3E
	stc	;@4F41
	mov al, byte ptr PlayerY	;@4F42
	sub al, byte ptr MonsterY[di]	;@4F45
	mov byte ptr DeltaY, al	;@4F49
	ret	;@4F4C
;------------------------------------------------------------------------------
; ReadKey: poll the keyboard (does not wait). Returns AH = 0 when there is no key
; (AL is then meaningless), else AH = FFh and AL = the key, letters in upper
; case; Escape gives AX = FF1Bh. The rest of the BIOS buffer is thrown away
; (no type-ahead). Special keys, handled here and reported as "no key":
;   Ctrl-S          toggle the sound (SoundOff)
;   Ctrl-Right/Left speed setting SpeedSetting -/+ 200h (within SpeedMin..3A00h), then
;                   CalcDelayTbl rescales the delay table
; The arrow keys become the direction keys 0Eh/19h/05h/17h (table ArrowScanTbl);
; typed Ctrl-E, Ctrl-N and Ctrl-W give AX = FF00h so that only the arrows make
; those codes (Ctrl-Y = 19h, south, is not filtered). Other extended keys give
; FF00h too.
; In: -. Out: AX. Uses: AX (saves BX).
;------------------------------------------------------------------------------
ReadKey:	push bx	;@4F4D
	mov ah, 1	;@4F4E
	int 16h		; BIOS keyboard: key waiting? (ZF=1: none)	;@4F50
	mov ah, 0	;@4F52
	je ReadKey_Upcase	;@4F54
	int 16h		; BIOS keyboard: read key, AH = scan code, AL = ASCII	;@4F56
	cmp al, 5	;@4F58
	je ReadKey_Ignore	;@4F5A
	cmp al, 0Eh	;@4F5C
	je ReadKey_Ignore	;@4F5E
	cmp al, 17h	;@4F60
	jne ReadKey_Flush	;@4F62
ReadKey_Ignore:	mov al, 0		; Ctrl-E/N/W typed: return FF00h	;@4F64
	jmp ReadKey_Got	;@4F66
; empty the BIOS keyboard buffer
ReadKey_Flush:	push ax	;@4F69
ReadKey_FlushLoop:	mov ah, 1	;@4F6A
	int 16h	;@4F6C
	je ReadKey_Check	;@4F6E
	mov ah, 0	;@4F70
	int 16h	;@4F72
	jmp ReadKey_FlushLoop	;@4F74
ReadKey_Check:	pop ax	;@4F76
	cmp al, 13h		; Ctrl-S	;@4F77
	jne ReadKey_NotCtrlS	;@4F79
	xor byte ptr SoundOff, 0FFh	;@4F7B
	mov ah, 0	;@4F80
	jmp ReadKey_Done	;@4F82
ReadKey_NotCtrlS:	cmp al, 0	;@4F85
	jne ReadKey_Got		; ordinary key	;@4F87
; Ctrl-Right: faster (smaller delays). BUG: from the start value 00FFh (set by
; SetDefaultSpeed) the subtraction wraps to FEFFh, which passes the unsigned check, and
; CalcDelayTbl's div then overflows. In DOSBox the game hangs (checked in play).
	cmp ax, 7400h	;@4F89
	jne ReadKey_CtrlLeft	;@4F8C
	mov ax, word ptr SpeedSetting	;@4F8E
	sub ax, 200h	;@4F91
	cmp ax, word ptr SpeedMin	;@4F94
	jb ReadKey_NoKey	;@4F98
	mov word ptr SpeedSetting, ax	;@4F9A
	jmp ReadKey_NewSpeed	;@4F9D
ReadKey_CtrlLeft:	cmp ax, 7300h		; Ctrl-Left: slower	;@4FA0
	jne ReadKey_Arrows	;@4FA3
	mov ax, word ptr SpeedSetting	;@4FA5
	add ax, 200h	;@4FA8
	cmp ax, 3A00h	;@4FAB
	ja ReadKey_NoKey	;@4FAE
	mov word ptr SpeedSetting, ax	;@4FB0
ReadKey_NewSpeed:	call CalcDelayTbl		; rescale the delay table DelayTbl	;@4FB3
ReadKey_NoKey:	mov ah, 0	;@4FB6
	jmp ReadKey_Done	;@4FB8
; other extended key: look the scan code up in the arrow table
ReadKey_Arrows:	mov bx, 6	;@4FBB
ReadKey_ArrowLoop:	cmp ah, byte ptr cs:ArrowScanTbl[bx]	;@4FBE
	je ReadKey_Arrow	;@4FC3
	sub bx, 2	;@4FC5
	js ReadKey_Got	;@4FC8
	jmp ReadKey_ArrowLoop	;@4FCA
ReadKey_Arrow:	mov al, byte ptr cs:ArrowKeyTbl[bx]	;@4FCC
ReadKey_Got:	mov ah, 0FFh	;@4FD1
ReadKey_Upcase:	cmp al, 61h		; 'a'-'z' to upper case	;@4FD3
	jb ReadKey_Done	;@4FD5
	cmp al, 7Ah	;@4FD7
	ja ReadKey_Done	;@4FD9
	and al, 0DFh	;@4FDB
ReadKey_Done:	pop bx	;@4FDD
	ret	;@4FDE
;------------------------------------------------------------------------------
; PrintInline: print the zero-terminated text that follows the call (in CS) with
; PrintChar, then return to the byte after the 0. Bit 7 of each character is
; ignored, so 8Dh = CR. InlineTextPtr holds the text pointer while printing.
; In: cursor CursorCol/CursorRow. Out: cursor advanced, SI = 0.
; Uses: AX, BX, SI.
;------------------------------------------------------------------------------
PrintInline:	call UpdateBiosCursor	;@4FDF
	pop ax		; AX = return address = the text	;@4FE2
	mov word ptr InlineTextPtr, ax	;@4FE3
	mov si, 0	;@4FE6
	jmp PrintInline_Loop	;@4FE9
PrintInline_Next:	inc word ptr InlineTextPtr	;@4FEC
PrintInline_Loop:	mov bx, word ptr InlineTextPtr	;@4FF0
	mov al, byte ptr cs:[bx+si]	;@4FF4
	cmp al, 0	;@4FF7
	je PrintInline_Done	;@4FF9
	call PrintChar	;@4FFB
	jmp PrintInline_Next	;@4FFE
PrintInline_Done:	inc bx	;@5000
	push bx		; return past the 0	;@5001
	ret	;@5002
;------------------------------------------------------------------------------
; PrintChar: print the character AL (bit 7 ignored) at the cursor and advance it.
; 0Dh = CR: back to column TextLeftCol and down a line; 0Ah = line feed. Past
; column TextRightCol the text wraps to the next line. Moving below row 23 scrolls
; the message window (rows 20-23, columns 0..TextRightCol) up one line. The colour
; (graphics mode) or attribute (text mode) is TextAttr.
; In: AL, CursorCol/CursorRow. Out: cursor moved (and the BIOS cursor updated).
; Saves all registers.
;------------------------------------------------------------------------------
PrintChar:	push bx	;@5003
	push cx	;@5004
	push dx	;@5005
	push ax	;@5006
	and al, 7Fh	;@5007
	cmp al, 0Dh	;@5009
	jne PrintChar_NotCR	;@500B
PrintChar_CR:	mov al, byte ptr TextLeftCol	;@500D
	mov byte ptr CursorCol, al	;@5010
	jmp PrintChar_LF	;@5013
PrintChar_NotCR:	cmp al, 0Ah	;@5016
	jne PrintChar_Glyph	;@5018
PrintChar_LF:	inc byte ptr CursorRow	;@501A
	cmp byte ptr CursorRow, 18h	;@501E
	jne PrintChar_Done	;@5023
; row 24 reached: scroll rows 20-23 (columns 0..TextRightCol) up one line, stay on row 23
	mov al, 1	;@5025
	mov cx, 1400h	;@5027
	mov dh, 17h	;@502A
	mov dl, byte ptr TextRightCol	;@502C
	mov bh, 0		; fill with attribute / colour 0	;@5030
	mov ah, 6	;@5032
	int 10h		; BIOS scroll window up: AL lines, CH,CL to DH,DL	;@5034
	dec byte ptr CursorRow	;@5036
	jmp PrintChar_Done	;@503A
PrintChar_Glyph:	mov ah, 9	;@503D
	mov cx, 1	;@503F
	mov bl, byte ptr TextAttr	;@5042
	mov bh, 0	;@5046
	int 10h		; BIOS write char AL, attribute BL, CX times, page BH	;@5048
	inc byte ptr CursorCol	;@504A
	mov al, byte ptr TextRightCol	;@504E
	cmp al, byte ptr CursorCol	;@5051
	jb PrintChar_CR		; past the right edge: new line	;@5055
PrintChar_Done:	call UpdateBiosCursor	;@5057
	pop ax	;@505A
	pop dx	;@505B
	pop cx	;@505C
	pop bx	;@505D
	ret	;@505E
;------------------------------------------------------------------------------
; PrintSex: print the player's sex: "MALE" if PlayerSex = 'M', else "FEMALE".
; In: PlayerSex. Out: -. Uses: AX, BX, SI.
;------------------------------------------------------------------------------
PrintSex:	mov al, byte ptr PlayerSex	;@505F
	cmp al, 4Dh		; 'M'	;@5062
	jne PrintSex_Female	;@5064
	call PrintInline	;@5066
	db 4Dh,41h,4Ch,45h,0h	;@5069
	ret	;@506E
PrintSex_Female:	call PrintInline	;@506F
	db 46h,45h,4Dh,41h,4Ch,45h,0h	;@5072
	ret	;@5079
;------------------------------------------------------------------------------
; PrintPlayerName: print the player's name, the zero-terminated string at PlayerRecord (the
; start of the player record read from the PLAYER file).
; In: PlayerRecord. Out: -. Uses: AL, BX.
;------------------------------------------------------------------------------
PrintPlayerName:	mov bx, 0	;@507A
PrintPlayerName_Loop:	mov al, byte ptr PlayerRecord[bx]	;@507D
	cmp al, 0	;@5081
	je PrintPlayerName_Done	;@5083
	call PrintChar	;@5085
	inc bx	;@5088
	jmp PrintPlayerName_Loop	;@5089
PrintPlayerName_Done:	ret	;@508B
;------------------------------------------------------------------------------
; PrintNameStr: print string number AL (1-75) of the name table NameStrTbl (terrain,
; weapons, armour, spells, items, attributes, races, classes). AL = 0 would
; skip 65536 strings: callers never pass 0, presumably.
; In: AL = string number. Out: -. Uses: AX, SI, DI.
;------------------------------------------------------------------------------
PrintNameStr:	mov ah, 0	;@508C
	mov si, ax		; SI = strings still to skip	;@508E
	mov di, 0	;@5090
PrintNameStr_Scan:	cmp byte ptr cs:NameStrTbl[di], 0	;@5093
	je PrintNameStr_EndStr	;@5099
PrintNameStr_SkipChar:	inc di	;@509B
	jmp PrintNameStr_Scan	;@509C
PrintNameStr_EndStr:	dec si		; at a 0: one string fewer to skip	;@509E
	je PrintNameStr_Print	;@509F
	jmp PrintNameStr_SkipChar	;@50A1
PrintNameStr_Print:	inc di	;@50A3
	mov al, byte ptr cs:NameStrTbl[di]	;@50A4
	cmp al, 0	;@50A9
	je PrintNameStr_Done	;@50AB
	call PrintChar	;@50AD
	jmp PrintNameStr_Print	;@50B0
PrintNameStr_Done:	ret	;@50B2
;------------------------------------------------------------------------------
; GetMapSquare: read the map byte at (LookX, LookY) from the 64x64 map buffer
; (pointer MapBufPtr): address = MapBufPtr + 64*LookY + LookX. The address is left
; in the word MapCellPtr and SI = 0, so callers write the square with
; "mov bx, MapCellPtr / mov [bx+si], al". No range check or wrap.
; In: LookX = x, LookY = y. Out: AL = map byte (flags set by or al,al),
; MapCellPtr = its address, SI = 0. Uses: AX, SI (saves BX, CX).
;------------------------------------------------------------------------------
GetMapSquare:	push bx	;@50B3
	push cx	;@50B4
	mov ah, 0	;@50B5
	mov al, byte ptr LookY	;@50B7
	mov cl, 6	;@50BA
	shl ax, cl		; y*64	;@50BC
	mov bh, 0	;@50BE
	mov bl, byte ptr LookX	;@50C0
	add bx, ax	;@50C4
	add bx, word ptr MapBufPtr	;@50C6
	mov word ptr MapCellPtr, bx	;@50CA
	mov al, byte ptr [bx]	;@50CE
	mov si, 0	;@50D0
	pop cx	;@50D3
	pop bx	;@50D4
	or al, al	;@50D5
	ret	;@50D7
;------------------------------------------------------------------------------
; SignOf: sign of AL: 0 stays 0, 1-7Fh gives 1, 80h-FFh gives FFh.
; In: AL. Out: AL. Uses: AL.
;------------------------------------------------------------------------------
SignOf:	cmp al, 0	;@50D8
	je SignOf_Ret	;@50DA
	jns SignOf_Plus	;@50DC
	mov al, 0FFh	;@50DE
	ret	;@50E0
SignOf_Plus:	mov al, 1	;@50E1
SignOf_Ret:	ret		; also the exit of AbsOf	;@50E3
; Dead code, nothing calls it: another sign routine, 0 -> 0, 1-1Fh -> 1, 20h-FFh -> FFh
; (cmp al,0 / je 50E3 / cmp al,20h / jb 50E1 / mov al,0FFh / ret).
	db 3Ch,0h,74h,0FBh,3Ch,20h,72h,0F5h,0B0h,0FFh,0C3h	;@50E4
;------------------------------------------------------------------------------
; AbsOf: absolute value of the signed byte AL.
; In: AL. Out: AL. Uses: AL.
;------------------------------------------------------------------------------
AbsOf:	cmp al, 80h	;@50EF
	jb SignOf_Ret	;@50F1
	xor al, 0FFh	;@50F3
	clc	;@50F5
	adc al, 1		; two's complement (6502 EOR #FF / CLC / ADC #1)	;@50F6
	ret	;@50F8
;------------------------------------------------------------------------------
; DrawStatusLines: draw the status lines at column 30, rows 20-23: "H.P.=", "FOOD=",
; "EXP.=", "GOLD=", each a 4-digit BCD number (hit points and food shown in
; the warning colour when below 100). Then the text window is narrowed to
; columns 0-29 (TextRightCol = 29) and the cursor goes to (0, 23).
; In: HitPointsHi-GoldLo (BCD, high byte first). Out: cursor, TextRightCol.
; Uses: AX, BX, SI, DI.
;------------------------------------------------------------------------------
DrawStatusLines:	mov al, 28h	;@50F9
	mov byte ptr TextRightCol, al	;@50FB
	mov byte ptr CursorCol, 1Eh	;@50FE
	mov al, 14h	;@5103
	mov byte ptr CursorRow, al	;@5105
	call PrintInline	;@5108
	db 48h,2Eh,50h,2Eh,3Dh,0h	;@510B
	mov bh, 0	;@5111
	mov bl, byte ptr HitPointsLo	;@5113
	mov di, bx	;@5117
	mov al, byte ptr HitPointsHi	;@5119
	or al, al	;@511C
	jne DrawStatus_PrintHP	;@511E
	call SetTextWarning		; below 100: warning colour	;@5120
DrawStatus_PrintHP:	call PrintBcdWord	;@5123
	call SetTextNormal	;@5126
	mov al, 1Eh	;@5129
	mov byte ptr CursorCol, al	;@512B
	mov byte ptr CursorRow, 15h	;@512E
	call PrintInline	;@5133
	db 46h,4Fh,4Fh,44h,3Dh,0h	;@5136
	mov bh, 0	;@513C
	mov bl, byte ptr FoodLo	;@513E
	mov di, bx	;@5142
	mov al, byte ptr FoodHi	;@5144
	or al, al	;@5147
	jne DrawStatus_PrintFood	;@5149
	call SetTextWarning	;@514B
DrawStatus_PrintFood:	call PrintBcdWord	;@514E
	call SetTextNormal	;@5151
	mov al, 1Eh	;@5154
	mov byte ptr CursorCol, al	;@5156
	mov byte ptr CursorRow, 16h	;@5159
	call PrintInline	;@515E
	db 45h,58h,50h,2Eh,3Dh,0h	;@5161
	mov al, byte ptr ExpHi	;@5167
	mov bh, 0	;@516A
	mov bl, byte ptr ExpLo	;@516C
	mov di, bx	;@5170
	call PrintBcdWord	;@5172
	mov al, 1Eh	;@5175
	mov byte ptr CursorCol, al	;@5177
	mov byte ptr CursorRow, 17h	;@517A
	call PrintInline	;@517F
	db 47h,4Fh,4Ch,44h,3Dh,0h	;@5182
	mov al, byte ptr GoldHi	;@5188
	mov bh, 0	;@518B
	mov bl, byte ptr GoldLo	;@518D
	mov di, bx	;@5191
	call PrintBcdWord	;@5193
	mov al, 1Dh	;@5196
	mov byte ptr TextRightCol, al	;@5198
	mov di, 0	;@519B
	mov si, 17h	;@519E
	call SetCursor	;@51A1
	ret	;@51A4
;------------------------------------------------------------------------------
; PrintBcdWord: print a 4-digit BCD number: AL = high two digits, low byte of DI =
; low two digits.
; In: AL, DI. Out: -. Saves all registers.
;------------------------------------------------------------------------------
PrintBcdWord:	push ax	;@51A5
	call PrintBcdByte	;@51A6
	mov ax, di	;@51A9
	call PrintBcdByte	;@51AB
	pop ax	;@51AE
	ret	;@51AF
;------------------------------------------------------------------------------
; ReadTwoDigits: read a two-digit decimal number from the keyboard, echoing each digit
; (other keys are ignored; no Escape, no backspace). AmountHi = temporary.
; In: -. Out: AL = the number in BCD (tens in the high nibble), AmountHi.
; Uses: AX.
;------------------------------------------------------------------------------
ReadTwoDigits:	call ReadKey	;@51B0
	cmp ah, 0FFh	;@51B3
	jne ReadTwoDigits	;@51B6
	cmp al, 30h	;@51B8
	jb ReadTwoDigits	;@51BA
	cmp al, 39h	;@51BC
	ja ReadTwoDigits	;@51BE
	call PrintChar	;@51C0
	sub al, 30h	;@51C3
	add al, al	;@51C5
	add al, al	;@51C7
	add al, al	;@51C9
	add al, al		; tens digit << 4	;@51CB
	mov byte ptr AmountHi, al	;@51CD
ReadTwoDigits_Units:	call ReadKey	;@51D0
	cmp ah, 0FFh	;@51D3
	jne ReadTwoDigits_Units	;@51D6
	cmp al, 30h	;@51D8
	jb ReadTwoDigits_Units	;@51DA
	cmp al, 39h	;@51DC
	ja ReadTwoDigits_Units	;@51DE
	call PrintChar	;@51E0
	sub al, 30h	;@51E3
	clc	;@51E5
	adc al, byte ptr AmountHi	;@51E6
	ret	;@51EA
;------------------------------------------------------------------------------
; SetCursor: set the cursor to column DI, row SI (and move the BIOS cursor there).
; In: DI = column, SI = row. Out: CursorCol, CursorRow. Saves all registers.
;------------------------------------------------------------------------------
SetCursor:	push bx	;@51EB
	mov bx, di	;@51EC
	mov byte ptr CursorCol, bl	;@51EE
	mov bx, si	;@51F2
	mov byte ptr CursorRow, bl	;@51F4
	call UpdateBiosCursor	;@51F8
	pop bx	;@51FB
	ret	;@51FC
;------------------------------------------------------------------------------
; UpdateBiosCursor: move the BIOS cursor (page 0) to CursorCol/CursorRow.
; In: CursorCol = column, CursorRow = row. Out: -. Saves all registers.
;------------------------------------------------------------------------------
UpdateBiosCursor:	push ax	;@51FD
	push bx	;@51FE
	push cx	;@51FF
	push dx	;@5200
	mov dh, byte ptr CursorRow	;@5201
	mov dl, byte ptr CursorCol	;@5205
	mov cx, 1		; (not used by this BIOS call)	;@5209
	mov bh, 0	;@520C
	mov ah, 2	;@520E
	int 10h		; BIOS set cursor position: page BH, row DH, column DL	;@5210
	pop dx	;@5212
	pop cx	;@5213
	pop bx	;@5214
	pop ax	;@5215
	ret	;@5216
;------------------------------------------------------------------------------
; Random: random number: an additive generator over the 6-byte history at
; RandSeed-RandSeed5 (newest first). new = RandSeed1 + RandSeed4 + RandSeed5 + 1 (the first
; carry is set, later carries ripple through the adc chain); the history moves
; down one byte and the new value is stored at RandSeed.
; In: -. Out: AL = random byte, flags from or al,al (SF = bit 7).
; Uses: AL (saves AH, BX).
;------------------------------------------------------------------------------
Random:	push ax	;@5217
	push bx	;@5218
	stc	;@5219
	mov al, byte ptr RandSeed1	;@521A
	adc al, byte ptr RandSeed4	;@521D
	adc al, byte ptr RandSeed5	;@5221
	mov byte ptr RandSeed, al	;@5225
	mov bx, 4		; shift RandSeed..RandSeed4 up to RandSeed1..RandSeed5	;@5228
Random_Shift:	mov al, byte ptr RandSeed[bx]	;@522B
	mov byte ptr RandSeed1[bx], al	;@522F
	dec bx	;@5233
	jns Random_Shift	;@5234
	pop bx	;@5236
	pop ax	;@5237
	mov al, byte ptr RandSeed	;@5238
	or al, al	;@523B
	ret	;@523D
;------------------------------------------------------------------------------
; XorAttackMark: XOR the attack mark (a filled circle, bitmap AttackMarkBmp) onto the map tile
; next to the player in direction (DeltaX, DeltaY); the player's tile is at
; pixel (90h, 50h) = column 9, row 5 of the window. A vertical direction wins
; over a horizontal one. Called in pairs around a sound: draw, sound, erase.
; XorPlayerMark: the same on the player's own tile.
; In: DeltaX, DeltaY (each 0, 1 or FFh). Out: -. Uses: AX, BX, CX.
;------------------------------------------------------------------------------
XorAttackMark:	nop	;@523E
	mov al, byte ptr DeltaY	;@523F
	cmp al, 1	;@5242
	je XorMark_South	;@5244
	cmp al, 0FFh	;@5246
	je XorMark_North	;@5248
	mov al, byte ptr DeltaX	;@524A
	cmp al, 1	;@524D
	je XorMark_East	;@524F
	cmp al, 0FFh	;@5251
	je XorMark_West	;@5253
; XorPlayerMark (entry point): the player's tile
XorPlayerMark:	mov ax, 90h	;@5255
	mov bx, 50h	;@5258
	jmp XorMark_Draw	;@525B
XorMark_South:	mov ax, 90h		; south	;@525E
	mov bx, 60h	;@5261
	jmp XorMark_Draw	;@5264
XorMark_North:	mov ax, 90h		; north	;@5267
	mov bx, 40h	;@526A
	jmp XorMark_Draw	;@526D
XorMark_East:	mov ax, 0A0h		; east	;@5270
	mov bx, 50h	;@5273
	jmp XorMark_Draw	;@5276
XorMark_West:	mov ax, 80h		; west	;@5279
	mov bx, 50h	;@527C
XorMark_Draw:	db 2Eh		; cs: prefix, which MASM drops on lea	;@527F
	lea cx, AttackMarkBmp	;@5280
	call XorBitmapCS	;@5284
	ret	;@5287
; AttackMarkBmp: the attack mark, a 16x16 bitmap record (header 04h,10h; 16 lines of 4 bytes) in
; colour 3: a filled circle.
AttackMarkBmp label byte
	db 4h,10h,0h,0Fh,0F0h,0h,0h,0FFh,0FFh,0h,3h,0FFh,0FFh,0C0h,0Fh,0FFh	;@5288
	db 0FFh,0F0h,0Fh,0FFh,0FFh,0F0h,3Fh,0FFh,0FFh,0FCh,3Fh,0FFh,0FFh,0FCh,3Fh,0FFh	;@5298
	db 0FFh,0FCh,3Fh,0FFh,0FFh,0FCh,3Fh,0FFh,0FFh,0FCh,3Fh,0FFh,0FFh,0FCh,0Fh,0FFh	;@52A8
	db 0FFh,0F0h,0Fh,0FFh,0FFh,0F0h,3h,0FFh,0FFh,0C0h,0h,0FFh,0FFh,0h,0h,0Fh	;@52B8
	db 0F0h,0h	;@52C8
;------------------------------------------------------------------------------
; ReadWriteFile: read or write a file with a DOS FCB. The 8-character file name (no
; extension, padded with blanks) follows the call; the routine returns past it.
; Builds the FCB at Fcb (default drive, extension "   "), opens the file
; (if that fails: "WRONG DISK", wait for Escape, retry), sets the DTA to DX
; (in segment B800h, the CGA screen, when the name starts with "PI": the PIC*
; pictures), record size 1, then does the random block function AH for CX
; bytes from record 0, and closes the file. Errors of the transfer and the
; close are not checked.
; In: AH = 27h (read) or 28h (write), CX = byte count, DX = buffer offset.
; Out: -. Uses: BX (saves AX, CX, DX, SI, DI, ES).
;------------------------------------------------------------------------------
ReadWriteFile:	pop bx	;@52CA
	add bx, 8	;@52CB
	push bx		; return address = past the name	;@52CE
	push ax	;@52CF
	push cx	;@52D0
	push dx	;@52D1
	push si	;@52D2
	push di	;@52D3
	push es	;@52D4
; keep the arguments in CS variables (self-modified data)
	mov byte ptr cs:FileFunc, ah	;@52D5
	mov word ptr cs:FileByteCount, cx	;@52DA
	mov word ptr cs:FileDtaOfs, dx	;@52DF
	mov si, 24h		; clear the FCB, 25h bytes	;@52E4
RWFile_ClearFcb:	mov byte ptr Fcb[si], 0	;@52E7
	dec si	;@52EC
	jns RWFile_ClearFcb	;@52ED
	mov si, bx	;@52EF
	mov bx, 8	;@52F1
	sub si, bx		; SI = the inline name	;@52F4
RWFile_CopyName:	dec bx	;@52F6
	mov al, byte ptr cs:[bx+si]	;@52F7
	mov byte ptr FcbName[bx], al	;@52FA
	jne RWFile_CopyName		; flags from dec bx: copies bytes 7..0	;@52FE
	mov byte ptr FcbExt, 20h	;@5300
	mov byte ptr FcbExt1, 20h	;@5305
	mov byte ptr FcbExt2, 20h	;@530A
RWFile_Open:	mov ah, 0Fh	;@530F
	lea dx, Fcb	;@5311
	int 21h		; DOS open file (FCB), AL = 0 if found	;@5315
	cmp al, 0	;@5317
	je RWFile_Opened	;@5319
	call PrintInline	;@531B
	db 0Dh,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h	;@531E
	db 57h,52h,4Fh,4Eh,47h,20h,44h,49h,53h,4Bh,0h	;@532E
RWFile_WaitEsc:	call ReadKey	;@5339
	cmp ax, 0FF1Bh		; Escape	;@533C
	jne RWFile_WaitEsc	;@533F
	jmp RWFile_Open	;@5341
RWFile_Opened:	mov dx, word ptr cs:FileDtaOfs	;@5343
	push ds	;@5348
	cmp word ptr FcbName, 4950h	; name starts with "PI"?	;@5349
	jne RWFile_SetDta	;@534F
	mov ax, 0B800h	;@5351
	mov ds, ax		; DTA in the CGA screen (the only DS change)	;@5354
RWFile_SetDta:	mov ah, 1Ah	;@5356
	int 21h		; DOS set DTA = DS:DX	;@5358
	pop ds	;@535A
	lea dx, Fcb	;@535B
	mov cx, word ptr cs:FileByteCount	;@535F
	mov word ptr FcbRecSize, 1		; FCB record size = 1 byte	;@5364
	mov ah, byte ptr cs:FileFunc	;@536A
	int 21h		; DOS random block read (27h) / write (28h), CX records	;@536F
	lea dx, Fcb	;@5371
	mov ah, 10h	;@5375
	int 21h		; DOS close file (FCB)	;@5377
	pop es	;@5379
	pop di	;@537A
	pop si	;@537B
	pop dx	;@537C
	pop cx	;@537D
	pop ax	;@537E
	ret	;@537F
; Dead code (HANDOFF lists it): a delay loop, AL times 256 iterations
; (push ax / push bx / mov bx,100h / dec bx / jnz / dec al / jnz / pop bx / pop ax / ret).
	db 50h,53h,0BBh,0h,1h,4Bh,75h,0FDh,0FEh,0C8h,75h,0F6h,5Bh,58h,0C3h	;@5380
;------------------------------------------------------------------------------
; ClearBottomLines: blank text rows 23 and 24 (40 spaces each, from column 0).
; In: -. Out: cursor at (40, 24). Saves all registers.
;------------------------------------------------------------------------------
ClearBottomLines:	mov byte ptr CursorRow, 17h	;@538F
	call ClearTextLine	;@5394
	mov byte ptr CursorRow, 18h	;@5397
	call ClearTextLine	;@539C
	ret	;@539F
;------------------------------------------------------------------------------
; ClearTextLine: print 40 spaces from column 0 of the cursor row.
; In: CursorRow. Out: CursorCol = 40. Saves all registers.
;------------------------------------------------------------------------------
ClearTextLine:	push ax	;@53A0
	push cx	;@53A1
	mov byte ptr CursorCol, 0	;@53A2
	mov al, 20h	;@53A7
	mov cx, 28h	;@53A9
ClearTextLine_Loop:	call PrintChar	;@53AC
	dec cx	;@53AF
	jne ClearTextLine_Loop	;@53B0
	pop cx	;@53B2
	pop ax	;@53B3
	ret	;@53B4
;------------------------------------------------------------------------------
; PrintBcdByte: print AL as two BCD digits (each nibble or 30h, so only 0-9 print as
; digits).
; In: AL. Out: -. Saves all registers.
;------------------------------------------------------------------------------
PrintBcdByte:	push ax	;@53B5
	mov ah, al	;@53B6
	shr al, 1	;@53B8
	shr al, 1	;@53BA
	shr al, 1	;@53BC
	shr al, 1	;@53BE
	or al, 30h	;@53C0
	call PrintChar	;@53C2
	mov al, ah	;@53C5
	and al, 0Fh	;@53C7
	or al, 30h	;@53C9
	call PrintChar	;@53CB
	pop ax	;@53CE
	ret	;@53CF
;------------------------------------------------------------------------------
; WaitKey: wait for a key (loops on ReadKey; Ctrl-S etc. are handled there).
; In: -. Out: AL = key (upper case), AH = FFh. Uses: AX.
;------------------------------------------------------------------------------
WaitKey:	call ReadKey	;@53D0
	cmp ah, 0FFh	;@53D3
	jne WaitKey	;@53D6
	ret	;@53D8
;------------------------------------------------------------------------------
; SetTextNormal: normal text colour: TextAttr = 0Fh (bright white in text mode; colour 3,
; white, in graphics mode). In: -. Out: TextAttr. Saves all registers.
;------------------------------------------------------------------------------
SetTextNormal:	mov byte ptr TextAttr, 0Fh	;@53D9
	ret	;@53DE
;------------------------------------------------------------------------------
; SetTextWarning: warning text colour: TextAttr = 2 (colour 2, magenta) in graphics mode,
; 70h (inverse video) in text mode (GraphicsMode = 0).
; In: GraphicsMode. Out: TextAttr. Saves all registers.
;------------------------------------------------------------------------------
SetTextWarning:	cmp byte ptr GraphicsMode, 0	;@53DF
	je SetTextWarn_TextMode	;@53E4
	mov byte ptr TextAttr, 2	;@53E6
	jmp SetTextWarn_Done	;@53EB
SetTextWarn_TextMode:	mov byte ptr TextAttr, 70h	;@53EE
SetTextWarn_Done:	ret	;@53F3
;------------------------------------------------------------------------------
; PutChar: print the character AL (just calls PrintChar).
; In: AL. Out: -. Saves all registers.
;------------------------------------------------------------------------------
PutChar:	call PrintChar	;@53F4
	ret	;@53F7
; zero padding up to 5400 (CHARGEN)
	db 0h,0h,0h,0h,0h,0h,0h,0h	;@53F8
CODE ENDS
END
