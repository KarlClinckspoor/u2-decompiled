; CMDMZ.ASM: commands M-Z (magic, negate, offer, pass, quit, ready, steal, ...); status.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 3B92-48CD.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0000:BYTE, D_0001:BYTE, D_0006:BYTE, D_0013:BYTE, D_0014:BYTE, D_0019:BYTE
	EXTRN D_001A:BYTE, D_001F:BYTE, D_0020:BYTE, D_0023:BYTE, D_0024:BYTE, D_0027:BYTE
	EXTRN D_0028:BYTE, D_002E:BYTE, D_0031:BYTE, D_0046:BYTE, D_0047:BYTE, D_0048:BYTE
	EXTRN D_0049:BYTE, D_004A:BYTE, D_004B:BYTE, D_004C:BYTE, D_004D:BYTE, D_004E:BYTE
	EXTRN D_004F:BYTE, D_0050:BYTE, D_0051:BYTE, D_0053:BYTE, D_0056:BYTE, D_0061:BYTE
	EXTRN D_0062:BYTE, D_0063:BYTE, D_0064:BYTE, D_0065:BYTE, D_0066:BYTE, D_006C:BYTE
	EXTRN D_006D:BYTE, D_0076:BYTE, D_007F:BYTE, D_0096:BYTE, D_00B6:BYTE, D_00D6:BYTE
	EXTRN D_00DB:BYTE, D_00E3:BYTE, D_0197:BYTE, D_01D7:BYTE, D_026A:BYTE, D_0272:BYTE
	EXTRN D_0372:BYTE, D_054F:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L0711:NEAR, L0A30:NEAR, L0A33:NEAR, L113A:NEAR, L154E:NEAR, L1590:NEAR
	EXTRN L2028:NEAR, L2052:NEAR, L22FD:NEAR, L2362:NEAR, L23E6:NEAR, L29D2:NEAR
	EXTRN L4A1C:NEAR, L4A3E:NEAR, L4F4D:NEAR, L4FDF:NEAR, L505F:NEAR, L507A:NEAR
	EXTRN L508C:NEAR, L50B3:NEAR, L50F9:NEAR, L51A5:NEAR, L51EB:NEAR, L51FD:NEAR
	EXTRN L5217:NEAR, L53B5:NEAR, L53F4:NEAR
	PUBLIC L3B92, L3BCE, L3C2E, L3DBC, L3DC7, L3E50
	PUBLIC L3F25, L4050, L42F1, L437E, L43F3, L44D4
	PUBLIC L4542, L4568
ASSUME CS:CODE, DS:DATA
L3B92:	call L4FDF	;@3B92
	db 4Dh,41h,47h,49h,43h,20h,53h,50h,45h,4Ch,4Ch,20h,52h,45h,41h,44h	;@3B95
	db 59h,20h,23h,0h	;@3BA5
	call L2028	;@3BA9
	mov byte ptr D_0063, al	;@3BAC
	call L4FDF	;@3BAF
	db 53h,50h,45h,4Ch,4Ch,20h,52h,45h,41h,44h,59h,20h,3Dh,3Eh,20h,0h	;@3BB2
	mov al, byte ptr D_0063	;@3BC2
	clc	;@3BC5
	adc al, 24h	;@3BC6
	call L508C	;@3BC8
	jmp L0A33	;@3BCB
L3BCE:	call L4FDF	;@3BCE
	db 4Eh,45h,47h,41h,54h,45h,20h,54h,49h,4Dh,45h,0h	;@3BD1
	mov al, byte ptr D_00E3	;@3BDD
	or al, al	;@3BE0
	jne L3C04	;@3BE2
	call L4FDF	;@3BE4
	db 20h,48h,4Fh,57h,3Fh,8Dh,59h,4Fh,55h,27h,52h,45h,20h,4Eh,4Fh,54h	;@3BE7
	db 20h,45h,49h,4Eh,53h,54h,45h,49h,4Eh,0h	;@3BF7
	jmp L0A33	;@3C01
L3C04:	stc	;@3C04
	mov al, byte ptr D_00E3	;@3C05
	cmc	;@3C08
	sbb al, 1	;@3C09
	das	;@3C0B
	cmc	;@3C0C
	mov byte ptr D_00E3, al	;@3C0D
	call L4FDF	;@3C10
	db 8Dh,59h,4Fh,55h,20h,52h,55h,42h,20h,41h,20h,43h,4Fh,49h,4Eh,2Eh	;@3C13
	db 2Eh,2Eh,0h	;@3C23
	mov al, 14h	;@3C26
	mov byte ptr D_026A, al	;@3C28
	jmp L0A33	;@3C2B
L3C2E:	call L4FDF	;@3C2E
	db 4Fh,46h,46h,45h,52h,20h,47h,4Fh,4Ch,44h,20h,44h,49h,52h,45h,43h	;@3C31
	db 54h,2Dh,0h	;@3C41
	call L2362	;@3C44
	call L23E6	;@3C47
	mov bx, di	;@3C4A
	mov byte ptr D_001F, bl	;@3C4C
	mov al, 8Dh	;@3C50
	call L53F4	;@3C52
	mov bx, di	;@3C55
	cmp bl, 0	;@3C57
	jne L3C71	;@3C5A
	call L4FDF	;@3C5C
	db 4Fh,46h,46h,45h,52h,20h,54h,4Fh,20h,57h,48h,4Fh,4Dh,3Fh,0h	;@3C5F
	jmp L0A33	;@3C6E
L3C71:	call L4FDF	;@3C71
	db 48h,4Fh,57h,20h,4Dh,55h,43h,48h,20h,28h,2Ah,31h,30h,30h,29h,20h	;@3C74
	db 3Fh,20h,0h	;@3C84
	call L2028	;@3C87
	mov byte ptr D_0027, al	;@3C8A
	mov al, 0	;@3C8D
	mov byte ptr D_0028, al	;@3C8F
	call L2052	;@3C92
	mov bh, 0	;@3C95
	mov bl, byte ptr D_001F	;@3C97
	mov di, bx	;@3C9B
	mov al, byte ptr D_01D7[di]	;@3C9D
	or al, al	;@3CA1
	jns L3CB6	;@3CA3
	mov al, byte ptr D_004A	;@3CA5
	cmp al, 2	;@3CA8
	jne L3CB6	;@3CAA
	mov al, byte ptr D_0049	;@3CAC
	cmp al, 3	;@3CAF
	jne L3CB6	;@3CB1
	jmp L3CD2	;@3CB3
L3CB6:	nop	;@3CB6
	call L4FDF	;@3CB7
	db 54h,48h,41h,4Eh,4Bh,20h,59h,4Fh,55h,20h,56h,45h,52h,59h,20h,4Dh	;@3CBA
	db 55h,43h,48h,21h,0h	;@3CCA
	jmp L0A33	;@3CCF
L3CD2:	mov bh, 0	;@3CD2
	mov bl, byte ptr D_001F	;@3CD4
	mov di, bx	;@3CD8
	mov al, byte ptr D_01D7[di]	;@3CDA
	cmp al, 81h	;@3CDE
	je L3CED	;@3CE0
	cmp al, 82h	;@3CE2
	je L3D10	;@3CE4
	cmp al, 83h	;@3CE6
	je L3D52	;@3CE8
	jmp L3D7E	;@3CEA
L3CED:	mov al, byte ptr D_0027	;@3CED
	cmp al, 5	;@3CF0
	jb L3CB6	;@3CF2
	call L4FDF	;@3CF4
	db 45h,4Eh,49h,4Ch,4Eh,4Fh,20h,49h,53h,20h,59h,4Fh,55h,52h,53h,21h	;@3CF7
	db 0h	;@3D07
	mov al, 1	;@3D08
	mov byte ptr D_007F, al	;@3D0A
	jmp L0A33	;@3D0D
L3D10:	mov al, byte ptr D_0027	;@3D10
	cmp al, 5	;@3D13
	jb L3CB6	;@3D15
	mov al, byte ptr D_006C	;@3D17
	or al, al	;@3D1A
	jne L3D33	;@3D1C
	call L4FDF	;@3D1E
	db 45h,41h,52h,4Eh,20h,54h,48h,45h,20h,52h,49h,4Eh,47h,21h,0h	;@3D21
	jmp L0A33	;@3D30
L3D33:	nop	;@3D33
	call L4FDF	;@3D34
	db 54h,48h,45h,20h,52h,49h,4Eh,47h,20h,49h,53h,20h,59h,4Fh,55h,52h	;@3D37
	db 53h,21h,0h	;@3D47
	mov al, 1	;@3D4A
	mov byte ptr D_00D6, al	;@3D4C
	jmp L0A33	;@3D4F
L3D52:	call L5217	;@3D52
	and al, 7	;@3D55
	clc	;@3D57
	mov ah, 0	;@3D58
	mov di, ax	;@3D5A
	inc di	;@3D5C
	mov al, byte ptr D_0076[di]	;@3D5D
	adc al, 1	;@3D61
	daa	;@3D63
	mov byte ptr D_0076[di], al	;@3D64
	call L4FDF	;@3D68
	db 48h,45h,52h,45h,20h,54h,41h,4Bh,45h,20h,54h,48h,49h,53h,21h,0h	;@3D6B
	jmp L0A33	;@3D7B
L3D7E:	call L5217	;@3D7E
	and al, 7	;@3D81
	cmp al, 6	;@3D83
	jb L3D8A	;@3D85
	jmp L3CB6	;@3D87
L3D8A:	nop	;@3D8A
	mov ah, 0	;@3D8B
	mov di, ax	;@3D8D
	clc	;@3D8F
	mov al, byte ptr D_004B[di]	;@3D90
	adc al, byte ptr D_0027	;@3D94
	daa	;@3D98
	adc al, byte ptr D_0027	;@3D99
	daa	;@3D9D
	adc al, byte ptr D_0027	;@3D9E
	daa	;@3DA2
	adc al, byte ptr D_0027	;@3DA3
	daa	;@3DA7
	mov byte ptr D_004B[di], al	;@3DA8
	call L4FDF	;@3DAC
	db 41h,4Ch,41h,4Bh,41h,5Ah,41h,4Dh,21h,0h	;@3DAF
	jmp L0A33	;@3DB9
L3DBC:	call L4FDF	;@3DBC
	db 50h,41h,53h,53h,0h	;@3DBF
	jmp L0A33	;@3DC4
L3DC7:	call L4FDF	;@3DC7
	db 51h,55h,49h,54h,20h,4Fh,52h,20h,53h,41h,56h,45h,20h,47h,41h,4Dh	;@3DCA
	db 45h,2Eh,0h	;@3DDA
	mov al, byte ptr D_004A	;@3DDD
	or al, al	;@3DE0
	je L3DFA	;@3DE2
	call L4FDF	;@3DE4
	db 8Dh,4Fh,4Eh,4Ch,59h,20h,4Fh,55h,54h,44h,4Fh,4Fh,52h,53h,21h,0h	;@3DE7
	jmp L0A30	;@3DF7
L3DFA:	mov al, byte ptr D_006D	;@3DFA
	or al, al	;@3DFD
	je L3E17	;@3DFF
	call L4FDF	;@3E01
	db 8Dh,4Fh,4Eh,4Ch,59h,20h,4Fh,4Eh,20h,45h,41h,52h,54h,48h,21h,0h	;@3E04
	jmp L0A30	;@3E14
L3E17:	mov al, byte ptr D_0013	;@3E17
	cmp al, 78h	;@3E1A
	jae L3E33	;@3E1C
	call L4FDF	;@3E1E
	db 8Dh,4Fh,4Eh,4Ch,59h,20h,4Fh,4Eh,20h,46h,4Fh,4Fh,54h,21h,0h	;@3E21
	jmp L0A30	;@3E30
L3E33:	call L4FDF	;@3E33
	db 8Dh,4Fh,4Eh,45h,20h,4Dh,4Fh,4Dh,45h,4Eh,54h,20h,50h,4Ch,45h,41h	;@3E36
	db 53h,45h,21h,0h	;@3E46
	call L22FD	;@3E4A
	jmp L0A33	;@3E4D
L3E50:	call L4FDF	;@3E50
	db 52h,45h,41h,44h,59h,20h,57h,45h,41h,50h,4Fh,4Eh,3Ah,0Dh,31h,2Dh	;@3E53
	db 44h,41h,2Ch,20h,32h,2Dh,4Dh,41h,2Ch,20h,33h,2Dh,41h,58h,2Ch,20h	;@3E63
	db 34h,2Dh,42h,4Fh,2Ch,0Dh,35h,2Dh,53h,57h,2Ch,20h,36h,2Dh,47h,52h	;@3E73
	db 2Ch,20h,37h,2Dh,4Ch,49h,2Ch,20h,38h,2Dh,50h,48h,2Eh,0Dh,39h,2Dh	;@3E83
	db 51h,55h,2Ch,20h,57h,48h,49h,43h,48h,3Fh,20h,0h	;@3E93
	call L2028	;@3E9F
	mov byte ptr D_001F, al	;@3EA2
	clc	;@3EA5
	adc al, 13h	;@3EA6
	call L508C	;@3EA8
	mov bh, 0	;@3EAB
	mov bl, byte ptr D_001F	;@3EAD
	mov di, bx	;@3EB1
	mov al, byte ptr D_0076[di]	;@3EB3
	or al, al	;@3EB7
	jne L3ED4	;@3EB9
	mov al, byte ptr D_001F	;@3EBB
	or al, al	;@3EBE
	je L3ED4	;@3EC0
	call L4FDF	;@3EC2
	db 20h,4Eh,4Fh,54h,20h,4Fh,57h,4Eh,45h,44h,21h,0h	;@3EC5
	jmp L0A30	;@3ED1
L3ED4:	mov al, byte ptr D_001F	;@3ED4
	add al, al	;@3ED7
	add al, al	;@3ED9
	add al, al	;@3EDB
	cmp al, byte ptr D_004C	;@3EDD
	jb L3F11	;@3EE1
	call L4FDF	;@3EE3
	db 20h,3Ch,2Dh,54h,48h,4Fh,55h,20h,41h,52h,54h,20h,4Eh,4Fh,54h,20h	;@3EE6
	db 8Dh,41h,47h,49h,4Ch,45h,20h,45h,4Eh,4Fh,55h,47h,48h,20h,54h,4Fh	;@3EF6
	db 20h,57h,49h,45h,4Ch,44h,21h,0h	;@3F06
	jmp L0A33	;@3F0E
L3F11:	call L4FDF	;@3F11
	db 20h,52h,45h,41h,44h,59h,2Eh,0h	;@3F14
	mov al, byte ptr D_001F	;@3F1C
	mov byte ptr D_0061, al	;@3F1F
	jmp L0A33	;@3F22
L3F25:	call L4FDF	;@3F25
	db 53h,54h,45h,41h,4Ch,20h,44h,49h,52h,45h,43h,54h,2Dh,0h	;@3F28
	call L2362	;@3F36
	clc	;@3F39
	mov al, byte ptr D_0000	;@3F3A
	adc al, byte ptr D_0019	;@3F3D
	mov byte ptr D_0023, al	;@3F41
	clc	;@3F44
	mov al, byte ptr D_0001	;@3F45
	adc al, byte ptr D_001A	;@3F48
	mov byte ptr D_0024, al	;@3F4C
	mov al, 8Dh	;@3F4F
	call L53F4	;@3F51
	call L50B3	;@3F54
	js L3F5D	;@3F57
	cmp al, 7Ch	;@3F59
	jne L3F7E	;@3F5B
L3F5D:	nop	;@3F5D
	clc	;@3F5E
	mov al, byte ptr D_0023	;@3F5F
	adc al, byte ptr D_0019	;@3F62
	mov byte ptr D_0023, al	;@3F66
	clc	;@3F69
	mov al, byte ptr D_0024	;@3F6A
	adc al, byte ptr D_001A	;@3F6D
	mov byte ptr D_0024, al	;@3F71
	call L50B3	;@3F74
	cmp al, 68h	;@3F77
	jne L3F7E	;@3F79
	jmp L3F98	;@3F7B
L3F7E:	call L4FDF	;@3F7E
	db 4Eh,4Fh,20h,4Ch,55h,43h,4Bh,21h,0h	;@3F81
	call L5217	;@3F8A
	and al, 7	;@3F8D
	jne L3F94	;@3F8F
	call L113A	;@3F91
L3F94:	nop	;@3F94
	jmp L0A33	;@3F95
L3F98:	nop	;@3F98
	mov al, byte ptr D_0047	;@3F99
	cmp al, 3	;@3F9C
	je L3FA5	;@3F9E
	call L5217	;@3FA0
	js L3F7E	;@3FA3
L3FA5:	nop	;@3FA5
	call L5217	;@3FA6
	js L3F7E	;@3FA9
	mov al, byte ptr D_01D7	;@3FAB
	cmp al, 1	;@3FAE
	je L3F7E	;@3FB0
	mov al, byte ptr D_004A	;@3FB2
	cmp al, 1	;@3FB5
	je L3FCE	;@3FB7
	cmp al, 2	;@3FB9
	jne L3F7E	;@3FBB
	mov al, byte ptr D_0001	;@3FBD
	cmp al, 20h	;@3FC0
	jae L3F7E	;@3FC2
	mov al, byte ptr D_0000	;@3FC4
	cmp al, 20h	;@3FC7
	jae L3FF9	;@3FC9
	jmp L4024	;@3FCB
L3FCE:	mov al, byte ptr D_0001	;@3FCE
	cmp al, 20h	;@3FD1
	jae L3F7E	;@3FD3
	mov al, byte ptr D_0000	;@3FD5
	cmp al, 20h	;@3FD8
	jb L3F7E	;@3FDA
	nop	;@3FDC
	call L4FDF	;@3FDD
	db 53h,54h,45h,41h,4Ch,20h,46h,4Fh,4Fh,44h,21h,0h	;@3FE0
	clc	;@3FEC
	mov al, byte ptr D_0053	;@3FED
	adc al, 1	;@3FF0
	daa	;@3FF2
	mov byte ptr D_0053, al	;@3FF3
	jmp L0A33	;@3FF6
L3FF9:	nop	;@3FF9
	call L4FDF	;@3FFA
	db 53h,54h,45h,41h,4Ch,20h,41h,52h,4Dh,4Fh,55h,52h,21h,0h	;@3FFD
	call L5217	;@400B
	and al, 3	;@400E
	mov ah, 0	;@4010
	mov di, ax	;@4012
	inc di	;@4014
	clc	;@4015
	mov al, byte ptr D_0096[di]	;@4016
	adc al, 1	;@401A
	daa	;@401C
	mov byte ptr D_0096[di], al	;@401D
	jmp L0A33	;@4021
L4024:	nop	;@4024
	call L4FDF	;@4025
	db 53h,54h,45h,41h,4Ch,20h,57h,45h,41h,50h,4Fh,4Eh,53h,21h,0h	;@4028
	call L5217	;@4037
	and al, 7	;@403A
	mov ah, 0	;@403C
	mov di, ax	;@403E
	inc di	;@4040
	clc	;@4041
	mov al, byte ptr D_0076[di]	;@4042
	adc al, 1	;@4046
	daa	;@4048
	mov byte ptr D_0076[di], al	;@4049
	jmp L0A33	;@404D
L4050:	call L4FDF	;@4050
	db 54h,52h,41h,4Eh,53h,41h,43h,54h,2Dh,0h	;@4053
	call L2362	;@405D
	call L23E6	;@4060
	mov bx, di	;@4063
	mov byte ptr D_0020, bl	;@4065
	mov al, 8Dh	;@4069
	call L53F4	;@406B
	mov al, byte ptr D_004A	;@406E
	or al, al	;@4071
	je L40A6	;@4073
	mov bx, di	;@4075
	cmp bl, 0	;@4077
	jne L40C0	;@407A
	call L50B3	;@407C
	js L4085	;@407F
	cmp al, 7Ch	;@4081
	jne L40A6	;@4083
L4085:	nop	;@4085
	clc	;@4086
	mov al, byte ptr D_0023	;@4087
	adc al, byte ptr D_0019	;@408A
	mov byte ptr D_0023, al	;@408E
	clc	;@4091
	mov al, byte ptr D_0024	;@4092
	adc al, byte ptr D_001A	;@4095
	mov byte ptr D_0024, al	;@4099
	call L50B3	;@409C
	cmp al, 68h	;@409F
	jne L40A6	;@40A1
	jmp L1590	;@40A3
L40A6:	call L4FDF	;@40A6
	db 46h,55h,4Eh,4Eh,59h,2Ch,20h,4Eh,4Fh,20h,52h,45h,53h,50h,4Fh,4Eh	;@40A9
	db 53h,45h,21h,0h	;@40B9
	jmp L0A33	;@40BD
L40C0:	mov al, byte ptr D_01D7[di]	;@40C0
	cmp al, 80h	;@40C4
	jb L40CB	;@40C6
	jmp L4209	;@40C8
L40CB:	nop	;@40CB
	mov al, byte ptr D_0197[di]	;@40CC
	cmp al, 6Ch	;@40D0
	jne L40D7	;@40D2
	jmp L4249	;@40D4
L40D7:	nop	;@40D7
	mov al, byte ptr D_0197[di]	;@40D8
	cmp al, 60h	;@40DC
	jne L4104	;@40DE
	call L4FDF	;@40E0
	db 41h,20h,47h,55h,41h,52h,44h,20h,53h,41h,59h,53h,3Ah,0Dh,50h,41h	;@40E3
	db 59h,20h,59h,4Fh,55h,52h,20h,54h,41h,58h,45h,53h,21h,0h	;@40F3
	jmp L0A33	;@4101
L4104:	cmp al, 64h	;@4104
	jne L4128	;@4106
	call L4FDF	;@4108
	db 41h,20h,4Ah,45h,53h,54h,45h,52h,20h,53h,49h,4Eh,47h,53h,3Ah,0Dh	;@410B
	db 48h,4Fh,20h,48h,4Fh,20h,48h,4Fh,21h,0h	;@411B
	jmp L0A33	;@4125
L4128:	cmp al, 68h	;@4128
	jne L415B	;@412A
	call L4FDF	;@412C
	db 41h,20h,4Dh,45h,52h,43h,48h,41h,4Eh,54h,20h,53h,41h,59h,53h,3Ah	;@412F
	db 0Dh,57h,49h,4Ch,4Ch,20h,59h,4Fh,55h,20h,42h,55h,59h,20h,4Dh,59h	;@413F
	db 20h,41h,50h,50h,4Ch,45h,53h,3Fh,0h	;@414F
	jmp L0A33	;@4158
L415B:	cmp al, 0F0h	;@415B
	jne L4184	;@415D
	call L4FDF	;@415F
	db 41h,20h,46h,49h,47h,48h,54h,45h,52h,20h,53h,41h,59h,53h,3Ah,0Dh	;@4162
	db 55h,47h,48h,2Ch,20h,4Dh,45h,20h,54h,4Fh,55h,47h,48h,21h,0h	;@4172
	jmp L0A33	;@4181
L4184:	cmp al, 0F4h	;@4184
	jne L41A6	;@4186
	call L4FDF	;@4188
	db 41h,20h,43h,4Ch,45h,52h,49h,43h,20h,53h,41h,59h,53h,3Ah,0Dh,42h	;@418B
	db 45h,4Ch,49h,45h,56h,45h,21h,0h	;@419B
	jmp L0A33	;@41A3
L41A6:	cmp al, 0F8h	;@41A6
	jne L41D5	;@41A8
	call L4FDF	;@41AA
	db 41h,20h,57h,49h,5Ah,41h,52h,44h,20h,53h,41h,59h,53h,3Ah,0Dh,48h	;@41AD
	db 45h,58h,2Dh,45h,2Dh,50h,4Fh,4Fh,2Dh,48h,45h,58h,2Dh,4Fh,4Eh,2Dh	;@41BD
	db 59h,4Fh,55h,21h,0h	;@41CD
	jmp L0A33	;@41D2
L41D5:	cmp al, 0FCh	;@41D5
	jne L4206	;@41D7
	call L4FDF	;@41D9
	db 41h,20h,54h,48h,49h,45h,46h,20h,53h,41h,59h,53h,3Ah,0Dh,50h,53h	;@41DC
	db 53h,54h,2Ch,20h,57h,41h,4Eh,4Eh,41h,20h,42h,55h,59h,20h,41h,20h	;@41EC
	db 57h,41h,54h,43h,48h,3Fh,0h	;@41FC
	jmp L0A33	;@4203
L4206:	jmp L40A6	;@4206
L4209:	stc	;@4209
	cmc	;@420A
	sbb al, 80h	;@420B
	cmc	;@420D
	call L154E	;@420E
	mov di, 3	;@4211
L4214:	mov si, 0FFFFh	;@4214
L4217:	dec si	;@4217
	jne L4217	;@4218
	mov bx, 4	;@421A
	call L0711	;@421D
	dec di	;@4220
	jne L4214	;@4221
	mov bh, 0	;@4223
	mov bl, byte ptr D_0020	;@4225
	mov di, bx	;@4229
	mov al, byte ptr D_006D	;@422B
	cmp al, 9	;@422E
	jne L4246	;@4230
	mov al, byte ptr D_004A	;@4232
	cmp al, 3	;@4235
	jne L4246	;@4237
	mov al, byte ptr D_01D7[di]	;@4239
	cmp al, 81h	;@423D
	jne L4246	;@423F
	mov al, 1	;@4241
	mov byte ptr D_006C, al	;@4243
L4246:	jmp L0A33	;@4246
L4249:	nop	;@4249
	call L4FDF	;@424A
	db 57h,45h,4Ch,43h,4Fh,4Dh,45h,20h,4Dh,59h,20h,43h,48h,49h,4Ch,44h	;@424D
	db 20h,0h	;@425D
	call L507A	;@425F
	call L4FDF	;@4262
	db 8Dh,46h,49h,52h,53h,54h,20h,4Dh,59h,20h,35h,30h,20h,47h,2Eh,50h	;@4265
	db 2Eh,20h,54h,52h,49h,42h,55h,54h,45h,21h,8Dh,0h	;@4275
	mov al, 50h	;@4281
	mov byte ptr D_0028, al	;@4283
	mov al, 0	;@4286
	mov byte ptr D_0027, al	;@4288
	call L2052	;@428B
	call L4FDF	;@428E
	db 41h,4Eh,44h,20h,46h,4Fh,52h,20h,49h,54h,20h,49h,20h,52h,41h,49h	;@4291
	db 53h,45h,20h,54h,48h,45h,45h,20h,0h	;@42A1
	mov al, byte ptr D_0051	;@42AA
	mov bh, 0	;@42AD
	mov bl, 3	;@42AF
	mov di, bx	;@42B1
	cmp al, 50h	;@42B3
	jb L42D1	;@42B5
	mov bh, 0	;@42B7
	mov bl, 2	;@42B9
	mov di, bx	;@42BB
	cmp al, 75h	;@42BD
	jb L42D1	;@42BF
	mov bh, 0	;@42C1
	mov bl, 1	;@42C3
	mov di, bx	;@42C5
	cmp al, 99h	;@42C7
	jb L42D1	;@42C9
	mov bh, 0	;@42CB
	mov bl, 0	;@42CD
	mov di, bx	;@42CF
L42D1:	mov bx, di	;@42D1
	mov byte ptr D_001F, bl	;@42D3
	mov ax, di	;@42D7
	mov bh, 0	;@42D9
	mov bl, 0	;@42DB
	mov di, bx	;@42DD
	call L51A5	;@42DF
	clc	;@42E2
	mov al, byte ptr D_0051	;@42E3
	adc al, byte ptr D_001F	;@42E6
	daa	;@42EA
	mov byte ptr D_0051, al	;@42EB
	jmp L0A33	;@42EE
L42F1:	call L4FDF	;@42F1
	db 55h,4Eh,4Ch,4Fh,43h,4Bh,20h,44h,49h,52h,45h,43h,54h,49h,4Fh,4Eh	;@42F4
	db 2Dh,0h	;@4304
	call L2362	;@4306
	mov al, byte ptr D_0019	;@4309
	or al, al	;@430C
	jne L4326	;@430E
L4310:	call L4FDF	;@4310
	db 8Dh,4Eh,4Fh,20h,44h,4Fh,4Fh,52h,20h,54h,48h,45h,52h,45h,21h,0h	;@4313
	jmp L0A30	;@4323
L4326:	mov al, byte ptr D_0001	;@4326
	mov byte ptr D_0024, al	;@4329
	mov al, byte ptr D_0000	;@432C
	clc	;@432F
	adc al, byte ptr D_0019	;@4330
	mov byte ptr D_0023, al	;@4334
	call L50B3	;@4337
	cmp al, 0A0h	;@433A
	jne L4310	;@433C
	mov al, byte ptr D_0065	;@433E
	or al, al	;@4341
	jne L435E	;@4343
	call L4FDF	;@4345
	db 8Dh,4Eh,4Fh,20h,4Bh,45h,59h,53h,20h,54h,48h,41h,54h,20h,46h,49h	;@4348
	db 54h,21h,0h	;@4358
	jmp L0A30	;@435B
L435E:	stc	;@435E
	mov al, byte ptr D_0065	;@435F
	cmc	;@4362
	sbb al, 1	;@4363
	das	;@4365
	cmc	;@4366
	mov byte ptr D_0065, al	;@4367
	mov al, byte ptr D_0014	;@436A
	add al, al	;@436D
	mov bh, 0	;@436F
	mov bl, 0	;@4371
	mov di, bx	;@4373
	mov bx, word ptr D_0006[di]	;@4375
	mov byte ptr [bx], al	;@4379
	jmp L0A33	;@437B
L437E:	mov al, byte ptr D_00DB	;@437E
	or al, al	;@4381
	jne L4396	;@4383
L4385:	call L4FDF	;@4385
	db 56h,49h,45h,57h,20h,57h,48h,41h,54h,3Fh,0h	;@4388
	jmp L0A33	;@4393
L4396:	mov al, byte ptr D_004A	;@4396
	cmp al, 4	;@4399
	jae L4385	;@439B
	call L4FDF	;@439D
	db 56h,49h,45h,57h,8Dh,57h,49h,54h,48h,20h,4Dh,41h,47h,49h,43h,41h	;@43A0
	db 4Ch,20h,48h,45h,4Ch,4Dh,21h,0h	;@43B0
	stc	;@43B8
	mov al, byte ptr D_00DB	;@43B9
	cmc	;@43BC
	sbb al, 1	;@43BD
	das	;@43BF
	cmc	;@43C0
	mov byte ptr D_00DB, al	;@43C1
	mov al, 20h	;@43C4
	mov byte ptr D_0023, al	;@43C6
	mov byte ptr D_0024, al	;@43C9
	call L29D2	;@43CC
L43CF:	call L4F4D	;@43CF
	cmp ah, 0FFh	;@43D2
	jne L43CF	;@43D5
	mov bh, 0	;@43D7
	mov bl, 0FFh	;@43D9
	mov di, bx	;@43DB
	mov al, 0FFh	;@43DD
L43DF:	mov byte ptr D_0272[di], al	;@43DF
	mov byte ptr D_0372[di], al	;@43E3
	dec di	;@43E7
	jne L43DF	;@43E8
	mov byte ptr D_0272, al	;@43EA
	mov byte ptr D_0372, al	;@43ED
	jmp L0A33	;@43F0
L43F3:	call L4FDF	;@43F3
	db 57h,45h,41h,52h,20h,41h,52h,4Dh,4Fh,55h,52h,3Ah,0Dh,31h,2Dh,43h	;@43F6
	db 4Ch,4Fh,54h,48h,2Ch,20h,32h,2Dh,4Ch,45h,41h,54h,48h,45h,52h,2Ch	;@4406
	db 20h,33h,2Dh,43h,48h,41h,49h,4Eh,2Ch,0Dh,34h,2Dh,50h,4Ch,41h,54h	;@4416
	db 45h,2Ch,20h,35h,2Dh,52h,45h,46h,4Ch,45h,43h,54h,2Ch,20h,36h,2Dh	;@4426
	db 50h,4Fh,57h,45h,52h,2Ch,0Dh,57h,48h,49h,43h,48h,3Fh,20h,0h	;@4436
	call L2028	;@4445
	mov byte ptr D_001F, al	;@4448
	cmp al, 7	;@444B
	jb L4454	;@444D
	mov al, 0	;@444F
	mov byte ptr D_001F, al	;@4451
L4454:	nop	;@4454
	clc	;@4455
	adc al, 1Dh	;@4456
	call L508C	;@4458
	mov bh, 0	;@445B
	mov bl, byte ptr D_001F	;@445D
	mov di, bx	;@4461
	mov al, byte ptr D_0096[di]	;@4463
	or al, al	;@4467
	jne L4484	;@4469
	mov al, byte ptr D_001F	;@446B
	or al, al	;@446E
	je L4484	;@4470
	call L4FDF	;@4472
	db 20h,4Eh,4Fh,54h,20h,4Fh,57h,4Eh,45h,44h,21h,0h	;@4475
	jmp L0A33	;@4481
L4484:	mov al, byte ptr D_001F	;@4484
	add al, al	;@4487
	add al, al	;@4489
	add al, al	;@448B
	cmp al, byte ptr D_004B	;@448D
	jb L44C0	;@4491
	call L4FDF	;@4493
	db 20h,3Ch,2Dh,54h,48h,4Fh,55h,20h,41h,52h,54h,20h,4Eh,4Fh,54h,0Dh	;@4496
	db 53h,54h,52h,4Fh,4Eh,47h,20h,45h,4Eh,4Fh,55h,47h,48h,20h,54h,4Fh	;@44A6
	db 20h,57h,45h,41h,52h,21h,0h	;@44B6
	jmp L0A33	;@44BD
L44C0:	call L4FDF	;@44C0
	db 20h,52h,45h,41h,44h,59h,2Eh,0h	;@44C3
	mov al, byte ptr D_001F	;@44CB
	mov byte ptr D_0062, al	;@44CE
	jmp L0A33	;@44D1
L44D4:	call L4FDF	;@44D4
	db 58h,2Dh,49h,54h,0h	;@44D7
	mov al, byte ptr D_0013	;@44DC
	cmp al, 78h	;@44DF
	jb L44F0	;@44E1
	call L4FDF	;@44E3
	db 20h,57h,48h,41h,54h,3Fh,0h	;@44E6
	jmp L0A30	;@44ED
L44F0:	nop	;@44F0
	mov al, byte ptr D_0000	;@44F1
	mov byte ptr D_0023, al	;@44F4
	mov al, byte ptr D_0001	;@44F7
	mov byte ptr D_0024, al	;@44FA
	call L50B3	;@44FD
	mov al, byte ptr D_0014	;@4500
	cmp al, 4	;@4503
	je L4523	;@4505
	cmp al, 0	;@4507
	jne L4512	;@4509
	mov al, byte ptr D_0013	;@450B
	cmp al, 24h	;@450E
	je L4523	;@4510
L4512:	call L4FDF	;@4512
	db 2Dh,4Eh,4Fh,54h,20h,48h,45h,52h,45h,21h,0h	;@4515
	jmp L0A30	;@4520
L4523:	mov al, byte ptr D_0013	;@4523
	add al, al	;@4526
	mov bh, 0	;@4528
	mov bl, 0	;@452A
	mov si, bx	;@452C
	mov bx, word ptr D_0006	;@452E
	mov byte ptr [bx+si], al	;@4532
	mov al, byte ptr D_0047	;@4534
	add al, al	;@4537
	clc	;@4539
	adc al, 78h	;@453A
	mov byte ptr D_0013, al	;@453C
	jmp L0A33	;@453F
L4542:	call L4FDF	;@4542
	db 59h,45h,4Ch,4Ch,20h,57h,48h,41h,54h,3Fh,8Dh,0h	;@4545
L4551:	call L4F4D	;@4551
	cmp ah, 0FFh	;@4554
	jne L4551	;@4557
	cmp al, 0Dh	;@4559
	je L4562	;@455B
	call L53F4	;@455D
	jmp L4551	;@4560
L4562:	call L53F4	;@4562
	jmp L0A33	;@4565
L4568:	call L4A1C	;@4568
	mov byte ptr D_054F, 1	;@456B
	mov byte ptr D_002E, 1	;@4570
	mov byte ptr D_0031, 26h	;@4575
	call L51FD	;@457A
	call L507A	;@457D
	call L4FDF	;@4580
	db 8Dh,41h,20h,4Ch,45h,56h,45h,4Ch,20h,0h	;@4583
	mov al, byte ptr D_0056	;@458D
	call L53B5	;@4590
	mov al, 20h	;@4593
	call L53F4	;@4595
	mov al, byte ptr D_0046	;@4598
	call L505F	;@459B
	mov al, 20h	;@459E
	call L53F4	;@45A0
	mov al, byte ptr D_0048	;@45A3
	clc	;@45A6
	adc al, 44h	;@45A7
	call L508C	;@45A9
	mov al, 20h	;@45AC
	call L53F4	;@45AE
	mov al, byte ptr D_0047	;@45B1
	clc	;@45B4
	adc al, 48h	;@45B5
	call L508C	;@45B7
	mov al, 0Dh	;@45BA
	call L53F4	;@45BC
	mov al, 0Dh	;@45BF
	call L53F4	;@45C1
	call L4FDF	;@45C4
	db 20h,20h,57h,45h,41h,50h,4Fh,4Eh,2Dh,0h	;@45C7
	mov al, byte ptr D_0061	;@45D1
	clc	;@45D4
	adc al, 13h	;@45D5
	call L508C	;@45D7
	mov bh, 0	;@45DA
	mov bl, 1Dh	;@45DC
	mov di, bx	;@45DE
	mov bh, 0	;@45E0
	mov bl, 3	;@45E2
	mov si, bx	;@45E4
	call L51EB	;@45E6
	call L4FDF	;@45E9
	db 54h,4Fh,52h,43h,48h,45h,53h,2Dh,0h	;@45EC
	mov al, byte ptr D_0064	;@45F5
	call L53B5	;@45F8
	mov bh, 0	;@45FB
	mov bl, 1	;@45FD
	mov di, bx	;@45FF
	mov bh, 0	;@4601
	mov bl, 4	;@4603
	mov si, bx	;@4605
	call L51EB	;@4607
	call L4FDF	;@460A
	db 20h,20h,41h,52h,4Dh,4Fh,55h,52h,2Dh,0h	;@460D
	mov al, byte ptr D_0062	;@4617
	clc	;@461A
	adc al, 1Dh	;@461B
	call L508C	;@461D
	mov bh, 0	;@4620
	mov bl, 20h	;@4622
	mov di, bx	;@4624
	mov bh, 0	;@4626
	mov bl, 4	;@4628
	mov si, bx	;@462A
	call L51EB	;@462C
	call L4FDF	;@462F
	db 4Bh,45h,59h,53h,2Dh,0h	;@4632
	mov al, byte ptr D_0065	;@4638
	call L53B5	;@463B
	mov bh, 0	;@463E
	mov bl, 4	;@4640
	mov di, bx	;@4642
	mov bh, 0	;@4644
	mov bl, 5	;@4646
	mov si, bx	;@4648
	call L51EB	;@464A
	call L4FDF	;@464D
	db 53h,50h,45h,4Ch,4Ch,2Dh,0h	;@4650
	mov al, byte ptr D_0063	;@4657
	clc	;@465A
	adc al, 24h	;@465B
	call L508C	;@465D
	mov bh, 0	;@4660
	mov bl, 1Fh	;@4662
	mov di, bx	;@4664
	mov bh, 0	;@4666
	mov bl, 5	;@4668
	mov si, bx	;@466A
	call L51EB	;@466C
	call L4FDF	;@466F
	db 54h,4Fh,4Fh,4Ch,53h,2Dh,0h	;@4672
	mov al, byte ptr D_0066	;@4679
	call L53B5	;@467C
	mov bh, 0	;@467F
	mov bl, 1	;@4681
	mov di, bx	;@4683
	mov bh, 0	;@4685
	mov bl, 6	;@4687
	mov si, bx	;@4689
	call L51EB	;@468B
	mov al, 3Eh	;@468E
	call L508C	;@4690
	mov al, 2Dh	;@4693
	call L53F4	;@4695
	mov al, byte ptr D_004B	;@4698
	call L53B5	;@469B
	mov bh, 0	;@469E
	mov bl, 2	;@46A0
	mov di, bx	;@46A2
	mov bh, 0	;@46A4
	mov bl, 7	;@46A6
	mov si, bx	;@46A8
	call L51EB	;@46AA
	mov al, 3Fh	;@46AD
	call L508C	;@46AF
	mov al, 2Dh	;@46B2
	call L53F4	;@46B4
	mov al, byte ptr D_004C	;@46B7
	call L53B5	;@46BA
	mov bh, 0	;@46BD
	mov bl, 10h	;@46BF
	mov di, bx	;@46C1
	mov bh, 0	;@46C3
	mov bl, 6	;@46C5
	mov si, bx	;@46C7
	call L51EB	;@46C9
	mov al, 40h	;@46CC
	call L508C	;@46CE
	mov al, 2Dh	;@46D1
	call L53F4	;@46D3
	mov al, byte ptr D_004D	;@46D6
	call L53B5	;@46D9
	mov bh, 0	;@46DC
	mov bl, 0Fh	;@46DE
	mov di, bx	;@46E0
	mov bh, 0	;@46E2
	mov bl, 7	;@46E4
	mov si, bx	;@46E6
	call L51EB	;@46E8
	mov al, 41h	;@46EB
	call L508C	;@46ED
	mov al, 2Dh	;@46F0
	call L53F4	;@46F2
	mov al, byte ptr D_004E	;@46F5
	call L53B5	;@46F8
	mov bh, 0	;@46FB
	mov bl, 1Eh	;@46FD
	mov di, bx	;@46FF
	mov bh, 0	;@4701
	mov bl, 6	;@4703
	mov si, bx	;@4705
	call L51EB	;@4707
	mov al, 42h	;@470A
	call L508C	;@470C
	mov al, 2Dh	;@470F
	call L53F4	;@4711
	mov al, byte ptr D_004F	;@4714
	call L53B5	;@4717
	mov bh, 0	;@471A
	mov bl, 1Dh	;@471C
	mov di, bx	;@471E
	mov bh, 0	;@4720
	mov bl, 7	;@4722
	mov si, bx	;@4724
	call L51EB	;@4726
	mov al, 43h	;@4729
	call L508C	;@472B
	mov al, 2Dh	;@472E
	call L53F4	;@4730
	mov al, byte ptr D_0050	;@4733
	call L53B5	;@4736
	mov bh, 0	;@4739
	mov bl, 1	;@473B
	mov di, bx	;@473D
	mov bh, 0	;@473F
	mov bl, 9	;@4741
	mov si, bx	;@4743
	call L51EB	;@4745
	call L4FDF	;@4748
	db 57h,45h,41h,50h,4Fh,4Eh,53h,3Ah,20h,0h	;@474B
	mov bh, 0	;@4755
	mov bl, 1	;@4757
	mov di, bx	;@4759
L475B:	mov al, byte ptr D_0076[di]	;@475B
	or al, al	;@475F
	je L478B	;@4761
	mov bx, di	;@4763
	mov byte ptr D_001F, bl	;@4765
	mov ax, di	;@4769
	clc	;@476B
	adc al, 13h	;@476C
	call L508C	;@476E
	call L4FDF	;@4771
	db 53h,2Dh,0h	;@4774
	mov bh, 0	;@4777
	mov bl, byte ptr D_001F	;@4779
	mov di, bx	;@477D
	mov al, byte ptr D_0076[di]	;@477F
	call L53B5	;@4783
	mov al, 20h	;@4786
	call L53F4	;@4788
L478B:	inc di	;@478B
	mov bx, di	;@478C
	cmp bl, 0Ah	;@478E
	jb L475B	;@4791
	mov bh, 0	;@4793
	mov bl, 1	;@4795
	mov di, bx	;@4797
	mov bh, 0	;@4799
	mov bl, 0Ch	;@479B
	mov si, bx	;@479D
	call L51EB	;@479F
	call L4FDF	;@47A2
	db 41h,52h,4Dh,4Fh,55h,52h,3Ah,20h,0h	;@47A5
	mov bh, 0	;@47AE
	mov bl, 1	;@47B0
	mov di, bx	;@47B2
L47B4:	mov al, byte ptr D_0096[di]	;@47B4
	or al, al	;@47B8
	je L47E3	;@47BA
	mov bx, di	;@47BC
	mov byte ptr D_001F, bl	;@47BE
	mov ax, di	;@47C2
	clc	;@47C4
	adc al, 1Dh	;@47C5
	call L508C	;@47C7
	call L4FDF	;@47CA
	db 2Dh,0h	;@47CD
	mov bh, 0	;@47CF
	mov bl, byte ptr D_001F	;@47D1
	mov di, bx	;@47D5
	mov al, byte ptr D_0096[di]	;@47D7
	call L53B5	;@47DB
	mov al, 20h	;@47DE
	call L53F4	;@47E0
L47E3:	inc di	;@47E3
	mov bx, di	;@47E4
	cmp bl, 7	;@47E6
	jb L47B4	;@47E9
	mov bh, 0	;@47EB
	mov bl, 1	;@47ED
	mov di, bx	;@47EF
	mov bh, 0	;@47F1
	mov bl, 0Eh	;@47F3
	mov si, bx	;@47F5
	call L51EB	;@47F7
	call L4FDF	;@47FA
	db 53h,50h,45h,4Ch,4Ch,53h,3Ah,20h,0h	;@47FD
	mov bh, 0	;@4806
	mov bl, 1	;@4808
	mov di, bx	;@480A
L480C:	mov al, byte ptr D_00B6[di]	;@480C
	or al, al	;@4810
	je L483C	;@4812
	mov bx, di	;@4814
	mov byte ptr D_001F, bl	;@4816
	mov ax, di	;@481A
	clc	;@481C
	adc al, 24h	;@481D
	call L508C	;@481F
	call L4FDF	;@4822
	db 53h,2Dh,0h	;@4825
	mov bh, 0	;@4828
	mov bl, byte ptr D_001F	;@482A
	mov di, bx	;@482E
	mov al, byte ptr D_00B6[di]	;@4830
	call L53B5	;@4834
	mov al, 20h	;@4837
	call L53F4	;@4839
L483C:	inc di	;@483C
	mov bx, di	;@483D
	cmp bl, 0Ah	;@483F
	jb L480C	;@4842
	mov bh, 0	;@4844
	mov bl, 1	;@4846
	mov di, bx	;@4848
	mov bh, 0	;@484A
	mov bl, 12h	;@484C
	mov si, bx	;@484E
	call L51EB	;@4850
	call L4FDF	;@4853
	db 49h,54h,45h,4Dh,53h,3Ah,20h,0h	;@4856
	mov bh, 0	;@485E
	mov bl, 0	;@4860
	mov di, bx	;@4862
L4864:	mov al, byte ptr D_00D6[di]	;@4864
	or al, al	;@4868
	je L489F	;@486A
	mov bx, di	;@486C
	mov byte ptr D_001F, bl	;@486E
	mov ax, di	;@4872
	clc	;@4874
	adc al, 2Eh	;@4875
	call L508C	;@4877
	cmp byte ptr D_001F, 3	;@487A
	je L4886	;@487F
	call L4FDF	;@4881
	db 53h,0h	;@4884
L4886:	call L4FDF	;@4886
	db 2Dh,0h	;@4889
	mov bh, 0	;@488B
	mov bl, byte ptr D_001F	;@488D
	mov di, bx	;@4891
	mov al, byte ptr D_00D6[di]	;@4893
	call L53B5	;@4897
	mov al, 20h	;@489A
	call L53F4	;@489C
L489F:	inc di	;@489F
	mov bx, di	;@48A0
	cmp bl, 10h	;@48A2
	jb L4864	;@48A5
	mov byte ptr D_002E, 0	;@48A7
	mov byte ptr D_054F, 0	;@48AC
	mov byte ptr D_0031, 28h	;@48B1
	mov bh, 0	;@48B6
	mov bl, 0	;@48B8
	mov di, bx	;@48BA
L48BC:	call L4F4D	;@48BC
	cmp ah, 0FFh	;@48BF
	jne L48BC	;@48C2
	call L4A3E	;@48C4
	call L50F9	;@48C7
	jmp L0A33	;@48CA
CODE ENDS
END
