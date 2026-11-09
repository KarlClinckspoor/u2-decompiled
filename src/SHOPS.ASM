; SHOPS.ASM: towns: pub (tips), temple, oracle, armour and weapon shops, transport.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 154E-2028.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0000:BYTE, D_0001:BYTE, D_0013:BYTE, D_001F:BYTE, D_0021:BYTE, D_0025:BYTE
	EXTRN D_0027:BYTE, D_0028:BYTE, D_0046:BYTE, D_0047:BYTE, D_004A:BYTE, D_0053:BYTE
	EXTRN D_0076:BYTE, D_0096:BYTE, D_00B6:BYTE, D_0476:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L0A33:NEAR, L2028:NEAR, L2052:NEAR, L20AB:NEAR, L4F4D:NEAR, L4FDF:NEAR
	EXTRN L507A:NEAR, L508C:NEAR, L50D8:NEAR, L51A5:NEAR, L5217:NEAR, L53F4:NEAR
	PUBLIC L154E, L1590
ASSUME CS:CODE, DS:DATA
L154E:	nop	;@154E
	push es	;@154F
	mov ah, 0	;@1550
	mov si, ax	;@1552
	mov di, word ptr D_0476	;@1554
	push ds	;@1558
	pop es	;@1559
	jmp L1564	;@155A
L155D:	push es	;@155D
	push cs	;@155E
	pop es	;@155F
	mov di, word ptr D_0027	;@1560
L1564:	mov al, byte ptr es:[di]	;@1564
	cmp al, 0	;@1567
	je L156E	;@1569
L156B:	inc di	;@156B
	jmp L1564	;@156C
L156E:	dec si	;@156E
	je L1573	;@156F
	jmp L156B	;@1571
L1573:	inc di	;@1573
	mov al, byte ptr es:[di]	;@1574
	cmp al, 0	;@1577
	je L1580	;@1579
	call L53F4	;@157B
	jmp L1573	;@157E
L1580:	pop es	;@1580
	ret	;@1581
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h	;@1582
L1590:	nop	;@1590
	mov al, byte ptr D_0000	;@1591
	cmp al, 20h	;@1594
	jb L15A2	;@1596
	mov al, byte ptr D_0001	;@1598
	cmp al, 20h	;@159B
	jb L15AC	;@159D
	jmp L15C8	;@159F
L15A2:	mov al, byte ptr D_0001	;@15A2
	cmp al, 20h	;@15A5
	jb L15BA	;@15A7
	jmp L15D6	;@15A9
L15AC:	nop	;@15AC
	mov al, byte ptr D_004A	;@15AD
	cmp al, 2	;@15B0
	jne L15B7	;@15B2
	jmp L1D1D	;@15B4
L15B7:	jmp L1799	;@15B7
L15BA:	nop	;@15BA
	mov al, byte ptr D_004A	;@15BB
	cmp al, 2	;@15BE
	jne L15C5	;@15C0
	jmp L1E4F	;@15C2
L15C5:	jmp L1AE0	;@15C5
L15C8:	nop	;@15C8
	mov al, byte ptr D_004A	;@15C9
	cmp al, 2	;@15CC
	jne L15D3	;@15CE
	jmp L1F75	;@15D0
L15D3:	jmp L1841	;@15D3
L15D6:	nop	;@15D6
	mov al, byte ptr D_004A	;@15D7
	cmp al, 2	;@15DA
	jne L15E1	;@15DC
	jmp L15E4	;@15DE
L15E1:	jmp L19AF	;@15E1
L15E4:	nop	;@15E4
	call L4FDF	;@15E5
	db 57h,45h,4Ch,43h,4Fh,4Dh,45h,20h,54h,4Fh,20h,54h,48h,45h,20h,50h	;@15E8
	db 55h,42h,21h,0Dh,31h,2Dh,42h,55h,59h,2Ch,20h,32h,2Dh,54h,49h,50h	;@15F8
	db 20h,2Dh,2Dh,2Dh,20h,0h	;@1608
	call L2028	;@160E
	cmp al, 1	;@1611
	je L161C	;@1613
	cmp al, 2	;@1615
	je L1651	;@1617
	jmp L0A33	;@1619
L161C:	nop	;@161C
	mov al, 5	;@161D
	mov byte ptr D_0028, al	;@161F
	mov al, 0	;@1622
	mov byte ptr D_0027, al	;@1624
	call L2052	;@1627
	call L4FDF	;@162A
	db 48h,45h,52h,45h,2Ch,20h,48h,41h,56h,45h,20h,41h,20h,53h,54h,52h	;@162D
	db 4Fh,4Eh,47h,20h,4Fh,4Eh,45h,21h,0Dh,0h	;@163D
	call L5217	;@1647
	and al, 3	;@164A
	mov al, 1	;@164C
	jmp L1686	;@164E
L1651:	nop	;@1651
	call L4FDF	;@1652
	db 54h,49h,50h,20h,48h,4Fh,57h,20h,4Dh,55h,43h,48h,3Fh,20h,0h	;@1655
	call L2028	;@1664
	mov byte ptr D_0025, al	;@1667
	mov byte ptr D_0028, al	;@166A
	mov al, 0	;@166D
	mov byte ptr D_0027, al	;@166F
	call L2052	;@1672
	call L5217	;@1675
	call L50D8	;@1678
	clc	;@167B
	adc al, byte ptr D_0025	;@167C
	cmp al, 0Ah	;@1680
	jb L1686	;@1682
	mov al, 0	;@1684
L1686:	nop	;@1686
	mov byte ptr D_0025, al	;@1687
	call L4FDF	;@168A
	db 54h,48h,45h,20h,42h,41h,52h,4Bh,45h,45h,50h,20h,53h,41h,59h,53h	;@168D
	db 3Ah,0Dh,0h	;@169D
	mov al, byte ptr D_0025	;@16A0
	mov ah, 0	;@16A3
	mov si, ax	;@16A5
	inc si	;@16A7
	db 2Eh		; cs: prefix, which MASM drops on lea	;@16A8
	lea ax, L16BC	;@16A9
	mov word ptr D_0027, ax	;@16AD
	mov bh, 0	;@16B0
	mov bl, 0	;@16B2
	mov di, bx	;@16B4
	call L155D	;@16B6
	jmp L0A33	;@16B9
L16BC label byte
	db 0h,43h,41h,55h,47h,48h,2Eh,2Eh,2Eh,0h,49h,53h,4Eh,27h,54h,20h	;@16BC
	db 54h,48h,49h,53h,20h,41h,20h,47h,52h,45h,41h,54h,20h,47h,41h,4Dh	;@16CC
	db 45h,3Fh,0h,48h,48h,4Dh,4Dh,4Dh,2Eh,2Eh,2Eh,0h,53h,4Fh,4Dh,45h	;@16DC
	db 20h,46h,49h,47h,48h,54h,45h,52h,53h,20h,57h,45h,41h,52h,20h,4Dh	;@16EC
	db 41h,47h,49h,43h,20h,48h,45h,4Ch,4Dh,53h,21h,0h,41h,56h,49h,41h	;@16FC
	db 54h,4Fh,52h,53h,20h,55h,53h,45h,20h,53h,4Bh,55h,4Ch,4Ch,20h,4Bh	;@170C
	db 45h,59h,53h,21h,0h,53h,41h,59h,4Ch,4Fh,52h,53h,20h,57h,45h,41h	;@171C
	db 52h,20h,42h,4Ch,55h,45h,20h,54h,41h,53h,53h,4Ch,45h,53h,21h,0h	;@172C
	db 4Dh,41h,47h,45h,53h,20h,43h,41h,52h,52h,59h,20h,57h,41h,4Eh,44h	;@173C
	db 53h,20h,4Fh,52h,20h,53h,54h,41h,46h,46h,53h,21h,0h,47h,55h,41h	;@174C
	db 52h,44h,53h,20h,43h,41h,52h,52h,59h,20h,4Bh,45h,59h,53h,21h,0h	;@175C
	db 41h,4Eh,4Bh,48h,53h,20h,4Fh,50h,45h,4Eh,20h,53h,50h,41h,43h,45h	;@176C
	db 21h,0h,50h,4Ch,41h,4Eh,45h,53h,20h,4Eh,45h,45h,44h,20h,42h,52h	;@177C
	db 41h,53h,53h,20h,42h,55h,54h,54h,4Fh,4Eh,53h,21h,0h	;@178C
L1799:	nop	;@1799
	call L4FDF	;@179A
	db 54h,48h,45h,20h,46h,4Fh,4Fh,44h,20h,48h,45h,52h,45h,20h,43h,4Fh	;@179D
	db 53h,54h,53h,20h,0h	;@17AD
	mov al, 3	;@17B2
	call L20AB	;@17B4
	mov al, byte ptr D_0027	;@17B7
	mov bh, 0	;@17BA
	mov bl, byte ptr D_0028	;@17BC
	mov di, bx	;@17C0
	call L51A5	;@17C2
	call L4FDF	;@17C5
	db 8Dh,50h,45h,52h,20h,31h,30h,30h,2Ch,20h,57h,41h,4Eh,54h,20h,4Fh	;@17C8
	db 4Eh,45h,3Fh,20h,0h	;@17D8
L17DD:	call L4F4D	;@17DD
	cmp ah, 0FFh	;@17E0
	jne L17DD	;@17E3
	cmp al, 59h	;@17E5
	je L17F2	;@17E7
	call L4FDF	;@17E9
	db 4Eh,4Fh,0h	;@17EC
	jmp L0A33	;@17EF
L17F2:	call L4FDF	;@17F2
	db 59h,45h,53h,2Ch,8Dh,4Eh,4Fh,20h,4Fh,4Eh,49h,4Fh,4Eh,53h,20h,41h	;@17F5
	db 4Eh,44h,20h,54h,4Fh,20h,47h,4Fh,20h,50h,4Ch,45h,41h,53h,45h,21h	;@1805
	db 8Dh,0h	;@1815
	call L2052	;@1817
	clc	;@181A
	mov al, byte ptr D_0053	;@181B
	adc al, 1	;@181E
	daa	;@1820
	mov byte ptr D_0053, al	;@1821
	call L4FDF	;@1824
	db 54h,48h,41h,4Eh,4Bh,20h,59h,4Fh,55h,2Ch,20h,43h,4Fh,4Dh,45h,20h	;@1827
	db 41h,47h,41h,49h,4Eh,21h,0h	;@1837
	jmp L0A33	;@183E
L1841:	nop	;@1841
	mov al, byte ptr D_0047	;@1842
	cmp al, 1	;@1845
	je L1869	;@1847
	call L507A	;@1849
	call L4FDF	;@184C
	db 20h,59h,4Fh,55h,20h,41h,52h,45h,20h,4Eh,4Fh,54h,20h,41h,20h,43h	;@184F
	db 4Ch,45h,52h,49h,43h,21h,0h	;@185F
	jmp L0A33	;@1866
L1869:	nop	;@1869
	call L4FDF	;@186A
	db 57h,45h,4Ch,43h,4Fh,4Dh,45h,20h,0h	;@186D
	mov al, byte ptr D_0046	;@1876
	cmp al, 1	;@1879
	je L188C	;@187B
	call L4FDF	;@187D
	db 42h,52h,4Fh,54h,48h,45h,52h,20h,0h	;@1880
	jmp L1897	;@1889
L188C:	call L4FDF	;@188C
	db 53h,49h,53h,54h,45h,52h,20h,0h	;@188F
L1897:	call L507A	;@1897
	call L4FDF	;@189A
	db 8Dh,31h,2Dh,4Ch,49h,47h,48h,54h,2Ch,20h,32h,2Dh,4Ch,2Eh,44h,2Eh	;@189D
	db 2Ch,20h,33h,2Dh,4Ch,2Eh,55h,2Eh,2Ch,8Dh,34h,2Dh,50h,41h,53h,53h	;@18AD
	db 20h,35h,2Dh,53h,55h,52h,46h,41h,43h,45h,2Ch,20h,36h,2Dh,50h,52h	;@18BD
	db 41h,59h,45h,52h,2Eh,8Dh,59h,4Fh,55h,52h,20h,49h,4Eh,54h,45h,52h	;@18CD
	db 45h,53h,54h,3Fh,20h,0h	;@18DD
	call L2028	;@18E3
	je L18EF	;@18E6
	cmp al, 7	;@18E8
	jae L18EF	;@18EA
	jmp L190F	;@18EC
L18EF:	call L4FDF	;@18EF
	db 46h,4Fh,4Ch,4Ch,4Fh,57h,20h,54h,48h,45h,20h,4Ch,49h,47h,48h,54h	;@18F2
	db 2Ch,20h,46h,52h,49h,45h,4Eh,44h,21h,0h	;@1902
	jmp L0A33	;@190C
L190F:	mov byte ptr D_001F, al	;@190F
	call L4FDF	;@1912
	db 46h,49h,56h,45h,20h,0h	;@1915
	mov al, byte ptr D_001F	;@191B
	clc	;@191E
	adc al, 24h	;@191F
	call L508C	;@1921
	call L4FDF	;@1924
	db 53h,20h,46h,4Fh,52h,20h,0h	;@1927
	mov al, byte ptr D_001F	;@192E
	call L20AB	;@1931
	mov al, byte ptr D_0027	;@1934
	mov bh, 0	;@1937
	mov bl, byte ptr D_0028	;@1939
	mov di, bx	;@193D
	call L51A5	;@193F
	call L4FDF	;@1942
	db 8Dh,59h,45h,53h,2Ch,20h,46h,52h,49h,45h,4Eh,44h,3Fh,20h,0h	;@1945
L1954:	call L4F4D	;@1954
	cmp ah, 0FFh	;@1957
	jne L1954	;@195A
	cmp al, 59h	;@195C
	je L197E	;@195E
	call L4FDF	;@1960
	db 4Eh,4Fh,8Dh,49h,27h,4Dh,20h,53h,4Fh,52h,52h,59h,2Ch,20h,47h,4Fh	;@1963
	db 4Fh,44h,20h,44h,41h,59h,2Eh,0h	;@1973
	jmp L0A33	;@197B
L197E:	call L4FDF	;@197E
	db 59h,45h,53h,2Ch,8Dh,49h,20h,57h,49h,4Ch,4Ch,20h,54h,41h,4Bh,45h	;@1981
	db 20h,35h,21h,0h	;@1991
	call L2052	;@1995
	mov bh, 0	;@1998
	mov bl, byte ptr D_001F	;@199A
	mov di, bx	;@199E
	mov al, byte ptr D_00B6[di]	;@19A0
	clc	;@19A4
	adc al, 5	;@19A5
	daa	;@19A7
	mov byte ptr D_00B6[di], al	;@19A8
	jmp L0A33	;@19AC
L19AF:	nop	;@19AF
	call L507A	;@19B0
	mov al, byte ptr D_0047	;@19B3
	cmp al, 2	;@19B6
	je L19D7	;@19B8
	call L4FDF	;@19BA
	db 20h,59h,4Fh,55h,20h,41h,52h,45h,20h,4Eh,4Fh,54h,20h,41h,20h,57h	;@19BD
	db 49h,5Ah,41h,52h,44h,21h,0h	;@19CD
	jmp L0A33	;@19D4
L19D7:	nop	;@19D7
	call L4FDF	;@19D8
	db 20h,4Dh,55h,53h,45h,52h,52h,45h,46h,20h,4Fh,4Ch,44h,55h,4Dh,21h	;@19DB
	db 8Dh,31h,2Dh,4Ch,49h,47h,48h,54h,2Ch,20h,32h,2Dh,4Ch,2Eh,44h,2Eh	;@19EB
	db 2Ch,20h,33h,2Dh,4Ch,2Eh,55h,2Eh,2Ch,8Dh,34h,2Dh,4Dh,2Eh,4Dh,2Eh	;@19FB
	db 2Ch,20h,35h,2Dh,42h,4Ch,49h,4Eh,4Bh,2Ch,20h,36h,2Dh,4Bh,49h,4Ch	;@1A0B
	db 4Ch,2Ch,8Dh,42h,49h,52h,20h,49h,4Bh,49h,20h,55h,43h,2Eh,2Eh,2Eh	;@1A1B
	db 3Fh,20h,0h	;@1A2B
	call L2028	;@1A2E
	je L1A3A	;@1A31
	cmp al, 7	;@1A33
	jae L1A3A	;@1A35
	jmp L1A4F	;@1A37
L1A3A:	call L4FDF	;@1A3A
	db 8Dh,55h,47h,55h,52h,4Ch,41h,20h,4Fh,4Ch,53h,55h,4Eh,21h,0h	;@1A3D
	jmp L0A33	;@1A4C
L1A4F:	cmp al, 4	;@1A4F
	jb L1A56	;@1A51
	clc	;@1A53
	adc al, 3	;@1A54
L1A56:	mov byte ptr D_001F, al	;@1A56
	call L4FDF	;@1A59
	db 46h,49h,56h,45h,20h,0h	;@1A5C
	mov al, byte ptr D_001F	;@1A62
	clc	;@1A65
	adc al, 24h	;@1A66
	call L508C	;@1A68
	call L4FDF	;@1A6B
	db 53h,20h,46h,4Fh,52h,20h,0h	;@1A6E
	mov al, byte ptr D_001F	;@1A75
	call L20AB	;@1A78
	mov al, byte ptr D_0027	;@1A7B
	mov bh, 0	;@1A7E
	mov bl, byte ptr D_0028	;@1A80
	mov di, bx	;@1A84
	call L51A5	;@1A86
	call L4FDF	;@1A89
	db 8Dh,4Ch,55h,54h,46h,45h,4Eh,20h,45h,56h,45h,54h,3Fh,20h,0h	;@1A8C
L1A9B:	call L4F4D	;@1A9B
	cmp ah, 0FFh	;@1A9E
	jne L1A9B	;@1AA1
	cmp al, 59h	;@1AA3
	je L1AB0	;@1AA5
	call L4FDF	;@1AA7
	db 4Eh,4Fh,21h,0h	;@1AAA
	jmp L1A3A	;@1AAE
L1AB0:	call L4FDF	;@1AB0
	db 59h,45h,53h,8Dh,0h	;@1AB3
	call L2052	;@1AB8
	clc	;@1ABB
	mov bh, 0	;@1ABC
	mov bl, byte ptr D_001F	;@1ABE
	mov di, bx	;@1AC2
	mov al, byte ptr D_00B6[di]	;@1AC4
	adc al, 5	;@1AC8
	daa	;@1ACA
	mov byte ptr D_00B6[di], al	;@1ACB
	call L4FDF	;@1ACF
	db 47h,55h,4Ch,45h,20h,47h,55h,4Ch,45h,21h,0h	;@1AD2
	jmp L0A33	;@1ADD
L1AE0:	nop	;@1AE0
	call L4FDF	;@1AE1
	db 54h,49h,4Dh,45h,20h,41h,4Eh,44h,20h,54h,52h,41h,56h,45h,4Ch,20h	;@1AE4
	db 4Dh,41h,44h,45h,20h,4Dh,45h,20h,57h,49h,53h,45h,2Ch,0Dh,50h,52h	;@1AF4
	db 45h,43h,49h,4Fh,55h,53h,20h,47h,4Fh,4Ch,44h,2Ch,20h,41h,20h,43h	;@1B04
	db 4Ch,55h,45h,20h,49h,54h,20h,42h,55h,59h,53h,21h,48h,4Fh,57h,20h	;@1B14
	db 4Dh,55h,43h,48h,20h,57h,49h,4Ch,4Ch,20h,59h,4Fh,55h,20h,50h,41h	;@1B24
	db 59h,20h,2Ah,31h,30h,30h,3Fh,0h	;@1B34
	call L2028	;@1B3C
	mov byte ptr D_001F, al	;@1B3F
	mov byte ptr D_0027, al	;@1B42
	mov al, 0	;@1B45
	mov byte ptr D_0028, al	;@1B47
	call L2052	;@1B4A
	mov bh, 0	;@1B4D
	mov bl, byte ptr D_001F	;@1B4F
	mov si, bx	;@1B53
	inc si	;@1B55
	db 2Eh		; cs: prefix, which MASM drops on lea	;@1B56
	lea ax, L1B6A	;@1B57
	mov word ptr D_0027, ax	;@1B5B
	mov bh, 0	;@1B5E
	mov bl, 0	;@1B60
	mov di, bx	;@1B62
	call L155D	;@1B64
	jmp L0A33	;@1B67
L1B6A label byte
	db 0h,41h,53h,4Bh,20h,4Dh,45h,20h,4Eh,4Fh,20h,51h,55h,45h,53h,54h	;@1B6A
	db 49h,4Fh,4Eh,53h,2Ch,8Dh,49h,27h,4Ch,4Ch,20h,54h,45h,4Ch,4Ch,20h	;@1B7A
	db 59h,4Fh,55h,20h,4Eh,4Fh,20h,4Ch,49h,45h,53h,2Eh,0h,54h,48h,45h	;@1B8A
	db 20h,51h,55h,45h,45h,4Eh,20h,49h,53h,20h,54h,48h,45h,20h,4Bh,49h	;@1B9A
	db 4Eh,47h,8Dh,41h,4Eh,44h,20h,54h,48h,45h,20h,4Bh,49h,4Eh,47h,20h	;@1BAA
	db 49h,53h,20h,41h,20h,53h,50h,59h,2Eh,0h,54h,48h,45h,20h,45h,56h	;@1BBA
	db 49h,4Ch,20h,4Dh,45h,4Eh,20h,44h,4Fh,8Dh,49h,53h,20h,41h,20h,48h	;@1BCA
	db 4Fh,52h,52h,49h,42h,4Ch,45h,20h,54h,48h,49h,4Eh,47h,2Eh,0h,42h	;@1BDA
	db 55h,54h,20h,44h,49h,53h,50h,45h,4Ch,4Ch,49h,4Eh,47h,20h,4Dh,45h	;@1BEA
	db 41h,4Eh,53h,8Dh,54h,48h,41h,54h,20h,59h,4Fh,55h,20h,4Dh,55h,53h	;@1BFA
	db 54h,20h,48h,41h,56h,45h,20h,54h,48h,45h,20h,52h,49h,4Eh,47h,2Eh	;@1C0A
	db 0h,4Ah,55h,53h,54h,20h,57h,48h,45h,52h,45h,20h,49h,54h,20h,49h	;@1C1A
	db 53h,2Ch,8Dh,49h,20h,43h,41h,4Eh,4Eh,4Fh,54h,20h,53h,41h,59h,2Eh	;@1C2A
	db 0h,42h,55h,54h,20h,49h,27h,4Ch,4Ch,20h,54h,45h,4Ch,4Ch,20h,59h	;@1C3A
	db 4Fh,55h,20h,52h,49h,47h,48h,54h,20h,4Eh,4Fh,57h,2Ch,8Dh,54h,48h	;@1C4A
	db 45h,52h,45h,20h,49h,53h,20h,4Eh,4Fh,20h,4Fh,54h,48h,45h,52h,20h	;@1C5A
	db 57h,41h,59h,2Eh,0h,49h,20h,48h,45h,41h,52h,20h,49h,4Eh,20h,41h	;@1C6A
	db 20h,54h,4Fh,57h,4Eh,8Dh,57h,48h,45h,52h,45h,20h,54h,48h,45h,20h	;@1C7A
	db 57h,41h,54h,45h,52h,20h,52h,55h,4Eh,53h,20h,46h,52h,45h,45h,2Eh	;@1C8A
	db 0h,54h,48h,45h,52h,45h,20h,49h,53h,20h,41h,4Eh,20h,4Fh,4Ch,44h	;@1C9A
	db 20h,4Dh,41h,4Eh,8Dh,4Ch,49h,56h,49h,4Eh,47h,20h,55h,4Eh,44h,45h	;@1CAA
	db 52h,20h,41h,20h,54h,52h,45h,45h,2Eh,0h,48h,45h,20h,48h,41h,53h	;@1CBA
	db 20h,4Eh,4Fh,54h,20h,41h,20h,4Eh,41h,4Dh,45h,8Dh,42h,55h,54h,20h	;@1CCA
	db 48h,45h,20h,44h,4Fh,45h,53h,20h,48h,41h,56h,45h,20h,41h,20h,43h	;@1CDA
	db 4Ch,55h,45h,0h,4Dh,41h,59h,48h,41h,50h,53h,20h,49h,46h,20h,59h	;@1CEA
	db 4Fh,55h,20h,46h,49h,4Eh,44h,20h,48h,49h,4Dh,2Ch,8Dh,48h,45h,27h	;@1CFA
	db 4Ch,4Ch,20h,54h,45h,4Ch,4Ch,20h,49h,54h,20h,54h,4Fh,20h,59h,4Fh	;@1D0A
	db 55h,21h,0h	;@1D1A
L1D1D:	nop	;@1D1D
	call L4FDF	;@1D1E
	db 20h,20h,20h,20h,20h,54h,48h,45h,20h,41h,52h,4Dh,4Fh,55h,52h,20h	;@1D21
	db 53h,48h,4Fh,50h,50h,45h,3Ah,0Dh,31h,2Dh,43h,4Ch,4Fh,54h,48h,2Ch	;@1D31
	db 20h,32h,2Dh,4Ch,45h,41h,54h,48h,45h,52h,2Ch,20h,33h,2Dh,43h,48h	;@1D41
	db 41h,49h,4Eh,2Ch,0Dh,34h,2Dh,50h,4Ch,41h,54h,45h,2Ch,20h,35h,2Dh	;@1D51
	db 52h,45h,46h,4Ch,45h,43h,54h,2Ch,20h,36h,2Dh,50h,4Fh,57h,45h,52h	;@1D61
	db 2Ch,0Dh,59h,4Fh,55h,52h,20h,49h,4Eh,54h,45h,52h,45h,53h,54h,3Fh	;@1D71
	db 20h,0h	;@1D81
	call L2028	;@1D83
	je L1D8F	;@1D86
	cmp al, 7	;@1D88
	jae L1D8F	;@1D8A
	jmp L1DAD	;@1D8C
L1D8F:	call L4FDF	;@1D8F
	db 54h,48h,41h,4Eh,4Bh,53h,20h,46h,4Fh,52h,20h,43h,4Fh,4Dh,49h,4Eh	;@1D92
	db 47h,20h,42h,59h,2Eh,2Eh,2Eh,0h	;@1DA2
	jmp L0A33	;@1DAA
L1DAD:	mov byte ptr D_001F, al	;@1DAD
	call L4FDF	;@1DB0
	db 41h,48h,21h,20h,59h,45h,53h,21h,20h,0h	;@1DB3
	mov al, byte ptr D_001F	;@1DBD
	clc	;@1DC0
	adc al, 1Dh	;@1DC1
	call L508C	;@1DC3
	call L4FDF	;@1DC6
	db 0Dh,46h,4Fh,52h,20h,59h,4Fh,55h,20h,4Fh,4Eh,4Ch,59h,20h,0h	;@1DC9
	mov al, byte ptr D_001F	;@1DD8
	add al, al	;@1DDB
	call L20AB	;@1DDD
	mov al, byte ptr D_0027	;@1DE0
	mov bh, 0	;@1DE3
	mov bl, byte ptr D_0028	;@1DE5
	mov di, bx	;@1DE9
	call L51A5	;@1DEB
	call L4FDF	;@1DEE
	db 0Dh,48h,4Fh,57h,20h,27h,42h,4Fh,55h,54h,20h,49h,54h,3Fh,20h,0h	;@1DF1
L1E01:	call L4F4D	;@1E01
	cmp ah, 0FFh	;@1E04
	jne L1E01	;@1E07
	mov byte ptr D_0021, al	;@1E09
	call L53F4	;@1E0C
	mov al, 8Dh	;@1E0F
	call L53F4	;@1E11
	mov al, byte ptr D_0021	;@1E14
	cmp al, 59h	;@1E17
	je L1E2B	;@1E19
	call L4FDF	;@1E1B
	db 4Fh,48h,2Ch,20h,57h,45h,4Ch,4Ch,2Eh,0h	;@1E1E
	jmp L0A33	;@1E28
L1E2B:	nop	;@1E2B
	call L2052	;@1E2C
	call L4FDF	;@1E2F
	db 53h,4Fh,4Ch,44h,21h,0h	;@1E32
	mov bh, 0	;@1E38
	mov bl, byte ptr D_001F	;@1E3A
	mov di, bx	;@1E3E
	mov al, byte ptr D_0096[di]	;@1E40
	clc	;@1E44
	adc al, 1	;@1E45
	daa	;@1E47
	mov byte ptr D_0096[di], al	;@1E48
	jmp L0A33	;@1E4C
L1E4F:	nop	;@1E4F
	call L4FDF	;@1E50
	db 20h,20h,54h,48h,45h,20h,57h,45h,41h,50h,4Fh,4Eh,53h,20h,53h,48h	;@1E53
	db 4Fh,50h,50h,45h,3Ah,0Dh,31h,2Dh,44h,41h,2Ch,20h,32h,2Dh,4Dh,41h	;@1E63
	db 2Ch,20h,33h,2Dh,41h,58h,2Ch,20h,34h,2Dh,42h,4Fh,2Ch,0Dh,35h,2Dh	;@1E73
	db 53h,57h,2Ch,20h,36h,2Dh,47h,52h,2Ch,20h,37h,2Dh,4Ch,49h,2Ch,20h	;@1E83
	db 38h,2Dh,50h,48h,2Eh,0Dh,59h,4Fh,55h,52h,20h,49h,4Eh,54h,45h,52h	;@1E93
	db 45h,53h,54h,3Fh,20h,0h	;@1EA3
	call L2028	;@1EA9
	je L1EB5	;@1EAC
	cmp al, 9	;@1EAE
	je L1EB5	;@1EB0
	jmp L1ED3	;@1EB2
L1EB5:	call L4FDF	;@1EB5
	db 54h,48h,41h,4Eh,4Bh,53h,20h,46h,4Fh,52h,20h,43h,4Fh,4Dh,49h,4Eh	;@1EB8
	db 47h,20h,42h,59h,2Eh,2Eh,2Eh,0h	;@1EC8
	jmp L0A33	;@1ED0
L1ED3:	mov byte ptr D_001F, al	;@1ED3
	call L4FDF	;@1ED6
	db 41h,48h,21h,20h,59h,45h,53h,21h,20h,41h,20h,0h	;@1ED9
	mov al, byte ptr D_001F	;@1EE5
	clc	;@1EE8
	adc al, 13h	;@1EE9
	call L508C	;@1EEB
	call L4FDF	;@1EEE
	db 0Dh,46h,4Fh,52h,20h,59h,4Fh,55h,20h,4Fh,4Eh,4Ch,59h,20h,0h	;@1EF1
	mov al, byte ptr D_001F	;@1F00
	call L20AB	;@1F03
	mov al, byte ptr D_0027	;@1F06
	mov bh, 0	;@1F09
	mov bl, byte ptr D_0028	;@1F0B
	mov di, bx	;@1F0F
	call L51A5	;@1F11
	call L4FDF	;@1F14
	db 0Dh,48h,4Fh,57h,20h,27h,42h,4Fh,55h,54h,20h,49h,54h,3Fh,20h,0h	;@1F17
L1F27:	call L4F4D	;@1F27
	cmp ah, 0FFh	;@1F2A
	jne L1F27	;@1F2D
	mov byte ptr D_0021, al	;@1F2F
	call L53F4	;@1F32
	mov al, 8Dh	;@1F35
	call L53F4	;@1F37
	mov al, byte ptr D_0021	;@1F3A
	cmp al, 59h	;@1F3D
	je L1F51	;@1F3F
	call L4FDF	;@1F41
	db 4Fh,48h,2Ch,20h,57h,45h,4Ch,4Ch,2Eh,0h	;@1F44
	jmp L0A33	;@1F4E
L1F51:	nop	;@1F51
	call L2052	;@1F52
	call L4FDF	;@1F55
	db 53h,4Fh,4Ch,44h,21h,0h	;@1F58
	mov bh, 0	;@1F5E
	mov bl, byte ptr D_001F	;@1F60
	mov di, bx	;@1F64
	mov al, byte ptr D_0076[di]	;@1F66
	clc	;@1F6A
	adc al, 1	;@1F6B
	daa	;@1F6D
	mov byte ptr D_0076[di], al	;@1F6E
	jmp L0A33	;@1F72
L1F75:	nop	;@1F75
	call L4FDF	;@1F76
	db 57h,45h,4Ch,43h,4Fh,4Dh,45h,2Ch,20h,54h,4Fh,20h,54h,48h,45h,20h	;@1F79
	db 54h,52h,41h,4Eh,53h,50h,4Fh,52h,54h,0Dh,53h,48h,4Fh,50h,50h,45h	;@1F89
	db 2Eh,20h,49h,20h,53h,45h,4Ch,4Ch,20h,59h,4Fh,55h,20h,48h,4Fh,52h	;@1F99
	db 53h,45h,20h,0h	;@1FA9
	mov al, 4	;@1FAD
	call L20AB	;@1FAF
	mov al, byte ptr D_0027	;@1FB2
	mov bh, 0	;@1FB5
	mov bl, byte ptr D_0028	;@1FB7
	mov di, bx	;@1FBB
	call L51A5	;@1FBD
	call L4FDF	;@1FC0
	db 0Dh,47h,4Fh,4Ch,44h,2Ch,20h,44h,45h,41h,4Ch,2Ch,20h,4Fh,4Bh,3Fh	;@1FC3
	db 20h,2Dh,2Dh,2Dh,20h,0h	;@1FD3
L1FD9:	call L4F4D	;@1FD9
	cmp ah, 0FFh	;@1FDC
	jne L1FD9	;@1FDF
	push ax	;@1FE1
	call L53F4	;@1FE2
	mov al, 8Dh	;@1FE5
	call L53F4	;@1FE7
	pop ax	;@1FEA
	cmp al, 59h	;@1FEB
	je L2007	;@1FED
	call L4FDF	;@1FEF
	db 0Dh,4Fh,2Eh,4Bh,2Eh,20h,42h,59h,45h,20h,54h,48h,45h,4Eh,2Eh,2Eh	;@1FF2
	db 2Eh,0h	;@2002
	jmp L0A33	;@2004
L2007:	call L2052	;@2007
	call L4FDF	;@200A
	db 8Dh,52h,49h,44h,45h,20h,53h,57h,49h,46h,54h,4Ch,59h,21h,0h	;@200D
	mov al, 22h	;@201C
	mov byte ptr D_0013, al	;@201E
	jmp L0A33	;@2021
	db 90h,0E9h,0Bh,0EAh	;@2024
CODE ENDS
END
