				;; out 01    = Explosion matrix
				;; out 02    = Torpedo display
				;; out 03    = Shifter data
				;; out 04    = Shifter count
				;; out 05    = Sound triggers
				;; out 06    = watchdog (add this)

				;; 2000-2001 = Pointer address for main game/attract loop
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
				;;						 D7 = $2002, D6 = $2010, D5 = $2011, D4 = $2021
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
				;; 		Byte C-D = (read into bc)
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
	.org $0000
L0000:
	nop
	nop
	ld   sp,$2400									; Stack pointer
	jp   L043A										; Startup jump

				;; rst $08 ($cf interrupt vector)
	push hl
	push de
	push bc
	push af
	jp   L007E
	nop

				;; rst $10 ($d7 interrupt vector)
	push hl
	push de
	push bc
	push af
	ld   a,($201F)
	and  a
	jp   nz,L003E
	
	call L03BC										; Update wave
	call L012E										; Update a sprite
	
	ld   hl,($2016)								; Sprite pointer
	ld   a,(hl)
	and  a
	jp   p,L0036									; Jump if not active
	and  $20
	jp   z,L0036									; Jump if ??
	
	call $035B										; Load de, bc from ship data
	dec  c
	ex   de,hl
	call L0A2A										; Draw b x c block from de at hl
				
L0036:
	ld   a,$FF
	ld   ($201F),a
	jp   L0069										; End of interrupt routine
	
L003E:
	ld   hl,($2016)								; Sprite pointer
	ld   a,(hl)
	and  a
	jp   p,L0062									; Jump if not active
	
	and  $40
	jp   nz,L0050									; Jump if not set to clear
	ld   (hl),$00									; Clear sprite
	jp   L0062
	
L0050:
	ld   a,(hl)										; Set bit 5
	or   $20
	ld   (hl),a
	call L0165										; Update sprite
	ld   a,b
	push hl
	ld   hl,($201C)
	ld   b,h
	ld   c,l
	pop  hl
	call L0A16
	
L0062:
	call L0368
	xor  a
	ld   ($201F),a

				;; End of interrupt routine
L0069:
	in   a,($02)									; IN1
	ld   b,a
	in   a,($02)									; IN1
	ld   hl,$2007									; Last IN1?
	ld   de,$09CA
	cp   b												; Poor man's debounce
	call z,L0B05									; Call if stable
	pop  af
	pop  bc
	pop  de
	pop  hl
	ei
	ret

				;; Interrupt vector continues...
L007E:
	ld   a,($201F)
	and  a
	jp   nz,L0119
	call L03BC										; Update wave
	
				;; Clear $215f-$21a3
	ld   hl,$215F
	ld   b,$44
	xor  a
L008E:
	ld   (hl),a
	inc  hl
	dec  b
	jp   nz,L008E
	
	ld   hl,($2018)								; Sprite pointer 0
	ld   a,$03										; Loop counter 
L0099:
	push af
	ld   a,l
	cp   $58											; hl==$2058?
	jp   nz,L00A3
L00A0:
	ld   hl,$2031									; Resets to $2031
L00A3:
	or   h
	jp   z,L00A0
	
	push hl
	call L01DE
	pop  hl
	jp   nc,L00B2
	
	ld   ($2018),hl								; Sprite pointer 0
L00B2:
	ld   de,$000D
	add  hl,de
	pop  af
	dec  a
	jp   nz,L0099									; Loop back
	
	ld   hl,($2018)								; Sprite pointer 0
	call L030C
	
	ld   hl,($201A)								; Sprite pointer 1
	ld   a,$03										; Loop counter
L00C6:
	push af
	ld   a,l
	cp   $7F											; hl==$207F?
	jp   nz,L00D0
L00CD:
	ld   hl,$2058									; Reset to $2058
L00D0:
	or   h
	jp   z,L00CD
	
	push hl
	call L01DE
	pop  hl
	jp   nc,L00DF
	
	ld   ($201A),hl								; Sprite pointer 1
L00DF:
	ld   de,$000D									; Sprint increment
	add  hl,de
	pop  af
	dec  a
	jp   nz,L00C6									; Loop back
	
	xor  a
	ld   ($2030),a								; Clear sprite shift
	
	ld   hl,($2016)								; Pointer?
	ld   a,$04										; Loop counter
L00F1:
	push af
	ld   a,l
	cp   $5F
	jp   nz,L00FB
	
L00F8:
	ld   hl,$20E7									; Reset to $20E7
L00FB:
	or   h
	jp   z,L00F8
	
	push hl
	call L0250
	pop  hl
	jp   nc,L010A
	
	ld   ($2016),hl								; Pointer?
L010A:
	ld   de,$001E
	add  hl,de
	pop  af
	dec  a
	jp   nz,L00F1									; Loop back
	
	call L0331
	jp   L0069										; End of interrupt routine

	
L0119:
	ld   hl,($201A)								; Ship 1 pointer
	call L030C
	
	ld   hl,($201A)								; Ship 1 pointer
	call L013A
	
	ld   hl,($2018)								; Ship 0 pointer
	call L013A
	jp   L0069										; End of interrupt routine

				;; Called from rst $10
L012E:
	ld   hl,($2014)
	ld   a,(hl)
	and  a
	ret  p												; No sprite to update?
	call L0165										; Update sprite
	jp   L0192

				;; Handle 2018/201a entries (read into hl)
L013A:
	ld   a,(hl)
	and  a
	ret  p												; Return if b7 clear
	
	and  $40											; Check bit 6
	jp   nz,L0145									; Jump if set
	ld   (hl),$00									; Clear entry
	ret

				;; Bits 7 set, bit 6 clear
L0145:
	ld   a,(hl)
	or   $20
	ld   (hl),a										; Set bit 5	 
	push af
	call L0165										; Update sprite
				;; hl = screen loc, c=shift on return
				
	pop  af
	and  $10											; Check bit 4
	jp   z,L0192									; Initial sprite draw
	
	ld   a,c
	add  a,l
	ld   l,a
	push hl
	ld   hl,$2030
	ld   a,(hl)
	cpl
	and  $07
	ld   (hl),a
	pop  hl
	out  ($04),a									; Update shift count
	jp   L01B8

				;; Update/redraw sprite
L0165:
	inc  hl
	inc  hl
	ld   e,(hl)										; LSB of loc + shift
	inc  hl
	inc  hl
	inc  hl
	ld   d,(hl)										; MSB of loc
	inc  hl
	inc  hl
	call L0A00										; de >> 3, e&3 -> c
	ld   a,c											; (shift)
	ld   ($2030),a
	out  ($04),a									; Shifter count
	push de												; Store screen loc
	ld   e,(hl)										; Read rom loc
	inc  hl
	ld   d,(hl)
	inc  hl
	ex   de,hl										; rom loc -> hl
	ld   c,(hl)										; Read bc (row/cols)
	inc  hl
	ld   b,(hl)
	inc  hl
	ex   (sp),hl									; swap screen loc 
	ex   de,hl										; Back to ram table
	ld   (hl),e
	inc  hl
	ld   (hl),d
	inc  hl
	ld   (hl),c
	inc  (hl)											; +1 wide for shifting?
	inc  hl
	ld   (hl),b
	inc  hl
	ld   ($201C),hl
	ex   de,hl										; hl = screen loc
	pop  de												; de = sprite data in ROM
	ret

				;; Initial sprite draw
L0192:
	push bc												; bc = bytes wide, pix high
	push hl												; hl = screen loc
L0194:
	ld   a,(de)										; Sprite byte
	inc  de
	out  ($03),a									; MB12421 data write
	in   a,($03)									; MB12421 data read
	ld   (hl),a										; Write to RAM
	inc  hl
	dec  c
	jp   nz,L0194									; Loop for width
	xor  a
	out  ($03),a									; MB12421 data write
	in   a,($03)									; MB12421 data read
	ld   (hl),a										; Final write
	ld   bc,$0020									; Row increment
	pop  hl
	add  hl,bc										; Next row
	pop  bc
	ld   a,l
	and  $E0
	jp   nz,L0192									; Not bottom of screen
	ld   a,h
	rra
	jp   c,L0192									; Not end of screen
	ret

				;; Finish sprite draw
L01B8:
	push bc
	push hl
L01BA:
	ld   a,(de)
	inc  de
	out  ($03),a									; Shifter input
	in   a,($00)									; Shifter output
	ld   (hl),a										; Write to screen
	dec  hl
	dec  c
	jp   nz,L01BA									; Loop for row
	
	xor  a
	out  ($03),a									; Shifter input 
	in   a,($00)									; Shifter output
	ld   (hl),a										; Write to screen
	ld   bc,$0020									; Next line
	pop  hl
	add  hl,bc
	pop  bc
	ld   a,l
	and  $E0
	jp   nz,L01B8									; Loop
	
	ld   a,h
	rra
	jp   c,L01B8									; Loop
	ret

					;; 
L01DE:
	ld   a,(hl)
	and  a
	ret  p												; High bit clear = inactive
	
	push hl
	inc  hl												; hl now delta X
	and  $07											; Mask low 3 bits 
	jp   nz,L01ED									; (is a ship)

				;; This is a missle?
	inc  hl
	inc  hl
	jp   L0237
	
L01ED:
	ld   a,(hl)										; Delta X
	ld   de,$215F									; Table for +
	and  a
	jp   p,L01F8
	
	ld   de,$2181									; Table for -
	
L01F8:
	ld   b,a											; b = delta x
	inc  hl												; (hl) = X
	add  a,(hl)										; a = x + dx
	ld   (hl),a										; store x
	ld   a,b											; a = delta X
	and  a
	ld   a,(hl)										; a = X
	jp   p,L0210									; (left to right)
	
	cp   $01
	jp   nc,L0216
	
L0207:
	ex   (sp),hl
	ld   a,(hl)
	and  $BF											; Clear bit 5 (Ship done?)
	ld   (hl),a
	ex   (sp),hl
	jp   L0216
	
L0210:
	inc  hl
	cp   (hl)											; End X
	dec  hl
	jp   nc,L0207
				
L0216:
	ld   a,(hl)
	rrca
	rrca
	rrca
	and  $1F
	add  a,e
	ld   e,a
	ex   (sp),hl
	ld   a,(hl)
	ex   (sp),hl
	and  $07
	ld   b,a
	inc  hl
	ld   a,(hl)
	cpl
	inc  a
	rrca
	rrca
	rrca
	and  $07
	add  a,$03
	ex   de,hl
L0230:
	ld   (hl),b
	inc  hl
	dec  a
	jp   nz,L0230
	ex   de,hl

				;; Handle missiles?
L0237:
	ld   de,$202F
	ld   a,(de)
	cpl
	ld   (de),a
	jp   nz,L0247
	inc  hl
	ld   a,(hl)
	inc  hl
	add  a,(hl)
	ld   (hl),a
	inc  hl
	cp   (hl)
L0247:
	pop  hl
	scf
	ret  nz
	ld   a,(hl)
	and  $BF
	ld   (hl),a
	scf
	ret
L0250:
	ld   a,(hl)
	and  a
	ret  p
	push hl
	inc  hl
	inc  hl
	ld   c,(hl)
	inc  hl
	inc  hl
	ld   a,(hl)
	inc  hl
	ld   b,(hl)
	add  a,b
	ld   (hl),a
	ld   a,b
	cp   $C0
	jp   nc,L0309
	cp   $30
	jp   nc,L0275
	ld   a,($2024)
	and  a
	jp   z,L0275
	inc  a
	inc  a
	ld   ($2024),a
L0275:
	ld   a,(hl)
	inc  hl
	cp   (hl)
	jp   nc,L029C
				
	ld   a,$C0
	add  a,(hl)
	ld   (hl),a
	dec  hl
	dec  hl
	inc  (hl)
	inc  (hl)
	ld   a,(hl)
	inc  hl
	inc  hl
	inc  hl
	jp   z,L0296
	ld   (hl),SHOT1&$ff										; Change missile to SHOT1
	cp   $FC
	jp   z,L029C
	ld   (hl),SHOT2&$ff										; Change missile to SHOT2
	jp   L029C
				
L0296:
	ex   (sp),hl
	ld   a,(hl)
	and  $BF															; Clear bit 5 
	ld   (hl),a
	ex   (sp),hl
				
L029C:
	ld   de,$2030
	ld   a,(de)
	and  a
	jp   nz,L0309
				
	inc  a
	ld   (de),a
	ld   a,b
	and  $10
	jp   z,L0309
	ld   de,$0007
	add  hl,de
	ld   a,(hl)
	and  a
	jp   nz,L02C3
	add  hl,de
	ld   a,b
	add  a,e
	ld   b,a
	and  $10
	jp   z,L0309
	ld   a,(hl)
	and  a
	jp   z,L0309
L02C3:
	ex   (sp),hl
	ld   a,(hl)
	and  $BF
	ld   (hl),a
	ex   (sp),hl
	ld   a,b
	sub  $40
	ld   b,a
	jp   c,L02E0
	ld   hl,$21A1
L02D3:
	inc  hl
	inc  hl
	ld   a,(hl)
	and  a
	jp   nz,L02D3
	ld   (hl),b
	inc  hl
	ld   (hl),c
	jp   L0309
L02E0:
	ld   hl,$21BE
L02E3:
	inc  hl
	inc  hl
	inc  hl
	ld   a,(hl)
	and  a
	jp   nz,L02E3
	ld   a,b
	add  a,$20
	ld   de,$2160
	jp   m,L02F7
	ld   de,$2182
L02F7:
	ld   a,c
	rrca
	rrca
	rrca
	and  $1F
	add  a,e
	ld   e,a
	ld   a,(de)
	and  a
	jp   z,L0309
	ld   (hl),a
	inc  hl
	ld   (hl),c
	inc  hl
	ld   (hl),b
L0309:
	scf
	pop  hl
	ret

				
				;; hl = Ship pointer
L030C:
	ld   a,(hl)										; Sprite flags
	and  a
	ret  p												; Return if high bit not set
	
	and  $20
	ret  z												; Bit 5 clear = not active
	
	call $035B										; Get de, bc from bytes 9-d
	
	ex   de,hl										; hl = read de
	ld   b,c
L0317:
	xor  a
	push hl												; Store loc

				;; Clear c bytes
L0319:
	ld   (hl),a
	inc  hl
	dec  c
	jp   nz,L0319
	
	ld   de,$0020
	pop  hl												; Get loc
	add  hl,de										; Next line
	ld   c,b
	ld   a,l
	and  $E0
	jp   nz,L0317									; Loop
	ld   a,h
	rra
	jp   c,L0317									; Loop
	ret

	
L0331:
	ld   hl,($2014)
	ld   b,$0A										; Loop counter
	ld   a,l
	or   h
	jp   nz,L033E
	ld   hl,$2072									; Reset to $2072
L033E:
	ld   de,$000D
L0341:
	add  hl,de
	dec  b
	ret  z												; End of loop
	
	ld   a,l
	cp   $E7											; hl == $20E7?
	jp   nz,L034D
	
	ld   hl,$207F									; Reset to $207F
L034D:
	ld   a,(hl)										; X flags
	and  a
	jp   p,L0341									; MSB clear?
	
	ld   ($2014),hl
	inc  hl
	ld   a,(hl)										; Delta X
	inc  hl
	add  a,(hl)										; Add to X
	ld   (hl),a										; Store X
	ret

				;; Load de, bc from ship data
L035B:
	ld   de,$0009
	add  hl,de
	ld   e,(hl)
	inc  hl
	ld   d,(hl)
	inc  hl
	ld   c,(hl)
	inc  hl
	ld   b,(hl)
	inc  hl
	ret

				;; Called from ISR
L0368:
	ld   a,($2020)
	and  a
	ret  nz
	ld   b,a											; No ret, so a=0, b=0
	ld   hl,$2003									; Counter address
	dec  (hl)											; Decrement counter
	jp   nz,L038E

				;; $2003 Counter zero
	ld   (hl),$1E									; Reset counter
	ld   hl,$2002									; Game timer
	ld   a,(hl)				
	and  a
	jp   z,L0388									; Game over
				
	add  a,$99
	daa
	ld   (hl),a										; Decrement game timer
	jp   nz,L0388
				
	ld   b,$01										; set d7 (eventually) = Game over
				
L0388:
	ld   hl,$2010
	call L03AE										; Handle $2010 timer d6

				;; Counter non-zero
L038E:
	ld   hl,$2011 			
	call L03AE										; Handle $2011 timer d5
	ld   hl,$2021
	call L03AE										; Handle $2021 timer d4
	inc  hl
	call L03AE										; Handle $2022 timer d3
	inc  hl
	call L03AE										; Handle $2023 timer d2
	inc  hl
	call L03AE										; Handle $2024 timer d1
	inc  hl
	call L03AE										; Handle $2025 timer d0
	ld   ($2020),a
	ret

				;; Decrement timer, set bit if 0
L03AE:
	ld   a,(hl)
	and  a
	jp   z,L03B8
	dec  (hl)
	jp   nz,L03B8
	scf														; Set carry
	
				;; Shift 0 into b unless carry set above
L03B8:
	ld   a,b			
	rla
	ld   b,a
	ret

				;; Called from both interrupt routines
				;; Updates and redraw "wave"
L03BC:
	ld   bc,$2027
	ld   a,(bc)
	add  a,$0A										; $00 -> $0A -> $14 -> $1E = $00
	cp   $1E
	jp   nz,L03C8
	xor  a
L03C8:
	ld   (bc),a										; Store state
	
	inc  bc												; $2028
	ld   e,a
	ld   d,$00
	ld   hl,WATER0								; Start of waves
	add  hl,de
	ex   de,hl										; de = wave table entry

	ld   a,(bc)
	inc  a
	and  $1F											; Loops $00 to $1F
	ld   (bc),a

				;; Screen location
	ld   hl,$27E0
	add  a,l
	ld   l,a
	ld   bc,$0020									; Next char
L03DF:
	ld   a,(de)										; Get byte
	inc  de
	ld   (hl),a										; Write byte
	add  hl,bc										; Next char
	ld   a,l
	and  $E0
	cp   $60
	jp   nz,L03DF									; Loop	
	ret

				;; Test mode
L03EC:
	ld   hl,L0000									; Start address
	ld   de,$0000									; Offset 0
	ld   c,$02										; Until $200
L03F4:
	xor  a
L03F5:
	add  a,(hl)
	inc  hl
	ld   b,a
	ld   a,c
	cp   h
	ld   a,b
	jp   nz,L03F5									; Loop
	
	push hl												; Push address
	
	ld   hl,L0429									; Checksum table
	add  hl,de
	cp   (hl)											; Compare checksum
	ld   a,$40										; (Space)
	jp   z,L040E
	ld   hl,L0432
	add  hl,de
	ld   a,(hl)
L040E:
	ld   hl,$21E9									; Base screen loc
	add  hl,de
	ld   (hl),a										; Store char
	
	pop  hl												; Get address back
	inc  de												; Next rom
	inc  c												; $2 more pages
	inc  c
	ld   a,$12
	cp   c
	jp   nz,L03F4									; Loop if not done
	
	ld   hl,$21E9
	ld   de,$3008
	ld   a,$08
	call $0B30										; Draw string hl @ de, length a
	halt													; Stop!

				;; $200 block checksums
L0429:
	.db	$8D, $79, $00, $1F, $58, $6D, $EA, $C5		; Checksum 
	
	.db	$2A		; Patch byte for $400 checksum

				;; Error locations
L0432:
	.db	$48, $48, $47, $47, $46, $46, $45, $45		; HHGGFFEE

				;; Initial jump
L043A:
	call L08A2										; (End of game routine)
	in   a,($02)									; IN2
	and  $E0											; Test mode bits
	cp   $E0
	call z,L03EC									; Go to test mode

				;; Clear $2002-$200a
	ld   hl,$2002
	ld   a,$09
	ld   b,$00
L044D:
	ld   (hl),b
	inc  hl
	dec  a
	jp   nz,L044D
	
	ld   hl,L0929
	ld   ($2000),hl
L0459:
	ei														; Enable interrupts
	
	ld   hl,L0459									; Return address
	push hl
	ld   hl,($2000)
	ld   a,(hl)
	and  a
	jp   nz,L047D

				;; a=(($2000)) == 0
	call L06A4
	call L04CE
	call L04BF
	ld   a,($2002)								; Game timer
	and  a
	ret  z												; Skip rest if game over
	
	call L074C
	call L08B8
	jp   L048C

				;; a=(($2000)) != 0
L047D:
	inc  hl
	ex   de,hl										; ($2000+1) --> de
	ld   hl,TBLJMP-2							; Jump table
	rlca													; a = ($2000)<<1
	ld   c,a											; c = ($2000)<<1
	ld   b,$00
	add  hl,bc										; hl = L09e8 + ($2000)<<1
	ld   a,(hl)
	inc  hl
	ld   h,(hl)
	ld   l,a
	jp   (hl)
	
L048C:
	ld   a,($2003)
	cp   $1D
	ret  m
	ld   bc,$2002
	ld   de,$21E9
	call L0A82
	ex   de,hl
	call L0A7A
	inc  hl
	ld   (hl),$2C
	inc  hl
	ex   de,hl
	ld   bc,$202B									; Player score
	call L0A82										; Draw score digits
	ex   de,hl
	call L0A7A
	inc  hl
	ld   (hl),$30
	inc  hl
	ld   (hl),$30
	ld   hl,$21E9
	ld   de,$3E2F
	ld   a,$06
	jp   $0B30										; Draw string hl @ de, length a
L04BF:
	ld   hl,$202A
	ld   a,(hl)
	and  a
	ret  z
	ld   (hl),$00
	ld   hl,L09A6
	ld   ($2000),hl
	ret

				;; Choose subroutine based on $2020 bits
L04CE:
	ld   hl,$2020
	ld   a,(hl)
	and  a
	ret  z												; Nothing to do
	ld   (hl),$00									; Clear all bits
	rra
	call c,L0601									; Bit 0 set = Clear explosion lights
	rra
	call c,L060E									; Bit 1 set = Clear explosion on screen
	rra
	call c,L04F7									; Bit 2 set = Trigger bit 2 sound	
	rra
	call c,L0634									; Bit 3 set = Launch new ship
	rra
	call c,L05E9									; Bit 4 set = Reload torpedos
	rra
	call c,L0573									; Bit 5 set = Increment $2000 counter
	rra
	call c,L056C									; Bit 6 set = Initialize $2000 counter
	rra
	call c,L0511									; Bit 7 set = Game time over
	ret

				;; Bit 2 set on $2020
				;; Trigger bit 2 sound and set timers
L04F7:
	push af
	ld   hl,$2026
	ld   a,(hl)
	and  a
	jp   z,L050F									; Do nothing
	
	dec  (hl)
	ld   a,$04
	out  ($05),a									; Audio outputs
	ld   a,$19
	ld   ($2023),a								; Set timer
	ld   a,$0F
	ld   ($2025),a								; Set timer
L050F:
	pop  af
	ret

				;; Bit 7 set on $2020
L0511:
	ld   hl,$202E
	ld   a,(hl)
	and  a
	jp   nz,L053D									; Jump if already extended time
	
	ld   (hl),$01									; Only 1 extend
	ld   a,($2007)								; Last IN1
	rrca
	and  $70											; Base score for extended time (00 = none)
	jp   z,L053D									; Jump if no extended time
	
	add  a,$09										; $20 dip = $19(00) score
	ld   hl,$202B									; Player score
	cp   (hl)
	jp   nc,L053D									; Jump if score lower than metric
	
	ld   a,$20	
	ld   ($2002),a								; Set game time
	ld   hl,LTEXT									; EXTENDED_TIME
	ld   de,$3C03
	ld   a,$0C
	jp   $0B30										; Draw string hl @ de, length a
	
L053D:
	ld   hl,$20C9
	ld   bc,$001E
L0543:
	add  hl,bc
	ld   a,l
	cp   $5F
	jp   z,L055C
	
	ld   a,(hl)
	and  a
	jp   p,L0543
	
	xor  a
	ld   ($2021),a
	ld   ($202D),a 		; Torpedo status
	ld   a,$01
	ld   ($2002),a
	ret
	
L055C:
	ld   hl,L0929
	ld   ($2000),hl
	ld   a,($202B)								; Player score
	ld   hl,$2006									; High score
	cp   (hl)
	ret  c
	ld   (hl),a										; Write new score
	ret

				;; Bit 6 set on $2020
				;; Initialize $2000 counter
L056C:
	ld   hl,L0963
	ld   ($2000),hl
	ret

				;; Bit 5 set on $2020
				;; Increment $2000 counter
L0573:
	ld   hl,($2000)
	inc  hl
	ld   ($2000),hl
	ret

				;; Handle change in fire button
HFIRE:
	ret  z												; Not pressed
	ld   a,($2002)								; Game timer
	and  a	
	ret  z												; Not in game mode
	
	ld   a,($2021)
	and  a
	ret  nz												; Missile already active? 
	
	ld   hl,$202D									; Torpedo status
	ld   a,(hl)
	and  $1F
	ret  z												; ??
	
	ld   a,(hl)
	and  $0F											; Mask torp bits
	rra
	ld   b,$20										; Bit 5 = Reload
	and  a
	jp   z,L0599
	
	ld   b,$10										; Bit 4 = Ready
L0599:
	or   b
	ld   (hl),a
	out  ($02),a									; Torpedo display
	ld   hl,$2021
	ld   (hl),$08
	and  $10
	jp   nz,L05A9
	
	ld   (hl),$3C
L05A9:
	ld   a,$02
	out  ($05),a									; Audio outputs
	ld   a,$0F
	ld   ($2025),a								; Set timer
	ld   hl,$20C9
	ld   de,$001E
L05B8:
	add  hl,de
	ld   a,(hl)
	and  a
	jp   m,L05B8
	
	ld   de,$0008
	add  hl,de
	ld   (hl),$0E
	dec  hl
	ld   (hl),$75
	dec  hl
	ld   (hl),$9C
	dec  hl
	ld   (hl),$E0
	dec  hl
	ld   (hl),$FA
	dec  hl
	dec  hl
	ld   de,$0F5E									; Grey code table?
	ex   de,hl
	ld   a,($2008)
	and  $1F
	ld   c,a
	ld   b,$00
	add  hl,bc
	ld   a,(hl)
	ex   de,hl
	ld   (hl),a
	dec  hl
	ld   (hl),$00
	dec  hl
	ld   (hl),$C0
	ret

				;; Bit 4 set on $2020
				;; Reset torpedo status after reload
L05E9:
	push af
	ld   hl,$202D									; Torpedo status
	ld   a,(hl)
	and  $10											; Check ready
	jp   nz,L05FF
	
	ld   a,$1F										; Reset torpedo status
	out  ($02),a									; Torpedo lamps
	ld   (hl),a
	ld   a,$08
	out  ($05),a									; Audio outputs
	call L07EA
L05FF:
	pop  af
	ret

				;; Bit 0 set on $2020
				;; Clear explosions
L0601:
	push af
	xor  a
	out  ($05),a									; Audio outputs
	out  ($01),a									; Explosion lamp
	ld   a,($202D)								; Torpedo status
	out  ($02),a									; Periscope lamp
	pop  af
	ret

				;; Bit 1 set on $2020
L060E:
	push af
	ld   hl,$21F0
L0612:
	ld   a,(hl)
	and  a
	jp   z,L0632

				;; ($21f0) -> de
	ld   (hl),$00
	inc  hl
	ld   d,a
	ld   e,(hl)
	ld   (hl),$00
	inc  hl
	cp   $2C
	ld   bc,$0A03									; 10 x 3 byte area  (after ship hit)
	jp   c,L062A
	ld   bc,$2005									; 32 x 5 byte area  (after mine hit)
L062A:
	ex   de,hl
	call L0A3F										; Clear area at hl
	ex   de,hl
	jp   L0612										; Repeat
L0632:
	pop  af
	ret

				;; Bit 3 set on $2020
				;; Launch new ship
L0634:
	push af
	ld   a,($2003)
	and  $0F
	or   $50
	ld   ($2022),a 		; Set counter
	
	ld   bc,$2029									; Ship type loc
	ld   a,(bc)										; Get ship index
	inc  a												; Increment
	cp   $07											; Max = 6
	jp   nz,L064A
	xor  a												; Set to 0
L064A:
	ld   (bc),a										; Store ship index
	
	ld   hl,L0FDE									; Ship type table
	add  a,l
	ld   l,a
	ld   a,(hl)										; Get ship type
	ld   b,a											; Stash in b
	cp   $06											; Is small / fast?
	jp   nz,L066B									; No = jump
	
	ld   a,$04
	out  ($05),a									; Audio outputs
	ld   a,$19
	ld   ($2023),a								; Set timer
	ld   a,$02
	ld   ($2026),a								; Set timer
	ld   a,$0F
	ld   ($2025),a								; Set timer
	ld   a,b
	
				;; hl = $202c + $0d * a 
L066B:
	ld   hl,$202C
	ld   de,$000D
L0671:
	add  hl,de
	dec  a
	jp   nz,L0671
	
	ld   a,b
	ex   de,hl
	
	ld   hl,$201E									; Current ship move index
	ld   a,(hl)										; Read ship move index
	inc  (hl)											; Increment ship move index
	ld   hl,L0F7E									; Even ship move table?
	rra
	jp   nc,L068B
	
	ld   hl,L0FAE									; Odd ship move table?
	ld   a,b
	or   $10											; Set direction bit
	ld   b,a
	
L068B:
	ld   a,b

				;; Index into ship type table
	dec  a												; a = 0-5 / 10-14
	rlca
	rlca
	rlca
	and  $38											; Clear low bits
	add  a,l
	ld   l,a

				;; Copy ship table data
	ld   c,$08
L0696:
	ld   a,(hl)
	inc  hl
	ld   (de),a
	dec  de
	dec  c
	jp   nz,L0696
	
	ld   a,b
	or   $C0											; B7 = moving, B6 = don't clear, B5 = ??
	ld   (de),a										; Store ship type?
	pop  af
	ret

				;; Called when (($2000)) == 0
L06A4:
	ld   hl,$21C1
L06A7:
	ld   a,(hl)
	and  a
	ret  z												; Skip if $21C1 = 00
	
	ld   (hl),$00									; Clear $21C1
	inc  hl
	ld   d,(hl)										; ($21C2) -> d
	push hl

	;; hl = $2024 + $d * a
	ld   hl,$2024
	ld   bc,$000D
L06B5:
	add  hl,bc
	dec  a
	jp   nz,L06B5
	
	ld   bc,$0008
	add  hl,bc
	
	ld   (hl),$0E
	dec  hl
	ld   (hl),$55
	dec  hl
	dec  hl
	dec  hl
	ld   (hl),$01
	dec  hl
	dec  hl
	ld   (hl),d
	dec  hl
	ld   (hl),$00
	dec  hl
	ld   b,(hl)
	ld   (hl),$E0
	
	ld   a,($2002)								; Ship hit score?
	and  a
	jp   nz,L06DB
	pop  hl
	ret
	
L06DB:
	ld   a,b
	ld   bc,TSCORE-1							; Ship hit score table
	and  $07
	add  a,c
	ld   c,a											; bc = index into table	
	
	ld   de,$21E9
	call L0A82
	ld   a,$30
	ld   (de),a
	inc  de
	ld   (de),a
	ld   a,(bc)
	ld   hl,$202B									; Player score
	add  a,(hl)										; Add a
	daa
	ld   (hl),a										; Store
	pop  hl
	ld   c,(hl)
	inc  hl
	ld   b,(hl)
	inc  hl
	push hl
	ld   a,b
	add  a,$20
	ld   hl,L09C2									; Explosion lamp 0-7 table
	jp   c,L0707
	ld   hl,L09BA									; Explosion lamp 8-F table
L0707:
	ld   a,c
	rlca
	rlca
	rlca
	and  $07
	add  a,l
	ld   l,a
	ld   a,(hl)
	out  ($01),a									; Explosion lamp
	ld   a,$01
	out  ($05),a									; Audio write
	ld   a,$1E
	ld   ($2025),a								; Set timer
	ld   a,b
	ld   d,$24
	add  a,$20
	jp   m,L0725
	ld   d,$28
L0725:
	ld   a,c
	rrca
	rrca
	rrca
	and  $1F
	jp   z,L072F
	dec  a
L072F:
	cp   $1E
	jp   nz,L0735
	dec  a
L0735:
	or   $A0
	ld   e,a
	call L07DB
	ld   a,$2D
	ld   ($2024),a
	ld   hl,$21EA
	ld   a,$03
	call $0B30										; Draw string hl @ de, length a
	pop  hl
	jp   L06A7
	
L074C:
	ld   hl,$21A3
L074F:
	ld   a,(hl)
	and  a
	ret  z
	
	inc  hl
	add  a,$10
	rlca
	rlca
	rlca
	and  $07
	ld   de,$2067
	ld   bc,$000D
	ex   de,hl
L0761:
	add  hl,bc
	add  hl,bc
	dec  a
	jp   nz,L0761
	
	ld   a,(de)
	sub  $08
	sub  (hl)
	cp   $EC
	jp   nc,L0771
	
	add  hl,bc
L0771:
	dec  hl
	dec  hl
	ld   (hl),$00
	ex   de,hl
	dec  hl
	ld   a,(hl)
	add  a,$30
	and  $F0
	ld   d,a
	ld   (hl),$00
	inc  hl
	ld   e,(hl)
	inc  hl
	push hl
	call L0A00
	
	ld   a,e
	and  $1F
	jp   z,L0796
	
	dec  a
	jp   z,L0796
	
L0790:
	dec  a
	cp   $1C
	
	jp   p,L0790
L0796:
	ld   e,a
	call L07DB
	
	ld   b,d
	inc  b
	inc  b
	ld   c,e
	inc  c
	push bc
	ld   a,e
	add  a,$60
	ld   e,a
	push de
	ld   b,d
	inc  c
	push bc
	ld   a,$1E
	ld   ($2025),a								; Set timer
	ld   a,$0F
	ld   ($2024),a
	ld   a,$10
	out  ($05),a									; Sound write
	ld   a,e
	and  $02											; Mask bit 1
	ld   hl,L0F40									; $0F40 or $0F42
	add  a,l
	ld   l,a											; hl = ZAP or WAM

				;; Get address from table -> hl
	ld   e,(hl)
	inc  hl
	ld   d,(hl)
	ex   de,hl										; hl = table entry
	
	pop  de
	ld   a,(hl)
	inc  hl
	call $0B30										; Draw string hl @ de, length a
	
	pop  de
	ld   a,(hl)
	inc  hl
	call $0B30										; Draw string hl @ de, length a
	
	pop  de
	ld   hl,L0EB5
	ld   a,$03
	call $0B30										; Draw string hl @ de, length a
	pop  hl
	jp   L074F
L07DB:
	ld   hl,$21F0
L07DE:
	ld   a,(hl)
	inc  hl
	or   (hl)
	inc  hl
	jp   nz,L07DE
	dec  hl
	ld   (hl),e
	dec  hl
	ld   (hl),d
	ret
	
L07EA:
	ld   a,($202B)								; Player score
	cp   $40			
	jp   c,L07F4
	ld   a,$39										; Min of score or $39
L07F4:
	ld   ($202C),a 		
	
	ld   hl,$207F									; 1st mine sprite
	ld   de,$5050
	
L07FD:
	ld   a,(hl)
	and  a
	jp   m,L0835

				;; Launch mine?
L0802:
	ld   bc,$0008
	add  hl,bc
	ld   (hl),MINE>>8							; Mine MSB (+8)
	dec  hl
	ld   (hl),MINE&$FF 				    ; Mine LSB (+7)
	dec  hl
	dec  hl
	ld   (hl),e										; Y Pos (+5)
	dec  hl
	ld   (hl),b										; Delta Y (+4)
	dec  hl
	dec  hl
	ld   (hl),d										; X Pos (+2)
	dec  hl
	ld   (hl),$01									; Delta X (+1)
	dec  hl
	ld   (hl),$80									; Flags
	ld   a,d
	add  a,$51
	ld   d,a
	rra
	jp   c,L082E
	
	ld   a,($202C)
	sub  $10
	ret  m
	
	ld   ($202C),a
	ld   a,e
	add  a,$20
	ld   e,a
	
L082E:
	ld   bc,$000D									; Increment
	add  hl,bc										; Next mine
	jp   L07FD										; More mines!

	
L0835:
	push hl
	push de
	inc  hl
	inc  hl
	ld   e,(hl)
	inc  hl
	inc  hl
	inc  hl
	ld   d,(hl)
	call L0A00
	ex   de,hl
	ld   bc,$1002									; 16 x 2 byte area
	call L0A3F										; Clear area at hl
	pop  de
	pop  hl
	jp   L0802

HERASE:	
	ret  z
	xor  a
	ld   ($2006),a
	ld   a,($2010)
	and  a
	ret  z
	ld   hl,$21E9
	push hl
	ld   bc,$0430
L085E:
	ld   (hl),c
	inc  hl
	dec  b
	jp   nz,L085E
	pop  hl
	ld   de,$3E25
	ld   a,$04
	jp   $0B30										; Draw string hl @ de, length a

				;; $09E8 Entry B -- ??
JTBLB:													; $086D
	ex   de,hl										; Sequence back to hl
	ld   ($2000),hl								; Store
	
	ld   a,($2003)								; 
	and  $07											; Mask low 3 bits
	cp   $07											; == $07?
	jp   nz,L087C
	xor  a												; Clear
L087C:
	ld   ($2029),a								; Write
	ret

				;; End of game clears
L0880:
	di
	ex   de,hl										; Stash hl in de
	ld   ($2000),hl
	xor  a
	out  ($02),a									; Clear periscope lamp
	out  ($05),a									; Clear audio latches
	out  ($01),a									; Clear explosion lamp
	pop  hl												; (Return address)
	ld   bc,$0000
	ld   de,$0000
	ld   a,$10
	ld   sp,$4010									; Clear $4010 down to $2011
L0898:
	push bc
	inc  de
	cp   d
	jp   nz,L0898									; Loop
	ld   sp,$2400
	jp   (hl)

				;; $09E8 Entry 3 (End game)
JTBL3:	
L08A2:
	pop  hl
	ld   ($2009),hl
	call L0880
	ld   hl,($2009)
	push hl
	ld   hl,L0F04									; Water
	ld   de,$27E0
	ld   a,$20
	jp   $0B30										; Draw string hl @ de, length a
L08B8:
	in   a,($01)									; IN0
	ld   b,a
	in   a,($01)									; IN0
	ld   hl,$2008									; Last IN0
	ld   de,$09DA									; Jump table for IN0
	cp   b
	call z,L0B05									; Handle inputs

				;; Jump table do nothing "routine"
HRET:		
	ret														; (reset)

				;; Handle coin
HCOIN:
	ret  z												; No coin
	ld   a,$20
	out  ($05),a
	ld   a,$0F
	ld   ($2025),a								; Set timer
	ld   a,($2007)
	ld   b,a
	ld   hl,$2004
	inc  (hl)
	and  $04
	jp   z,L08E2
	ld   a,(hl)
	rrca
	ret  c
L08E2:
	ld   (hl),$00
	inc  hl
	inc  (hl)
	ld   a,b
	and  $08
	jp   z,L08F4
	inc  (hl)
	ld   a,b
	and  $04
	jp   z,L08F4
	inc  (hl)
L08F4:
	ld   a,(hl)
	and  $0F
	ld   (hl),a

HPUSH:	
	ret  z
	ld   a,($2002)
	and  a
	ret  nz
	ld   hl,$2005
	ld   a,(hl)
	and  a
	jp   z,L091A
L0906:
	dec  (hl)
	
	in   a,($01)									; IN1
	rlca
	rlca
	and  $03											; Game time dips
	ld   de,$0F54
	add  a,e
	ld   e,a
	ld   a,(de)
	ld   ($2002),a								; Store time
	ld   ($202A),a								; Store time ?
	ret
	
L091A:
	ld   a,($2007)
	and  $0C
	cp   $0C
	ret  nz
	dec  hl
	ld   a,(hl)
	and  a
	ret  z
	jp   L0906

				;; $2000 at reset
L0929:
	.db	$04												; Command 4 = String
	.db	$01												; Length
	.dw	LTBLANK										; String src address
	.db	$30, $3E									; Screen dst address

	.db	$09												; Commnad 9
	.db	$05, $20									; ($2005) -> a   (select string)
	.db	$33, $38									; Location
	.dw	LTCOIN										; "Insert Coin"
	.dw LTPUSH										; "Push Button"

	.db	$04												; Command 4 = String
	.db	$1A												; Length 
	.dw	LTHIGH										; String src address
	.db	$02, $3C									; Screen dst address
	
	.db	$0A												; Command A = BCD @ loc
	.db	$06, $20									; bc = 2006 = high score
	.db	$E9, $21									; Buffer loc
	.db	$25, $3E									; Screen loc
	
	.db	$0A												; Command A = BCD @ loc
	.db	$2B, $20									; bc = 202b = score
	.db	$E9, $21									; Buffer loc
	.db	$35, $3E									; Screen loc
	
	.db	$02												; Command 2 = arg to 2010
	.db	$0F												; arg

L094E:	
	.db	$04												; Command 4 = String
	.db	$09												; Length
	.dw	LTOVER										; String src address
	.db	$0B, $2C									; Screen dst address
        
				;; Delay timer
	.db	$01												; Command 1 = arg to 2011
	.db	$1E												; arg
	.db	$00												; End of sequence

	.db	$04												; Command 4 = String
	.db	$09												; Length
	.dw	LTBLANK										; String src address
	.db $0B, $2C									; Screen dst address

				;; Delay timer
	.db	$01												; Command 1 = arg to 2011
	.db	$1E												; arg
	.db	$00												; End of sequence

				
	.db	$06												; Command 6 = Set ($2000)
	.dw	L094E											; Next command address
	
L0963:
	.db	$03												; Do end of game sequence
	
	.db	$04												; Command 4 = String
	.db	$08												; Length
	.dw LTSEA											; String src address (SEA WOLF)
	.db	$0C, $2C									; Screen dst address

	.db	$04												; Command 4 = String
	.db	$0A												; Length
	.dw	LTHIGH										; String src address (HIGH SCORE)
	.db	$02, $3C									; Screen dst address
	
	.db	$0A												; Command A = BCD @ loc
	.db	$06, $20									; bc = 2006 = high score
	.db	$E9, $21									; Buffer loc
	.db	$25, $3E									; Screen loc
	
	.db	$09												; Commnad 9
	.db	$05, $20									; ($2005) -> a   (select string)
	.db	$33, $38									; Location
	.dw	LTCOIN										; "Insert Coin"
	.dw	LTPUSH										; "Push Button"

				;; Delay timer
	.db	$01												; Command 1 = arg to 2011
	.db	$5A												; arg
	.db	$00												; End of sequence

				;; Launch ship in attract
	.db	$08												; Command 8 (Data backwards to loc)
	.db	$09												; Count
	.dw	$2060											; de = $2060
	.dw	SHIP3											; $0DBE -> ($205F-2060)
	.db	$20												; $20   -> ($205E)
	.db	$15												; $15 	-> ($205D)
	.db	$00												; $00   -> ($205C)
	.db	$E0												; $E0   -> ($205B)
	.db	$00												; $00   -> ($205A)
	.db	$01												; $01	-> ($2059)
	.db	$C4												; $C4	-> ($2058)

				;; Delay timer
	.db	$01												; Command 1 = arg to 2011
	.db	$5A												; arg
	.db	$00												; End of sequence

				;; Launch missile in attract
	.db	$08												; Command 8 (Data backwards to loc)
	.db	$09												; Count
	.dw	$20EF											; de = $20EF
	.dw	SHOT0											; $0E75 -> ($20EE-20EF)
	.db	$9C												; $9C	-> ($20ED)
	.db	$E0												; $E0	-> ($20EC)
	.db	$FA												; $FA	-> ($20EB)
	.db	$00												; $00	-> ($20EA)
	.db	$A8												; $A8	-> ($20E9)
	.db	$00												; $00	-> ($20E8)
	.db	$C0												; $C0	-> ($20E7)

				;; Delay timer
	.db	$01												; Command 1 = arg to 2011
	.db	$B4												; arg
	.db	$00												; End of sequence
	
	.db	$06												; Command 6 = Set ($2000)
	.dw L0963   									; Next command address
        
				;; Delay timer
L09A6:
	.db	$01												; Command 1 = arg to 2011
	.db	$0F												; arg
	.db	$00												; End of sequence
	
	.db	$03												; Command 3 = End game
       	
	.db	$04												; Command 4 = String
	.db	$09												; Length
	.dw	LTTIME										; String src address (TIME/SCORE)
	.db	$0E, $3C									; Screen dst address
	
	.db	$07												; Command 7 = Store a to bc
	.db	$28												; a
	.db	$22, $20									; bc

	.db	$07												; Command 7 = Store a to bc
	.db	$0A												; a
	.db	$21, $20									; bc

	.db	$0B												; Command B = ??
	.db	$00												; End of sequence

				;; Explosion lamp tables!
				;; Table for $0704
L09BA:
	.db	$48, $44, $42, $41, $88, $84, $82, $81		; 
	
				;; Table for $06FE
L09C2:
	.db	$18, $14, $12, $11, $28, $24, $22, $21		; 


				;; Jump table for IN1 changes (8 entries)
TBLIN1:	
	.dw	HCOIN											; 0 = 08C8 = Coin
	.dw	HPUSH											; 1 = 08F8 = Start
	.dw	HRET											; 2 = 08C7 = (ret) Coinage
	.dw HRET											; 3 = 08C7 = (ret) Coinage
	.dw	HERASE  									; 4 = 084D = Erase highs
	.dw	HRET											; 5 = 08C7 = (ret) Extended time
	.dw HRET											; 6 = 08C7 = (ret) Extended time
	.dw	HRET											; 7 = 08C7 = (ret) Extended time

				;; Jump table for IN0 changes (8 entries)
TBLIN0:	
	.dw	HRET											; 0 = 08C7 = (ret) Turret
	.dw	HRET											; 1 = 08C7 = (ret) Turret
	.dw	HRET											; 2 = 08C7 = (ret) Turret
	.dw	HRET											; 3 = 08C7 = (ret) Turret
	.dw	HRET											; 4 = 08C7 = (ret) Turret
	.dw	HFIRE											; 5 = 057B = Fire button
	.dw	HRET											; 6 = 08C7 = (ret) Time
L09E8:
	.dw	HRET											; 7 = 08C7 = (ret) Time

				;; Jump table for $047F (0 entry not used)
				;; Used for attract mode sequence
TBLJMP:	
	.dw	JTBL1											; 1 = 0B7C = Arg to 2011
	.dw	JTBL2											; 2 = 0B72 = Arg to 2010
	.dw	JTBL3											; 3 = 08A2 = End of game + reset
	.dw JTBL4											; 4 = 0B22 = String
	.dw	JTBL5											; 5 = 0AED = d <- (hl++), ret
	.dw	JTBL6											; 6 = 0B86 = (de) -> $2000 
	.dw	JTBL7											; 7 = 0AE1 = val -> addr
	.dw	JTBL8											; 8 = 0A9F = data to loc
	.dw	JTBL9											; 9 = 0ABC = Select String
	.dw	JTBLA											; A = 0A53 = BCD @ location
	.dw	JTBLB											; B = 086D

				;; e&$07 -> c,  de = de >> 3 + $2400, 
L0A00:
	ld   a,e			; Mask e
	and  $07
	ld   c,a			; Stash in a
	ld   b,$03
L0A06:
	xor  a			; a=0, clc
	ld   a,d
	rra
	ld   d,a
	ld   a,e
	rra
	ld   e,a
	dec  b
	jp   nz,L0A06
	ld   a,d
	add  a,$24
	ld   d,a
	ret

L0A16:
	push af												; Store count
	ld   a,(hl)										; Get value
	ld   (bc),a										; Store value
	inc  bc			
	ex   de,hl
	or   (hl)
	inc  hl
	ld   (de),a
	pop  af												; count = a
	push hl
	ld   hl,$0020									; Line increment
	add  hl,de										; hl = de+$0020
	pop  de												; de = old hl
	dec  a
	jp   nz,L0A16									; loop
	ret

	
				;; Draw b x c block from de to screen at hl
L0A2A:
	push bc
	push hl
L0A2C:
	ld   a,(de)
	inc  de
	ld   (hl),a
	inc  hl
	dec  c
	jp   nz,L0A2C
	pop  hl
	ld   bc,$0020
	add  hl,bc
	pop  bc
	dec  b
	jp   nz,L0A2A
	ret


				;; Clear (hl - hl+c-1)  b times with row offsets
L0A3F:
	xor  a
L0A40:
	push bc
	push hl
L0A42:
	ld   (hl),a
	inc  hl
	dec  c
	jp   nz,L0A42
	pop  hl
	ld   bc,$0020
	add  hl,bc
	pop  bc
	dec  b
	jp   nz,L0A40
	ret

	
				;; $09E8 Entry A
JTBLA:													; $0A53
	ex   de,hl
	ld   c,(hl)										; Read bc
	inc  hl
	ld   b,(hl)
	inc  hl
	ld   e,(hl)										; Read de
	inc  hl
	ld   d,(hl)
	dec  hl												; Back up to use again
	call L0A82										; Draw BCD from bc at de
	ex   de,hl										; Last address now in hl
	call L0A7A										; Replace space with zero
	inc  hl
	ex   de,hl										; Last address now in de
	ld   a,$30
	ld   (de),a										; Append zero
	inc  de
	ld   (de),a										; Append zero
	call $0ADC										; (hl, hl+1) -> de, hl+=2
	push de
	call $0ADC										; (hl, hl+1) -> de, hl+=2
	ld   ($2000),hl								; Next command 
	pop  hl
	ld   a,$04
	jp   $0B30										; Draw string hl @ de, length a

				;; Replace space with a zero
L0A7A:
	dec  hl
	ld   a,(hl)
	and  $40
	ret  z
	ld   (hl),$30
	ret

				;; Draw BCD from bc at de
L0A82:
	ld   a,(bc)	
	rra
	rra
	rra
	rra
	and  $0F			; Mask high nybble
	jp   nz,L0A8E	
	ld   a,$10			; $40 -> blank
L0A8E:
	add  a,$30			; Decimal to ascii
	ld   (de),a			; Store digit
	inc  de			; Next screen loc
	ld   a,(bc)			
	and  $0F			; Mask low nybble
	jp   nz,L0A9A
	ld   a,$10			; $40 -> blank
L0A9A:
	add  a,$30			; Decimal to ascii
	ld   (de),a			; Store digit
	inc  de			; Next screen loc
	ret

				;; $09E8 Entry 8 -- Copy data from sequence to address (backwards)
JTBL8:													; $0A9F
	ex   de,hl										; Sequence address back to hl
	ld   b,(hl)										; Get count
	inc  hl
	dec  b
	dec  b
	call $0ADC										; (hl, hl+1) -> de, hl+=2  (address)
	ld   c,(hl)										; Read first byte
	inc  hl
	ld   a,(hl)										; Read second byte
	inc  hl
	ld   (de),a										; Write first byte
	dec  de
	ld   a,c
	ld   (de),a										; Write second byte
	dec  de
	
L0AB0:
	ld   a,(hl)										; Loop for rest of count
	inc  hl
	ld   (de),a
	dec  de
	dec  b
	jp   nz,L0AB0
	ld   ($2000),hl								; Next command
	ret

	
				;; $09E8 Entry 9 -- Draw INSERT COIN or PUSH BUTTON
JTBL9:													; $0ABC
	ex   de,hl
	call $0ADC										; (hl, hl+1) -> de, hl+=2
	ld   a,(de)
	call $0ADC										; (hl, hl+1) -> de, hl+=2
	push de
	call $0ADC										; (hl, hl+1) -> de, hl+=2
	push de
	call $0ADC										; (hl, hl+1) -> de, hl+=2
	ld   ($2000),hl								; Next command
	
	ex   de,hl
	and  a
	jp   z,L0AD5									; Draw first string?
	ex   (sp),hl
L0AD5:
	pop  hl
	pop  de
	ld   a,$0B										; Length
	jp   $0B30										; Draw string hl @ de, length a

L0ADC:
	ld   e,(hl)										; LSB from table
	inc  hl
	ld   d,(hl)										; MSB from table
	inc  hl
	ret

				;; $9EA8 Entry 7 -- arg -> addr
JTBL7:													; $0AE1
	ld   a,(de)										; Next entry
	inc  de
	ex   de,hl
	ld   c,(hl)										; Next entry
	inc  hl
	ld   b,(hl)										; Next entry
	inc  hl
	ld   ($2000),hl								; Store command
	ld   (bc),a										; a -> (bc)
	ret

				;; $09E8 Entry 5
				;; Read from de table into b, c, a, e, d
JTBL5:													; $0AED
	ex   de,hl			
	ld   b,(hl)
	inc  hl
	ld   c,(hl)
	inc  hl
	ld   a,(hl)
	inc  hl
	call L0ADC
	ld   ($2000),hl
	ex   de,hl
	ld   (hl),$DB
	inc  hl
	ld   (hl),c
	inc  hl
	ld   (hl),$C9
	dec  hl
	dec  hl
	jp   (hl)

				;; Deal with inputs (when stable)
L0B05:
	xor  (hl)
	ret  z			; No changes
	
	ld   c,a			; Stash IN0	
	ld   b,$01			; Bit being checked
	
L0B0A:
	ld   a,c			; Restore IN0	
	rrca
	jp   c,L0B18 		; Bit is high
	
	ld   c,a			; Stash IN0
	ld   a,b			; Shift check bit
	rlca
	ld   b,a
	inc  de			; Advance jump table
	inc  de
	jp   L0B0A			; Loop
	
L0B18:
	ld   a,b			; Bit found to a
	xor  (hl)			; Clear bit
	ld   (hl),a			; Store back
	and  b			; Value of changed bit
	ex   de,hl
	ld   c,(hl)
	inc  hl
	ld   h,(hl)
	ld   l,c
	jp   (hl)			; Handle changed bit

				;; $09E8 Entry 4 (Draw string))
JTBL4:													; $0E22
	ex   de,hl										; ($2000)+1 -> 
	ld   a,(hl)
	inc  hl
	call $0ADC										; (hl, hl+1) -> de, hl+=2
	push de
	call $0ADC										; (hl, hl,1) -> de, hl+=2
	ld   ($2000),hl								; Next command
	pop  hl												; String src address

				;; Write string length a from hl to de
L0B30:
	push af
L0B31:
	ld   a,(hl)										; Get byte
	inc  hl
	sub  $30											; Ascii -> tbl
	jp   p,L0B49									; Jump if >=$30

				;; Blank space = $30-a (?)
	ld   b,a
L0B39:
	inc  e
	ld   a,e
	and  $1F
	jp   nz,L0B42									; No wrap
	inc  d
	inc  d
L0B42:
	inc  b
	jp   nz,L0B39									; Loop
	jp   L0B31										; Next char

				;; ASCII
L0B49:
	push hl
	push de
	ld   hl,CHARS									; Start of char table
	jp   z,L0B59									; (no need to add)
	ld   bc,$000A									; Add a*$0a
L0B54:
	add  hl,bc
	dec  a
	jp   nz,L0B54
	
L0B59:
	ex   de,hl
	ld   bc,$0020
	ld   a,$0A										; Loop $a times
L0B5F:
	push af
	ld   a,(de)										; Load byte
	inc  de												; Inc index
	ld   (hl),a										; Store to screen
	add  hl,bc										; Next screen loc
	pop  af
	dec  a
	jp   nz,L0B5F									; Loop for this char
	pop  de
	pop  hl
	inc  de
	pop  af
	dec  a
	jp   nz,L0B30									; Next char
	ret

				;; $09E8 Entry 2  (argument to 2010)
JTBL2:													; $0B72
	ex   de,hl
	ld   a,(hl)										; Argument
	inc  hl
	ld   ($2000),hl
	ld   ($2010),a								; Store ??
	ret

				;; $09E8 Entry 1 (argument to 2011)
JTBL1:													; $0B7C
	ex   de,hl
	ld   a,(hl)										; Argument
	inc  hl
	ld   ($2000),hl
	ld   ($2011),a								; Store ??
	ret

				;; $09E8 Entry 6 (de) -> $2000
JTBL6:													; $0B86
	ex   de,hl
	ld   e,(hl)
	inc  hl
	ld   d,(hl)
	ex   de,hl
	ld   ($2000),hl
	ret

				;; Character table
				;; .org	$0b8f
CHARS:													; $0B8F

	.db	$3c		; ....########.... $30
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3c		; ....########.... 

	.db	$18		; ......####...... $31
	.db	$1c		; ....######...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$3c		; ....########.... 
	.db	$3c		; ....########.... 

	.db	$3c		; ....########.... $32
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$60		; ..........####.. 
	.db	$7c		; ....##########.. 
	.db	$3e		; ..##########.... 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$7e		; ..############.. 
	.db	$7e		; ..############.. 

	.db	$3c		; ....########.... $33
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$60		; ..........####.. 
	.db	$38		; ......######.... 
	.db	$78		; ......########.. 
	.db	$60		; ..........####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3c		; ....########.... 

	.db	$66		; ..####....####.. $34
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$7e		; ..############.. 
	.db	$60		; ..........####.. 
	.db	$60		; ..........####.. 
	.db	$60		; ..........####.. 
	.db	$60		; ..........####.. 

	.db	$3e		; ..##########.... $35
	.db	$3e		; ..##########.... 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$3e		; ..##########.... 
	.db	$7e		; ..############.. 
	.db	$60		; ..........####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3c		; ....########.... 

	.db	$3c		; ....########.... $36
	.db	$3e		; ..##########.... 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$3e		; ..##########.... 
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3c		; ....########.... 

	.db	$7e		; ..############.. $37
	.db	$7e		; ..############.. 
	.db	$60		; ..........####.. 
	.db	$70		; ........######.. 
	.db	$30		; ........####.... 
	.db	$38		; ......######.... 
	.db	$18		; ......####...... 
	.db	$1c		; ....######...... 
	.db	$0c		; ....####........ 
	.db	$0c		; ....####........ 

	.db	$3c		; ....########.... $38
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$3c		; ....########.... 
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3c		; ....########.... 

	.db	$3c		; ....########.... $39
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$7c		; ....##########.. 
	.db	$60		; ..........####.. 
	.db	$60		; ..........####.. 
	.db	$7c		; ....##########.. 
	.db	$3c		; ....########.... 

WATER0:													; $0BF3 
	.db	$0c		; ....####........ $3A
	.db	$93		; ####....##....## 
	.db	$60		; ..........####.. 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 

WATER1:													; $0BFD
	.db	$60		; ..........####.. $3B
	.db	$99		; ##....####....## 
	.db	$06		; ..####.......... 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 

WATER2:													; $0C07
	.db	$30		; ........####.... $3C
	.db	$cd		; ##..####....#### 
	.db	$02		; ..##............ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 

EXP0:														; $0C11
	.db	$02		; ..##............ $3D
	.db	$c0		; ............#### 
	.db	$78		; ......########.. 
	.db	$e0		; ..........###### 
	.db	$80		; ..............## 
	.db	$f0		; ........######## 
	.db	$01		; ##.............. 
	.db	$c0		; ............#### 
	.db	$f0		; ........######## 
	.db	$7c		; ....##########.. 

EXP1:														; $0C1B
	.db	$08		; ......##........ $3E
	.db	$1c		; ....######...... 
	.db	$3e		; ..##########.... 
	.db	$7f		; ##############.. 
	.db	$ff		; ################ 
	.db	$ff		; ################ 
	.db	$bf		; ############..## 
	.db	$1f		; ##########...... 
	.db	$02		; ..##............ 
	.db	$40		; ............##.. 

EXP2:														; $0C25
	.db	$02		; ..##............ $3F
	.db	$80		; ..............## 
	.db	$78		; ......########.. 
	.db	$1e		; ..########...... 
	.db	$07		; ######.......... 
	.db	$01		; ##.............. 
	.db	$7c		; ....##########.. 
	.db	$f8		; ......########## 
	.db	$0c		; ....####........ 
	.db	$10		; ........##...... 

	.db	$00		; ................ $40
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$00		; ................ 

	.db	$18		; ......####...... $41
	.db	$3c		; ....########.... 
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 

	.db	$3e		; ..##########.... $42
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$3e		; ..##########.... 
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3e		; ..##########.... 

	.db	$3c		; ....########.... $43
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3c		; ....########.... 

	.db	$3e		; ..##########.... $44
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3e		; ..##########.... 

	.db	$7e		; ..############.. $45
	.db	$7e		; ..############.. 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$3e		; ..##########.... 
	.db	$3e		; ..##########.... 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$7e		; ..############.. 
	.db	$7e		; ..############.. 

	.db	$7e		; ..############.. $46
	.db	$7e		; ..############.. 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$3e		; ..##########.... 
	.db	$3e		; ..##########.... 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 

	.db	$3c		; ....########.... $47
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$76		; ..####..######.. 
	.db	$76		; ..####..######.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3c		; ....########.... 

	.db	$66		; ..####....####.. $48
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 

	.db	$3c		; ....########.... $49
	.db	$3c		; ....########.... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$3c		; ....########.... 
	.db	$3c		; ....########.... 

	.db	$60		; ..........####.. $4A
	.db	$60		; ..........####.. 
	.db	$60		; ..........####.. 
	.db	$60		; ..........####.. 
	.db	$60		; ..........####.. 
	.db	$60		; ..........####.. 
	.db	$60		; ..........####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3c		; ....########.... 

	.db	$66		; ..####....####.. $4B
	.db	$66		; ..####....####.. 
	.db	$76		; ..####..######.. 
	.db	$3e		; ..##########.... 
	.db	$1e		; ..########...... 
	.db	$1e		; ..########...... 
	.db	$3e		; ..##########.... 
	.db	$76		; ..####..######.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 

	.db	$06		; ..####.......... $4C
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$7e		; ..############.. 
	.db	$7e		; ..############.. 

	.db	$c3		; ####........#### $4D
	.db	$c3		; ####........#### 
	.db	$e7		; ######....###### 
	.db	$e7		; ######....###### 
	.db	$ff		; ################ 
	.db	$ff		; ################ 
	.db	$db		; ####..####..#### 
	.db	$c3		; ####........#### 
	.db	$c3		; ####........#### 
	.db	$c3		; ####........#### 

	.db	$66		; ..####....####.. $4E
	.db	$66		; ..####....####.. 
	.db	$6e		; ..######..####.. 
	.db	$6e		; ..######..####.. 
	.db	$7e		; ..############.. 
	.db	$7e		; ..############.. 
	.db	$76		; ..####..######.. 
	.db	$76		; ..####..######.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 

	.db	$3c		; ....########.... $4F
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3c		; ....########.... 

	.db	$3e		; ..##########.... $50
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3e		; ..##########.... 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 
	.db	$06		; ..####.......... 

	.db	$3c		; ....########.... $51
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$5c		; ....######..##.. 

	.db	$3e		; ..##########.... $52
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3e		; ..##########.... 
	.db	$76		; ..####..######.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 

	.db	$3c		; ....########.... $53
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$06		; ..####.......... 
	.db	$3e		; ..##########.... 
	.db	$7c		; ....##########.. 
	.db	$60		; ..........####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3c		; ....########.... 

	.db	$7e		; ..############.. $54
	.db	$7e		; ..############.. 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 

	.db	$66		; ..####....####.. $55
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3c		; ....########.... 

	.db	$66		; ..####....####.. $56
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3c		; ....########.... 
	.db	$3c		; ....########.... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 

	.db	$c3		; ####........#### $57
	.db	$c3		; ####........#### 
	.db	$c3		; ####........#### 
	.db	$db		; ####..####..#### 
	.db	$ff		; ################ 
	.db	$ff		; ################ 
	.db	$e7		; ######....###### 
	.db	$e7		; ######....###### 
	.db	$c3		; ####........#### 
	.db	$c3		; ####........#### 

	.db	$66		; ..####....####.. $58
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3c		; ....########.... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$3c		; ....########.... 
	.db	$7e		; ..############.. 
	.db	$66		; ..####....####.. 
	.db	$66		; ..####....####.. 

	.db	$66		; ..####....####.. $59
	.db	$66		; ..####....####.. 
	.db	$7e		; ..############.. 
	.db	$3c		; ....########.... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 

	.db	$7e		; ..############.. $5A
	.db	$7e		; ..############.. 
	.db	$60		; ..........####.. 
	.db	$70		; ........######.. 
	.db	$38		; ......######.... 
	.db	$1c		; ....######...... 
	.db	$0e		; ..######........ 
	.db	$06		; ..####.......... 
	.db	$7e		; ..############.. 
	.db	$7e		; ..############..

				;; .org	$0d3d
SHIP0:													; $0D3D
	.db	$05, $0c		; Size 5 x 12
	.db	$00, $00, $08, $00, $00		; ................ ................ ......##........ ................ ................ 
	.db	$00, $00, $08, $00, $00		; ................ ................ ......##........ ................ ................ 
	.db	$00, $60, $0e, $00, $00		; ................ ..........####.. ..######........ ................ ................ 
	.db	$00, $e0, $ce, $3f, $00		; ................ ..........###### ..######....#### ############.... ................ 
	.db	$00, $e0, $de, $03, $00		; ................ ..........###### ..########..#### ####............ ................ 
	.db	$f8, $f7, $df, $f7, $0f		; ......########## ######..######## ##########..#### ######..######## ########........ 
	.db	$80, $f7, $df, $f7, $00		; ..............## ######..######## ##########..#### ######..######## ................ 
	.db	$ff, $ff, $ff, $ff, $ff		; ################ ################ ################ ################ ################ 
	.db	$ff, $ff, $ff, $ff, $7f		; ################ ################ ################ ################ ##############.. 
	.db	$ff, $ff, $ff, $ff, $3f		; ################ ################ ################ ################ ############.... 
	.db	$fe, $ff, $ff, $ff, $1f		; ..############## ################ ################ ################ ##########...... 
	.db	$fe, $ff, $ff, $ff, $0f		; ..############## ################ ################ ################ ########........ 

SHIP1:													; $0D7C
	.db	$04, $0c		; Size 4 x 12
	.db	$00, $00, $03, $00		; ................ ................ ####............ ................ 
	.db	$00, $36, $03, $00		; ................ ..####..####.... ####............ ................ 
	.db	$00, $36, $03, $00		; ................ ..####..####.... ####............ ................ 
	.db	$02, $b6, $03, $00		; ..##............ ..####..####..## ####............ ................ 
	.db	$87, $ff, $f3, $07		; ######........## ################ ####....######## ######.......... 
	.db	$e2, $ff, $f7, $00		; ..##......###### ################ ######..######## ................ 
	.db	$ff, $ff, $ff, $ff		; ################ ################ ################ ################ 
	.db	$ff, $ff, $ff, $7f		; ################ ################ ################ ##############.. 
	.db	$ff, $ff, $ff, $3f		; ################ ################ ################ ############.... 
	.db	$fc, $ff, $ff, $1f		; ....############ ################ ################ ##########...... 
	.db	$fc, $ff, $ff, $0f		; ....############ ################ ################ ########........ 
	.db	$f8, $ff, $ff, $07		; ......########## ################ ################ ######.......... 

SHIP2:													;	$0DAE
	.db	$05, $0c		; Size 5 x 12
	.db	$00, $00, $40, $00, $00		; ................ ................ ............##.. ................ ................ 
	.db	$00, $00, $f0, $00, $00		; ................ ................ ........######## ................ ................ 
	.db	$00, $00, $f0, $00, $00		; ................ ................ ........######## ................ ................ 
	.db	$00, $80, $f0, $1e, $00		; ................ ..............## ........######## ..########...... ................ 
	.db	$00, $00, $fb, $06, $00		; ................ ................ ####..########## ..####.......... ................ 
	.db	$ff, $ff, $ff, $ff, $ff		; ################ ################ ################ ################ ################ 
	.db	$fc, $ff, $ff, $ff, $3f		; ....############ ################ ################ ################ ############.... 
	.db	$fc, $ff, $ff, $ff, $1f		; ....############ ################ ################ ################ ##########...... 
	.db	$fc, $ff, $ff, $ff, $0f		; ....############ ################ ################ ################ ########........ 
	.db	$f8, $ff, $ff, $ff, $07		; ......########## ################ ################ ################ ######.......... 
	.db	$f8, $ff, $ff, $ff, $03		; ......########## ################ ################ ################ ####............ 
	.db	$f8, $ff, $ff, $ff, $03		; ......########## ################ ################ ################ ####............ 

SHIP3:													; $0DEC
	.db	$04, $0b		; Size 4 x 11
	.db	$40, $00, $00, $02		; ............##.. ................ ................ ..##............ 
	.db	$40, $80, $00, $02		; ............##.. ..............## ................ ..##............ 
	.db	$40, $00, $07, $02		; ............##.. ................ ######.......... ..##............ 
	.db	$40, $00, $07, $02		; ............##.. ................ ######.......... ..##............ 
	.db	$40, $f0, $07, $02		; ............##.. ........######## ######.......... ..##............ 
	.db	$fc, $f0, $07, $f8		; ....############ ........######## ######.......... ......########## 
	.db	$fc, $ff, $ff, $7f		; ....############ ################ ################ ##############.. 
	.db	$fc, $ff, $ff, $3f		; ....############ ################ ################ ############.... 
	.db	$f8, $ff, $ff, $1f		; ......########## ################ ################ ##########...... 
	.db	$f0, $ff, $ff, $0f		; ........######## ################ ################ ########........ 
	.db	$f0, $ff, $ff, $0f		; ........######## ################ ################ ########........ 

SHIP4:													; $0E1A
	.db	$04, $0b		; Size 4 x 11
	.db	$80, $00, $00, $00		; ..............## ................ ................ ................ 
	.db	$00, $00, $00, $01		; ................ ................ ................ ##.............. 
	.db	$a0, $01, $00, $01		; ..........##..## ##.............. ................ ##.............. 
	.db	$a0, $01, $00, $01		; ..........##..## ##.............. ................ ##.............. 
	.db	$f0, $01, $00, $01		; ........######## ##.............. ................ ##.............. 
	.db	$f8, $01, $00, $f9		; ......########## ##.............. ................ ##....########## 
	.db	$f8, $ff, $ff, $7f		; ......########## ################ ################ ##############.. 
	.db	$f0, $ff, $ff, $3f		; ........######## ################ ################ ############.... 
	.db	$f0, $ff, $ff, $1f		; ........######## ################ ################ ##########...... 
	.db	$f0, $ff, $ff, $0f		; ........######## ################ ################ ########........ 
	.db	$e0, $ff, $ff, $0f		; ..........###### ################ ################ ########........ 

SHIP5:													; $0E48
	.db	$02, $06		; Size 2 x 6
	.db	$00, $03		; ................ ####............ 
	.db	$10, $07		; ........##...... ######.......... 
	.db	$e0, $ff		; ..........###### ################ 
	.db	$ff, $7f		; ################ ##############.. 
	.db	$ff, $3f		; ################ ############.... 
	.db	$ff, $1f		; ################ ##########...... 

SINK:														; $0E56
	.db	$02, $0f		; Size 2 x 15
	.db	$10, $00		; ........##...... ................ 
	.db	$30, $02		; ........####.... ..##............ 
	.db	$70, $01		; ........######.. ##.............. 
	.db	$fc, $00		; ....############ ................ 
	.db	$f8, $11		; ......########## ##......##...... 
	.db	$f0, $3b		; ........######## ####..######.... 
	.db	$e0, $7f		; ..........###### ##############.. 
	.db	$c0, $3f		; ............#### ############.... 
	.db	$80, $1f		; ..............## ##########...... 
	.db	$00, $3f		; ................ ############.... 
	.db	$00, $1e		; ................ ..########...... 
	.db	$00, $04		; ................ ....##.......... 
	.db	$00, $48		; ................ ......##....##.. 
	.db	$00, $f8		; ................ ......########## 
	.db	$00, $f8		; ................ ......########## 

SHOT0:													; E0E76
	.db	$01, $11									; Size 1 x 17
	.db	$10		; ........##...... 
	.db	$38		; ......######.... 
	.db	$38		; ......######.... 
	.db	$38		; ......######.... 
	.db	$38		; ......######.... 
	.db	$38		; ......######.... 
	.db	$38		; ......######.... 
	.db	$38		; ......######.... 
	.db	$38		; ......######.... 
	.db	$38		; ......######.... 
	.db	$38		; ......######.... 
	.db	$38		; ......######.... 
	.db	$38		; ......######.... 
	.db	$10		; ........##...... 
	.db	$10		; ........##...... 
	.db	$10		; ........##...... 
	.db	$38		; ......######.... 

SHOT1:													; $0E89
	.db	$01, $0e									; Size 1 x 14
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$18		; ......####...... 
	.db	$00		; ................ 
	.db	$18		; ......####...... 

SHOT2:													; $0E99
	.db	$01, $09									; Size 1 x 9
	.db	$10		; ........##...... 
	.db	$10		; ........##...... 
	.db	$10		; ........##...... 
	.db	$10		; ........##...... 
	.db	$10		; ........##...... 
	.db	$10		; ........##...... 
	.db	$10		; ........##...... 
	.db	$10		; ........##...... 
	.db	$10		; ........##...... 

MINE:														; $0EA4
	.db	$01, $10									; Size 1 x 16
	.db	$10		; ........##...... 
	.db	$ba		; ..##..######..## 
	.db	$7c		; ....##########.. 
	.db	$fe		; ..############## 
	.db	$7c		; ....##########.. 
	.db	$38		; ......######.... 
	.db	$54		; ....##..##..##.. 
	.db	$10		; ........##...... 
	.db	$00		; ................ 
	.db	$10		; ........##...... 
	.db	$00		; ................ 
	.db	$08		; ......##........ 
	.db	$00		; ................ 
	.db	$00		; ................ 
	.db	$04		; ....##.......... 
	.db	$00		; ................ 

				
				;; Table for $07CF
L0EB5:
	.db	$3D, $3E, $3F		; TABLE

LTBLANK:																				; $0EB8
	.db	$40, $40, $40, $40, $40, $40, $40, $40		; ________
	.db	$40, $40, $40															; ___

LTOVER:																					; $0EC3
	.db	$47, $41, $4D, $45, $40, $4F, $56, $45		; GAME_OVE
	.db	$52																				; R

LTHIGH:																					; $0ECC 
	.db	$48, $49, $47, $48, $40, $53, $43, $4F		; HIGH_SCO
	.db	$52, $45, $40, $40, $40, $40, $40, $40		; RE______
	.db	$59, $4F, $55, $52, $40, $53, $43, $4F		; YOUR_SCO
	.db	$52, $45																	; RE

LTCOIN:																					; $0EE6
	.db	$49, $4E, $53, $45, $52, $54, $40, $43		; INSERT_C
	.db	$4F, $49, $4E															; OIN

LTPUSH:																					; $0EF1 
	.db	$50, $55, $53, $48, $40, $42, $55, $54		; PUSH_BUT
	.db	$54, $4F, $4E															; TON

LTSEA:																					; $0EFC 
	.db	$53, $45, $41, $40, $57, $4F, $4C, $46		; SEA_WOLF

				;; Water
L0F04:
	.db	$3A, $3B, $3C, $3B, $3C, $3A, $3B, $3C		; All
	.db	$3A, $3C, $3B, $3C, $3A, $3B, $3A, $3C		; Water
	.db	$3B, $3A, $3C, $3A, $3B, $3C, $3A, $3C		; Codes
	.db	$3B, $3C, $3A, $3B, $3C, $3A, $3B, $3C		; Here

LTBONUS:																				; $0F24 
	.db	$42, $4F, $4E, $55, $53										; BONUS

LTTIME:																					; $0F29 
	.db	$54, $49, $4D, $45												; TIME
	.db	$2D																				; <space>
	.db	$53, $43, $4F, $52, $45										; SCORE

LTEXT:																					; $0F33 
L0F33:
	.db	$45, $58, $54, $45, $4E, $44, $45, $44		; EXTENDED
	.db	$16																				; <space>
	.db	$54, $49, $4D, $45     										; TIME

				;; Table for $07B9
L0F40:
	.dw	TZAP																			; ZAP
	.dw TWAM																			; WAM

				;; Table from $0F40	(For ZAP)
TZAP:		
	.db	$01, $41, $04, $3D, $5A, $2F, $50, $3F		; *ZAP*

				;; Table from $0F42	(For WAM)
TWAM:
	.db	$01, $41, $04,	$3D, $57, $2F, $4D, $3F		; *WAM*

				;; 4-byte table (time per credit)
LDTIME:																					; $0F54 
	.db	$61, $71, $81, $91												; (Seconds) 

				;; $0F57 = 8-byte score table (0 not used)
TSCORE:																					; $0F58
	.db	$03, $03, $03, $01, $01, $07		; 

				;; Table for $05D2	(0x20 long)
				;; Grey code decode
TGREY:																					; $0F5E 
	.db	$00, $08, $18, $10, $38, $30, $20, $28		; 
	.db	$78, $70, $60, $68, $40, $48, $58, $50		; 
	.db	$F8, $F0, $E0, $E8, $C0, $C8, $D8, $D0		; 
	.db	$80, $88, $98, $90, $B8, $B0, $A0, $A8		; 


				;; Ship tables
				;; 00-01	= Sprite address
				;; 02			= $20 = Right to Left, $40 = Left to Right
				;; 03 		= Initial Y
				;; 04 		= Delta Y (Always 0 for ships)
				;; 05			= Final X
				;; 06			= Initial X
				;; 07			= Delta X
	
				;; Even ship table
L0F7E:
	.db	(SHIP0>>8), SHIP0&$ff
	.db	$20, $14, $00, $D8, $00, $02							; Ship 0
	.db	(SHIP1>>8), SHIP1&$ff
	.db	$20, $14, $00, $E0, $00, $02							; Ship 1
	.db	(SHIP2>>8), SHIP2&$ff
	.db	$20, $14, $00, $D8, $00, $02							; Ship 2
	.db	(SHIP3>>8), SHIP3&$ff
	.db	$20, $15, $00, $E0, $00, $01							; Ship 3
	.db	(SHIP4>>8), SHIP4&$ff
	.db	$20, $15, $00, $E0, $00, $01							; Ship 4
	.db	(SHIP5>>8), SHIP5&$ff
	.db	$20, $1A, $00, $F0, $00, $03							; Ship 5

				;; Odd ship table
L0FAE:
	.db	(SHIP0>>8), SHIP0&$ff
	.db $40, $34, $00, $D8, $D8, $FE							; Ship 0
	.db (SHIP1>>8), SHIP1&$ff
	.db	$40, $34, $00, $E0, $E0, $FE							; Ship 1
	.db (SHIP2>>8), SHIP2&$ff
	.db	$40, $34, $00, $D8, $D8, $FE							; Ship 2
	.db (SHIP3>>8), SHIP3&$ff
	.db	$40, $35, $00, $E0, $E0, $FF							; Ship 3
	.db (SHIP4>>8), SHIP4&$ff
	.db	$40, $35, $00, $E0, $E0, $FF							; Ship 4
	.db (SHIP5>>8), SHIP5&$ff
	.db	$40, $3A, $00, $F0, $F0, $FD							; Ship 5

	
				;; Ship type table
L0FDE:
	.db	$06																				; Small, fast
	.db	$04																				; Mid, 2 towers
	.db	$02																				; Cross in back
	.db	$06																				; Small, fast
	.db	$03																				; Big, flat top
	.db	$05																				; Tower in back
	.db	$01																				; Battleship
	
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
	rst  38
				
.end
			