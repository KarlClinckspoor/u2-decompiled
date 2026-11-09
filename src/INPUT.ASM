; INPUT.ASM: number and money entry, "illegal command".
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 2028-2290.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0000:BYTE, D_0001:BYTE, D_0006:BYTE, D_0019:BYTE, D_001A:BYTE, D_001F:BYTE
	EXTRN D_0020:BYTE, D_0023:BYTE, D_0024:BYTE, D_0027:BYTE, D_0028:BYTE, D_0029:BYTE
	EXTRN D_002A:BYTE, D_004A:BYTE, D_004E:BYTE, D_0050:BYTE, D_0058:BYTE, D_0059:BYTE
	EXTRN D_0137:BYTE, D_0157:BYTE, D_0177:BYTE, D_0197:BYTE, D_01B7:BYTE, D_026A:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L0A30:NEAR, L0AA1:NEAR, L0C62:NEAR, L1040:NEAR, L4F4D:NEAR, L4FDF:NEAR
	EXTRN L50B3:NEAR, L53F4:NEAR
	PUBLIC L2028, L2052, L20AB, L2122, L2201, L2275
	PUBLIC L228D
ASSUME CS:CODE, DS:DATA
L2028:	nop	;@2028
	call L4F4D	;@2029
	cmp ah, 0FFh	;@202C
	jne L2028	;@202F
	cmp al, 30h	;@2031
	jb L2028	;@2033
	cmp al, 39h	;@2035
	ja L2028	;@2037
	stc	;@2039
	cmc	;@203A
	sbb al, 30h	;@203B
	cmc	;@203D
	mov ah, 0	;@203E
	mov di, ax	;@2040
	clc	;@2042
	adc al, 30h	;@2043
	call L53F4	;@2045
	mov al, 8Dh	;@2048
	call L53F4	;@204A
	mov ax, di	;@204D
	cmp al, 0	;@204F
	ret	;@2051
L2052:	nop	;@2052
	stc	;@2053
	mov al, byte ptr D_0059	;@2054
	cmc	;@2057
	sbb al, byte ptr D_0028	;@2058
	das	;@205C
	cmc	;@205D
	mov byte ptr D_0059, al	;@205E
	mov al, byte ptr D_0058	;@2061
	cmc	;@2064
	sbb al, byte ptr D_0027	;@2065
	das	;@2069
	cmc	;@206A
	mov byte ptr D_0058, al	;@206B
	jb L20A7	;@206E
	clc	;@2070
	mov al, byte ptr D_0059	;@2071
	adc al, byte ptr D_0028	;@2074
	daa	;@2078
	mov byte ptr D_0059, al	;@2079
	mov al, byte ptr D_0058	;@207C
	adc al, byte ptr D_0027	;@207F
	daa	;@2083
	mov byte ptr D_0058, al	;@2084
	pop ax	;@2087
	call L4FDF	;@2088
	db 59h,4Fh,55h,20h,44h,4Fh,4Eh,54h,20h,48h,41h,56h,45h,20h,54h,48h	;@208B
	db 41h,54h,20h,4Dh,55h,43h,48h,21h,0h	;@209B
	jmp L0A30	;@20A4
L20A7:	nop	;@20A7
	mov al, 0	;@20A8
	ret	;@20AA
L20AB:	nop	;@20AB
	clc	;@20AC
	adc al, 8	;@20AD
	mov byte ptr D_0020, al	;@20AF
	mov al, 0	;@20B2
	mov byte ptr D_0027, al	;@20B4
	mov byte ptr D_0029, al	;@20B7
	mov al, 4	;@20BA
	mov byte ptr D_0028, al	;@20BC
	mov byte ptr D_002A, al	;@20BF
	mov al, byte ptr D_0050	;@20C2
	adc al, byte ptr D_004E	;@20C5
	mov bh, 0	;@20C9
	mov bl, 0	;@20CB
	mov si, bx	;@20CD
L20CF:	inc si	;@20CF
	clc	;@20D0
	rcr al, 1	;@20D1
	or al, al	;@20D3
	jne L20CF	;@20D5
	mov al, byte ptr D_0020	;@20D7
	mov bx, si	;@20DA
	mov byte ptr D_0020, bl	;@20DC
	stc	;@20E0
	cmc	;@20E1
	sbb al, byte ptr D_0020	;@20E2
	cmc	;@20E6
	mov ah, 0	;@20E7
	mov di, ax	;@20E9
L20EB:	clc	;@20EB
	mov al, byte ptr D_002A	;@20EC
	adc al, byte ptr D_0028	;@20EF
	daa	;@20F3
	mov bh, 0	;@20F4
	mov bl, byte ptr D_0028	;@20F6
	mov si, bx	;@20FA
	mov bx, si	;@20FC
	mov byte ptr D_002A, bl	;@20FE
	mov byte ptr D_0028, al	;@2102
	mov al, byte ptr D_0029	;@2105
	adc al, byte ptr D_0027	;@2108
	daa	;@210C
	mov bh, 0	;@210D
	mov bl, byte ptr D_0027	;@210F
	mov si, bx	;@2113
	mov bx, si	;@2115
	mov byte ptr D_0029, bl	;@2117
	mov byte ptr D_0027, al	;@211B
	dec di	;@211E
	jne L20EB	;@211F
	ret	;@2121
L2122:	mov al, byte ptr D_0177[di]	;@2122
	cmp al, 10h	;@2126
	jae L212E	;@2128
	inc byte ptr D_0177[di]	;@212A
L212E:	clc	;@212E
	mov al, byte ptr D_0137[di]	;@212F
	adc al, byte ptr D_0019	;@2133
	and al, 3Fh	;@2137
	mov byte ptr D_0023, al	;@2139
	clc	;@213C
	mov al, byte ptr D_0157[di]	;@213D
	adc al, byte ptr D_001A	;@2141
	and al, 3Fh	;@2145
	mov byte ptr D_0024, al	;@2147
	call L50B3	;@214A
	call L2199	;@214D
	jne L2155	;@2150
	jmp L2201	;@2152
L2155:	mov al, byte ptr D_001A	;@2155
	cmp al, 0	;@2158
	je L216E	;@215A
	mov al, byte ptr D_0137[di]	;@215C
	mov byte ptr D_0023, al	;@2160
	call L50B3	;@2163
	call L2199	;@2166
	jne L216E	;@2169
	jmp L2201	;@216B
L216E:	clc	;@216E
	mov al, byte ptr D_0137[di]	;@216F
	adc al, byte ptr D_0019	;@2173
	and al, 3Fh	;@2177
	mov byte ptr D_0023, al	;@2179
	mov al, byte ptr D_0157[di]	;@217C
	mov byte ptr D_0024, al	;@2180
	call L50B3	;@2183
	call L2199	;@2186
	je L2201	;@2189
L218B:	mov al, byte ptr D_004A	;@218B
	cmp al, 0	;@218E
	je L2195	;@2190
	jmp L1040	;@2192
L2195:	nop	;@2195
	jmp L0AA1	;@2196
L2199:	mov byte ptr D_001F, al	;@2199
	mov al, byte ptr D_026A	;@219C
	cmp al, 0	;@219F
	je L21A6	;@21A1
	jmp L21FC	;@21A3
L21A6:	mov al, byte ptr D_0197[di]	;@21A6
	cmp al, 2Ch	;@21AA
	je L21D8	;@21AC
	cmp al, 48h	;@21AE
	je L21D8	;@21B0
	cmp al, 78h	;@21B2
	jae L21BD	;@21B4
	mov al, byte ptr D_001F	;@21B6
	cmp al, 5Ch	;@21B9
	je L21E2	;@21BB
L21BD:	nop	;@21BD
	mov al, byte ptr D_001F	;@21BE
	cmp al, 10h	;@21C1
	je L21FC	;@21C3
	cmp al, 4	;@21C5
	je L21FC	;@21C7
	cmp al, 0	;@21C9
	je L21FC	;@21CB
	cmp al, 14h	;@21CD
	jb L21E2	;@21CF
	cmp al, 70h	;@21D1
	je L21E2	;@21D3
	jmp L21FC	;@21D5
L21D8:	mov al, byte ptr D_001F	;@21D8
	cmp al, 0	;@21DB
	jne L21FC	;@21DD
	jmp L21E2	;@21DF
L21E2:	mov al, byte ptr D_004A	;@21E2
	cmp al, 0	;@21E5
	je L21F7	;@21E7
	mov al, byte ptr D_0023	;@21E9
	cmp al, 0	;@21EC
	je L21FC	;@21EE
	mov al, byte ptr D_0024	;@21F0
	cmp al, 0	;@21F3
	je L21FC	;@21F5
L21F7:	mov al, 0	;@21F7
	cmp al, 0	;@21F9
	ret	;@21FB
L21FC:	mov al, 0FFh	;@21FC
	cmp al, 0	;@21FE
	ret	;@2200
L2201:	mov al, byte ptr D_0000	;@2201
	cmp al, byte ptr D_0023	;@2204
	jne L2216	;@2208
	mov al, byte ptr D_0001	;@220A
	cmp al, byte ptr D_0024	;@220D
	jne L2216	;@2211
	jmp L218B	;@2213
L2216:	mov al, byte ptr D_0023	;@2216
	mov byte ptr D_0027, al	;@2219
	mov al, byte ptr D_0024	;@221C
	mov byte ptr D_0028, al	;@221F
	mov al, byte ptr D_0137[di]	;@2222
	mov byte ptr D_0023, al	;@2226
	mov al, byte ptr D_0157[di]	;@2229
	mov byte ptr D_0024, al	;@222D
	call L50B3	;@2230
	mov al, byte ptr D_01B7[di]	;@2233
	mov bh, 0	;@2237
	mov bl, 0	;@2239
	mov si, bx	;@223B
	mov bx, word ptr D_0006	;@223D
	mov byte ptr [bx+si], al	;@2241
	mov al, byte ptr D_0027	;@2243
	mov byte ptr D_0023, al	;@2246
	mov byte ptr D_0137[di], al	;@2249
	mov al, byte ptr D_0028	;@224D
	mov byte ptr D_0024, al	;@2250
	mov byte ptr D_0157[di], al	;@2253
	call L50B3	;@2257
	mov byte ptr D_01B7[di], al	;@225A
	mov al, byte ptr D_0197[di]	;@225E
	mov bx, word ptr D_0006	;@2262
	mov byte ptr [bx+si], al	;@2266
	mov al, byte ptr D_004A	;@2268
	cmp al, 0	;@226B
	je L2272	;@226D
	jmp L1040	;@226F
L2272:	jmp L0AA1	;@2272
L2275:	call L4FDF	;@2275
	db 2Dh,49h,4Ch,4Ch,45h,47h,41h,4Ch,20h,43h,4Fh,4Dh,4Dh,41h,4Eh,44h	;@2278
	db 21h,0h	;@2288
	jmp L0A30	;@228A
L228D:	jmp L0C62	;@228D
CODE ENDS
END
