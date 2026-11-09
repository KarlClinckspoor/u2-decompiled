; SCREEN.ASM: video tables (CGA segments, masks), clearing, tiles and pixels.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 48CD-4C60.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_002E:BYTE, D_002F:BYTE, D_0031:BYTE, D_0272:BYTE, D_0372:BYTE, D_0478:BYTE
	EXTRN D_0479:BYTE, D_047A:BYTE, D_04BF:BYTE, D_04C1:BYTE, D_05B0:BYTE, D_05DE:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L51FD:NEAR, L53D9:NEAR
	PUBLIC L4A1C, L4A3E, L4AAD, L4AE6, L4AF1, L4B26
	PUBLIC L4B4E, L4B76, L4BAA, L4BE0, L4C1E
ASSUME CS:CODE, DS:DATA
	db 0h,0h,0h	;@48CD
L48D0 label byte
	db 0C0h,30h,0Ch,3h	;@48D0
L48D4 label byte
	db 0FFh,11h,88h,0CCh,33h,0h,0h,0h	;@48D4
L48DC label byte
	db 0h,0B8h	;@48DC
L48DE label byte
	db 0h,0BAh,5h,0B8h,5h,0BAh,0Ah,0B8h,0Ah,0BAh,0Fh,0B8h,0Fh,0BAh,14h,0B8h	;@48DE
	db 14h,0BAh,19h,0B8h,19h,0BAh,1Eh,0B8h,1Eh,0BAh,23h,0B8h,23h,0BAh,28h,0B8h	;@48EE
	db 28h,0BAh,2Dh,0B8h,2Dh,0BAh,32h,0B8h,32h,0BAh,37h,0B8h,37h,0BAh,3Ch,0B8h	;@48FE
	db 3Ch,0BAh,41h,0B8h,41h,0BAh,46h,0B8h,46h,0BAh,4Bh,0B8h,4Bh,0BAh,50h,0B8h	;@490E
	db 50h,0BAh,55h,0B8h,55h,0BAh,5Ah,0B8h,5Ah,0BAh,5Fh,0B8h,5Fh,0BAh,64h,0B8h	;@491E
	db 64h,0BAh,69h,0B8h,69h,0BAh,6Eh,0B8h,6Eh,0BAh,73h,0B8h,73h,0BAh,78h,0B8h	;@492E
	db 78h,0BAh,7Dh,0B8h,7Dh,0BAh,82h,0B8h,82h,0BAh,87h,0B8h,87h,0BAh,8Ch,0B8h	;@493E
	db 8Ch,0BAh,91h,0B8h,91h,0BAh,96h,0B8h,96h,0BAh,9Bh,0B8h,9Bh,0BAh,0A0h,0B8h	;@494E
	db 0A0h,0BAh,0A5h,0B8h,0A5h,0BAh,0AAh,0B8h,0AAh,0BAh,0AFh,0B8h,0AFh,0BAh,0B4h,0B8h	;@495E
	db 0B4h,0BAh,0B9h,0B8h,0B9h,0BAh,0BEh,0B8h,0BEh,0BAh,0C3h,0B8h,0C3h,0BAh,0C8h,0B8h	;@496E
	db 0C8h,0BAh,0CDh,0B8h,0CDh,0BAh,0D2h,0B8h,0D2h,0BAh,0D7h,0B8h,0D7h,0BAh,0DCh,0B8h	;@497E
	db 0DCh,0BAh,0E1h,0B8h,0E1h,0BAh,0E6h,0B8h,0E6h,0BAh,0EBh,0B8h,0EBh,0BAh,0F0h,0B8h	;@498E
	db 0F0h,0BAh,0F5h,0B8h,0F5h,0BAh,0FAh,0B8h,0FAh,0BAh,0FFh,0B8h,0FFh,0BAh,4h,0B9h	;@499E
	db 4h,0BBh,9h,0B9h,9h,0BBh,0Eh,0B9h,0Eh,0BBh,13h,0B9h,13h,0BBh,18h,0B9h	;@49AE
	db 18h,0BBh,1Dh,0B9h,1Dh,0BBh,22h,0B9h,22h,0BBh,27h,0B9h,27h,0BBh,2Ch,0B9h	;@49BE
	db 2Ch,0BBh,31h,0B9h,31h,0BBh,36h,0B9h,36h,0BBh,3Bh,0B9h,3Bh,0BBh,40h,0B9h	;@49CE
	db 40h,0BBh,45h,0B9h,45h,0BBh,4Ah,0B9h,4Ah,0BBh,4Fh,0B9h,4Fh,0BBh,54h,0B9h	;@49DE
	db 54h,0BBh,59h,0B9h,59h,0BBh,5Eh,0B9h,5Eh,0BBh,63h,0B9h,63h,0BBh,68h,0B9h	;@49EE
	db 68h,0BBh,6Dh,0B9h,6Dh,0BBh,72h,0B9h,72h,0BBh,77h,0B9h,77h,0BBh,7Ch,0B9h	;@49FE
	db 7Ch,0BBh,81h,0B9h,81h,0BBh,86h,0B9h,86h,0BBh,8Bh,0B9h,8Bh,0BBh	;@4A0E
L4A1C:	push ax	;@4A1C
	mov ax, 1	;@4A1D
	int 10h	;@4A20
	mov byte ptr D_002E, 0	;@4A22
	mov byte ptr D_002F, 0	;@4A27
	call L51FD	;@4A2C
	mov byte ptr D_0031, 28h	;@4A2F
	mov byte ptr D_0478, 0	;@4A34
	call L53D9	;@4A39
	pop ax	;@4A3C
	ret	;@4A3D
L4A3E:	push ax	;@4A3E
	push bx	;@4A3F
	mov ah, 0	;@4A40
	mov al, 4	;@4A42
	int 10h	;@4A44
	mov ah, 0Bh	;@4A46
	mov bh, 0	;@4A48
	mov bl, 0	;@4A4A
	int 10h	;@4A4C
	mov ah, 0Bh	;@4A4E
	mov bh, 1	;@4A50
	mov bl, 1	;@4A52
	int 10h	;@4A54
	mov byte ptr D_0478, 1	;@4A56
	call L53D9	;@4A5B
	mov bx, 0FEh	;@4A5E
	mov ax, 0FFFFh	;@4A61
L4A64:	mov word ptr D_0272[bx], ax	;@4A64
	mov word ptr D_0372[bx], ax	;@4A68
	sub bx, 2	;@4A6C
	jns L4A64	;@4A6F
	pop bx	;@4A71
	pop ax	;@4A72
	ret	;@4A73
L4A74:	push ax	;@4A74
	push bx	;@4A75
	push dx	;@4A76
	push di	;@4A77
	push si	;@4A78
	push es	;@4A79
	mov si, cx	;@4A7A
	shr ax, 1	;@4A7C
	shr ax, 1	;@4A7E
	mov di, ax	;@4A80
	shl bx, 1	;@4A82
	mov dl, 10h	;@4A84
	add si, 2	;@4A86
L4A89:	mov ax, word ptr cs:L48DC[bx]	;@4A89
	mov es, ax	;@4A8E
	mov ax, word ptr [si]	;@4A90
	mov word ptr es:[di], ax	;@4A92
	mov ax, word ptr [si+2]	;@4A95
	mov word ptr es:[di+2], ax	;@4A98
	add si, 4	;@4A9C
	add bx, 2	;@4A9F
	dec dl	;@4AA2
	jne L4A89	;@4AA4
	pop es	;@4AA6
	pop si	;@4AA7
	pop di	;@4AA8
	pop dx	;@4AA9
	pop bx	;@4AAA
	pop ax	;@4AAB
	ret	;@4AAC
L4AAD:	push ax	;@4AAD
	push bx	;@4AAE
	push cx	;@4AAF
	push di	;@4AB0
	push si	;@4AB1
	mov bx, 0	;@4AB2
	mov si, 0	;@4AB5
L4AB8:	mov ax, 0	;@4AB8
L4ABB:	mov cl, byte ptr D_0272[si]	;@4ABB
	or cl, cl	;@4ABF
	js L4ACE	;@4AC1
	mov ch, 0	;@4AC3
	mov di, cx	;@4AC5
	mov cx, word ptr D_05B0[di]	;@4AC7
	call L4A74	;@4ACB
L4ACE:	inc si	;@4ACE
	add ax, 10h	;@4ACF
	cmp ax, 140h	;@4AD2
	jb L4ABB	;@4AD5
	add bx, 10h	;@4AD7
	cmp bx, 0A0h	;@4ADA
	jb L4AB8	;@4ADE
	pop si	;@4AE0
	pop di	;@4AE1
	pop cx	;@4AE2
	pop bx	;@4AE3
	pop ax	;@4AE4
	ret	;@4AE5
L4AE6:	push si	;@4AE6
ASSUME CS:CGROUP
	mov si, word ptr cs:CGROUP:D_05B0	;@4AE7
ASSUME CS:CODE
	call L4AFC	;@4AEC
	pop si	;@4AEF
	ret	;@4AF0
L4AF1:	push si	;@4AF1
ASSUME CS:CGROUP
	mov si, word ptr cs:CGROUP:D_05DE	;@4AF2
ASSUME CS:CODE
	call L4AFC	;@4AF7
	pop si	;@4AFA
	ret	;@4AFB
L4AFC:	push ax	;@4AFC
	push bx	;@4AFD
	push cx	;@4AFE
	push dx	;@4AFF
	mov bx, word ptr [si+2]	;@4B00
	mov cx, word ptr [si+4]	;@4B03
	mov dl, 0Fh	;@4B06
L4B08:	mov ax, word ptr [si+6]	;@4B08
	mov word ptr [si+2], ax	;@4B0B
	mov ax, word ptr [si+8]	;@4B0E
	mov word ptr [si+4], ax	;@4B11
	add si, 4	;@4B14
	dec dl	;@4B17
	jne L4B08	;@4B19
	mov word ptr [si+2], bx	;@4B1B
	mov word ptr [si+4], cx	;@4B1E
	pop dx	;@4B21
	pop cx	;@4B22
	pop bx	;@4B23
	pop ax	;@4B24
	ret	;@4B25
L4B26:	push ax	;@4B26
	mov ax, 0B800h	;@4B27
	call L4B35	;@4B2A
	mov ax, 0BA00h	;@4B2D
	call L4B35	;@4B30
	pop ax	;@4B33
	ret	;@4B34
L4B35:	push bx	;@4B35
	push es	;@4B36
	mov es, ax	;@4B37
	mov ax, 0FFFFh	;@4B39
	mov bx, 0	;@4B3C
L4B3F:	xor word ptr es:[bx], ax	;@4B3F
	add bx, 2	;@4B42
	cmp bx, 1900h	;@4B45
	jne L4B3F	;@4B49
	pop es	;@4B4B
	pop bx	;@4B4C
	ret	;@4B4D
L4B4E:	push ax	;@4B4E
	mov ax, 0B800h	;@4B4F
	call L4B5D	;@4B52
	mov ax, 0BA00h	;@4B55
	call L4B5D	;@4B58
	pop ax	;@4B5B
	ret	;@4B5C
L4B5D:	push bx	;@4B5D
	push es	;@4B5E
	mov es, ax	;@4B5F
	mov ax, 0	;@4B61
	mov bx, 0	;@4B64
L4B67:	mov word ptr es:[bx], ax	;@4B67
	add bx, 2	;@4B6A
	cmp bx, 1900h	;@4B6D
	jne L4B67	;@4B71
	pop es	;@4B73
	pop bx	;@4B74
	ret	;@4B75
L4B76:	push es	;@4B76
	mov ah, 0	;@4B77
	mov al, byte ptr D_0479	;@4B79
	add ax, word ptr D_04BF	;@4B7C
	mov di, ax	;@4B80
	mov ah, 0	;@4B82
	mov al, byte ptr D_047A	;@4B84
	add ax, word ptr D_04C1	;@4B87
	mov si, ax	;@4B8B
	mov bx, di	;@4B8D
	and bx, 3	;@4B8F
	shr di, 1	;@4B93
	shr di, 1	;@4B95
	shl si, 1	;@4B97
	mov ax, word ptr cs:L48DC[si]	;@4B99
	mov es, ax	;@4B9E
	mov al, byte ptr cs:L48D0[bx]	;@4BA0
	or byte ptr es:[di], al	;@4BA5
	pop es	;@4BA8
	ret	;@4BA9
L4BAA:	push es	;@4BAA
	mov ah, 0	;@4BAB
	mov al, byte ptr D_0479	;@4BAD
	add ax, word ptr D_04BF	;@4BB0
	mov di, ax	;@4BB4
	mov ah, 0	;@4BB6
	mov al, byte ptr D_047A	;@4BB8
	add ax, word ptr D_04C1	;@4BBB
	mov si, ax	;@4BBF
	mov bx, di	;@4BC1
	and bx, 3	;@4BC3
	shr di, 1	;@4BC7
	shr di, 1	;@4BC9
	shl si, 1	;@4BCB
	mov ax, word ptr cs:L48DC[si]	;@4BCD
	mov es, ax	;@4BD2
	mov al, byte ptr cs:L48D0[bx]	;@4BD4
	xor al, 0FFh	;@4BD9
	and byte ptr es:[di], al	;@4BDB
	pop es	;@4BDE
	ret	;@4BDF
L4BE0:	push ax	;@4BE0
	push bx	;@4BE1
	push bp	;@4BE2
	push cx	;@4BE3
	push di	;@4BE4
	push es	;@4BE5
	add ax, word ptr D_04BF	;@4BE6
	shr ax, 1	;@4BEA
	shr ax, 1	;@4BEC
	mov di, ax	;@4BEE
	mov cl, byte ptr cs:L48D4[bp]	;@4BF0
	add bx, word ptr D_04C1	;@4BF5
	shl bx, 1	;@4BF9
	mov ax, word ptr cs:L48DC[bx]	;@4BFB
	mov es, ax	;@4C00
	mov byte ptr es:[di], cl	;@4C02
	mov byte ptr es:[di+50h], cl	;@4C05
	mov ax, word ptr cs:L48DE[bx]	;@4C09
	mov es, ax	;@4C0E
	mov byte ptr es:[di], cl	;@4C10
	mov byte ptr es:[di+50h], cl	;@4C13
	pop es	;@4C17
	pop di	;@4C18
	pop cx	;@4C19
	pop bp	;@4C1A
	pop bx	;@4C1B
	pop ax	;@4C1C
	ret	;@4C1D
L4C1E:	push dx	;@4C1E
	push di	;@4C1F
	push si	;@4C20
	push es	;@4C21
	mov si, cx	;@4C22
	shr ax, 1	;@4C24
	shr ax, 1	;@4C26
	mov di, ax	;@4C28
	shl bx, 1	;@4C2A
	mov dl, 10h	;@4C2C
	add si, 2	;@4C2E
L4C31:	mov ax, word ptr cs:L48DC[bx]	;@4C31
	mov es, ax	;@4C36
	mov ax, word ptr cs:[si]	;@4C38
	xor word ptr es:[di], ax	;@4C3B
	mov ax, word ptr cs:[si+2]	;@4C3E
	xor word ptr es:[di+2], ax	;@4C42
	add si, 4	;@4C46
	add bx, 2	;@4C49
	dec dl	;@4C4C
	jne L4C31	;@4C4E
	pop es	;@4C50
	pop si	;@4C51
	pop di	;@4C52
	pop dx	;@4C53
	ret	;@4C54
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h	;@4C55
CODE ENDS
END
