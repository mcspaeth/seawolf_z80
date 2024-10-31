	;; out 01    = Explosion matrix
	;; out 02    = Torpedo display
	;; out 03    = Shifter data
	;; out 04    = Shifter count
	;; out 05    = Sound triggers
	;; out 06    = watchdog (add this)

	;; 2000-2001 = ??
	;; 2002      = Down counter (when $200e == 0)  (Game time?)
	;; 2003      = Down counter ($1E to $00)
	;; 2005      = Credits
	;; 2006      = High score byte
	;; 2007      = Last IN1
	;; 2008	     = Last IN0
	;; 2010      = Down counter (when $2003 == 0)
	;; 2011      = Down counter
	
	;; 2014-2015 = Sprite loc to update (0 in attract)
	;; 2016-2017 = 
	;; 2018-2019 = Pointer to ship 0 data
	;; 201a-201b = Pointer to ship 1 data
	;; 201c      = Next sprite?
	;; 201e	     = ??
	;; 201f	     = ??
	
	;; 2020	     = Mask for subs to call at 04ce (when [[$2000]] == 00)
	;; 	       D7 = $2002, D6 = $2010, D5 = $2011, D4 = $2021
	;;             D3 = $2022, D2 = $2023, D1 = $2024, D0 = $2025
	;; 2021      = Down counter (non-zero inhibits fire)
	;; 2022	     = Down counter
	;; 2023      = Down counter ($19 for small ship)
	;; 2024      = Down counter
	;; 2025      = Audio timer (down counter)
	;; 2026      = Down counter ($0f for small ship)
	
	;; 2027-2028 = Wave state
	;; 2029	     = Next ship type
	;; 202b	     = Player score
	;; 202c      = ?? 
	;; 202d	     = Torpedo status
	;; 202e      = 1 if extended time passed
	;; 2030      = Current sprite shift
	;; 2058-2064 = Ship data 0 (Attract?)
	;;		Byte 0   = X flags?
	;; 		Byte 1   = Delta X
	;; 		Byte 2   = X Pos	((loc-$2400) & $1f)<<3 | (shift & $07)
	;; 		Byte 3   = Y flags
	;; 		Byte 4   = Delta Y
	;; 		Byte 5   = Y Pos	(loc-$2400)>>5
	;; 		Byte 6   = ??
	;; 		Byte 7-8 = Sprite tbl LSB,MSB
	;; 		Byte 9-A = (address -> de -> hl)
	;; 		Byte C   = (read into b)
	;; 		Byte D   = (read into c)
	;; 2065-2071 = Ship data 1
	;; 2072-207e = Ship data 2
	;; 207f-208b = Ship data 3
	;; 208c-2098 = Ship data 4
	;; 2099-20a5 = Ship data 5
	;; 20a6-20b2 = Ship data 6
	;; 20b3-20bf = Ship data 7
	;; 20c0-20cc = Ship data 8
	;; 20cd-20d9 = Ship data 9
	;; 20da-20e6 = Ship data a
	
	;; Torpedo control?
	;; 20c9-20e6 = $1e data block
	;; 20e7-2104 = $1e data block
	;; 2105-2122 = $1e data block
	;; 2123-2140 = $1e data block

	;; 215f-21a3 = $44 data block, cleared at $0088
	;; 215f
	;; 2181 
	
	;; 21f0-21f1 = Address for $0A3F clear if non-zero
	;; 21f2-21f3 = Address for $0A3F clear if non-zero
	;; 21f4-21f5 = Address for $0A3F clear if non-zero
	;; 21f4-21f5 = Address for $0A3F clear if non-zero



	;; RST $00 ($C7)
0000: 00            nop
0001: 00            nop
0002: 31 00 24      ld   sp,$2400 			; Stack pointer
0005: C3 3A 04      jp   $043A				; Startup jump

	;; rst $08 ($cf interrupt vector)
0008: E5            push hl
0009: D5            push de
000A: C5            push bc
000B: F5            push af
000C: C3 7E 00      jp   $007E
000F: 00            nop

	;; rst $10 ($d7 interrupt vector)
0010: E5            push hl
0011: D5            push de
0012: C5            push bc
0013: F5            push af
0014: 3A 1F 20      ld   a,($201F)
0017: A7            and  a
0018: C2 3E 00      jp   nz,$003E
	
001B: CD BC 03      call $03BC			; Update wave
001E: CD 2E 01      call $012E			; Update a sprite
	
0021: 2A 16 20      ld   hl,($2016)		; Sprite pointer
0024: 7E            ld   a,(hl)
0025: A7            and  a
0026: F2 36 00      jp   p,$0036		; Jump if not active
0029: E6 20         and  $20
002B: CA 36 00      jp   z,$0036 		; Jump if ??
	
002E: CD 5B 03      call $035B			; Load de, bc from ship data
0031: 0D            dec  c
0032: EB            ex   de,hl
0033: CD 2A 0A      call $0A2A			; Draw b x c block from de at hl
0036: 3E FF         ld   a,$FF
0038: 32 1F 20      ld   ($201F),a
003B: C3 69 00      jp   $0069			; End of interrupt routine
	
003E: 2A 16 20      ld   hl,($2016) 		; Sprite pointer
0041: 7E            ld   a,(hl)
0042: A7            and  a
0043: F2 62 00      jp   p,$0062 		; Jump if not active
	
0046: E6 40         and  $40
0048: C2 50 00      jp   nz,$0050 		; Jump if not set to clear
004B: 36 00         ld   (hl),$00		; Clear sprite
004D: C3 62 00      jp   $0062
	
0050: 7E            ld   a,(hl)			; Set bit 5
0051: F6 20         or   $20
0053: 77            ld   (hl),a
0054: CD 65 01      call $0165			; Update sprite
0057: 78            ld   a,b
0058: E5            push hl
0059: 2A 1C 20      ld   hl,($201C)
005C: 44            ld   b,h
005D: 4D            ld   c,l
005E: E1            pop  hl
005F: CD 16 0A      call $0A16
	
0062: CD 68 03      call $0368
0065: AF            xor  a
0066: 32 1F 20      ld   ($201F),a

	;; End of interrupt routine
0069: DB 02         in   a,($02) 		; IN1
006B: 47            ld   b,a
006C: DB 02         in   a,($02) 		; IN1
006E: 21 07 20      ld   hl,$2007		; Last IN1?
0071: 11 CA 09      ld   de,$09CA
0074: B8            cp   b			; Bits changed?
0075: CC 05 0B      call z,$0B05
0078: F1            pop  af
0079: C1            pop  bc
007A: D1            pop  de
007B: E1            pop  hl
007C: FB            ei
007D: C9            ret

	;; Interrupt vector continues...
007E: 3A 1F 20      ld   a,($201F)
0081: A7            and  a
0082: C2 19 01      jp   nz,$0119
0085: CD BC 03      call $03BC			; Update wave
	
	;; Clear $215f-$21a3
0088: 21 5F 21      ld   hl,$215F
008B: 06 44         ld   b,$44
008D: AF            xor  a
008E: 77            ld   (hl),a
008F: 23            inc  hl
0090: 05            dec  b
0091: C2 8E 00      jp   nz,$008E
	
0094: 2A 18 20      ld   hl,($2018) 		; Sprite pointer 0
0097: 3E 03         ld   a,$03			; Loop counter 
0099: F5            push af
009A: 7D            ld   a,l
009B: FE 58         cp   $58			; hl==$2058?
009D: C2 A3 00      jp   nz,$00A3
00A0: 21 31 20      ld   hl,$2031 		; Resets to $2031
00A3: B4            or   h
00A4: CA A0 00      jp   z,$00A0
	
00A7: E5            push hl
00A8: CD DE 01      call $01DE
00AB: E1            pop  hl
00AC: D2 B2 00      jp   nc,$00B2
	
00AF: 22 18 20      ld   ($2018),hl 		; Sprite pointer 0
00B2: 11 0D 00      ld   de,$000D
00B5: 19            add  hl,de
00B6: F1            pop  af
00B7: 3D            dec  a
00B8: C2 99 00      jp   nz,$0099 		; Loop back
	
00BB: 2A 18 20      ld   hl,($2018) 		; Sprite pointer 0
00BE: CD 0C 03      call $030C
	
00C1: 2A 1A 20      ld   hl,($201A) 		; Sprite pointer 1
00C4: 3E 03         ld   a,$03			; Loop counter
00C6: F5            push af
00C7: 7D            ld   a,l
00C8: FE 7F         cp   $7F			; hl==$207F?
00CA: C2 D0 00      jp   nz,$00D0
00CD: 21 58 20      ld   hl,$2058 		; Reset to $2058
00D0: B4            or   h
00D1: CA CD 00      jp   z,$00CD
	
00D4: E5            push hl
00D5: CD DE 01      call $01DE
00D8: E1            pop  hl
00D9: D2 DF 00      jp   nc,$00DF
	
00DC: 22 1A 20      ld   ($201A),hl 		; Sprite pointer 1
00DF: 11 0D 00      ld   de,$000D
00E2: 19            add  hl,de
00E3: F1            pop  af
00E4: 3D            dec  a
00E5: C2 C6 00      jp   nz,$00C6 		; Loop back
	
00E8: AF            xor  a
00E9: 32 30 20      ld   ($2030),a 		; Clear sprite shift
	
00EC: 2A 16 20      ld   hl,($2016) 		; Pointer?
00EF: 3E 04         ld   a,$04			; Loop counter
00F1: F5            push af
00F2: 7D            ld   a,l
00F3: FE 5F         cp   $5F
00F5: C2 FB 00      jp   nz,$00FB
	
00F8: 21 E7 20      ld   hl,$20E7 		; Reset to $20E7
00FB: B4            or   h
00FC: CA F8 00      jp   z,$00F8
	
00FF: E5            push hl
0100: CD 50 02      call $0250
0103: E1            pop  hl
0104: D2 0A 01      jp   nc,$010A
	
0107: 22 16 20      ld   ($2016),hl 		; Pointer?
010A: 11 1E 00      ld   de,$001E
010D: 19            add  hl,de
010E: F1            pop  af
010F: 3D            dec  a
0110: C2 F1 00      jp   nz,$00F1 		; Loop back
	
0113: CD 31 03      call $0331
0116: C3 69 00      jp   $0069			; End of interrupt routine

	
0119: 2A 1A 20      ld   hl,($201A) 		; Ship 1 pointer
011C: CD 0C 03      call $030C
	
011F: 2A 1A 20      ld   hl,($201A) 		; Ship 1 pointer
0122: CD 3A 01      call $013A
	
0125: 2A 18 20      ld   hl,($2018) 		; Ship 0 pointer
0128: CD 3A 01      call $013A
012B: C3 69 00      jp   $0069			; End of interrupt routine

	;; Called from rst $10
012E: 2A 14 20      ld   hl,($2014)
0131: 7E            ld   a,(hl)
0132: A7            and  a
0133: F0            ret  p			; No sprite to update?
0134: CD 65 01      call $0165			; Update sprite
0137: C3 92 01      jp   $0192

	;; Handle 2018/201a entries (read into hl)
013A: 7E            ld   a,(hl)
013B: A7            and  a
013C: F0            ret  p			; Return if b7 clear
	
013D: E6 40         and  $40			; Check bit 6
013F: C2 45 01      jp   nz,$0145 		; Jump if set
0142: 36 00         ld   (hl),$00		; Clear entry
0144: C9            ret

	;; Bits 7 set, bit 6 clear
0145: 7E            ld   a,(hl)
0146: F6 20         or   $20
0148: 77            ld   (hl),a			; Set bit 5	 
0149: F5            push af
014A: CD 65 01      call $0165			; Update sprite
	;; hl = screen loc, c= shift on return 
014D: F1            pop  af
014E: E6 10         and  $10			; Check bit 4
0150: CA 92 01      jp   z,$0192		; Initial sprite draw
	
0153: 79            ld   a,c
0154: 85            add  a,l
0155: 6F            ld   l,a
0156: E5            push hl
0157: 21 30 20      ld   hl,$2030
015A: 7E            ld   a,(hl)
015B: 2F            cpl
015C: E6 07         and  $07
015E: 77            ld   (hl),a
015F: E1            pop  hl
0160: D3 04         out  ($04),a 		; Update shift count
0162: C3 B8 01      jp   $01B8

	;; Update/redraw sprite
0165: 23            inc  hl
0166: 23            inc  hl
0167: 5E            ld   e,(hl)			; LSB of loc + shift
0168: 23            inc  hl
0169: 23            inc  hl
016A: 23            inc  hl
016B: 56            ld   d,(hl)			; MSB of loc
016C: 23            inc  hl
016D: 23            inc  hl
016E: CD 00 0A      call $0A00			; de >> 3, e&3 -> c
0171: 79            ld   a,c			; (shift)
0172: 32 30 20      ld   ($2030),a
0175: D3 04         out  ($04),a 		; Shifter count
0177: D5            push de			; Store screen loc
0178: 5E            ld   e,(hl)			; Read rom loc
0179: 23            inc  hl
017A: 56            ld   d,(hl)
017B: 23            inc  hl
017C: EB            ex   de,hl			; rom loc -> hl
017D: 4E            ld   c,(hl)			; Read bc (row/cols)
017E: 23            inc  hl
017F: 46            ld   b,(hl)
0180: 23            inc  hl
0181: E3            ex   (sp),hl 		; swap screen loc 
0182: EB            ex   de,hl			; Back to ram table
0183: 73            ld   (hl),e
0184: 23            inc  hl
0185: 72            ld   (hl),d
0186: 23            inc  hl
0187: 71            ld   (hl),c
0188: 34            inc  (hl)			; +1 wide for shifting?
0189: 23            inc  hl
018A: 70            ld   (hl),b
018B: 23            inc  hl
018C: 22 1C 20      ld   ($201C),hl
018F: EB            ex   de,hl			; hl = screen loc
0190: D1            pop  de			; de = sprite data in ROM
0191: C9            ret				; bc = bytes wide, pix high

	;; Initial sprite draw
0192: C5            push bc			; bc = bytes wide, pix high
0193: E5            push hl			; hl = screen loc
0194: 1A            ld   a,(de)			; Sprite byte
0195: 13            inc  de
0196: D3 03         out  ($03),a		; MB12421 data write
0198: DB 03         in   a,($03)		; MB12421 data read
019A: 77            ld   (hl),a			; Write to RAM
019B: 23            inc  hl
019C: 0D            dec  c
019D: C2 94 01      jp   nz,$0194 		; Loop for width
01A0: AF            xor  a
01A1: D3 03         out  ($03),a 		; MB12421 data write
01A3: DB 03         in   a,($03) 		; MB12421 data read
01A5: 77            ld   (hl),a			; Final write
01A6: 01 20 00      ld   bc,$0020 		; Row increment
01A9: E1            pop  hl
01AA: 09            add  hl,bc			; Next row
01AB: C1            pop  bc
01AC: 7D            ld   a,l
01AD: E6 E0         and  $E0
01AF: C2 92 01      jp   nz,$0192 		; Not bottom of screen
01B2: 7C            ld   a,h
01B3: 1F            rra
01B4: DA 92 01      jp   c,$0192 		; Not end of screen
01B7: C9            ret

	;; Finish sprite draw
01B8: C5            push bc
01B9: E5            push hl
01BA: 1A            ld   a,(de)
01BB: 13            inc  de
01BC: D3 03         out  ($03),a 		; Shifter input
01BE: DB 00         in   a,($00)		; Shifter output
01C0: 77            ld   (hl),a			; Write to screen
01C1: 2B            dec  hl
01C2: 0D            dec  c
01C3: C2 BA 01      jp   nz,$01BA 		; Loop for row
	
01C6: AF            xor  a
01C7: D3 03         out  ($03),a 		; Shifter input 
01C9: DB 00         in   a,($00)		; Shifter output
01CB: 77            ld   (hl),a			; Write to screen
01CC: 01 20 00      ld   bc,$0020		; Next line
01CF: E1            pop  hl
01D0: 09            add  hl,bc
01D1: C1            pop  bc
01D2: 7D            ld   a,l
01D3: E6 E0         and  $E0
01D5: C2 B8 01      jp   nz,$01B8 		; Loop
	
01D8: 7C            ld   a,h
01D9: 1F            rra
01DA: DA B8 01      jp   c,$01B8 		; Loop
01DD: C9            ret

	;; 
01DE: 7E            ld   a,(hl)
01DF: A7            and  a
01E0: F0            ret  p			; High bit clear = inactive
	
01E1: E5            push hl			; hl now delta X
01E2: 23            inc  hl
01E3: E6 07         and  $07			; Mask low 3 bits 
01E5: C2 ED 01      jp   nz,$01ED		; (is a ship)
	
01E8: 23            inc  hl
01E9: 23            inc  hl
01EA: C3 37 02      jp   $0237
	
01ED: 7E            ld   a,(hl)			; Delta X
01EE: 11 5F 21      ld   de,$215F		; Table for +
01F1: A7            and  a
01F2: F2 F8 01      jp   p,$01F8
	
01F5: 11 81 21      ld   de,$2181 		; Table for -
	
01F8: 47            ld   b,a			; b = delta x
01F9: 23            inc  hl			; (hl) = X
01FA: 86            add  a,(hl)			; a = x + dx
01FB: 77            ld   (hl),a			; store x
01FC: 78            ld   a,b			; a = delta X
01FD: A7            and  a
01FE: 7E            ld   a,(hl)	 		; a = X
01FF: F2 10 02      jp   p,$0210 		; (left to right)
	
0202: FE 01         cp   $01
0204: D2 16 02      jp   nc,$0216
	
0207: E3            ex   (sp),hl
0208: 7E            ld   a,(hl)
0209: E6 BF         and  $BF			; Clear bit 5
020B: 77            ld   (hl),a
020C: E3            ex   (sp),hl
020D: C3 16 02      jp   $0216
	
0210: 23            inc  hl
0211: BE            cp   (hl)			; End X
0212: 2B            dec  hl
0213: D2 07 02      jp   nc,$0207
0216: 7E            ld   a,(hl)
0217: 0F            rrca
0218: 0F            rrca
0219: 0F            rrca
021A: E6 1F         and  $1F
021C: 83            add  a,e
021D: 5F            ld   e,a
021E: E3            ex   (sp),hl
021F: 7E            ld   a,(hl)
0220: E3            ex   (sp),hl
0221: E6 07         and  $07
0223: 47            ld   b,a
0224: 23            inc  hl
0225: 7E            ld   a,(hl)
0226: 2F            cpl
0227: 3C            inc  a
0228: 0F            rrca
0229: 0F            rrca
022A: 0F            rrca
022B: E6 07         and  $07
022D: C6 03         add  a,$03
022F: EB            ex   de,hl
0230: 70            ld   (hl),b
0231: 23            inc  hl
0232: 3D            dec  a
0233: C2 30 02      jp   nz,$0230
0236: EB            ex   de,hl
0237: 11 2F 20      ld   de,$202F
023A: 1A            ld   a,(de)
023B: 2F            cpl
023C: 12            ld   (de),a
023D: C2 47 02      jp   nz,$0247
0240: 23            inc  hl
0241: 7E            ld   a,(hl)
0242: 23            inc  hl
0243: 86            add  a,(hl)
0244: 77            ld   (hl),a
0245: 23            inc  hl
0246: BE            cp   (hl)
0247: E1            pop  hl
0248: 37            scf
0249: C0            ret  nz
024A: 7E            ld   a,(hl)
024B: E6 BF         and  $BF
024D: 77            ld   (hl),a
024E: 37            scf
024F: C9            ret
0250: 7E            ld   a,(hl)
0251: A7            and  a
0252: F0            ret  p
0253: E5            push hl
0254: 23            inc  hl
0255: 23            inc  hl
0256: 4E            ld   c,(hl)
0257: 23            inc  hl
0258: 23            inc  hl
0259: 7E            ld   a,(hl)
025A: 23            inc  hl
025B: 46            ld   b,(hl)
025C: 80            add  a,b
025D: 77            ld   (hl),a
025E: 78            ld   a,b
025F: FE C0         cp   $C0
0261: D2 09 03      jp   nc,$0309
0264: FE 30         cp   $30
0266: D2 75 02      jp   nc,$0275
0269: 3A 24 20      ld   a,($2024)
026C: A7            and  a
026D: CA 75 02      jp   z,$0275
0270: 3C            inc  a
0271: 3C            inc  a
0272: 32 24 20      ld   ($2024),a
0275: 7E            ld   a,(hl)
0276: 23            inc  hl
0277: BE            cp   (hl)
0278: D2 9C 02      jp   nc,$029C
027B: 3E C0         ld   a,$C0
027D: 86            add  a,(hl)
027E: 77            ld   (hl),a
027F: 2B            dec  hl
0280: 2B            dec  hl
0281: 34            inc  (hl)
0282: 34            inc  (hl)
0283: 7E            ld   a,(hl)
0284: 23            inc  hl
0285: 23            inc  hl
0286: 23            inc  hl
0287: CA 96 02      jp   z,$0296
028A: 36 88         ld   (hl),$88
028C: FE FC         cp   $FC
028E: CA 9C 02      jp   z,$029C
0291: 36 98         ld   (hl),$98
0293: C3 9C 02      jp   $029C
0296: E3            ex   (sp),hl
0297: 7E            ld   a,(hl)
0298: E6 BF         and  $BF
029A: 77            ld   (hl),a
029B: E3            ex   (sp),hl
029C: 11 30 20      ld   de,$2030
029F: 1A            ld   a,(de)
02A0: A7            and  a
02A1: C2 09 03      jp   nz,$0309
02A4: 3C            inc  a
02A5: 12            ld   (de),a
02A6: 78            ld   a,b
02A7: E6 10         and  $10
02A9: CA 09 03      jp   z,$0309
02AC: 11 07 00      ld   de,$0007
02AF: 19            add  hl,de
02B0: 7E            ld   a,(hl)
02B1: A7            and  a
02B2: C2 C3 02      jp   nz,$02C3
02B5: 19            add  hl,de
02B6: 78            ld   a,b
02B7: 83            add  a,e
02B8: 47            ld   b,a
02B9: E6 10         and  $10
02BB: CA 09 03      jp   z,$0309
02BE: 7E            ld   a,(hl)
02BF: A7            and  a
02C0: CA 09 03      jp   z,$0309
02C3: E3            ex   (sp),hl
02C4: 7E            ld   a,(hl)
02C5: E6 BF         and  $BF
02C7: 77            ld   (hl),a
02C8: E3            ex   (sp),hl
02C9: 78            ld   a,b
02CA: D6 40         sub  $40
02CC: 47            ld   b,a
02CD: DA E0 02      jp   c,$02E0
02D0: 21 A1 21      ld   hl,$21A1
02D3: 23            inc  hl
02D4: 23            inc  hl
02D5: 7E            ld   a,(hl)
02D6: A7            and  a
02D7: C2 D3 02      jp   nz,$02D3
02DA: 70            ld   (hl),b
02DB: 23            inc  hl
02DC: 71            ld   (hl),c
02DD: C3 09 03      jp   $0309
02E0: 21 BE 21      ld   hl,$21BE
02E3: 23            inc  hl
02E4: 23            inc  hl
02E5: 23            inc  hl
02E6: 7E            ld   a,(hl)
02E7: A7            and  a
02E8: C2 E3 02      jp   nz,$02E3
02EB: 78            ld   a,b
02EC: C6 20         add  a,$20
02EE: 11 60 21      ld   de,$2160
02F1: FA F7 02      jp   m,$02F7
02F4: 11 82 21      ld   de,$2182
02F7: 79            ld   a,c
02F8: 0F            rrca
02F9: 0F            rrca
02FA: 0F            rrca
02FB: E6 1F         and  $1F
02FD: 83            add  a,e
02FE: 5F            ld   e,a
02FF: 1A            ld   a,(de)
0300: A7            and  a
0301: CA 09 03      jp   z,$0309
0304: 77            ld   (hl),a
0305: 23            inc  hl
0306: 71            ld   (hl),c
0307: 23            inc  hl
0308: 70            ld   (hl),b
0309: 37            scf
030A: E1            pop  hl
030B: C9            ret

	;; hl = Ship pointer
030C: 7E            ld   a,(hl)			; X flags?
030D: A7            and  a
030E: F0            ret  p			; Return if high bit not set
	
030F: E6 20         and  $20
0311: C8            ret  z			; Bit 5 clear = not active
	
0312: CD 5B 03      call $035B			; Get de, bc from bytes 9-d
	
0315: EB            ex   de,hl			; hl = read de
0316: 41            ld   b,c
0317: AF            xor  a
0318: E5            push hl			; Store loc

	;; Clear c bytes
0319: 77            ld   (hl),a
031A: 23            inc  hl
031B: 0D            dec  c
031C: C2 19 03      jp   nz,$0319
	
031F: 11 20 00      ld   de,$0020
0322: E1            pop  hl			; Get loc
0323: 19            add  hl,de 			; Next line
0324: 48            ld   c,b
0325: 7D            ld   a,l
0326: E6 E0         and  $E0
0328: C2 17 03      jp   nz,$0317 		; Loop
032B: 7C            ld   a,h
032C: 1F            rra
032D: DA 17 03      jp   c,$0317 		; Loop
0330: C9            ret

	
0331: 2A 14 20      ld   hl,($2014)
0334: 06 0A         ld   b,$0A			; Loop counter
0336: 7D            ld   a,l
0337: B4            or   h
0338: C2 3E 03      jp   nz,$033E
033B: 21 72 20      ld   hl,$2072 		; Reset to $2072
033E: 11 0D 00      ld   de,$000D
0341: 19            add  hl,de
0342: 05            dec  b
0343: C8            ret  z			; End of loop
	
0344: 7D            ld   a,l
0345: FE E7         cp   $E7			; hl == $20E7?
0347: C2 4D 03      jp   nz,$034D
	
034A: 21 7F 20      ld   hl,$207F 		; Reset to $207F
034D: 7E            ld   a,(hl)			; X flags
034E: A7            and  a
034F: F2 41 03      jp   p,$0341 		; MSB clear?
	
0352: 22 14 20      ld   ($2014),hl
0355: 23            inc  hl
0356: 7E            ld   a,(hl)			; Delta X
0357: 23            inc  hl
0358: 86            add  a,(hl)			; Add to X
0359: 77            ld   (hl),a			; Store X
035A: C9            ret

	;; Load de, bc from ship data
035B: 11 09 00      ld   de,$0009
035E: 19            add  hl,de
035F: 5E            ld   e,(hl)
0360: 23            inc  hl
0361: 56            ld   d,(hl)
0362: 23            inc  hl
0363: 4E            ld   c,(hl)
0364: 23            inc  hl
0365: 46            ld   b,(hl)
0366: 23            inc  hl
0367: C9            ret

	;; Called from ISR
0368: 3A 20 20      ld   a,($2020)
036B: A7            and  a
036C: C0            ret  nz
036D: 47            ld   b,a
036E: 21 03 20      ld   hl,$2003 		; Counter address
0371: 35            dec  (hl)			; Decrement counter
0372: C2 8E 03      jp   nz,$038E

	;; Counter zero
0375: 36 1E         ld   (hl),$1E 		; Reset counter
0377: 21 02 20      ld   hl,$2002		; Game timer
037A: 7E            ld   a,(hl)				
037B: A7            and  a
037C: CA 88 03      jp   z,$0388 		; Game over
037F: C6 99         add  a,$99
0381: 27            daa
0382: 77            ld   (hl),a			; Decrement game timer
0383: C2 88 03      jp   nz,$0388
0386: 06 01         ld   b,$01			; --> d7
0388: 21 10 20      ld   hl,$2010
038B: CD AE 03      call $03AE			; Handle $2010 timer d6

	;; Counter non-zero
038E: 21 11 20      ld   hl,$2011 			
0391: CD AE 03      call $03AE			; Handle $2011 timer d5
0394: 21 21 20      ld   hl,$2021
0397: CD AE 03      call $03AE			; Handle $2021 timer d4
039A: 23            inc  hl
039B: CD AE 03      call $03AE			; Handle $2022 timer d3
039E: 23            inc  hl
039F: CD AE 03      call $03AE			; Handle $2023 timer d2
03A2: 23            inc  hl
03A3: CD AE 03      call $03AE			; Handle $2024 timer d1
03A6: 23            inc  hl
03A7: CD AE 03      call $03AE			; Handle $2025 timer d0
03AA: 32 20 20      ld   ($2020),a
03AD: C9            ret

	;; Decrement timer, set bit if 0
03AE: 7E            ld   a,(hl)
03AF: A7            and  a
03B0: CA B8 03      jp   z,$03B8
03B3: 35            dec  (hl)
03B4: C2 B8 03      jp   nz,$03B8
03B7: 37            scf				; Set carry
	
	;; Shift 0 into b unless carry set above
03B8: 78            ld   a,b			
03B9: 17            rla
03BA: 47            ld   b,a
03BB: C9            ret

	;; Called from both interrupt routines
	;; Updates and redraw "wave"
03BC: 01 27 20      ld   bc,$2027
03BF: 0A            ld   a,(bc)
03C0: C6 0A         add  a,$0A			; $00 -> $0A -> $14 -> $1E = $00
03C2: FE 1E         cp   $1E
03C4: C2 C8 03      jp   nz,$03C8
03C7: AF            xor  a
03C8: 02            ld   (bc),a			; Store state
	
03C9: 03            inc  bc			; $2028
03CA: 5F            ld   e,a
03CB: 16 00         ld   d,$00
03CD: 21 F3 0B      ld   hl,$0BF3 		; Start of waves
03D0: 19            add  hl,de
03D1: EB            ex   de,hl			; de = wave table entry

03D2: 0A            ld   a,(bc)
03D3: 3C            inc  a
03D4: E6 1F         and  $1F			; Loops $00 to $1F
03D6: 02            ld   (bc),a

	;; Screen location
03D7: 21 E0 27      ld   hl,$27E0
03DA: 85            add  a,l
03DB: 6F            ld   l,a
03DC: 01 20 00      ld   bc,$0020 		; Next char
03DF: 1A            ld   a,(de)			; Get byte
03E0: 13            inc  de
03E1: 77            ld   (hl),a			; Write byte
03E2: 09            add  hl,bc			; Next char
03E3: 7D            ld   a,l
03E4: E6 E0         and  $E0
03E6: FE 60         cp   $60
03E8: C2 DF 03      jp   nz,$03DF 		; Loop	
03EB: C9            ret

	;; Test mode
03EC: 21 00 00      ld   hl,$0000 		; Start address
03EF: 11 00 00      ld   de,$0000		; Offset 0
03F2: 0E 02         ld   c,$02			; Until $200
03F4: AF            xor  a
03F5: 86            add  a,(hl)
03F6: 23            inc  hl
03F7: 47            ld   b,a
03F8: 79            ld   a,c
03F9: BC            cp   h
03FA: 78            ld   a,b
03FB: C2 F5 03      jp   nz,$03F5 		; Loop
	
03FE: E5            push hl			; Push address
	
03FF: 21 29 04      ld   hl,$0429 		; Checksum table
0402: 19            add  hl,de
0403: BE            cp   (hl)			; Compare checksum
0404: 3E 40         ld   a,$40			; _
0406: CA 0E 04      jp   z,$040E
0409: 21 32 04      ld   hl,$0432
040C: 19            add  hl,de
040D: 7E            ld   a,(hl)
040E: 21 E9 21      ld   hl,$21E9 		; Base screen loc
0411: 19            add  hl,de
0412: 77            ld   (hl),a			; Store char
	
0413: E1            pop  hl			; Get address back
0414: 13            inc  de			; Next rom
0415: 0C            inc  c			; $2 more pages
0416: 0C            inc  c
0417: 3E 12         ld   a,$12
0419: B9            cp   c
041A: C2 F4 03      jp   nz,$03F4 		; Loop if not done
	
041D: 21 E9 21      ld   hl,$21E9
0420: 11 08 30      ld   de,$3008
0423: 3E 08         ld   a,$08
0425: CD 30 0B      call $0B30			; Draw string hl @ de, length a
0428: 76            halt			; Stop!

	;; $200 block checksums
0429: 8D 79 00 1F 58 6D EA C5		; DATA Checksum 
	
0431: 2A					; DATA Patch byte for $400 checksum

	;; Error locations
0432: 48 48 47 47 46 46 45 45			; DATA HHGGFFEE

	;; Initial jump
043A: CD A2 08      call $08A2	 		; (End of game routine)
043D: DB 02         in   a,($02) 		; IN2
043F: E6 E0         and  $E0			; Test mode bits
0441: FE E0         cp   $E0
0443: CC EC 03      call z,$03EC 		; Go to test mode

	;; Clear $2002-$200a
0446: 21 02 20      ld   hl,$2002
0449: 3E 09         ld   a,$09
044B: 06 00         ld   b,$00
044D: 70            ld   (hl),b
044E: 23            inc  hl
044F: 3D            dec  a
0450: C2 4D 04      jp   nz,$044D
	
0453: 21 29 09      ld   hl,$0929
0456: 22 00 20      ld   ($2000),hl
0459: FB            ei				; Enable interrupts
	
045A: 21 59 04      ld   hl,$0459		; Return address
045D: E5            push hl
045E: 2A 00 20      ld   hl,($2000)
0461: 7E            ld   a,(hl)
0462: A7            and  a
0463: C2 7D 04      jp   nz,$047D

	;; a=(($2000)) == 0
0466: CD A4 06      call $06A4
0469: CD CE 04      call $04CE
046C: CD BF 04      call $04BF
046F: 3A 02 20      ld   a,($2002) 		; Game timer
0472: A7            and  a
0473: C8            ret  z			; Skip rest if game over
	
0474: CD 4C 07      call $074C
0477: CD B8 08      call $08B8
047A: C3 8C 04      jp   $048C

	;; a=(($2000)) != 0
047D: 23            inc  hl
047E: EB            ex   de,hl	  		; ($2000+1) --> de
047F: 21 E8 09      ld   hl,$09E8 		; Jump table
0482: 07            rlca			; a = ($2000)<<1
0483: 4F            ld   c,a			; c = ($2000)<<1
0484: 06 00         ld   b,$00
0486: 09            add  hl,bc			; hl = $09e8 + ($2000)<<1
0487: 7E            ld   a,(hl)
0488: 23            inc  hl
0489: 66            ld   h,(hl)
048A: 6F            ld   l,a
048B: E9            jp   (hl)
	
048C: 3A 03 20      ld   a,($2003)
048F: FE 1D         cp   $1D
0491: F8            ret  m
0492: 01 02 20      ld   bc,$2002
0495: 11 E9 21      ld   de,$21E9
0498: CD 82 0A      call $0A82
049B: EB            ex   de,hl
049C: CD 7A 0A      call $0A7A
049F: 23            inc  hl
04A0: 36 2C         ld   (hl),$2C
04A2: 23            inc  hl
04A3: EB            ex   de,hl
04A4: 01 2B 20      ld   bc,$202B 		; Player score
04A7: CD 82 0A      call $0A82			; Draw score digits
04AA: EB            ex   de,hl
04AB: CD 7A 0A      call $0A7A
04AE: 23            inc  hl
04AF: 36 30         ld   (hl),$30
04B1: 23            inc  hl
04B2: 36 30         ld   (hl),$30
04B4: 21 E9 21      ld   hl,$21E9
04B7: 11 2F 3E      ld   de,$3E2F
04BA: 3E 06         ld   a,$06
04BC: C3 30 0B      jp   $0B30			; Draw string hl @ de, length a
04BF: 21 2A 20      ld   hl,$202A
04C2: 7E            ld   a,(hl)
04C3: A7            and  a
04C4: C8            ret  z
04C5: 36 00         ld   (hl),$00
04C7: 21 A6 09      ld   hl,$09A6
04CA: 22 00 20      ld   ($2000),hl
04CD: C9            ret

	;; Choose subroutine based on $2020 bits
04CE: 21 20 20      ld   hl,$2020
04D1: 7E            ld   a,(hl)
04D2: A7            and  a
04D3: C8            ret  z	  		; Nothing to do
04D4: 36 00         ld   (hl),$00 		; Clear all bits
04D6: 1F            rra
04D7: DC 01 06      call c,$0601 		; Bit 0 set = Clear explosion lights
04DA: 1F            rra
04DB: DC 0E 06      call c,$060E 		; Bit 1 set = Clear explosion on screen
04DE: 1F            rra
04DF: DC F7 04      call c,$04F7 		; Bit 2 set = Trigger bit 2 sound	
04E2: 1F            rra
04E3: DC 34 06      call c,$0634 		; Bit 3 set = Launch new ship
04E6: 1F            rra
04E7: DC E9 05      call c,$05E9 		; Bit 4 set = Reload torpedos
04EA: 1F            rra
04EB: DC 73 05      call c,$0573 		; Bit 5 set = Increment $2000 counter
04EE: 1F            rra
04EF: DC 6C 05      call c,$056C 		; Bit 6 set = Initialize $2000 counter
04F2: 1F            rra
04F3: DC 11 05      call c,$0511  		; Bit 7 set = Game time over
04F6: C9            ret

	;; Bit 2 set on $2020
	;; Trigger bit 2 sound and set timers
04F7: F5            push af
04F8: 21 26 20      ld   hl,$2026
04FB: 7E            ld   a,(hl)
04FC: A7            and  a
04FD: CA 0F 05      jp   z,$050F 		; Do nothing
	
0500: 35            dec  (hl)
0501: 3E 04         ld   a,$04
0503: D3 05         out  ($05),a 		; Audio outputs
0505: 3E 19         ld   a,$19
0507: 32 23 20      ld   ($2023),a 		; Set timer
050A: 3E 0F         ld   a,$0F
050C: 32 25 20      ld   ($2025),a 		; Set timer
050F: F1            pop  af
0510: C9            ret

	;; Bit 7 set on $2020
0511: 21 2E 20      ld   hl,$202E
0514: 7E            ld   a,(hl)
0515: A7            and  a
0516: C2 3D 05      jp   nz,$053D 		; Jump if already extended time
	
0519: 36 01         ld   (hl),$01 		; Only 1 extend
051B: 3A 07 20      ld   a,($2007)		; Last IN1
051E: 0F            rrca
051F: E6 70         and  $70	 		; Base score for extended time (00 = none)
0521: CA 3D 05      jp   z,$053D 		; Jump if no extended time
	
0524: C6 09         add  a,$09			; $20 dip = $19(00) score
0526: 21 2B 20      ld   hl,$202B		; Player score
0529: BE            cp   (hl)
052A: D2 3D 05      jp   nc,$053D 		; Jump if score lower than metric
	
052D: 3E 20         ld   a,$20	
052F: 32 02 20      ld   ($2002),a 		; Set game time
0532: 21 33 0F      ld   hl,$0F33 		; EXTENDED_TIME
0535: 11 03 3C      ld   de,$3C03
0538: 3E 0C         ld   a,$0C
053A: C3 30 0B      jp   $0B30			; Draw string hl @ de, length a
	
053D: 21 C9 20      ld   hl,$20C9
0540: 01 1E 00      ld   bc,$001E
0543: 09            add  hl,bc
0544: 7D            ld   a,l
0545: FE 5F         cp   $5F
0547: CA 5C 05      jp   z,$055C
	
054A: 7E            ld   a,(hl)
054B: A7            and  a
054C: F2 43 05      jp   p,$0543
	
054F: AF            xor  a
0550: 32 21 20      ld   ($2021),a
0553: 32 2D 20      ld   ($202D),a 		; Torpedo status
0556: 3E 01         ld   a,$01
0558: 32 02 20      ld   ($2002),a
055B: C9            ret
	
055C: 21 29 09      ld   hl,$0929
055F: 22 00 20      ld   ($2000),hl
0562: 3A 2B 20      ld   a,($202B) 		; Player score
0565: 21 06 20      ld   hl,$2006		; High score
0568: BE            cp   (hl)
0569: D8            ret  c
056A: 77            ld   (hl),a			; Write new score
056B: C9            ret

	;; Bit 6 set on $2020
	;; Initialize $2000 counter
056C: 21 63 09      ld   hl,$0963
056F: 22 00 20      ld   ($2000),hl
0572: C9            ret

	;; Bit 5 set on $2020
	;; Increment $2000 counter
0573: 2A 00 20      ld   hl,($2000)
0576: 23            inc  hl
0577: 22 00 20      ld   ($2000),hl
057A: C9            ret

	;; Handle change in fire button
057B: C8            ret  z			; Not pressed
057C: 3A 02 20      ld   a,($2002)		; Game timer
057F: A7            and  a	
0580: C8            ret  z			; Not in game mode
	
0581: 3A 21 20      ld   a,($2021)
0584: A7            and  a
0585: C0            ret  nz			; Missile already active? 
	
0586: 21 2D 20      ld   hl,$202D 		; Torpedo status
0589: 7E            ld   a,(hl)
058A: E6 1F         and  $1F
058C: C8            ret  z			; ??
	
058D: 7E            ld   a,(hl)
058E: E6 0F         and  $0F			; Mask torp bits
0590: 1F            rra
0591: 06 20         ld   b,$20			; Bit 5 = Reload
0593: A7            and  a
0594: CA 99 05      jp   z,$0599
	
0597: 06 10         ld   b,$10			; Bit 4 = Ready
0599: B0            or   b
059A: 77            ld   (hl),a
059B: D3 02         out  ($02),a 		; Torpedo display
059D: 21 21 20      ld   hl,$2021
05A0: 36 08         ld   (hl),$08
05A2: E6 10         and  $10
05A4: C2 A9 05      jp   nz,$05A9
	
05A7: 36 3C         ld   (hl),$3C
05A9: 3E 02         ld   a,$02
05AB: D3 05         out  ($05),a 		; Audio outputs
05AD: 3E 0F         ld   a,$0F
05AF: 32 25 20      ld   ($2025),a 		; Set timer
05B2: 21 C9 20      ld   hl,$20C9
05B5: 11 1E 00      ld   de,$001E
05B8: 19            add  hl,de
05B9: 7E            ld   a,(hl)
05BA: A7            and  a
05BB: FA B8 05      jp   m,$05B8
	
05BE: 11 08 00      ld   de,$0008
05C1: 19            add  hl,de
05C2: 36 0E         ld   (hl),$0E
05C4: 2B            dec  hl
05C5: 36 75         ld   (hl),$75
05C7: 2B            dec  hl
05C8: 36 9C         ld   (hl),$9C
05CA: 2B            dec  hl
05CB: 36 E0         ld   (hl),$E0
05CD: 2B            dec  hl
05CE: 36 FA         ld   (hl),$FA
05D0: 2B            dec  hl
05D1: 2B            dec  hl
05D2: 11 5E 0F      ld   de,$0F5E 		; Grey code table?
05D5: EB            ex   de,hl
05D6: 3A 08 20      ld   a,($2008)
05D9: E6 1F         and  $1F
05DB: 4F            ld   c,a
05DC: 06 00         ld   b,$00
05DE: 09            add  hl,bc
05DF: 7E            ld   a,(hl)
05E0: EB            ex   de,hl
05E1: 77            ld   (hl),a
05E2: 2B            dec  hl
05E3: 36 00         ld   (hl),$00
05E5: 2B            dec  hl
05E6: 36 C0         ld   (hl),$C0
05E8: C9            ret

	;; Bit 4 set on $2020
	;; Reset torpedo status after reload
05E9: F5            push af
05EA: 21 2D 20      ld   hl,$202D 		; Torpedo status
05ED: 7E            ld   a,(hl)
05EE: E6 10         and  $10			; Check ready
05F0: C2 FF 05      jp   nz,$05FF
	
05F3: 3E 1F         ld   a,$1F	 		; Reset torpedo status
05F5: D3 02         out  ($02),a 		; Torpedo lamps
05F7: 77            ld   (hl),a
05F8: 3E 08         ld   a,$08
05FA: D3 05         out  ($05),a 		; Audio outputs
05FC: CD EA 07      call $07EA
05FF: F1            pop  af
0600: C9            ret

	;; Bit 0 set on $2020
	;; Clear explosions
0601: F5            push af
0602: AF            xor  a
0603: D3 05         out  ($05),a 		; Audio outputs
0605: D3 01         out  ($01),a		; Explosion lamp
0607: 3A 2D 20      ld   a,($202D) 		; Torpedo status
060A: D3 02         out  ($02),a 		; Periscope lamp
060C: F1            pop  af
060D: C9            ret

	;; Bit 1 set on $2020
060E: F5            push af
060F: 21 F0 21      ld   hl,$21F0
0612: 7E            ld   a,(hl)
0613: A7            and  a
0614: CA 32 06      jp   z,$0632

	;; ($21f0) -> de
0617: 36 00         ld   (hl),$00
0619: 23            inc  hl
061A: 57            ld   d,a
061B: 5E            ld   e,(hl)
061C: 36 00         ld   (hl),$00
061E: 23            inc  hl
061F: FE 2C         cp   $2C
0621: 01 03 0A      ld   bc,$0A03 		; 20 x 3 byte area  (after ship hit)
0624: DA 2A 06      jp   c,$062A
0627: 01 05 20      ld   bc,$2005 		; 32 x 5 byte area  (after mine hit)
062A: EB            ex   de,hl
062B: CD 3F 0A      call $0A3F			; Clear area at hl
062E: EB            ex   de,hl
062F: C3 12 06      jp   $0612			; Repeat
0632: F1            pop  af
0633: C9            ret

	;; Bit 3 set on $2020
	;; Launch new ship
0634: F5            push af
0635: 3A 03 20      ld   a,($2003)
0638: E6 0F         and  $0F
063A: F6 50         or   $50
063C: 32 22 20      ld   ($2022),a 		; Set counter
	
063F: 01 29 20      ld   bc,$2029 		; Ship type loc
0642: 0A            ld   a,(bc)			; Get ship index
0643: 3C            inc  a			; Increment
0644: FE 07         cp   $07			; Max = 6
0646: C2 4A 06      jp   nz,$064A
0649: AF            xor  a			; Set to 0
064A: 02            ld   (bc),a			; Store ship index
	
064B: 21 DE 0F      ld   hl,$0FDE 		; Ship type table
064E: 85            add  a,l
064F: 6F            ld   l,a
0650: 7E            ld   a,(hl)			; Get ship type
0651: 47            ld   b,a			; Stash in b
0652: FE 06         cp   $06			; Is small / fast?
0654: C2 6B 06      jp   nz,$066B		; No = jump
	
0657: 3E 04         ld   a,$04
0659: D3 05         out  ($05),a 		; Audio outputs
065B: 3E 19         ld   a,$19
065D: 32 23 20      ld   ($2023),a 		; Set timer
0660: 3E 02         ld   a,$02
0662: 32 26 20      ld   ($2026),a 		; Set timer
0665: 3E 0F         ld   a,$0F
0667: 32 25 20      ld   ($2025),a 		; Set timer
066A: 78            ld   a,b
	
	;; hl = $202c + $0d * a 
066B: 21 2C 20      ld   hl,$202C
066E: 11 0D 00      ld   de,$000D
0671: 19            add  hl,de
0672: 3D            dec  a
0673: C2 71 06      jp   nz,$0671
	
0676: 78            ld   a,b
0677: EB            ex   de,hl
	
0678: 21 1E 20      ld   hl,$201E 		; Current ship move index
067B: 7E            ld   a,(hl)			; Read ship move index
067C: 34            inc  (hl)			; Increment ship move index
067D: 21 7E 0F      ld   hl,$0F7E 		; Even ship move table?
0680: 1F            rra
0681: D2 8B 06      jp   nc,$068B
	
0684: 21 AE 0F      ld   hl,$0FAE 		; Odd ship move table?
0687: 78            ld   a,b
0688: F6 10         or   $10			; Set direction bit
068A: 47            ld   b,a
	
068B: 78            ld   a,b

	;; Index into ship type table
068C: 3D            dec  a			; a = 0-5 / 10-14
068D: 07            rlca
068E: 07            rlca
068F: 07            rlca
0690: E6 38         and  $38			; Clear low bits
0692: 85            add  a,l
0693: 6F            ld   l,a

	;; Copy ship table data
0694: 0E 08         ld   c,$08
0696: 7E            ld   a,(hl)
0697: 23            inc  hl
0698: 12            ld   (de),a
0699: 1B            dec  de
069A: 0D            dec  c
069B: C2 96 06      jp   nz,$0696
	
069E: 78            ld   a,b
069F: F6 C0         or   $C0			; B7 = moving, B6 = don't clear, B5 = ??
06A1: 12            ld   (de),a			; Store ship type?
06A2: F1            pop  af
06A3: C9            ret

	;; Called when (($2000)) == 0
06A4: 21 C1 21      ld   hl,$21C1
06A7: 7E            ld   a,(hl)
06A8: A7            and  a
06A9: C8            ret  z			; Skip if $21C1 = 00
	
06AA: 36 00         ld   (hl),$00 		; Clear $21C1
06AC: 23            inc  hl
06AD: 56            ld   d,(hl)			; ($21C2) -> d
06AE: E5            push hl

	;; hl = $2024 + $d * a
06AF: 21 24 20      ld   hl,$2024
06B2: 01 0D 00      ld   bc,$000D
06B5: 09            add  hl,bc
06B6: 3D            dec  a
06B7: C2 B5 06      jp   nz,$06B5
	
06BA: 01 08 00      ld   bc,$0008
06BD: 09            add  hl,bc
	
06BE: 36 0E         ld   (hl),$0E
06C0: 2B            dec  hl
06C1: 36 55         ld   (hl),$55
06C3: 2B            dec  hl
06C4: 2B            dec  hl
06C5: 2B            dec  hl
06C6: 36 01         ld   (hl),$01
06C8: 2B            dec  hl
06C9: 2B            dec  hl
06CA: 72            ld   (hl),d
06CB: 2B            dec  hl
06CC: 36 00         ld   (hl),$00
06CE: 2B            dec  hl
06CF: 46            ld   b,(hl)
06D0: 36 E0         ld   (hl),$E0
	
06D2: 3A 02 20      ld   a,($2002) 		; Ship hit score?
06D5: A7            and  a
06D6: C2 DB 06      jp   nz,$06DB
06D9: E1            pop  hl
06DA: C9            ret
	
06DB: 78            ld   a,b
06DC: 01 57 0F      ld   bc,$0F57 		; Ship hit score table
06DF: E6 07         and  $07
06E1: 81            add  a,c
06E2: 4F            ld   c,a			; bc = index into table	
	
06E3: 11 E9 21      ld   de,$21E9
06E6: CD 82 0A      call $0A82
06E9: 3E 30         ld   a,$30
06EB: 12            ld   (de),a
06EC: 13            inc  de
06ED: 12            ld   (de),a
06EE: 0A            ld   a,(bc)
06EF: 21 2B 20      ld   hl,$202B 		; Player score
06F2: 86            add  a,(hl)			; Add a
06F3: 27            daa
06F4: 77            ld   (hl),a			; Store
06F5: E1            pop  hl
06F6: 4E            ld   c,(hl)
06F7: 23            inc  hl
06F8: 46            ld   b,(hl)
06F9: 23            inc  hl
06FA: E5            push hl
06FB: 78            ld   a,b
06FC: C6 20         add  a,$20
06FE: 21 C2 09      ld   hl,$09C2 		; Explosion lamp 0-7 table
0701: DA 07 07      jp   c,$0707
0704: 21 BA 09      ld   hl,$09BA 		; Explosion lamp 8-F table
0707: 79            ld   a,c
0708: 07            rlca
0709: 07            rlca
070A: 07            rlca
070B: E6 07         and  $07
070D: 85            add  a,l
070E: 6F            ld   l,a
070F: 7E            ld   a,(hl)
0710: D3 01         out  ($01),a 		; Explosion lamp
0712: 3E 01         ld   a,$01
0714: D3 05         out  ($05),a 		; Audio write
0716: 3E 1E         ld   a,$1E
0718: 32 25 20      ld   ($2025),a 		; Set timer
071B: 78            ld   a,b
071C: 16 24         ld   d,$24
071E: C6 20         add  a,$20
0720: FA 25 07      jp   m,$0725
0723: 16 28         ld   d,$28
0725: 79            ld   a,c
0726: 0F            rrca
0727: 0F            rrca
0728: 0F            rrca
0729: E6 1F         and  $1F
072B: CA 2F 07      jp   z,$072F
072E: 3D            dec  a
072F: FE 1E         cp   $1E
0731: C2 35 07      jp   nz,$0735
0734: 3D            dec  a
0735: F6 A0         or   $A0
0737: 5F            ld   e,a
0738: CD DB 07      call $07DB
073B: 3E 2D         ld   a,$2D
073D: 32 24 20      ld   ($2024),a
0740: 21 EA 21      ld   hl,$21EA
0743: 3E 03         ld   a,$03
0745: CD 30 0B      call $0B30			; Draw string hl @ de, length a
0748: E1            pop  hl
0749: C3 A7 06      jp   $06A7
	
074C: 21 A3 21      ld   hl,$21A3
074F: 7E            ld   a,(hl)
0750: A7            and  a
0751: C8            ret  z
	
0752: 23            inc  hl
0753: C6 10         add  a,$10
0755: 07            rlca
0756: 07            rlca
0757: 07            rlca
0758: E6 07         and  $07
075A: 11 67 20      ld   de,$2067
075D: 01 0D 00      ld   bc,$000D
0760: EB            ex   de,hl
0761: 09            add  hl,bc
0762: 09            add  hl,bc
0763: 3D            dec  a
0764: C2 61 07      jp   nz,$0761
	
0767: 1A            ld   a,(de)
0768: D6 08         sub  $08
076A: 96            sub  (hl)
076B: FE EC         cp   $EC
076D: D2 71 07      jp   nc,$0771
	
0770: 09            add  hl,bc
0771: 2B            dec  hl
0772: 2B            dec  hl
0773: 36 00         ld   (hl),$00
0775: EB            ex   de,hl
0776: 2B            dec  hl
0777: 7E            ld   a,(hl)
0778: C6 30         add  a,$30
077A: E6 F0         and  $F0
077C: 57            ld   d,a
077D: 36 00         ld   (hl),$00
077F: 23            inc  hl
0780: 5E            ld   e,(hl)
0781: 23            inc  hl
0782: E5            push hl
0783: CD 00 0A      call $0A00
	
0786: 7B            ld   a,e
0787: E6 1F         and  $1F
0789: CA 96 07      jp   z,$0796
	
078C: 3D            dec  a
078D: CA 96 07      jp   z,$0796
	
0790: 3D            dec  a
0791: FE 1C         cp   $1C
	
0793: F2 90 07      jp   p,$0790
0796: 5F            ld   e,a
0797: CD DB 07      call $07DB
	
079A: 42            ld   b,d
079B: 04            inc  b
079C: 04            inc  b
079D: 4B            ld   c,e
079E: 0C            inc  c
079F: C5            push bc
07A0: 7B            ld   a,e
07A1: C6 60         add  a,$60
07A3: 5F            ld   e,a
07A4: D5            push de
07A5: 42            ld   b,d
07A6: 0C            inc  c
07A7: C5            push bc
07A8: 3E 1E         ld   a,$1E
07AA: 32 25 20      ld   ($2025),a 		; Set timer
07AD: 3E 0F         ld   a,$0F
07AF: 32 24 20      ld   ($2024),a
07B2: 3E 10         ld   a,$10
07B4: D3 05         out  ($05),a 		; Sound write
07B6: 7B            ld   a,e
07B7: E6 02         and  $02	  		; Mask bit 1
07B9: 21 40 0F      ld   hl,$0F40 		; $0F40 or $0F42
07BC: 85            add  a,l
07BD: 6F            ld   l,a			; hl = ZAP or WAM

	;; Get address from table -> hl
07BE: 5E            ld   e,(hl)
07BF: 23            inc  hl
07C0: 56            ld   d,(hl)
07C1: EB            ex   de,hl			; hl = table entry
	
07C2: D1            pop  de
07C3: 7E            ld   a,(hl)
07C4: 23            inc  hl
07C5: CD 30 0B      call $0B30			; Draw string hl @ de, length a
	
07C8: D1            pop  de
07C9: 7E            ld   a,(hl)
07CA: 23            inc  hl
07CB: CD 30 0B      call $0B30			; Draw string hl @ de, length a
	
07CE: D1            pop  de
07CF: 21 B5 0E      ld   hl,$0EB5
07D2: 3E 03         ld   a,$03
07D4: CD 30 0B      call $0B30			; Draw string hl @ de, length a
07D7: E1            pop  hl
07D8: C3 4F 07      jp   $074F
07DB: 21 F0 21      ld   hl,$21F0
07DE: 7E            ld   a,(hl)
07DF: 23            inc  hl
07E0: B6            or   (hl)
07E1: 23            inc  hl
07E2: C2 DE 07      jp   nz,$07DE
07E5: 2B            dec  hl
07E6: 73            ld   (hl),e
07E7: 2B            dec  hl
07E8: 72            ld   (hl),d
07E9: C9            ret
	
07EA: 3A 2B 20      ld   a,($202B) 		; Player score
07ED: FE 40         cp   $40			
07EF: DA F4 07      jp   c,$07F4
07F2: 3E 39         ld   a,$39	   		; Min of score or $39
07F4: 32 2C 20      ld   ($202C),a 		
	
07F7: 21 7F 20      ld   hl,$207F 		; 1st mine sprite
07FA: 11 50 50      ld   de,$5050
	
07FD: 7E            ld   a,(hl)
07FE: A7            and  a
07FF: FA 35 08      jp   m,$0835

	;; Launch mine?
0802: 01 08 00      ld   bc,$0008
0805: 09            add  hl,bc
0806: 36 0E         ld   (hl),$0E 		; Mine MSB (+8)
0808: 2B            dec  hl
0809: 36 A3         ld   (hl),$A3 		; Mine LSB (+7)
080B: 2B            dec  hl
080C: 2B            dec  hl
080D: 73            ld   (hl),e			; Y Pos (+5)
080E: 2B            dec  hl
080F: 70            ld   (hl),b			; Delta Y (+4)
0810: 2B            dec  hl
0811: 2B            dec  hl
0812: 72            ld   (hl),d			; X Pos (+2)
0813: 2B            dec  hl
0814: 36 01         ld   (hl),$01 		; Delta X (+1)
0816: 2B            dec  hl
0817: 36 80         ld   (hl),$80 		; Flags
0819: 7A            ld   a,d
081A: C6 51         add  a,$51
081C: 57            ld   d,a
081D: 1F            rra
081E: DA 2E 08      jp   c,$082E
	
0821: 3A 2C 20      ld   a,($202C)
0824: D6 10         sub  $10
0826: F8            ret  m
	
0827: 32 2C 20      ld   ($202C),a
082A: 7B            ld   a,e
082B: C6 20         add  a,$20
082D: 5F            ld   e,a
	
082E: 01 0D 00      ld   bc,$000D 		; Increment
0831: 09            add  hl,bc			; Next mine
0832: C3 FD 07      jp   $07FD			; More mines!

	
0835: E5            push hl
0836: D5            push de
0837: 23            inc  hl
0838: 23            inc  hl
0839: 5E            ld   e,(hl)
083A: 23            inc  hl
083B: 23            inc  hl
083C: 23            inc  hl
083D: 56            ld   d,(hl)
083E: CD 00 0A      call $0A00
0841: EB            ex   de,hl
0842: 01 02 10      ld   bc,$1002 		; 16 x 2 byte area
0845: CD 3F 0A      call $0A3F			; Clear area at hl
0848: D1            pop  de
0849: E1            pop  hl
084A: C3 02 08      jp   $0802
	
084D: C8            ret  z
084E: AF            xor  a
084F: 32 06 20      ld   ($2006),a
0852: 3A 10 20      ld   a,($2010)
0855: A7            and  a
0856: C8            ret  z
0857: 21 E9 21      ld   hl,$21E9
085A: E5            push hl
085B: 01 30 04      ld   bc,$0430
085E: 71            ld   (hl),c
085F: 23            inc  hl
0860: 05            dec  b
0861: C2 5E 08      jp   nz,$085E
0864: E1            pop  hl
0865: 11 25 3E      ld   de,$3E25
0868: 3E 04         ld   a,$04
086A: C3 30 0B      jp   $0B30			; Draw string hl @ de, length a

	;; $09E8 Entry B -- ??
086D: EB            ex   de,hl			; Sequence back to hl
086E: 22 00 20      ld   ($2000),hl		; Store
	
0871: 3A 03 20      ld   a,($2003) 		;
0874: E6 07         and  $07			; Mask low 3 bits
0876: FE 07         cp   $07			; == $07?
0878: C2 7C 08      jp   nz,$087C
087B: AF            xor  a			; Clear
087C: 32 29 20      ld   ($2029),a		; Write
087F: C9            ret

	;; End of game clears
0880: F3            di
0881: EB            ex   de,hl			; Stash hl in de
0882: 22 00 20      ld   ($2000),hl
0885: AF            xor  a
0886: D3 02         out  ($02),a 		; Clear periscope lamp
0888: D3 05         out  ($05),a		; Clear audio latches
088A: D3 01         out  ($01),a		; Clear explosion lamp
088C: E1            pop  hl			; (Return address)
088D: 01 00 00      ld   bc,$0000
0890: 11 00 00      ld   de,$0000
0893: 3E 10         ld   a,$10
0895: 31 10 40      ld   sp,$4010 		 ; Clear $4010 down to $2011
0898: C5            push bc
0899: 13            inc  de
089A: BA            cp   d
089B: C2 98 08      jp   nz,$0898 		; Loop
089E: 31 00 24      ld   sp,$2400
08A1: E9            jp   (hl)

	;; $09E8 Entry 3 (End game)
08A2: E1            pop  hl
08A3: 22 09 20      ld   ($2009),hl
08A6: CD 80 08      call $0880
08A9: 2A 09 20      ld   hl,($2009)
08AC: E5            push hl
08AD: 21 04 0F      ld   hl,$0F04 		; Water
08B0: 11 E0 27      ld   de,$27E0
08B3: 3E 20         ld   a,$20
08B5: C3 30 0B      jp   $0B30			; Draw string hl @ de, length a
08B8: DB 01         in   a,($01)		; IN0
08BA: 47            ld   b,a
08BB: DB 01         in   a,($01) 		; IN0
08BD: 21 08 20      ld   hl,$2008		; Last IN0
08C0: 11 DA 09      ld   de,$09DA 		; Jump table for IN0
08C3: B8            cp   b
08C4: CC 05 0B      call z,$0B05 		; Handle inputs

	;; Jump table do nothing routine
08C7: C9            ret				; (reset)

	;; Handle coin
08C8: C8            ret  z			; No coin
08C9: 3E 20         ld   a,$20
08CB: D3 05         out  ($05),a
08CD: 3E 0F         ld   a,$0F
08CF: 32 25 20      ld   ($2025),a 		; Set timer
08D2: 3A 07 20      ld   a,($2007)
08D5: 47            ld   b,a
08D6: 21 04 20      ld   hl,$2004
08D9: 34            inc  (hl)
08DA: E6 04         and  $04
08DC: CA E2 08      jp   z,$08E2
08DF: 7E            ld   a,(hl)
08E0: 0F            rrca
08E1: D8            ret  c
08E2: 36 00         ld   (hl),$00
08E4: 23            inc  hl
08E5: 34            inc  (hl)
08E6: 78            ld   a,b
08E7: E6 08         and  $08
08E9: CA F4 08      jp   z,$08F4
08EC: 34            inc  (hl)
08ED: 78            ld   a,b
08EE: E6 04         and  $04
08F0: CA F4 08      jp   z,$08F4
08F3: 34            inc  (hl)
08F4: 7E            ld   a,(hl)
08F5: E6 0F         and  $0F
08F7: 77            ld   (hl),a
08F8: C8            ret  z
08F9: 3A 02 20      ld   a,($2002)
08FC: A7            and  a
08FD: C0            ret  nz
08FE: 21 05 20      ld   hl,$2005
0901: 7E            ld   a,(hl)
0902: A7            and  a
0903: CA 1A 09      jp   z,$091A
0906: 35            dec  (hl)
	
0907: DB 01         in   a,($01) 		; IN1
0909: 07            rlca
090A: 07            rlca
090B: E6 03         and  $03			; Game time dips
090D: 11 54 0F      ld   de,$0F54
0910: 83            add  a,e
0911: 5F            ld   e,a
0912: 1A            ld   a,(de)
0913: 32 02 20      ld   ($2002),a 		; Store time
0916: 32 2A 20      ld   ($202A),a		; Store time ?
0919: C9            ret
	
091A: 3A 07 20      ld   a,($2007)
091D: E6 0C         and  $0C
091F: FE 0C         cp   $0C
0921: C0            ret  nz
0922: 2B            dec  hl
0923: 7E            ld   a,(hl)
0924: A7            and  a
0925: C8            ret  z
0926: C3 06 09      jp   $0906

	;; $2000 at reset
0929: 04					; DATA Command 4 = String
092A: 01					; DATA Length
092B: B8 0E					; DATA String src address
092D: 30 3E					; DATA Screen dst address

092F: 09					; DATA Commnad 9
0930: 05 20					; DATA ($2005) -> a   (select string)
0932: 33 38					; DATA Location
0934: E6 0E					; DATA "Insert Coin"
0936: F1 0E					; DATA "Push Button"

0938: 04					; DATA Command 4 = String
0939: 1A					; DATA Length 
093A: CC 0E					; DATA String src address
093C: 02 3C					; DATA Screen dst address
	
093E: 0A					; DATA Command A = BCD @ loc
093F: 06 20					; DATA bc = 2006 = high score
0941: E9 21					; DATA Buffer loc
0943: 25 3E					; DATA Screen loc
	
0945: 0A					; DATA Command A = BCD @ loc
0946: 2B 20					; DATA bc = 202b = score
0947: E9 21					; DATA Buffer loc
0949: 35 3E					; DATA Screen loc
	
094C: 02					; DATA Command 2 = arg to 2010
094D: 0F					; DATA arg

094E: 04					; DATA Command 4 = String
094F: 09					; DATA Length
0950: C3 0E					; DATA String src address
0952: 0B 2C					; DATA Screen dst address
        
	;; Delay timer
0954: 01					; DATA Command 1 = arg to 2011
0955: 1E					; DATA arg
0956: 00					; DATA End of sequence

	
0957: 04					; DATA Command 4 = String
0958: 09					; DATA Length
0959: B8 0E					; DATA String src address
095B: 0B 2C					; Screen dst address

	;; Delay timer
095D: 01					; Command 1 = arg to 2011
095E: 1E					; DATA arg
095F: 00					; DATA End of sequence

	
0960: 06					; DATA Command 6 = Set ($2000)
0961: 4E 09					; DATA Next command address
	
0963: 03            				; DATA Do end of game sequence
	
0964: 04					; DATA Command 4 = String
0965: 08					; DATA Length
0966: FC 0E					; DATA String src address (SEA WOLF)
0966: 0C 2C					; DATA Screen dst address

096A: 04					; DATA Command 4 = String
096B: 0A					; DATA Length
096C: CC 0E					; DATA String src address (HIGH SCORE)
096E: 02 3C					; DATA Screen dst address
	
0970: 0A					; DATA Command A = BCD @ loc
0971: 06 20					; DATA bc = 2006 = high score
0973: E9 21					; DATA Buffer loc
0975: 25 3E					; DATA Screen loc
	
0977: 09					; DATA Commnad 9
0978: 05 20					; DATA ($2005) -> a   (select string)
097A: 33 38					; DATA Location
097B: E6 0E					; DATA "Insert Coin"
097D: F1 0E					; DATA "Push Button"

	;; Delay timer
097F: 01					; DATA Command 1 = arg to 2011
0981: 5A					; DATA arg
0982: 00					; DATA End of sequence

	;; Launch ship in attract
0983: 08					; DATA Command 8 (Data backwards to loc)
0984: 09					; DATA Count
0985: 60 20					; DATA de = $2060
0986: EB 0D					; DATA $0DBE -> ($205F-2060)
0989: 20					; DATA $20   -> ($205E)
098A: 15					; DATA $15 	-> ($205D)
098B: 00					; DATA $00   -> ($205C)
098C: E0					; DATA $E0   -> ($205B)
098D: 00					; DATA $00   -> ($205A)
098E: 01					; DATA $01	-> ($2059)
098F: C4					; DATA $C4	-> ($2058)

	;; Delay timer
0990: 01					; DATA Command 1 = arg to 2011
0991: 5A					; DATA arg
0992: 00					; DATA End of sequence

	;; Launch missile in attract
0993: 08					; DATA Command 8 (Data backwards to loc)
0994: 09					; DATA Count
0995: EF 20					; DATA de = $20EF
0996: 75 0E					; DATA $0E75 -> ($20EE-20EF)
0998: 9C					; DATA $9C	-> ($20ED)
099A: E0					; DATA $E0	-> ($20EC)
099B: FA					; DATA $FA	-> ($20EB)
099C: 00					; DATA $00	-> ($20EA)
099d: A8					; DATA $A8	-> ($20E9)
099E: 00					; DATA $00	-> ($20E8)
099F: C0					; DATA $C0	-> ($20E7)

	;; Delay timer
09A0: 01					; DATA Command 1 = arg to 2011
09A1: B4					; DATA arg
09A2: 00					; DATA End of sequence
	
09A3: 06					; DATA Command 6 = Set ($2000)
09A4: 63 09					; DATA Next command address
        
	;; Delay timer
09A6: 01					; DATA Command 1 = arg to 2011
09A7: 0F					; DATA arg
09A8: 00					; DATA End of sequence
	
09A9: 03					; DATA Coomand 3 = End game
       	
09AA: 04					; DATA Command 4 = String
09AB: 09					; DATA Length
09AC: 29 0F					; DATA String src address (TIME/SCORE)
09AE: 0E 3C					; DATA Screen dst address
	
09B0: 07					; DATA Command 7 = Store a to bc
09B1: 28					; DATA a
09B2: 22 20					; DATA bc

09B4: 07					; DATA Command 7 = Store a to bc
09B5: 0A					; DATA a
09B6: 21 20					; DATA bc

09B8: 0B					; DATA Command B = ??
09B9: 00					; DATA End of sequence

	;; Explosion lamp tables!
	;; Table for $0704
09BA: 48 44 42 41 88 84 82 81		; DATA 
	
	;; Table for $06FE
09C2: 18 14 12 11 28 24 22 21		; DATA 

	
	;; Jump table for IN1 changes (8 entries)
09CA: C8 08					; DATA 0 = 08C8 = Coin
09CC: F8 08					; DATA 1 = 08F8 = Start
09CE: C7 08					; DATA 2 = 08C7 = (ret) Coinage
09D0: C7 08					; DATA 3 = 08C7 = (ret) Coinage
09D2: 4D 08					; DATA 4 = 084D = Erase highs
09D4: C7 08					; DATA 5 = 08C7 = (ret) Extended time
09D6: C7 08					; DATA 6 = 08C7 = (ret) Extended time
09D8: C7 08					; DATA 7 = 08C7 = (ret) Extended time

	;; Jump table for IN0 changes (8 entries)
09DA: C7 08					; DATA 0 = 08C7 = (ret) Turret
09DC: C7 08					; DATA 1 = 08C7 = (ret) Turret
09DE: C7 08					; DATA 2 = 08C7 = (ret) Turret
09E0: C7 08					; DATA 3 = 08C7 = (ret) Turret
09E2: C7 08					; DATA 4 = 08C7 = (ret) Turret
09E4: 7B 05					; DATA 5 = 057B = Fire button
09E6: C7 08					; DATA 6 = 08C7 = (ret) Time
09E8: C7 08					; DATA 7 = 08C7 = (ret) Time

	;; Jump table for $047F (0 entry not used)
09EA: 7C 0B					; DATA 1 = 0B7C = Arg to 2011
09EC: 72 0B					; DATA 2 = 0B72 = Arg to 2010
09EE: A2 08					; DATA 3 = 08A2 = End of game reset
09F0: 22 0B					; DATA 4 = 0B22 = String
09F2: ED 0A					; DATA 5 = 0AED = d <- (hl++), ret
09F4: 86 0B					; DATA 6 = 0B86 = (de) -> $2000 
09F6: E1 0A					; DATA 7 = 0AE1 = val -> addr
09F8: 9F 0A					; DATA 8 = 0A9F = data to loc
09FA: BC 0A					; DATA 9 = 0ABC = Select String
09FC: 53 0A					; DATA A = 0A53 = BCD @ location
09FE: 6D 08					; DATA B = 086D

	;; e&$07 -> c,  de = de >> 3 + $2400, 
0A00: 7B            ld   a,e			; Mask e
0A01: E6 07         and  $07
0A03: 4F            ld   c,a			; Stash in a
0A04: 06 03         ld   b,$03
0A06: AF            xor  a			; a=0, clc
0A07: 7A            ld   a,d
0A08: 1F            rra
0A09: 57            ld   d,a
0A0A: 7B            ld   a,e
0A0B: 1F            rra
0A0C: 5F            ld   e,a
0A0D: 05            dec  b
0A0E: C2 06 0A      jp   nz,$0A06
0A11: 7A            ld   a,d
0A12: C6 24         add  a,$24
0A14: 57            ld   d,a
0A15: C9            ret

	;; Entry 7 continues
0A16: F5            push af			; Store count
0A17: 7E            ld   a,(hl)			; Get value
0A18: 02            ld   (bc),a			; Store value
0A19: 03            inc  bc			
0A1A: EB            ex   de,hl
0A1B: B6            or   (hl)
0A1C: 23            inc  hl
0A1D: 12            ld   (de),a

	;; $09E8 Entry 7
0A1E: F1            pop  af			; count = a
0A1F: E5            push hl
0A20: 21 20 00      ld   hl,$0020 		
0A23: 19            add  hl,de			; hl = de+$0020
0A24: D1            pop  de			; de = old hl
0A25: 3D            dec  a
0A26: C2 16 0A      jp   nz,$0A16 		; loop
0A29: C9            ret

	
	;; Draw b x c block from de to screen at hl
0A2A: C5            push bc
0A2B: E5            push hl
0A2C: 1A            ld   a,(de)
0A2D: 13            inc  de
0A2E: 77            ld   (hl),a
0A2F: 23            inc  hl
0A30: 0D            dec  c
0A31: C2 2C 0A      jp   nz,$0A2C
0A34: E1            pop  hl
0A35: 01 20 00      ld   bc,$0020
0A38: 09            add  hl,bc
0A39: C1            pop  bc
0A3A: 05            dec  b
0A3B: C2 2A 0A      jp   nz,$0A2A
0A3E: C9            ret


	;; Clear (hl - hl+c-1)  b times with row offsets
0A3F: AF            xor  a
0A40: C5            push bc
0A41: E5            push hl
0A42: 77            ld   (hl),a
0A43: 23            inc  hl
0A44: 0D            dec  c
0A45: C2 42 0A      jp   nz,$0A42
0A48: E1            pop  hl
0A49: 01 20 00      ld   bc,$0020
0A4C: 09            add  hl,bc
0A4D: C1            pop  bc
0A4E: 05            dec  b
0A4F: C2 40 0A      jp   nz,$0A40
0A52: C9            ret

	
	;; $09E8 Entry A
0A53: EB            ex   de,hl
0A54: 4E            ld   c,(hl)			; Read bc
0A55: 23            inc  hl
0A56: 46            ld   b,(hl)
0A57: 23            inc  hl
0A58: 5E            ld   e,(hl)			; Read de
0A59: 23            inc  hl
0A5A: 56            ld   d,(hl)
0A5B: 2B            dec  hl			; Back up to use again
0A5C: CD 82 0A      call $0A82			; Draw BCD from bc at de
0A5F: EB            ex   de,hl			; Last address now in hl
0A60: CD 7A 0A      call $0A7A			; Replace space with zero
0A63: 23            inc  hl
0A64: EB            ex   de,hl			; Last address now in de
0A65: 3E 30         ld   a,$30
0A67: 12            ld   (de),a			; Append zero
0A68: 13            inc  de
0A69: 12            ld   (de),a			; Append zero
0A6A: CD DC 0A      call $0ADC			; (hl, hl+1) -> de, hl+=2
0A6D: D5            push de
0A6E: CD DC 0A      call $0ADC			; (hl, hl+1) -> de, hl+=2
0A71: 22 00 20      ld   ($2000),hl 		; Next command 
0A74: E1            pop  hl
0A75: 3E 04         ld   a,$04
0A77: C3 30 0B      jp   $0B30			; Draw string hl @ de, length a

	;; Replace space with a zero
0A7A: 2B            dec  hl
0A7B: 7E            ld   a,(hl)
0A7C: E6 40         and  $40
0A7E: C8            ret  z
0A7F: 36 30         ld   (hl),$30
0A81: C9            ret

	;; Draw BCD from bc at de
0A82: 0A            ld   a,(bc)	
0A83: 1F            rra
0A84: 1F            rra
0A85: 1F            rra
0A86: 1F            rra
0A87: E6 0F         and  $0F			; Mask high nybble
0A89: C2 8E 0A      jp   nz,$0A8E	
0A8C: 3E 10         ld   a,$10			; $40 -> blank
0A8E: C6 30         add  a,$30			; Decimal to ascii
0A90: 12            ld   (de),a			; Store digit
0A91: 13            inc  de			; Next screen loc
0A92: 0A            ld   a,(bc)			
0A93: E6 0F         and  $0F			; Mask low nybble
0A95: C2 9A 0A      jp   nz,$0A9A
0A98: 3E 10         ld   a,$10			; $40 -> blank
0A9A: C6 30         add  a,$30			; Decimal to ascii
0A9C: 12            ld   (de),a			; Store digit
0A9D: 13            inc  de			; Next screen loc
0A9E: C9            ret

	;; $09E8 Entry 8 -- Copy data from sequence to address (backwards)
0A9F: EB            ex   de,hl			; Sequence address back to hl
0AA0: 46            ld   b,(hl)			; Get count
0AA1: 23            inc  hl
0AA2: 05            dec  b
0AA3: 05            dec  b
0AA4: CD DC 0A      call $0ADC			; (hl, hl+1) -> de, hl+=2  (address)
0AA7: 4E            ld   c,(hl)			; Read first byte
0AA8: 23            inc  hl
0AA9: 7E            ld   a,(hl)			; Read second byte
0AAA: 23            inc  hl
0AAB: 12            ld   (de),a			; Write first byte
0AAC: 1B            dec  de
0AAD: 79            ld   a,c
0AAE: 12            ld   (de),a			; Write second byte
0AAF: 1B            dec  de
	
0AB0: 7E            ld   a,(hl)			; Loop for rest of count
0AB1: 23            inc  hl
0AB2: 12            ld   (de),a
0AB3: 1B            dec  de
0AB4: 05            dec  b
0AB5: C2 B0 0A      jp   nz,$0AB0
0AB8: 22 00 20      ld   ($2000),hl 		; Next command
0ABB: C9            ret

	
	;; $09E8 Entry 9 -- Draw INSERT COIN or PUSH BUTTON
0ABC: EB            ex   de,hl
0ABD: CD DC 0A      call $0ADC			; (hl, hl+1) -> de, hl+=2
0AC0: 1A            ld   a,(de)
0AC1: CD DC 0A      call $0ADC			; (hl, hl+1) -> de, hl+=2
0AC4: D5            push de
0AC5: CD DC 0A      call $0ADC			; (hl, hl+1) -> de, hl+=2
0AC8: D5            push de
0AC9: CD DC 0A      call $0ADC			; (hl, hl+1) -> de, hl+=2
0ACC: 22 00 20      ld   ($2000),hl		; Next command
	
0ACF: EB            ex   de,hl
0AD0: A7            and  a
0AD1: CA D5 0A      jp   z,$0AD5 		; Draw first string?
0AD4: E3            ex   (sp),hl
0AD5: E1            pop  hl
0AD6: D1            pop  de
0AD7: 3E 0B         ld   a,$0B			; Length
0AD9: C3 30 0B      jp   $0B30			; Draw string hl @ de, length a

	;; Get LSB from table
0ADC: 5E            ld   e,(hl)
0ADD: 23            inc  hl
	;; Get MSB from table
0ADE: 56            ld   d,(hl)
0ADF: 23            inc  hl
0AE0: C9            ret

	;; $9EA8 Entry 7 -- arg -> addr
0AE1: 1A            ld   a,(de)			; Next entry
0AE2: 13            inc  de
0AE3: EB            ex   de,hl
0AE4: 4E            ld   c,(hl)			; Next entry
0AE5: 23            inc  hl
0AE6: 46            ld   b,(hl)			; Next entry
0AE7: 23            inc  hl
0AE8: 22 00 20      ld   ($2000),hl 		; Store command
0AEB: 02            ld   (bc),a			; a -> (bc)
0AEC: C9            ret

	;; $09E8 Entry 5
	;; Read from de table into b, c, a, e, d
0AED: EB            ex   de,hl			
0AEE: 46            ld   b,(hl)
0AEF: 23            inc  hl
0AF0: 4E            ld   c,(hl)
0AF1: 23            inc  hl
0AF2: 7E            ld   a,(hl)
0AF3: 23            inc  hl
0AF4: CD DC 0A      call $0ADC
0AF7: 22 00 20      ld   ($2000),hl
0AFA: EB            ex   de,hl
0AFB: 36 DB         ld   (hl),$DB
0AFD: 23            inc  hl
0AFE: 71            ld   (hl),c
0AFF: 23            inc  hl
0B00: 36 C9         ld   (hl),$C9
0B02: 2B            dec  hl
0B03: 2B            dec  hl
0B04: E9            jp   (hl)

	;; Deal with inputs (when stable)
0B05: AE            xor  (hl)
0B06: C8            ret  z			; No changes
	
0B07: 4F            ld   c,a			; Stash IN0	
0B08: 06 01         ld   b,$01			; Bit being checked
	
0B0A: 79            ld   a,c			; Restore IN0	
0B0B: 0F            rrca
0B0C: DA 18 0B      jp   c,$0B18 		; Bit is high
	
0B0F: 4F            ld   c,a			; Stash IN0
0B10: 78            ld   a,b			; Shift check bit
0B11: 07            rlca
0B12: 47            ld   b,a
0B13: 13            inc  de			; Advance jump table
0B14: 13            inc  de
0B15: C3 0A 0B      jp   $0B0A			; Loop
	
0B18: 78            ld   a,b			; Bit found to a
0B19: AE            xor  (hl)			; Clear bit
0B1A: 77            ld   (hl),a			; Store back
0B1B: A0            and  b			; Value of changed bit
0B1C: EB            ex   de,hl
0B1D: 4E            ld   c,(hl)
0B1E: 23            inc  hl
0B1F: 66            ld   h,(hl)
0B20: 69            ld   l,c
0B21: E9            jp   (hl)			; Handle changed bit

	;; $09E8 Entry 4 (Draw string))
0B22: EB            ex   de,hl			; ($2000)+1 -> 
0B23: 7E            ld   a,(hl)
0B24: 23            inc  hl
0B25: CD DC 0A      call $0ADC			; (hl, hl+1) -> de, hl+=2
0B28: D5            push de
0B29: CD DC 0A      call $0ADC			; (hl, hl,1) -> de, hl+=2
0B2C: 22 00 20      ld   ($2000),hl		; Next command
0B2F: E1            pop  hl			; String src address

	;; Write string length a from hl to de
0B30: F5            push af
0B31: 7E            ld   a,(hl)			; Get byte
0B32: 23            inc  hl
0B33: D6 30         sub  $30			; Ascii -> tbl
0B35: F2 49 0B      jp   p,$0B49		; Jump if >=$30

	;; Carriage returns = $30-a (?)
0B38: 47            ld   b,a
0B39: 1C            inc  e
0B3A: 7B            ld   a,e
0B3B: E6 1F         and  $1F
0B3D: C2 42 0B      jp   nz,$0B42 		; No wrap
0B40: 14            inc  d
0B41: 14            inc  d
0B42: 04            inc  b
0B43: C2 39 0B      jp   nz,$0B39 		; Loop
0B46: C3 31 0B      jp   $0B31			; Next char

	;; ASCII
0B49: E5            push hl
0B4A: D5            push de
0B4B: 21 8F 0B      ld   hl,$0B8F 		; Start of char table
0B4E: CA 59 0B      jp   z,$0B59		; (no need to add)
0B51: 01 0A 00      ld   bc,$000A		; Add a*$0a
0B54: 09            add  hl,bc
0B55: 3D            dec  a
0B56: C2 54 0B      jp   nz,$0B54
	
0B59: EB            ex   de,hl
0B5A: 01 20 00      ld   bc,$0020
0B5D: 3E 0A         ld   a,$0A			; Loop $a times
0B5F: F5            push af
0B60: 1A            ld   a,(de)			; Load byte
0B61: 13            inc  de			; Inc index
0B62: 77            ld   (hl),a			; Store to screen
0B63: 09            add  hl,bc			; Next screen loc
0B64: F1            pop  af
0B65: 3D            dec  a
0B66: C2 5F 0B      jp   nz,$0B5F 		; Loop for this char
0B69: D1            pop  de
0B6A: E1            pop  hl
0B6B: 13            inc  de
0B6C: F1            pop  af
0B6D: 3D            dec  a
0B6E: C2 30 0B      jp   nz,$0B30 		; Next char
0B71: C9            ret

	;; $09E8 Entry 2  (argument to 2010)
0B72: EB            ex   de,hl
0B73: 7E            ld   a,(hl)			; Argument
0B74: 23            inc  hl
0B75: 22 00 20      ld   ($2000),hl
0B78: 32 10 20      ld   ($2010),a 		; Store ??
0B7B: C9            ret

	;; $09E8 Entry 1 (argument to 2011)
0B7C: EB            ex   de,hl
0B7D: 7E            ld   a,(hl)			; Argument
0B7E: 23            inc  hl
0B7F: 22 00 20      ld   ($2000),hl
0B82: 32 11 20      ld   ($2011),a 		; Store ??
0B85: C9            ret

	;; $09E8 Entry 6 (de) -> $2000
0B86: EB            ex   de,hl
0B87: 5E            ld   e,(hl)
0B88: 23            inc  hl
0B89: 56            ld   d,(hl)
0B8A: EB            ex   de,hl
0B8B: 22 00 20      ld   ($2000),hl
0B8E: C9            ret

	;; Character table
0B8F: 3C 7E 66 66 66 66 66 66 7E 3C ; 0
0B99: 18 1C 18 18 18 18 18 18 3C 3C	; 1
0BA3: 3C 7E 66 60 7C 3E 06 06 7E 7E	; 2
0BAD: 3C 7E 66 60 38 78 60 66 7E 3C	; 3
0BB7: 66 66 66 66 7E 7E 60 60 60 60	; 4
0BC1: 3E 3E 06 06 3E 7E 60 66 7E 3C	; 5
0BCB: 3C 3E 06 06 3E 7E 66 66 7E 3C	; 6
0BD5: 7E 7E 60 70 30 38 18 1C 0C 0C	; 7
0BDF: 3C 7E 66 66 3C 7E 66 66 7E 3C	; 8
0BE9: 3C 7E 66 66 7E 7C 60 60 7C 3C	; 9
0BF3: 0C 93 60 00 00 00 00 00 00 00	; 0A = Wave
0BFD: 60 99 06 00 00 00 00 00 00 00	; 0B = Wave
0C07: 30 CD 02 00 00 00 00 00 00 00	; 0C = Wave
0C11: 02 C0 78 E0 80 F0 01 C0 F0 7C	; 0D = <part of wam gfx>
0C1B: 08 1C 3E 7F FF FF BF 1F 02 40	; 0E = <part of wam gfx>
0C25: 02 80 78 1E 07 01 7C F8 0C 10	; 0F = <part of wam gfx>
0C2F: 00 00 00 00 00 00 00 00 00 00	; 10 = <space>
0C39: 18 3C 7E 66 66 66 7E 7E 66 66	; 11 = A
0C43: 3E 7E 66 66 3E 7E 66 66 7E 3E	; 12 = B
0C4D: 3C 7E 66 06 06 06 06 66 7E 3C	; 13 = C
0C57: 3E 7E 66 66 66 66 66 66 7E 3E	; 14 = D
0C61: 7E 7E 06 06 3E 3E 06 06 7E 7E	; 15 = E
0C6B: 7E 7E 06 06 3E 3E 06 06 06 06	; 16 = F
0C75: 3C 7E 66 06 06 76 76 66 7E 3C	; 17 = G
0C7F: 66 66 66 66 7E 7E 66 66 66 66	; 18 = H
0C89: 3C 3C 18 18 18 18 18 18 3C 3C	; 19 = I
0C93: 60 60 60 60 60 60 60 66 7E 3C	; 1A = J
0C9D: 66 66 76 3E 1E 1E 3E 76 66 66	; 1B = K
0CA7: 06 06 06 06 06 06 06 06 7E 7E	; 1C = L
0CB1: C3 C3 E7 E7 FF FF DB C3 C3 C3	; 1D = M
0CBB: 66 66 6E 6E 7E 7E 76 76 66 66	; 1E = N
0CC5: 3C 7E 66 66 66 66 66 66 7E 3C	; 1F = O
0CCF: 3E 7E 66 66 7E 3E 06 06 06 06	; 20 = P
0CD9: 3C 7E 66 66 66 66 66 66 7E 5C	; 21 = Q
0CE3: 3E 7E 66 66 7E 3E 76 66 66 66	; 22 = R
0CED: 3C 7E 66 06 3E 7C 60 66 7E 3C	; 23 = S
0CF7: 7E 7E 18 18 18 18 18 18 18 18	; 24 = T
0D01: 66 66 66 66 66 66 66 66 7E 3C	; 25 = U
0D0B: 66 66 66 66 66 7E 3C 3C 18 18	; 26 = V
0D15: C3 C3 C3 DB FF FF E7 E7 C3 C3	; 27 = W
0D1F: 66 66 7E 3C 18 18 3C 7E 66 66	; 28 = X
0D29: 66 66 7E 3C 18 18 18 18 18 18 	; 29 = Y
0D33: 7E 7E 60 70 38 1C 0E 06 7E 7E 	; 2A = Z

0D3D: 05 0C		    	; Size
0D3F: 00 00 08 00 00		; ....................#...................
0D44: 00 00 08 00 00		; ....................#...................
0D47: 00 60 0E 00 00		; ....................###..##.............
0D4C: 00 E0 CE 3F 00		; ..........########..###.###.............
0D53: 00 E0 DE 03 00		; ..............####.####.###.............
0D58: F8 F7 DF F7 0F		; ....########.#####.#########.########...
0D5D: 80 F7 DF F7 00		; ........####.#####.#########.####.......
0D62: FF FF FF FF FF		; ########################################
0D67: FF FF FF FF 7F		; .#######################################
0D6C: FF FF FF FF 3F		; ..######################################
0D71: FE FF FF FF 1F		; ...#####################################
0D76: FE FF FF FF 0F	    	; ....####################################
	
0D7B: 04 0C		      	; Size
0D7D: 00 00 03 00	    	; ..............##................
0D81: 00 36 03 00		; ..............##..##.##.........
0D85: 00 36 03 00		; ..............##..##.##.........
0D89: 02 B6 03 00		; ..............###.##.##.......#.
0D8D: 87 FF F3 07		; .....#######..###########....###
0D91: E2 FF F7 00		; ........####.##############...#..	
0D95: FF FF FF FF		; #################################
0D99: FF FF FF 7F		; .################################
0D9D: FF FF FF 3F		; ..###############################
0DA1: FC FF FF 1F		; ...############################..
0DA5: FC FF FF 0F		; ....###########################..
0DA9: F8 FF FF 07		; .....#########################...
	
0DAD: 05 0C		    	; Size
0DAF: 00 00 40 00 00		; .................#......................
0DB4: 00 00 F0 00 00		; ................####....................
0DB9: 00 00 F0 00 00		; ................####....................
0DBE: 00 80 F0 1E 00		; ...........####.####....#...............
0DC3: 00 00 FB 06 00		; .............##.#####.##................
0DC8: FF FF FF FF FF		; ########################################
0DCD: FC FF FF FF 3F		; ..####################################..
0DD2: FC FF FF FF 1F		; ...###################################..
0DD7: FC FF FF FF 0F		; ....##################################..
0DDC: F8 FF FF FF 07		; .....################################...
0DE1: F8 FF FF FF 03		; ......###############################...
0DE6: F8 FF FF FF 03		; ......###############################...

0DEB: 04 0B			; Size
0DED: 40 00 00 02		; ......#..................#......
0DF1: 40 80 00 02		; ......#.........#........#......
0DF5: 40 00 07 02		; ......#......###.........#......
0DF9: 40 00 07 02		; ......#......###.........#......
0DFD: 40 F0 07 02		; ......#......#######.....#......
0E01: FC F0 07 F8		; #####........#######....######..
0E05: FC FF FF 7F		; .#############################..
0E09: FC FF FF 3F		; ..############################..
0E0D: F8 FF FF 1F		; ...##########################...
0E11: F0 FF FF 0F		; ....########################....
0E15: F0 FF FF 0F		; ....########################....

0E19: 04 0B			; Size
0E1B: 80 00 00 00		; ........................#.......
0E1F: 00 00 00 01		; .......#........................
0E23: A0 01 00 01		; .......#...............##.#.....
0E27: A0 01 00 01		; .......#...............##.#.....
0E2A: F0 01 00 01		; .......#...............#####....
0E2F: F8 01 00 F9		; #####..#...............######...
0E33: F8 FF FF 7F		; .############################...
0E37: F0 FF FF 3F		; ..##########################....
0E3B: F0 FF FF 1F		; ...#########################....
0E3F: F0 FF FF 0F		; ....########################....
0E43: E0 FF FF 0F		; ....#######################.....

	;; Small ship (byte swapped)
0E47: 02 06			; Size
0E48: 00 03			; ......##........
0E4B: 10 07			; .....###...#....
0E4D: E0 FF			; ###########.....
0E4F: FF 7F			; .###############
0E51: FF 3F			; ..##############
0E53: FF 1F			; ...#############

	;; Sinking ship (byte swapped)
0E55: 02 0F			; Size
0E57: 10 00			; ...........#....
0E59: 30 02			; ......#...##....
0E5B: 70 01			; .......#.###....
0E5D: FC 00			; ........######..
0E5F: F8 11			; ...#...######...
0E61: F0 3B			; ..###.######....
0E63: E0 7F			; .##########.....
0E65: C0 3F			; ..########......
0E67: 80 1F			; ...######.......
0E69: 00 3F			; ..######........
0E6B: 00 1E			; ...####.........
0E6D: 00 04			; .....#..........
0E6F: 00 48			; .#..#...........
0E71: 00 F8			; #####...........
0E73: 00 F8			; #####...........
	
	
0E75: 01 11					; Size
0E77: 10 38 38 38 38 38 38 38			; Big missile
0E7F: 38 38 38 38 38 10 10 10
0E8F: 38
	
0E88: 01 0E					; Size
0E8A: 18 18 18 18 18 18 18 18			; Mid missile
0E93: 18 18 18 18 00 18

0E98: 01 09					; Size
0E9A: 10 10 10 10 10 10 10 10			; Small missile
0EA2: 10

0EA3: 01 10					; Size
0EA5: 10			; ...#....
0EA6: BA			; #.###.#.
0EA7: 7C			; .#####..
0EA8: FE			; #######.
0EA9: 7C			; .#####..
0EAA: 38			; ..###...
0EAB: 54			; .#.#.#..
0EAC: 10			; ...#....
0EAD: 00			; ........
0EAE: 10			; ...#....
0EAF: 00			; ........
0EB0: 08			; ....#...
0EB1: 00			; ........
0EB2: 00			; ........
0EB3: 04			; .....#..
0EB4: 00			; ........


	;; Table for $07CF
0EB5: 3D 3E 3F									; DATA TABLE

0EB8: 40 40 40 40 40 40 40 40			; DATA ________
0EC0: 40 40 40					; ___
	
0EC3: 47 41 4D 45 40 4F 56 45			; DATA GAME_OVE
0ECB: 52					; DATA R
	
0ECC: 48 49 47 48 40 53 43 4F			; DATA HIGH_SCO
0ED4: 52 45 40 40 40 40 40 40			; DATA RE______
0EDC: 59 4F 55 52 40 53 43 4F			; DATA YOUR_SCO
0EE4: 52 45					; DATA RE
	
0EE6: 49 4E 53 45 52 54 40 43			; DATA INSERT_C
0EEE: 4F 49 4E					; DATA OIN
	
0EF1: 50 55 53 48 40 42 55 54			; DATA PUSH_BUT
0EF9: 54 4F 4E 					; DATA TON
	
0EFC: 53 45 41 40 57 4F 4C 46			; DATA SEA_WOLF

	;; Water?
0F04: 3A 3B 3C 3B 3C 3A 3B 3C			; DATA 
0F0C: 3A 3C 3B 3C 3A 3B 3A 3C			; DATA 
0F14: 3B 3A 3C 3A 3B 3C 3A 3C			; DATA 
0F1C: 3B 3C 3A 3B 3C 3A 3B 3C			; DATA 
	
0F24: 42 4F 4E 55 53				; DATA BONUS
	
0F29: 54 49 4D 45				; DATA TIME
0F2D: 2D					; DATA <space>
0F2E: 53 43 4F 52 45				; DATA SCORE
	
0F33: 45 58 54 45 4E 44 45 44 			; DATA EXTENDED
0F3B: 16					; DATA <space>
0F3C: 54 49 4D 45 44				; DATA TIME

	;; Table for $07B9
0F40: 44 0F					; DATA ZAP
0F42: 4C 0F					; DATA WAM

	;; Table from $0F40	(For ZAP)
0F44: 01 41 04 	; DATA 
0F47: 3D 5A 2F 50 3F				; DATA *ZAP*

	;; TAble from $0F42	(For WAM)
0F4C: 01 41 04	; DATA 
0F4F: 3D 57 2F 4D 3F				; DATA *WAM*

	;; 4-byte table (time per credit)
0F54: 61 71 81 91								; DATA 

	;; $0F57 = 8-byte score table (0 not used) 
0F58: 03 03 03 01 01 07					; DATA 

	;; Table for $05D2	(0x20 long)
	;; Grey code decode
0F5E: 00 08 18 10 38 30 20 28		; DATA 
0F66: 78 70 60 68 40 48 58 50		; DATA 
0F6E: F8 F0 E0 E8 C0 C8 D8 D0		; DATA 
0F76: 80 88 98 90 B8 B0 A0 A8		; DATA 


	;; Ship tables
	;; 00-01	= Sprite address
	;; 02		= $20 = Right to Left, $40 = Left to Right
	;; 03 		= Initial Y
	;; 04 		= Delta Y (Always 0 for ships)
	;; 05		= Final X
	;; 06		= Initial X
	;; 07		= Delta X
	
	;; Even ship table
0F7E: 0D 3D 20 14 00 D8 00 02		; DATA 
0F86: 0D 7B 20 14 00 E0 00 02		; DATA 
0F8E: 0D AD 20 14 00 D8 00 02		; DATA 
0F96: 0D EB 20 15 00 E0 00 01		; DATA 
0F9E: 0E 19 20 15 00 E0 00 01		; DATA 
0FA6: 0E 47 20 1A 00 F0 00 03		; DATA 

	;; Odd ship table
0FAE: 0D 3D 40 34 00 D8 D8 FE		; DATA 
0FB6: 0D 7B 40 34 00 E0 E0 FE		; DATA 
0FBE: 0D AD 40 34 00 D8 D8 FE		; DATA 
0FC6: 0D EB 40 35 00 E0 E0 FF		; DATA 
0FCE: 0E 19 40 35 00 E0 E0 FF		; DATA 
0FD6: 0E 47 40 3A 00 F0 F0 FD		; DATA 

	
	;; Ship type table
0FDE: 06			; DATA Small, fast
0FDF: 04			; DATA Mid, 2 towers
0FE0: 02			; DATA Cross in back
0FE1: 06			; DATA Small, fast
0FE0: 03			; DATA Big, flat top
0FE3: 05			; DATA Tower in back
0FE4: 01			; DATA Battleship
	
0FE5: FF            rst  $38
0FE6: FF            rst  $38
0FE7: FF            rst  $38
0FE8: FF            rst  $38
0FE9: FF            rst  $38
0FEA: FF            rst  $38
0FEB: FF            rst  $38
0FEC: FF            rst  $38
0FED: FF            rst  $38
0FEE: FF            rst  $38
0FEF: FF            rst  $38
0FF0: FF            rst  $38
0FF1: FF            rst  $38
0FF2: FF            rst  $38
0FF3: FF            rst  $38
0FF4: FF            rst  $38
0FF5: FF            rst  $38
0FF6: FF            rst  $38
0FF7: FF            rst  $38
0FF8: FF            rst  $38
0FF9: FF            rst  $38
0FFA: FF            rst  $38
0FFB: FF            rst  $38
0FFC: FF            rst  $38
0FFD: FF            rst  $38
0FFE: FF            rst  $38
0FFF: FF            rst  $38
