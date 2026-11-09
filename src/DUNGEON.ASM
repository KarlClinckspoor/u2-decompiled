; DUNGEON.ASM: the dungeon and tower loop: advance, turn, retreat, traps.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 26F9-2B65.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0000:BYTE, D_0001:BYTE, D_0002:BYTE, D_0003:BYTE, D_0006:BYTE, D_0015:BYTE
	EXTRN D_0016:BYTE, D_0019:BYTE, D_001A:BYTE, D_001F:BYTE, D_0023:BYTE, D_0024:BYTE
	EXTRN D_0025:BYTE, D_0026:BYTE, D_0027:BYTE, D_0049:BYTE, D_0066:BYTE, D_006D:BYTE
	EXTRN D_006E:BYTE, D_006F:BYTE, D_0070:BYTE, D_026D:BYTE, D_026E:BYTE, D_026F:BYTE
	EXTRN D_0270:BYTE, D_0271:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L0711:NEAR, L09FB:NEAR, L0A30:NEAR, L0A33:NEAR, L0C62:NEAR, L2B65:NEAR
	EXTRN L4B4E:NEAR, L4F4D:NEAR, L4FDF:NEAR, L50B3:NEAR, L5217:NEAR, L5E3B:NEAR
	EXTRN L5EF2:NEAR
	PUBLIC L26F9, L2798, L27C0, L29D2
ASSUME CS:CODE, DS:DATA
L26F9:	mov al, byte ptr D_006D	;@26F9
	cmp al, 0	;@26FC
	je L2701	;@26FE
	ret	;@2700
L2701:	dec byte ptr D_006F	;@2701
	je L2708	;@2705
	ret	;@2707
L2708:	clc	;@2708
	mov al, byte ptr D_0049	;@2709
	add al, al	;@270C
	add al, al	;@270E
	add al, al	;@2710
	mov byte ptr D_001F, al	;@2712
	adc al, byte ptr D_006E	;@2715
	mov ah, 0	;@2719
	mov di, ax	;@271B
	mov al, byte ptr cs:L2798[di]	;@271D
	mov byte ptr D_0023, al	;@2722
	inc di	;@2725
	mov al, byte ptr cs:L2798[di]	;@2726
	mov byte ptr D_0024, al	;@272B
	call L50B3	;@272E
	cmp al, 0C0h	;@2731
	jne L2744	;@2733
	mov bh, 0	;@2735
	mov bl, 0	;@2737
	mov si, bx	;@2739
	mov al, byte ptr D_0070	;@273B
	mov bx, word ptr D_0006	;@273E
	mov byte ptr [bx+si], al	;@2742
L2744:	mov al, 8	;@2744
	mov byte ptr D_006F, al	;@2746
	inc byte ptr D_006E	;@2749
	inc byte ptr D_006E	;@274D
	mov al, byte ptr D_006E	;@2751
	and al, 7	;@2754
	mov byte ptr D_006E, al	;@2756
	clc	;@2759
	adc al, byte ptr D_001F	;@275A
	mov ah, 0	;@275E
	mov di, ax	;@2760
	mov al, byte ptr cs:L2798[di]	;@2762
	mov byte ptr D_0023, al	;@2767
	inc di	;@276A
	mov al, byte ptr cs:L2798[di]	;@276B
	mov byte ptr D_0024, al	;@2770
	call L50B3	;@2773
	cmp al, 14h	;@2776
	jb L277B	;@2778
	ret	;@277A
L277B:	mov byte ptr D_0070, al	;@277B
	mov bh, 0	;@277E
	mov bl, 0	;@2780
	mov si, bx	;@2782
	mov al, 0C0h	;@2784
	mov bx, word ptr D_0006	;@2786
	mov byte ptr [bx+si], al	;@278A
	mov al, byte ptr D_0023	;@278C
	mov bh, 0	;@278F
	mov bl, byte ptr D_0024	;@2791
	mov di, bx	;@2795
	ret	;@2797
L2798 label byte
	db 1Dh,38h,1Fh,38h,21h,38h,23h,38h,22h,8h,2Fh,1Ch,24h,38h,14h,25h	;@2798
	db 10h,10h,30h,18h,2Ah,18h,13h,34h,38h,34h,1Ch,0Ch,21h,17h,14h,34h	;@27A8
	db 12h,17h,32h,22h,34h,18h,8h,0Bh	;@27B8
L27C0:	nop	;@27C0
	mov al, byte ptr D_026D	;@27C1
	or al, al	;@27C4
	je L27F1	;@27C6
	call L4FDF	;@27C8
	db 43h,4Dh,44h,3Ah,20h,0h	;@27CB
	mov al, 14h	;@27D1
	mov byte ptr D_0027, al	;@27D3
L27D6:	call L4FDF	;@27D6
	db 5Ah,0h	;@27D9
	mov bh, 0	;@27DB
	mov bl, 0FFh	;@27DD
	mov di, bx	;@27DF
L27E1:	dec di	;@27E1
	jne L27E1	;@27E2
	dec byte ptr D_0027	;@27E4
	jne L27D6	;@27E8
	dec byte ptr D_026D	;@27EA
	jmp L0A33	;@27EE
L27F1:	nop	;@27F1
	call L4FDF	;@27F2
	db 43h,4Dh,44h,3Ah,20h,0h	;@27F5
	mov bh, 0	;@27FB
	mov bl, 0FFh	;@27FD
	mov di, bx	;@27FF
	mov bh, 0	;@2801
	mov bl, 2	;@2803
	mov si, bx	;@2805
L2807:	mov bx, 0	;@2807
	call L0711	;@280A
	call L4F4D	;@280D
	cmp ah, 0FFh	;@2810
	je L2832	;@2813
	push ax	;@2815
	pop ax	;@2816
	push ax	;@2817
	pop ax	;@2818
	push ax	;@2819
	pop ax	;@281A
	push ax	;@281B
	pop ax	;@281C
	push ax	;@281D
	pop ax	;@281E
	push ax	;@281F
	pop ax	;@2820
	dec di	;@2821
	jne L2807	;@2822
	dec si	;@2824
	jne L2807	;@2825
	call L4FDF	;@2827
	db 50h,41h,53h,53h,0h	;@282A
	jmp L0A33	;@282F
L2832:	nop	;@2832
	cmp al, byte ptr D_026E	;@2833
	jne L283C	;@2837
	jmp L2861	;@2839
L283C:	cmp al, byte ptr D_0271	;@283C
	jne L2845	;@2840
	jmp L2912	;@2842
L2845:	cmp al, byte ptr D_0270	;@2845
	jne L284E	;@2849
	jmp L2944	;@284B
L284E:	cmp al, byte ptr D_026F	;@284E
	jne L2857	;@2852
	jmp L2977	;@2854
L2857:	cmp al, 20h	;@2857
	jne L285E	;@2859
	jmp L29BC	;@285B
L285E:	jmp L09FB	;@285E
L2861:	nop	;@2861
	call L4FDF	;@2862
	db 41h,44h,56h,41h,4Eh,43h,45h,0h	;@2865
	mov al, byte ptr D_0015	;@286D
	and al, 0Fh	;@2870
	je L2884	;@2872
L2874:	call L4FDF	;@2874
	db 2Dh,42h,4Ch,4Fh,43h,4Bh,45h,44h,21h,0h	;@2877
	jmp L0A30	;@2881
L2884:	mov al, byte ptr D_0015	;@2884
	cmp al, 80h	;@2887
	je L2874	;@2889
	clc	;@288B
	mov al, byte ptr D_0000	;@288C
	adc al, byte ptr D_0002	;@288F
	and al, 3Fh	;@2893
	mov byte ptr D_0000, al	;@2895
	clc	;@2898
	mov al, byte ptr D_0001	;@2899
	adc al, byte ptr D_0003	;@289C
	and al, 3Fh	;@28A0
	mov byte ptr D_0001, al	;@28A2
	call L5217	;@28A5
	cmp al, byte ptr D_0025	;@28A8
	jb L28B1	;@28AC
	jmp L0A33	;@28AE
L28B1:	nop	;@28B1
	call L4B4E	;@28B2
	mov al, 0	;@28B5
	mov byte ptr D_0026, al	;@28B7
	call L4FDF	;@28BA
	db 8Dh,41h,52h,47h,48h,21h,20h,41h,20h,54h,52h,41h,50h,21h,8Dh,0h	;@28BD
	call L5E3B	;@28CD
	call L5EF2	;@28D0
	call L5EF2	;@28D3
	call L5EF2	;@28D6
	call L5EF2	;@28D9
	mov al, byte ptr D_0066	;@28DC
	or al, al	;@28DF
	jne L28E6	;@28E1
	jmp L0C62	;@28E3
L28E6:	call L4FDF	;@28E6
	db 45h,53h,43h,41h,50h,45h,44h,21h,20h,42h,59h,20h,55h,53h,45h,20h	;@28E9
	db 4Fh,46h,20h,54h,4Fh,4Fh,4Ch,53h,21h,0h	;@28F9
	stc	;@2903
	mov al, byte ptr D_0066	;@2904
	cmc	;@2907
	sbb al, 1	;@2908
	das	;@290A
	cmc	;@290B
	mov byte ptr D_0066, al	;@290C
	jmp L0A33	;@290F
L2912:	nop	;@2912
	call L4FDF	;@2913
	db 54h,55h,52h,4Eh,20h,4Ch,45h,46h,54h,0h	;@2916
	mov al, byte ptr D_0003	;@2920
	cmp al, 0	;@2923
	je L2932	;@2925
	mov byte ptr D_0002, al	;@2927
	mov al, 0	;@292A
	mov byte ptr D_0003, al	;@292C
	jmp L0A33	;@292F
L2932:	stc	;@2932
	cmc	;@2933
	sbb al, byte ptr D_0002	;@2934
	cmc	;@2938
	mov byte ptr D_0003, al	;@2939
	mov al, 0	;@293C
	mov byte ptr D_0002, al	;@293E
	jmp L0A33	;@2941
L2944:	nop	;@2944
	call L4FDF	;@2945
	db 54h,55h,52h,4Eh,20h,52h,49h,47h,48h,54h,0h	;@2948
	mov al, byte ptr D_0002	;@2953
	or al, al	;@2956
	je L2965	;@2958
	mov byte ptr D_0003, al	;@295A
	mov al, 0	;@295D
	mov byte ptr D_0002, al	;@295F
	jmp L0A33	;@2962
L2965:	stc	;@2965
	cmc	;@2966
	sbb al, byte ptr D_0003	;@2967
	cmc	;@296B
	mov byte ptr D_0002, al	;@296C
	mov al, 0	;@296F
	mov byte ptr D_0003, al	;@2971
	jmp L0A33	;@2974
L2977:	nop	;@2977
	call L4FDF	;@2978
	db 52h,45h,54h,52h,45h,41h,54h,0h	;@297B
	mov al, byte ptr D_0016	;@2983
	and al, 8Fh	;@2986
	je L299A	;@2988
	call L4FDF	;@298A
	db 2Dh,42h,4Ch,4Fh,43h,4Bh,45h,44h,21h,0h	;@298D
	jmp L0A30	;@2997
L299A:	nop	;@299A
	mov al, byte ptr D_0000	;@299B
	stc	;@299E
	cmc	;@299F
	sbb al, byte ptr D_0002	;@29A0
	cmc	;@29A4
	and al, 3Fh	;@29A5
	mov byte ptr D_0000, al	;@29A7
	mov al, byte ptr D_0001	;@29AA
	stc	;@29AD
	cmc	;@29AE
	sbb al, byte ptr D_0003	;@29AF
	cmc	;@29B3
	and al, 3Fh	;@29B4
	mov byte ptr D_0001, al	;@29B6
	jmp L0A33	;@29B9
L29BC:	call L4FDF	;@29BC
	db 50h,41h,53h,53h,0h	;@29BF
	jmp L0A33	;@29C4
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h	;@29C7
L29D0 label byte
	db 0h	;@29D0
L29D1 label byte
	db 0h	;@29D1
L29D2:	nop	;@29D2
	mov al, 0	;@29D3
	mov byte ptr cs:L29D0, al	;@29D5
	mov byte ptr cs:L29D1, al	;@29D9
	mov byte ptr D_0019, al	;@29DD
	mov byte ptr D_001A, al	;@29E0
	call L4B4E	;@29E3
L29E6:	mov al, byte ptr cs:L29D0	;@29E6
	clc	;@29EA
	adc al, byte ptr D_0019	;@29EB
	and al, 3Fh	;@29EF
	mov byte ptr D_0023, al	;@29F1
	mov al, byte ptr cs:L29D1	;@29F4
	clc	;@29F8
	adc al, byte ptr D_001A	;@29F9
	and al, 3Fh	;@29FD
	mov byte ptr D_0024, al	;@29FF
	call L50B3	;@2A02
	jne L2A0A	;@2A05
	jmp L2B46	;@2A07
L2A0A:	cmp al, 10h	;@2A0A
	je L2A2F	;@2A0C
	cmp al, 78h	;@2A0E
	jb L2A16	;@2A10
	cmp al, 0F0h	;@2A12
	jb L2A2F	;@2A14
L2A16:	cmp al, 8	;@2A16
	je L2A89	;@2A18
	cmp al, 0Ch	;@2A1A
	je L2A6B	;@2A1C
	cmp al, 4	;@2A1E
	je L2A29	;@2A20
	cmp al, 70h	;@2A22
	je L2A2C	;@2A24
	jmp L2B0A	;@2A26
L2A29:	jmp L2AAA	;@2A29
L2A2C:	jmp L2ACB	;@2A2C
L2A2F:	mov bh, 0	;@2A2F
	mov bl, 0	;@2A31
	mov di, bx	;@2A33
	mov bh, 0	;@2A35
	mov bl, 0	;@2A37
	mov si, bx	;@2A39
	call L2B65	;@2A3B
	mov bh, 0	;@2A3E
	mov bl, 0	;@2A40
	mov di, bx	;@2A42
	mov bh, 0	;@2A44
	mov bl, 1	;@2A46
	mov si, bx	;@2A48
	call L2B65	;@2A4A
	mov bh, 0	;@2A4D
	mov bl, 2	;@2A4F
	mov di, bx	;@2A51
	mov bh, 0	;@2A53
	mov bl, 1	;@2A55
	mov si, bx	;@2A57
	call L2B65	;@2A59
	mov bh, 0	;@2A5C
	mov bl, 2	;@2A5E
	mov di, bx	;@2A60
	mov bh, 0	;@2A62
	mov bl, 0	;@2A64
	mov si, bx	;@2A66
	call L2B65	;@2A68
L2A6B:	mov bh, 0	;@2A6B
	mov bl, 1	;@2A6D
	mov di, bx	;@2A6F
	mov bh, 0	;@2A71
	mov bl, 1	;@2A73
	mov si, bx	;@2A75
	call L2B65	;@2A77
	mov bh, 0	;@2A7A
	mov bl, 3	;@2A7C
	mov di, bx	;@2A7E
	mov bh, 0	;@2A80
	mov bl, 0	;@2A82
	mov si, bx	;@2A84
	call L2B65	;@2A86
L2A89:	mov bh, 0	;@2A89
	mov bl, 1	;@2A8B
	mov di, bx	;@2A8D
	mov bh, 0	;@2A8F
	mov bl, 0	;@2A91
	mov si, bx	;@2A93
	call L2B65	;@2A95
	mov bh, 0	;@2A98
	mov bl, 3	;@2A9A
	mov di, bx	;@2A9C
	mov bh, 0	;@2A9E
	mov bl, 1	;@2AA0
	mov si, bx	;@2AA2
	call L2B65	;@2AA4
	jmp L2B46	;@2AA7
L2AAA:	mov bh, 0	;@2AAA
	mov bl, 1	;@2AAC
	mov di, bx	;@2AAE
	mov bh, 0	;@2AB0
	mov bl, 0	;@2AB2
	mov si, bx	;@2AB4
	call L2B65	;@2AB6
	mov bh, 0	;@2AB9
	mov bl, 3	;@2ABB
	mov di, bx	;@2ABD
	mov bh, 0	;@2ABF
	mov bl, 0	;@2AC1
	mov si, bx	;@2AC3
	call L2B65	;@2AC5
	jmp L2B46	;@2AC8
L2ACB:	mov bh, 0	;@2ACB
	mov bl, 0	;@2ACD
	mov di, bx	;@2ACF
	mov bh, 0	;@2AD1
	mov bl, 0	;@2AD3
	mov si, bx	;@2AD5
	call L2B65	;@2AD7
	mov bh, 0	;@2ADA
	mov bl, 0	;@2ADC
	mov di, bx	;@2ADE
	mov bh, 0	;@2AE0
	mov bl, 1	;@2AE2
	mov si, bx	;@2AE4
	call L2B65	;@2AE6
	mov bh, 0	;@2AE9
	mov bl, 2	;@2AEB
	mov di, bx	;@2AED
	mov bh, 0	;@2AEF
	mov bl, 0	;@2AF1
	mov si, bx	;@2AF3
	call L2B65	;@2AF5
	mov bh, 0	;@2AF8
	mov bl, 2	;@2AFA
	mov di, bx	;@2AFC
	mov bh, 0	;@2AFE
	mov bl, 1	;@2B00
	mov si, bx	;@2B02
	call L2B65	;@2B04
	jmp L2B46	;@2B07
L2B0A:	mov bh, 0	;@2B0A
	mov bl, 1	;@2B0C
	mov di, bx	;@2B0E
	mov bh, 0	;@2B10
	mov bl, 0	;@2B12
	mov si, bx	;@2B14
	call L2B65	;@2B16
	mov bh, 0	;@2B19
	mov bl, 2	;@2B1B
	mov di, bx	;@2B1D
	mov bh, 0	;@2B1F
	mov bl, 0	;@2B21
	mov si, bx	;@2B23
	call L2B65	;@2B25
	mov bh, 0	;@2B28
	mov bl, 2	;@2B2A
	mov di, bx	;@2B2C
	mov bh, 0	;@2B2E
	mov bl, 1	;@2B30
	mov si, bx	;@2B32
	call L2B65	;@2B34
	mov bh, 0	;@2B37
	mov bl, 1	;@2B39
	mov di, bx	;@2B3B
	mov bh, 0	;@2B3D
	mov bl, 1	;@2B3F
	mov si, bx	;@2B41
	call L2B65	;@2B43
L2B46:	inc byte ptr D_0019	;@2B46
	mov al, byte ptr D_0019	;@2B4A
	and al, 3Fh	;@2B4D
	mov byte ptr D_0019, al	;@2B4F
	or al, al	;@2B52
	je L2B59	;@2B54
L2B56:	jmp L29E6	;@2B56
L2B59:	inc byte ptr D_001A	;@2B59
	mov al, byte ptr D_001A	;@2B5D
	cmp al, 40h	;@2B60
	jb L2B56	;@2B62
	ret	;@2B64
CODE ENDS
END
