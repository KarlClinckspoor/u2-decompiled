; SHOPS.ASM: towns: pub (tips), temple, oracle, armour and weapon shops, transport.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 154E-2028.
;
; Overview: the shopkeepers that T)ransact reaches across a counter, plus the "print the n-th
; string" helpers used by the pub, the oracle and the townspeople's talk.
; - PrintTalkString prints the n-th string of the talk buffer (TLKxxx file at TalkBufPtr); called by T)ransact
;   in CMDMZ when the person transacted with is a townsperson. PrintCsTblString is the same for a table in CS.
; - ShopDispatch (jumped to from T)ransact in CMDMZ when the target is a merchant tile 68h behind a
;   counter) picks the shop from the map type MapType and the quarter of the 64x64 map the player
;   is in (PlayerX/PlayerY below or above 20h):
;       quarter      towne (MapType=2)   village/castle (other)
;       NW           weapons  ShopWeapons     oracle   ShopOracle
;       NE           armour   ShopArmour     food     ShopFood
;       SW           pub      ShopPub     wizard   ShopWizardSpells (magic store, Turkish patter)
;       SE           transport ShopTransport    cleric   ShopClericSpells (magic store)
;   Every shop ends with jmp EndCommand (end of turn).
; - Common pattern: ReadDigit reads one digit (ZF = 0 entered), CalcPrice computes the price of an item
;   into AmountHi:AmountLo (BCD, hundreds:units), PrintBcdWord prints it, ReadKey waits for 'Y', then PayPrice
;   takes the price from the gold (or prints "YOU DONT HAVE THAT MUCH!" and abandons the shop).
; Data: AmountHi/AmountLo (price, or a CS string table pointer as a word), Temp1F (item chosen),
; WeaponCounts/ArmourCounts/SpellCounts (weapon/armour/spell counts, BCD), FoodHi (food hundreds), PlayerSex (sex),
; PlayerClass (class), PlayerTile (transport). Strings are inline after call PrintInline; 0Dh/8Dh = new line.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN PlayerX:BYTE, PlayerY:BYTE, PlayerTile:BYTE, Temp1F:BYTE, Temp21:BYTE, DungeonLevel:BYTE
	EXTRN AmountHi:BYTE, AmountLo:BYTE, PlayerSex:BYTE, PlayerClass:BYTE, MapType:BYTE, FoodHi:BYTE
	EXTRN WeaponCounts:BYTE, ArmourCounts:BYTE, SpellCounts:BYTE, TalkBufPtr:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN EndCommand:NEAR, ReadDigit:NEAR, PayPrice:NEAR, CalcPrice:NEAR, ReadKey:NEAR, PrintInline:NEAR
	EXTRN PrintPlayerName:NEAR, PrintNameStr:NEAR, SignOf:NEAR, PrintBcdWord:NEAR, Random:NEAR, PutChar:NEAR
	PUBLIC PrintTalkString, ShopDispatch
ASSUME CS:CODE, DS:DATA

;------------------------------------------------------------------------------
; PrintTalkString: print string number AL (1-based) of the talk buffer at TalkBufPtr (DS): the
; text after the AL-th zero byte, up to the next zero, through PutChar.
; Called by T)ransact (CMDMZ 420E) with the person's tile - 80h. AL = 0 would
; skip 65536 strings (never happens, presumably).
; In: AL. Out: text printed. Uses: AX, SI, DI (ES saved).
;------------------------------------------------------------------------------
PrintTalkString:	nop	;@154E
	push es	;@154F
	mov ah, 0	;@1550
	mov si, ax	;@1552
	mov di, word ptr TalkBufPtr	;@1554
	push ds	;@1558
	pop es	;@1559
	jmp PrintNth_Skip	;@155A

;------------------------------------------------------------------------------
; PrintCsTblString: print string number SI of a string table in CS whose address is in the
; word AmountHi: skip SI zero bytes from the start of the table, then print up to
; the next zero. The tables (PubTipTbl, OracleVerseTbl) start with a zero byte, so SI = n+1
; prints entry n (0-based). Shares its loop with PrintTalkString.
; In: SI, word AmountHi. Out: text printed. Uses: AX, SI, DI (ES saved).
;------------------------------------------------------------------------------
PrintCsTblString:	push es	;@155D
	push cs	;@155E
	pop es	;@155F
	mov di, word ptr AmountHi	;@1560
; skip SI zero terminators
PrintNth_Skip:	mov al, byte ptr es:[di]	;@1564
	cmp al, 0	;@1567
	je PrintNth_CountZero	;@1569
PrintNth_NextByte:	inc di	;@156B
	jmp PrintNth_Skip	;@156C
PrintNth_CountZero:	dec si	;@156E
	je PrintNth_Print	;@156F
	jmp PrintNth_NextByte	;@1571
; print until the next zero
PrintNth_Print:	inc di	;@1573
	mov al, byte ptr es:[di]	;@1574
	cmp al, 0	;@1577
	je PrintNth_Done	;@1579
	call PutChar	;@157B
	jmp PrintNth_Print	;@157E
PrintNth_Done:	pop es	;@1580
	ret	;@1581
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h	; padding (never executed)	;@1582

;------------------------------------------------------------------------------
; ShopDispatch: shop dispatcher, jumped to by T)ransact (CMDMZ 40A3) when the player
; transacts across a counter with a merchant (tile 68h). The shop depends on the
; quarter of the map the player stands in (PlayerX/PlayerY < 20h = west/north)
; and on the map type MapType (2 = towne; otherwise village or castle). See the
; table in the module header. Does not return: every shop ends at EndCommand.
; In: PlayerX, PlayerY, MapType. Uses: AL.
;------------------------------------------------------------------------------
ShopDispatch:	nop	;@1590
	mov al, byte ptr PlayerX	;@1591
	cmp al, 20h	;@1594
	jb ShopDispatch_West	; west half	;@1596
	mov al, byte ptr PlayerY	;@1598
	cmp al, 20h	;@159B
	jb ShopDispatch_NE	; north-east	;@159D
	jmp ShopDispatch_SE	; south-east	;@159F
ShopDispatch_West:	mov al, byte ptr PlayerY	;@15A2
	cmp al, 20h	;@15A5
	jb ShopDispatch_NW	; north-west	;@15A7
	jmp ShopDispatch_SW	; south-west	;@15A9
ShopDispatch_NE:	nop	;@15AC
	mov al, byte ptr MapType	;@15AD
	cmp al, 2	; towne?	;@15B0
	jne ShopDispatch_Food	;@15B2
	jmp ShopArmour	; towne: armour	;@15B4
ShopDispatch_Food:	jmp ShopFood	; village/castle: food	;@15B7
ShopDispatch_NW:	nop	;@15BA
	mov al, byte ptr MapType	;@15BB
	cmp al, 2	;@15BE
	jne ShopDispatch_Oracle	;@15C0
	jmp ShopWeapons	; towne: weapons	;@15C2
ShopDispatch_Oracle:	jmp ShopOracle	; village/castle: oracle	;@15C5
ShopDispatch_SE:	nop	;@15C8
	mov al, byte ptr MapType	;@15C9
	cmp al, 2	;@15CC
	jne ShopDispatch_Cleric	;@15CE
	jmp ShopTransport	; towne: transport	;@15D0
ShopDispatch_Cleric:	jmp ShopClericSpells	; village/castle: cleric spells	;@15D3
ShopDispatch_SW:	nop	;@15D6
	mov al, byte ptr MapType	;@15D7
	cmp al, 2	;@15DA
	jne ShopDispatch_Wizard	;@15DC
	jmp ShopPub	; towne: pub	;@15DE
ShopDispatch_Wizard:	jmp ShopWizardSpells	; village/castle: wizard spells	;@15E1

;------------------------------------------------------------------------------
; ShopPub: the pub. "1-BUY, 2-TIP". Buy: pay 5 gold for a drink and hear tip 1.
; Tip: pay 0-9 gold (one digit, 0 is free) and hear tip number (amount +1 or
; -1, at random); a result outside 0-9 gives tip 0. Tips are in PubTipTbl, printed
; by PrintCsTblString. Any other key leaves. Uses DungeonLevel as a scratch byte (the tip number).
;------------------------------------------------------------------------------
ShopPub:	nop	;@15E4
	call PrintInline	; "WELCOME TO THE PUB! 1-BUY, 2-TIP ---"	;@15E5
	db 57h,45h,4Ch,43h,4Fh,4Dh,45h,20h,54h,4Fh,20h,54h,48h,45h,20h,50h	;@15E8
	db 55h,42h,21h,0Dh,31h,2Dh,42h,55h,59h,2Ch,20h,32h,2Dh,54h,49h,50h	;@15F8
	db 20h,2Dh,2Dh,2Dh,20h,0h	;@1608
	call ReadDigit	; read a digit	;@160E
	cmp al, 1	;@1611
	je Pub_Buy	;@1613
	cmp al, 2	;@1615
	je Pub_Tip	;@1617
	jmp EndCommand	;@1619
; 1 = buy a drink: 5 gold
Pub_Buy:	nop	;@161C
	mov al, 5	;@161D
	mov byte ptr AmountLo, al	; price = 0005 (BCD)	;@161F
	mov al, 0	;@1622
	mov byte ptr AmountHi, al	;@1624
	call PayPrice	; pay (leaves the shop if too poor)	;@1627
	call PrintInline	; "HERE, HAVE A STRONG ONE!"	;@162A
	db 48h,45h,52h,45h,2Ch,20h,48h,41h,56h,45h,20h,41h,20h,53h,54h,52h	;@162D
	db 4Fh,4Eh,47h,20h,4Fh,4Eh,45h,21h,0Dh,0h	;@163D
; The random number is masked and then thrown away: a drink always gives tip 1
; ("ISN'T THIS A GREAT GAME?"). Probably meant to pick one of tips 0-3.
	call Random	;@1647
	and al, 3	; result unused	;@164A
	mov al, 1	;@164C
	jmp Pub_SayTip	;@164E
; 2 = tip 0-9 gold
Pub_Tip:	nop	;@1651
	call PrintInline	;@1652
	db 54h,49h,50h,20h,48h,4Fh,57h,20h,4Dh,55h,43h,48h,3Fh,20h,0h	;@1655
	call ReadDigit	; tip = one digit, 0-9	;@1664
	mov byte ptr DungeonLevel, al	;@1667
	mov byte ptr AmountLo, al	; price = 00 0t (BCD)	;@166A
	mov al, 0	;@166D
	mov byte ptr AmountHi, al	;@166F
	call PayPrice	;@1672
; tip number = amount + sign(random) = amount +1 or -1 (0 only if the random
; byte is 0); 0FFh or 10 wrap to tip 0. So tip 9 is reached only from 8.
	call Random	;@1675
	call SignOf	; AL = sign: 0FFh, 0 or 1	;@1678
	clc	;@167B
	adc al, byte ptr DungeonLevel	;@167C
	cmp al, 0Ah	;@1680
	jb Pub_SayTip	;@1682
	mov al, 0	;@1684
Pub_SayTip:	nop	;@1686
	mov byte ptr DungeonLevel, al	;@1687
	call PrintInline	; "THE BARKEEP SAYS:"	;@168A
	db 54h,48h,45h,20h,42h,41h,52h,4Bh,45h,45h,50h,20h,53h,41h,59h,53h	;@168D
	db 3Ah,0Dh,0h	;@169D
	mov al, byte ptr DungeonLevel	;@16A0
	mov ah, 0	;@16A3
	mov si, ax	;@16A5
	inc si	; SI = tip + 1 (table starts with a 0)	;@16A7
	db 2Eh		; cs: prefix, which MASM drops on lea	;@16A8
	lea ax, PubTipTbl	;@16A9
	mov word ptr AmountHi, ax	; AmountHi (word) = table address	;@16AD
	mov bh, 0	;@16B0
	mov bl, 0	;@16B2
	mov di, bx	; DI = 0: unused, PrintCsTblString reloads DI	;@16B4
	call PrintCsTblString	;@16B6
	jmp EndCommand	;@16B9

; PubTipTbl: pub tips, a 0 byte then ten zero-terminated strings (0-based):
; 0 CAUGH... 1 ISN'T THIS A GREAT GAME? 2 HHMMM... 3 SOME FIGHTERS WEAR MAGIC HELMS!
; 4 AVIATORS USE SKULL KEYS! 5 SAYLORS WEAR BLUE TASSLES! 6 MAGES CARRY WANDS OR STAFFS!
; 7 GUARDS CARRY KEYS! 8 ANKHS OPEN SPACE! 9 PLANES NEED BRASS BUTTONS!
PubTipTbl label byte
	db 0h,43h,41h,55h,47h,48h,2Eh,2Eh,2Eh,0h,49h,53h,4Eh,27h,54h,20h	;@16BC
	db 54h,48h,49h,53h,20h,41h,20h,47h,52h,45h,41h,54h,20h,47h,41h,4Dh	;@16CC
	db 45h,3Fh,0h,48h,48h,4Dh,4Dh,4Dh,2Eh,2Eh,2Eh,0h,53h,4Fh,4Dh,45h	;@16DC
	db 20h,46h,49h,47h,48h,54h,45h,52h,53h,20h,57h,45h,41h,52h,20h,4Dh	;@16EC
	db 41h,47h,49h,43h,20h,48h,45h,4Ch,4Dh,53h,21h,0h,41h,56h,49h,41h	;@16FC
	db 54h,4Fh,52h,53h,20h,55h,53h,45h,20h,53h,4Bh,55h,4Ch,4Ch,20h,4Bh	;@170C
	db 45h,59h,53h,21h,0h,53h,41h,59h,4Ch,4Fh,52h,53h,20h,57h,45h,41h	;@171C
	db 52h,20h,42h,4Ch,55h,45h,20h,54h,41h,53h,53h,4Ch,45h,53h,21h,0h	;@172C
	db 4Dh,41h,47h,45h,53h,20h,43h,41h,52h,52h,59h,20h,57h,41h,4Eh,44h	;@173C
	db 53h,20h,4Fh,52h,20h,53h,54h,41h,46h,46h,53h,21h,0h,47h,55h,41h	;@174C
	db 52h,44h,53h,20h,43h,41h,52h,52h,59h,20h,4Bh,45h,59h,53h,21h,0h	;@175C
	db 41h,4Eh,4Bh,48h,53h,20h,4Fh,50h,45h,4Eh,20h,53h,50h,41h,43h,45h	;@176C
	db 21h,0h,50h,4Ch,41h,4Eh,45h,53h,20h,4Eh,45h,45h,44h,20h,42h,52h	;@177C
	db 41h,53h,53h,20h,42h,55h,54h,54h,4Fh,4Eh,53h,21h,0h	;@178C
;------------------------------------------------------------------------------
; ShopFood: the food stand (villages and castles). Offers 100 food for the price
; of item 3 (CalcPrice); on 'Y' pays and adds 1 to the BCD hundreds of food FoodHi.
; No check for 9900+ food: the BCD byte wraps from 99 to 00.
;------------------------------------------------------------------------------
ShopFood:	nop	;@1799
	call PrintInline	; "THE FOOD HERE COSTS "	;@179A
	db 54h,48h,45h,20h,46h,4Fh,4Fh,44h,20h,48h,45h,52h,45h,20h,43h,4Fh	;@179D
	db 53h,54h,53h,20h,0h	;@17AD
	mov al, 3	;@17B2
	call CalcPrice	; price -> AmountHi:AmountLo	;@17B4
	mov al, byte ptr AmountHi	;@17B7
	mov bh, 0	;@17BA
	mov bl, byte ptr AmountLo	;@17BC
	mov di, bx	;@17C0
	call PrintBcdWord	; print AL, DI as 4 BCD digits	;@17C2
	call PrintInline	; "PER 100, WANT ONE? "	;@17C5
	db 8Dh,50h,45h,52h,20h,31h,30h,30h,2Ch,20h,57h,41h,4Eh,54h,20h,4Fh	;@17C8
	db 4Eh,45h,3Fh,20h,0h	;@17D8
Food_WaitKey:	call ReadKey	; wait for a key	;@17DD
	cmp ah, 0FFh	;@17E0
	jne Food_WaitKey	;@17E3
	cmp al, 59h	; 'Y'?	;@17E5
	je Food_Buy	;@17E7
	call PrintInline	; "NO"	;@17E9
	db 4Eh,4Fh,0h	;@17EC
	jmp EndCommand	;@17EF
Food_Buy:	call PrintInline	; "YES, NO ONIONS AND TO GO PLEASE!"	;@17F2
	db 59h,45h,53h,2Ch,8Dh,4Eh,4Fh,20h,4Fh,4Eh,49h,4Fh,4Eh,53h,20h,41h	;@17F5
	db 4Eh,44h,20h,54h,4Fh,20h,47h,4Fh,20h,50h,4Ch,45h,41h,53h,45h,21h	;@1805
	db 8Dh,0h	;@1815
	call PayPrice	; pay	;@1817
	clc	;@181A
	mov al, byte ptr FoodHi	;@181B
	adc al, 1	;@181E
	daa	; food += 100 (BCD)	;@1820
	mov byte ptr FoodHi, al	;@1821
	call PrintInline	; "THANK YOU, COME AGAIN!"	;@1824
	db 54h,48h,41h,4Eh,4Bh,20h,59h,4Fh,55h,2Ch,20h,43h,4Fh,4Dh,45h,20h	;@1827
	db 41h,47h,41h,49h,4Eh,21h,0h	;@1837
	jmp EndCommand	;@183E
;------------------------------------------------------------------------------
; ShopClericSpells: the clerics' magic store (villages and castles). Only for clerics
; (PlayerClass = 1). Spells 1-6: light, ladder down, ladder up, passwall, surface,
; prayer. Sells five of the chosen spell for the price of item n (CalcPrice) and
; adds 5 (BCD, wraps past 99) to its count SpellCounts[n]. BUG: the greeting tests PlayerSex = 1
; for "SISTER", but the sex is stored as the letter 'M' or 'F', so every cleric is a BROTHER.
;------------------------------------------------------------------------------
ShopClericSpells:	nop	;@1841
	mov al, byte ptr PlayerClass	;@1842
	cmp al, 1	; cleric?	;@1845
	je Cleric_Welcome	;@1847
	call PrintPlayerName	; print the player's name	;@1849
	call PrintInline	; " YOU ARE NOT A CLERIC!"	;@184C
	db 20h,59h,4Fh,55h,20h,41h,52h,45h,20h,4Eh,4Fh,54h,20h,41h,20h,43h	;@184F
	db 4Ch,45h,52h,49h,43h,21h,0h	;@185F
	jmp EndCommand	;@1866
Cleric_Welcome:	nop	;@1869
	call PrintInline	; "WELCOME "	;@186A
	db 57h,45h,4Ch,43h,4Fh,4Dh,45h,20h,0h	;@186D
	mov al, byte ptr PlayerSex	;@1876
	cmp al, 1	; female? BUG: PlayerSex is 'M' or 'F', never 1	;@1879
	je Cleric_Sister	;@187B
	call PrintInline	; "BROTHER "	;@187D
	db 42h,52h,4Fh,54h,48h,45h,52h,20h,0h	;@1880
	jmp Cleric_Menu	;@1889
Cleric_Sister:	call PrintInline	; "SISTER "	;@188C
	db 53h,49h,53h,54h,45h,52h,20h,0h	;@188F
Cleric_Menu:	call PrintPlayerName	; player's name	;@1897
	call PrintInline	; menu of spells 1-6, "YOUR INTEREST?"	;@189A
	db 8Dh,31h,2Dh,4Ch,49h,47h,48h,54h,2Ch,20h,32h,2Dh,4Ch,2Eh,44h,2Eh	;@189D
	db 2Ch,20h,33h,2Dh,4Ch,2Eh,55h,2Eh,2Ch,8Dh,34h,2Dh,50h,41h,53h,53h	;@18AD
	db 20h,35h,2Dh,53h,55h,52h,46h,41h,43h,45h,2Ch,20h,36h,2Dh,50h,52h	;@18BD
	db 41h,59h,45h,52h,2Eh,8Dh,59h,4Fh,55h,52h,20h,49h,4Eh,54h,45h,52h	;@18CD
	db 45h,53h,54h,3Fh,20h,0h	;@18DD
	call ReadDigit	; spell 1-6; 0 or 7-9 leave	;@18E3
	je Cleric_Leave	;@18E6
	cmp al, 7	;@18E8
	jae Cleric_Leave	;@18EA
	jmp Cleric_Offer	;@18EC
Cleric_Leave:	call PrintInline	; "FOLLOW THE LIGHT, FRIEND!"	;@18EF
	db 46h,4Fh,4Ch,4Ch,4Fh,57h,20h,54h,48h,45h,20h,4Ch,49h,47h,48h,54h	;@18F2
	db 2Ch,20h,46h,52h,49h,45h,4Eh,44h,21h,0h	;@1902
	jmp EndCommand	;@190C
Cleric_Offer:	mov byte ptr Temp1F, al	; spell number	;@190F
	call PrintInline	; "FIVE "	;@1912
	db 46h,49h,56h,45h,20h,0h	;@1915
	mov al, byte ptr Temp1F	;@191B
	clc	;@191E
	adc al, 24h	;@191F
	call PrintNameStr	; spell name (string 24h+n of NameStrTbl)	;@1921
	call PrintInline	; "S FOR "	;@1924
	db 53h,20h,46h,4Fh,52h,20h,0h	;@1927
	mov al, byte ptr Temp1F	;@192E
	call CalcPrice	; price of item n	;@1931
	mov al, byte ptr AmountHi	;@1934
	mov bh, 0	;@1937
	mov bl, byte ptr AmountLo	;@1939
	mov di, bx	;@193D
	call PrintBcdWord	;@193F
	call PrintInline	; "YES, FRIEND? "	;@1942
	db 8Dh,59h,45h,53h,2Ch,20h,46h,52h,49h,45h,4Eh,44h,3Fh,20h,0h	;@1945
Cleric_WaitKey:	call ReadKey	;@1954
	cmp ah, 0FFh	;@1957
	jne Cleric_WaitKey	;@195A
	cmp al, 59h	; 'Y'?	;@195C
	je Cleric_Buy	;@195E
	call PrintInline	; "NO  I'M SORRY, GOOD DAY."	;@1960
	db 4Eh,4Fh,8Dh,49h,27h,4Dh,20h,53h,4Fh,52h,52h,59h,2Ch,20h,47h,4Fh	;@1963
	db 4Fh,44h,20h,44h,41h,59h,2Eh,0h	;@1973
	jmp EndCommand	;@197B
Cleric_Buy:	call PrintInline	; "YES, I WILL TAKE 5!"	;@197E
	db 59h,45h,53h,2Ch,8Dh,49h,20h,57h,49h,4Ch,4Ch,20h,54h,41h,4Bh,45h	;@1981
	db 20h,35h,21h,0h	;@1991
	call PayPrice	; pay	;@1995
	mov bh, 0	;@1998
	mov bl, byte ptr Temp1F	;@199A
	mov di, bx	;@199E
	mov al, byte ptr SpellCounts[di]	;@19A0
	clc	;@19A4
	adc al, 5	;@19A5
	daa	; spell count += 5 (BCD)	;@19A7
	mov byte ptr SpellCounts[di], al	;@19A8
	jmp EndCommand	;@19AC

;------------------------------------------------------------------------------
; ShopWizardSpells: the wizards' magic store (villages and castles), the twin of ShopClericSpells
; with Turkish patter (MUSERREF OLDUM = honoured, BIR IKI UC = one two three,
; LUTFEN EVET = yes please, UGURLA OLSUN = good luck, GULE GULE = goodbye).
; Only for wizards (PlayerClass = 2). Menu 1-6 = spells 1, 2, 3, 7, 8, 9: light,
; ladder down, ladder up, magic missile, blink, kill. Five for the price of
; item n; adds 5 (BCD) to SpellCounts[n].
;------------------------------------------------------------------------------
ShopWizardSpells:	nop	;@19AF
	call PrintPlayerName	; print the player's name	;@19B0
	mov al, byte ptr PlayerClass	;@19B3
	cmp al, 2	; wizard?	;@19B6
	je Wizard_Menu	;@19B8
	call PrintInline	; " YOU ARE NOT A WIZARD!"	;@19BA
	db 20h,59h,4Fh,55h,20h,41h,52h,45h,20h,4Eh,4Fh,54h,20h,41h,20h,57h	;@19BD
	db 49h,5Ah,41h,52h,44h,21h,0h	;@19CD
	jmp EndCommand	;@19D4
Wizard_Menu:	nop	;@19D7
	call PrintInline	; " MUSERREF OLDUM!", menu, "BIR IKI UC...?"	;@19D8
	db 20h,4Dh,55h,53h,45h,52h,52h,45h,46h,20h,4Fh,4Ch,44h,55h,4Dh,21h	;@19DB
	db 8Dh,31h,2Dh,4Ch,49h,47h,48h,54h,2Ch,20h,32h,2Dh,4Ch,2Eh,44h,2Eh	;@19EB
	db 2Ch,20h,33h,2Dh,4Ch,2Eh,55h,2Eh,2Ch,8Dh,34h,2Dh,4Dh,2Eh,4Dh,2Eh	;@19FB
	db 2Ch,20h,35h,2Dh,42h,4Ch,49h,4Eh,4Bh,2Ch,20h,36h,2Dh,4Bh,49h,4Ch	;@1A0B
	db 4Ch,2Ch,8Dh,42h,49h,52h,20h,49h,4Bh,49h,20h,55h,43h,2Eh,2Eh,2Eh	;@1A1B
	db 3Fh,20h,0h	;@1A2B
	call ReadDigit	; choice 1-6; 0 or 7-9 leave	;@1A2E
	je Wizard_Leave	;@1A31
	cmp al, 7	;@1A33
	jae Wizard_Leave	;@1A35
	jmp Wizard_Offer	;@1A37
Wizard_Leave:	call PrintInline	; "UGURLA OLSUN!"	;@1A3A
	db 8Dh,55h,47h,55h,52h,4Ch,41h,20h,4Fh,4Ch,53h,55h,4Eh,21h,0h	;@1A3D
	jmp EndCommand	;@1A4C
Wizard_Offer:	cmp al, 4	;@1A4F
	jb Wizard_SetSpell	;@1A51
	clc	;@1A53
	adc al, 3	; 4-6 -> wizard spells 7-9	;@1A54
Wizard_SetSpell:	mov byte ptr Temp1F, al	; spell number	;@1A56
	call PrintInline	; "FIVE "	;@1A59
	db 46h,49h,56h,45h,20h,0h	;@1A5C
	mov al, byte ptr Temp1F	;@1A62
	clc	;@1A65
	adc al, 24h	;@1A66
	call PrintNameStr	; spell name	;@1A68
	call PrintInline	; "S FOR "	;@1A6B
	db 53h,20h,46h,4Fh,52h,20h,0h	;@1A6E
	mov al, byte ptr Temp1F	;@1A75
	call CalcPrice	; price of item n	;@1A78
	mov al, byte ptr AmountHi	;@1A7B
	mov bh, 0	;@1A7E
	mov bl, byte ptr AmountLo	;@1A80
	mov di, bx	;@1A84
	call PrintBcdWord	;@1A86
	call PrintInline	; "LUTFEN EVET? "	;@1A89
	db 8Dh,4Ch,55h,54h,46h,45h,4Eh,20h,45h,56h,45h,54h,3Fh,20h,0h	;@1A8C
Wizard_WaitKey:	call ReadKey	;@1A9B
	cmp ah, 0FFh	;@1A9E
	jne Wizard_WaitKey	;@1AA1
	cmp al, 59h	; 'Y'?	;@1AA3
	je Wizard_Buy	;@1AA5
	call PrintInline	; "NO!"	;@1AA7
	db 4Eh,4Fh,21h,0h	;@1AAA
	jmp Wizard_Leave	;@1AAE
Wizard_Buy:	call PrintInline	; "YES"	;@1AB0
	db 59h,45h,53h,8Dh,0h	;@1AB3
	call PayPrice	; pay	;@1AB8
	clc	;@1ABB
	mov bh, 0	;@1ABC
	mov bl, byte ptr Temp1F	;@1ABE
	mov di, bx	;@1AC2
	mov al, byte ptr SpellCounts[di]	;@1AC4
	adc al, 5	;@1AC8
	daa	; spell count += 5 (BCD)	;@1ACA
	mov byte ptr SpellCounts[di], al	;@1ACB
	call PrintInline	; "GULE GULE!"	;@1ACF
	db 47h,55h,4Ch,45h,20h,47h,55h,4Ch,45h,21h,0h	;@1AD2
	jmp EndCommand	;@1ADD

;------------------------------------------------------------------------------
; ShopOracle: the oracle (villages and castles). Asks how much to pay in hundreds
; of gold (one digit 0-9, 0 is free), takes it and recites verse n of OracleVerseTbl.
;------------------------------------------------------------------------------
ShopOracle:	nop	;@1AE0
	call PrintInline	; "TIME AND TRAVEL MADE ME WISE, ... HOW MUCH WILL YOU PAY *100?"	;@1AE1
	db 54h,49h,4Dh,45h,20h,41h,4Eh,44h,20h,54h,52h,41h,56h,45h,4Ch,20h	;@1AE4
	db 4Dh,41h,44h,45h,20h,4Dh,45h,20h,57h,49h,53h,45h,2Ch,0Dh,50h,52h	;@1AF4
	db 45h,43h,49h,4Fh,55h,53h,20h,47h,4Fh,4Ch,44h,2Ch,20h,41h,20h,43h	;@1B04
	db 4Ch,55h,45h,20h,49h,54h,20h,42h,55h,59h,53h,21h,48h,4Fh,57h,20h	;@1B14
	db 4Dh,55h,43h,48h,20h,57h,49h,4Ch,4Ch,20h,59h,4Fh,55h,20h,50h,41h	;@1B24
	db 59h,20h,2Ah,31h,30h,30h,3Fh,0h	;@1B34
	call ReadDigit	; one digit = hundreds of gold	;@1B3C
	mov byte ptr Temp1F, al	;@1B3F
	mov byte ptr AmountHi, al	; price = n * 100 (BCD n 00)	;@1B42
	mov al, 0	;@1B45
	mov byte ptr AmountLo, al	;@1B47
	call PayPrice	; pay	;@1B4A
	mov bh, 0	;@1B4D
	mov bl, byte ptr Temp1F	;@1B4F
	mov si, bx	;@1B53
	inc si	; SI = n + 1 (table starts with a 0)	;@1B55
	db 2Eh		; cs: prefix, which MASM drops on lea	;@1B56
	lea ax, OracleVerseTbl	;@1B57
	mov word ptr AmountHi, ax	; AmountHi (word) = table address	;@1B5B
	mov bh, 0	;@1B5E
	mov bl, 0	;@1B60
	mov di, bx	; DI = 0: unused, PrintCsTblString reloads DI	;@1B62
	call PrintCsTblString	;@1B64
	jmp EndCommand	;@1B67

; OracleVerseTbl: oracle verses, a 0 byte then ten zero-terminated strings (0-based, 8Dh = new line):
; 0 ASK ME NO QUESTIONS, I'LL TELL YOU NO LIES. 1 THE QUEEN IS THE KING AND THE KING IS A SPY.
; 2 THE EVIL MEN DO IS A HORRIBLE THING. 3 BUT DISPELLING MEANS THAT YOU MUST HAVE THE RING.
; 4 JUST WHERE IT IS, I CANNOT SAY. 5 BUT I'LL TELL YOU RIGHT NOW, THERE IS NO OTHER WAY.
; 6 I HEAR IN A TOWN WHERE THE WATER RUNS FREE. 7 THERE IS AN OLD MAN LIVING UNDER A TREE.
; 8 HE HAS NOT A NAME BUT HE DOES HAVE A CLUE 9 MAYHAPS IF YOU FIND HIM, HE'LL TELL IT TO YOU!
OracleVerseTbl label byte
	db 0h,41h,53h,4Bh,20h,4Dh,45h,20h,4Eh,4Fh,20h,51h,55h,45h,53h,54h	;@1B6A
	db 49h,4Fh,4Eh,53h,2Ch,8Dh,49h,27h,4Ch,4Ch,20h,54h,45h,4Ch,4Ch,20h	;@1B7A
	db 59h,4Fh,55h,20h,4Eh,4Fh,20h,4Ch,49h,45h,53h,2Eh,0h,54h,48h,45h	;@1B8A
	db 20h,51h,55h,45h,45h,4Eh,20h,49h,53h,20h,54h,48h,45h,20h,4Bh,49h	;@1B9A
	db 4Eh,47h,8Dh,41h,4Eh,44h,20h,54h,48h,45h,20h,4Bh,49h,4Eh,47h,20h	;@1BAA
	db 49h,53h,20h,41h,20h,53h,50h,59h,2Eh,0h,54h,48h,45h,20h,45h,56h	;@1BBA
	db 49h,4Ch,20h,4Dh,45h,4Eh,20h,44h,4Fh,8Dh,49h,53h,20h,41h,20h,48h	;@1BCA
	db 4Fh,52h,52h,49h,42h,4Ch,45h,20h,54h,48h,49h,4Eh,47h,2Eh,0h,42h	;@1BDA
	db 55h,54h,20h,44h,49h,53h,50h,45h,4Ch,4Ch,49h,4Eh,47h,20h,4Dh,45h	;@1BEA
	db 41h,4Eh,53h,8Dh,54h,48h,41h,54h,20h,59h,4Fh,55h,20h,4Dh,55h,53h	;@1BFA
	db 54h,20h,48h,41h,56h,45h,20h,54h,48h,45h,20h,52h,49h,4Eh,47h,2Eh	;@1C0A
	db 0h,4Ah,55h,53h,54h,20h,57h,48h,45h,52h,45h,20h,49h,54h,20h,49h	;@1C1A
	db 53h,2Ch,8Dh,49h,20h,43h,41h,4Eh,4Eh,4Fh,54h,20h,53h,41h,59h,2Eh	;@1C2A
	db 0h,42h,55h,54h,20h,49h,27h,4Ch,4Ch,20h,54h,45h,4Ch,4Ch,20h,59h	;@1C3A
	db 4Fh,55h,20h,52h,49h,47h,48h,54h,20h,4Eh,4Fh,57h,2Ch,8Dh,54h,48h	;@1C4A
	db 45h,52h,45h,20h,49h,53h,20h,4Eh,4Fh,20h,4Fh,54h,48h,45h,52h,20h	;@1C5A
	db 57h,41h,59h,2Eh,0h,49h,20h,48h,45h,41h,52h,20h,49h,4Eh,20h,41h	;@1C6A
	db 20h,54h,4Fh,57h,4Eh,8Dh,57h,48h,45h,52h,45h,20h,54h,48h,45h,20h	;@1C7A
	db 57h,41h,54h,45h,52h,20h,52h,55h,4Eh,53h,20h,46h,52h,45h,45h,2Eh	;@1C8A
	db 0h,54h,48h,45h,52h,45h,20h,49h,53h,20h,41h,4Eh,20h,4Fh,4Ch,44h	;@1C9A
	db 20h,4Dh,41h,4Eh,8Dh,4Ch,49h,56h,49h,4Eh,47h,20h,55h,4Eh,44h,45h	;@1CAA
	db 52h,20h,41h,20h,54h,52h,45h,45h,2Eh,0h,48h,45h,20h,48h,41h,53h	;@1CBA
	db 20h,4Eh,4Fh,54h,20h,41h,20h,4Eh,41h,4Dh,45h,8Dh,42h,55h,54h,20h	;@1CCA
	db 48h,45h,20h,44h,4Fh,45h,53h,20h,48h,41h,56h,45h,20h,41h,20h,43h	;@1CDA
	db 4Ch,55h,45h,0h,4Dh,41h,59h,48h,41h,50h,53h,20h,49h,46h,20h,59h	;@1CEA
	db 4Fh,55h,20h,46h,49h,4Eh,44h,20h,48h,49h,4Dh,2Ch,8Dh,48h,45h,27h	;@1CFA
	db 4Ch,4Ch,20h,54h,45h,4Ch,4Ch,20h,49h,54h,20h,54h,4Fh,20h,59h,4Fh	;@1D0A
	db 55h,21h,0h	;@1D1A
;------------------------------------------------------------------------------
; ShopArmour: the armour shoppe (townes). Armour 1-6: cloth, leather, chain, plate,
; reflect, power. Price = item 2n (CalcPrice); on 'Y' adds 1 (BCD) to ArmourCounts[n].
;------------------------------------------------------------------------------
ShopArmour:	nop	;@1D1D
	call PrintInline	; "THE ARMOUR SHOPPE:", menu 1-6, "YOUR INTEREST?"	;@1D1E
	db 20h,20h,20h,20h,20h,54h,48h,45h,20h,41h,52h,4Dh,4Fh,55h,52h,20h	;@1D21
	db 53h,48h,4Fh,50h,50h,45h,3Ah,0Dh,31h,2Dh,43h,4Ch,4Fh,54h,48h,2Ch	;@1D31
	db 20h,32h,2Dh,4Ch,45h,41h,54h,48h,45h,52h,2Ch,20h,33h,2Dh,43h,48h	;@1D41
	db 41h,49h,4Eh,2Ch,0Dh,34h,2Dh,50h,4Ch,41h,54h,45h,2Ch,20h,35h,2Dh	;@1D51
	db 52h,45h,46h,4Ch,45h,43h,54h,2Ch,20h,36h,2Dh,50h,4Fh,57h,45h,52h	;@1D61
	db 2Ch,0Dh,59h,4Fh,55h,52h,20h,49h,4Eh,54h,45h,52h,45h,53h,54h,3Fh	;@1D71
	db 20h,0h	;@1D81
	call ReadDigit	; armour 1-6; 0 or 7-9 leave	;@1D83
	je Armour_Leave	;@1D86
	cmp al, 7	;@1D88
	jae Armour_Leave	;@1D8A
	jmp Armour_Offer	;@1D8C
Armour_Leave:	call PrintInline	; "THANKS FOR COMING BY..."	;@1D8F
	db 54h,48h,41h,4Eh,4Bh,53h,20h,46h,4Fh,52h,20h,43h,4Fh,4Dh,49h,4Eh	;@1D92
	db 47h,20h,42h,59h,2Eh,2Eh,2Eh,0h	;@1DA2
	jmp EndCommand	;@1DAA
Armour_Offer:	mov byte ptr Temp1F, al	; armour number	;@1DAD
	call PrintInline	; "AH! YES! "	;@1DB0
	db 41h,48h,21h,20h,59h,45h,53h,21h,20h,0h	;@1DB3
	mov al, byte ptr Temp1F	;@1DBD
	clc	;@1DC0
	adc al, 1Dh	;@1DC1
	call PrintNameStr	; armour name (string 1Dh+n of NameStrTbl)	;@1DC3
	call PrintInline	; "FOR YOU ONLY "	;@1DC6
	db 0Dh,46h,4Fh,52h,20h,59h,4Fh,55h,20h,4Fh,4Eh,4Ch,59h,20h,0h	;@1DC9
	mov al, byte ptr Temp1F	;@1DD8
	add al, al	;@1DDB
	call CalcPrice	; price of item 2n	;@1DDD
	mov al, byte ptr AmountHi	;@1DE0
	mov bh, 0	;@1DE3
	mov bl, byte ptr AmountLo	;@1DE5
	mov di, bx	;@1DE9
	call PrintBcdWord	;@1DEB
	call PrintInline	; "HOW 'BOUT IT? "	;@1DEE
	db 0Dh,48h,4Fh,57h,20h,27h,42h,4Fh,55h,54h,20h,49h,54h,3Fh,20h,0h	;@1DF1
Armour_WaitKey:	call ReadKey	;@1E01
	cmp ah, 0FFh	;@1E04
	jne Armour_WaitKey	;@1E07
	mov byte ptr Temp21, al	; echo the key and a new line	;@1E09
	call PutChar	;@1E0C
	mov al, 8Dh	;@1E0F
	call PutChar	;@1E11
	mov al, byte ptr Temp21	;@1E14
	cmp al, 59h	; 'Y'?	;@1E17
	je Armour_Buy	;@1E19
	call PrintInline	; "OH, WELL."	;@1E1B
	db 4Fh,48h,2Ch,20h,57h,45h,4Ch,4Ch,2Eh,0h	;@1E1E
	jmp EndCommand	;@1E28
Armour_Buy:	nop	;@1E2B
	call PayPrice	; pay	;@1E2C
	call PrintInline	; "SOLD!"	;@1E2F
	db 53h,4Fh,4Ch,44h,21h,0h	;@1E32
	mov bh, 0	;@1E38
	mov bl, byte ptr Temp1F	;@1E3A
	mov di, bx	;@1E3E
	mov al, byte ptr ArmourCounts[di]	;@1E40
	clc	;@1E44
	adc al, 1	;@1E45
	daa	; armour count += 1 (BCD)	;@1E47
	mov byte ptr ArmourCounts[di], al	;@1E48
	jmp EndCommand	;@1E4C

;------------------------------------------------------------------------------
; ShopWeapons: the weapons shoppe (townes). Weapons 1-8: dagger, mace, axe, bow,
; sword, great sword, light sword, phaser. Price = item n (CalcPrice); on 'Y' adds
; 1 (BCD) to WeaponCounts[n]. Same code as the armour shoppe otherwise.
;------------------------------------------------------------------------------
ShopWeapons:	nop	;@1E4F
	call PrintInline	; "THE WEAPONS SHOPPE:", menu 1-8, "YOUR INTEREST?"	;@1E50
	db 20h,20h,54h,48h,45h,20h,57h,45h,41h,50h,4Fh,4Eh,53h,20h,53h,48h	;@1E53
	db 4Fh,50h,50h,45h,3Ah,0Dh,31h,2Dh,44h,41h,2Ch,20h,32h,2Dh,4Dh,41h	;@1E63
	db 2Ch,20h,33h,2Dh,41h,58h,2Ch,20h,34h,2Dh,42h,4Fh,2Ch,0Dh,35h,2Dh	;@1E73
	db 53h,57h,2Ch,20h,36h,2Dh,47h,52h,2Ch,20h,37h,2Dh,4Ch,49h,2Ch,20h	;@1E83
	db 38h,2Dh,50h,48h,2Eh,0Dh,59h,4Fh,55h,52h,20h,49h,4Eh,54h,45h,52h	;@1E93
	db 45h,53h,54h,3Fh,20h,0h	;@1EA3
	call ReadDigit	; weapon 1-8; 0 or 9 leave	;@1EA9
	je Weapons_Leave	;@1EAC
	cmp al, 9	;@1EAE
	je Weapons_Leave	;@1EB0
	jmp Weapons_Offer	;@1EB2
Weapons_Leave:	call PrintInline	; "THANKS FOR COMING BY..."	;@1EB5
	db 54h,48h,41h,4Eh,4Bh,53h,20h,46h,4Fh,52h,20h,43h,4Fh,4Dh,49h,4Eh	;@1EB8
	db 47h,20h,42h,59h,2Eh,2Eh,2Eh,0h	;@1EC8
	jmp EndCommand	;@1ED0
Weapons_Offer:	mov byte ptr Temp1F, al	; weapon number	;@1ED3
	call PrintInline	; "AH! YES! A "	;@1ED6
	db 41h,48h,21h,20h,59h,45h,53h,21h,20h,41h,20h,0h	;@1ED9
	mov al, byte ptr Temp1F	;@1EE5
	clc	;@1EE8
	adc al, 13h	;@1EE9
	call PrintNameStr	; weapon name (string 13h+n of NameStrTbl)	;@1EEB
	call PrintInline	; "FOR YOU ONLY "	;@1EEE
	db 0Dh,46h,4Fh,52h,20h,59h,4Fh,55h,20h,4Fh,4Eh,4Ch,59h,20h,0h	;@1EF1
	mov al, byte ptr Temp1F	;@1F00
	call CalcPrice	; price of item n	;@1F03
	mov al, byte ptr AmountHi	;@1F06
	mov bh, 0	;@1F09
	mov bl, byte ptr AmountLo	;@1F0B
	mov di, bx	;@1F0F
	call PrintBcdWord	;@1F11
	call PrintInline	; "HOW 'BOUT IT? "	;@1F14
	db 0Dh,48h,4Fh,57h,20h,27h,42h,4Fh,55h,54h,20h,49h,54h,3Fh,20h,0h	;@1F17
Weapons_WaitKey:	call ReadKey	;@1F27
	cmp ah, 0FFh	;@1F2A
	jne Weapons_WaitKey	;@1F2D
	mov byte ptr Temp21, al	; echo the key and a new line	;@1F2F
	call PutChar	;@1F32
	mov al, 8Dh	;@1F35
	call PutChar	;@1F37
	mov al, byte ptr Temp21	;@1F3A
	cmp al, 59h	; 'Y'?	;@1F3D
	je Weapons_Buy	;@1F3F
	call PrintInline	; "OH, WELL."	;@1F41
	db 4Fh,48h,2Ch,20h,57h,45h,4Ch,4Ch,2Eh,0h	;@1F44
	jmp EndCommand	;@1F4E
Weapons_Buy:	nop	;@1F51
	call PayPrice	; pay	;@1F52
	call PrintInline	; "SOLD!"	;@1F55
	db 53h,4Fh,4Ch,44h,21h,0h	;@1F58
	mov bh, 0	;@1F5E
	mov bl, byte ptr Temp1F	;@1F60
	mov di, bx	;@1F64
	mov al, byte ptr WeaponCounts[di]	;@1F66
	clc	;@1F6A
	adc al, 1	;@1F6B
	daa	; weapon count += 1 (BCD)	;@1F6D
	mov byte ptr WeaponCounts[di], al	;@1F6E
	jmp EndCommand	;@1F72

;------------------------------------------------------------------------------
; ShopTransport: the transport shoppe (townes). Sells only a horse, for the price of
; item 4 (CalcPrice). On 'Y' pays and sets PlayerTile = 22h (the player is now on a
; horse; whatever transport he had is simply replaced).
;------------------------------------------------------------------------------
ShopTransport:	nop	;@1F75
	call PrintInline	; "WELCOME, TO THE TRANSPORT SHOPPE. I SELL YOU HORSE "	;@1F76
	db 57h,45h,4Ch,43h,4Fh,4Dh,45h,2Ch,20h,54h,4Fh,20h,54h,48h,45h,20h	;@1F79
	db 54h,52h,41h,4Eh,53h,50h,4Fh,52h,54h,0Dh,53h,48h,4Fh,50h,50h,45h	;@1F89
	db 2Eh,20h,49h,20h,53h,45h,4Ch,4Ch,20h,59h,4Fh,55h,20h,48h,4Fh,52h	;@1F99
	db 53h,45h,20h,0h	;@1FA9
	mov al, 4	;@1FAD
	call CalcPrice	; price of item 4	;@1FAF
	mov al, byte ptr AmountHi	;@1FB2
	mov bh, 0	;@1FB5
	mov bl, byte ptr AmountLo	;@1FB7
	mov di, bx	;@1FBB
	call PrintBcdWord	;@1FBD
	call PrintInline	; "GOLD, DEAL, OK? --- "	;@1FC0
	db 0Dh,47h,4Fh,4Ch,44h,2Ch,20h,44h,45h,41h,4Ch,2Ch,20h,4Fh,4Bh,3Fh	;@1FC3
	db 20h,2Dh,2Dh,2Dh,20h,0h	;@1FD3
Transport_WaitKey:	call ReadKey	;@1FD9
	cmp ah, 0FFh	;@1FDC
	jne Transport_WaitKey	;@1FDF
	push ax	; echo the key and a new line	;@1FE1
	call PutChar	;@1FE2
	mov al, 8Dh	;@1FE5
	call PutChar	;@1FE7
	pop ax	;@1FEA
	cmp al, 59h	; 'Y'?	;@1FEB
	je Transport_Buy	;@1FED
	call PrintInline	; "O.K. BYE THEN..."	;@1FEF
	db 0Dh,4Fh,2Eh,4Bh,2Eh,20h,42h,59h,45h,20h,54h,48h,45h,4Eh,2Eh,2Eh	;@1FF2
	db 2Eh,0h	;@2002
	jmp EndCommand	;@2004
Transport_Buy:	call PayPrice	; pay	;@2007
	call PrintInline	; "RIDE SWIFTLY!"	;@200A
	db 8Dh,52h,49h,44h,45h,20h,53h,57h,49h,46h,54h,4Ch,59h,21h,0h	;@200D
	mov al, 22h	;@201C
	mov byte ptr PlayerTile, al	; transport = horse	;@201E
	jmp EndCommand	;@2021
; dead: "nop; jmp EndCommand" (90 E9 0B EA) that nothing reaches, kept as bytes
	db 90h,0E9h,0Bh,0EAh	;@2024
CODE ENDS
END
