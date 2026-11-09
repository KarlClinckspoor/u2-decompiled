; LOAD.ASM: loading the map, monster, talk and player files.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 2290-2362.
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
L2290:	clc	;@2290
	mov al, byte ptr D_0049	;@2291
	adc al, 30h	;@2294
	mov byte ptr cs:L22BB, al	;@2296
	mov byte ptr cs:L22CD, al	;@229A
	mov al, byte ptr D_004A	;@229E
	adc al, 30h	;@22A1
	mov byte ptr cs:L22BC, al	;@22A3
	mov byte ptr cs:L22CE, al	;@22A7
	mov ah, 27h	;@22AB
	mov cx, 1000h	;@22AD
	mov dx, word ptr D_0472	;@22B0
	call L52CA	;@22B4
	db 4Dh,41h,50h	;@22B7
L22BA label byte
	db 58h	;@22BA
L22BB label byte
	db 46h	;@22BB
L22BC label byte
	db 46h,20h,20h	;@22BC
	mov cx, 100h	;@22BF
	lea dx, D_0137	;@22C2
	call L52CA	;@22C6
	db 4Dh,4Fh,4Eh	;@22C9
L22CC label byte
	db 58h	;@22CC
L22CD label byte
	db 46h	;@22CD
L22CE label byte
	db 46h,20h,20h	;@22CE
	call L4F4D	;@22D1
	ret	;@22D4
L22D5:	clc	;@22D5
	mov al, byte ptr D_0049	;@22D6
	adc al, 30h	;@22D9
	mov byte ptr cs:L22F8, al	;@22DB
	mov al, byte ptr D_004A	;@22DF
	adc al, 30h	;@22E2
	mov byte ptr cs:L22F9, al	;@22E4
	mov ah, 27h	;@22E8
	mov cx, 100h	;@22EA
	mov dx, word ptr D_0476	;@22ED
	call L52CA	;@22F1
	db 54h,4Ch,4Bh	;@22F4
L22F7 label byte
	db 58h	;@22F7
L22F8 label byte
	db 46h	;@22F8
L22F9 label byte
	db 46h,20h,20h	;@22F9
	ret	;@22FC
L22FD:	mov al, byte ptr D_006D	;@22FD
	or al, al	;@2300
	je L2305	;@2302
	ret	;@2304
L2305:	clc	;@2305
	mov al, byte ptr D_0049	;@2306
	adc al, 30h	;@2309
	mov byte ptr cs:L233C, al	;@230B
	mov byte ptr cs:L234E, al	;@230F
	mov al, byte ptr D_004A	;@2313
	adc al, 30h	;@2316
	mov byte ptr cs:L233D, al	;@2318
	mov byte ptr cs:L234F, al	;@231C
	mov al, byte ptr D_0000	;@2320
	mov byte ptr D_005A, al	;@2323
	mov al, byte ptr D_0001	;@2326
	mov byte ptr D_005B, al	;@2329
	mov ah, 28h	;@232C
	mov cx, 1000h	;@232E
	mov dx, word ptr D_0472	;@2331
	call L52CA	;@2335
	db 4Dh,41h,50h,58h	;@2338
L233C label byte
	db 46h	;@233C
L233D label byte
	db 46h,20h,20h	;@233D
	mov cx, 100h	;@2340
	lea dx, D_0137	;@2343
	call L52CA	;@2347
	db 4Dh,4Fh,4Eh,58h	;@234A
L234E label byte
	db 46h	;@234E
L234F label byte
	db 46h,20h,20h	;@234F
	lea dx, D_0036	;@2352
	call L52CA	;@2356
	db 50h,4Ch,41h,59h,45h,52h,20h,20h	;@2359
	ret	;@2361
CODE ENDS
END
