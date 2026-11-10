; CMDMZ.ASM: commands M-Z (magic, negate, offer, pass, quit, ready, steal, ...); status.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 3B92-48CD.
;
; The handlers for the player commands M to Z, reached through the jump table CmdJumpTbl in MAIN
; (`jmp bx` at 0A2E). Each one prints its own command name, does its work and ends with
; `jmp EndCommand` (end of command: CR, then the monsters' turn) or `jmp EndCommandBeep` (the same after an
; error beep, used for "you can't do that here"). None of them returns.
;   M CmdMagic Magic (ready a spell)   N CmdNegateTime Negate time    O CmdOffer Offer gold   P CmdPass Pass
;   Q CmdQuit Quit and save           R CmdReady Ready weapon   S CmdSteal Steal        T CmdTransact Transact
;   U CmdUnlock Unlock                  V CmdView View (helm)    W CmdWear Wear armour  X CmdXit X-it
;   Y CmdYell Yell                    Z CmdZtats Ztats (the status screen, in 40-column text mode)
; Data mostly used: the character (PlayerSex-Intelligence sex, class, race, attributes), the BCD
; inventory counts (weapons WeaponCounts[1..9], armour ArmourCounts[1..6], spells SpellCounts[1..9], items
; ItemCounts[0..15]), the readied weapon/armour/spell ReadyWeapon/WornArmour/ReadySpell, torches/keys/tools
; Torches/Keys/Tools, and the monster tables of the current map (MonsterTile type, MonsterMood mood
; or talk number, indexed 1..1Fh). Names of weapons, armour, spells, items, attributes, races
; and classes are printed from the string table NameStrTbl with PrintNameStr (see the index bases below).
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN PlayerX:BYTE, PlayerY:BYTE, MapCellPtr:BYTE, PlayerTile:BYTE, TileHere:BYTE, DeltaX:BYTE
	EXTRN DeltaY:BYTE, Temp1F:BYTE, Temp20:BYTE, LookX:BYTE, LookY:BYTE, AmountHi:BYTE
	EXTRN AmountLo:BYTE, CursorCol:BYTE, TextRightCol:BYTE, PlayerSex:BYTE, PlayerClass:BYTE, PlayerRace:BYTE
	EXTRN TimeZone:BYTE, MapType:BYTE, Strength:BYTE, Agility:BYTE, Stamina:BYTE, Charisma:BYTE
	EXTRN Wisdom:BYTE, Intelligence:BYTE, HitPointsHi:BYTE, FoodHi:BYTE, ExpHi:BYTE, ReadyWeapon:BYTE
	EXTRN WornArmour:BYTE, ReadySpell:BYTE, Torches:BYTE, Keys:BYTE, Tools:BYTE, RingEarned:BYTE
	EXTRN Planet:BYTE, WeaponCounts:BYTE, QuickSwordCount:BYTE, ArmourCounts:BYTE, SpellCounts:BYTE, ItemCounts:BYTE
	EXTRN Helms:BYTE, StrangeCoins:BYTE, MonsterTile:BYTE, MonsterMood:BYTE, TimeStopTurns:BYTE, TileCache:BYTE
	EXTRN TileCacheShown:BYTE, TextLeftCol:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN SpeedDelay:NEAR, EndCommandBeep:NEAR, EndCommand:NEAR, AlertTownGuards:NEAR, PrintTalkString:NEAR
	EXTRN ShopDispatch:NEAR
	EXTRN ReadDigit:NEAR, PayPrice:NEAR, SaveGame:NEAR, ReadDirection:NEAR, FindMonsterInDir:NEAR, DrawHelmMap:NEAR
	EXTRN SetTextMode:NEAR, SetGraphicsMode:NEAR, ReadKey:NEAR, PrintInline:NEAR, PrintSex:NEAR
	EXTRN PrintPlayerName:NEAR
	EXTRN PrintNameStr:NEAR, GetMapSquare:NEAR, DrawStatusLines:NEAR, PrintBcdWord:NEAR, SetCursor:NEAR
	EXTRN UpdateBiosCursor:NEAR
	EXTRN Random:NEAR, PrintBcdByte:NEAR, PutChar:NEAR
	PUBLIC CmdMagic, CmdNegateTime, CmdOffer, CmdPass, CmdQuit, CmdReady
	PUBLIC CmdSteal, CmdTransact, CmdUnlock, CmdView, CmdWear, CmdXit
	PUBLIC CmdYell, CmdZtats
ASSUME CS:CODE, DS:DATA

;------------------------------------------------------------------------------
; CmdMagic (M): Magic. Asks for a spell number 0-9 and makes it the readied spell
; ReadySpell, printing its name (NameStrTbl string 24h+n: NONE, LIGHT, ..., KILL).
; There is no check that the spell has been bought (Cast checks that).
;------------------------------------------------------------------------------
CmdMagic:	call PrintInline	;@3B92
	db 4Dh,41h,47h,49h,43h,20h,53h,50h,45h,4Ch,4Ch,20h,52h,45h,41h,44h	;@3B95
	db 59h,20h,23h,0h	;@3BA5
	call ReadDigit	; read a digit 0-9	;@3BA9
	mov byte ptr ReadySpell, al	; readied spell	;@3BAC
	call PrintInline	;@3BAF
	db 53h,50h,45h,4Ch,4Ch,20h,52h,45h,41h,44h,59h,20h,3Dh,3Eh,20h,0h	;@3BB2
	mov al, byte ptr ReadySpell	;@3BC2
	clc	;@3BC5
	adc al, 24h	; 24h = spell names in NameStrTbl	;@3BC6
	call PrintNameStr	;@3BC8
	jmp EndCommand	;@3BCB

;------------------------------------------------------------------------------
; CmdNegateTime (N): Negate time. Uses up one strange coin (StrangeCoins = item 13) and sets
; the time-stop counter TimeStopTurns to 20 (MAIN 0C54 counts it down once a turn;
; while it runs the monsters are frozen, probably). Without a coin: "HOW?
; YOU'RE NOT EINSTEIN".
;------------------------------------------------------------------------------
CmdNegateTime:	call PrintInline	;@3BCE
	db 4Eh,45h,47h,41h,54h,45h,20h,54h,49h,4Dh,45h,0h	;@3BD1
	mov al, byte ptr StrangeCoins	; strange coins (BCD)	;@3BDD
	or al, al	;@3BE0
	jne NegateTime_UseCoin	;@3BE2
	call PrintInline	;@3BE4
	db 20h,48h,4Fh,57h,3Fh,8Dh,59h,4Fh,55h,27h,52h,45h,20h,4Eh,4Fh,54h	;@3BE7
	db 20h,45h,49h,4Eh,53h,54h,45h,49h,4Eh,0h	;@3BF7
	jmp EndCommand	;@3C01
NegateTime_UseCoin:	stc	;@3C04
	mov al, byte ptr StrangeCoins	;@3C05
	cmc	;@3C08
	sbb al, 1	;@3C09
	das	;@3C0B
	cmc	;@3C0C
	mov byte ptr StrangeCoins, al	;@3C0D
	call PrintInline	;@3C10
	db 8Dh,59h,4Fh,55h,20h,52h,55h,42h,20h,41h,20h,43h,4Fh,49h,4Eh,2Eh	;@3C13
	db 2Eh,2Eh,0h	;@3C23
	mov al, 14h	; 20 turns	;@3C26
	mov byte ptr TimeStopTurns, al	; time-stop counter	;@3C28
	jmp EndCommand	;@3C2B

;------------------------------------------------------------------------------
; CmdOffer (O): Offer gold. Asks a direction and finds the monster/person there
; (FindMonsterInDir: DI = its index 1..1Fh, 0 = nobody), asks an amount n*100 (one digit)
; and takes it (PayPrice aborts the command with "YOU DONT HAVE THAT MUCH!").
; The gold is just "thanked" for, unless the person has a talk number
; (MonsterMood bit 7) and the map is type 2 (MapType) of time zone 3 (TimeZone):
;   talk 81h: with >= 500 gold, the quick sword "ENILNO" (QuickSwordCount = 1)
;   talk 82h: with >= 500 gold and RingEarned set by Transact, the ring (ItemCounts = 1)
;   talk 83h: one more of a random weapon 1-8 ("HERE TAKE THIS!")
;   other:    6 in 8, a random attribute + 4*n ("ALAKAZAM!"), else thanks.
; Temp: Temp1F = the person's index, AmountHi/AmountLo = BCD amount.
;------------------------------------------------------------------------------
CmdOffer:	call PrintInline	;@3C2E
	db 4Fh,46h,46h,45h,52h,20h,47h,4Fh,4Ch,44h,20h,44h,49h,52h,45h,43h	;@3C31
	db 54h,2Dh,0h	;@3C41
	call ReadDirection	; read a direction into DeltaX/DeltaY	;@3C44
	call FindMonsterInDir	; DI = monster at that square, or 0	;@3C47
	mov bx, di	;@3C4A
	mov byte ptr Temp1F, bl	;@3C4C
	mov al, 8Dh	; CR	;@3C50
	call PutChar	;@3C52
	mov bx, di	;@3C55
	cmp bl, 0	;@3C57
	jne Offer_AskAmount	;@3C5A
	call PrintInline	;@3C5C
	db 4Fh,46h,46h,45h,52h,20h,54h,4Fh,20h,57h,48h,4Fh,4Dh,3Fh,0h	;@3C5F
	jmp EndCommand	;@3C6E
Offer_AskAmount:	call PrintInline	;@3C71
	db 48h,4Fh,57h,20h,4Dh,55h,43h,48h,20h,28h,2Ah,31h,30h,30h,29h,20h	;@3C74
	db 3Fh,20h,0h	;@3C84
	call ReadDigit	; digit 0-9 = hundreds of gold	;@3C87
	mov byte ptr AmountHi, al	; BCD amount, high byte	;@3C8A
	mov al, 0	;@3C8D
	mov byte ptr AmountLo, al	; low byte	;@3C8F
	call PayPrice	; pay it (aborts if too little gold)	;@3C92
	mov bh, 0	;@3C95
	mov bl, byte ptr Temp1F	;@3C97
	mov di, bx	;@3C9B
	mov al, byte ptr MonsterMood[di]	;@3C9D
	or al, al	;@3CA1
	jns Offer_ThankYou	; no talk number: just thanks	;@3CA3
	mov al, byte ptr MapType	;@3CA5
	cmp al, 2	; map type 2 (towne?)	;@3CA8
	jne Offer_ThankYou	;@3CAA
	mov al, byte ptr TimeZone	;@3CAC
	cmp al, 3	; time zone 3	;@3CAF
	jne Offer_ThankYou	;@3CB1
	jmp Offer_Special	;@3CB3
; The gold is gone, nothing in return.
Offer_ThankYou:	nop	;@3CB6
	call PrintInline	;@3CB7
	db 54h,48h,41h,4Eh,4Bh,20h,59h,4Fh,55h,20h,56h,45h,52h,59h,20h,4Dh	;@3CBA
	db 55h,43h,48h,21h,0h	;@3CCA
	jmp EndCommand	;@3CCF
; A special person: what happens depends on its talk number.
Offer_Special:	mov bh, 0	;@3CD2
	mov bl, byte ptr Temp1F	;@3CD4
	mov di, bx	;@3CD8
	mov al, byte ptr MonsterMood[di]	;@3CDA
	cmp al, 81h	;@3CDE
	je Offer_QuickSword	;@3CE0
	cmp al, 82h	;@3CE2
	je Offer_Ring	;@3CE4
	cmp al, 83h	;@3CE6
	je Offer_Weapon	;@3CE8
	jmp Offer_Attribute	;@3CEA
; Talk 81h: the quick sword for 500 gold or more.
Offer_QuickSword:	mov al, byte ptr AmountHi	;@3CED
	cmp al, 5	; at least 500 gold?	;@3CF0
	jb Offer_ThankYou	;@3CF2
	call PrintInline	;@3CF4
	db 45h,4Eh,49h,4Ch,4Eh,4Fh,20h,49h,53h,20h,59h,4Fh,55h,52h,53h,21h	;@3CF7
	db 0h	;@3D07
	mov al, 1	;@3D08
	mov byte ptr QuickSwordCount, al	; weapon 9 (quick sword) count = 1	;@3D0A
	jmp EndCommand	;@3D0D
; Talk 82h: the ring for 500 gold or more, once Transact has set RingEarned.
Offer_Ring:	mov al, byte ptr AmountHi	;@3D10
	cmp al, 5	;@3D13
	jb Offer_ThankYou	;@3D15
	mov al, byte ptr RingEarned	; ring earned (set at 4243)	;@3D17
	or al, al	;@3D1A
	jne Offer_GiveRing	;@3D1C
	call PrintInline	;@3D1E
	db 45h,41h,52h,4Eh,20h,54h,48h,45h,20h,52h,49h,4Eh,47h,21h,0h	;@3D21
	jmp EndCommand	;@3D30
Offer_GiveRing:	nop	;@3D33
	call PrintInline	;@3D34
	db 54h,48h,45h,20h,52h,49h,4Eh,47h,20h,49h,53h,20h,59h,4Fh,55h,52h	;@3D37
	db 53h,21h,0h	;@3D47
	mov al, 1	;@3D4A
	mov byte ptr ItemCounts, al	; item 0 (ring) count = 1	;@3D4C
	jmp EndCommand	;@3D4F
; Talk 83h: a random weapon 1-8 (dagger..phaser), any amount.
Offer_Weapon:	call Random	; random	;@3D52
	and al, 7	;@3D55
	clc	;@3D57
	mov ah, 0	;@3D58
	mov di, ax	;@3D5A
	inc di	;@3D5C
	mov al, byte ptr WeaponCounts[di]	;@3D5D
	adc al, 1	; BCD count + 1 (99 wraps to 00)	;@3D61
	daa	;@3D63
	mov byte ptr WeaponCounts[di], al	;@3D64
	call PrintInline	;@3D68
	db 48h,45h,52h,45h,20h,54h,41h,4Bh,45h,20h,54h,48h,49h,53h,21h,0h	;@3D6B
	jmp EndCommand	;@3D7B
; Any other talk number: 6 in 8, attribute 0-5 (strength..intelligence) + 4*n.
Offer_Attribute:	call Random	;@3D7E
	and al, 7	;@3D81
	cmp al, 6	;@3D83
	jb Offer_RaiseAttribute	;@3D85
	jmp Offer_ThankYou	;@3D87
Offer_RaiseAttribute:	nop	;@3D8A
	mov ah, 0	;@3D8B
	mov di, ax	;@3D8D
; Four BCD additions of the amount; no limit: past 99 the attribute wraps.
	clc	;@3D8F
	mov al, byte ptr Strength[di]	;@3D90
	adc al, byte ptr AmountHi	;@3D94
	daa	;@3D98
	adc al, byte ptr AmountHi	;@3D99
	daa	;@3D9D
	adc al, byte ptr AmountHi	;@3D9E
	daa	;@3DA2
	adc al, byte ptr AmountHi	;@3DA3
	daa	;@3DA7
	mov byte ptr Strength[di], al	;@3DA8
	call PrintInline	;@3DAC
	db 41h,4Ch,41h,4Bh,41h,5Ah,41h,4Dh,21h,0h	;@3DAF
	jmp EndCommand	;@3DB9

;------------------------------------------------------------------------------
; CmdPass (P): Pass. Prints "PASS" and lets a turn go by.
;------------------------------------------------------------------------------
CmdPass:	call PrintInline	;@3DBC
	db 50h,41h,53h,53h,0h	;@3DBF
	jmp EndCommand	;@3DC4

;------------------------------------------------------------------------------
; CmdQuit (Q): Quit and save game. Only outdoors (MapType = 0), on Earth
; (Planet = 0) and on foot (PlayerTile >= 78h, the player figure, not a
; vehicle); then "ONE MOMENT PLEASE!" and SaveGame writes the map, monster and
; player files. The game goes on afterwards (it does not exit to DOS).
;------------------------------------------------------------------------------
CmdQuit:	call PrintInline	;@3DC7
	db 51h,55h,49h,54h,20h,4Fh,52h,20h,53h,41h,56h,45h,20h,47h,41h,4Dh	;@3DCA
	db 45h,2Eh,0h	;@3DDA
	mov al, byte ptr MapType	; map type, 0 = outdoors	;@3DDD
	or al, al	;@3DE0
	je Quit_CheckEarth	;@3DE2
	call PrintInline	;@3DE4
	db 8Dh,4Fh,4Eh,4Ch,59h,20h,4Fh,55h,54h,44h,4Fh,4Fh,52h,53h,21h,0h	;@3DE7
	jmp EndCommandBeep	;@3DF7
Quit_CheckEarth:	mov al, byte ptr Planet	; planet, 0 = Earth	;@3DFA
	or al, al	;@3DFD
	je Quit_CheckOnFoot	;@3DFF
	call PrintInline	;@3E01
	db 8Dh,4Fh,4Eh,4Ch,59h,20h,4Fh,4Eh,20h,45h,41h,52h,54h,48h,21h,0h	;@3E04
	jmp EndCommandBeep	;@3E14
Quit_CheckOnFoot:	mov al, byte ptr PlayerTile	; player tile; >= 78h = on foot	;@3E17
	cmp al, 78h	;@3E1A
	jae Quit_Save	;@3E1C
	call PrintInline	;@3E1E
	db 8Dh,4Fh,4Eh,4Ch,59h,20h,4Fh,4Eh,20h,46h,4Fh,4Fh,54h,21h,0h	;@3E21
	jmp EndCommandBeep	;@3E30
Quit_Save:	call PrintInline	;@3E33
	db 8Dh,4Fh,4Eh,45h,20h,4Dh,4Fh,4Dh,45h,4Eh,54h,20h,50h,4Ch,45h,41h	;@3E36
	db 53h,45h,21h,0h	;@3E46
	call SaveGame	; save MAPxx, MONxx and PLAYER	;@3E4A
	jmp EndCommand	;@3E4D

;------------------------------------------------------------------------------
; CmdReady (R): Ready weapon. Asks a weapon number 0-9 (0 = hands, 1 dagger ..
; 9 quick sword; names at NameStrTbl 13h+n) and makes it the readied weapon ReadyWeapon
; if it is owned (WeaponCounts[n] <> 0; hands always are) and the agility Agility
; is above n*8. That compares a binary n*8 with a BCD agility, so the real
; limits are 08,10,18,20,28,30,38,40,48 (decimal) for weapons 1-9.
; Temp: Temp1F = n.
;------------------------------------------------------------------------------
CmdReady:	call PrintInline	;@3E50
	db 52h,45h,41h,44h,59h,20h,57h,45h,41h,50h,4Fh,4Eh,3Ah,0Dh,31h,2Dh	;@3E53
	db 44h,41h,2Ch,20h,32h,2Dh,4Dh,41h,2Ch,20h,33h,2Dh,41h,58h,2Ch,20h	;@3E63
	db 34h,2Dh,42h,4Fh,2Ch,0Dh,35h,2Dh,53h,57h,2Ch,20h,36h,2Dh,47h,52h	;@3E73
	db 2Ch,20h,37h,2Dh,4Ch,49h,2Ch,20h,38h,2Dh,50h,48h,2Eh,0Dh,39h,2Dh	;@3E83
	db 51h,55h,2Ch,20h,57h,48h,49h,43h,48h,3Fh,20h,0h	;@3E93
	call ReadDigit	; digit 0-9	;@3E9F
	mov byte ptr Temp1F, al	;@3EA2
	clc	;@3EA5
	adc al, 13h	; 13h = weapon names in NameStrTbl	;@3EA6
	call PrintNameStr	;@3EA8
	mov bh, 0	;@3EAB
	mov bl, byte ptr Temp1F	;@3EAD
	mov di, bx	;@3EB1
	mov al, byte ptr WeaponCounts[di]	; how many of that weapon	;@3EB3
	or al, al	;@3EB7
	jne Ready_CheckAgility	;@3EB9
	mov al, byte ptr Temp1F	;@3EBB
	or al, al	; hands need not be owned	;@3EBE
	je Ready_CheckAgility	;@3EC0
	call PrintInline	;@3EC2
	db 20h,4Eh,4Fh,54h,20h,4Fh,57h,4Eh,45h,44h,21h,0h	;@3EC5
	jmp EndCommandBeep	;@3ED1
Ready_CheckAgility:	mov al, byte ptr Temp1F	;@3ED4
	add al, al	;@3ED7
	add al, al	;@3ED9
	add al, al	; n*8 (binary)	;@3EDB
	cmp al, byte ptr Agility	; agility (BCD)	;@3EDD
	jb Ready_Done	;@3EE1
	call PrintInline	;@3EE3
	db 20h,3Ch,2Dh,54h,48h,4Fh,55h,20h,41h,52h,54h,20h,4Eh,4Fh,54h,20h	;@3EE6
	db 8Dh,41h,47h,49h,4Ch,45h,20h,45h,4Eh,4Fh,55h,47h,48h,20h,54h,4Fh	;@3EF6
	db 20h,57h,49h,45h,4Ch,44h,21h,0h	;@3F06
	jmp EndCommand	;@3F0E
Ready_Done:	call PrintInline	;@3F11
	db 20h,52h,45h,41h,44h,59h,2Eh,0h	;@3F14
	mov al, byte ptr Temp1F	;@3F1C
	mov byte ptr ReadyWeapon, al	; readied weapon	;@3F1F
	jmp EndCommand	;@3F22

;------------------------------------------------------------------------------
; CmdSteal (S): Steal. Asks a direction. The square there must be a shop counter
; (map code 7Ch, or any code >= 80h) with a merchant (68h) one square beyond.
; Then, unless the town is alarmed (MonsterMood[0] = 1): a thief (class 3) needs
; one coin flip, the others two. The quadrant of the map decides the goods:
;   map type 1, x >= 20h, y < 20h: +100 food (FoodHi, the food shop corner)
;   map type 2, x >= 20h, y < 20h: one more of a random armour 1-4
;   map type 2, x <  20h, y < 20h: one more of a random weapon 1-8
; Failure: "NO LUCK!", and 1 in 8 the guards are alarmed (AlertTownGuards).
; Uses LookX/LookY (the square looked at), DeltaX/DeltaY (direction).
;------------------------------------------------------------------------------
CmdSteal:	call PrintInline	;@3F25
	db 53h,54h,45h,41h,4Ch,20h,44h,49h,52h,45h,43h,54h,2Dh,0h	;@3F28
	call ReadDirection	; read a direction into DeltaX/DeltaY	;@3F36
; LookX/LookY = player position PlayerX/PlayerY + direction.
	clc	;@3F39
	mov al, byte ptr PlayerX	;@3F3A
	adc al, byte ptr DeltaX	;@3F3D
	mov byte ptr LookX, al	;@3F41
	clc	;@3F44
	mov al, byte ptr PlayerY	;@3F45
	adc al, byte ptr DeltaY	;@3F48
	mov byte ptr LookY, al	;@3F4C
	mov al, 8Dh	; CR	;@3F4F
	call PutChar	;@3F51
	call GetMapSquare	; AL = map code at LookX/LookY	;@3F54
	js Steal_LookBehind	; >= 80h: counter?	;@3F57
	cmp al, 7Ch	; counter	;@3F59
	jne Steal_NoLuck	;@3F5B
; Look one square further in the same direction: is a merchant behind it?
Steal_LookBehind:	nop	;@3F5D
	clc	;@3F5E
	mov al, byte ptr LookX	;@3F5F
	adc al, byte ptr DeltaX	;@3F62
	mov byte ptr LookX, al	;@3F66
	clc	;@3F69
	mov al, byte ptr LookY	;@3F6A
	adc al, byte ptr DeltaY	;@3F6D
	mov byte ptr LookY, al	;@3F71
	call GetMapSquare	;@3F74
	cmp al, 68h	; merchant	;@3F77
	jne Steal_NoLuck	;@3F79
	jmp Steal_TryLuck	;@3F7B
; Failed. AlertTownGuards uses Temp20 as the victim's index, but Steal never sets it
; (it holds what ReadDirection left there, usually 0).
Steal_NoLuck:	call PrintInline	;@3F7E
	db 4Eh,4Fh,20h,4Ch,55h,43h,4Bh,21h,0h	;@3F81
	call Random	;@3F8A
	and al, 7	;@3F8D
	jne L3F94	;@3F8F
	call AlertTownGuards	; 1 in 8: alarm the guards	;@3F91
L3F94:	nop	;@3F94
	jmp EndCommand	;@3F95
; A merchant: try the luck.
Steal_TryLuck:	nop	;@3F98
	mov al, byte ptr PlayerClass	; class	;@3F99
	cmp al, 3	; thief: skip the first coin flip	;@3F9C
	je Steal_SecondFlip	;@3F9E
	call Random	;@3FA0
	js Steal_NoLuck	;@3FA3
Steal_SecondFlip:	nop	;@3FA5
	call Random	;@3FA6
	js Steal_NoLuck	;@3FA9
	mov al, byte ptr MonsterMood	; entry 0 = town alarmed flag	;@3FAB
	cmp al, 1	;@3FAE
	je Steal_NoLuck	;@3FB0
	mov al, byte ptr MapType	; map type	;@3FB2
	cmp al, 1	;@3FB5
	je Steal_Village	;@3FB7
	cmp al, 2	;@3FB9
	jne Steal_NoLuck	;@3FBB
; Map type 2: only the north half (y < 20h); east armour, west weapons.
	mov al, byte ptr PlayerY	;@3FBD
	cmp al, 20h	;@3FC0
	jae Steal_NoLuck	;@3FC2
	mov al, byte ptr PlayerX	;@3FC4
	cmp al, 20h	;@3FC7
	jae Steal_Armour	;@3FC9
	jmp Steal_Weapons	;@3FCB
; Map type 1: only the north-east quarter, food.
Steal_Village:	mov al, byte ptr PlayerY	;@3FCE
	cmp al, 20h	;@3FD1
	jae Steal_NoLuck	;@3FD3
	mov al, byte ptr PlayerX	;@3FD5
	cmp al, 20h	;@3FD8
	jb Steal_NoLuck	;@3FDA
	nop	;@3FDC
	call PrintInline	;@3FDD
	db 53h,54h,45h,41h,4Ch,20h,46h,4Fh,4Fh,44h,21h,0h	;@3FE0
	clc	;@3FEC
	mov al, byte ptr FoodHi	; food, high BCD byte (hundreds)	;@3FED
	adc al, 1	;@3FF0
	daa	;@3FF2
	mov byte ptr FoodHi, al	;@3FF3
	jmp EndCommand	;@3FF6
Steal_Armour:	nop	;@3FF9
	call PrintInline	;@3FFA
	db 53h,54h,45h,41h,4Ch,20h,41h,52h,4Dh,4Fh,55h,52h,21h,0h	;@3FFD
	call Random	;@400B
	and al, 3	;@400E
	mov ah, 0	;@4010
	mov di, ax	;@4012
	inc di	; armour 1-4 (cloth..plate)	;@4014
	clc	;@4015
	mov al, byte ptr ArmourCounts[di]	;@4016
	adc al, 1	;@401A
	daa	;@401C
	mov byte ptr ArmourCounts[di], al	;@401D
	jmp EndCommand	;@4021
Steal_Weapons:	nop	;@4024
	call PrintInline	;@4025
	db 53h,54h,45h,41h,4Ch,20h,57h,45h,41h,50h,4Fh,4Eh,53h,21h,0h	;@4028
	call Random	;@4037
	and al, 7	;@403A
	mov ah, 0	;@403C
	mov di, ax	;@403E
	inc di	; weapon 1-8 (dagger..phaser)	;@4040
	clc	;@4041
	mov al, byte ptr WeaponCounts[di]	;@4042
	adc al, 1	;@4046
	daa	;@4048
	mov byte ptr WeaponCounts[di], al	;@4049
	jmp EndCommand	;@404D

;------------------------------------------------------------------------------
; CmdTransact (T): Transact. Asks a direction. Outdoors nobody answers. In a town:
; - nobody there, but a counter with a merchant behind it (as in Steal):
;   the shop of that quarter of the map (ShopDispatch, in SHOPS; does not return here)
; - a person with a talk number (MonsterMood = 80h+n): prints talk string n from
;   the TLK file (PrintTalkString), waits a while; talk 81h in map type 3 on planet 9
;   also earns the ring (RingEarned = 1, see Offer)
; - else by the person's type MonsterTile: 6Ch the king (tribute, hit points),
;   60h guard, 64h jester, 68h merchant, F0h fighter, F4h cleric, F8h wizard,
;   FCh thief say their line; anyone else: "FUNNY, NO RESPONSE!".
; Temp: Temp20 = the person's index (DI from FindMonsterInDir).
;------------------------------------------------------------------------------
CmdTransact:	call PrintInline	;@4050
	db 54h,52h,41h,4Eh,53h,41h,43h,54h,2Dh,0h	;@4053
	call ReadDirection	; read a direction into DeltaX/DeltaY	;@405D
	call FindMonsterInDir	; DI = monster there, or 0; sets LookX/LookY	;@4060
	mov bx, di	;@4063
	mov byte ptr Temp20, bl	;@4065
	mov al, 8Dh	; CR	;@4069
	call PutChar	;@406B
	mov al, byte ptr MapType	; map type, 0 = outdoors	;@406E
	or al, al	;@4071
	je Transact_NoResponse	;@4073
	mov bx, di	;@4075
	cmp bl, 0	;@4077
	jne Transact_Person	;@407A
; Nobody there: a counter (7Ch or >= 80h) with a merchant (68h) behind it?
	call GetMapSquare	; AL = map code at LookX/LookY	;@407C
	js Transact_LookBehind	;@407F
	cmp al, 7Ch	;@4081
	jne Transact_NoResponse	;@4083
Transact_LookBehind:	nop	;@4085
	clc	;@4086
	mov al, byte ptr LookX	;@4087
	adc al, byte ptr DeltaX	;@408A
	mov byte ptr LookX, al	;@408E
	clc	;@4091
	mov al, byte ptr LookY	;@4092
	adc al, byte ptr DeltaY	;@4095
	mov byte ptr LookY, al	;@4099
	call GetMapSquare	;@409C
	cmp al, 68h	;@409F
	jne Transact_NoResponse	;@40A1
	jmp ShopDispatch	; enter the shop	;@40A3
Transact_NoResponse:	call PrintInline	;@40A6
	db 46h,55h,4Eh,4Eh,59h,2Ch,20h,4Eh,4Fh,20h,52h,45h,53h,50h,4Fh,4Eh	;@40A9
	db 53h,45h,21h,0h	;@40B9
	jmp EndCommand	;@40BD
; Somebody there.
Transact_Person:	mov al, byte ptr MonsterMood[di]	;@40C0
	cmp al, 80h	; >= 80h: has a talk string	;@40C4
	jb Transact_ByType	;@40C6
	jmp Transact_Talk	;@40C8
Transact_ByType:	nop	;@40CB
	mov al, byte ptr MonsterTile[di]	; monster type (its map code)	;@40CC
	cmp al, 6Ch	; the king	;@40D0
	jne Transact_Guard	;@40D2
	jmp Transact_King	;@40D4
Transact_Guard:	nop	;@40D7
	mov al, byte ptr MonsterTile[di]	;@40D8
	cmp al, 60h	; guard	;@40DC
	jne Transact_Jester	;@40DE
	call PrintInline	;@40E0
	db 41h,20h,47h,55h,41h,52h,44h,20h,53h,41h,59h,53h,3Ah,0Dh,50h,41h	;@40E3
	db 59h,20h,59h,4Fh,55h,52h,20h,54h,41h,58h,45h,53h,21h,0h	;@40F3
	jmp EndCommand	;@4101
Transact_Jester:	cmp al, 64h	; jester	;@4104
	jne Transact_Merchant	;@4106
	call PrintInline	;@4108
	db 41h,20h,4Ah,45h,53h,54h,45h,52h,20h,53h,49h,4Eh,47h,53h,3Ah,0Dh	;@410B
	db 48h,4Fh,20h,48h,4Fh,20h,48h,4Fh,21h,0h	;@411B
	jmp EndCommand	;@4125
Transact_Merchant:	cmp al, 68h	; merchant	;@4128
	jne Transact_Fighter	;@412A
	call PrintInline	;@412C
	db 41h,20h,4Dh,45h,52h,43h,48h,41h,4Eh,54h,20h,53h,41h,59h,53h,3Ah	;@412F
	db 0Dh,57h,49h,4Ch,4Ch,20h,59h,4Fh,55h,20h,42h,55h,59h,20h,4Dh,59h	;@413F
	db 20h,41h,50h,50h,4Ch,45h,53h,3Fh,0h	;@414F
	jmp EndCommand	;@4158
Transact_Fighter:	cmp al, 0F0h	; fighter	;@415B
	jne Transact_Cleric	;@415D
	call PrintInline	;@415F
	db 41h,20h,46h,49h,47h,48h,54h,45h,52h,20h,53h,41h,59h,53h,3Ah,0Dh	;@4162
	db 55h,47h,48h,2Ch,20h,4Dh,45h,20h,54h,4Fh,55h,47h,48h,21h,0h	;@4172
	jmp EndCommand	;@4181
Transact_Cleric:	cmp al, 0F4h	; cleric	;@4184
	jne Transact_Wizard	;@4186
	call PrintInline	;@4188
	db 41h,20h,43h,4Ch,45h,52h,49h,43h,20h,53h,41h,59h,53h,3Ah,0Dh,42h	;@418B
	db 45h,4Ch,49h,45h,56h,45h,21h,0h	;@419B
	jmp EndCommand	;@41A3
Transact_Wizard:	cmp al, 0F8h	; wizard	;@41A6
	jne Transact_Thief	;@41A8
	call PrintInline	;@41AA
	db 41h,20h,57h,49h,5Ah,41h,52h,44h,20h,53h,41h,59h,53h,3Ah,0Dh,48h	;@41AD
	db 45h,58h,2Dh,45h,2Dh,50h,4Fh,4Fh,2Dh,48h,45h,58h,2Dh,4Fh,4Eh,2Dh	;@41BD
	db 59h,4Fh,55h,21h,0h	;@41CD
	jmp EndCommand	;@41D2
Transact_Thief:	cmp al, 0FCh	; thief	;@41D5
	jne Transact_Other	;@41D7
	call PrintInline	;@41D9
	db 41h,20h,54h,48h,49h,45h,46h,20h,53h,41h,59h,53h,3Ah,0Dh,50h,53h	;@41DC
	db 53h,54h,2Ch,20h,57h,41h,4Eh,4Eh,41h,20h,42h,55h,59h,20h,41h,20h	;@41EC
	db 57h,41h,54h,43h,48h,3Fh,0h	;@41FC
	jmp EndCommand	;@4203
Transact_Other:	jmp Transact_NoResponse	;@4206
; A person with a talk string: AL = MonsterMood[di] = 80h + n.
Transact_Talk:	stc	;@4209
	cmc	;@420A
	sbb al, 80h	; stc/cmc/sbb = 6502 SEC/SBC: AL = n	;@420B
	cmc	;@420D
	call PrintTalkString	; print the n-th string of the talk buffer	;@420E
; A pause to read it: 3 x (65535 empty loops + SpeedDelay delay 4), CPU-speed dependent.
	mov di, 3	;@4211
Transact_Pause:	mov si, 0FFFFh	;@4214
Transact_PauseInner:	dec si	;@4217
	jne Transact_PauseInner	;@4218
	mov bx, 4	;@421A
	call SpeedDelay	;@421D
	dec di	;@4220
	jne Transact_Pause	;@4221
	mov bh, 0	;@4223
	mov bl, byte ptr Temp20	;@4225
	mov di, bx	;@4229
	mov al, byte ptr Planet	;@422B
	cmp al, 9	; planet 9 (planet X?)	;@422E
	jne Transact_Done	;@4230
	mov al, byte ptr MapType	;@4232
	cmp al, 3	; map type 3	;@4235
	jne Transact_Done	;@4237
	mov al, byte ptr MonsterMood[di]	;@4239
	cmp al, 81h	; talk string 1	;@423D
	jne Transact_Done	;@423F
	mov al, 1	;@4241
	mov byte ptr RingEarned, al	; the ring is earned (Offer 3D17)	;@4243
Transact_Done:	jmp EndCommand	;@4246
; The king (Lord British?): takes 50 gold, then raises the hit points by 300
; below 5000, by 200 below 7500, by 100 below 9900, else by 0 (HitPointsHi = HP/100).
Transact_King:	nop	;@4249
	call PrintInline	;@424A
	db 57h,45h,4Ch,43h,4Fh,4Dh,45h,20h,4Dh,59h,20h,43h,48h,49h,4Ch,44h	;@424D
	db 20h,0h	;@425D
	call PrintPlayerName	; print the player's name	;@425F
	call PrintInline	;@4262
	db 8Dh,46h,49h,52h,53h,54h,20h,4Dh,59h,20h,35h,30h,20h,47h,2Eh,50h	;@4265
	db 2Eh,20h,54h,52h,49h,42h,55h,54h,45h,21h,8Dh,0h	;@4275
	mov al, 50h	; BCD 0050 gold	;@4281
	mov byte ptr AmountLo, al	;@4283
	mov al, 0	;@4286
	mov byte ptr AmountHi, al	;@4288
	call PayPrice	; pay (aborts if too little gold)	;@428B
	call PrintInline	;@428E
	db 41h,4Eh,44h,20h,46h,4Fh,52h,20h,49h,54h,20h,49h,20h,52h,41h,49h	;@4291
	db 53h,45h,20h,54h,48h,45h,45h,20h,0h	;@42A1
	mov al, byte ptr HitPointsHi	; hit points / 100 (BCD)	;@42AA
	mov bh, 0	;@42AD
	mov bl, 3	;@42AF
	mov di, bx	;@42B1
	cmp al, 50h	;@42B3
	jb King_Raise	;@42B5
	mov bh, 0	;@42B7
	mov bl, 2	;@42B9
	mov di, bx	;@42BB
	cmp al, 75h	;@42BD
	jb King_Raise	;@42BF
	mov bh, 0	;@42C1
	mov bl, 1	;@42C3
	mov di, bx	;@42C5
	cmp al, 99h	;@42C7
	jb King_Raise	;@42C9
	mov bh, 0	;@42CB
	mov bl, 0	;@42CD
	mov di, bx	;@42CF
King_Raise:	mov bx, di	;@42D1
	mov byte ptr Temp1F, bl	; the raise, in hundreds	;@42D3
	mov ax, di	;@42D7
	mov bh, 0	;@42D9
	mov bl, 0	;@42DB
	mov di, bx	;@42DD
	call PrintBcdWord	; print AL, DI as 4 BCD digits ("0300")	;@42DF
	clc	;@42E2
	mov al, byte ptr HitPointsHi	;@42E3
	adc al, byte ptr Temp1F	;@42E6
	daa	;@42EA
	mov byte ptr HitPointsHi, al	;@42EB
	jmp EndCommand	;@42EE

;------------------------------------------------------------------------------
; CmdUnlock (U): Unlock. Asks a direction; only east or west count (DeltaX <> 0;
; the row stays PlayerY), so doors can only be unlocked sideways (the maps put every locked
; door in a north-south wall, so this never matters). The square
; must hold a locked door (map code 0A0h) and a key is used up (Keys). The
; door is replaced by the tile the player stands on (TileHere, map code/2).
;------------------------------------------------------------------------------
CmdUnlock:	call PrintInline	;@42F1
	db 55h,4Eh,4Ch,4Fh,43h,4Bh,20h,44h,49h,52h,45h,43h,54h,49h,4Fh,4Eh	;@42F4
	db 2Dh,0h	;@4304
	call ReadDirection	; read a direction into DeltaX/DeltaY	;@4306
	mov al, byte ptr DeltaX	; east/west part	;@4309
	or al, al	;@430C
	jne Unlock_CheckDoor	;@430E
Unlock_NoDoor:	call PrintInline	;@4310
	db 8Dh,4Eh,4Fh,20h,44h,4Fh,4Fh,52h,20h,54h,48h,45h,52h,45h,21h,0h	;@4313
	jmp EndCommandBeep	;@4323
Unlock_CheckDoor:	mov al, byte ptr PlayerY	;@4326
	mov byte ptr LookY, al	;@4329
	mov al, byte ptr PlayerX	;@432C
	clc	;@432F
	adc al, byte ptr DeltaX	;@4330
	mov byte ptr LookX, al	;@4334
	call GetMapSquare	; AL = map code there, MapCellPtr -> the map cell	;@4337
	cmp al, 0A0h	; locked door	;@433A
	jne Unlock_NoDoor	;@433C
	mov al, byte ptr Keys	; keys (BCD)	;@433E
	or al, al	;@4341
	jne Unlock_UseKey	;@4343
	call PrintInline	;@4345
	db 8Dh,4Eh,4Fh,20h,4Bh,45h,59h,53h,20h,54h,48h,41h,54h,20h,46h,49h	;@4348
	db 54h,21h,0h	;@4358
	jmp EndCommandBeep	;@435B
Unlock_UseKey:	stc	;@435E
	mov al, byte ptr Keys	;@435F
	cmc	;@4362
	sbb al, 1	;@4363
	das	;@4365
	cmc	;@4366
	mov byte ptr Keys, al	; one key less	;@4367
	mov al, byte ptr TileHere	; tile under the player	;@436A
	add al, al	; as a map code	;@436D
	mov bh, 0	;@436F
	mov bl, 0	;@4371
	mov di, bx	;@4373
	mov bx, word ptr MapCellPtr[di]	; the door's map cell	;@4375
	mov byte ptr [bx], al	;@4379
	jmp EndCommand	;@437B

;------------------------------------------------------------------------------
; CmdView (V): View. With a magical helm (Helms = item 5), and not in a dungeon
; or tower (MapType < 4): uses up the helm, shows the whole map from above
; (DrawHelmMap centred on 20h,20h), waits for a key, then marks the map window's
; tile caches TileCache/TileCacheShown as invalid (FFh) so the normal view is redrawn.
;------------------------------------------------------------------------------
CmdView:	mov al, byte ptr Helms	; magical helms (BCD)	;@437E
	or al, al	;@4381
	jne View_CheckMap	;@4383
View_What:	call PrintInline	;@4385
	db 56h,49h,45h,57h,20h,57h,48h,41h,54h,3Fh,0h	;@4388
	jmp EndCommand	;@4393
View_CheckMap:	mov al, byte ptr MapType	;@4396
	cmp al, 4	; 4, 5 = dungeon, tower?	;@4399
	jae View_What	;@439B
	call PrintInline	;@439D
	db 56h,49h,45h,57h,8Dh,57h,49h,54h,48h,20h,4Dh,41h,47h,49h,43h,41h	;@43A0
	db 4Ch,20h,48h,45h,4Ch,4Dh,21h,0h	;@43B0
	stc	;@43B8
	mov al, byte ptr Helms	;@43B9
	cmc	;@43BC
	sbb al, 1	;@43BD
	das	;@43BF
	cmc	;@43C0
	mov byte ptr Helms, al	; one helm less	;@43C1
	mov al, 20h	; the map centre	;@43C4
	mov byte ptr LookX, al	;@43C6
	mov byte ptr LookY, al	;@43C9
	call DrawHelmMap	; draw the whole map (DUNGEON module)	;@43CC
View_WaitKey:	call ReadKey	; wait for an ASCII key (AH = FFh)	;@43CF
	cmp ah, 0FFh	;@43D2
	jne View_WaitKey	;@43D5
; Fill entries FFh..1, then 0, of both tile caches with FFh ("unknown").
	mov bh, 0	;@43D7
	mov bl, 0FFh	;@43D9
	mov di, bx	;@43DB
	mov al, 0FFh	;@43DD
View_ClearCache:	mov byte ptr TileCache[di], al	;@43DF
	mov byte ptr TileCacheShown[di], al	;@43E3
	dec di	;@43E7
	jne View_ClearCache	;@43E8
	mov byte ptr TileCache, al	;@43EA
	mov byte ptr TileCacheShown, al	;@43ED
	jmp EndCommand	;@43F0

;------------------------------------------------------------------------------
; CmdWear (W): Wear armour. Asks an armour number 0-6 (7-9 become 0 = skin;
; 1 cloth .. 6 power; names at NameStrTbl 1Dh+n) and makes it the worn armour
; WornArmour if owned (ArmourCounts[n] <> 0; skin always is) and the strength Strength is
; above n*8 (binary against BCD, as in Ready: real limits 08,10,..,30). Checked in play:
; strength 30 wears reflect (5).
; Unlike Ready, "NOT OWNED!" ends without the error beep.
; Temp: Temp1F = n.
;------------------------------------------------------------------------------
CmdWear:	call PrintInline	;@43F3
	db 57h,45h,41h,52h,20h,41h,52h,4Dh,4Fh,55h,52h,3Ah,0Dh,31h,2Dh,43h	;@43F6
	db 4Ch,4Fh,54h,48h,2Ch,20h,32h,2Dh,4Ch,45h,41h,54h,48h,45h,52h,2Ch	;@4406
	db 20h,33h,2Dh,43h,48h,41h,49h,4Eh,2Ch,0Dh,34h,2Dh,50h,4Ch,41h,54h	;@4416
	db 45h,2Ch,20h,35h,2Dh,52h,45h,46h,4Ch,45h,43h,54h,2Ch,20h,36h,2Dh	;@4426
	db 50h,4Fh,57h,45h,52h,2Ch,0Dh,57h,48h,49h,43h,48h,3Fh,20h,0h	;@4436
	call ReadDigit	; digit 0-9	;@4445
	mov byte ptr Temp1F, al	;@4448
	cmp al, 7	;@444B
	jb Wear_ShowName	;@444D
	mov al, 0	; 7-9: skin	;@444F
	mov byte ptr Temp1F, al	;@4451
Wear_ShowName:	nop	;@4454
	clc	;@4455
	adc al, 1Dh	; 1Dh = armour names in NameStrTbl	;@4456
	call PrintNameStr	;@4458
	mov bh, 0	;@445B
	mov bl, byte ptr Temp1F	;@445D
	mov di, bx	;@4461
	mov al, byte ptr ArmourCounts[di]	; how many of that armour	;@4463
	or al, al	;@4467
	jne Wear_CheckStrength	;@4469
	mov al, byte ptr Temp1F	;@446B
	or al, al	; skin need not be owned	;@446E
	je Wear_CheckStrength	;@4470
	call PrintInline	;@4472
	db 20h,4Eh,4Fh,54h,20h,4Fh,57h,4Eh,45h,44h,21h,0h	;@4475
	jmp EndCommand	;@4481
Wear_CheckStrength:	mov al, byte ptr Temp1F	;@4484
	add al, al	;@4487
	add al, al	;@4489
	add al, al	; n*8 (binary)	;@448B
	cmp al, byte ptr Strength	; strength (BCD)	;@448D
	jb Wear_Done	;@4491
	call PrintInline	;@4493
	db 20h,3Ch,2Dh,54h,48h,4Fh,55h,20h,41h,52h,54h,20h,4Eh,4Fh,54h,0Dh	;@4496
	db 53h,54h,52h,4Fh,4Eh,47h,20h,45h,4Eh,4Fh,55h,47h,48h,20h,54h,4Fh	;@44A6
	db 20h,57h,45h,41h,52h,21h,0h	;@44B6
	jmp EndCommand	;@44BD
Wear_Done:	call PrintInline	;@44C0
	db 20h,52h,45h,41h,44h,59h,2Eh,0h	;@44C3
	mov al, byte ptr Temp1F	;@44CB
	mov byte ptr WornArmour, al	; worn armour	;@44CE
	jmp EndCommand	;@44D1

;------------------------------------------------------------------------------
; CmdXit (X): X-it, leave the vehicle. Only when riding (PlayerTile < 78h), and
; only where the ground under the player (TileHere) is 4 (grass?), or 0 (water?)
; when leaving the frigate (PlayerTile = 24h). The vehicle is put back on the map
; at the player's square and the player figure becomes 78h + 2 * class.
; PlayerTile/TileHere hold tile numbers = map code / 2.
;------------------------------------------------------------------------------
CmdXit:	call PrintInline	;@44D4
	db 58h,2Dh,49h,54h,0h	;@44D7
	mov al, byte ptr PlayerTile	; player tile; < 78h = a vehicle	;@44DC
	cmp al, 78h	;@44DF
	jb Xit_CheckGround	;@44E1
	call PrintInline	;@44E3
	db 20h,57h,48h,41h,54h,3Fh,0h	;@44E6
	jmp EndCommandBeep	;@44ED
Xit_CheckGround:	nop	;@44F0
	mov al, byte ptr PlayerX	;@44F1
	mov byte ptr LookX, al	;@44F4
	mov al, byte ptr PlayerY	;@44F7
	mov byte ptr LookY, al	;@44FA
	call GetMapSquare	; only for MapCellPtr -> the player's map cell	;@44FD
	mov al, byte ptr TileHere	; tile under the player	;@4500
	cmp al, 4	;@4503
	je Xit_LeaveVehicle	;@4505
	cmp al, 0	;@4507
	jne Xit_NotHere	;@4509
	mov al, byte ptr PlayerTile	;@450B
	cmp al, 24h	; frigate	;@450E
	je Xit_LeaveVehicle	;@4510
Xit_NotHere:	call PrintInline	;@4512
	db 2Dh,4Eh,4Fh,54h,20h,48h,45h,52h,45h,21h,0h	;@4515
	jmp EndCommandBeep	;@4520
Xit_LeaveVehicle:	mov al, byte ptr PlayerTile	;@4523
	add al, al	; vehicle tile -> map code	;@4526
	mov bh, 0	;@4528
	mov bl, 0	;@452A
	mov si, bx	;@452C
	mov bx, word ptr MapCellPtr	;@452E
	mov byte ptr [bx+si], al	; leave the vehicle on the map	;@4532
	mov al, byte ptr PlayerClass	; class 0-3	;@4534
	add al, al	;@4537
	clc	;@4539
	adc al, 78h	;@453A
	mov byte ptr PlayerTile, al	; on foot (as at game start, MAIN 080D)	;@453C
	jmp EndCommand	;@453F

;------------------------------------------------------------------------------
; CmdYell (Y): Yell. Echoes the keys typed until Enter; nothing else happens.
;------------------------------------------------------------------------------
CmdYell:	call PrintInline	;@4542
	db 59h,45h,4Ch,4Ch,20h,57h,48h,41h,54h,3Fh,8Dh,0h	;@4545
Yell_Loop:	call ReadKey	; read a key; AH = FFh for an ASCII key	;@4551
	cmp ah, 0FFh	;@4554
	jne Yell_Loop	;@4557
	cmp al, 0Dh	; Enter	;@4559
	je Yell_Done	;@455B
	call PutChar	; echo it	;@455D
	jmp Yell_Loop	;@4560
Yell_Done:	call PutChar	;@4562
	jmp EndCommand	;@4565

;------------------------------------------------------------------------------
; CmdZtats (Z): Ztats, the status screen. Switches to 40-column text mode (SetTextMode)
; with a left margin of 1 (TextLeftCol) and a right one at 38 (TextRightCol), and shows:
;   the name; "A LEVEL nn" (ExpHi = Exp/100), sex, race, class
;   readied weapon, torches, worn armour, keys, readied spell, tools
;   the six attributes, then every weapon, armour, spell and item held, with
;   its count, as "NAMES-nn"
; Waits for a key, restores the margins, returns to the CGA graphics mode
; (SetGraphicsMode) and redraws the status lines (DrawStatusLines). Positions via SetCursor (DI =
; column, SI = row). Temp: Temp1F = the list index.
;------------------------------------------------------------------------------
CmdZtats:	call SetTextMode	; 40x25 text mode, cursor 0,0	;@4568
	mov byte ptr TextLeftCol, 1	; column after a CR	;@456B
	mov byte ptr CursorCol, 1	; cursor column	;@4570
	mov byte ptr TextRightCol, 26h	; wrap column	;@4575
	call UpdateBiosCursor	; move the cursor	;@457A
	call PrintPlayerName	; the player's name	;@457D
	call PrintInline	;@4580
	db 8Dh,41h,20h,4Ch,45h,56h,45h,4Ch,20h,0h	;@4583
	mov al, byte ptr ExpHi	; Exp high BCD byte = level	;@458D
	call PrintBcdByte	; print a BCD byte as 2 digits	;@4590
	mov al, 20h	;@4593
	call PutChar	;@4595
	mov al, byte ptr PlayerSex	;@4598
	call PrintSex	; MALE / FEMALE from PlayerSex	;@459B
	mov al, 20h	;@459E
	call PutChar	;@45A0
	mov al, byte ptr PlayerRace	; race 0-3	;@45A3
	clc	;@45A6
	adc al, 44h	; 44h = HUMAN, ELF, DWARF, HOBBIT	;@45A7
	call PrintNameStr	;@45A9
	mov al, 20h	;@45AC
	call PutChar	;@45AE
	mov al, byte ptr PlayerClass	; class 0-3	;@45B1
	clc	;@45B4
	adc al, 48h	; 48h = FIGHTER, CLERIC, WIZARD, THIEF	;@45B5
	call PrintNameStr	;@45B7
	mov al, 0Dh	;@45BA
	call PutChar	;@45BC
	mov al, 0Dh	;@45BF
	call PutChar	;@45C1
	call PrintInline	;@45C4
	db 20h,20h,57h,45h,41h,50h,4Fh,4Eh,2Dh,0h	;@45C7
	mov al, byte ptr ReadyWeapon	; readied weapon	;@45D1
	clc	;@45D4
	adc al, 13h	;@45D5
	call PrintNameStr	;@45D7
	mov bh, 0	;@45DA
	mov bl, 1Dh	;@45DC
	mov di, bx	;@45DE
	mov bh, 0	;@45E0
	mov bl, 3	;@45E2
	mov si, bx	;@45E4
	call SetCursor	; cursor to column 29, row 3	;@45E6
	call PrintInline	;@45E9
	db 54h,4Fh,52h,43h,48h,45h,53h,2Dh,0h	;@45EC
	mov al, byte ptr Torches	; torches	;@45F5
	call PrintBcdByte	;@45F8
	mov bh, 0	;@45FB
	mov bl, 1	;@45FD
	mov di, bx	;@45FF
	mov bh, 0	;@4601
	mov bl, 4	;@4603
	mov si, bx	;@4605
	call SetCursor	;@4607
	call PrintInline	;@460A
	db 20h,20h,41h,52h,4Dh,4Fh,55h,52h,2Dh,0h	;@460D
	mov al, byte ptr WornArmour	; worn armour	;@4617
	clc	;@461A
	adc al, 1Dh	;@461B
	call PrintNameStr	;@461D
	mov bh, 0	;@4620
	mov bl, 20h	;@4622
	mov di, bx	;@4624
	mov bh, 0	;@4626
	mov bl, 4	;@4628
	mov si, bx	;@462A
	call SetCursor	;@462C
	call PrintInline	;@462F
	db 4Bh,45h,59h,53h,2Dh,0h	;@4632
	mov al, byte ptr Keys	; keys	;@4638
	call PrintBcdByte	;@463B
	mov bh, 0	;@463E
	mov bl, 4	;@4640
	mov di, bx	;@4642
	mov bh, 0	;@4644
	mov bl, 5	;@4646
	mov si, bx	;@4648
	call SetCursor	;@464A
	call PrintInline	;@464D
	db 53h,50h,45h,4Ch,4Ch,2Dh,0h	;@4650
	mov al, byte ptr ReadySpell	; readied spell	;@4657
	clc	;@465A
	adc al, 24h	;@465B
	call PrintNameStr	;@465D
	mov bh, 0	;@4660
	mov bl, 1Fh	;@4662
	mov di, bx	;@4664
	mov bh, 0	;@4666
	mov bl, 5	;@4668
	mov si, bx	;@466A
	call SetCursor	;@466C
	call PrintInline	;@466F
	db 54h,4Fh,4Fh,4Ch,53h,2Dh,0h	;@4672
	mov al, byte ptr Tools	; tools	;@4679
	call PrintBcdByte	;@467C
	mov bh, 0	;@467F
	mov bl, 1	;@4681
	mov di, bx	;@4683
	mov bh, 0	;@4685
	mov bl, 6	;@4687
	mov si, bx	;@4689
	call SetCursor	;@468B
; The attributes, "NAME-nn" each (NameStrTbl 3Eh-43h), two or three to a row.
	mov al, 3Eh	; STRENGTH	;@468E
	call PrintNameStr	;@4690
	mov al, 2Dh	;@4693
	call PutChar	;@4695
	mov al, byte ptr Strength	;@4698
	call PrintBcdByte	;@469B
	mov bh, 0	;@469E
	mov bl, 2	;@46A0
	mov di, bx	;@46A2
	mov bh, 0	;@46A4
	mov bl, 7	;@46A6
	mov si, bx	;@46A8
	call SetCursor	;@46AA
	mov al, 3Fh	;@46AD
	call PrintNameStr	;@46AF
	mov al, 2Dh	;@46B2
	call PutChar	;@46B4
	mov al, byte ptr Agility	;@46B7
	call PrintBcdByte	;@46BA
	mov bh, 0	;@46BD
	mov bl, 10h	;@46BF
	mov di, bx	;@46C1
	mov bh, 0	;@46C3
	mov bl, 6	;@46C5
	mov si, bx	;@46C7
	call SetCursor	;@46C9
	mov al, 40h	;@46CC
	call PrintNameStr	;@46CE
	mov al, 2Dh	;@46D1
	call PutChar	;@46D3
	mov al, byte ptr Stamina	;@46D6
	call PrintBcdByte	;@46D9
	mov bh, 0	;@46DC
	mov bl, 0Fh	;@46DE
	mov di, bx	;@46E0
	mov bh, 0	;@46E2
	mov bl, 7	;@46E4
	mov si, bx	;@46E6
	call SetCursor	;@46E8
	mov al, 41h	;@46EB
	call PrintNameStr	;@46ED
	mov al, 2Dh	;@46F0
	call PutChar	;@46F2
	mov al, byte ptr Charisma	;@46F5
	call PrintBcdByte	;@46F8
	mov bh, 0	;@46FB
	mov bl, 1Eh	;@46FD
	mov di, bx	;@46FF
	mov bh, 0	;@4701
	mov bl, 6	;@4703
	mov si, bx	;@4705
	call SetCursor	;@4707
	mov al, 42h	;@470A
	call PrintNameStr	;@470C
	mov al, 2Dh	;@470F
	call PutChar	;@4711
	mov al, byte ptr Wisdom	;@4714
	call PrintBcdByte	;@4717
	mov bh, 0	;@471A
	mov bl, 1Dh	;@471C
	mov di, bx	;@471E
	mov bh, 0	;@4720
	mov bl, 7	;@4722
	mov si, bx	;@4724
	call SetCursor	;@4726
	mov al, 43h	;@4729
	call PrintNameStr	;@472B
	mov al, 2Dh	;@472E
	call PutChar	;@4730
	mov al, byte ptr Intelligence	;@4733
	call PrintBcdByte	;@4736
	mov bh, 0	;@4739
	mov bl, 1	;@473B
	mov di, bx	;@473D
	mov bh, 0	;@473F
	mov bl, 9	;@4741
	mov si, bx	;@4743
	call SetCursor	;@4745
; The weapons held, 1-9: "DAGGERS-nn " for every nonzero count.
	call PrintInline	;@4748
	db 57h,45h,41h,50h,4Fh,4Eh,53h,3Ah,20h,0h	;@474B
	mov bh, 0	;@4755
	mov bl, 1	;@4757
	mov di, bx	;@4759
Ztats_WeaponLoop:	mov al, byte ptr WeaponCounts[di]	;@475B
	or al, al	;@475F
	je Ztats_NextWeapon	;@4761
	mov bx, di	;@4763
	mov byte ptr Temp1F, bl	;@4765
	mov ax, di	;@4769
	clc	;@476B
	adc al, 13h	;@476C
	call PrintNameStr	;@476E
	call PrintInline	;@4771
	db 53h,2Dh,0h	;@4774
	mov bh, 0	;@4777
	mov bl, byte ptr Temp1F	;@4779
	mov di, bx	;@477D
	mov al, byte ptr WeaponCounts[di]	;@477F
	call PrintBcdByte	;@4783
	mov al, 20h	;@4786
	call PutChar	;@4788
Ztats_NextWeapon:	inc di	;@478B
	mov bx, di	;@478C
	cmp bl, 0Ah	;@478E
	jb Ztats_WeaponLoop	;@4791
	mov bh, 0	;@4793
	mov bl, 1	;@4795
	mov di, bx	;@4797
	mov bh, 0	;@4799
	mov bl, 0Ch	;@479B
	mov si, bx	;@479D
	call SetCursor	;@479F
; The armour held, 1-6: "CLOTH-nn ".
	call PrintInline	;@47A2
	db 41h,52h,4Dh,4Fh,55h,52h,3Ah,20h,0h	;@47A5
	mov bh, 0	;@47AE
	mov bl, 1	;@47B0
	mov di, bx	;@47B2
Ztats_ArmourLoop:	mov al, byte ptr ArmourCounts[di]	;@47B4
	or al, al	;@47B8
	je Ztats_NextArmour	;@47BA
	mov bx, di	;@47BC
	mov byte ptr Temp1F, bl	;@47BE
	mov ax, di	;@47C2
	clc	;@47C4
	adc al, 1Dh	;@47C5
	call PrintNameStr	;@47C7
	call PrintInline	;@47CA
	db 2Dh,0h	;@47CD
	mov bh, 0	;@47CF
	mov bl, byte ptr Temp1F	;@47D1
	mov di, bx	;@47D5
	mov al, byte ptr ArmourCounts[di]	;@47D7
	call PrintBcdByte	;@47DB
	mov al, 20h	;@47DE
	call PutChar	;@47E0
Ztats_NextArmour:	inc di	;@47E3
	mov bx, di	;@47E4
	cmp bl, 7	;@47E6
	jb Ztats_ArmourLoop	;@47E9
	mov bh, 0	;@47EB
	mov bl, 1	;@47ED
	mov di, bx	;@47EF
	mov bh, 0	;@47F1
	mov bl, 0Eh	;@47F3
	mov si, bx	;@47F5
	call SetCursor	;@47F7
; The spells held, 1-9: "LIGHTS-nn ".
	call PrintInline	;@47FA
	db 53h,50h,45h,4Ch,4Ch,53h,3Ah,20h,0h	;@47FD
	mov bh, 0	;@4806
	mov bl, 1	;@4808
	mov di, bx	;@480A
Ztats_SpellLoop:	mov al, byte ptr SpellCounts[di]	;@480C
	or al, al	;@4810
	je Ztats_NextSpell	;@4812
	mov bx, di	;@4814
	mov byte ptr Temp1F, bl	;@4816
	mov ax, di	;@481A
	clc	;@481C
	adc al, 24h	;@481D
	call PrintNameStr	;@481F
	call PrintInline	;@4822
	db 53h,2Dh,0h	;@4825
	mov bh, 0	;@4828
	mov bl, byte ptr Temp1F	;@482A
	mov di, bx	;@482E
	mov al, byte ptr SpellCounts[di]	;@4830
	call PrintBcdByte	;@4834
	mov al, 20h	;@4837
	call PutChar	;@4839
Ztats_NextSpell:	inc di	;@483C
	mov bx, di	;@483D
	cmp bl, 0Ah	;@483F
	jb Ztats_SpellLoop	;@4842
	mov bh, 0	;@4844
	mov bl, 1	;@4846
	mov di, bx	;@4848
	mov bh, 0	;@484A
	mov bl, 12h	;@484C
	mov si, bx	;@484E
	call SetCursor	;@4850
; The items held, 0-15 (ring .. tri-lithium, NameStrTbl 2Eh+n): "RINGS-nn ";
; item 3 (BOOTS) gets no extra "S".
	call PrintInline	;@4853
	db 49h,54h,45h,4Dh,53h,3Ah,20h,0h	;@4856
	mov bh, 0	;@485E
	mov bl, 0	;@4860
	mov di, bx	;@4862
Ztats_ItemLoop:	mov al, byte ptr ItemCounts[di]	;@4864
	or al, al	;@4868
	je Ztats_NextItem	;@486A
	mov bx, di	;@486C
	mov byte ptr Temp1F, bl	;@486E
	mov ax, di	;@4872
	clc	;@4874
	adc al, 2Eh	;@4875
	call PrintNameStr	;@4877
	cmp byte ptr Temp1F, 3	; BOOTS: already plural	;@487A
	je Ztats_ItemCount	;@487F
	call PrintInline	;@4881
	db 53h,0h	;@4884
Ztats_ItemCount:	call PrintInline	;@4886
	db 2Dh,0h	;@4889
	mov bh, 0	;@488B
	mov bl, byte ptr Temp1F	;@488D
	mov di, bx	;@4891
	mov al, byte ptr ItemCounts[di]	;@4893
	call PrintBcdByte	;@4897
	mov al, 20h	;@489A
	call PutChar	;@489C
Ztats_NextItem:	inc di	;@489F
	mov bx, di	;@48A0
	cmp bl, 10h	;@48A2
	jb Ztats_ItemLoop	;@48A5
; Restore the margins, wait for a key and go back to the map screen.
	mov byte ptr CursorCol, 0	;@48A7
	mov byte ptr TextLeftCol, 0	;@48AC
	mov byte ptr TextRightCol, 28h	; wrap at column 40 again	;@48B1
	mov bh, 0	;@48B6
	mov bl, 0	;@48B8
	mov di, bx	; DI = 0 (not used afterwards?)	;@48BA
Ztats_WaitKey:	call ReadKey	; wait for an ASCII key	;@48BC
	cmp ah, 0FFh	;@48BF
	jne Ztats_WaitKey	;@48C2
	call SetGraphicsMode	; CGA 320x200 mode, tile caches invalid	;@48C4
	call DrawStatusLines	; redraw the status lines (H.P., FOOD, ...)	;@48C7
	jmp EndCommand	;@48CA
CODE ENDS
END
