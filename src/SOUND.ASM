; SOUND.ASM: PC speaker sounds.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 5C90-6000.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_054D:BYTE, D_058C:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	PUBLIC L5C95, L5CB2, L5CD2, L5CE4, L5E3B, L5E83
	PUBLIC L5EAC, L5EC7, L5ED7, L5EF2, L5FA6, L5FC3
	PUBLIC L5FE0
ASSUME CS:CODE, DS:DATA
L5C90 label byte
	db 0h,0h,0h,0h,0h	;@5C90
L5C95:	cmp byte ptr D_054D, 0	;@5C95
	jne L5CB1	;@5C9A
	push ax	;@5C9C
	push bx	;@5C9D
	push cx	;@5C9E
	mov bx, 500h	;@5C9F
	call L5CB2	;@5CA2
	mov cx, 4000h	;@5CA5
	call L5CD2	;@5CA8
	call L5CE4	;@5CAB
	pop cx	;@5CAE
	pop bx	;@5CAF
	pop ax	;@5CB0
L5CB1:	ret	;@5CB1
L5CB2:	push ax	;@5CB2
	mov al, 0B6h	;@5CB3
	out 43h, al	;@5CB5
	mov ax, bx	;@5CB7
	out 42h, al	;@5CB9
	mov al, ah	;@5CBB
	out 42h, al	;@5CBD
	in al, 61h	;@5CBF
	mov byte ptr cs:L5C90, al	;@5CC1
	cmp byte ptr D_054D, 0	;@5CC5
	jne L5CD0	;@5CCA
	or al, 3	;@5CCC
	out 61h, al	;@5CCE
L5CD0:	pop ax	;@5CD0
	ret	;@5CD1
L5CD2:	mov ax, bx	;@5CD2
	out 42h, al	;@5CD4
	mov al, ah	;@5CD6
	out 42h, al	;@5CD8
L5CDA:	mov ax, word ptr D_058C	;@5CDA
L5CDD:	dec ax	;@5CDD
	jns L5CDD	;@5CDE
	dec cx	;@5CE0
	jne L5CDA	;@5CE1
	ret	;@5CE3
L5CE4:	push ax	;@5CE4
	mov al, byte ptr cs:L5C90	;@5CE5
	out 61h, al	;@5CE9
	pop ax	;@5CEB
	ret	;@5CEC
	db 0B0h,0B6h,0E6h,43h,8Bh,0C3h,0E6h,42h,8Ah,0C4h,0E6h,42h,0E4h,61h,8Ah,0E0h	;@5CED
	db 0Ch,3h,0E6h,61h,49h,75h,0FDh,8Ah,0C4h,0E6h,61h,0C3h	;@5CFD
L5D09:	push ax	;@5D09
	push bx	;@5D0A
	push cx	;@5D0B
	push bp	;@5D0C
	cmp byte ptr D_054D, 0	;@5D0D
	jne L5D58	;@5D12
	shl bx, 1	;@5D14
	mov bp, word ptr cs:L5D9B[bx]	;@5D16
	mov bx, word ptr cs:[bp+1]	;@5D1B
	call L5CB2	;@5D1F
L5D22:	mov cl, 0	;@5D22
	mov ch, byte ptr cs:[bp]	;@5D24
	cmp ch, 0	;@5D28
	je L5D55	;@5D2B
	mov bx, word ptr cs:[bp+1]	;@5D2D
	db 81h,0FBh,0FFh,0FFh	;@5D31
	je L5D3D	;@5D35
	call L5CD2	;@5D37
	jmp L5D50	;@5D3A
L5D3D:	call L5CE4	;@5D3D
L5D40:	mov ax, word ptr D_058C	;@5D40
L5D43:	dec ax	;@5D43
	jns L5D43	;@5D44
	dec cx	;@5D46
	jne L5D40	;@5D47
	mov bx, word ptr cs:[bp+4]	;@5D49
	call L5CB2	;@5D4D
L5D50:	add bp, 3	;@5D50
	jmp L5D22	;@5D53
L5D55:	call L5CE4	;@5D55
L5D58:	pop bp	;@5D58
	pop cx	;@5D59
	pop bx	;@5D5A
	pop ax	;@5D5B
	ret	;@5D5C
	db 5h,0h,40h,0h,1h,0h,1h,0h,1h,0h,1h,0h,0h,0h,0h,0h	;@5D5D
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h	;@5D6D
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h	;@5D7D
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h	;@5D8D
L5D9B label byte
	db 5Dh,5Dh,61h,5Dh,65h,5Dh	;@5D9B
L5DA1 label byte
	db 0h,0h	;@5DA1
L5DA3 label byte
	db 0h,0h	;@5DA3
L5DA5 label byte
	db 0h,0h	;@5DA5
L5DA7 label byte
	db 0h,0h	;@5DA7
L5DA9:	cmp byte ptr D_054D, 0	;@5DA9
	je L5DB3	;@5DAE
	jmp L5E3A	;@5DB0
L5DB3:	push ax	;@5DB3
	push bx	;@5DB4
	push cx	;@5DB5
	push dx	;@5DB6
	push bp	;@5DB7
	shr bp, 1	;@5DB8
	mov word ptr cs:L5DA1, ax	;@5DBA
	mov word ptr cs:L5DA3, bx	;@5DBE
	mov word ptr cs:L5DA5, cx	;@5DC3
	mov bx, ax	;@5DC8
	call L5CB2	;@5DCA
	mov ax, 0	;@5DCD
	sub ax, word ptr cs:L5DA5	;@5DD0
	js L5DDE	;@5DD5
	mov word ptr cs:L5DA5, ax	;@5DD7
	jmp L5E07	;@5DDB
L5DDE:	mov ax, word ptr cs:L5DA1	;@5DDE
	mov word ptr cs:L5DA7, ax	;@5DE2
L5DE6:	mov bx, word ptr cs:L5DA7	;@5DE6
	mov cx, bp	;@5DEB
	call L5CD2	;@5DED
	dec dx	;@5DF0
	je L5E32	;@5DF1
	mov ax, word ptr cs:L5DA7	;@5DF3
	add ax, word ptr cs:L5DA5	;@5DF7
	mov word ptr cs:L5DA7, ax	;@5DFC
	cmp ax, word ptr cs:L5DA3	;@5E00
	jb L5DE6	;@5E05
L5E07:	mov ax, word ptr cs:L5DA3	;@5E07
	mov word ptr cs:L5DA7, ax	;@5E0B
L5E0F:	mov bx, word ptr cs:L5DA7	;@5E0F
	mov cx, bp	;@5E14
	call L5CD2	;@5E16
	dec dx	;@5E19
	je L5E32	;@5E1A
	mov ax, word ptr cs:L5DA7	;@5E1C
	sub ax, word ptr cs:L5DA5	;@5E20
	mov word ptr cs:L5DA7, ax	;@5E25
	cmp ax, word ptr cs:L5DA1	;@5E29
	ja L5E0F	;@5E2E
	jmp L5DDE	;@5E30
L5E32:	call L5CE4	;@5E32
	pop bp	;@5E35
	pop dx	;@5E36
	pop cx	;@5E37
	pop bx	;@5E38
	pop ax	;@5E39
L5E3A:	ret	;@5E3A
L5E3B:	push ax	;@5E3B
	push bx	;@5E3C
	push cx	;@5E3D
	push dx	;@5E3E
	mov ax, 100h	;@5E3F
	mov bx, 4000h	;@5E42
	mov cx, 1	;@5E45
	mov dx, 1000h	;@5E48
	mov bp, 80h	;@5E4B
	call L5DA9	;@5E4E
	pop dx	;@5E51
	pop cx	;@5E52
	pop bx	;@5E53
	pop ax	;@5E54
	ret	;@5E55
	db 80h,3Eh,4Dh,5h,0h,75h,25h,50h,53h,51h,52h,0BAh,0h,4h,0BBh,0h	;@5E56
	db 6h,0E8h,48h,0FEh,8Bh,0CAh,0E8h,63h,0FEh,83h,0C3h,40h,83h,0EAh,20h,81h	;@5E66
	db 0FAh,0h,1h,77h,0EFh,0E8h,66h,0FEh,5Ah,59h,5Bh,58h,0C3h	;@5E76
L5E83:	cmp byte ptr D_054D, 0	;@5E83
	jne L5EAB	;@5E88
	push ax	;@5E8A
	push bx	;@5E8B
	push cx	;@5E8C
	push dx	;@5E8D
	mov bx, 800h	;@5E8E
	call L5CB2	;@5E91
	mov dx, 100h	;@5E94
L5E97:	mov cx, dx	;@5E97
	call L5CD2	;@5E99
	sub dx, 2	;@5E9C
	sub bx, 40h	;@5E9F
	jns L5E97	;@5EA2
	call L5CE4	;@5EA4
	pop dx	;@5EA7
	pop cx	;@5EA8
	pop bx	;@5EA9
	pop ax	;@5EAA
L5EAB:	ret	;@5EAB
L5EAC:	push ax	;@5EAC
	push bx	;@5EAD
	push cx	;@5EAE
	push dx	;@5EAF
	mov ax, 300h	;@5EB0
	mov bx, 1000h	;@5EB3
	mov cx, 2	;@5EB6
	mov dx, 200h	;@5EB9
	mov bp, 8	;@5EBC
	call L5DA9	;@5EBF
	pop dx	;@5EC2
	pop cx	;@5EC3
	pop bx	;@5EC4
	pop ax	;@5EC5
	ret	;@5EC6
L5EC7:	cmp byte ptr D_054D, 0	;@5EC7
	jne L5ED6	;@5ECC
	push bx	;@5ECE
	mov bx, 0	;@5ECF
	call L5D09	;@5ED2
	pop bx	;@5ED5
L5ED6:	ret	;@5ED6
L5ED7:	push ax	;@5ED7
	push bx	;@5ED8
	push cx	;@5ED9
	push dx	;@5EDA
	mov ax, 200h	;@5EDB
	mov bx, 3000h	;@5EDE
	mov cx, 20h	;@5EE1
	mov dx, 0E00h	;@5EE4
	mov bp, 8	;@5EE7
	call L5DA9	;@5EEA
	pop dx	;@5EED
	pop cx	;@5EEE
	pop bx	;@5EEF
	pop ax	;@5EF0
	ret	;@5EF1
L5EF2:	push ax	;@5EF2
	push bx	;@5EF3
	push cx	;@5EF4
	push dx	;@5EF5
	mov ax, 800h	;@5EF6
	mov bx, 1800h	;@5EF9
	mov cx, 47h	;@5EFC
	mov dx, 800h	;@5EFF
	mov bp, 8	;@5F02
	call L5DA9	;@5F05
	pop dx	;@5F08
	pop cx	;@5F09
	pop bx	;@5F0A
	pop ax	;@5F0B
	ret	;@5F0C
	db 80h,3Eh,4Dh,5h,0h,74h,3h,0E9h,8Eh,0h,50h,53h,51h,52h,55h,2Eh	;@5F0D
	db 89h,1Eh,91h,5Ch,8Bh,0C1h,0F7h,26h,74h,0h,0F7h,36h,54h,5h,0F7h,26h	;@5F1D
	db 74h,0h,0F7h,36h,54h,5h,2Eh,0A3h,93h,5Ch,81h,3Eh,74h,0h,0h,18h	;@5F2D
	db 72h,17h,8Bh,0D0h,0B8h,0h,0h,0BBh,88h,13h,0F7h,0F3h,0BBh,1Eh,0h,89h	;@5F3D
	db 87h,80h,5h,0E8h,0BEh,0A7h,0EBh,4Bh,90h,0BDh,1h,0h,2Eh,8Bh,16h,93h	;@5F4D
	db 5Ch,8Bh,0CDh,0BBh,0h,30h,0E8h,87h,0FDh,0B8h,0Ah,0h,2Eh,3h,6h,91h	;@5F5D
	db 5Ch,2Bh,0C5h,48h,75h,0FDh,4Ah,75h,0E8h,83h,0C5h,1h,83h,0FDh,0Ah,76h	;@5F6D
	db 0DBh,2Eh,8Bh,16h,93h,5Ch,8Bh,0CDh,0BBh,0h,30h,0E8h,62h,0FDh,0B8h,0Ah	;@5F7D
	db 0h,2Eh,3h,6h,91h,5Ch,2Bh,0C5h,48h,75h,0FDh,4Ah,75h,0E8h,83h,0EDh	;@5F8D
	db 1h,75h,0DEh,5Dh,5Ah,59h,5Bh,58h,0C3h	;@5F9D
L5FA6:	push ax	;@5FA6
	push bx	;@5FA7
	push cx	;@5FA8
	push dx	;@5FA9
	push bp	;@5FAA
	mov ax, 2F8h	;@5FAB
	mov bx, 320h	;@5FAE
	mov cx, 0FFFFh	;@5FB1
	mov dx, 50h	;@5FB4
	mov bp, 0F00h	;@5FB7
	call L5DA9	;@5FBA
	pop bp	;@5FBD
	pop dx	;@5FBE
	pop cx	;@5FBF
	pop bx	;@5FC0
	pop ax	;@5FC1
	ret	;@5FC2
L5FC3:	push ax	;@5FC3
	push bx	;@5FC4
	push cx	;@5FC5
	push dx	;@5FC6
	push bp	;@5FC7
	mov ax, 492h	;@5FC8
	mov bx, 4C0h	;@5FCB
	mov cx, 0FFFFh	;@5FCE
	mov dx, 5Ch	;@5FD1
	mov bp, 0B00h	;@5FD4
	call L5DA9	;@5FD7
	pop bp	;@5FDA
	pop dx	;@5FDB
	pop cx	;@5FDC
	pop bx	;@5FDD
	pop ax	;@5FDE
	ret	;@5FDF
L5FE0:	push ax	;@5FE0
	push bx	;@5FE1
	push cx	;@5FE2
	push dx	;@5FE3
	push bp	;@5FE4
	mov ax, 400h	;@5FE5
	mov bx, 1000h	;@5FE8
	mov cx, 1	;@5FEB
	mov dx, 200h	;@5FEE
	mov bp, 80h	;@5FF1
	call L5DA9	;@5FF4
	pop bp	;@5FF7
	pop dx	;@5FF8
	pop cx	;@5FF9
	pop bx	;@5FFA
	pop ax	;@5FFB
	ret	;@5FFC
	db 0h,0h,0h	;@5FFD
CODE ENDS
END
