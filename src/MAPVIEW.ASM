; MAPVIEW.ASM: drawing the outdoor and town map window.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 5AB1-5C90.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0000:BYTE, D_0001:BYTE, D_0002:BYTE, D_0003:BYTE, D_0004:BYTE, D_0005:BYTE
	EXTRN D_0006:BYTE, D_0007:BYTE, D_0012:BYTE, D_0013:BYTE, D_0014:BYTE, D_0015:BYTE
	EXTRN D_0016:BYTE, D_0017:BYTE, D_0018:BYTE, D_0272:BYTE, D_02CB:BYTE, D_02DE:BYTE
	EXTRN D_02DF:BYTE, D_02E0:BYTE, D_02F3:BYTE, D_0372:BYTE, D_0472:BYTE, D_054E:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA
D_0473 equ byte ptr D_0472+1

CODE SEGMENT BYTE PUBLIC
	EXTRN L4AAD:NEAR, L5AB0:BYTE
	PUBLIC L5AB1
ASSUME CS:CODE, DS:DATA
L5AB1:	cmp byte ptr D_0012, 0FFh	;@5AB1
	jne L5ABB	;@5AB6
	jmp L5B98	;@5AB8
L5ABB:	stc	;@5ABB
	mov al, byte ptr D_0001	;@5ABC
	cmc	;@5ABF
	sbb al, 5	;@5AC0
	cmc	;@5AC2
	mov byte ptr D_0003, al	;@5AC3
	stc	;@5AC6
	mov al, byte ptr D_0000	;@5AC7
	cmc	;@5ACA
	sbb al, 9	;@5ACB
	cmc	;@5ACD
	mov byte ptr D_0002, al	;@5ACE
	mov al, 0	;@5AD1
	mov byte ptr D_0005, al	;@5AD3
	mov byte ptr D_0004, al	;@5AD6
	mov ah, 0	;@5AD9
	mov si, ax	;@5ADB
	mov ah, 0	;@5ADD
	mov di, ax	;@5ADF
L5AE1:	clc	;@5AE1
	mov al, byte ptr D_0004	;@5AE2
	adc al, byte ptr D_0002	;@5AE5
	cmp al, 40h	;@5AE9
	jae L5AF9	;@5AEB
	clc	;@5AED
	mov al, byte ptr D_0005	;@5AEE
	adc al, byte ptr D_0003	;@5AF1
	cmp al, 40h	;@5AF5
	jb L5AFF	;@5AF7
L5AF9:	mov al, byte ptr D_0012	;@5AF9
	jmp L5B33	;@5AFC
L5AFF:	mov byte ptr D_0007, al	;@5AFF
	mov al, 0	;@5B02
	clc	;@5B04
	rcr byte ptr D_0007, 1	;@5B05
	rcr al, 1	;@5B09
	clc	;@5B0B
	rcr byte ptr D_0007, 1	;@5B0C
	rcr al, 1	;@5B10
	adc al, byte ptr D_0004	;@5B12
	adc al, byte ptr D_0002	;@5B16
	mov byte ptr D_0006, al	;@5B1A
	clc	;@5B1D
	mov al, byte ptr D_0007	;@5B1E
	adc al, byte ptr D_0473	;@5B21
	mov byte ptr D_0007, al	;@5B25
	mov bx, word ptr D_0006	;@5B28
	mov al, byte ptr [bx+si]	;@5B2C
	clc	;@5B2E
	rcr al, 1	;@5B2F
	and al, 0FEh	;@5B31
L5B33:	cmp al, byte ptr D_0372[di]	;@5B33
	jne L5B4D	;@5B37
	cmp al, 0	;@5B39
	jne L5B47	;@5B3B
	cmp byte ptr D_054E, 0FFh	;@5B3D
	jne L5B4D	;@5B42
	jmp L5B4B	;@5B44
L5B47:	cmp al, 2Eh	;@5B47
	je L5B4D	;@5B49
L5B4B:	or al, 80h	;@5B4B
L5B4D:	mov byte ptr D_0272[di], al	;@5B4D
	inc di	;@5B51
	inc byte ptr D_0004	;@5B52
	mov al, byte ptr D_0004	;@5B56
	cmp al, 14h	;@5B59
	jne L5AE1	;@5B5B
	mov bx, si	;@5B5D
	mov byte ptr D_0004, bl	;@5B5F
	inc byte ptr D_0005	;@5B63
	mov al, byte ptr D_0005	;@5B67
	cmp al, 0Ah	;@5B6A
	je L5B71	;@5B6C
	jmp L5AE1	;@5B6E
L5B71:	mov al, byte ptr D_02DF	;@5B71
	mov byte ptr D_0014, al	;@5B74
	mov al, byte ptr D_02CB	;@5B77
	mov byte ptr D_0015, al	;@5B7A
	mov al, byte ptr D_02F3	;@5B7D
	mov byte ptr D_0016, al	;@5B80
	mov al, byte ptr D_02DE	;@5B83
	mov byte ptr D_0018, al	;@5B86
	mov al, byte ptr D_02E0	;@5B89
	mov byte ptr D_0017, al	;@5B8C
	mov al, byte ptr D_0013	;@5B8F
	mov byte ptr D_02DF, al	;@5B92
	jmp L5C6D	;@5B95
L5B98:	stc	;@5B98
	mov al, byte ptr D_0001	;@5B99
	cmc	;@5B9C
	sbb al, 5	;@5B9D
	cmc	;@5B9F
	and al, 3Fh	;@5BA0
	mov byte ptr D_0003, al	;@5BA2
	stc	;@5BA5
	mov al, byte ptr D_0000	;@5BA6
	cmc	;@5BA9
	sbb al, 9	;@5BAA
	cmc	;@5BAC
	and al, 3Fh	;@5BAD
	mov byte ptr D_0002, al	;@5BAF
	mov al, 0	;@5BB2
	mov byte ptr D_0005, al	;@5BB4
	mov byte ptr D_0004, al	;@5BB7
	mov ah, 0	;@5BBA
	mov si, ax	;@5BBC
	mov ah, 0	;@5BBE
	mov di, ax	;@5BC0
L5BC2:	clc	;@5BC2
	mov al, byte ptr D_0004	;@5BC3
	adc al, byte ptr D_0002	;@5BC6
	and al, 3Fh	;@5BCA
	mov byte ptr cs:L5AB0, al	;@5BCC
	clc	;@5BD0
	mov al, byte ptr D_0005	;@5BD1
	adc al, byte ptr D_0003	;@5BD4
	and al, 3Fh	;@5BD8
	mov byte ptr D_0007, al	;@5BDA
	mov al, 0	;@5BDD
	clc	;@5BDF
	rcr byte ptr D_0007, 1	;@5BE0
	rcr al, 1	;@5BE4
	clc	;@5BE6
	rcr byte ptr D_0007, 1	;@5BE7
	rcr al, 1	;@5BEB
	adc al, byte ptr cs:L5AB0	;@5BED
	mov byte ptr D_0006, al	;@5BF2
	clc	;@5BF5
	mov al, byte ptr D_0007	;@5BF6
	adc al, byte ptr D_0473	;@5BF9
	mov byte ptr D_0007, al	;@5BFD
	mov bx, word ptr D_0006	;@5C00
	mov al, byte ptr [bx+si]	;@5C04
	clc	;@5C06
	rcr al, 1	;@5C07
	and al, 0FEh	;@5C09
	cmp al, byte ptr D_0372[di]	;@5C0B
	jne L5C25	;@5C0F
	cmp al, 0	;@5C11
	jne L5C1F	;@5C13
	cmp byte ptr D_054E, 0FFh	;@5C15
	jne L5C25	;@5C1A
	jmp L5C23	;@5C1C
L5C1F:	cmp al, 2Eh	;@5C1F
	je L5C25	;@5C21
L5C23:	or al, 80h	;@5C23
L5C25:	mov byte ptr D_0272[di], al	;@5C25
	inc di	;@5C29
	inc byte ptr D_0004	;@5C2A
	mov al, byte ptr D_0004	;@5C2E
	cmp al, 14h	;@5C31
	jne L5BC2	;@5C33
	mov bx, si	;@5C35
	mov byte ptr D_0004, bl	;@5C37
	inc byte ptr D_0005	;@5C3B
	mov al, byte ptr D_0005	;@5C3F
	cmp al, 0Ah	;@5C42
	je L5C49	;@5C44
	jmp L5BC2	;@5C46
L5C49:	mov al, byte ptr D_02DF	;@5C49
	mov byte ptr D_0014, al	;@5C4C
	mov al, byte ptr D_02CB	;@5C4F
	mov byte ptr D_0015, al	;@5C52
	mov al, byte ptr D_02F3	;@5C55
	mov byte ptr D_0016, al	;@5C58
	mov al, byte ptr D_02DE	;@5C5B
	mov byte ptr D_0018, al	;@5C5E
	mov al, byte ptr D_02E0	;@5C61
	mov byte ptr D_0017, al	;@5C64
	mov al, byte ptr D_0013	;@5C67
	mov byte ptr D_02DF, al	;@5C6A
L5C6D:	call L4AAD	;@5C6D
	mov bh, 0	;@5C70
	mov bl, 0	;@5C72
	mov di, bx	;@5C74
L5C76:	mov al, byte ptr D_0272[di]	;@5C76
	and al, 7Fh	;@5C7A
	mov byte ptr D_0372[di], al	;@5C7C
	inc di	;@5C80
	mov bx, di	;@5C81
	cmp bl, 0F0h	;@5C83
	jne L5C76	;@5C86
	ret	;@5C88
	db 0h,0h,0h,0h,0h,0h,0h	;@5C89
CODE ENDS
END
