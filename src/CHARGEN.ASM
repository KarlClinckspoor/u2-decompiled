; CHARGEN.ASM: character generation.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); original addresses 5400-5AB1.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	EXTRN D_0029:BYTE, D_002A:BYTE, D_0036:BYTE, D_0046:BYTE, D_0047:BYTE, D_0048:BYTE
	EXTRN D_0049:BYTE, D_004B:BYTE, D_004C:BYTE, D_004D:BYTE, D_004E:BYTE, D_004F:BYTE
	EXTRN D_0050:BYTE, D_0051:BYTE, D_0053:BYTE, D_0058:BYTE, D_005A:BYTE, D_005B:BYTE
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA

CODE SEGMENT BYTE PUBLIC
	EXTRN L0100:NEAR, L4A1C:NEAR, L4FDF:NEAR, L5003:NEAR, L51B0:NEAR, L51EB:NEAR
	EXTRN L52CA:NEAR, L53B5:NEAR, L53D0:NEAR, L53D9:NEAR, L53DF:NEAR
	PUBLIC L5400, L5AB0
ASSUME CS:CODE, DS:DATA
L5400:	call L4A1C	;@5400
	mov bh, 0	;@5403
	mov bl, 6	;@5405
	mov di, bx	;@5407
	mov bh, 0	;@5409
	mov bl, 0Ch	;@540B
	mov si, bx	;@540D
	call L51EB	;@540F
	jmp short L543B	;@5412
	db 0FBh,28h,49h,4Eh,53h,45h,52h,54h,20h,41h,20h,42h,4Ch,41h,4Eh,4Bh	;@5414
	db 20h,50h,4Ch,41h,59h,45h,52h,20h,44h,49h,53h,4Bh,29h,0Dh,0h,0E8h	;@5424
	db 17h,0FBh,3Dh,1Bh,0FFh,75h,0F8h	;@5434
L543B:	mov ah, 27h	;@543B
	mov cx, 100h	;@543D
	lea dx, D_0036	;@5440
	call L52CA	;@5444
	db 50h,4Ch,41h,59h,45h,52h,20h,20h	;@5447
	cmp byte ptr D_0036, 0	;@544F
	je L5498	;@5454
	call L4A1C	;@5456
	mov bh, 0	;@5459
	mov bl, 0Bh	;@545B
	mov si, bx	;@545D
	mov bh, 0	;@545F
	mov bl, 0Eh	;@5461
	mov di, bx	;@5463
	call L51EB	;@5465
	call L4FDF	;@5468
	db 4Eh,4Fh,54h,20h,41h,20h,42h,4Ch,41h,4Eh,4Bh,0h	;@546B
	mov bh, 0	;@5477
	mov bl, 0Dh	;@5479
	mov si, bx	;@547B
	mov bh, 0	;@547D
	mov bl, 0Eh	;@547F
	mov di, bx	;@5481
	call L51EB	;@5483
	call L4FDF	;@5486
	db 50h,4Ch,41h,59h,45h,52h,20h,44h,49h,53h,4Bh,0h	;@5489
	jmp L5A64	;@5495
L5498:	call L4A1C	;@5498
	call L4FDF	;@549B
	db 20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,50h,4Ch,41h,59h,45h,52h	;@549E
	db 20h,47h,45h,4Eh,45h,52h,41h,54h,49h,4Fh,4Eh,20h,3Ah,0h	;@54AE
	call L4FDF	;@54BC
	db 0Dh,0Ah,20h,20h,20h,20h,20h,50h,4Fh,49h,4Eh,54h,53h,20h,4Ch,45h	;@54BF
	db 46h,54h,20h,54h,4Fh,20h,44h,49h,53h,54h,52h,49h,42h,55h,54h,45h	;@54CF
	db 20h,3Ah,20h,0h	;@54DF
	call L53DF	;@54E3
	mov al, 90h	;@54E6
	mov byte ptr D_0029, al	;@54E8
	call L53B5	;@54EB
	call L53D9	;@54EE
	call L4FDF	;@54F1
	db 0Dh,0Ah,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,53h,54h,52h	;@54F4
	db 45h,4Eh,47h,54h,48h,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,0Dh,20h,20h,20h	;@5504
	db 20h,20h,20h,20h,20h,20h,20h,20h,41h,47h,49h,4Ch,49h,54h,59h,2Eh	;@5514
	db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,0Dh,20h,20h,20h,20h,20h,20h,20h,20h	;@5524
	db 20h,20h,20h,53h,54h,41h,4Dh,49h,4Eh,41h,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh	;@5534
	db 2Eh,2Eh,0Dh,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,43h,48h	;@5544
	db 41h,52h,49h,53h,4Dh,41h,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,0Dh,20h,20h	;@5554
	db 20h,20h,20h,20h,20h,20h,20h,20h,20h,57h,49h,53h,44h,4Fh,4Dh,2Eh	;@5564
	db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,0Dh,20h,20h,20h,20h,20h,20h,20h	;@5574
	db 20h,20h,20h,20h,49h,4Eh,54h,45h,4Ch,4Ch,49h,47h,45h,4Eh,43h,45h	;@5584
	db 2Eh,2Eh,2Eh,0Dh,0Ah,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h	;@5594
	db 20h,20h,20h,20h,20h,4Dh,2Fh,46h,2Dh,0Dh,20h,20h,20h,20h,20h,20h	;@55A4
	db 20h,20h,20h,20h,20h,20h,20h,20h,20h,52h,41h,43h,45h,2Dh,0Dh,20h	;@55B4
	db 20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,54h,59h	;@55C4
	db 50h,45h,2Dh,0Dh,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h	;@55D4
	db 20h,20h,20h,4Eh,41h,4Dh,45h,2Dh,0Dh,0Ah,20h,20h,20h,20h,20h,20h	;@55E4
	db 20h,20h,20h,20h,53h,41h,54h,49h,53h,46h,41h,43h,54h,4Fh,52h,59h	;@55F4
	db 20h,28h,59h,2Fh,4Eh,29h,2Dh,0Dh,0Ah,20h,20h,20h,20h,20h,20h,20h	;@5604
	db 20h,52h,41h,43h,45h,53h,3Ah,20h,20h,20h,20h,20h,20h,20h,20h,20h	;@5614
	db 54h,59h,50h,45h,53h,3Ah,0Dh,20h,20h,20h,20h,20h,20h,20h,20h,20h	;@5624
	db 31h,2Dh,48h,55h,4Dh,41h,4Eh,20h,20h,20h,20h,20h,20h,20h,20h,31h	;@5634
	db 2Dh,46h,49h,47h,48h,54h,45h,52h,0Dh,20h,20h,20h,20h,20h,20h,20h	;@5644
	db 20h,20h,32h,2Dh,45h,4Ch,46h,20h,20h,20h,20h,20h,20h,20h,20h,20h	;@5654
	db 20h,32h,2Dh,43h,4Ch,45h,52h,49h,43h,0Dh,20h,20h,20h,20h,20h,20h	;@5664
	db 20h,20h,20h,33h,2Dh,44h,57h,41h,52h,46h,20h,20h,20h,20h,20h,20h	;@5674
	db 20h,20h,33h,2Dh,57h,49h,5Ah,41h,52h,44h,0Dh,20h,20h,20h,20h,20h	;@5684
	db 20h,20h,20h,20h,34h,2Dh,48h,4Fh,42h,42h,49h,54h,20h,20h,20h,20h	;@5694
	db 20h,20h,20h,34h,2Dh,54h,48h,49h,45h,46h,0h	;@56A4
	mov bh, 0	;@56AF
	mov bl, 4	;@56B1
	mov si, bx	;@56B3
	mov bh, 0	;@56B5
	mov bl, 1Ah	;@56B7
	mov di, bx	;@56B9
	call L51EB	;@56BB
	call L51B0	;@56BE
	mov byte ptr D_004B, al	;@56C1
	call L5A66	;@56C4
	mov bh, 0	;@56C7
	mov bl, 5	;@56C9
	mov si, bx	;@56CB
	mov bh, 0	;@56CD
	mov bl, 1Ah	;@56CF
	mov di, bx	;@56D1
	call L51EB	;@56D3
	call L51B0	;@56D6
	mov byte ptr D_004C, al	;@56D9
	call L5A66	;@56DC
	mov bh, 0	;@56DF
	mov bl, 1Ah	;@56E1
	mov di, bx	;@56E3
	mov bh, 0	;@56E5
	mov bl, 6	;@56E7
	mov si, bx	;@56E9
	call L51EB	;@56EB
	call L51B0	;@56EE
	mov byte ptr D_004D, al	;@56F1
	call L5A66	;@56F4
	mov bh, 0	;@56F7
	mov bl, 7	;@56F9
	mov si, bx	;@56FB
	mov bh, 0	;@56FD
	mov bl, 1Ah	;@56FF
	mov di, bx	;@5701
	call L51EB	;@5703
	call L51B0	;@5706
	mov byte ptr D_004E, al	;@5709
	call L5A66	;@570C
	mov bh, 0	;@570F
	mov bl, 1Ah	;@5711
	mov di, bx	;@5713
	mov bh, 0	;@5715
	mov bl, 8	;@5717
	mov si, bx	;@5719
	call L51EB	;@571B
	call L51B0	;@571E
	mov byte ptr D_004F, al	;@5721
	call L5A66	;@5724
	mov bh, 0	;@5727
	mov bl, 1Ah	;@5729
	mov di, bx	;@572B
	mov bh, 0	;@572D
	mov bl, 9	;@572F
	mov si, bx	;@5731
	call L51EB	;@5733
	call L51B0	;@5736
	mov byte ptr D_0050, al	;@5739
	call L5A66	;@573C
	mov bh, 0	;@573F
	mov bl, 14h	;@5741
	mov di, bx	;@5743
	mov bh, 0	;@5745
	mov bl, 0Bh	;@5747
	mov si, bx	;@5749
	call L51EB	;@574B
L574E:	call L53D0	;@574E
	mov byte ptr D_0046, al	;@5751
	cmp al, 4Dh	;@5754
	jne L5781	;@5756
	call L4FDF	;@5758
	db 4Dh,41h,4Ch,45h,0h	;@575B
	mov al, byte ptr D_004B	;@5760
	add al, 5	;@5763
	daa	;@5765
	mov byte ptr D_004B, al	;@5766
	mov bh, 0	;@5769
	mov bl, 1Ah	;@576B
	mov di, bx	;@576D
	mov bh, 0	;@576F
	mov bl, 4	;@5771
	mov si, bx	;@5773
	call L51EB	;@5775
	mov al, byte ptr D_004B	;@5778
	call L53B5	;@577B
	jmp L57AD	;@577E
L5781:	cmp al, 46h	;@5781
	jne L574E	;@5783
	call L4FDF	;@5785
	db 46h,45h,4Dh,41h,4Ch,45h,0h	;@5788
	mov al, byte ptr D_004E	;@578F
	add al, 10h	;@5792
	daa	;@5794
	mov byte ptr D_004E, al	;@5795
	mov bh, 0	;@5798
	mov bl, 1Ah	;@579A
	mov di, bx	;@579C
	mov bh, 0	;@579E
	mov bl, 7	;@57A0
	mov si, bx	;@57A2
	call L51EB	;@57A4
	mov al, byte ptr D_004E	;@57A7
	call L53B5	;@57AA
L57AD:	mov bh, 0	;@57AD
	mov bl, 14h	;@57AF
	mov di, bx	;@57B1
	mov bh, 0	;@57B3
	mov bl, 0Ch	;@57B5
	mov si, bx	;@57B7
	call L51EB	;@57B9
	call L53D0	;@57BC
	mov byte ptr D_0048, al	;@57BF
	cmp al, 31h	;@57C2
	jne L57F0	;@57C4
	call L4FDF	;@57C6
	db 48h,55h,4Dh,41h,4Eh,0h	;@57C9
	mov al, byte ptr D_0050	;@57CF
	add al, 5	;@57D2
	daa	;@57D4
	mov byte ptr D_0050, al	;@57D5
	mov bh, 0	;@57D8
	mov bl, 1Ah	;@57DA
	mov di, bx	;@57DC
	mov bh, 0	;@57DE
	mov bl, 9	;@57E0
	mov si, bx	;@57E2
	call L51EB	;@57E4
	mov al, byte ptr D_0050	;@57E7
	call L53B5	;@57EA
	jmp L5879	;@57ED
L57F0:	cmp al, 32h	;@57F0
	jne L581C	;@57F2
	call L4FDF	;@57F4
	db 45h,4Ch,46h,0h	;@57F7
	mov al, byte ptr D_004C	;@57FB
	add al, 5	;@57FE
	daa	;@5800
	mov byte ptr D_004C, al	;@5801
	mov bh, 0	;@5804
	mov bl, 1Ah	;@5806
	mov di, bx	;@5808
	mov bh, 0	;@580A
	mov bl, 5	;@580C
	mov si, bx	;@580E
	call L51EB	;@5810
	mov al, byte ptr D_004C	;@5813
	call L53B5	;@5816
	jmp L5879	;@5819
L581C:	cmp al, 33h	;@581C
	jne L584A	;@581E
	call L4FDF	;@5820
	db 44h,57h,41h,52h,46h,0h	;@5823
	mov al, byte ptr D_004B	;@5829
	add al, 5	;@582C
	daa	;@582E
	mov byte ptr D_004B, al	;@582F
	mov bh, 0	;@5832
	mov bl, 1Ah	;@5834
	mov di, bx	;@5836
	mov bh, 0	;@5838
	mov bl, 4	;@583A
	mov si, bx	;@583C
	call L51EB	;@583E
	mov al, byte ptr D_004B	;@5841
	call L53B5	;@5844
	jmp L5879	;@5847
L584A:	cmp al, 34h	;@584A
	je L5851	;@584C
	jmp L57AD	;@584E
L5851:	call L4FDF	;@5851
	db 48h,4Fh,42h,42h,49h,54h,0h	;@5854
	mov al, byte ptr D_004F	;@585B
	add al, 10h	;@585E
	daa	;@5860
	mov byte ptr D_004F, al	;@5861
	mov bh, 0	;@5864
	mov bl, 1Ah	;@5866
	mov di, bx	;@5868
	mov bh, 0	;@586A
	mov bl, 8	;@586C
	mov si, bx	;@586E
	call L51EB	;@5870
	mov al, byte ptr D_004F	;@5873
	call L53B5	;@5876
L5879:	clc	;@5879
	mov al, byte ptr D_0048	;@587A
	sub al, 31h	;@587D
	mov byte ptr D_0048, al	;@587F
	mov bh, 0	;@5882
	mov bl, 0Dh	;@5884
	mov si, bx	;@5886
	mov bh, 0	;@5888
	mov bl, 14h	;@588A
	mov di, bx	;@588C
	call L51EB	;@588E
	call L53D0	;@5891
	mov byte ptr D_0047, al	;@5894
	cmp al, 31h	;@5897
	jne L58C7	;@5899
	call L4FDF	;@589B
	db 46h,49h,47h,48h,54h,45h,52h,0h	;@589E
	mov al, byte ptr D_004B	;@58A6
	add al, 15h	;@58A9
	daa	;@58AB
	mov byte ptr D_004B, al	;@58AC
	mov bh, 0	;@58AF
	mov bl, 1Ah	;@58B1
	mov di, bx	;@58B3
	mov bh, 0	;@58B5
	mov bl, 4	;@58B7
	mov si, bx	;@58B9
	call L51EB	;@58BB
	mov al, byte ptr D_004B	;@58BE
	call L53B5	;@58C1
	jmp L5953	;@58C4
L58C7:	cmp al, 32h	;@58C7
	jne L58F6	;@58C9
	call L4FDF	;@58CB
	db 43h,4Ch,45h,52h,49h,43h,0h	;@58CE
	mov al, byte ptr D_004F	;@58D5
	add al, 10h	;@58D8
	daa	;@58DA
	mov byte ptr D_004F, al	;@58DB
	mov bh, 0	;@58DE
	mov bl, 1Ah	;@58E0
	mov di, bx	;@58E2
	mov bh, 0	;@58E4
	mov bl, 8	;@58E6
	mov si, bx	;@58E8
	call L51EB	;@58EA
	mov al, byte ptr D_004F	;@58ED
	call L53B5	;@58F0
	jmp L5953	;@58F3
L58F6:	cmp al, 33h	;@58F6
	jne L5925	;@58F8
	call L4FDF	;@58FA
	db 57h,49h,5Ah,41h,52h,44h,0h	;@58FD
	mov al, byte ptr D_0050	;@5904
	add al, 10h	;@5907
	daa	;@5909
	mov byte ptr D_0050, al	;@590A
	mov bh, 0	;@590D
	mov bl, 1Ah	;@590F
	mov di, bx	;@5911
	mov bh, 0	;@5913
	mov bl, 9	;@5915
	mov si, bx	;@5917
	call L51EB	;@5919
	mov al, byte ptr D_0050	;@591C
	call L53B5	;@591F
	jmp L5953	;@5922
L5925:	cmp al, 34h	;@5925
	je L592C	;@5927
	jmp L5879	;@5929
L592C:	call L4FDF	;@592C
	db 54h,48h,49h,45h,46h,0h	;@592F
	mov al, byte ptr D_004C	;@5935
	add al, 10h	;@5938
	daa	;@593A
	mov byte ptr D_004C, al	;@593B
	mov bh, 0	;@593E
	mov bl, 1Ah	;@5940
	mov di, bx	;@5942
	mov bh, 0	;@5944
	mov bl, 5	;@5946
	mov si, bx	;@5948
	call L51EB	;@594A
	mov al, byte ptr D_004C	;@594D
	call L53B5	;@5950
L5953:	clc	;@5953
	mov al, byte ptr D_0047	;@5954
	sub al, 31h	;@5957
	mov byte ptr D_0047, al	;@5959
L595C:	mov bh, 0	;@595C
	mov bl, 0Eh	;@595E
	mov si, bx	;@5960
	mov bh, 0	;@5962
	mov bl, 14h	;@5964
	mov di, bx	;@5966
	call L51EB	;@5968
	call L4FDF	;@596B
	db 20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,0h	;@596E
	mov bh, 0	;@597E
	mov bl, 14h	;@5980
	mov di, bx	;@5982
	mov bh, 0	;@5984
	mov bl, 0Eh	;@5986
	mov si, bx	;@5988
	call L51EB	;@598A
	mov bh, 0	;@598D
	mov bl, 0Eh	;@598F
	mov di, bx	;@5991
	mov al, 0	;@5993
L5995:	mov byte ptr D_0036[di], al	;@5995
	dec di	;@5999
	jne L5995	;@599A
	mov bh, 0	;@599C
	mov bl, 0	;@599E
	mov di, bx	;@59A0
L59A2:	call L53D0	;@59A2
	cmp al, 8	;@59A5
	je L595C	;@59A7
	cmp al, 0Dh	;@59A9
	je L59BC	;@59AB
	call L5003	;@59AD
	mov byte ptr D_0036[di], al	;@59B0
	inc di	;@59B4
	mov bx, di	;@59B5
	cmp bl, 0Ch	;@59B7
	jb L59A2	;@59BA
L59BC:	mov bh, 0	;@59BC
	mov bl, 10h	;@59BE
	mov si, bx	;@59C0
	mov bh, 0	;@59C2
	mov bl, 1Dh	;@59C4
	mov di, bx	;@59C6
	call L51EB	;@59C8
	call L53D0	;@59CB
	call L5003	;@59CE
	cmp al, 4Eh	;@59D1
	jne L59D8	;@59D3
	jmp L5498	;@59D5
L59D8:	cmp al, 59h	;@59D8
	jne L59BC	;@59DA
	mov al, 14h	;@59DC
	mov byte ptr D_005A, al	;@59DE
	mov al, 14h	;@59E1
	mov byte ptr D_005B, al	;@59E3
	mov al, 2	;@59E6
	mov byte ptr D_0049, al	;@59E8
	mov al, 4	;@59EB
	mov byte ptr D_0051, al	;@59ED
	mov byte ptr D_0053, al	;@59F0
	mov byte ptr D_0058, al	;@59F3
	mov ah, 28h	;@59F6
	mov cx, 100h	;@59F8
	lea dx, D_0036	;@59FB
	call L52CA	;@59FF
	db 50h,4Ch,41h,59h,45h,52h,20h,20h	;@5A02
	call L4A1C	;@5A0A
	mov bh, 0	;@5A0D
	mov bl, 0Bh	;@5A0F
	mov si, bx	;@5A11
	mov bh, 0	;@5A13
	mov bl, 0Bh	;@5A15
	mov di, bx	;@5A17
	call L51EB	;@5A19
	jmp short L5A61	;@5A1C
	db 0F5h,54h,4Fh,20h,50h,4Ch,41h,59h,20h,55h,4Ch,54h,49h,4Dh,41h,20h	;@5A1E
	db 5Dh,5Bh,0h,0B7h,0h,0B3h,0Dh,8Bh,0F3h,0B7h,0h,0B3h,9h,8Bh,0FBh,0E8h	;@5A2E
	db 0ABh,0F7h,0E8h,9Ch,0F5h,49h,4Eh,53h,45h,52h,54h,20h,50h,52h,4Fh,47h	;@5A3E
	db 52h,41h,4Dh,20h,4Dh,41h,53h,54h,45h,52h,0h,0E8h,0F1h,0F4h,3Dh,1Bh	;@5A4E
	db 0FFh,75h,0F8h	;@5A5E
L5A61:	call L0100	;@5A61
L5A64:	jmp L5A64	;@5A64
L5A66:	mov byte ptr D_002A, al	;@5A66
	cmp al, 0Ah	;@5A69
	jb L5A96	;@5A6B
	mov al, byte ptr D_0029	;@5A6D
	sub al, byte ptr D_002A	;@5A70
	das	;@5A74
	jb L5A96	;@5A75
	call L53DF	;@5A77
	mov byte ptr D_0029, al	;@5A7A
	mov bh, 0	;@5A7D
	mov bl, 2	;@5A7F
	mov si, bx	;@5A81
	mov bh, 0	;@5A83
	mov bl, 21h	;@5A85
	mov di, bx	;@5A87
	call L51EB	;@5A89
	mov al, byte ptr D_0029	;@5A8C
	call L53B5	;@5A8F
	call L53D9	;@5A92
	ret	;@5A95
L5A96:	call L4FDF	;@5A96
	db 7h,7h,7h,0h	;@5A99
	pop ax	;@5A9D
	jmp L5498	;@5A9E
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h	;@5AA1
L5AB0 label byte
	db 0h	;@5AB0
CODE ENDS
END
