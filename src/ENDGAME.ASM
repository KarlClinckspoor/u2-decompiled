; ENDGAME.ASM: the end of Minax and the end of the game.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 7242-740B.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0000:BYTE, D_0001:BYTE, D_0006:BYTE, D_0012:BYTE, D_0013:BYTE, D_001F:BYTE
	EXTRN D_0020:BYTE, D_0023:BYTE, D_0024:BYTE, D_0031:BYTE, D_0472:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L0711:NEAR, L4FDF:NEAR, L50B3:NEAR, L5217:NEAR, L52CA:NEAR, L5AB1:NEAR
	EXTRN L5CB2:NEAR, L5CD2:NEAR, L5CE4:NEAR, L5ED7:NEAR, L5FA6:NEAR, L6994:BYTE
	EXTRN L6998:BYTE
	PUBLIC L7242, L7276, L7289, L72A0
ASSUME CS:CODE, DS:DATA
L7242:	nop	;@7242
	cmp byte ptr cs:L6998, 0FFh	;@7243
	je L7258	;@7249
	call L7289	;@724B
	mov word ptr cs:L6994, 0E0h	;@724E
	jmp L7275	;@7255
L7258:	call L5217	;@7258
	mov ah, al	;@725B
	and ax, 1F00h	;@725D
	add ax, 100h	;@7260
	mov bx, ax	;@7263
	mov cx, 1	;@7265
	call L7276	;@7268
	call L5CD2	;@726B
	mov word ptr cs:L6994, 18h	;@726E
L7275:	ret	;@7275
L7276:	nop	;@7276
	cmp byte ptr cs:L6998, 0FFh	;@7277
	jne L7288	;@727D
	call L5CB2	;@727F
	mov byte ptr cs:L6998, 0	;@7282
L7288:	ret	;@7288
L7289:	nop	;@7289
	cmp byte ptr cs:L6998, 0	;@728A
	jne L729B	;@7290
	call L5CE4	;@7292
	mov byte ptr cs:L6998, 0FFh	;@7295
L729B:	ret	;@729B
	db 0h,0h,0h,0h	;@729C
L72A0:	nop	;@72A0
	mov byte ptr D_0031, 28h	;@72A1
	call L4FDF	;@72A6
	db 8Dh,8Dh,20h,20h,20h,20h,20h,4Dh,49h,4Eh,41h,58h,20h,49h,53h,20h	;@72A9
	db 44h,45h,41h,44h,21h,21h,8Dh,41h,4Ch,4Ch,20h,48h,45h,52h,20h,57h	;@72B9
	db 4Fh,52h,4Bh,53h,20h,53h,48h,41h,4Ch,4Ch,20h,44h,49h,45h,21h,8Dh	;@72C9
	db 0h	;@72D9
	mov al, 40h	;@72DA
	mov byte ptr D_001F, al	;@72DC
L72DF:	call L5ED7	;@72DF
	mov al, 40h	;@72E2
	mov byte ptr D_0020, al	;@72E4
L72E7:	call L5217	;@72E7
	and al, 3Fh	;@72EA
	mov byte ptr D_0023, al	;@72EC
	call L5217	;@72EF
	and al, 3Fh	;@72F2
	mov byte ptr D_0024, al	;@72F4
	call L50B3	;@72F7
	mov al, 74h	;@72FA
	mov bx, word ptr D_0006	;@72FC
	mov byte ptr [bx+si], al	;@7300
	dec byte ptr D_0020	;@7302
	jne L72E7	;@7306
	call L5AB1	;@7308
	mov bx, 0Eh	;@730B
	call L0711	;@730E
	dec byte ptr D_001F	;@7311
	jne L72DF	;@7315
	call L4FDF	;@7317
	db 8Dh,59h,4Fh,55h,20h,46h,45h,45h,4Ch,20h,41h,20h,53h,54h,52h,41h	;@731A
	db 4Eh,47h,45h,20h,46h,4Fh,52h,43h,45h,21h,0h	;@732A
	call L5FA6	;@7335
	mov ah, 27h	;@7338
	mov cx, 1000h	;@733A
	mov dx, word ptr D_0472	;@733D
	call L52CA	;@7341
	db 4Dh,41h,50h,58h,33h,30h,20h,20h	;@7344
	call L5FA6	;@734C
	call L4FDF	;@734F
	db 8Dh,8Dh,59h,4Fh,55h,20h,48h,41h,56h,45h,20h,53h,41h,56h,45h,44h	;@7352
	db 20h,54h,48h,45h,20h,55h,4Eh,49h,56h,45h,52h,53h,45h,2Ch,8Dh,41h	;@7362
	db 4Eh,44h,20h,43h,4Fh,4Dh,50h,4Ch,45h,54h,45h,44h,20h,55h,4Ch,54h	;@7372
	db 49h,4Dh,41h,20h,5Dh,5Bh,21h,20h,53h,45h,45h,4Bh,8Dh,4Eh,4Fh,57h	;@7382
	db 20h,54h,4Fh,20h,43h,4Fh,4Eh,51h,55h,45h,52h,20h,57h,49h,43h,4Bh	;@7392
	db 45h,44h,20h,45h,58h,4Fh,44h,55h,53h,2Ch,8Dh,0h	;@73A2
	call L4FDF	;@73AE
	db 46h,4Fh,55h,4Eh,44h,20h,49h,4Eh,20h,55h,4Ch,54h,49h,4Dh,41h,20h	;@73B1
	db 5Dh,49h,5Bh,2Dh,44h,20h,5Dh,49h,49h,5Bh,2Dh,50h,21h,0h	;@73C1
	mov al, 0FFh	;@73CF
	mov byte ptr D_0012, al	;@73D1
	mov al, 28h	;@73D4
	mov byte ptr D_0013, al	;@73D6
	mov al, 0	;@73D9
	mov byte ptr D_0000, al	;@73DB
	mov byte ptr D_0001, al	;@73DE
L73E1:	clc	;@73E1
	mov al, byte ptr D_0001	;@73E2
	adc al, 1	;@73E5
	and al, 3Fh	;@73E7
	mov byte ptr D_0001, al	;@73E9
	clc	;@73EC
	rcr al, 1	;@73ED
	jb L7400	;@73EF
	clc	;@73F1
	rcr al, 1	;@73F2
	jb L7400	;@73F4
	mov al, byte ptr D_0000	;@73F6
	adc al, 1	;@73F9
	and al, 3Fh	;@73FB
	mov byte ptr D_0000, al	;@73FD
L7400:	call L5AB1	;@7400
	mov bx, 6	;@7403
	call L0711	;@7406
	jmp L73E1	;@7409
CODE ENDS
END
