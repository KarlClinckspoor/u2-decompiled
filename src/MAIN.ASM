; MAIN.ASM: command jump table (A-Z), game start, the outdoor main loop and movement.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 0730-0E70.
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
L0730:	dw L2B8F	;@0730
	dw L2F6F	;@0732
	dw L310B	;@0734
	dw L334D	;@0736
	dw L3389	;@0738
	dw L35C1	;@073A
	dw L363B	;@073C
	dw L3782	;@073E
	dw L3794	;@0740
	dw L37DC	;@0742
	dw L37F1	;@0744
	dw L38B0	;@0746
	dw L3B92	;@0748
	dw L3BCE	;@074A
	dw L3C2E	;@074C
	dw L3DBC	;@074E
	dw L3DC7	;@0750
	dw L3E50	;@0752
	dw L3F25	;@0754
	dw L4050	;@0756
	dw L42F1	;@0758
	dw L437E	;@075A
	dw L43F3	;@075C
	dw L44D4	;@075E
	dw L4542	;@0760
	dw L4568	;@0762
L0764:	call L4A1C	;@0764
	mov bh, 0	;@0767
	mov bl, 0Ch	;@0769
	mov si, bx	;@076B
	mov bh, 0	;@076D
	mov bl, 0Ah	;@076F
	mov di, bx	;@0771
	call L51EB	;@0773
	jmp short L0796	;@0776
	db 48h,28h,49h,4Eh,53h,45h,52h,54h,20h,50h,4Ch,41h,59h,45h,52h,20h	;@0778
	db 44h,49h,53h,4Bh,29h,0h,0E8h,0BCh,47h,3Dh,1Bh,0FFh,75h,0F8h	;@0788
L0796:	mov cx, 100h	;@0796
	lea dx, D_0036	;@0799
	mov ah, 27h	;@079D
	call L52CA	;@079F
	db 50h,4Ch,41h,59h,45h,52h,20h,20h	;@07A2
	mov al, byte ptr D_0036	;@07AA
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
	db 4Eh,4Fh,20h,43h,48h,41h,52h,41h,43h,54h,45h,52h,20h,4Fh,4Eh,20h	;@07C6
	db 44h,49h,53h,4Bh,0h	;@07D6
L07DB:	call L4F4D	;@07DB
	cmp ax, 0FF1Bh	;@07DE
	jne L07DB	;@07E1
	jmp L0764	;@07E3
L07E6:	cmp word ptr D_0074, 0	;@07E6
	jne L07F0	;@07EB
	call L06AC	;@07ED
L07F0:	call L06ED	;@07F0
	mov cx, 800h	;@07F3
	mov dx, word ptr D_0474	;@07F6
	mov ah, 27h	;@07FA
	call L52CA	;@07FC
	db 4Dh,4Fh,4Eh,53h,54h,45h,52h,53h	;@07FF
	call L2290	;@0807
	call L4A3E	;@080A
	mov al, byte ptr D_0047	;@080D
	add al, al	;@0810
	clc	;@0812
	adc al, 78h	;@0813
	mov byte ptr D_0013, al	;@0815
	mov al, 0	;@0818
	mov byte ptr D_026A, al	;@081A
	mov byte ptr D_026B, al	;@081D
	mov byte ptr D_026C, al	;@0820
	mov byte ptr D_026D, al	;@0823
	mov al, byte ptr D_005A	;@0826
	mov byte ptr D_0000, al	;@0829
	mov al, byte ptr D_005B	;@082C
	mov byte ptr D_0001, al	;@082F
	mov al, byte ptr D_0069	;@0832
	or al, al	;@0835
	je L0850	;@0837
	mov al, byte ptr D_006A	;@0839
	mov byte ptr D_0023, al	;@083C
	mov al, byte ptr D_006B	;@083F
	mov byte ptr D_0024, al	;@0842
	call L50B3	;@0845
	mov al, 50h	;@0848
	mov bx, word ptr D_0006	;@084A
	mov byte ptr [bx+si], al	;@084E
L0850:	nop	;@0850
	mov bh, 0	;@0851
	mov bl, 0FFh	;@0853
	mov di, bx	;@0855
	mov al, 0FFh	;@0857
L0859:	dec di	;@0859
	mov byte ptr D_0272[di], al	;@085A
	mov byte ptr D_0372[di], al	;@085E
	jne L0859	;@0862
	call L5AB1	;@0864
	mov al, 0FFh	;@0867
	mov byte ptr D_0012, al	;@0869
	call L50F9	;@086C
L086F:	nop	;@086F
	mov sp, 100h	;@0870
	mov al, byte ptr D_004A	;@0873
	cmp al, 4	;@0876
	jb L087D	;@0878
	jmp L27C0	;@087A
L087D:	nop	;@087D
	call L4FDF	;@087E
	db 43h,4Dh,44h,3Ah,20h,0h	;@0881
	call L4AE6	;@0887
	call L4AE6	;@088A
	call L4AE6	;@088D
	call L4AE6	;@0890
	call L4AF1	;@0893
	mov al, 0	;@0896
	mov byte ptr D_0021, al	;@0898
	mov al, 0C0h	;@089B
	mov byte ptr D_0022, al	;@089D
	mov al, byte ptr D_026D	;@08A0
	or al, al	;@08A3
	je L08C8	;@08A5
	mov al, 14h	;@08A7
	mov byte ptr D_0027, al	;@08A9
L08AC:	call L4FDF	;@08AC
	db 5Ah,0h	;@08AF
	mov bh, 0	;@08B1
	mov bl, 0FFh	;@08B3
	mov di, bx	;@08B5
L08B7:	dec di	;@08B7
	nop	;@08B8
	nop	;@08B9
	nop	;@08BA
	nop	;@08BB
	nop	;@08BC
	jne L08B7	;@08BD
	dec byte ptr D_0027	;@08BF
	jne L08AC	;@08C3
	jmp L0A33	;@08C5
L08C8:	mov bx, 0	;@08C8
	call L0711	;@08CB
	call L4F4D	;@08CE
	cmp ah, 0FFh	;@08D1
	je L0936	;@08D4
	inc byte ptr D_0021	;@08D6
	jne L08C8	;@08DA
	mov al, byte ptr D_0013	;@08DC
	cmp al, 26h	;@08DF
	jne L08E6	;@08E1
	call L5EC7	;@08E3
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
	mov byte ptr D_0026, al	;@0901
	call L4FDF	;@0904
	db 50h,41h,53h,53h,0h	;@0907
L090C:	stc	;@090C
	mov al, byte ptr D_0055	;@090D
	cmc	;@0910
	sbb al, 0Ah	;@0911
	das	;@0913
	cmc	;@0914
	mov byte ptr D_0055, al	;@0915
	mov al, byte ptr D_0054	;@0918
	cmc	;@091B
	sbb al, 0	;@091C
	das	;@091E
	cmc	;@091F
	mov byte ptr D_0054, al	;@0920
	mov al, byte ptr D_0053	;@0923
	cmc	;@0926
	sbb al, 0	;@0927
	das	;@0929
	cmc	;@092A
	mov byte ptr D_0053, al	;@092B
	jb L0933	;@092E
	jmp L228D	;@0930
L0933:	jmp L0A33	;@0933
L0936:	mov byte ptr D_005D, al	;@0936
	mov al, byte ptr D_005D	;@0939
	cmp al, 20h	;@093C
	jne L094F	;@093E
	mov al, 0	;@0940
	mov byte ptr D_0026, al	;@0942
	call L4FDF	;@0945
	db 50h,41h,53h,53h,0h	;@0948
	jmp L090C	;@094D
L094F:	cmp al, byte ptr D_026E	;@094F
	jne L0976	;@0953
	dec byte ptr D_0001	;@0955
	call L4FDF	;@0959
	db 4Eh,4Fh,52h,54h,48h,0h	;@095C
	mov al, byte ptr D_0015	;@0962
	call L2423	;@0965
	cmp al, 0	;@0968
	je L0973	;@096A
	inc byte ptr D_0001	;@096C
	jmp L0A02	;@0970
L0973:	jmp L09E9	;@0973
L0976:	cmp al, byte ptr D_026F	;@0976
	jne L099D	;@097A
	inc byte ptr D_0001	;@097C
	call L4FDF	;@0980
	db 53h,4Fh,55h,54h,48h,0h	;@0983
	mov al, byte ptr D_0016	;@0989
	call L2423	;@098C
	cmp al, 0	;@098F
	je L099A	;@0991
	dec byte ptr D_0001	;@0993
	jmp L0A02	;@0997
L099A:	jmp L09E9	;@099A
L099D:	cmp al, byte ptr D_0271	;@099D
	jne L09C3	;@09A1
	dec byte ptr D_0000	;@09A3
	call L4FDF	;@09A7
	db 57h,45h,53h,54h,0h	;@09AA
	mov al, byte ptr D_0018	;@09AF
	call L2423	;@09B2
	cmp al, 0	;@09B5
	je L09C0	;@09B7
	inc byte ptr D_0000	;@09B9
	jmp L0A02	;@09BD
L09C0:	jmp L09E9	;@09C0
L09C3:	cmp al, byte ptr D_0270	;@09C3
	jne L09F4	;@09C7
	inc byte ptr D_0000	;@09C9
	call L4FDF	;@09CD
	db 45h,41h,53h,54h,0h	;@09D0
	mov al, byte ptr D_0017	;@09D5
	call L2423	;@09D8
	cmp al, 0	;@09DB
	je L09E6	;@09DD
	dec byte ptr D_0000	;@09DF
	jmp L0A02	;@09E3
L09E6:	jmp L09E9	;@09E6
L09E9:	mov al, byte ptr D_0026	;@09E9
	xor al, 0FFh	;@09EC
	mov byte ptr D_0026, al	;@09EE
	jmp L0A33	;@09F1
L09F4:	push ax	;@09F4
	mov al, 0	;@09F5
	mov byte ptr D_0026, al	;@09F7
	pop ax	;@09FA
L09FB:	cmp al, 41h	;@09FB
	jae L0A18	;@09FD
	jmp L2275	;@09FF
L0A02:	call L4FDF	;@0A02
	db 2Dh,2Dh,49h,4Eh,56h,41h,4Ch,49h,44h,20h,4Dh,4Fh,56h,45h,21h,0h	;@0A05
	jmp L0A30	;@0A15
L0A18:	cmp al, 5Ah	;@0A18
	jbe L0A1F	;@0A1A
	jmp L2275	;@0A1C
L0A1F:	stc	;@0A1F
	cmc	;@0A20
	sbb al, 41h	;@0A21
	add al, al	;@0A23
	mov ah, 0	;@0A25
	mov si, ax	;@0A27
	mov bx, word ptr cs:L0730[si]	;@0A29
	jmp bx	;@0A2E
L0A30:	call L5C95	;@0A30
L0A33:	mov al, 0Dh	;@0A33
	call L53F4	;@0A35
	mov al, 0	;@0A38
	mov byte ptr D_0022, al	;@0A3A
	mov byte ptr D_0020, al	;@0A3D
	mov byte ptr D_0021, al	;@0A40
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
L0A6D:	nop	;@0A6D
	mov bh, 0	;@0A6E
	mov bl, 1Fh	;@0A70
	mov di, bx	;@0A72
L0A74:	mov al, byte ptr D_0197[di]	;@0A74
	or al, al	;@0A78
	je L0AA1	;@0A7A
	mov al, byte ptr D_0013	;@0A7C
	cmp al, 22h	;@0A7F
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
	mov al, byte ptr D_0013	;@0A9A
	cmp al, 22h	;@0A9D
	jne L0AA7	;@0A9F
L0AA1:	dec di	;@0AA1
	jne L0A74	;@0AA2
	jmp L0C9C	;@0AA4
L0AA7:	call L4F36	;@0AA7
	mov bx, di	;@0AAA
	mov byte ptr D_0029, bl	;@0AAC
	mov al, byte ptr D_0019	;@0AB0
	call L50EF	;@0AB3
	cmp al, 3	;@0AB6
	jae L0AFC	;@0AB8
	mov al, byte ptr D_001A	;@0ABA
	call L50EF	;@0ABD
	cmp al, 3	;@0AC0
	jae L0AFC	;@0AC2
	call L5217	;@0AC4
	mov bh, 0	;@0AC7
	mov bl, byte ptr D_0029	;@0AC9
	mov di, bx	;@0ACD
	cmp al, 20h	;@0ACF
	jae L0AFC	;@0AD1
	mov al, byte ptr D_0197[di]	;@0AD3
	cmp al, 34h	;@0AD7
	jne L0AE1	;@0AD9
	call L0E70	;@0ADB
	jmp L0AFC	;@0ADE
L0AE1:	cmp al, 38h	;@0AE1
	jne L0AEB	;@0AE3
	call L0EC2	;@0AE5
	jmp L0AFC	;@0AE8
L0AEB:	cmp al, 0F8h	;@0AEB
	jne L0AF5	;@0AED
	call L0F12	;@0AEF
	jmp L0AFC	;@0AF2
L0AF5:	cmp al, 3Ch	;@0AF5
	jne L0AFC	;@0AF7
	call L0F48	;@0AF9
L0AFC:	mov bh, 0	;@0AFC
	mov bl, byte ptr D_0029	;@0AFE
	mov di, bx	;@0B02
	call L4F11	;@0B04
	mov al, byte ptr D_0177[di]	;@0B07
	cmp al, 0Fh	;@0B0B
	jae L0B25	;@0B0D
	stc	;@0B0F
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
	mov al, byte ptr D_0137[di]	;@0B26
	adc al, byte ptr D_0019	;@0B2A
	and al, 3Fh	;@0B2E
	cmp al, byte ptr D_0000	;@0B30
	je L0B39	;@0B34
	jmp L2122	;@0B36
L0B39:	clc	;@0B39
	mov al, byte ptr D_0157[di]	;@0B3A
	adc al, byte ptr D_001A	;@0B3E
	and al, 3Fh	;@0B42
	cmp al, byte ptr D_0001	;@0B44
	je L0B4D	;@0B48
	jmp L2122	;@0B4A
L0B4D:	inc byte ptr D_0020	;@0B4D
	mov bx, di	;@0B51
	mov byte ptr D_0027, bl	;@0B53
	mov al, byte ptr D_0197[di]	;@0B57
	cmp al, 0FCh	;@0B5B
	jne L0B62	;@0B5D
	call L0FCD	;@0B5F
L0B62:	call L5217	;@0B62
	mov bh, 0	;@0B65
	mov bl, byte ptr D_0027	;@0B67
	mov di, bx	;@0B6B
	cmp al, 0	;@0B6D
	js L0BA0	;@0B6F
	and al, 7	;@0B71
	cmp al, byte ptr D_0062	;@0B73
	jb L0BA0	;@0B77
	inc byte ptr D_0021	;@0B79
	mov al, byte ptr D_0177[di]	;@0B7D
	clc	;@0B81
	rcr al, 1	;@0B82
	clc	;@0B84
	rcr al, 1	;@0B85
	stc	;@0B87
	adc al, byte ptr D_0022	;@0B88
	mov bh, 0	;@0B8C
	mov bl, byte ptr D_0014	;@0B8E
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
	jmp L1040	;@0BA8
L0BAB:	nop	;@0BAB
	jmp L0AA1	;@0BAC
L0BAF:	call L5AB1	;@0BAF
L0BB2:	mov al, byte ptr D_0020	;@0BB2
	or al, al	;@0BB5
	je L0BD1	;@0BB7
	call L5EAC	;@0BB9
	dec byte ptr D_0020	;@0BBC
	dec byte ptr D_0021	;@0BC0
	js L0BB2	;@0BC4
	call L5255	;@0BC6
	call L5EF2	;@0BC9
	call L5255	;@0BCC
	jmp L0BB2	;@0BCF
L0BD1:	mov al, byte ptr D_0022	;@0BD1
	or al, al	;@0BD4
	je L0C1C	;@0BD6
	call L5217	;@0BD8
	and al, byte ptr D_0022	;@0BDB
	and al, 77h	;@0BDF
	clc	;@0BE1
	adc al, 1	;@0BE2
	mov byte ptr D_0022, al	;@0BE4
	stc	;@0BE7
	mov al, byte ptr D_0052	;@0BE8
	cmc	;@0BEB
	sbb al, byte ptr D_0022	;@0BEC
	das	;@0BF0
	cmc	;@0BF1
	mov byte ptr D_0052, al	;@0BF2
	mov al, byte ptr D_0051	;@0BF5
	cmc	;@0BF8
	sbb al, 0	;@0BF9
	das	;@0BFB
	cmc	;@0BFC
	mov byte ptr D_0051, al	;@0BFD
	jae L0C62	;@0C00
	mov al, byte ptr D_004A	;@0C02
	or al, al	;@0C05
	je L0C1C	;@0C07
	mov byte ptr D_0022, al	;@0C09
	stc	;@0C0C
	mov al, byte ptr D_0051	;@0C0D
	cmc	;@0C10
	sbb al, byte ptr D_0022	;@0C11
	das	;@0C15
	cmc	;@0C16
	mov byte ptr D_0051, al	;@0C17
	jae L0C62	;@0C1A
L0C1C:	call L50F9	;@0C1C
	mov al, 4	;@0C1F
	mov byte ptr D_0012, al	;@0C21
	mov al, byte ptr D_004A	;@0C24
	or al, al	;@0C27
	jne L0C33	;@0C29
	mov al, 0FFh	;@0C2B
	mov byte ptr D_0012, al	;@0C2D
	call L26F9	;@0C30
L0C33:	mov al, byte ptr D_026B	;@0C33
	or al, al	;@0C36
	je L0C3E	;@0C38
	dec byte ptr D_026B	;@0C3A
L0C3E:	mov al, byte ptr D_026C	;@0C3E
	or al, al	;@0C41
	je L0C49	;@0C43
	dec byte ptr D_026C	;@0C45
L0C49:	mov al, byte ptr D_026D	;@0C49
	or al, al	;@0C4C
	je L0C54	;@0C4E
	dec byte ptr D_026D	;@0C50
L0C54:	mov al, byte ptr D_026A	;@0C54
	or al, al	;@0C57
	je L0C5F	;@0C59
	dec byte ptr D_026A	;@0C5B
L0C5F:	jmp L086F	;@0C5F
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
	db 8Dh,8Dh,8Dh,0h	;@0C85
	call L507A	;@0C89
	call L4FDF	;@0C8C
	db 20h,49h,53h,20h,44h,45h,41h,44h,21h,8Dh,0h	;@0C8F
L0C9A:	jmp L0C9A	;@0C9A
L0C9C:	mov bh, 0	;@0C9C
	mov bl, 1Fh	;@0C9E
	mov di, bx	;@0CA0
L0CA2:	mov al, byte ptr D_0197[di]	;@0CA2
	or al, al	;@0CA6
	je L0CB0	;@0CA8
	dec di	;@0CAA
	jne L0CA2	;@0CAB
	jmp L0BAF	;@0CAD
L0CB0:	mov bx, di	;@0CB0
	mov byte ptr D_001F, bl	;@0CB2
	call L5217	;@0CB6
	cmp al, 3Fh	;@0CB9
	jb L0CC0	;@0CBB
	jmp L0BAF	;@0CBD
L0CC0:	mov bh, 0	;@0CC0
	mov bl, byte ptr D_001F	;@0CC2
	mov di, bx	;@0CC6
	mov byte ptr D_0137[di], al	;@0CC8
	mov byte ptr D_0023, al	;@0CCC
	call L5217	;@0CCF
	js L0CD9	;@0CD2
	and al, 3Fh	;@0CD4
	jmp L0CDC	;@0CD6
L0CD9:	jmp L0BAF	;@0CD9
L0CDC:	mov bh, 0	;@0CDC
	mov bl, byte ptr D_001F	;@0CDE
	mov di, bx	;@0CE2
	mov byte ptr D_0157[di], al	;@0CE4
	mov byte ptr D_0024, al	;@0CE8
	call L50B3	;@0CEB
	mov bh, 0	;@0CEE
	mov bl, byte ptr D_001F	;@0CF0
	mov di, bx	;@0CF4
	mov byte ptr D_01B7[di], al	;@0CF6
	inc byte ptr D_0060	;@0CFA
	mov al, byte ptr D_0060	;@0CFE
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
L0D41:	jmp L0E50	;@0D41
L0D44:	mov al, byte ptr D_01B7[di]	;@0D44
	cmp al, 8	;@0D48
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
L0D6F:	mov al, 0FCh	;@0D6F
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
	cmp al, 0	;@0DA8
	je L0DAF	;@0DAA
	jmp L0DC4	;@0DAC
L0DAF:	mov al, 2Ch	;@0DAF
	mov bx, word ptr D_0006	;@0DB1
	mov byte ptr [bx+si], al	;@0DB5
	mov byte ptr D_0197[di], al	;@0DB7
	mov al, 40h	;@0DBB
	mov byte ptr D_0177[di], al	;@0DBD
	jmp L0BAF	;@0DC1
L0DC4:	dec byte ptr D_0060	;@0DC4
	jmp L0BAF	;@0DC8
L0DCB:	jmp L0DF3	;@0DCB
L0DCE:	jmp L0E12	;@0DCE
L0DD1:	jmp L0E31	;@0DD1
L0DD4:	mov al, byte ptr D_01B7[di]	;@0DD4
	cmp al, 8	;@0DD8
	je L0DDE	;@0DDA
	jmp L0DC4	;@0DDC
L0DDE:	mov al, 0F0h	;@0DDE
	mov bx, word ptr D_0006	;@0DE0
	mov byte ptr [bx+si], al	;@0DE4
	mov byte ptr D_0197[di], al	;@0DE6
	mov al, 80h	;@0DEA
	mov byte ptr D_0177[di], al	;@0DEC
	jmp L0BAF	;@0DF0
L0DF3:	mov al, byte ptr D_01B7[di]	;@0DF3
	cmp al, 0	;@0DF7
	je L0DFD	;@0DF9
	jmp L0DC4	;@0DFB
L0DFD:	mov al, 48h	;@0DFD
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
L0E3B:	mov al, 0F8h	;@0E3B
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
