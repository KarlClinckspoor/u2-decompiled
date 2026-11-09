; MAIN.ASM: command jump table (A-Z), game start, the outdoor main loop and movement.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 0730-0E70.
;
; The heart of the game on a map (outdoors and in villages, towns and castles):
;   L0730  the command jump table, one word per letter A-Z (manual: Attack ... Ztatus)
;   L0764  game start ('P' in the menu): read PLAYER, MONSTERS, the map and its monsters, set
;          up the map window and the status lines
;   L086F  the main loop: "CMD: " prompt, key (or idle "PASS" after a while), the four
;          arrow-key moves, Space = pass, A-Z through the jump table. Dungeons and towers
;          (D_004A >= 4) go to the DUNGEON loop L27C0 instead.
;   L0A30/L0A33  end of every command (L0A30 beeps first): the monsters' turn, dispatched
;          on the map type D_004A; outdoors here (L0A6D), else EVENTS (L1013/L115E/L115F)
;   L0AA7  one monster: ranged spells, then move towards the player (L2122) or attack
;   L0BAF  end of the turn: show the attacks, apply the damage, count down the
;          paralysis/sleep/negate timers, back to L086F
;   L0C62  the player's death ("... IS DEAD!", hangs)
;   L0C9C  outdoors: maybe spawn a new monster in a free slot
; Data mostly used: the position D_0000/D_0001, the map type D_004A, the player figure
; D_0013 and the tiles around it D_0014-D_0018, the BCD hit points D_0051/D_0052 and food
; D_0053-D_0055, the timers D_026A-D_026D, the 32-slot monster table (D_0137 X, D_0157 Y,
; D_0177 hit points, D_0197 map code (0 = free), D_01B7 terrain under it), and the
; per-turn counters D_0020 (attacks), D_0021 (hits), D_0022 (damage), which double as the
; idle timer at the prompt.
; Dead code: 0778 "(INSERT PLAYER DISK)" (jumped over by the 1989 patch).
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0000:BYTE, D_0001:BYTE, D_0006:BYTE, D_0012:BYTE, D_0013:BYTE, D_0014:BYTE
	EXTRN D_0015:BYTE, D_0016:BYTE, D_0017:BYTE, D_0018:BYTE, D_0019:BYTE, D_001A:BYTE
	EXTRN D_001F:BYTE, D_0020:BYTE, D_0021:BYTE, D_0022:BYTE, D_0023:BYTE, D_0024:BYTE
	EXTRN D_0026:BYTE, D_0027:BYTE, D_0029:BYTE, D_0036:BYTE, D_0047:BYTE, D_004A:BYTE
	EXTRN D_0051:BYTE, D_0052:BYTE, D_0053:BYTE, D_0054:BYTE, D_0055:BYTE, D_0056:BYTE
	EXTRN D_0057:BYTE, D_0058:BYTE, D_0059:BYTE, D_005A:BYTE, D_005B:BYTE, D_005D:BYTE
	EXTRN D_0060:BYTE, D_0062:BYTE, D_0069:BYTE, D_006A:BYTE, D_006B:BYTE, D_0074:BYTE
	EXTRN D_0137:BYTE, D_0157:BYTE, D_0177:BYTE, D_0197:BYTE, D_01B7:BYTE, D_026A:BYTE
	EXTRN D_026B:BYTE, D_026C:BYTE, D_026D:BYTE, D_026E:BYTE, D_026F:BYTE, D_0270:BYTE
	EXTRN D_0271:BYTE, D_0272:BYTE, D_0372:BYTE, D_0474:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L06AC:NEAR, L06ED:NEAR, L0711:NEAR, L0E70:NEAR, L0EC2:NEAR, L0F12:NEAR
	EXTRN L0F48:NEAR, L0FCD:NEAR, L1013:NEAR, L1014:NEAR, L1015:NEAR, L1040:NEAR
	EXTRN L115E:NEAR, L115F:NEAR, L2122:NEAR, L2275:NEAR, L228D:NEAR, L2290:NEAR
	EXTRN L2423:NEAR, L26F9:NEAR, L27C0:NEAR, L2B8F:NEAR, L2F6F:NEAR, L310B:NEAR
	EXTRN L334D:NEAR, L3389:NEAR, L35C1:NEAR, L363B:NEAR, L3782:NEAR, L3794:NEAR
	EXTRN L37DC:NEAR, L37F1:NEAR, L38B0:NEAR, L3B92:NEAR, L3BCE:NEAR, L3C2E:NEAR
	EXTRN L3DBC:NEAR, L3DC7:NEAR, L3E50:NEAR, L3F25:NEAR, L4050:NEAR, L42F1:NEAR
	EXTRN L437E:NEAR, L43F3:NEAR, L44D4:NEAR, L4542:NEAR, L4568:NEAR, L4A1C:NEAR
	EXTRN L4A3E:NEAR, L4AE6:NEAR, L4AF1:NEAR, L4F11:NEAR, L4F36:NEAR, L4F4D:NEAR
	EXTRN L4FDF:NEAR, L507A:NEAR, L50B3:NEAR, L50EF:NEAR, L50F9:NEAR, L51EB:NEAR
	EXTRN L5217:NEAR, L5255:NEAR, L52CA:NEAR, L53F4:NEAR, L5AB1:NEAR, L5C95:NEAR
	EXTRN L5EAC:NEAR, L5EC7:NEAR, L5EF2:NEAR
	PUBLIC L0764, L086F, L09FB, L0A30, L0A33, L0AA1
	PUBLIC L0AA7, L0BAF, L0C62
ASSUME CS:CODE, DS:DATA

;------------------------------------------------------------------------------
; L0730: command jump table, one handler per letter A-Z (index (key-'A')*2,
; read at 0A29, `jmp bx` at 0A2E). Names as in the manual. The handlers (CMDAL,
; CMDMZ) print their name and end with jmp L0A33 / L0A30.
;------------------------------------------------------------------------------
L0730:	dw L2B8F	; A Attack	;@0730
	dw L2F6F	; B Board	;@0732
	dw L310B	; C Cast	;@0734
	dw L334D	; D Descend	;@0736
	dw L3389	; E Enter	;@0738
	dw L35C1	; F Fire	;@073A
	dw L363B	; G Get	;@073C
	dw L3782	; H Hyperspace	;@073E
	dw L3794	; I Ignite (a torch)	;@0740
	dw L37DC	; J Jump	;@0742
	dw L37F1	; K Klimb	;@0744
	dw L38B0	; L Launch	;@0746
	dw L3B92	; M Magic	;@0748
	dw L3BCE	; N Negate	;@074A
	dw L3C2E	; O Offer	;@074C
	dw L3DBC	; P Pass	;@074E
	dw L3DC7	; Q Quit (save)	;@0750
	dw L3E50	; R Ready	;@0752
	dw L3F25	; S Steal	;@0754
	dw L4050	; T Transact	;@0756
	dw L42F1	; U Unlock	;@0758
	dw L437E	; V View	;@075A
	dw L43F3	; W Wear	;@075C
	dw L44D4	; X Xit	;@075E
	dw L4542	; Y Yell	;@0760
	dw L4568	; Z Ztatus	;@0762

;------------------------------------------------------------------------------
; L0764: game start ('P' in the menu, START 03AC). Reads
; the 256-byte PLAYER record to D_0036 (an empty name means "NO CHARACTER ON
; DISK": wait for Escape and try again, forever), resets the delay table from
; the saved speed D_0074, reads MONSTERS (800h bytes) to the buffer at D_0474,
; then the map and monster files of the saved place (L2290), CGA mode, the
; player on foot (figure 78h + 2 * class) at the saved surface position
; D_005A/D_005B, timers cleared, the parked rocket (D_0069) put back on the
; map, the map window drawn and the status lines shown. Falls into L086F.
; Out: does not return.
;------------------------------------------------------------------------------
L0764:	call L4A1C	; text mode, clear	;@0764
	mov bh, 0	;@0767
	mov bl, 0Ch	;@0769
	mov si, bx	;@076B
	mov bh, 0	;@076D
	mov bl, 0Ah	;@076F
	mov di, bx	;@0771
	call L51EB	; cursor to column 10, row 12	;@0773
	jmp short L0796	; 1989 patch over a `call L4FDF` (E8 66 48): 48h left	;@0776
;
; Dead (jumped over): the rest of `call L4FDF` "(INSERT PLAYER DISK)", then
; wait for Escape (call L4F4D; cmp ax,0FF1Bh; jne 078E).
;
	db 48h,28h,49h,4Eh,53h,45h,52h,54h,20h,50h,4Ch,41h,59h,45h,52h,20h	;@0778
	db 44h,49h,53h,4Bh,29h,0h,0E8h,0BCh,47h,3Dh,1Bh,0FFh,75h,0F8h	;@0788
L0796:	mov cx, 100h	; 256 bytes	;@0796
	lea dx, D_0036	; the player record (starts with the name)	;@0799
	mov ah, 27h	; read	;@079D
	call L52CA	;@079F
	db 50h,4Ch,41h,59h,45h,52h,20h,20h	; "PLAYER  "	;@07A2
	mov al, byte ptr D_0036	; empty name: no character	;@07AA
	or al, al	;@07AD
	jne L07E6	;@07AF
	call L4A1C	;@07B1
	mov bh, 0	;@07B4
	mov bl, 0Ch	;@07B6
	mov si, bx	;@07B8
	mov bh, 0	;@07BA
	mov bl, 0Ah	;@07BC
	mov di, bx	;@07BE
	call L51EB	;@07C0
	call L4FDF	;@07C3
	db 4Eh,4Fh,20h,43h,48h,41h,52h,41h,43h,54h,45h,52h,20h,4Fh,4Eh,20h	; "NO CHARACTER ON DISK"	;@07C6
	db 44h,49h,53h,4Bh,0h	;@07D6
L07DB:	call L4F4D	;@07DB
	cmp ax, 0FF1Bh	; Escape: read PLAYER again	;@07DE
	jne L07DB	;@07E1
	jmp L0764	;@07E3
;
; D_0074 (speed setting) is part of the PLAYER record; 0 = never set.
;
L07E6:	cmp word ptr D_0074, 0	;@07E6
	jne L07F0	;@07EB
	call L06AC	; default 0FFh	;@07ED
L07F0:	call L06ED	; delay table from the saved speed	;@07F0
	mov cx, 800h	;@07F3
	mov dx, word ptr D_0474	; monster buffer	;@07F6
	mov ah, 27h	;@07FA
	call L52CA	;@07FC
	db 4Dh,4Fh,4Eh,53h,54h,45h,52h,53h	; "MONSTERS"	;@07FF
	call L2290	; map MAPxx and monster table MONxx (D_0137) of the saved place	;@0807
	call L4A3E	; CGA mode 4	;@080A
	mov al, byte ptr D_0047	; class 0-3 (fighter, cleric, wizard, thief)	;@080D
	add al, al	;@0810
	clc	;@0812
	adc al, 78h	;@0813
	mov byte ptr D_0013, al	; player figure 78h + 2 * class: on foot	;@0815
	mov al, 0	;@0818
	mov byte ptr D_026A, al	; negate timer	;@081A
	mov byte ptr D_026B, al	; legs paralysed	;@081D
	mov byte ptr D_026C, al	; arms paralysed	;@0820
	mov byte ptr D_026D, al	; asleep	;@0823
	mov al, byte ptr D_005A	;@0826
	mov byte ptr D_0000, al	; X = saved surface X	;@0829
	mov al, byte ptr D_005B	;@082C
	mov byte ptr D_0001, al	; Y = saved surface Y	;@082F
	mov al, byte ptr D_0069	; a rocket parked somewhere?	;@0832
	or al, al	;@0835
	je L0850	;@0837
	mov al, byte ptr D_006A	;@0839
	mov byte ptr D_0023, al	;@083C
	mov al, byte ptr D_006B	;@083F
	mov byte ptr D_0024, al	;@0842
	call L50B3	; D_0006 -> map cell at (D_0023, D_0024), SI = 0	;@0845
	mov al, 50h	; rocket (map code 50h = figure 28h)	;@0848
	mov bx, word ptr D_0006	;@084A
	mov byte ptr [bx+si], al	;@084E
;
; Fill both tile caches of the map window with 0FFh so L5AB1 redraws every
; tile. (Entries FEh..0; entry FFh is left alone, CMDAL 3964 does all 256.)
;
L0850:	nop	;@0850
	mov bh, 0	;@0851
	mov bl, 0FFh	;@0853
	mov di, bx	;@0855
	mov al, 0FFh	;@0857
L0859:	dec di	;@0859
	mov byte ptr D_0272[di], al	;@085A
	mov byte ptr D_0372[di], al	;@085E
	jne L0859	;@0862
	call L5AB1	; draw the map window	;@0864
	mov al, 0FFh	;@0867
	mov byte ptr D_0012, al	; map wraps around (surface)	;@0869
	call L50F9	; status lines: H.P., FOOD, EXP., GOLD	;@086C

;------------------------------------------------------------------------------
; L086F: the main loop, top: one player command per pass. Also jumped to from
; EVENTS (12D8). Resets SP. In a tower or dungeon (D_004A >= 4) the DUNGEON
; loop L27C0 takes over. Prints "CMD: ", animates the water tiles, then:
; asleep (D_026D) -> 20 'Z's and the turn is lost; otherwise wait for a key
; (L08C8).
;------------------------------------------------------------------------------
L086F:	nop	;@086F
	mov sp, 100h	; forget any pending returns	;@0870
	mov al, byte ptr D_004A	; map type: 0 surface, 1 village, 2 town, 3 castle, 4 tower, 5 dungeon	;@0873
	cmp al, 4	;@0876
	jb L087D	;@0878
	jmp L27C0	;@087A
L087D:	nop	;@087D
	call L4FDF	;@087E
	db 43h,4Dh,44h,3Ah,20h,0h	; "CMD: "	;@0881
;
; L4AE6 scrolls the bitmap of the first tile (water) by one row, L4AF1 that of
; tile record 23 (D_05DE); here 4 rows and 1 row. Seen at the next map redraw.
;
	call L4AE6	;@0887
	call L4AE6	;@088A
	call L4AE6	;@088D
	call L4AE6	;@0890
	call L4AF1	;@0893
	mov al, 0	;@0896
	mov byte ptr D_0021, al	; idle timer, low (counts key polls)	;@0898
	mov al, 0C0h	;@089B
	mov byte ptr D_0022, al	; idle timer, high: 40h x 256 polls until "PASS"	;@089D
	mov al, byte ptr D_026D	; asleep?	;@08A0
	or al, al	;@08A3
	je L08C8	;@08A5
	mov al, 14h	;@08A7
	mov byte ptr D_0027, al	; 20 'Z's	;@08A9
L08AC:	call L4FDF	;@08AC
	db 5Ah,0h	; "Z"	;@08AF
	mov bh, 0	;@08B1
	mov bl, 0FFh	;@08B3
	mov di, bx	;@08B5
L08B7:	dec di	; short busy loop, CPU-speed dependent	;@08B7
	nop	;@08B8
	nop	;@08B9
	nop	;@08BA
	nop	;@08BB
	nop	;@08BC
	jne L08B7	;@08BD
	dec byte ptr D_0027	;@08BF
	jne L08AC	;@08C3
	jmp L0A33	; the monsters move	;@08C5
;
; Wait for a key. Every 256 polls: plane engine sound (when flying, D_0013 =
; 26h), redraw the map window (animated tiles), scroll the tiles again. After
; 40h x 256 polls without a key the turn passes by itself ("PASS").
;
L08C8:	mov bx, 0	; delay table entry 0	;@08C8
	call L0711	;@08CB
	call L4F4D	; AH = FFh: key in AL (upper case)	;@08CE
	cmp ah, 0FFh	;@08D1
	je L0936	;@08D4
	inc byte ptr D_0021	;@08D6
	jne L08C8	;@08DA
	mov al, byte ptr D_0013	;@08DC
	cmp al, 26h	; plane?	;@08DF
	jne L08E6	;@08E1
	call L5EC7	; engine sound	;@08E3
L08E6:	nop	;@08E6
	call L5AB1	;@08E7
	call L4AE6	;@08EA
	call L4AE6	;@08ED
	call L4AE6	;@08F0
	call L4AE6	;@08F3
	call L4AF1	;@08F6
	inc byte ptr D_0022	;@08F9
	jne L08C8	;@08FD
	mov al, 0	;@08FF
	mov byte ptr D_0026, al	; idle pass resets the horse half-turn	;@0901
	call L4FDF	;@0904
	db 50h,41h,53h,53h,0h	; "PASS"	;@0907
;
; L090C: a turn passes without moving: food -= 0.1 (BCD D_0053 D_0054 . D_0055;
; 6502 style: stc/cmc + sbb = SBC with carry, das after each byte). Running out
; of food is death (L228D -> L0C62).
;
L090C:	stc	;@090C
	mov al, byte ptr D_0055	; food, hundredths	;@090D
	cmc	;@0910
	sbb al, 0Ah	; minus 10 hundredths (das fixes it to BCD)	;@0911
	das	;@0913
	cmc	; CF = 1: no borrow (6502 carry)	;@0914
	mov byte ptr D_0055, al	;@0915
	mov al, byte ptr D_0054	; food, low two digits	;@0918
	cmc	;@091B
	sbb al, 0	;@091C
	das	;@091E
	cmc	;@091F
	mov byte ptr D_0054, al	;@0920
	mov al, byte ptr D_0053	; food, high two digits	;@0923
	cmc	;@0926
	sbb al, 0	;@0927
	das	;@0929
	cmc	;@092A
	mov byte ptr D_0053, al	;@092B
	jb L0933	; no borrow: still food left	;@092E
	jmp L228D	; starved: L0C62	;@0930
L0933:	jmp L0A33	;@0933
;
; L0936: a key was pressed. Space = pass, then the four direction keys
; D_026E-D_0271 (what L4F4D makes of the arrow keys: N 0Eh, S 19h, E 05h,
; W 17h). A move changes D_0000/D_0001 first and lets L2423 (MOVE) judge the
; tile entered (AL = D_0015-D_0018, the tile in that direction): AL = 0 means
; the move is allowed, otherwise it is undone ("--INVALID MOVE!").
;
L0936:	mov byte ptr D_005D, al	; the last key (only used here)	;@0936
	mov al, byte ptr D_005D	;@0939
	cmp al, 20h	; Space = pass	;@093C
	jne L094F	;@093E
	mov al, 0	;@0940
	mov byte ptr D_0026, al	;@0942
	call L4FDF	;@0945
	db 50h,41h,53h,53h,0h	; "PASS"	;@0948
	jmp L090C	;@094D
L094F:	cmp al, byte ptr D_026E	; north (up arrow)	;@094F
	jne L0976	;@0953
	dec byte ptr D_0001	;@0955
	call L4FDF	;@0959
	db 4Eh,4Fh,52h,54h,48h,0h	; "NORTH"	;@095C
	mov al, byte ptr D_0015	; tile north of the player	;@0962
	call L2423	;@0965
	cmp al, 0	;@0968
	je L0973	;@096A
	inc byte ptr D_0001	; blocked: undo	;@096C
	jmp L0A02	;@0970
L0973:	jmp L09E9	;@0973
L0976:	cmp al, byte ptr D_026F	; south (down arrow)	;@0976
	jne L099D	;@097A
	inc byte ptr D_0001	;@097C
	call L4FDF	;@0980
	db 53h,4Fh,55h,54h,48h,0h	; "SOUTH"	;@0983
	mov al, byte ptr D_0016	;@0989
	call L2423	;@098C
	cmp al, 0	;@098F
	je L099A	;@0991
	dec byte ptr D_0001	;@0993
	jmp L0A02	;@0997
L099A:	jmp L09E9	;@099A
L099D:	cmp al, byte ptr D_0271	; west (left arrow)	;@099D
	jne L09C3	;@09A1
	dec byte ptr D_0000	;@09A3
	call L4FDF	;@09A7
	db 57h,45h,53h,54h,0h	; "WEST"	;@09AA
	mov al, byte ptr D_0018	;@09AF
	call L2423	;@09B2
	cmp al, 0	;@09B5
	je L09C0	;@09B7
	inc byte ptr D_0000	;@09B9
	jmp L0A02	;@09BD
L09C0:	jmp L09E9	;@09C0
L09C3:	cmp al, byte ptr D_0270	; east (right arrow)	;@09C3
	jne L09F4	;@09C7
	inc byte ptr D_0000	;@09C9
	call L4FDF	;@09CD
	db 45h,41h,53h,54h,0h	; "EAST"	;@09D0
	mov al, byte ptr D_0017	;@09D5
	call L2423	;@09D8
	cmp al, 0	;@09DB
	je L09E6	;@09DD
	dec byte ptr D_0000	;@09DF
	jmp L0A02	;@09E3
L09E6:	jmp L09E9	;@09E6
;
; A successful move flips D_0026. On horseback the slow monsters only move
; when D_0026 is 0 (see 0A83): the horse is twice as fast.
;
L09E9:	mov al, byte ptr D_0026	;@09E9
	xor al, 0FFh	;@09EC
	mov byte ptr D_0026, al	;@09EE
	jmp L0A33	;@09F1
L09F4:	push ax	;@09F4
	mov al, 0	;@09F5
	mov byte ptr D_0026, al	; any command resets the horse half-turn	;@09F7
	pop ax	;@09FA
;
; L09FB: dispatch a command key A-Z through L0730 (also entered from the
; DUNGEON loop at 285E). Others: "-ILLEGAL COMMAND!" (L2275).
; In: AL = key (upper case).
;
L09FB:	cmp al, 41h	; 'A'	;@09FB
	jae L0A18	;@09FD
	jmp L2275	;@09FF
L0A02:	call L4FDF	;@0A02
	db 2Dh,2Dh,49h,4Eh,56h,41h,4Ch,49h,44h,20h,4Dh,4Fh,56h,45h,21h,0h	; "--INVALID MOVE!"	;@0A05
	jmp L0A30	;@0A15
L0A18:	cmp al, 5Ah	; 'Z'	;@0A18
	jbe L0A1F	;@0A1A
	jmp L2275	;@0A1C
L0A1F:	stc	;@0A1F
	cmc	;@0A20
	sbb al, 41h	; AL - 'A' (6502 SEC/SBC, carry clear = no borrow in)	;@0A21
	add al, al	;@0A23
	mov ah, 0	;@0A25
	mov si, ax	;@0A27
	mov bx, word ptr cs:L0730[si]	;@0A29
	jmp bx	; the only indirect jump in the program	;@0A2E

;------------------------------------------------------------------------------
; L0A30: end of a command that failed: error beep (L5C95), then L0A33.
; L0A33: end of a command: new line, clear the turn counters D_0020-D_0022,
; then the monsters' turn according to the map type D_004A: outdoors L0A6D
; below; village/town/castle L1013/L1014/L1015 and tower/dungeon L115F/L115E
; in EVENTS (they come back through L0AA7, L0BAF, L086F).
; Jumped to from nearly every command handler (about 130 places).
;------------------------------------------------------------------------------
L0A30:	call L5C95	; error beep	;@0A30
L0A33:	mov al, 0Dh	;@0A33
	call L53F4	; print CR	;@0A35
	mov al, 0	;@0A38
	mov byte ptr D_0022, al	; damage this turn	;@0A3A
	mov byte ptr D_0020, al	; attacks this turn	;@0A3D
	mov byte ptr D_0021, al	; hits this turn	;@0A40
	mov al, byte ptr D_004A	;@0A43
	or al, al	;@0A46
	je L0A6D	;@0A48
	cmp al, 1	;@0A4A
	jne L0A51	;@0A4C
	jmp L1013	;@0A4E
L0A51:	cmp al, 2	;@0A51
	jne L0A58	;@0A53
	jmp L1014	;@0A55
L0A58:	cmp al, 3	;@0A58
	jne L0A5F	;@0A5A
	jmp L1015	;@0A5C
L0A5F:	cmp al, 4	;@0A5F
	jne L0A66	;@0A61
	jmp L115F	;@0A63
L0A66:	cmp al, 5	;@0A66
	jne L0A6D	;@0A68
	jmp L115E	;@0A6A

;------------------------------------------------------------------------------
; L0A6D: the outdoor monsters' turn: monster slots 1Fh down to 1 (slot 0 is
; never used here). Free slots (D_0197 = 0) are skipped. On horseback
; (D_0013 = 22h) on the half-turns where D_0026 is negative, all but the fast
; monsters (map codes 48h, 3Ch, 2Ch) skip their move. Then L0C9C may spawn a
; new monster.
;------------------------------------------------------------------------------
L0A6D:	nop	;@0A6D
	mov bh, 0	;@0A6E
	mov bl, 1Fh	;@0A70
	mov di, bx	;@0A72
L0A74:	mov al, byte ptr D_0197[di]	; map code of the monster, 0 = free slot	;@0A74
	or al, al	;@0A78
	je L0AA1	;@0A7A
	mov al, byte ptr D_0013	;@0A7C
	cmp al, 22h	; on horseback?	;@0A7F
	jne L0AA7	;@0A81
	mov al, byte ptr D_0026	;@0A83
	or al, al	;@0A86
	jns L0AA7	;@0A88
	mov al, byte ptr D_0197[di]	;@0A8A
	cmp al, 48h	;@0A8E
	je L0AA7	;@0A90
	cmp al, 3Ch	;@0A92
	je L0AA7	;@0A94
	cmp al, 2Ch	;@0A96
	je L0AA7	;@0A98
	mov al, byte ptr D_0013	; the same test again: always 22h here	;@0A9A
	cmp al, 22h	;@0A9D
	jne L0AA7	;@0A9F
L0AA1:	dec di	; next monster (also entered from INPUT 2196/2272)	;@0AA1
	jne L0A74	;@0AA2
	jmp L0C9C	;@0AA4

;------------------------------------------------------------------------------
; L0AA7: one monster's turn (also entered from EVENTS 1083 for town monsters).
; In: DI = monster slot. Within 2 squares (raw difference, no wrap) and with a
; 1 in 8 chance it casts by type (map code): 34h "LEGS PARALYZED!" (L0E70),
; 38h "ARMS PARALYZED!" (L0EC2), 0F8h "MAGIC MISSILE!" (L0F12), 3Ch "SLEEP
; SPELL!" (L0F48). Then it steps one square towards the player (away from him
; when its hit points D_0177 are below 0Fh): if that square is the player's it
; attacks (L0B4D), else L2122 (INPUT) moves it, which ends with jmp L0AA1.
; Uses: D_0019/D_001A (deltas), D_0029 (slot), D_0027.
;------------------------------------------------------------------------------
L0AA7:	call L4F36	; D_0019/D_001A = player X/Y - monster X/Y	;@0AA7
	mov bx, di	;@0AAA
	mov byte ptr D_0029, bl	; save the slot	;@0AAC
	mov al, byte ptr D_0019	;@0AB0
	call L50EF	; absolute value	;@0AB3
	cmp al, 3	;@0AB6
	jae L0AFC	;@0AB8
	mov al, byte ptr D_001A	;@0ABA
	call L50EF	;@0ABD
	cmp al, 3	;@0AC0
	jae L0AFC	;@0AC2
	call L5217	; random 0-FFh	;@0AC4
	mov bh, 0	;@0AC7
	mov bl, byte ptr D_0029	;@0AC9
	mov di, bx	;@0ACD
	cmp al, 20h	; 1 in 8	;@0ACF
	jae L0AFC	;@0AD1
	mov al, byte ptr D_0197[di]	;@0AD3
	cmp al, 34h	;@0AD7
	jne L0AE1	;@0AD9
	call L0E70	; legs paralysed (magical boots save)	;@0ADB
	jmp L0AFC	;@0ADE
L0AE1:	cmp al, 38h	;@0AE1
	jne L0AEB	;@0AE3
	call L0EC2	; arms paralysed (magical cloak saves)	;@0AE5
	jmp L0AFC	;@0AE8
L0AEB:	cmp al, 0F8h	;@0AEB
	jne L0AF5	;@0AED
	call L0F12	; magic missile: adds 2 attacks, 2 hits, 40h damage	;@0AEF
	jmp L0AFC	;@0AF2
L0AF5:	cmp al, 3Ch	;@0AF5
	jne L0AFC	;@0AF7
	call L0F48	; sleep spell (the idol saves)	;@0AF9
L0AFC:	mov bh, 0	;@0AFC
	mov bl, byte ptr D_0029	;@0AFE
	mov di, bx	;@0B02
	call L4F11	; D_0019/D_001A = direction to the player, -1/0/1 (with wrap)	;@0B04
	mov al, byte ptr D_0177[di]	; hit points	;@0B07
	cmp al, 0Fh	;@0B0B
	jae L0B25	;@0B0D
	stc	; weak: flee, negate the direction (0 - D)	;@0B0F
	mov al, 0	;@0B10
	cmc	;@0B12
	sbb al, byte ptr D_0019	;@0B13
	mov byte ptr D_0019, al	;@0B17
	stc	;@0B1A
	mov al, 0	;@0B1B
	cmc	;@0B1D
	sbb al, byte ptr D_001A	;@0B1E
	mov byte ptr D_001A, al	;@0B22
L0B25:	clc	;@0B25
	mov al, byte ptr D_0137[di]	; monster X + DX = player X?	;@0B26
	adc al, byte ptr D_0019	;@0B2A
	and al, 3Fh	;@0B2E
	cmp al, byte ptr D_0000	;@0B30
	je L0B39	;@0B34
	jmp L2122	; no: move it	;@0B36
L0B39:	clc	;@0B39
	mov al, byte ptr D_0157[di]	; monster Y + DY = player Y?	;@0B3A
	adc al, byte ptr D_001A	;@0B3E
	and al, 3Fh	;@0B42
	cmp al, byte ptr D_0001	;@0B44
	je L0B4D	;@0B48
	jmp L2122	;@0B4A
;
; L0B4D: the monster attacks. A thief (0FCh) may steal first (L0FCD). Misses
; when the random number has bit 7 set, or when its low 3 bits are below the
; armour worn D_0062. A hit adds (hit points / 4) + 1 to the damage D_0022,
; doubled when D_0014 (the tile under the player) is 6 (woods?).
;
L0B4D:	inc byte ptr D_0020	; attacks this turn	;@0B4D
	mov bx, di	;@0B51
	mov byte ptr D_0027, bl	;@0B53
	mov al, byte ptr D_0197[di]	;@0B57
	cmp al, 0FCh	; thief?	;@0B5B
	jne L0B62	;@0B5D
	call L0FCD	; steal	;@0B5F
L0B62:	call L5217	;@0B62
	mov bh, 0	;@0B65
	mov bl, byte ptr D_0027	;@0B67
	mov di, bx	;@0B6B
	cmp al, 0	;@0B6D
	js L0BA0	; miss (1 in 2)	;@0B6F
	and al, 7	;@0B71
	cmp al, byte ptr D_0062	; armour worn	;@0B73
	jb L0BA0	; miss	;@0B77
	inc byte ptr D_0021	; hits this turn	;@0B79
	mov al, byte ptr D_0177[di]	;@0B7D
	clc	;@0B81
	rcr al, 1	;@0B82
	clc	;@0B84
	rcr al, 1	; hit points / 4	;@0B85
	stc	; + 1	;@0B87
	adc al, byte ptr D_0022	;@0B88
	mov bh, 0	;@0B8C
	mov bl, byte ptr D_0014	; 6502 LDX $14 / CPX #6	;@0B8E
	mov si, bx	;@0B92
	mov bx, si	;@0B94
	cmp bl, 6	;@0B96
	jne L0B9D	;@0B99
	add al, al	;@0B9B
L0B9D:	mov byte ptr D_0022, al	;@0B9D
L0BA0:	nop	;@0BA0
	mov al, byte ptr D_004A	;@0BA1
	or al, al	;@0BA4
	je L0BAB	;@0BA6
	jmp L1040	; not outdoors: back to the EVENTS monster loop	;@0BA8
L0BAB:	nop	;@0BAB
	jmp L0AA1	;@0BAC

;------------------------------------------------------------------------------
; L0BAF: end of the turn (also entered from EVENTS 1078, and from the spawn
; code). Redraw the map window; for each attack D_0020 an attack sound, the
; first D_0021 of them also flash the player square (L5255 twice, XOR?) with
; the hit sound; then apply the damage D_0022: hit points (BCD D_0051 D_0052)
; -= (random AND D_0022 AND 77h) + 1, a BCD number of at most 78. In a
; village/town/castle (or tower/dungeon) also D_004A hundreds more (hence the
; deadly guards?). Hit points below 0: L0C62. Then the status lines, the
; off-map tile, the time doors (outdoors) and the four timers count down.
;------------------------------------------------------------------------------
L0BAF:	call L5AB1	;@0BAF
L0BB2:	mov al, byte ptr D_0020	;@0BB2
	or al, al	;@0BB5
	je L0BD1	;@0BB7
	call L5EAC	; attack sound	;@0BB9
	dec byte ptr D_0020	;@0BBC
	dec byte ptr D_0021	;@0BC0
	js L0BB2	; no hits left: a miss	;@0BC4
	call L5255	; mark the player square	;@0BC6
	call L5EF2	; hit sound	;@0BC9
	call L5255	; and unmark it	;@0BCC
	jmp L0BB2	;@0BCF
L0BD1:	mov al, byte ptr D_0022	;@0BD1
	or al, al	;@0BD4
	je L0C1C	;@0BD6
	call L5217	;@0BD8
	and al, byte ptr D_0022	;@0BDB
	and al, 77h	; keeps both BCD digits <= 7	;@0BDF
	clc	;@0BE1
	adc al, 1	;@0BE2
	mov byte ptr D_0022, al	;@0BE4
	stc	;@0BE7
	mov al, byte ptr D_0052	; hit points, low two digits	;@0BE8
	cmc	;@0BEB
	sbb al, byte ptr D_0022	;@0BEC
	das	;@0BF0
	cmc	;@0BF1
	mov byte ptr D_0052, al	;@0BF2
	mov al, byte ptr D_0051	; hit points, high two digits	;@0BF5
	cmc	;@0BF8
	sbb al, 0	;@0BF9
	das	;@0BFB
	cmc	;@0BFC
	mov byte ptr D_0051, al	;@0BFD
	jae L0C62	; borrow: dead	;@0C00
	mov al, byte ptr D_004A	;@0C02
	or al, al	;@0C05
	je L0C1C	;@0C07
	mov byte ptr D_0022, al	;@0C09
	stc	;@0C0C
	mov al, byte ptr D_0051	; hundreds -= map type (1-5)	;@0C0D
	cmc	;@0C10
	sbb al, byte ptr D_0022	;@0C11
	das	;@0C15
	cmc	;@0C16
	mov byte ptr D_0051, al	;@0C17
	jae L0C62	;@0C1A
L0C1C:	call L50F9	; status lines	;@0C1C
	mov al, 4	;@0C1F
	mov byte ptr D_0012, al	; off-map tile: 4 (grass) around a town	;@0C21
	mov al, byte ptr D_004A	;@0C24
	or al, al	;@0C27
	jne L0C33	;@0C29
	mov al, 0FFh	;@0C2B
	mov byte ptr D_0012, al	; outdoors: the map wraps	;@0C2D
	call L26F9	; every 8 turns move the time door (DUNGEON)	;@0C30
;
; Count down the timers (each stops at 0).
;
L0C33:	mov al, byte ptr D_026B	; legs paralysed	;@0C33
	or al, al	;@0C36
	je L0C3E	;@0C38
	dec byte ptr D_026B	;@0C3A
L0C3E:	mov al, byte ptr D_026C	; arms paralysed	;@0C3E
	or al, al	;@0C41
	je L0C49	;@0C43
	dec byte ptr D_026C	;@0C45
L0C49:	mov al, byte ptr D_026D	; asleep	;@0C49
	or al, al	;@0C4C
	je L0C54	;@0C4E
	dec byte ptr D_026D	;@0C50
L0C54:	mov al, byte ptr D_026A	; time stopped (Negate)	;@0C54
	or al, al	;@0C57
	je L0C5F	;@0C59
	dec byte ptr D_026A	;@0C5B
L0C5F:	jmp L086F	; next command	;@0C5F

;------------------------------------------------------------------------------
; L0C62: the player dies (no hit points, no food, ...; jumped to from EVENTS,
; INPUT, MOVE, DUNGEON, CMDAL). Hit points, food, experience and gold become
; 0, the status lines show it, then "<name> IS DEAD!" and the program hangs
; in an endless loop (the player must reboot).
;------------------------------------------------------------------------------
L0C62:	mov al, 0	;@0C62
	mov byte ptr D_0051, al	;@0C64
	mov byte ptr D_0052, al	;@0C67
	mov byte ptr D_0053, al	;@0C6A
	mov byte ptr D_0054, al	;@0C6D
	mov byte ptr D_0055, al	;@0C70
	mov byte ptr D_0056, al	;@0C73
	mov byte ptr D_0057, al	;@0C76
	mov byte ptr D_0058, al	;@0C79
	mov byte ptr D_0059, al	;@0C7C
	call L50F9	;@0C7F
	call L4FDF	;@0C82
	db 8Dh,8Dh,8Dh,0h	; three CRs	;@0C85
	call L507A	; the player's name	;@0C89
	call L4FDF	;@0C8C
	db 20h,49h,53h,20h,44h,45h,41h,44h,21h,8Dh,0h	; " IS DEAD!", CR	;@0C8F
L0C9A:	jmp L0C9A	; hang forever	;@0C9A

;------------------------------------------------------------------------------
; L0C9C: outdoors, after the monsters moved: maybe spawn one. Takes the
; highest free slot (1Fh..1; none free: L0BAF), a random X (0-3Eh, else no
; spawn) and Y (0-3Fh, a negative random number: no spawn), notes the terrain
; there in D_01B7 and picks the type from the lowest set bit of the counter
; D_0060 (saved with the player), so the types come in a fixed rotation:
;   bit 0: 30h (hit points 10h)   bit 1: 0FCh thief (20h)   bit 2: 34h (40h)
;   bit 3: 2Ch on water (40h)     bit 4: 0F0h (80h)         bit 5: 48h on water (A0h)
;   bit 6: 38h (C0h)              bit 7: 0F8h wizard (E0h)  none: 3Ch (FFh)
; (Map code / 2 is the figure: 0F0h/0F8h/0FCh look like a fighter/wizard/thief
; player figure 78h/7Ch/7Eh, 48h like a frigate 24h: pirates?)
; The land types need grass (terrain code 8), the water ones water (0); on the
; wrong terrain D_0060 is put back and nothing spawns this turn. The monster's
; map code is written into the map and into D_0197, its hit points into D_0177.
; A square holding a monster has its code, not 8 or 0, so it is refused; the
; player's own square is not checked (he is not in the map), so a monster can
; appear on top of him.
;------------------------------------------------------------------------------
L0C9C:	mov bh, 0	;@0C9C
	mov bl, 1Fh	;@0C9E
	mov di, bx	;@0CA0
L0CA2:	mov al, byte ptr D_0197[di]	;@0CA2
	or al, al	;@0CA6
	je L0CB0	; free slot found	;@0CA8
	dec di	;@0CAA
	jne L0CA2	;@0CAB
	jmp L0BAF	;@0CAD
L0CB0:	mov bx, di	;@0CB0
	mov byte ptr D_001F, bl	; the new monster's slot	;@0CB2
	call L5217	;@0CB6
	cmp al, 3Fh	;@0CB9
	jb L0CC0	;@0CBB
	jmp L0BAF	; most of the time: no spawn	;@0CBD
L0CC0:	mov bh, 0	;@0CC0
	mov bl, byte ptr D_001F	;@0CC2
	mov di, bx	;@0CC6
	mov byte ptr D_0137[di], al	; X	;@0CC8
	mov byte ptr D_0023, al	;@0CCC
	call L5217	;@0CCF
	js L0CD9	;@0CD2
	and al, 3Fh	;@0CD4
	jmp L0CDC	;@0CD6
L0CD9:	jmp L0BAF	;@0CD9
L0CDC:	mov bh, 0	;@0CDC
	mov bl, byte ptr D_001F	;@0CDE
	mov di, bx	;@0CE2
	mov byte ptr D_0157[di], al	; Y	;@0CE4
	mov byte ptr D_0024, al	;@0CE8
	call L50B3	; AL = map code at (X, Y), D_0006 -> the cell, SI = 0	;@0CEB
	mov bh, 0	;@0CEE
	mov bl, byte ptr D_001F	;@0CF0
	mov di, bx	;@0CF4
	mov byte ptr D_01B7[di], al	; terrain under the monster	;@0CF6
	inc byte ptr D_0060	;@0CFA
	mov al, byte ptr D_0060	;@0CFE
;
; Find the lowest set bit of D_0060 (rcr into the carry, bit by bit).
;
	clc	;@0D01
	rcr al, 1	;@0D02
	jae L0D09	;@0D04
	jmp L0D44	;@0D06
L0D09:	clc	;@0D09
	rcr al, 1	;@0D0A
	jae L0D11	;@0D0C
	jmp L0D64	;@0D0E
L0D11:	clc	;@0D11
	rcr al, 1	;@0D12
	jae L0D19	;@0D14
	jmp L0D84	;@0D16
L0D19:	clc	;@0D19
	rcr al, 1	;@0D1A
	jae L0D21	;@0D1C
	jmp L0DA4	;@0D1E
L0D21:	clc	;@0D21
	rcr al, 1	;@0D22
	jae L0D29	;@0D24
	jmp L0DD4	;@0D26
L0D29:	clc	;@0D29
	rcr al, 1	;@0D2A
	jae L0D31	;@0D2C
	jmp L0DCB	;@0D2E
L0D31:	clc	;@0D31
	rcr al, 1	;@0D32
	jae L0D39	;@0D34
	jmp L0DCE	;@0D36
L0D39:	clc	;@0D39
	rcr al, 1	;@0D3A
	jae L0D41	;@0D3C
	jmp L0DD1	;@0D3E
L0D41:	jmp L0E50	; D_0060 = 0	;@0D41
;
; One block per type: right terrain? then write the map code to the map
; (D_0006 = the cell, SI = 0) and to D_0197, the hit points to D_0177, done
; (L0BAF). Wrong terrain: L0DC4.
;
L0D44:	mov al, byte ptr D_01B7[di]	;@0D44
	cmp al, 8	; grass?	;@0D48
	je L0D4F	;@0D4A
	jmp L0DC4	;@0D4C
L0D4F:	mov al, 30h	;@0D4F
	mov bx, word ptr D_0006	;@0D51
	mov byte ptr [bx+si], al	;@0D55
	mov byte ptr D_0197[di], al	;@0D57
	mov al, 10h	;@0D5B
	mov byte ptr D_0177[di], al	;@0D5D
	jmp L0BAF	;@0D61
L0D64:	mov al, byte ptr D_01B7[di]	;@0D64
	cmp al, 8	;@0D68
	je L0D6F	;@0D6A
	jmp L0DC4	;@0D6C
L0D6F:	mov al, 0FCh	; thief	;@0D6F
	mov bx, word ptr D_0006	;@0D71
	mov byte ptr [bx+si], al	;@0D75
	mov byte ptr D_0197[di], al	;@0D77
	mov al, 20h	;@0D7B
	mov byte ptr D_0177[di], al	;@0D7D
	jmp L0BAF	;@0D81
L0D84:	mov al, byte ptr D_01B7[di]	;@0D84
	cmp al, 8	;@0D88
	je L0D8F	;@0D8A
	jmp L0DC4	;@0D8C
L0D8F:	mov al, 34h	;@0D8F
	mov bx, word ptr D_0006	;@0D91
	mov byte ptr [bx+si], al	;@0D95
	mov byte ptr D_0197[di], al	;@0D97
	mov al, 40h	;@0D9B
	mov byte ptr D_0177[di], al	;@0D9D
	jmp L0BAF	;@0DA1
L0DA4:	mov al, byte ptr D_01B7[di]	;@0DA4
	cmp al, 0	; water?	;@0DA8
	je L0DAF	;@0DAA
	jmp L0DC4	;@0DAC
L0DAF:	mov al, 2Ch	;@0DAF
	mov bx, word ptr D_0006	;@0DB1
	mov byte ptr [bx+si], al	;@0DB5
	mov byte ptr D_0197[di], al	;@0DB7
	mov al, 40h	;@0DBB
	mov byte ptr D_0177[di], al	;@0DBD
	jmp L0BAF	;@0DC1
L0DC4:	dec byte ptr D_0060	; wrong terrain: try this type again next time	;@0DC4
	jmp L0BAF	;@0DC8
L0DCB:	jmp L0DF3	; bit 5	;@0DCB
L0DCE:	jmp L0E12	; bit 6	;@0DCE
L0DD1:	jmp L0E31	; bit 7	;@0DD1
L0DD4:	mov al, byte ptr D_01B7[di]	;@0DD4
	cmp al, 8	;@0DD8
	je L0DDE	;@0DDA
	jmp L0DC4	;@0DDC
L0DDE:	mov al, 0F0h	; fighter figure	;@0DDE
	mov bx, word ptr D_0006	;@0DE0
	mov byte ptr [bx+si], al	;@0DE4
	mov byte ptr D_0197[di], al	;@0DE6
	mov al, 80h	;@0DEA
	mov byte ptr D_0177[di], al	;@0DEC
	jmp L0BAF	;@0DF0
L0DF3:	mov al, byte ptr D_01B7[di]	;@0DF3
	cmp al, 0	; water?	;@0DF7
	je L0DFD	;@0DF9
	jmp L0DC4	;@0DFB
L0DFD:	mov al, 48h	; frigate figure (pirates?)	;@0DFD
	mov bx, word ptr D_0006	;@0DFF
	mov byte ptr [bx+si], al	;@0E03
	mov byte ptr D_0197[di], al	;@0E05
	mov al, 0A0h	;@0E09
	mov byte ptr D_0177[di], al	;@0E0B
	jmp L0BAF	;@0E0F
L0E12:	mov al, byte ptr D_01B7[di]	;@0E12
	cmp al, 8	;@0E16
	je L0E1C	;@0E18
	jmp L0DC4	;@0E1A
L0E1C:	mov al, 38h	;@0E1C
	mov bx, word ptr D_0006	;@0E1E
	mov byte ptr [bx+si], al	;@0E22
	mov byte ptr D_0197[di], al	;@0E24
	mov al, 0C0h	;@0E28
	mov byte ptr D_0177[di], al	;@0E2A
	jmp L0BAF	;@0E2E
L0E31:	mov al, byte ptr D_01B7[di]	;@0E31
	cmp al, 8	;@0E35
	je L0E3B	;@0E37
	jmp L0DC4	;@0E39
L0E3B:	mov al, 0F8h	; wizard (casts magic missiles)	;@0E3B
	mov bx, word ptr D_0006	;@0E3D
	mov byte ptr [bx+si], al	;@0E41
	mov byte ptr D_0197[di], al	;@0E43
	mov al, 0E0h	;@0E47
	mov byte ptr D_0177[di], al	;@0E49
	jmp L0BAF	;@0E4D
L0E50:	mov al, byte ptr D_01B7[di]	;@0E50
	cmp al, 8	;@0E54
	je L0E5B	;@0E56
	jmp L0DC4	;@0E58
L0E5B:	mov al, 3Ch	;@0E5B
	mov bx, word ptr D_0006	;@0E5D
	mov byte ptr [bx+si], al	;@0E61
	mov byte ptr D_0197[di], al	;@0E63
	mov al, 0FFh	;@0E67
	mov byte ptr D_0177[di], al	;@0E69
	jmp L0BAF	;@0E6D
CODE ENDS
END
