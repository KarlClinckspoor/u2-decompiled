; U2DATA.ASM: the data segment: variables, tables, tile bitmaps.
; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); DATA segment, original image 7410-8AC0.
CODE SEGMENT BYTE PUBLIC
CODE ENDS
DATA SEGMENT PARA PUBLIC
	PUBLIC D_0000, D_0001, D_0002, D_0003, D_0004, D_0005
	PUBLIC D_0006, D_0007, D_0008, D_0009, D_0012, D_0013
	PUBLIC D_0014, D_0015, D_0016, D_0017, D_0018, D_0019
	PUBLIC D_001A, D_001F, D_0020, D_0021, D_0022, D_0023
	PUBLIC D_0024, D_0025, D_0026, D_0027, D_0028, D_0029
	PUBLIC D_002A, D_002B, D_002E, D_002F, D_0031, D_0036
	PUBLIC D_0046, D_0047, D_0048, D_0049, D_004A, D_004B
	PUBLIC D_004C, D_004D, D_004E, D_004F, D_0050, D_0051
	PUBLIC D_0052, D_0053, D_0054, D_0055, D_0056, D_0057
	PUBLIC D_0058, D_0059, D_005A, D_005B, D_005D, D_0060
	PUBLIC D_0061, D_0062, D_0063, D_0064, D_0065, D_0066
	PUBLIC D_0069, D_006A, D_006B, D_006C, D_006D, D_006E
	PUBLIC D_006F, D_0070, D_0074, D_0076, D_007F, D_0096
	PUBLIC D_00B6, D_00D6, D_00D7, D_00D8, D_00D9, D_00DA
	PUBLIC D_00DB, D_00DD, D_00DF, D_00E1, D_00E2, D_00E3
	PUBLIC D_00E4, D_00E5, D_0137, D_0157, D_0177, D_0197
	PUBLIC D_01B7, D_01D7, D_01F7, D_0217, D_0239, D_023E
	PUBLIC D_023F, D_0240, D_0241, D_0242, D_0243, D_0244
	PUBLIC D_0245, D_0246, D_024E, D_024F, D_0250, D_0253
	PUBLIC D_026A, D_026B, D_026C, D_026D, D_026E, D_026F
	PUBLIC D_0270, D_0271, D_0272, D_02CB, D_02DE, D_02DF
	PUBLIC D_02E0, D_02F3, D_0372, D_0472, D_0474, D_0476
	PUBLIC D_0478, D_0479, D_047A, D_047B, D_047C, D_047D
	PUBLIC D_047E, D_047F, D_0480, D_0481, D_0482, D_0483
	PUBLIC D_0484, D_0487, D_0488, D_0489, D_048A, D_048F
	PUBLIC D_0497, D_049F, D_04AF, D_04BF, D_04C1, D_04C3
	PUBLIC D_04C4, D_04C5, D_04C6, D_04C7, D_04C8, D_04C9
	PUBLIC D_04CA, D_04CB, D_04CC, D_04CD, D_050D, D_054D
	PUBLIC D_054E, D_054F, D_0554, D_0558, D_0580, D_058C
	PUBLIC D_05B0, D_05DE, STACK_PARA
D_START label byte	; offset 0 of DATA: keep it the first line (sizes are measured from it)
D_0000 label byte
	db 0h
D_0001 label byte
	db 0h
D_0002 label byte
	db 0h
D_0003 label byte
	db 0h
D_0004 label byte
	db 0h
D_0005 label byte
	db 0h
D_0006 label byte
	db 0h
D_0007 label byte
	db 0h
D_0008 label byte
	db 0h
D_0009 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h
D_0012 label byte
	db 0h
D_0013 label byte
	db 0h
D_0014 label byte
	db 0h
D_0015 label byte
	db 0h
D_0016 label byte
	db 0h
D_0017 label byte
	db 0h
D_0018 label byte
	db 0h
D_0019 label byte
	db 0h
D_001A label byte
	db 0h,0h,0h,0h,0h
D_001F label byte
	db 0h
D_0020 label byte
	db 0h
D_0021 label byte
	db 0h
D_0022 label byte
	db 0h
D_0023 label byte
	db 0h
D_0024 label byte
	db 0h
D_0025 label byte
	db 0h
D_0026 label byte
	db 0h
D_0027 label byte
	db 0h
D_0028 label byte
	db 0h
D_0029 label byte
	db 0h
D_002A label byte
	db 0h
D_002B label byte
	db 0h,0h,0h
D_002E label byte
	db 0h
D_002F label byte
	db 0h,0h
D_0031 label byte
	db 0h,0h,0h,0h,0h
D_0036 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
D_0046 label byte
	db 0h
D_0047 label byte
	db 0h
D_0048 label byte
	db 0h
D_0049 label byte
	db 0h
D_004A label byte
	db 0h
D_004B label byte
	db 0h
D_004C label byte
	db 0h
D_004D label byte
	db 0h
D_004E label byte
	db 0h
D_004F label byte
	db 0h
D_0050 label byte
	db 0h
D_0051 label byte
	db 0h
D_0052 label byte
	db 0h
D_0053 label byte
	db 0h
D_0054 label byte
	db 0h
D_0055 label byte
	db 0h
D_0056 label byte
	db 0h
D_0057 label byte
	db 0h
D_0058 label byte
	db 0h
D_0059 label byte
	db 0h
D_005A label byte
	db 0h
D_005B label byte
	db 0h,0h
D_005D label byte
	db 0h,0h,0h
D_0060 label byte
	db 0h
D_0061 label byte
	db 0h
D_0062 label byte
	db 0h
D_0063 label byte
	db 0h
D_0064 label byte
	db 0h
D_0065 label byte
	db 0h
D_0066 label byte
	db 0h,0h,0h
D_0069 label byte
	db 0h
D_006A label byte
	db 0h
D_006B label byte
	db 0h
D_006C label byte
	db 0h
D_006D label byte
	db 0h
D_006E label byte
	db 0h
D_006F label byte
	db 0h
D_0070 label byte
	db 0h,0h,0h,0h
D_0074 label byte
	db 0h,0h
D_0076 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h
D_007F label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h
D_0096 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
D_00B6 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
D_00D6 label byte
	db 0h
D_00D7 label byte
	db 0h
D_00D8 label byte
	db 0h
D_00D9 label byte
	db 0h
D_00DA label byte
	db 0h
D_00DB label byte
	db 0h,0h
D_00DD label byte
	db 0h,0h
D_00DF label byte
	db 0h,0h
D_00E1 label byte
	db 0h
D_00E2 label byte
	db 0h
D_00E3 label byte
	db 0h
D_00E4 label byte
	db 0h
D_00E5 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h
D_0137 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
D_0157 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
D_0177 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
D_0197 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
D_01B7 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
D_01D7 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
D_01F7 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
D_0217 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h
D_0239 label byte
	db 0h,0h,0h,0h,0h
D_023E label byte
	db 0Fh
D_023F label byte
	db 0h
D_0240 label byte
	db 0h
D_0241 label byte
	db 0h
D_0242 label byte
	db 0h
D_0243 label byte
	db 0h
D_0244 label byte
	db 0h
D_0245 label byte
	db 0h
D_0246 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h
D_024E label byte
	db 0h
D_024F label byte
	db 0h
D_0250 label byte
	db 0h,0h,0h
D_0253 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h
D_026A label byte
	db 0h
D_026B label byte
	db 0h
D_026C label byte
	db 0h
D_026D label byte
	db 0h
D_026E label byte
	db 0Eh
D_026F label byte
	db 19h
D_0270 label byte
	db 5h
D_0271 label byte
	db 17h
D_0272 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h
D_02CB label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h
D_02DE label byte
	db 0h
D_02DF label byte
	db 0h
D_02E0 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h
D_02F3 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
D_0372 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
D_0472 label byte
	dw D_END+150h
D_0473 equ byte ptr D_0472+1
D_0474 label byte
	dw D_END+1250h
D_0476 label byte
	dw D_END+1150h
D_0478 label byte
	db 0h
D_0479 label byte
	db 0h
D_047A label byte
	db 0h
D_047B label byte
	db 0h
D_047C label byte
	db 0h
D_047D label byte
	db 0h
D_047E label byte
	db 0h
D_047F label byte
	db 0h
D_0480 label byte
	db 0h
D_0481 label byte
	db 0h
D_0482 label byte
	db 0h
D_0483 label byte
	db 0h
D_0484 label byte
	db 0h,0h,0h
D_0487 label byte
	db 0h
D_0488 label byte
	db 0h
D_0489 label byte
	db 0h
D_048A label byte
	db 0h,0h,0h,0h,0h
D_048F label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h
D_0497 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h
D_049F label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
D_04AF label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
D_04BF label byte
	db 10h,0h
D_04C1 label byte
	db 10h,0h
D_04C3 label byte
	db 0h
D_04C4 label byte
	db 0h
D_04C5 label byte
	db 0h
D_04C6 label byte
	db 0h
D_04C7 label byte
	db 0h
D_04C8 label byte
	db 0h
D_04C9 label byte
	db 0h
D_04CA label byte
	db 0h
D_04CB label byte
	db 0h
D_04CC label byte
	db 0h
D_04CD label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
D_050D label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
D_054D label byte
	db 0h
D_054E label byte
	db 0h
D_054F label byte
	db 0h,0h,0h,0h,0h
D_0554 label byte
	db 8Ah,6h,0h,0h
D_0558 label byte
	db 6h,0h,0DEh,2h,0h,20h,0h,5h,3h,0h,3h,0h,3h,0h,0h,5h
	db 0Ah,0h,0h,10h,0E0h,1h,40h,1h,40h,2h,0h,2h,0h,8h,1h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h
D_0580 label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
D_058C label byte
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h
D_05B0 label byte
	dw D_0630
	dw D_0672
	dw D_06B4
	dw D_06F6
	dw D_0738
	dw D_077A
	dw D_07BC
	dw D_07FE
	dw D_0840
	dw D_0882
	dw D_08C4
	dw D_0906
	dw D_0948
	dw D_098A
	dw D_09CC
	dw D_0A0E
	dw D_0A50
	dw D_0A92
	dw D_0AD4
	dw D_0B16
	dw D_0B58
	dw D_0B9A
	dw D_0BDC
D_05DE label byte
	dw D_0C1E
	dw D_0C60
	dw D_0CA2
	dw D_0CE4
	dw D_0D26
	dw D_0D68
	dw D_0DAA
	dw D_0DEC
	dw D_0E2E
	dw D_0E70
	dw D_0EB2
	dw D_0EF4
	dw D_0F36
	dw D_0F78
	dw D_0FBA
	dw D_0FFC
	dw D_103E
	dw D_1080
	dw D_10C2
	dw D_1104
	dw D_1146
	dw D_1188
	dw D_11CA
	dw D_120C
	dw D_124E
	dw D_1290
	dw D_12D2
	dw D_1314
	dw D_1356
	dw D_1398
	dw D_13DA
	dw D_141C
	dw D_145E
	dw D_14A0
	dw D_14E2
	dw D_1524
	dw D_1566
	dw D_15A8
	dw D_15EA
	dw D_162C
	dw D_166E
D_0630 label byte
	db 4h,10h,0h,0h,0h,0h,0h,0h,0h,0h,22h,0h,20h,2h,0h,22h
	db 2h,20h,0h,0h,0h,0h,0h,0h,0h,0h,0h,20h,2h,22h,22h,2h
	db 20h,0h,0h,0h,0h,0h,0h,0h,0h,0h,20h,2h,22h,0h,2h,20h
	db 0h,22h,0h,0h,0h,0h,0h,0h,0h,0h,0h,22h,2h,20h,22h,0h
	db 20h,2h
D_0672 label byte
	db 4h,10h,0h,11h,0h,0h,0h,0h,0h,0h,3h,0h,1h,10h,0h,0h
	db 0h,0h,1h,10h,0h,30h,0h,0h,0h,0h,0h,11h,0h,3h,0h,0h
	db 0h,0h,0h,3h,0h,11h,0h,0h,0h,0h,1h,10h,0h,30h,0h,0h
	db 0h,0h,3h,0h,11h,0h,0h,0h,0h,0h,11h,0h,30h,0h,0h,0h
	db 0h,0h
D_06B4 label byte
	db 4h,10h,0h,1h,0h,0h,0h,0h,1h,0h,1h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,1h,0h,10h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,10h,0h,1h,0h,0h,0h,0h,0h,0h,1h,0h,0h,0h,0h,0h
	db 1h,0h,0h,0h,0h,0h,0h,0h,0h,10h,0h,10h,0h,0h,0h,0h
	db 0h,0h
D_06F6 label byte
	db 4h,10h,1h,50h,0h,0h,15h,55h,0h,0h,15h,55h,0h,0h,15h,55h
	db 0h,0h,1h,50h,0h,0h,0h,0h,1h,50h,0h,0h,15h,55h,0h,0h
	db 15h,55h,0h,0h,15h,55h,0h,0h,1h,50h,1h,50h,0h,0h,15h,55h
	db 0h,0h,15h,55h,0h,0h,15h,55h,0h,0h,1h,50h,0h,0h,0h,0h
	db 0h,0h
D_0738 label byte
	db 4h,10h,0C0h,0C0h,0Ch,0h,33h,30h,33h,3h,0Ch,0Ch,0C0h,0CCh,30h,3h
	db 0h,30h,0C0h,0Ch,0h,0Ch,0h,30h,0h,3h,0C0h,0C0h,0C0h,0Ch,33h,3h
	db 30h,30h,0Ch,0Ch,0Ch,0C0h,3h,30h,3h,3h,0C0h,0C0h,0h,0CCh,33h,0h
	db 0h,30h,0Ch,0h,0h,0C0h,3h,3h,3h,0h,0h,0CCh,0CCh,0h,0h,30h
	db 30h,0h
D_077A label byte
	db 4h,10h,0h,0h,0h,0h,3h,0C0h,0h,0h,0Ch,30h,0Fh,0h,0Ch,30h
	db 30h,0C0h,3h,0C0h,30h,0C0h,0h,0h,0Fh,0h,0h,0Fh,0h,0h,0h,30h
	db 0C0h,0h,0h,30h,0C0h,0h,0h,0Fh,0h,0h,0h,0h,3h,0C0h,3h,0C0h
	db 0Ch,30h,0Ch,30h,0Ch,30h,0Ch,30h,3h,0C0h,3h,0C0h,0h,0h,0h,0h
	db 0h,0h
D_07BC label byte
	db 4h,10h,0h,0h,0h,0h,0h,0h,0h,0h,0Fh,0FCh,3Fh,0F0h,0Ch,0Ch
	db 30h,30h,0Ch,0Ch,30h,30h,0Ch,0Ch,30h,30h,0Fh,0FFh,0FFh,0F0h,0h,0Ch
	db 30h,0h,0h,0Ch,30h,0h,0Fh,0FFh,0FFh,0F0h,0Ch,0Ch,30h,30h,0Ch,0Ch
	db 30h,30h,0Ch,0Ch,30h,30h,0Fh,0FCh,3Fh,0F0h,0h,0h,0h,0h,0h,0h
	db 0h,0h
D_07FE label byte
	db 4h,10h,0h,0h,0h,0h,0h,3Ch,3Ch,0h,0h,3Fh,0FCh,0h,0h,3Fh
	db 0FCh,0h,0h,0Fh,0F0h,0h,0h,0Fh,0F0h,0h,0h,0Fh,0F0h,0h,0h,0Fh
	db 0F0h,0h,0h,3Fh,0FCh,0h,0h,3Fh,0FCh,0h,0h,3Fh,0FCh,0h,0h,3Fh
	db 0FCh,0h,0h,0FFh,0FFh,0h,0h,0FFh,0FFh,0h,0h,0FFh,0FFh,0h,0h,0FFh
	db 0FFh,0h
D_0840 label byte
	db 4h,10h,0h,0h,0h,0h,0h,0h,0h,0h,0Fh,0h,0h,0F0h,0Fh,0FFh
	db 0FFh,0F0h,3h,0FFh,0FFh,0C0h,3h,0C0h,3h,0C0h,3h,0C0h,3h,0C0h,3h,0C0h
	db 3h,0C0h,3h,0C0h,3h,0C0h,3h,0C0h,3h,0C0h,3h,0C0h,3h,0C0h,3h,0FCh
	db 3Fh,0C0h,0Fh,0FCh,3Fh,0F0h,0Fh,0h,0h,0F0h,0h,0h,0h,0h,0h,0h
	db 0h,0h
D_0882 label byte
	db 4h,10h,0C0h,0C0h,0Ch,0h,33h,30h,33h,3h,0Ch,0Ch,0C0h,0CCh,30h,3h
	db 0h,30h,0C0h,0Ch,0h,0Ch,0h,30h,0h,3h,0C0h,0C0h,0C0h,0Ch,33h,3h
	db 30h,30h,0Ch,0h,0h,0C0h,3h,0Fh,0F0h,3h,0C0h,3Ch,3Ch,0Ch,30h,30h
	db 0Ch,30h,0Ch,30h,0Ch,0C0h,3h,30h,0Ch,3h,0C0h,30h,0Ch,0Ch,30h,30h
	db 0Ch,30h
D_08C4 label byte
	db 4h,10h,0h,0h,0h,0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,3h,0FFh
	db 0FFh,0C0h,3h,0FFh,0FFh,0C0h,3h,0FFh,0FFh,0C0h,3h,0FFh,0FFh,0C0h,3h,0FFh
	db 0FFh,0C0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,0h,3h
	db 0C0h,0h,0h,3h,0C0h,0h,0h,0FFh,0FFh,0h,0Fh,0FFh,0FFh,0F0h,0h,0h
	db 0h,0h
D_0906 label byte
	db 4h,10h,0h,0h,0h,0h,0h,0h,0h,0h,22h,0h,20h,2h,0h,22h
	db 2h,20h,0h,0h,0h,0h,0h,0h,0Fh,0F0h,0h,20h,3Fh,0FCh,22h,0h
	db 0C3h,0FCh,0h,0h,0Ch,3Ch,0h,0h,0h,3Ch,20h,0h,0h,3Ch,0h,0FFh
	db 0C0h,3Ch,3h,0FFh,0F0h,3Ch,0Fh,0FFh,0FCh,3Ch,0h,22h,2h,20h,22h,2h
	db 22h,2h
D_0948 label byte
	db 4h,10h,0h,0h,0h,0h,0h,30h,0Ch,0h,0h,3Fh,0FCh,0h,0h,0Fh
	db 0F0h,0h,0h,0Fh,0F0h,0h,0h,3h,0C0h,0h,0h,0FFh,0FFh,0h,3h,0FFh
	db 0FFh,0C0h,0Fh,0Fh,0F0h,0F0h,0Fh,0Fh,0F0h,0F0h,0Fh,3Fh,0FCh,0F0h,0h,3Ch
	db 3Ch,0h,0h,3Ch,3Ch,0h,0h,3Ch,3Ch,0h,0h,0FCh,3Fh,0h,0h,0h
	db 0h,0h
D_098A label byte
	db 4h,10h,0h,0h,0h,0h,0h,0Ch,30h,0h,0h,0Fh,0F0h,0h,0h,0Fh
	db 0F0h,0h,0h,3h,0C0h,0h,30h,3Fh,0FCh,0Ch,0Ch,0CFh,0F3h,30h,3h,0Fh
	db 0F0h,0C0h,0h,3h,0C0h,0h,0h,0Fh,0F0h,0h,0h,0Fh,0F0h,0h,0h,0Ch
	db 30h,0h,0h,0Ch,30h,0h,0h,0Ch,30h,0h,0h,3Ch,3Ch,0h,0h,0h
	db 0h,0h
D_09CC label byte
	db 4h,10h,0h,0h,0h,80h,0h,0C3h,8h,8h,0h,0FFh,8h,88h,0h,0FFh
	db 3h,0F0h,0h,3Ch,0h,0C0h,3h,0FFh,0C0h,0C0h,0Ch,0FFh,33h,0C0h,0Ch,3Ch
	db 0Ch,0C0h,0Ch,3Ch,0h,0C0h,0Ch,0FFh,0h,0C0h,0h,0FFh,0h,0C0h,0h,0C3h
	db 0h,0C0h,0h,0C3h,0h,0C0h,0h,0C3h,0h,0C0h,3h,0C3h,0C0h,0C0h,0h,0h
	db 0h,0h
D_0A0E label byte
	db 4h,10h,0h,0h,0h,0h,0h,0Ch,30h,0h,0h,0Fh,0F0h,0h,3h,0Fh
	db 0F0h,0C0h,0Fh,0C3h,0C3h,0F0h,3Fh,0FFh,0FFh,0FCh,3Fh,0FFh,0FFh,0FCh,3Fh,0CFh
	db 0F3h,0FCh,3Fh,0CFh,0F3h,0FCh,3Fh,0C3h,0C3h,0FCh,3Fh,0CFh,0F3h,0FCh,3Fh,0Fh
	db 0F0h,0FCh,3Fh,0Ch,30h,0FCh,3Ch,0Ch,30h,3Ch,30h,3Ch,3Ch,0Ch,0h,0h
	db 0h,0h
D_0A50 label byte
	db 4h,10h,0h,0h,0h,0h,0h,0Fh,0C0h,0h,0h,0Fh,0C0h,0h,0h,0Fh
	db 0C0h,0h,0h,3h,0h,0h,3Fh,0FFh,0FFh,0F0h,0Fh,0FFh,0FFh,0C0h,0Fh,0CFh
	db 0CFh,0C0h,0Fh,0C3h,0Fh,0C0h,0Fh,0Fh,0C3h,0C0h,0Fh,0Fh,0C3h,0C0h,0Ch,3Fh
	db 0F0h,0C0h,0Ch,3Fh,0F0h,0C0h,0h,0FFh,0FCh,0h,0h,0FFh,0FCh,0h,0h,30h
	db 30h,0h
D_0A92 label byte
	db 4h,10h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,3h,0C0h,0h,0h,0Fh,0F0h,0h,0h,3Fh,0FCh,0h,0h,0Ch,0FFh
	db 0FFh,0F0h,0h,3Fh,0FFh,0FCh,0h,0FFh,0FFh,0FCh,0h,0FFh,0FFh,0F0h,3h,30h
	db 0Fh,3Ch,0Ch,30h,3h,0Ch,0Ch,30h,3h,0Ch,0h,0C0h,0Ch,30h,0h,0h
	db 0h,0h
D_0AD4 label byte
	db 4h,10h,0h,0h,0h,0h,0h,0h,0h,0h,0h,3h,0h,0h,0h,3h
	db 0C0h,0h,0h,0C3h,0Ch,0h,0h,0FFh,0FCh,0h,0Fh,0F0h,0FFh,0C0h,0Ch,30h
	db 0C0h,0C0h,0Ch,30h,0C0h,0C0h,0Fh,0FFh,0FFh,0C0h,0h,0C3h,0Ch,0h,3Fh,0FFh
	db 0FFh,0FCh,3Fh,0CFh,3Ch,0F0h,0Fh,0FFh,0FFh,0C0h,3h,0FFh,0FFh,0h,0h,0h
	db 0h,0h
D_0B16 label byte
	db 4h,10h,0h,3Fh,0FCh,0h,0h,3h,0C0h,0h,0h,0Fh,0F0h,0h,0Fh,0FFh
	db 0FFh,0F0h,30h,0h,0h,0Ch,30h,3h,0C0h,0Ch,30h,0Ch,30h,0Ch,0Fh,0FCh
	db 3Fh,0F0h,0h,0Fh,0F0h,0h,0h,0Ch,30h,0h,0h,0Ch,30h,0h,0h,0Ch
	db 30h,0h,3h,0FCh,3Fh,0C0h,0Ch,3h,0C0h,30h,3h,0FFh,0FFh,0C0h,0h,3h
	db 0C0h,0h
D_0B58 label byte
	db 4h,10h,0h,0h,0C0h,0h,0h,0h,0C0h,0h,0h,0h,0C0h,0h,0h,3h
	db 30h,0h,0h,3h,30h,0h,0h,3h,30h,0h,0h,0Ch,0Ch,0h,0h,0Ch
	db 0Ch,0h,0h,0Ch,0Ch,0h,0h,0Ch,0Ch,0h,0h,0Ch,0Ch,0h,0h,0Ch
	db 0Ch,0h,0h,30h,0C3h,0h,0h,0C3h,0F0h,0C0h,3h,0Ch,0CCh,30h,3h,0F0h
	db 0C3h,0F0h
D_0B9A label byte
	db 4h,10h,0h,0h,0h,0h,0Fh,0FFh,0FFh,0F0h,0Ch,0h,0h,30h,0Ch,0Fh
	db 0FCh,30h,0Ch,30h,3Ch,30h,0Ch,30h,0h,30h,0Ch,0Fh,0F0h,30h,0Ch,0h
	db 0Ch,30h,0Ch,3h,0F0h,30h,0Ch,0Ch,0h,30h,0Ch,3h,0C0h,30h,3h,0h
	db 30h,0C0h,3h,3h,0C0h,0C0h,0h,0F0h,0Fh,0h,0h,0Fh,0F0h,0h,0h,0h
	db 0h,0h
D_0BDC label byte
	db 4h,10h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,30h,0h,0h
	db 0h,0C0h,0h,0h,3h,0h,0h,0h,0Ch,0h,0h,0h,30h,0h,0h,0h
	db 0C0h,0h,0h,3h,0h,0h,0Ch,0Ch,0h,0h,3h,30h,0h,0h,0h,0C0h
	db 0h,0h,3h,30h,0h,0h,0Ch,0Ch,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h
D_0C1E label byte
	db 4h,10h,88h,88h,88h,88h,33h,33h,33h,33h,33h,33h,33h,33h,11h,11h
	db 11h,11h,11h,11h,11h,11h,0CCh,0CCh,0CCh,0CCh,0CCh,0CCh,0CCh,0CCh,88h,88h
	db 88h,88h,88h,88h,88h,88h,33h,33h,33h,33h,33h,33h,33h,33h,11h,11h
	db 11h,11h,11h,11h,11h,11h,0CCh,0CCh,0CCh,0CCh,0CCh,0CCh,0CCh,0CCh,88h,88h
	db 88h,88h
D_0C60 label byte
	db 4h,10h,0h,0Fh,0F0h,0h,0h,0Fh,0F0h,0h,0h,0Fh,0F0h,0h,0h,3h
	db 0C0h,0h,3h,0FFh,0FFh,0C0h,0Fh,0FFh,0FFh,0F0h,3Fh,3Fh,0FCh,0FCh,3Ch,0Fh
	db 0F0h,3Ch,3Ch,3h,0C0h,3Ch,3Ch,3h,0C0h,3Ch,0h,0Fh,0F0h,0h,0h,3Fh
	db 0FCh,0h,0h,3Ch,3Ch,0h,0h,3Ch,3Ch,0h,0h,3Ch,3Ch,0h,0h,0FCh
	db 3Fh,0h
D_0CA2 label byte
	db 4h,10h,0h,0h,0h,0h,0Ch,0Fh,0C0h,0C0h,0Ch,0Fh,0C0h,0C0h,0Fh,0Fh
	db 0C3h,0h,3h,0C3h,0Fh,0h,0h,0FFh,0FCh,0h,0h,3Fh,0F0h,0h,0h,0Fh
	db 0C0h,0h,0h,3h,0h,0h,0h,0Fh,0C0h,0h,0h,0Fh,0C0h,0h,0h,3Ch
	db 0F0h,0h,0h,0F0h,3Ch,0h,3h,0C0h,0Fh,0h,0Fh,0h,3h,0C0h,0h,0h
	db 0h,0h
D_0CE4 label byte
	db 4h,10h,0h,0h,0h,0h,0h,0Fh,0C0h,0h,0h,0Fh,0C0h,0h,0h,0Fh
	db 0C0h,0h,0h,3h,0h,0h,0h,0FFh,0FCh,0h,3h,3Fh,0F3h,0h,3h,0Fh
	db 0C3h,0h,3h,3h,3h,0h,3h,0Fh,0C3h,0h,3h,0Fh,0C3h,0h,0h,3Ch
	db 0F0h,0h,0h,30h,30h,0h,0h,30h,30h,0h,0h,0F0h,3Ch,0h,0h,0h
	db 0h,0h
D_0D26 label byte
	db 4h,10h,0h,0h,0h,0h,0h,0Fh,0F0h,0h,0h,0Fh,0F0h,0h,0h,0Fh
	db 0F0h,0h,0h,3h,0C0h,0h,0h,3Fh,0FCh,0h,3h,0FFh,0FFh,0C0h,0Fh,0CFh
	db 0F3h,0F0h,0Fh,3h,0C0h,0F0h,0Fh,0Fh,0F0h,0F0h,0h,3Fh,0FCh,0h,0h,3Ch
	db 3Ch,0h,0h,3Ch,3Ch,0h,0h,3Ch,3Ch,0h,0h,3Ch,3Ch,0h,0h,3Ch
	db 3Ch,0h
D_0D68 label byte
	db 4h,10h,80h,0h,80h,0h,80h,0h,80h,0h,80h,0h,80h,0h,88h,88h
	db 88h,88h,0h,80h,0h,80h,0h,80h,0h,80h,0h,80h,0h,80h,88h,88h
	db 88h,88h,80h,0h,80h,0h,80h,0h,80h,0h,80h,0h,80h,0h,88h,88h
	db 88h,88h,0h,80h,0h,80h,0h,80h,0h,80h,0h,80h,0h,80h,88h,88h
	db 88h,88h
D_0DAA label byte
	db 4h,10h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h
D_0DEC label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
	db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
	db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
	db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
	db 0FFh,0FFh
D_0E2E label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h
	db 0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_0E70 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0h,0FCh,0h,0h,3h
	db 0CFh,0C0h,0h,0Fh,0Fh,0h,0h,3Ch,0Fh,0h,0h,3Ch,0Fh,0h,0h,0FCh
	db 0Fh,0h,0h,0FFh,0FFh,0h,0h,0FCh,0Fh,0h,0h,3Ch,0Fh,0h,0h,3Ch
	db 0Fh,0h,0h,3Ch,0Fh,0h,0h,0FCh,3Fh,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_0EB2 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0Fh,0F0h,0h,0h,3Ch
	db 3Ch,0h,0h,0FCh,0Fh,0h,0h,3Ch,0Fh,0h,0h,3Ch,3Ch,0h,0h,3Fh
	db 0F0h,0h,0h,3Ch,3Ch,0h,0h,3Ch,0Fh,0h,0h,3Ch,0Fh,0C0h,0h,0FCh
	db 0Fh,0h,0h,3Ch,3Ch,0h,0h,0Fh,0F0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_0EF4 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0h,0FFh,0C0h,0h,3h
	db 0CFh,0h,0h,0Fh,0Fh,0h,0h,3Fh,3h,0h,0h,3Ch,3h,0h,0h,0FCh
	db 0h,0h,0h,0FCh,0h,0h,0h,3Ch,0h,0h,0h,3Fh,3h,0h,0h,0Fh
	db 3h,0h,0h,3h,0CFh,0h,0h,0h,0FCh,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_0F36 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3Fh,0C0h,0h,0h,0F0h
	db 0F0h,0h,3h,0F0h,3Ch,0h,0h,0F0h,0Fh,0h,0h,0F0h,0Fh,0h,0h,0F0h
	db 0Fh,0C0h,0h,0F0h,0Fh,0C0h,0h,0F0h,0Fh,0h,0h,0F0h,0Fh,0h,3h,0F0h
	db 3Ch,0h,0h,0F0h,0F0h,0h,0h,3Fh,0C0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_0F78 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0h,0FFh,0C0h,0h,3h
	db 0CFh,0h,0h,0Fh,3h,0h,0h,3Fh,0h,0h,0h,3Ch,0Ch,0h,0h,0FFh
	db 0FCh,0h,0h,0FCh,3Ch,0h,0h,3Ch,0Ch,0h,0h,3Fh,0h,0h,0h,0Fh
	db 3h,0h,0h,3h,0CFh,0h,0h,0h,0FCh,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_0FBA label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0FFh,0FFh,0C0h,0h,3Ch
	db 0Fh,0h,0h,3Ch,3h,0h,0h,3Ch,0h,0h,0h,3Ch,0h,0h,0h,3Ch
	db 30h,0h,0h,3Fh,0F0h,0h,0h,3Ch,0F0h,0h,0h,3Ch,30h,0h,0h,3Ch
	db 0h,0h,0h,3Ch,0h,0h,0h,0FFh,0C0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_0FFC label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3h,0FFh,0h,0h,0Fh
	db 3Ch,0h,0h,3Ch,3Ch,0h,0h,0FCh,0Ch,0h,0h,0F0h,0h,0h,3h,0F0h
	db 0h,0h,3h,0F0h,0FCh,0h,0h,0F0h,0Fh,0h,0h,0FCh,0Fh,0C0h,0h,3Ch
	db 0Fh,0h,0h,0Fh,3Ch,0h,0h,3h,0F0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_103E label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,3h,0FFh,0FFh,0h,0h,0F0h
	db 3h,0h,0h,0F0h,0h,0h,0h,0F3h,0C0h,0h,0h,0FFh,0F0h,0h,0h,0F0h
	db 0FCh,0h,0h,0F0h,3Fh,0h,0h,0F0h,3Fh,0h,0h,0F0h,3Ch,0h,0h,0F0h
	db 3Ch,0h,0h,0F0h,30h,0h,3h,0FCh,3Fh,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_1080 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3Fh,0FCh,0h,0h,3h
	db 0C0h,0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,0h,3h
	db 0C0h,0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,0h,3h
	db 0C0h,0h,0h,3h,0C0h,0h,0h,3Fh,0FCh,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_10C2 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0Fh,0FFh,0C0h,0h,0h
	db 0Fh,0h,0h,0h,0Fh,0h,0h,0h,0Fh,0h,0h,0h,0Fh,0h,0h,0h
	db 0Fh,0h,0h,0C0h,0Fh,0h,0h,0C0h,0Fh,0h,0h,0C0h,0Fh,0h,0h,0F0h
	db 0Fh,0h,0h,0FCh,0F0h,0h,0h,0Fh,0C0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_1104 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0FFh,0FFh,0h,0h,3Ch
	db 3h,0h,0h,3Ch,30h,0h,0h,3Ch,0FCh,0h,0h,3Fh,0CFh,0h,0h,3Ch
	db 0Fh,0h,0h,3Ch,3Ch,0h,0h,3Fh,0F0h,0h,0h,3Ch,0FCh,0h,0h,3Ch
	db 3Fh,0h,0h,3Ch,0Fh,0h,0h,0FFh,0Fh,0C0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_1146 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0FFh,0FCh,0h,0h,3Ch
	db 0h,0h,0h,3Ch,0h,0h,0h,3Ch,0h,0h,0h,3Ch,0h,0h,0h,3Ch
	db 3h,0h,0h,3Ch,3h,0h,0h,3Ch,3h,0h,0h,3Ch,3h,0h,0h,3Ch
	db 0Fh,0h,0h,3Ch,3Fh,0h,0h,0FFh,0FFh,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_1188 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3Fh,0FCh,0h,0h,0F3h
	db 0CFh,0h,3h,0C3h,0C3h,0C0h,0Fh,0C3h,0C3h,0F0h,0Fh,3h,0C0h,0F0h,3Fh,3h
	db 0C0h,0FCh,3Fh,3h,0C0h,0FCh,0Fh,3h,0C0h,0F0h,0Fh,0C3h,0C3h,0F0h,3h,0C3h
	db 0C3h,0C0h,0h,0C3h,0C3h,0h,0Fh,0CFh,0F3h,0F0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_11CA label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3Fh,0C0h,0h,0h,0F0h
	db 0F0h,0h,3h,0F0h,3Ch,0h,0h,0F0h,3Fh,0h,0h,0F0h,0Fh,0h,0h,0F0h
	db 0Fh,0C0h,0h,0F0h,0Fh,0C0h,0h,0F0h,0Fh,0h,0h,0F0h,3Fh,0h,0h,0F0h
	db 3Ch,0h,0h,0F0h,30h,0h,3h,0FCh,3Fh,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_120C label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3h,0C0h,0h,0h,0Fh
	db 0F0h,0h,0h,3Ch,3Ch,0h,0h,0FCh,3Fh,0h,0h,0F0h,0Fh,0h,3h,0F0h
	db 0Fh,0C0h,3h,0F0h,0Fh,0C0h,0h,0F0h,0Fh,0h,0h,0FCh,3Fh,0h,0h,3Ch
	db 3Ch,0h,0h,0Fh,0F0h,0h,0h,3h,0C0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_124E label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0Fh,0F0h,0h,0h,3Ch
	db 3Ch,0h,0h,0FCh,0Fh,0h,0h,3Ch,0Fh,0C0h,0h,3Ch,0Fh,0C0h,0h,3Ch
	db 0Fh,0h,0h,3Ch,3Ch,0h,0h,3Ch,0F0h,0h,0h,3Ch,0h,0h,0h,3Ch
	db 0h,0h,0h,3Ch,0h,0h,0h,0FFh,0F0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_1290 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FCh,0FFh,0FFh,0FFh,0FCh,0F3h,33h,33h,3Ch,0F3h,33h
	db 33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h
	db 33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h
	db 33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h,33h,3Ch,0F3h,33h
	db 33h,3Ch
D_12D2 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3Fh,0C0h,0h,0h,0F0h
	db 0F0h,0h,3h,0F0h,3Ch,0h,0h,0F0h,3Fh,0h,0h,0F0h,3Fh,0h,0h,0F0h
	db 3Ch,0h,0h,0F3h,0F0h,0h,0h,0F0h,30h,0h,0h,0F0h,3Ch,0h,0h,0F0h
	db 0Fh,0h,0h,0F0h,0Fh,0h,3h,0FCh,0Fh,0C0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_1314 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3h,0FFh,0h,0h,0Fh
	db 3Ch,0h,0h,3Ch,0Ch,0h,0h,0FFh,0h,0h,0h,0FFh,0h,0h,0h,3Fh
	db 0C0h,0h,0h,0Fh,0F0h,0h,0h,3h,0FCh,0h,0h,0h,0FFh,0h,0h,0C0h
	db 0FFh,0h,0h,0F3h,0F0h,0h,0h,0FFh,0C0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_1356 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,3h,0FFh,0FFh,0C0h,0h,0F3h
	db 0CFh,0h,0h,0C3h,0C3h,0h,0h,0C3h,0C3h,0h,0h,3h,0C0h,0h,0h,3h
	db 0C0h,0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,0h,3h,0C0h,0h,0h,3h
	db 0C0h,0h,0h,3h,0C0h,0h,0h,0Fh,0F0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_1398 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,0FCh,0Fh,0C0h,0h,0Ch
	db 0Fh,0h,0h,3Ch,0Fh,0h,0h,0FCh,0Fh,0h,0h,0F0h,0Fh,0h,3h,0F0h
	db 0Fh,0h,3h,0F0h,0Fh,0h,0h,0F0h,0Fh,0h,0h,0FCh,0Fh,0h,0h,3Ch
	db 0Fh,0C0h,0h,3Ch,3Ch,0h,0h,0Fh,0F0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_13DA label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,3h,0F0h,0F0h,0h,0h,30h
	db 3Ch,0h,0h,0F0h,0Fh,0h,3h,0F0h,0Fh,0C0h,3h,0C0h,3h,0C0h,0Fh,0C0h
	db 3h,0F0h,0Fh,0C0h,3h,0F0h,3h,0C0h,3h,0C0h,3h,0F0h,0Fh,0C0h,0h,0F0h
	db 0Fh,0h,0h,3Ch,3Ch,0h,0h,0Fh,0F0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_141C label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0Fh,0C3h,0C3h,0F0h,0h,0C3h
	db 0C3h,0h,3h,0C3h,0C3h,0C0h,0Fh,0C3h,0C3h,0F0h,0Fh,3h,0C0h,0F0h,3Fh,3h
	db 0C0h,0FCh,3Fh,3h,0C0h,0FCh,0Fh,3h,0C0h,0F0h,0Fh,0C3h,0C3h,0F0h,3h,0C3h
	db 0C3h,0C0h,0h,0F3h,0CFh,0h,0h,3Fh,0FCh,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_145E label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0Fh,0F0h,3Fh,0C0h,3h,0C0h
	db 0Fh,0h,3h,0F0h,3Ch,0h,0h,0FCh,0F0h,0h,0h,0FFh,0C0h,0h,0h,3Fh
	db 0C0h,0h,0h,0Fh,0F0h,0h,0h,3Fh,0FCh,0h,0h,0F0h,0FCh,0h,3h,0C0h
	db 3Fh,0h,0Fh,0h,0Fh,0h,0Fh,0C0h,3Fh,0C0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_14A0 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,0h,3Ch,3Fh,0C0h,0h,0Ch
	db 0Fh,0h,0h,3Ch,0Fh,0h,0h,0FCh,0Fh,0h,3h,0F0h,0Fh,0h,3h,0F0h
	db 0Fh,0h,0h,0FCh,0Fh,0h,0h,3Ch,0Fh,0h,0h,0Fh,0FFh,0h,0h,0C0h
	db 0Fh,0h,0h,0F0h,3Ch,0h,0h,0FFh,0F0h,0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_14E2 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,0h,3h,0FFh,0FFh,0h,3h,0C0h
	db 0FCh,0h,3h,0h,0FCh,0h,0h,3h,0F0h,0h,0h,3h,0F0h,0h,0h,0Fh
	db 0C0h,0h,0h,0Fh,0C0h,0h,0h,3Fh,3h,0h,0h,3Fh,3h,0h,0h,0FCh
	db 3h,0h,0h,0FCh,0Fh,0h,3h,0FFh,0FFh,0C0h,0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_1524 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0h,0h,0h,3h,0h,0h,0h,3h,0h,0h
	db 0h,3h,0h,0h,0h,3h,0h,0h,0h,3h,0h,0h,0h,3h,0h,0h
	db 0h,3h,0h,0h,0h,3h,0h,0h,0h,3h,0h,0h,0h,3h,0h,0h
	db 0h,3h,0h,0h,0h,3h,0h,0h,0h,3h,0h,0h,0h,3h,0FFh,0FFh
	db 0FFh,0FFh
D_1566 label byte
	db 4h,10h,0FFh,0FFh,0FFh,0FFh,0C0h,0h,0h,0h,0C0h,0h,0h,0h,0C0h,0h
	db 0h,0h,0C0h,0h,0h,0h,0C0h,0h,0h,0h,0C0h,0h,0h,0h,0C0h,0h
	db 0h,0h,0C0h,0h,0h,0h,0C0h,0h,0h,0h,0C0h,0h,0h,0h,0C0h,0h
	db 0h,0h,0C0h,0h,0h,0h,0C0h,0h,0h,0h,0C0h,0h,0h,0h,0FFh,0FFh
	db 0FFh,0FFh
D_15A8 label byte
	db 4h,10h,0h,0h,0h,0h,0h,0Fh,0C0h,0h,0h,0Fh,0C0h,0h,0h,0Fh
	db 0C0h,0h,0h,3h,0h,0h,0h,0FFh,0FCh,0h,3h,3Fh,0F3h,0h,0Ch,0Fh
	db 0C0h,0C0h,3h,3h,3h,0h,0h,0CFh,0CCh,0h,0h,0Fh,0C0h,0h,0h,3Ch
	db 0F0h,0h,0h,30h,30h,0h,0h,30h,30h,0h,0h,0F0h,3Ch,0h,0h,0h
	db 0h,0h
D_15EA label byte
	db 4h,10h,0h,0h,0h,0h,0h,3Fh,0h,0C0h,0h,3Fh,0h,0C0h,0h,3Fh
	db 0Fh,0FCh,0h,0Ch,0h,0C0h,3h,0FFh,0F0h,0C0h,0Ch,0FFh,0CCh,0C0h,0Ch,3Fh
	db 3h,0C0h,0Ch,0Ch,0h,0C0h,0Ch,3Fh,0h,0h,0h,0F3h,0C0h,0h,0h,0C0h
	db 0C0h,0h,0h,0C0h,0C0h,0h,0h,0C0h,0C0h,0h,3h,0C0h,0F0h,0h,0h,0h
	db 0h,0h
D_162C label byte
	db 4h,10h,0h,0h,0h,0h,0h,0Fh,0C0h,0h,0h,0Fh,0C0h,0Ch,0h,0Fh
	db 0C0h,0Ch,0h,3h,0h,0Ch,0h,0FFh,0FCh,0Ch,33h,3Fh,0F3h,3Ch,0Ch,0Fh
	db 0C0h,0CCh,0h,3h,0h,0Ch,0h,0Fh,0C0h,0Ch,0h,3Ch,0F0h,0Ch,0h,30h
	db 30h,0Ch,0h,30h,30h,0Ch,0h,30h,30h,0Ch,0h,0F0h,3Ch,0Ch,0h,0h
	db 0h,0h
D_166E label byte
	db 4h,10h,0h,0h,0h,0h,0h,3Fh,0h,0h,0h,3Fh,0h,0h,0h,3Fh
	db 0h,0h,0h,0Ch,0h,0h,3h,0FFh,0FCh,0h,0Ch,0FFh,0CCh,0Ch,0Ch,3Fh
	db 0Ch,30h,0Ch,0Ch,0Ch,0C0h,0Ch,3Fh,3h,0h,0Ch,3Fh,0Ch,0C0h,0h,0F3h
	db 0C0h,0h,0h,0C0h,0C0h,0h,0h,0C0h,0C0h,0h,3h,0C0h,0F0h,0h,0h,0h
	db 0h,0h
D_END label byte	; end of the initialised data; BSS buffers and stack follow
STACK_PARA equ (D_END-D_START+1A50h+15)/16	; paragraphs of data, BSS and buffers: SS = DS+this
DATA ENDS
CGROUP GROUP CODE, DATA	; for the cs: reads of DATA
END
