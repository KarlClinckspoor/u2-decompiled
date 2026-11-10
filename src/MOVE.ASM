; MOVE.ASM: moving (pass, north/south/east/west), force fields, saving the player.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 2362-26F9.
;
; Movement on the surface and in towns, and the helpers the commands use to pick a direction.
; Entry points:
;   ReadDirection read a direction key (with a time-out that turns into "PASS") -> DeltaX/DeltaY
;   FindMonsterInDir find the monster on the square in that direction (Attack, Fire, Offer, Transact)
;   CheckStep the rules for stepping onto the tile the player just moved to: terrain by transport
;         (on foot, horse, frigate, plane, rocket), marsh poison, force fields, paralysis, the
;         food used per step, leaving a town over its edge (LeaveToSurface), time doors (EnterTimeDoor).
; Data: PlayerX/PlayerY player x/y (0-63), PlayerTile the player's tile (transport), Temp29 the tile
; moved onto, HitPointsHi/HitPointsLo hit points and FoodHi-FoodFrac food (BCD), MapType location type.
; Tiles here are "half" codes (map byte / 2, as kept by MAPVIEW in PlayerTile-TileWest; bit 7 is
; MAPVIEW's redraw flag): 0 water, 2 marsh, 4 grass, 6 woods, 8 mountains, 0Ah-14h village,
; towne, tower, castle, dungeon, sign; 22h horse, 24h frigate, 26h plane, 28h rocket, 2Eh force
; field, 60h time door, 78h+ the player on foot.
; BCD arithmetic uses the 6502 idiom stc/cmc + sbb + das + cmc (SEC/SBC): CF=1 afterwards means
; no borrow, so "jb" = still enough, falling through = it went below zero.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN PlayerX:BYTE, PlayerY:BYTE, MapCellPtr:BYTE, PlayerTile:BYTE, DeltaX:BYTE, DeltaY:BYTE
	EXTRN Temp1F:BYTE, Temp20:BYTE, LookX:BYTE, LookY:BYTE, Temp29:BYTE, PlayerRecord:BYTE
	EXTRN TimeZone:BYTE, MapType:BYTE, HitPointsHi:BYTE, HitPointsLo:BYTE, FoodHi:BYTE, FoodLo:BYTE
	EXTRN FoodFrac:BYTE, SurfaceX:BYTE, SurfaceY:BYTE, RocketX:BYTE, RocketY:BYTE, Planet:BYTE
	EXTRN TimeDoorSpot:BYTE, TimeDoorUnder:BYTE, ItemCounts:BYTE, MonsterX:BYTE, MonsterY:BYTE, MonsterTile:BYTE
	EXTRN LegsParalyzed:BYTE, KeyNorth:BYTE, KeySouth:BYTE, KeyEast:BYTE, KeyWest:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN SpeedDelay:NEAR, EndCommandBeep:NEAR, EndCommand:NEAR, PlayerDies:NEAR, DieOfStarvation:NEAR
	EXTRN LoadMapAndMonsters:NEAR
	EXTRN SaveGame:NEAR, TimeDoorTbl:BYTE, ReadKey:NEAR, PrintInline:NEAR, GetMapSquare:NEAR, XorAttackMark:NEAR
	EXTRN ReadWriteFile:NEAR, UpdateMapView:NEAR, PlayStepSound:NEAR, PlayHurtSound:NEAR, PlayWarpSound:NEAR
	PUBLIC ReadDirection, FindMonsterInDir, CheckStep, LeaveToSurface
ASSUME CS:CODE, DS:DATA

;------------------------------------------------------------------------------
; ReadDirection: read a direction for a command (Attack, Fire, Offer, Steal, Transact, Unlock).
; Waits for one of the four direction keys KeyNorth-KeyWest (north, south, east,
; west), prints NORTH/SOUTH/EAST/WEST and sets the step DeltaX (dx) / DeltaY
; (dy) to -1/0/+1. Other keys are ignored. If no key comes within 65536 polls
; it drops the caller's return address, prints "PASS" and ends the turn (EndCommandBeep).
; Out: DeltaX, DeltaY. Uses: AX (Temp1F/Temp20 as the time-out counter).
;------------------------------------------------------------------------------
ReadDirection:	mov al, 0	;@2362
	mov byte ptr Temp1F, al	; 16-bit time-out counter	;@2364
	mov byte ptr Temp20, al	;@2367
	mov byte ptr DeltaX, al	; dx = 0	;@236A
	mov byte ptr DeltaY, al	; dy = 0	;@236D
ReadDirection_Wait:	call ReadKey	; poll the keyboard: AH = FFh if a key came	;@2370
	cmp ah, 0FFh	;@2373
	je ReadDirection_Key	;@2376
	nop	; five NOPs: something patched out here	;@2378
	nop	;@2379
	nop	;@237A
	nop	;@237B
	nop	;@237C
	inc byte ptr Temp1F	;@237D
	jne ReadDirection_Wait	;@2381
	inc byte ptr Temp20	;@2383
	jne ReadDirection_Wait	;@2387
	pop ax	; timed out: forget the caller	;@2389
	call PrintInline	;@238A
	db 50h,41h,53h,53h,0h	; "PASS"	;@238D
	jmp EndCommandBeep	; beep, end of turn	;@2392
ReadDirection_Key:	nop	;@2395
	cmp al, byte ptr KeyNorth	; north key	;@2396
	je ReadDirection_North	;@239A
	cmp al, byte ptr KeySouth	; south key	;@239C
	je ReadDirection_South	;@23A0
	cmp al, byte ptr KeyEast	; east key	;@23A2
	je ReadDirection_East	;@23A6
	cmp al, byte ptr KeyWest	; west key	;@23A8
	je ReadDirection_West	;@23AC
	jmp ReadDirection_Wait	; not a direction: keep waiting (time-out not reset)	;@23AE
ReadDirection_North:	call PrintInline	;@23B0
	db 4Eh,4Fh,52h,54h,48h,0h	;@23B3
	dec byte ptr DeltaY	;@23B9
	ret	;@23BD
ReadDirection_South:	call PrintInline	;@23BE
	db 53h,4Fh,55h,54h,48h,0h	;@23C1
	inc byte ptr DeltaY	;@23C7
	ret	;@23CB
ReadDirection_East:	call PrintInline	;@23CC
	db 45h,41h,53h,54h,0h	;@23CF
	inc byte ptr DeltaX	;@23D4
	ret	;@23D8
ReadDirection_West:	call PrintInline	;@23D9
	db 57h,45h,53h,54h,0h	;@23DC
	dec byte ptr DeltaX	;@23E1
	ret	;@23E5

;------------------------------------------------------------------------------
; FindMonsterInDir: find the monster on the square next to the player in the direction
; DeltaX/DeltaY (from ReadDirection). Scans the monster table from slot 31 down to 1
; for a live monster (MonsterTile <> 0) at that x/y.
; Out: DI = monster slot, or DI = 0 if there is none (ZF is set either way);
; LookX/LookY = the target square. The sum is not wrapped to 0-63, so a
; monster across the map edge is not found. Uses: AX, BX, DI.
;------------------------------------------------------------------------------
FindMonsterInDir:	clc	;@23E6
	mov al, byte ptr PlayerX	;@23E7
	adc al, byte ptr DeltaX	;@23EA
	mov byte ptr LookX, al	; target x	;@23EE
	clc	;@23F1
	mov al, byte ptr PlayerY	;@23F2
	adc al, byte ptr DeltaY	;@23F5
	mov byte ptr LookY, al	; target y	;@23F9
	mov bh, 0	;@23FC
	mov bl, 1Fh	;@23FE
	mov di, bx	; slot 31	;@2400
FindMonsterInDir_Loop:	mov al, byte ptr MonsterTile[di]	; monster tile, 0 = empty slot	;@2402
	cmp al, 0	;@2406
	je FindMonsterInDir_Next	;@2408
	mov al, byte ptr MonsterX[di]	; monster x	;@240A
	cmp al, byte ptr LookX	;@240E
	jne FindMonsterInDir_Next	;@2412
	mov al, byte ptr MonsterY[di]	; monster y	;@2414
	cmp al, byte ptr LookY	;@2418
	jne FindMonsterInDir_Next	;@241C
	ret	; found: DI = slot	;@241E
FindMonsterInDir_Next:	dec di	;@241F
	jne FindMonsterInDir_Loop	; slot 0 is never checked	;@2420
	ret	; not found: DI = 0	;@2422

;------------------------------------------------------------------------------
; CheckStep: the rules for a step on the surface or in a town. MAIN has already
; moved PlayerX/PlayerY and printed the direction; AL = the tile moved onto (half
; code from TileNorth-TileWest). Order: leaving a town over its edge (LeaveToSurface, does not
; return), marsh (-5 hits), force field (-1000 hits unless a ring), legs
; paralyzed, then by transport PlayerTile: rocket never moves, frigate only on water,
; on foot / horse / plane: speed delay, food and terrain (StepOnFoot, StepHorse, StepPlane).
; Out: AL = 0, ZF = 1: allowed (x/y wrapped to 0-63); AL = FFh, ZF = 0: not
; allowed (MAIN steps back and prints "--INVALID MOVE!"). May end the turn
; itself (time door EnterTimeDoor) or kill the player (PlayerDies, DieOfStarvation).
; In: AL, PlayerTile, MapType. Uses: AX, BX, SI, DI, Temp1F, Temp29.
;------------------------------------------------------------------------------
CheckStep:	mov byte ptr Temp29, al	; the tile moved onto	;@2423
	mov al, byte ptr MapType	; location type	;@2426
	cmp al, 0	;@2429
	je CheckStep_Terrain	; surface: the map wraps around	;@242B
	mov al, byte ptr PlayerX	;@242D
	cmp al, 40h	; in a town: x or y out of 0-63 = walked off the edge	;@2430
	jae LeaveToSurface	;@2432
	mov al, byte ptr PlayerY	;@2434
	cmp al, 40h	;@2437
	jae LeaveToSurface	;@2439
	jmp CheckStep_Terrain	;@243B

;------------------------------------------------------------------------------
; LeaveToSurface: leave the town (or dungeon, CMDAL 3AD2) for the surface: back to the
; surface position SurfaceX/SurfaceY, location type 0, reload the surface map and
; monsters. On another planet the parked rocket (tile 50h) is put back on the
; reloaded map at RocketX/RocketY (those maps are never saved); on Earth the PLAYER
; file is written. Ends the turn (jmp EndCommand; MAIN resets SP, so the return
; address left by the call to CheckStep does no harm).
;------------------------------------------------------------------------------
LeaveToSurface:	nop	;@243E
	mov al, byte ptr SurfaceX	;@243F
	mov byte ptr PlayerX, al	;@2442
	mov al, byte ptr SurfaceY	;@2445
	mov byte ptr PlayerY, al	;@2448
	mov al, 0	;@244B
	mov byte ptr MapType, al	; surface	;@244D
	call LoadMapAndMonsters	; load MAPx<zone>0 / MONx<zone>0	;@2450
	mov al, byte ptr Planet	; planet, 0 = Earth	;@2453
	cmp al, 0	;@2456
	je LeaveToSurface_Save	;@2458
	mov al, byte ptr RocketX	; rocket x	;@245A
	mov byte ptr LookX, al	;@245D
	mov al, byte ptr RocketY	; rocket y	;@2460
	mov byte ptr LookY, al	;@2463
	call GetMapSquare	; MapCellPtr -> map cell	;@2466
	mov al, 50h	; rocket tile	;@2469
	mov bx, word ptr MapCellPtr	;@246B
	mov byte ptr [bx+si], al	;@246F
	jmp EndCommand	;@2471
LeaveToSurface_Save:	mov ah, 28h	; FCB random block write	;@2474
	mov cx, 100h	;@2476
	lea dx, PlayerRecord	; player record	;@2479
	call ReadWriteFile	;@247D
	db 50h,4Ch,41h,59h,45h,52h,20h,20h	; "PLAYER  "	;@2480
	jmp EndCommand	;@2488
; The tile rules proper.
CheckStep_Terrain:	nop	;@248B
	mov al, byte ptr Temp29	;@248C
	and al, 7Fh	; drop MAPVIEW's redraw flag	;@248F
	cmp al, 2	; marsh: 5 hits of poison	;@2491
	jne CheckStep_ForceField	;@2493
	stc	;@2495
	mov al, byte ptr HitPointsLo	; hits, low BCD byte	;@2496
	cmc	;@2499
	sbb al, 5	;@249A
	das	;@249C
	cmc	;@249D
	mov byte ptr HitPointsLo, al	;@249E
	mov al, byte ptr HitPointsHi	; hits, high BCD byte	;@24A1
	cmc	;@24A4
	sbb al, 0	;@24A5
	das	;@24A7
	cmc	;@24A8
	mov byte ptr HitPointsHi, al	;@24A9
	jb CheckStep_ForceField	; no borrow: still alive	;@24AC
	jmp PlayerDies	; the player is dead	;@24AE
CheckStep_ForceField:	cmp al, 2Eh	; force field	;@24B1
	jne CheckStep_Paralyzed	;@24B3
	mov al, byte ptr ItemCounts	; rings	;@24B5
	cmp al, 0	;@24B8
	je CheckStep_FieldDamage	;@24BA
	call PrintInline	;@24BC
	db 8Dh,52h,49h,4Eh,47h,20h,50h,52h,4Fh,54h,45h,43h,54h,53h,20h,46h	; "RING PROTECTS FROM FIELD!"	;@24BF
	db 52h,4Fh,4Dh,20h,46h,49h,45h,4Ch,44h,21h,0h	;@24CF
	call PlayHurtSound	; sound	;@24DA
	jmp CheckStep_Paralyzed	;@24DD
CheckStep_FieldDamage:	call PrintInline	;@24E0
	db 8Dh,46h,49h,45h,4Ch,44h,20h,43h,41h,55h,53h,45h,53h,20h,31h,30h	; "FIELD CAUSES 1000 DAMAGE!"	;@24E3
	db 30h,30h,20h,44h,41h,4Dh,41h,47h,45h,21h,0h	;@24F3
	mov al, 0	;@24FE
	mov byte ptr DeltaX, al	; direction 0,0: XorAttackMark marks the player's own square	;@2500
	mov byte ptr DeltaY, al	;@2503
	call XorAttackMark	; draw the hit mark (XOR)	;@2506
	call PlayHurtSound	; sound	;@2509
	call XorAttackMark	; and erase it	;@250C
	mov al, byte ptr HitPointsHi	;@250F
	stc	;@2512
	cmc	;@2513
	sbb al, 10h	; -1000 hits (10h in the high BCD byte)	;@2514
	das	;@2516
	cmc	;@2517
	mov byte ptr HitPointsHi, al	;@2518
	jb CheckStep_Paralyzed	;@251B
	jmp PlayerDies	; the player is dead	;@251D
CheckStep_Paralyzed:	mov al, byte ptr LegsParalyzed	; legs paralyzed (turns left)	;@2520
	cmp al, 0	;@2523
	je CheckStep_Transport	;@2525
	call PrintInline	;@2527
	db 2Dh,2Dh,50h,41h,52h,41h,4Ch,49h,5Ah,45h,44h,21h,0Dh,0h	; "--PARALYZED!"	;@252A
	mov al, 0FFh	; not allowed	;@2538
	ret	;@253A
; By transport.
CheckStep_Transport:	mov al, byte ptr PlayerTile	; the player's tile = transport	;@253B
	cmp al, 28h	; rocket	;@253E
	jne CheckStep_TryPlane	;@2540
	jmp StepRocket	;@2542
CheckStep_TryPlane:	cmp al, 26h	; plane	;@2545
	jne CheckStep_TryFrigate	;@2547
	jmp StepPlane	;@2549
CheckStep_TryFrigate:	cmp al, 24h	; frigate	;@254C
	jne CheckStep_TryHorse	;@254E
	jmp StepFrigate	;@2550
CheckStep_TryHorse:	cmp al, 22h	; horse	;@2553
	jne StepOnFoot	; anything else: on foot	;@2555
; Horse: a step sound and the same delay as on foot, then StepHorse (which walks once more).
	call PlayStepSound	; step sound	;@2557
	mov bh, 0	;@255A
	mov bl, 0FFh	;@255C
	mov di, bx	;@255E
HorseStep_Delay:	mov bh, 0	; speed-dependent delay: 255 x (32 loops + SpeedDelay delay 10h)	;@2560
	mov bl, 20h	;@2562
	mov si, bx	;@2564
HorseStep_BusyLoop:	dec si	;@2566
	jne HorseStep_BusyLoop	;@2567
	mov bx, 10h	;@2569
	call SpeedDelay	;@256C
	dec di	;@256F
	jne HorseStep_Delay	;@2570
	jmp StepHorse	;@2572

;------------------------------------------------------------------------------
; StepOnFoot: one step on foot (also called by StepHorse for the horse and the plane):
; step sounds and a delay, 0.19 food, then the terrain test for walking.
; Blocked: water (0), mountains (8), and every tile from 16h up except 22h-2Eh
; (transports, force field) and 38h. The time door (60h) goes to EnterTimeDoor.
; Out: AL = 0, ZF = 1 (allowed, x/y wrapped) or AL = FFh, ZF = 0 (blocked).
; Starving (food below 0) ends the game through DieOfStarvation. Uses: AX, BX, SI, DI.
;------------------------------------------------------------------------------
StepOnFoot:	call PlayStepSound	; step sound	;@2575
	mov bh, 0	;@2578
	mov bl, 0FFh	;@257A
	mov di, bx	;@257C
StepOnFoot_Delay:	mov bh, 0	; speed-dependent delay, as above	;@257E
	mov bl, 20h	;@2580
	mov si, bx	;@2582
StepOnFoot_BusyLoop:	dec si	;@2584
	jne StepOnFoot_BusyLoop	;@2585
	mov bx, 10h	;@2587
	call SpeedDelay	;@258A
	dec di	;@258D
	jne StepOnFoot_Delay	;@258E
	call PlayStepSound	; second step sound	;@2590
	mov bx, 12h	;@2593
	call SpeedDelay	;@2596
	stc	; food -= 0.19 (FoodFrac holds the hundredths)	;@2599
	mov al, byte ptr FoodFrac	;@259A
	cmc	;@259D
	sbb al, 19h	;@259E
	das	;@25A0
	cmc	;@25A1
	mov byte ptr FoodFrac, al	;@25A2
	mov al, byte ptr FoodLo	;@25A5
	cmc	;@25A8
	sbb al, 0	;@25A9
	das	;@25AB
	cmc	;@25AC
	mov byte ptr FoodLo, al	;@25AD
	mov al, byte ptr FoodHi	;@25B0
	cmc	;@25B3
	sbb al, 0	;@25B4
	das	;@25B6
	cmc	;@25B7
	mov byte ptr FoodHi, al	;@25B8
	jb StepOnFoot_Terrain	;@25BB
	jmp DieOfStarvation	; out of food: dead	;@25BD
StepOnFoot_Terrain:	mov al, byte ptr Temp29	;@25C0
	and al, 7Fh	;@25C3
	cmp al, 60h	; time door	;@25C5
	jne StepOnFoot_TryWater	;@25C7
	jmp EnterTimeDoor	;@25C9
StepOnFoot_TryWater:	cmp al, 0	; water	;@25CC
	je CheckStep_Refuse	;@25CE
	cmp al, 8	; mountains	;@25D0
	je CheckStep_Refuse	;@25D2
	cmp al, 22h	; 22h-2Eh: horse, frigate, plane, rocket, 2Ah, 2Ch, force field	;@25D4
	je CheckStep_AllowJmp	;@25D6
	cmp al, 24h	;@25D8
	je CheckStep_AllowJmp	;@25DA
	cmp al, 26h	;@25DC
	je CheckStep_AllowJmp	;@25DE
	cmp al, 28h	;@25E0
	je CheckStep_AllowJmp	;@25E2
	cmp al, 2Ah	;@25E4
	je CheckStep_AllowJmp	;@25E6
	cmp al, 2Ch	;@25E8
	je CheckStep_AllowJmp	;@25EA
	cmp al, 2Eh	;@25EC
	je CheckStep_AllowJmp	;@25EE
	cmp al, 38h	;@25F0
	je CheckStep_AllowJmp	;@25F2
	cmp al, 16h	; other tiles from 16h up: blocked	;@25F4
	jae CheckStep_Refuse	;@25F6
	jmp CheckStep_AllowJmp	; below 16h (marsh, grass, woods, towns, signs): allowed	;@25F8
; Rocket: it never moves on the ground (Launch flies it).
StepRocket:	call CheckStep_Refuse	;@25FB
	ret	;@25FE
; The two exits: CheckStep_Refuse = not allowed, CheckStep_AllowJmp/CheckStep_Allow = allowed.
CheckStep_Refuse:	mov al, 0FFh	;@25FF
	cmp al, 0	; ZF = 0	;@2601
	ret	;@2603
CheckStep_AllowJmp:	jmp CheckStep_Allow	;@2604
; Plane: the horse rules (StepHorse) and no woods (it can only come down on grass).
StepPlane:	call StepHorse	;@2607
	cmp al, 0FFh	;@260A
	je CheckStep_Refuse	;@260C
	mov al, byte ptr Temp29	;@260E
	and al, 7Fh	;@2611
	cmp al, 6	; woods	;@2613
	je CheckStep_Refuse	;@2615
	jmp CheckStep_AllowJmp	;@2617
; Frigate: water only (0, or 80h = water with the redraw flag). No food, no delay.
StepFrigate:	mov al, byte ptr Temp29	;@2619
	cmp al, 0	;@261C
	je CheckStep_AllowJmp	;@261E
	cmp al, 80h	;@2620
	je CheckStep_AllowJmp	;@2622
	jmp CheckStep_Refuse	;@2624

;------------------------------------------------------------------------------
; StepHorse: the horse step (after its delay at HorseStep_Delay) and, called, the plane step:
; 0.19 food, then a whole step on foot (StepOnFoot: delay, another 0.19 food, the
; walking terrain test), and in addition no marsh (2). The test for the time door
; (60h) after it is never true: StepOnFoot has already gone through the door (EnterTimeDoor).
; So a horse pays two delays and 0.38 food per step, a plane one delay and 0.38.
; Out: AL = 0, ZF = 1 (allowed) or AL = FFh, ZF = 0. Uses: AX, BX, SI, DI.
;------------------------------------------------------------------------------
StepHorse:	nop	;@2626
	stc	; food -= 0.19	;@2627
	mov al, byte ptr FoodFrac	;@2628
	cmc	;@262B
	sbb al, 19h	;@262C
	das	;@262E
	cmc	;@262F
	mov byte ptr FoodFrac, al	;@2630
	mov al, byte ptr FoodLo	;@2633
	cmc	;@2636
	sbb al, 0	;@2637
	das	;@2639
	cmc	;@263A
	mov byte ptr FoodLo, al	;@263B
	mov al, byte ptr FoodHi	;@263E
	cmc	;@2641
	sbb al, 0	;@2642
	das	;@2644
	cmc	;@2645
	mov byte ptr FoodHi, al	;@2646
	jb StepHorse_Walk	;@2649
	jmp DieOfStarvation	; out of food: dead	;@264B
StepHorse_Walk:	call StepOnFoot	; a step on foot	;@264E
	cmp al, 0FFh	;@2651
	je CheckStep_Refuse	;@2653
	mov al, byte ptr Temp29	;@2655
	and al, 7Fh	;@2658
	cmp al, 2	; marsh	;@265A
	je CheckStep_Refuse	;@265C
	cmp al, 60h	; time door: never true here (see above)	;@265E
	je CheckStep_Refuse	;@2660
	jmp CheckStep_AllowJmp	;@2662
; Allowed: wrap the position to 0-63 (the surface is a 64x64 torus), AL = 0, ZF = 1.
CheckStep_Allow:	mov al, byte ptr PlayerX	;@2664
	and al, 3Fh	;@2667
	mov byte ptr PlayerX, al	;@2669
	mov al, byte ptr PlayerY	;@266C
	and al, 3Fh	;@266F
	mov byte ptr PlayerY, al	;@2671
	mov al, 0	;@2674
	ret	;@2676

;------------------------------------------------------------------------------
; EnterTimeDoor: step into a time door (tile C0h on the map, 60h as a half code). The
; door's square gets back the terrain it covered (TimeDoorUnder) and the map is drawn
; once with that terrain in place of the player; the game is saved (SaveGame),
; then the door takes the player to another time zone: door slot TimeDoorSpot/2
; (0-3), counted over the zones other than the current one. The new zone's map
; is loaded and the player put at entry TimeDoorSpot of that zone's door table TimeDoorTbl
; (8 bytes, x/y pairs, per zone; DUNGEON 26F9 moves the door between those
; slots every 8 turns). Ends the turn (drops the return address, jmp EndCommand).
;------------------------------------------------------------------------------
EnterTimeDoor:	mov al, byte ptr PlayerTile	; save the player's tile	;@2677
	mov byte ptr Temp1F, al	;@267A
	mov al, byte ptr PlayerX	;@267D
	mov byte ptr LookX, al	;@2680
	mov al, byte ptr PlayerY	;@2683
	mov byte ptr LookY, al	;@2686
	call GetMapSquare	; MapCellPtr -> the door's map cell	;@2689
	mov al, byte ptr TimeDoorUnder	; the terrain under the door	;@268C
	mov bx, word ptr MapCellPtr	;@268F
	mov byte ptr [bx+si], al	; the door is gone from this map	;@2693
	clc	;@2695
	clc	;@2696
	rcr al, 1	; map byte -> half code	;@2697
	mov byte ptr PlayerTile, al	; draw the terrain where the player was: he vanishes	;@2699
	call UpdateMapView	; draw the map window	;@269C
	mov al, byte ptr Temp1F	;@269F
	mov byte ptr PlayerTile, al	; the player's tile back	;@26A2
	call PlayWarpSound	; time door sound	;@26A5
	mov al, byte ptr PlayerX	; surface position (SaveGame sets it again)	;@26A8
	mov byte ptr SurfaceX, al	;@26AB
	mov al, byte ptr PlayerY	;@26AE
	mov byte ptr SurfaceY, al	;@26B1
	call SaveGame	; save map, monsters, player	;@26B4
	mov al, byte ptr TimeDoorSpot	; door slot x2 (0, 2, 4, 6)	;@26B7
	clc	;@26BA
	rcr al, 1	; slot 0-3	;@26BB
	cmp al, byte ptr TimeZone	; skip the zone we are in	;@26BD
	jb EnterTimeDoor_SetZone	;@26C1
	clc	;@26C3
	adc al, 1	;@26C4
EnterTimeDoor_SetZone:	mov byte ptr TimeZone, al	; the new time zone	;@26C6
	call LoadMapAndMonsters	; load its map and monsters	;@26C9
	clc	;@26CC
	mov al, byte ptr TimeZone	;@26CD
	add al, al	;@26D0
	add al, al	;@26D2
	add al, al	; zone * 8	;@26D4
	adc al, byte ptr TimeDoorSpot	; + slot * 2	;@26D6
	mov ah, 0	;@26DA
	mov di, ax	;@26DC
	mov al, byte ptr cs:TimeDoorTbl[di]	; door position x in the new zone	;@26DE
	mov byte ptr PlayerX, al	;@26E3
	inc di	;@26E6
	mov al, byte ptr cs:TimeDoorTbl[di]	; and y	;@26E7
	mov byte ptr PlayerY, al	;@26EC
	call UpdateMapView	; draw the map window	;@26EF
	call PlayWarpSound	; time door sound	;@26F2
	pop ax	; drop the return address (MAIN resets SP anyway)	;@26F5
	jmp EndCommand	; end of turn	;@26F6
CODE ENDS
END
