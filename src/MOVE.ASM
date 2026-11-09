; MOVE.ASM: moving (pass, north/south/east/west), force fields, saving the player.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 2362-26F9.
;
; Movement on the surface and in towns, and the helpers the commands use to pick a direction.
; Entry points:
;   L2362 read a direction key (with a time-out that turns into "PASS") -> D_0019/D_001A
;   L23E6 find the monster on the square in that direction (Attack, Fire, Offer, Transact)
;   L2423 the rules for stepping onto the tile the player just moved to: terrain by transport
;         (on foot, horse, frigate, plane, rocket), marsh poison, force fields, paralysis, the
;         food used per step, leaving a town over its edge (L243E), time doors (L2677).
; Data: D_0000/D_0001 player x/y (0-63), D_0013 the player's tile (transport), D_0029 the tile
; moved onto, D_0051/D_0052 hit points and D_0053-D_0055 food (BCD), D_004A location type.
; Tiles here are "half" codes (map byte / 2, as kept by MAPVIEW in D_0013-D_0018; bit 7 is
; MAPVIEW's redraw flag): 0 water, 2 marsh, 4 grass, 6 woods, 8 mountains, 0Ah-14h village,
; towne, tower, castle, dungeon, sign; 22h horse, 24h frigate, 26h plane, 28h rocket, 2Eh force
; field, 60h time door, 78h+ the player on foot.
; BCD arithmetic uses the 6502 idiom stc/cmc + sbb + das + cmc (SEC/SBC): CF=1 afterwards means
; no borrow, so "jb" = still enough, falling through = it went below zero.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0000:BYTE, D_0001:BYTE, D_0006:BYTE, D_0013:BYTE, D_0019:BYTE, D_001A:BYTE
	EXTRN D_001F:BYTE, D_0020:BYTE, D_0023:BYTE, D_0024:BYTE, D_0029:BYTE, D_0036:BYTE
	EXTRN D_0049:BYTE, D_004A:BYTE, D_0051:BYTE, D_0052:BYTE, D_0053:BYTE, D_0054:BYTE
	EXTRN D_0055:BYTE, D_005A:BYTE, D_005B:BYTE, D_006A:BYTE, D_006B:BYTE, D_006D:BYTE
	EXTRN D_006E:BYTE, D_0070:BYTE, D_00D6:BYTE, D_0137:BYTE, D_0157:BYTE, D_0197:BYTE
	EXTRN D_026B:BYTE, D_026E:BYTE, D_026F:BYTE, D_0270:BYTE, D_0271:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L0711:NEAR, L0A30:NEAR, L0A33:NEAR, L0C62:NEAR, L228D:NEAR, L2290:NEAR
	EXTRN L22FD:NEAR, L2798:BYTE, L4F4D:NEAR, L4FDF:NEAR, L50B3:NEAR, L523E:NEAR
	EXTRN L52CA:NEAR, L5AB1:NEAR, L5EC7:NEAR, L5EF2:NEAR, L5FA6:NEAR
	PUBLIC L2362, L23E6, L2423, L243E
ASSUME CS:CODE, DS:DATA

;------------------------------------------------------------------------------
; L2362: read a direction for a command (Attack, Fire, Offer, Steal, Transact, Unlock).
; Waits for one of the four direction keys D_026E-D_0271 (north, south, east,
; west), prints NORTH/SOUTH/EAST/WEST and sets the step D_0019 (dx) / D_001A
; (dy) to -1/0/+1. Other keys are ignored. If no key comes within 65536 polls
; it drops the caller's return address, prints "PASS" and ends the turn (L0A30).
; Out: D_0019, D_001A. Uses: AX (D_001F/D_0020 as the time-out counter).
;------------------------------------------------------------------------------
L2362:	mov al, 0	;@2362
	mov byte ptr D_001F, al	; 16-bit time-out counter	;@2364
	mov byte ptr D_0020, al	;@2367
	mov byte ptr D_0019, al	; dx = 0	;@236A
	mov byte ptr D_001A, al	; dy = 0	;@236D
L2370:	call L4F4D	; poll the keyboard: AH = FFh if a key came	;@2370
	cmp ah, 0FFh	;@2373
	je L2395	;@2376
	nop	; five NOPs: something patched out here	;@2378
	nop	;@2379
	nop	;@237A
	nop	;@237B
	nop	;@237C
	inc byte ptr D_001F	;@237D
	jne L2370	;@2381
	inc byte ptr D_0020	;@2383
	jne L2370	;@2387
	pop ax	; timed out: forget the caller	;@2389
	call L4FDF	;@238A
	db 50h,41h,53h,53h,0h	; "PASS"	;@238D
	jmp L0A30	; beep, end of turn	;@2392
L2395:	nop	;@2395
	cmp al, byte ptr D_026E	; north key	;@2396
	je L23B0	;@239A
	cmp al, byte ptr D_026F	; south key	;@239C
	je L23BE	;@23A0
	cmp al, byte ptr D_0270	; east key	;@23A2
	je L23CC	;@23A6
	cmp al, byte ptr D_0271	; west key	;@23A8
	je L23D9	;@23AC
	jmp L2370	; not a direction: keep waiting (time-out not reset)	;@23AE
L23B0:	call L4FDF	;@23B0
	db 4Eh,4Fh,52h,54h,48h,0h	;@23B3
	dec byte ptr D_001A	;@23B9
	ret	;@23BD
L23BE:	call L4FDF	;@23BE
	db 53h,4Fh,55h,54h,48h,0h	;@23C1
	inc byte ptr D_001A	;@23C7
	ret	;@23CB
L23CC:	call L4FDF	;@23CC
	db 45h,41h,53h,54h,0h	;@23CF
	inc byte ptr D_0019	;@23D4
	ret	;@23D8
L23D9:	call L4FDF	;@23D9
	db 57h,45h,53h,54h,0h	;@23DC
	dec byte ptr D_0019	;@23E1
	ret	;@23E5

;------------------------------------------------------------------------------
; L23E6: find the monster on the square next to the player in the direction
; D_0019/D_001A (from L2362). Scans the monster table from slot 31 down to 1
; for a live monster (D_0197 <> 0) at that x/y.
; Out: DI = monster slot, or DI = 0 if there is none (ZF is set either way);
; D_0023/D_0024 = the target square. The sum is not wrapped to 0-63, so a
; monster across the map edge is not found. Uses: AX, BX, DI.
;------------------------------------------------------------------------------
L23E6:	clc	;@23E6
	mov al, byte ptr D_0000	;@23E7
	adc al, byte ptr D_0019	;@23EA
	mov byte ptr D_0023, al	; target x	;@23EE
	clc	;@23F1
	mov al, byte ptr D_0001	;@23F2
	adc al, byte ptr D_001A	;@23F5
	mov byte ptr D_0024, al	; target y	;@23F9
	mov bh, 0	;@23FC
	mov bl, 1Fh	;@23FE
	mov di, bx	; slot 31	;@2400
L2402:	mov al, byte ptr D_0197[di]	; monster tile, 0 = empty slot	;@2402
	cmp al, 0	;@2406
	je L241F	;@2408
	mov al, byte ptr D_0137[di]	; monster x	;@240A
	cmp al, byte ptr D_0023	;@240E
	jne L241F	;@2412
	mov al, byte ptr D_0157[di]	; monster y	;@2414
	cmp al, byte ptr D_0024	;@2418
	jne L241F	;@241C
	ret	; found: DI = slot	;@241E
L241F:	dec di	;@241F
	jne L2402	; slot 0 is never checked	;@2420
	ret	; not found: DI = 0	;@2422

;------------------------------------------------------------------------------
; L2423: the rules for a step on the surface or in a town. MAIN has already
; moved D_0000/D_0001 and printed the direction; AL = the tile moved onto (half
; code from D_0015-D_0018). Order: leaving a town over its edge (L243E, does not
; return), marsh (-5 hits), force field (-1000 hits unless a ring), legs
; paralyzed, then by transport D_0013: rocket never moves, frigate only on water,
; on foot / horse / plane: speed delay, food and terrain (L2575, L2626, L2607).
; Out: AL = 0, ZF = 1: allowed (x/y wrapped to 0-63); AL = FFh, ZF = 0: not
; allowed (MAIN steps back and prints "--INVALID MOVE!"). May end the turn
; itself (time door L2677) or kill the player (L0C62, L228D).
; In: AL, D_0013, D_004A. Uses: AX, BX, SI, DI, D_001F, D_0029.
;------------------------------------------------------------------------------
L2423:	mov byte ptr D_0029, al	; the tile moved onto	;@2423
	mov al, byte ptr D_004A	; location type	;@2426
	cmp al, 0	;@2429
	je L248B	; surface: the map wraps around	;@242B
	mov al, byte ptr D_0000	;@242D
	cmp al, 40h	; in a town: x or y out of 0-63 = walked off the edge	;@2430
	jae L243E	;@2432
	mov al, byte ptr D_0001	;@2434
	cmp al, 40h	;@2437
	jae L243E	;@2439
	jmp L248B	;@243B

;------------------------------------------------------------------------------
; L243E: leave the town (or dungeon, CMDAL 3AD2) for the surface: back to the
; surface position D_005A/D_005B, location type 0, reload the surface map and
; monsters. On another planet the parked rocket (tile 50h) is put back on the
; reloaded map at D_006A/D_006B (those maps are never saved); on Earth the PLAYER
; file is written. Ends the turn (jmp L0A33; MAIN resets SP, so the return
; address left by the call to L2423 does no harm).
;------------------------------------------------------------------------------
L243E:	nop	;@243E
	mov al, byte ptr D_005A	;@243F
	mov byte ptr D_0000, al	;@2442
	mov al, byte ptr D_005B	;@2445
	mov byte ptr D_0001, al	;@2448
	mov al, 0	;@244B
	mov byte ptr D_004A, al	; surface	;@244D
	call L2290	; load MAPx<zone>0 / MONx<zone>0	;@2450
	mov al, byte ptr D_006D	; planet, 0 = Earth	;@2453
	cmp al, 0	;@2456
	je L2474	;@2458
	mov al, byte ptr D_006A	; rocket x	;@245A
	mov byte ptr D_0023, al	;@245D
	mov al, byte ptr D_006B	; rocket y	;@2460
	mov byte ptr D_0024, al	;@2463
	call L50B3	; D_0006 -> map cell	;@2466
	mov al, 50h	; rocket tile	;@2469
	mov bx, word ptr D_0006	;@246B
	mov byte ptr [bx+si], al	;@246F
	jmp L0A33	;@2471
L2474:	mov ah, 28h	; FCB random block write	;@2474
	mov cx, 100h	;@2476
	lea dx, D_0036	; player record	;@2479
	call L52CA	;@247D
	db 50h,4Ch,41h,59h,45h,52h,20h,20h	; "PLAYER  "	;@2480
	jmp L0A33	;@2488
; The tile rules proper.
L248B:	nop	;@248B
	mov al, byte ptr D_0029	;@248C
	and al, 7Fh	; drop MAPVIEW's redraw flag	;@248F
	cmp al, 2	; marsh: 5 hits of poison	;@2491
	jne L24B1	;@2493
	stc	;@2495
	mov al, byte ptr D_0052	; hits, low BCD byte	;@2496
	cmc	;@2499
	sbb al, 5	;@249A
	das	;@249C
	cmc	;@249D
	mov byte ptr D_0052, al	;@249E
	mov al, byte ptr D_0051	; hits, high BCD byte	;@24A1
	cmc	;@24A4
	sbb al, 0	;@24A5
	das	;@24A7
	cmc	;@24A8
	mov byte ptr D_0051, al	;@24A9
	jb L24B1	; no borrow: still alive	;@24AC
	jmp L0C62	; the player is dead	;@24AE
L24B1:	cmp al, 2Eh	; force field	;@24B1
	jne L2520	;@24B3
	mov al, byte ptr D_00D6	; rings	;@24B5
	cmp al, 0	;@24B8
	je L24E0	;@24BA
	call L4FDF	;@24BC
	db 8Dh,52h,49h,4Eh,47h,20h,50h,52h,4Fh,54h,45h,43h,54h,53h,20h,46h	; "RING PROTECTS FROM FIELD!"	;@24BF
	db 52h,4Fh,4Dh,20h,46h,49h,45h,4Ch,44h,21h,0h	;@24CF
	call L5EF2	; sound	;@24DA
	jmp L2520	;@24DD
L24E0:	call L4FDF	;@24E0
	db 8Dh,46h,49h,45h,4Ch,44h,20h,43h,41h,55h,53h,45h,53h,20h,31h,30h	; "FIELD CAUSES 1000 DAMAGE!"	;@24E3
	db 30h,30h,20h,44h,41h,4Dh,41h,47h,45h,21h,0h	;@24F3
	mov al, 0	;@24FE
	mov byte ptr D_0019, al	; direction 0,0: L523E marks the player's own square	;@2500
	mov byte ptr D_001A, al	;@2503
	call L523E	; draw the hit mark (XOR)	;@2506
	call L5EF2	; sound	;@2509
	call L523E	; and erase it	;@250C
	mov al, byte ptr D_0051	;@250F
	stc	;@2512
	cmc	;@2513
	sbb al, 10h	; -1000 hits (10h in the high BCD byte)	;@2514
	das	;@2516
	cmc	;@2517
	mov byte ptr D_0051, al	;@2518
	jb L2520	;@251B
	jmp L0C62	; the player is dead	;@251D
L2520:	mov al, byte ptr D_026B	; legs paralyzed (turns left)	;@2520
	cmp al, 0	;@2523
	je L253B	;@2525
	call L4FDF	;@2527
	db 2Dh,2Dh,50h,41h,52h,41h,4Ch,49h,5Ah,45h,44h,21h,0Dh,0h	; "--PARALYZED!"	;@252A
	mov al, 0FFh	; not allowed	;@2538
	ret	;@253A
; By transport.
L253B:	mov al, byte ptr D_0013	; the player's tile = transport	;@253B
	cmp al, 28h	; rocket	;@253E
	jne L2545	;@2540
	jmp L25FB	;@2542
L2545:	cmp al, 26h	; plane	;@2545
	jne L254C	;@2547
	jmp L2607	;@2549
L254C:	cmp al, 24h	; frigate	;@254C
	jne L2553	;@254E
	jmp L2619	;@2550
L2553:	cmp al, 22h	; horse	;@2553
	jne L2575	; anything else: on foot	;@2555
; Horse: a step sound and the same delay as on foot, then L2626 (which walks once more).
	call L5EC7	; step sound	;@2557
	mov bh, 0	;@255A
	mov bl, 0FFh	;@255C
	mov di, bx	;@255E
L2560:	mov bh, 0	; speed-dependent delay: 255 x (32 loops + L0711 delay 10h)	;@2560
	mov bl, 20h	;@2562
	mov si, bx	;@2564
L2566:	dec si	;@2566
	jne L2566	;@2567
	mov bx, 10h	;@2569
	call L0711	;@256C
	dec di	;@256F
	jne L2560	;@2570
	jmp L2626	;@2572

;------------------------------------------------------------------------------
; L2575: one step on foot (also called by L2626 for the horse and the plane):
; step sounds and a delay, 0.19 food, then the terrain test for walking.
; Blocked: water (0), mountains (8), and every tile from 16h up except 22h-2Eh
; (transports, force field) and 38h. The time door (60h) goes to L2677.
; Out: AL = 0, ZF = 1 (allowed, x/y wrapped) or AL = FFh, ZF = 0 (blocked).
; Starving (food below 0) ends the game through L228D. Uses: AX, BX, SI, DI.
;------------------------------------------------------------------------------
L2575:	call L5EC7	; step sound	;@2575
	mov bh, 0	;@2578
	mov bl, 0FFh	;@257A
	mov di, bx	;@257C
L257E:	mov bh, 0	; speed-dependent delay, as above	;@257E
	mov bl, 20h	;@2580
	mov si, bx	;@2582
L2584:	dec si	;@2584
	jne L2584	;@2585
	mov bx, 10h	;@2587
	call L0711	;@258A
	dec di	;@258D
	jne L257E	;@258E
	call L5EC7	; second step sound	;@2590
	mov bx, 12h	;@2593
	call L0711	;@2596
	stc	; food -= 0.19 (D_0055 holds the hundredths)	;@2599
	mov al, byte ptr D_0055	;@259A
	cmc	;@259D
	sbb al, 19h	;@259E
	das	;@25A0
	cmc	;@25A1
	mov byte ptr D_0055, al	;@25A2
	mov al, byte ptr D_0054	;@25A5
	cmc	;@25A8
	sbb al, 0	;@25A9
	das	;@25AB
	cmc	;@25AC
	mov byte ptr D_0054, al	;@25AD
	mov al, byte ptr D_0053	;@25B0
	cmc	;@25B3
	sbb al, 0	;@25B4
	das	;@25B6
	cmc	;@25B7
	mov byte ptr D_0053, al	;@25B8
	jb L25C0	;@25BB
	jmp L228D	; out of food: dead	;@25BD
L25C0:	mov al, byte ptr D_0029	;@25C0
	and al, 7Fh	;@25C3
	cmp al, 60h	; time door	;@25C5
	jne L25CC	;@25C7
	jmp L2677	;@25C9
L25CC:	cmp al, 0	; water	;@25CC
	je L25FF	;@25CE
	cmp al, 8	; mountains	;@25D0
	je L25FF	;@25D2
	cmp al, 22h	; 22h-2Eh: horse, frigate, plane, rocket, 2Ah, 2Ch, force field	;@25D4
	je L2604	;@25D6
	cmp al, 24h	;@25D8
	je L2604	;@25DA
	cmp al, 26h	;@25DC
	je L2604	;@25DE
	cmp al, 28h	;@25E0
	je L2604	;@25E2
	cmp al, 2Ah	;@25E4
	je L2604	;@25E6
	cmp al, 2Ch	;@25E8
	je L2604	;@25EA
	cmp al, 2Eh	;@25EC
	je L2604	;@25EE
	cmp al, 38h	;@25F0
	je L2604	;@25F2
	cmp al, 16h	; other tiles from 16h up: blocked	;@25F4
	jae L25FF	;@25F6
	jmp L2604	; below 16h (marsh, grass, woods, towns, signs): allowed	;@25F8
; Rocket: it never moves on the ground (Launch flies it).
L25FB:	call L25FF	;@25FB
	ret	;@25FE
; The two exits: L25FF = not allowed, L2604/L2664 = allowed.
L25FF:	mov al, 0FFh	;@25FF
	cmp al, 0	; ZF = 0	;@2601
	ret	;@2603
L2604:	jmp L2664	;@2604
; Plane: the horse rules (L2626) and no woods (it can only come down on grass).
L2607:	call L2626	;@2607
	cmp al, 0FFh	;@260A
	je L25FF	;@260C
	mov al, byte ptr D_0029	;@260E
	and al, 7Fh	;@2611
	cmp al, 6	; woods	;@2613
	je L25FF	;@2615
	jmp L2604	;@2617
; Frigate: water only (0, or 80h = water with the redraw flag). No food, no delay.
L2619:	mov al, byte ptr D_0029	;@2619
	cmp al, 0	;@261C
	je L2604	;@261E
	cmp al, 80h	;@2620
	je L2604	;@2622
	jmp L25FF	;@2624

;------------------------------------------------------------------------------
; L2626: the horse step (after its delay at L2553) and, called, the plane step:
; 0.19 food, then a whole step on foot (L2575: delay, another 0.19 food, the
; walking terrain test), and in addition no marsh (2). The test for the time door
; (60h) after it is never true: L2575 has already gone through the door (L2677).
; So a horse pays two delays and 0.38 food per step, a plane one delay and 0.38.
; Out: AL = 0, ZF = 1 (allowed) or AL = FFh, ZF = 0. Uses: AX, BX, SI, DI.
;------------------------------------------------------------------------------
L2626:	nop	;@2626
	stc	; food -= 0.19	;@2627
	mov al, byte ptr D_0055	;@2628
	cmc	;@262B
	sbb al, 19h	;@262C
	das	;@262E
	cmc	;@262F
	mov byte ptr D_0055, al	;@2630
	mov al, byte ptr D_0054	;@2633
	cmc	;@2636
	sbb al, 0	;@2637
	das	;@2639
	cmc	;@263A
	mov byte ptr D_0054, al	;@263B
	mov al, byte ptr D_0053	;@263E
	cmc	;@2641
	sbb al, 0	;@2642
	das	;@2644
	cmc	;@2645
	mov byte ptr D_0053, al	;@2646
	jb L264E	;@2649
	jmp L228D	; out of food: dead	;@264B
L264E:	call L2575	; a step on foot	;@264E
	cmp al, 0FFh	;@2651
	je L25FF	;@2653
	mov al, byte ptr D_0029	;@2655
	and al, 7Fh	;@2658
	cmp al, 2	; marsh	;@265A
	je L25FF	;@265C
	cmp al, 60h	; time door: never true here (see above)	;@265E
	je L25FF	;@2660
	jmp L2604	;@2662
; Allowed: wrap the position to 0-63 (the surface is a 64x64 torus), AL = 0, ZF = 1.
L2664:	mov al, byte ptr D_0000	;@2664
	and al, 3Fh	;@2667
	mov byte ptr D_0000, al	;@2669
	mov al, byte ptr D_0001	;@266C
	and al, 3Fh	;@266F
	mov byte ptr D_0001, al	;@2671
	mov al, 0	;@2674
	ret	;@2676

;------------------------------------------------------------------------------
; L2677: step into a time door (tile C0h on the map, 60h as a half code). The
; door's square gets back the terrain it covered (D_0070) and the map is drawn
; once with that terrain in place of the player; the game is saved (L22FD),
; then the door takes the player to another time zone: door slot D_006E/2
; (0-3), counted over the zones other than the current one. The new zone's map
; is loaded and the player put at entry D_006E of that zone's door table L2798
; (8 bytes, x/y pairs, per zone; DUNGEON 26F9 moves the door between those
; slots every 8 turns). Ends the turn (drops the return address, jmp L0A33).
;------------------------------------------------------------------------------
L2677:	mov al, byte ptr D_0013	; save the player's tile	;@2677
	mov byte ptr D_001F, al	;@267A
	mov al, byte ptr D_0000	;@267D
	mov byte ptr D_0023, al	;@2680
	mov al, byte ptr D_0001	;@2683
	mov byte ptr D_0024, al	;@2686
	call L50B3	; D_0006 -> the door's map cell	;@2689
	mov al, byte ptr D_0070	; the terrain under the door	;@268C
	mov bx, word ptr D_0006	;@268F
	mov byte ptr [bx+si], al	; the door is gone from this map	;@2693
	clc	;@2695
	clc	;@2696
	rcr al, 1	; map byte -> half code	;@2697
	mov byte ptr D_0013, al	; draw the terrain where the player was: he vanishes	;@2699
	call L5AB1	; draw the map window	;@269C
	mov al, byte ptr D_001F	;@269F
	mov byte ptr D_0013, al	; the player's tile back	;@26A2
	call L5FA6	; time door sound	;@26A5
	mov al, byte ptr D_0000	; surface position (L22FD sets it again)	;@26A8
	mov byte ptr D_005A, al	;@26AB
	mov al, byte ptr D_0001	;@26AE
	mov byte ptr D_005B, al	;@26B1
	call L22FD	; save map, monsters, player	;@26B4
	mov al, byte ptr D_006E	; door slot x2 (0, 2, 4, 6)	;@26B7
	clc	;@26BA
	rcr al, 1	; slot 0-3	;@26BB
	cmp al, byte ptr D_0049	; skip the zone we are in	;@26BD
	jb L26C6	;@26C1
	clc	;@26C3
	adc al, 1	;@26C4
L26C6:	mov byte ptr D_0049, al	; the new time zone	;@26C6
	call L2290	; load its map and monsters	;@26C9
	clc	;@26CC
	mov al, byte ptr D_0049	;@26CD
	add al, al	;@26D0
	add al, al	;@26D2
	add al, al	; zone * 8	;@26D4
	adc al, byte ptr D_006E	; + slot * 2	;@26D6
	mov ah, 0	;@26DA
	mov di, ax	;@26DC
	mov al, byte ptr cs:L2798[di]	; door position x in the new zone	;@26DE
	mov byte ptr D_0000, al	;@26E3
	inc di	;@26E6
	mov al, byte ptr cs:L2798[di]	; and y	;@26E7
	mov byte ptr D_0001, al	;@26EC
	call L5AB1	; draw the map window	;@26EF
	call L5FA6	; time door sound	;@26F2
	pop ax	; drop the return address (MAIN resets SP anyway)	;@26F5
	jmp L0A33	; end of turn	;@26F6
CODE ENDS
END
