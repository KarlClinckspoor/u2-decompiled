; TEXTIO.ASM: terrain names; keyboard, text output, numbers, random numbers, file I/O.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 4C60-5400.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0000:BYTE, D_0001:BYTE, D_0006:BYTE, D_0019:BYTE, D_001A:BYTE, D_0023:BYTE
	EXTRN D_0024:BYTE, D_0027:BYTE, D_002B:BYTE, D_002E:BYTE, D_002F:BYTE, D_0031:BYTE
	EXTRN D_0036:BYTE, D_0046:BYTE, D_0051:BYTE, D_0052:BYTE, D_0053:BYTE, D_0054:BYTE
	EXTRN D_0056:BYTE, D_0057:BYTE, D_0058:BYTE, D_0059:BYTE, D_0074:BYTE, D_0137:BYTE
	EXTRN D_0157:BYTE, D_023E:BYTE, D_023F:BYTE, D_0240:BYTE, D_0243:BYTE, D_0244:BYTE
	EXTRN D_0245:BYTE, D_0246:BYTE, D_024E:BYTE, D_024F:BYTE, D_0250:BYTE, D_0253:BYTE
	EXTRN D_0472:BYTE, D_0478:BYTE, D_054D:BYTE, D_054F:BYTE, D_0554:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L06ED:NEAR, L4C1E:NEAR
	PUBLIC L4F11, L4F36, L4F4D, L4FDF, L5003, L505F
	PUBLIC L507A, L508C, L50B3, L50D8, L50EF, L50F9
	PUBLIC L51A5, L51B0, L51EB, L51FD, L5217, L523E
	PUBLIC L5255, L52CA, L538F, L53B5, L53D0, L53D9
	PUBLIC L53DF, L53F4
ASSUME CS:CODE, DS:DATA
L4C60 label byte
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
L4F04 label byte
	db 0h	;@4F04
L4F05 label byte
	db 0h,0h	;@4F05
L4F07 label byte
	db 0h,0h	;@4F07
L4F09 label byte
	db 48h	;@4F09
L4F0A label byte
	db 0Eh,50h,19h,4Dh,5h,4Bh,17h	;@4F0A
L4F11:	stc	;@4F11
	mov al, byte ptr D_0000	;@4F12
	sub al, byte ptr D_0137[di]	;@4F15
	add al, al	;@4F19
	add al, al	;@4F1B
	call L50D8	;@4F1D
	mov byte ptr D_0019, al	;@4F20
	stc	;@4F23
	mov al, byte ptr D_0001	;@4F24
	sub al, byte ptr D_0157[di]	;@4F27
	add al, al	;@4F2B
	add al, al	;@4F2D
	call L50D8	;@4F2F
	mov byte ptr D_001A, al	;@4F32
	ret	;@4F35
L4F36:	stc	;@4F36
	mov al, byte ptr D_0000	;@4F37
	sub al, byte ptr D_0137[di]	;@4F3A
	mov byte ptr D_0019, al	;@4F3E
	stc	;@4F41
	mov al, byte ptr D_0001	;@4F42
	sub al, byte ptr D_0157[di]	;@4F45
	mov byte ptr D_001A, al	;@4F49
	ret	;@4F4C
L4F4D:	push bx	;@4F4D
	mov ah, 1	;@4F4E
	int 16h	;@4F50
	mov ah, 0	;@4F52
	je L4FD3	;@4F54
	int 16h	;@4F56
	cmp al, 5	;@4F58
	je L4F64	;@4F5A
	cmp al, 0Eh	;@4F5C
	je L4F64	;@4F5E
	cmp al, 17h	;@4F60
	jne L4F69	;@4F62
L4F64:	mov al, 0	;@4F64
	jmp L4FD1	;@4F66
L4F69:	push ax	;@4F69
L4F6A:	mov ah, 1	;@4F6A
	int 16h	;@4F6C
	je L4F76	;@4F6E
	mov ah, 0	;@4F70
	int 16h	;@4F72
	jmp L4F6A	;@4F74
L4F76:	pop ax	;@4F76
	cmp al, 13h	;@4F77
	jne L4F85	;@4F79
	xor byte ptr D_054D, 0FFh	;@4F7B
	mov ah, 0	;@4F80
	jmp L4FDD	;@4F82
L4F85:	cmp al, 0	;@4F85
	jne L4FD1	;@4F87
	cmp ax, 7400h	;@4F89
	jne L4FA0	;@4F8C
	mov ax, word ptr D_0074	;@4F8E
	sub ax, 200h	;@4F91
	cmp ax, word ptr D_0554	;@4F94
	jb L4FB6	;@4F98
	mov word ptr D_0074, ax	;@4F9A
	jmp L4FB3	;@4F9D
L4FA0:	cmp ax, 7300h	;@4FA0
	jne L4FBB	;@4FA3
	mov ax, word ptr D_0074	;@4FA5
	add ax, 200h	;@4FA8
	cmp ax, 3A00h	;@4FAB
	ja L4FB6	;@4FAE
	mov word ptr D_0074, ax	;@4FB0
L4FB3:	call L06ED	;@4FB3
L4FB6:	mov ah, 0	;@4FB6
	jmp L4FDD	;@4FB8
L4FBB:	mov bx, 6	;@4FBB
L4FBE:	cmp ah, byte ptr cs:L4F09[bx]	;@4FBE
	je L4FCC	;@4FC3
	sub bx, 2	;@4FC5
	js L4FD1	;@4FC8
	jmp L4FBE	;@4FCA
L4FCC:	mov al, byte ptr cs:L4F0A[bx]	;@4FCC
L4FD1:	mov ah, 0FFh	;@4FD1
L4FD3:	cmp al, 61h	;@4FD3
	jb L4FDD	;@4FD5
	cmp al, 7Ah	;@4FD7
	ja L4FDD	;@4FD9
	and al, 0DFh	;@4FDB
L4FDD:	pop bx	;@4FDD
	ret	;@4FDE
L4FDF:	call L51FD	;@4FDF
	pop ax	;@4FE2
	mov word ptr D_002B, ax	;@4FE3
	mov si, 0	;@4FE6
	jmp L4FF0	;@4FE9
L4FEC:	inc word ptr D_002B	;@4FEC
L4FF0:	mov bx, word ptr D_002B	;@4FF0
	mov al, byte ptr cs:[bx+si]	;@4FF4
	cmp al, 0	;@4FF7
	je L5000	;@4FF9
	call L5003	;@4FFB
	jmp L4FEC	;@4FFE
L5000:	inc bx	;@5000
	push bx	;@5001
	ret	;@5002
L5003:	push bx	;@5003
	push cx	;@5004
	push dx	;@5005
	push ax	;@5006
	and al, 7Fh	;@5007
	cmp al, 0Dh	;@5009
	jne L5016	;@500B
L500D:	mov al, byte ptr D_054F	;@500D
	mov byte ptr D_002E, al	;@5010
	jmp L501A	;@5013
L5016:	cmp al, 0Ah	;@5016
	jne L503D	;@5018
L501A:	inc byte ptr D_002F	;@501A
	cmp byte ptr D_002F, 18h	;@501E
	jne L5057	;@5023
	mov al, 1	;@5025
	mov cx, 1400h	;@5027
	mov dh, 17h	;@502A
	mov dl, byte ptr D_0031	;@502C
	mov bh, 0	;@5030
	mov ah, 6	;@5032
	int 10h	;@5034
	dec byte ptr D_002F	;@5036
	jmp L5057	;@503A
L503D:	mov ah, 9	;@503D
	mov cx, 1	;@503F
	mov bl, byte ptr D_023E	;@5042
	mov bh, 0	;@5046
	int 10h	;@5048
	inc byte ptr D_002E	;@504A
	mov al, byte ptr D_0031	;@504E
	cmp al, byte ptr D_002E	;@5051
	jb L500D	;@5055
L5057:	call L51FD	;@5057
	pop ax	;@505A
	pop dx	;@505B
	pop cx	;@505C
	pop bx	;@505D
	ret	;@505E
L505F:	mov al, byte ptr D_0046	;@505F
	cmp al, 4Dh	;@5062
	jne L506F	;@5064
	call L4FDF	;@5066
	db 4Dh,41h,4Ch,45h,0h	;@5069
	ret	;@506E
L506F:	call L4FDF	;@506F
	db 46h,45h,4Dh,41h,4Ch,45h,0h	;@5072
	ret	;@5079
L507A:	mov bx, 0	;@507A
L507D:	mov al, byte ptr D_0036[bx]	;@507D
	cmp al, 0	;@5081
	je L508B	;@5083
	call L5003	;@5085
	inc bx	;@5088
	jmp L507D	;@5089
L508B:	ret	;@508B
L508C:	mov ah, 0	;@508C
	mov si, ax	;@508E
	mov di, 0	;@5090
L5093:	cmp byte ptr cs:L4C60[di], 0	;@5093
	je L509E	;@5099
L509B:	inc di	;@509B
	jmp L5093	;@509C
L509E:	dec si	;@509E
	je L50A3	;@509F
	jmp L509B	;@50A1
L50A3:	inc di	;@50A3
	mov al, byte ptr cs:L4C60[di]	;@50A4
	cmp al, 0	;@50A9
	je L50B2	;@50AB
	call L5003	;@50AD
	jmp L50A3	;@50B0
L50B2:	ret	;@50B2
L50B3:	push bx	;@50B3
	push cx	;@50B4
	mov ah, 0	;@50B5
	mov al, byte ptr D_0024	;@50B7
	mov cl, 6	;@50BA
	shl ax, cl	;@50BC
	mov bh, 0	;@50BE
	mov bl, byte ptr D_0023	;@50C0
	add bx, ax	;@50C4
	add bx, word ptr D_0472	;@50C6
	mov word ptr D_0006, bx	;@50CA
	mov al, byte ptr [bx]	;@50CE
	mov si, 0	;@50D0
	pop cx	;@50D3
	pop bx	;@50D4
	or al, al	;@50D5
	ret	;@50D7
L50D8:	cmp al, 0	;@50D8
	je L50E3	;@50DA
	jns L50E1	;@50DC
	mov al, 0FFh	;@50DE
	ret	;@50E0
L50E1:	mov al, 1	;@50E1
L50E3:	ret	;@50E3
	db 3Ch,0h,74h,0FBh,3Ch,20h,72h,0F5h,0B0h,0FFh,0C3h	;@50E4
L50EF:	cmp al, 80h	;@50EF
	jb L50E3	;@50F1
	xor al, 0FFh	;@50F3
	clc	;@50F5
	adc al, 1	;@50F6
	ret	;@50F8
L50F9:	mov al, 28h	;@50F9
	mov byte ptr D_0031, al	;@50FB
	mov byte ptr D_002E, 1Eh	;@50FE
	mov al, 14h	;@5103
	mov byte ptr D_002F, al	;@5105
	call L4FDF	;@5108
	db 48h,2Eh,50h,2Eh,3Dh,0h	;@510B
	mov bh, 0	;@5111
	mov bl, byte ptr D_0052	;@5113
	mov di, bx	;@5117
	mov al, byte ptr D_0051	;@5119
	or al, al	;@511C
	jne L5123	;@511E
	call L53DF	;@5120
L5123:	call L51A5	;@5123
	call L53D9	;@5126
	mov al, 1Eh	;@5129
	mov byte ptr D_002E, al	;@512B
	mov byte ptr D_002F, 15h	;@512E
	call L4FDF	;@5133
	db 46h,4Fh,4Fh,44h,3Dh,0h	;@5136
	mov bh, 0	;@513C
	mov bl, byte ptr D_0054	;@513E
	mov di, bx	;@5142
	mov al, byte ptr D_0053	;@5144
	or al, al	;@5147
	jne L514E	;@5149
	call L53DF	;@514B
L514E:	call L51A5	;@514E
	call L53D9	;@5151
	mov al, 1Eh	;@5154
	mov byte ptr D_002E, al	;@5156
	mov byte ptr D_002F, 16h	;@5159
	call L4FDF	;@515E
	db 45h,58h,50h,2Eh,3Dh,0h	;@5161
	mov al, byte ptr D_0056	;@5167
	mov bh, 0	;@516A
	mov bl, byte ptr D_0057	;@516C
	mov di, bx	;@5170
	call L51A5	;@5172
	mov al, 1Eh	;@5175
	mov byte ptr D_002E, al	;@5177
	mov byte ptr D_002F, 17h	;@517A
	call L4FDF	;@517F
	db 47h,4Fh,4Ch,44h,3Dh,0h	;@5182
	mov al, byte ptr D_0058	;@5188
	mov bh, 0	;@518B
	mov bl, byte ptr D_0059	;@518D
	mov di, bx	;@5191
	call L51A5	;@5193
	mov al, 1Dh	;@5196
	mov byte ptr D_0031, al	;@5198
	mov di, 0	;@519B
	mov si, 17h	;@519E
	call L51EB	;@51A1
	ret	;@51A4
L51A5:	push ax	;@51A5
	call L53B5	;@51A6
	mov ax, di	;@51A9
	call L53B5	;@51AB
	pop ax	;@51AE
	ret	;@51AF
L51B0:	call L4F4D	;@51B0
	cmp ah, 0FFh	;@51B3
	jne L51B0	;@51B6
	cmp al, 30h	;@51B8
	jb L51B0	;@51BA
	cmp al, 39h	;@51BC
	ja L51B0	;@51BE
	call L5003	;@51C0
	sub al, 30h	;@51C3
	add al, al	;@51C5
	add al, al	;@51C7
	add al, al	;@51C9
	add al, al	;@51CB
	mov byte ptr D_0027, al	;@51CD
L51D0:	call L4F4D	;@51D0
	cmp ah, 0FFh	;@51D3
	jne L51D0	;@51D6
	cmp al, 30h	;@51D8
	jb L51D0	;@51DA
	cmp al, 39h	;@51DC
	ja L51D0	;@51DE
	call L5003	;@51E0
	sub al, 30h	;@51E3
	clc	;@51E5
	adc al, byte ptr D_0027	;@51E6
	ret	;@51EA
L51EB:	push bx	;@51EB
	mov bx, di	;@51EC
	mov byte ptr D_002E, bl	;@51EE
	mov bx, si	;@51F2
	mov byte ptr D_002F, bl	;@51F4
	call L51FD	;@51F8
	pop bx	;@51FB
	ret	;@51FC
L51FD:	push ax	;@51FD
	push bx	;@51FE
	push cx	;@51FF
	push dx	;@5200
	mov dh, byte ptr D_002F	;@5201
	mov dl, byte ptr D_002E	;@5205
	mov cx, 1	;@5209
	mov bh, 0	;@520C
	mov ah, 2	;@520E
	int 10h	;@5210
	pop dx	;@5212
	pop cx	;@5213
	pop bx	;@5214
	pop ax	;@5215
	ret	;@5216
L5217:	push ax	;@5217
	push bx	;@5218
	stc	;@5219
	mov al, byte ptr D_0240	;@521A
	adc al, byte ptr D_0243	;@521D
	adc al, byte ptr D_0244	;@5221
	mov byte ptr D_023F, al	;@5225
	mov bx, 4	;@5228
L522B:	mov al, byte ptr D_023F[bx]	;@522B
	mov byte ptr D_0240[bx], al	;@522F
	dec bx	;@5233
	jns L522B	;@5234
	pop bx	;@5236
	pop ax	;@5237
	mov al, byte ptr D_023F	;@5238
	or al, al	;@523B
	ret	;@523D
L523E:	nop	;@523E
	mov al, byte ptr D_001A	;@523F
	cmp al, 1	;@5242
	je L525E	;@5244
	cmp al, 0FFh	;@5246
	je L5267	;@5248
	mov al, byte ptr D_0019	;@524A
	cmp al, 1	;@524D
	je L5270	;@524F
	cmp al, 0FFh	;@5251
	je L5279	;@5253
L5255:	mov ax, 90h	;@5255
	mov bx, 50h	;@5258
	jmp L527F	;@525B
L525E:	mov ax, 90h	;@525E
	mov bx, 60h	;@5261
	jmp L527F	;@5264
L5267:	mov ax, 90h	;@5267
	mov bx, 40h	;@526A
	jmp L527F	;@526D
L5270:	mov ax, 0A0h	;@5270
	mov bx, 50h	;@5273
	jmp L527F	;@5276
L5279:	mov ax, 80h	;@5279
	mov bx, 50h	;@527C
L527F:	db 2Eh		; cs: prefix, which MASM drops on lea	;@527F
	lea cx, L5288	;@5280
	call L4C1E	;@5284
	ret	;@5287
L5288 label byte
	db 4h,10h,0h,0Fh,0F0h,0h,0h,0FFh,0FFh,0h,3h,0FFh,0FFh,0C0h,0Fh,0FFh	;@5288
	db 0FFh,0F0h,0Fh,0FFh,0FFh,0F0h,3Fh,0FFh,0FFh,0FCh,3Fh,0FFh,0FFh,0FCh,3Fh,0FFh	;@5298
	db 0FFh,0FCh,3Fh,0FFh,0FFh,0FCh,3Fh,0FFh,0FFh,0FCh,3Fh,0FFh,0FFh,0FCh,0Fh,0FFh	;@52A8
	db 0FFh,0F0h,0Fh,0FFh,0FFh,0F0h,3h,0FFh,0FFh,0C0h,0h,0FFh,0FFh,0h,0h,0Fh	;@52B8
	db 0F0h,0h	;@52C8
L52CA:	pop bx	;@52CA
	add bx, 8	;@52CB
	push bx	;@52CE
	push ax	;@52CF
	push cx	;@52D0
	push dx	;@52D1
	push si	;@52D2
	push di	;@52D3
	push es	;@52D4
	mov byte ptr cs:L4F04, ah	;@52D5
	mov word ptr cs:L4F05, cx	;@52DA
	mov word ptr cs:L4F07, dx	;@52DF
	mov si, 24h	;@52E4
L52E7:	mov byte ptr D_0245[si], 0	;@52E7
	dec si	;@52EC
	jns L52E7	;@52ED
	mov si, bx	;@52EF
	mov bx, 8	;@52F1
	sub si, bx	;@52F4
L52F6:	dec bx	;@52F6
	mov al, byte ptr cs:[bx+si]	;@52F7
	mov byte ptr D_0246[bx], al	;@52FA
	jne L52F6	;@52FE
	mov byte ptr D_024E, 20h	;@5300
	mov byte ptr D_024F, 20h	;@5305
	mov byte ptr D_0250, 20h	;@530A
L530F:	mov ah, 0Fh	;@530F
	lea dx, D_0245	;@5311
	int 21h	;@5315
	cmp al, 0	;@5317
	je L5343	;@5319
	call L4FDF	;@531B
	db 0Dh,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h	;@531E
	db 57h,52h,4Fh,4Eh,47h,20h,44h,49h,53h,4Bh,0h	;@532E
L5339:	call L4F4D	;@5339
	cmp ax, 0FF1Bh	;@533C
	jne L5339	;@533F
	jmp L530F	;@5341
L5343:	mov dx, word ptr cs:L4F07	;@5343
	push ds	;@5348
	cmp word ptr D_0246, 4950h	;@5349
	jne L5356	;@534F
	mov ax, 0B800h	;@5351
	mov ds, ax	;@5354
L5356:	mov ah, 1Ah	;@5356
	int 21h	;@5358
	pop ds	;@535A
	lea dx, D_0245	;@535B
	mov cx, word ptr cs:L4F05	;@535F
	mov word ptr D_0253, 1	;@5364
	mov ah, byte ptr cs:L4F04	;@536A
	int 21h	;@536F
	lea dx, D_0245	;@5371
	mov ah, 10h	;@5375
	int 21h	;@5377
	pop es	;@5379
	pop di	;@537A
	pop si	;@537B
	pop dx	;@537C
	pop cx	;@537D
	pop ax	;@537E
	ret	;@537F
	db 50h,53h,0BBh,0h,1h,4Bh,75h,0FDh,0FEh,0C8h,75h,0F6h,5Bh,58h,0C3h	;@5380
L538F:	mov byte ptr D_002F, 17h	;@538F
	call L53A0	;@5394
	mov byte ptr D_002F, 18h	;@5397
	call L53A0	;@539C
	ret	;@539F
L53A0:	push ax	;@53A0
	push cx	;@53A1
	mov byte ptr D_002E, 0	;@53A2
	mov al, 20h	;@53A7
	mov cx, 28h	;@53A9
L53AC:	call L5003	;@53AC
	dec cx	;@53AF
	jne L53AC	;@53B0
	pop cx	;@53B2
	pop ax	;@53B3
	ret	;@53B4
L53B5:	push ax	;@53B5
	mov ah, al	;@53B6
	shr al, 1	;@53B8
	shr al, 1	;@53BA
	shr al, 1	;@53BC
	shr al, 1	;@53BE
	or al, 30h	;@53C0
	call L5003	;@53C2
	mov al, ah	;@53C5
	and al, 0Fh	;@53C7
	or al, 30h	;@53C9
	call L5003	;@53CB
	pop ax	;@53CE
	ret	;@53CF
L53D0:	call L4F4D	;@53D0
	cmp ah, 0FFh	;@53D3
	jne L53D0	;@53D6
	ret	;@53D8
L53D9:	mov byte ptr D_023E, 0Fh	;@53D9
	ret	;@53DE
L53DF:	cmp byte ptr D_0478, 0	;@53DF
	je L53EE	;@53E4
	mov byte ptr D_023E, 2	;@53E6
	jmp L53F3	;@53EB
L53EE:	mov byte ptr D_023E, 70h	;@53EE
L53F3:	ret	;@53F3
L53F4:	call L5003	;@53F4
	ret	;@53F7
	db 0h,0h,0h,0h,0h,0h,0h,0h	;@53F8
CODE ENDS
END
