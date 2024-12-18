				;; @2024 Mark Spaeth -- mspaeth@gmail.com
				;; Whitespace for emacs asm mode w/ tab width 2

				;; Programmed for tasm z80 mode using only 8080 instructions

				;; Config variables
OLDMINE	= 1
SW2024	= 0

				;; Generic variables
SINC		= $000D									; Ship entry length
MINC		= $000D									; Mine entry length
RINC		= $0020									; Row increment
TINC		= $001E									; Torpedo entry length

				;; Memory locations
PRGPTR	= $2000									; $2000-2001
GTIME		= $2002
CREDIT	= $2005									; Was $2005, half credit not used
HSCORE	= $2006									; Was $2006
HSCOREH	= HSCORE+1
IN1			= $2007
IN0			= $2008
TIMER1	= $2010
TIMER2	= $2011
HMINE		= $2014									; Next mine to update
HTORP		= $2016									; Next torp to update
HSHIPA	= $2018									; SHIPA handle
HSHIPB	= $201A									; SHIPB handle
HSUNK		= $201C									; SUNK handle (?)
PSCORE	= $202B									; Was $202B

SHIPA0	= $2031									; Base address of ship A
SHIPA1	= SHIPA0+SINC						; $203E ($0d block)
SHIPA2	= SHIPA1+SINC						; $204B ($0d block)
SHIPAX	= SHIPA2+SINC						; $2058 ($0d block)

SHIPB0	= $2058									; Base address of ship B
SHIPB1	= SHIPB0+SINC						; $2065 ($0d block)
SHIPB2	= SHIPB1+SINC						; $2072 ($0d block)
SHIPBX	= SHIPB2+SINC						; $207F ($0d block)

MINES		= $207F									; Base address of mines
MINEX		= MINES+(8*MINC)				; $20E7 (8x $0d blocks)

TORPS		= $20E7									; Base address of torpedos
TORPX		= TORPS+(4*TINC)				; $215F (4x $1e blocks)

TXTBUF	= $21E9
TXTBUF1	= TXTBUF+1

				;; out 01    = Explosion matrix
				;; out 02    = Torpedo display
				;; out 03    = Shifter data
				;; out 04    = Shifter count
				;; out 05    = Sound triggers
				;; out 06    = watchdog (add this)


				;; Original memory addresses (modded for this)
				;; 2000-2001 = Pointer address for main game/attract loop
				;; 2002      = Game time?
				;; 2003      = Down counter ($1E to $00)
				;; 2004      = Partial credits
				;; 2005      = Credits
				;; 2006      = High score byte
				;; 2007      = Last IN1
				;; 2008	     = Last IN0
				;; 200e-200f = Unused?
				;; 2010      = Down counter (when $2003 == 0)
				;; 2011      = Down counter
				;; 2012-2013 = (Not used?)
				;; 2014-2015 = Sprite draw handle
				;; 2016-2017 = Ship 0  handle
				;; 2018-2019 = Ship 1  handke
				;; 201a-201b = Torpedo handle 
				;; 201c      = Next sprite?
				;; 201e      = ??
				;; 201f      = Draw / not draw for flashing?

				;; 2020 = Mask for subs to call at 04ce (when [[$2000]] == 00)
				;;             D7 = $2002, D6 = $2010, D5 = $2011, D4 = $2021
				;;             D3 = $2022, D2 = $2023, D1 = $2024, D0 = $2025
				;; 2021      = Down counter (non-zero inhibits fire)
				;; 2022      = Down counter
				;; 2023      = Down counter ($19 for small ship)
				;; 2024      = Timer (to show score / explosion)
				;; 2025      = Timer (audio)
				;; 2026      = Down counter ($0f for small ship)
				;; 2027-2028 = Wave state
				;; 2029      = Next ship type
				;; 202A      = Duplicate game time
				;; 202b      = Player score
				;; 202c      = ?? 
				;; 202d      = Torpedo status
				;; 202e      = 1 if extended time passed
				;; 202f      = Ship Launch direction?
				;; 2030      = Current sprite shift
				;; 2031-203D = Sprite ($0d block)
				;;		Byte 0   = X flags?
				;;		Byte 1   = Delta X
				;;		Byte 2   = X Pos  ((loc-$2400) & $1f)<<3 | (shift & $07)
				;;		Byte 3   = Y flags
				;;		Byte 4   = Delta Y
				;;		Byte 5   = Y Pos  loc-$2400)>>5
				;;		Byte 6   = ??
				;;		Byte 7-8 = Sprite tbl LSB,MSB
				;;		Byte 9-A = (address -> de -> hl)
				;;		Byte C-D = (read into bc)
				;; 203E-204A = Sprite ($0d block)
				;; 204B-2057 = Sprite ($0d block)
				;; 2058-2064 = Ship data 0 (Attract?)
				;; 2065-2071 = Ship data 1
				;; 2072-207e = Ship data 2
				
				;; 207f-208b = Mine data 0
				;; 208c-2098 = Mine data 1
				;; 2099-20a5 = Mine data 2
				;; 20a6-20b2 = Mine data 3
				;; 20b3-20bf = Mine data 4
				;; 20c0-20cc = Mine data 5
				;; 20cd-20d9 = Mine data 6
				;; 20da-20e6 = Mine data 7

				;; 20c9-20e6
				
				;; Torpedo control?
				;; 20e7-2104 = $1e data block
				;; 2105-2122 = $1e data block
				;; 2123-2140 = $1e data block
				;; 2140-21r3 = $1e data block
				
				;; 215f-21a3 = $44 data block, cleared at $0088
				
				;; 21e9-21ef = 7 character buffer for time+score
				;; 21f0-21f1 = Address for $0A3F clear if non-zero
				;; 21f2-21f3 = Address for $0A3F clear if non-zero
				;; 21f4-21f5 = Address for $0A3F clear if non-zero
				;; 21f4-21f5 = Address for $0A3F clear if non-zero

				;; RST $00 ($C7)
				.org		$0000
L0000:
				nop
				nop
				ld			sp,$2400				; Stack pointer
				jp			L043A						; Startup jump

				;; rst $08 ($cf interrupt vector)
RST08:
				push		hl
				push		de
				push		bc
				push		af
				jp			L007E
				nop

				;; rst $10 ($d7 interrupt vector)
RST10:
				push		hl
				push		de
				push		bc
				push		af
				ld			a,($201F)				; ??
				and			a
				jp			nz,L003E

				call		L03BC						; Update wave
				call		L012E						; Update a sprite

				ld			hl,($2016)			; Sprite pointer
				ld			a,(hl)
				and			a
				jp			p,L0036					; D7=0 = inactive
				and			$20
				jp			z,L0036					; D5=0 = don't draw
	
				call		L035B						; Load de, bc from ship data
				dec			c
				ex			de,hl
				call		L0A2A						; Draw b x c block from de at hl
				
L0036:
				ld			a,$FF
				ld			($201F),a	
				jp			L0069						; End of interrupt routine
	
L003E:
				ld			hl,($2016)			; Sprite pointer
				ld			a,(hl)
				and			a
				jp			p,L0062					; D7=0 = inactive
	
				and			$40
				jp			nz,L0050				; Jump if not set to clear
				ld			(hl),$00				; Clear sprite
				jp			L0062
	
L0050:
				ld			a,(hl)					; Set flags bit 5
				or			$20
				ld			(hl),a
				call		L0165						; Update sprite
				ld			a,b
				push		hl							
				ld			hl,($201C)			; ($201C) to bc
				ld			b,h
				ld			c,l
				pop			hl
				call		L0A16
	
L0062:
				call		L0368
				xor			a
				ld			($201F),a

				;; End of interrupt routine
L0069:
				in			a,($02)					; IN1
				ld			b,a
				in			a,($02)					; IN1
				ld			hl,IN1					; Last IN1
				ld			de,TBLIN1				; IN1 handler table
				cp			b								; Poor man's debounce
				call		z,L0B05					; Call if stable
				
				pop			af
				pop			bc
				pop			de
				pop			hl
				ei
				ret
				

				;; Interrupt $08 vector continues...
L007E:
				ld			a,($201F)
				and			a
				jp			nz,L0119
				call		L03BC						; Update wave
	
				;; Clear $215f-$21a3
				ld			hl,$215F
				ld			b,$44
				xor			a
L008E:
				ld			(hl),a
				inc			hl
				dec			b
				jp			nz,L008E
	
				ld			hl,($2018)			; Sprite pointer 0
				ld			a,$03						; Loop counter 
L0099:
				push		af
				ld			a,l
				cp			$58							; Cycles $2031 / $203E / $204B
				jp			nz,L00A3
				
L00A0:
				ld			hl,$2031				; Resets to $2031
L00A3:
				or			h
				jp			z,L00A0					; If was $0000, init as $2013
	
				push		hl
				call		L01DE						; Handle sprite
				pop			hl
				jp			nc,L00B2
	
				ld			($2018),hl			; Store sprite pointer 0
L00B2:
				ld			de,$000D				; Sprite increment
				add			hl,de
				pop			af
				dec			a
				jp			nz,L0099				; Loop back
	
				ld			hl,($2018)			; Sprite pointer 0
				call		L030C
	
				ld			hl,($201A)			; Sprite pointer 1
				
				ld			a,$03						; Loop counter
L00C6:
				push		af
				ld			a,l
				cp			$7F							; Cycloes $2058 / $2065 / $2072
				jp			nz,L00D0
L00CD:
				ld			hl,$2058				; Reset to $2058
L00D0:
				or			h
				jp			z,L00CD					; If was $0000, init as $2058
	
				push		hl
				call		L01DE						; Handle sprite
				pop			hl
				jp			nc,L00DF
	
				ld			($201A),hl			; Store sprite pointer 1
L00DF:
				ld			de,$000D				; Sprite increment
				add			hl,de
				pop			af
				dec			a
				jp			nz,L00C6				; Loop back
	
				xor			a
				ld			($2030),a				; Clear sprite shift
	
				ld			hl,($2016)			; Pointer?
				ld			a,$04						; Loop counter
L00F1:
				push		af
				ld			a,l
				cp			$5F							; Cycles $20E7 / $2105 / $2123 / $2140
				jp			nz,L00FB
	
L00F8:
				ld			hl,$20E7				; Reset to $20E7
L00FB:
				or			h
				jp			z,L00F8					; If was $0000, init to $20E7

				push		hl
				call		L0250						; Handle torpedo
				pop			hl
				jp			nc,L010A

				ld			($2016),hl			; Update pointer
L010A:
				ld			de,$001E				; Torp increment
				add			hl,de
				pop			af
				dec			a
				jp			nz,L00F1				; Loop back

				call		L0331						; Update sprites
				jp			L0069						; End of interrupt routine


L0119:
				ld			hl,($201A)			; Ship 1 pointer
				call		L030C

				ld			hl,($201A)			; Ship 1 pointer
				call		L013A

				ld			hl,($2018)			; Ship 0 pointer
				call		L013A
				
				jp			L0069						; End of interrupt routine
				

				;; Called from rst $10
				;; Handle $2014 handle
L012E:
				ld			hl,($2014)
				ld			a,(hl)
				and			a
				ret			p								; D7 clear = inactive

				call		L0165						; Update sprite
				jp			L0192						; Draw sprite


				;; Handle $2018 / $201a entries
L013A:
				ld			a,(hl)
				and			a
				ret			p								; D7 clear = inactive

				and			$40							; Check bit 6
				jp			nz,L0145				; D6 set = clear
				ld			(hl),$00				; Clear entry
				ret

L0145:
				ld			a,(hl)
				or			$20							; Set bit 5 
				ld			(hl),a
				push		af
				call		L0165						; Update sprite
				;; hl = screen loc, c=shift on return

				pop			af
				and			$10							; Check bit 4
				jp			z,L0192					; Draw sprite

				ld			a,c
				add			a,l
				ld			l,a
				push		hl
				ld			hl,$2030
				ld			a,(hl)
				cpl
				and			$07
				ld			(hl),a
				pop			hl
				out			($04),a					; Update shift count
				jp			L01B8

				;; Update/redraw sprite
L0165:
				inc			hl
				inc			hl
				ld			e,(hl)					; LSB of loc + shift
				inc			hl
				inc			hl
				inc			hl
				ld			d,(hl)					; MSB of loc
				inc			hl
				inc			hl
				call		L0A00						; de >> 3, e&3 -> c
				
				ld			a,c							; (shift)
				ld			($2030),a
				out			($04),a					; Shifter count
				push		de							; Push screen loc
				ld			e,(hl)					; Get spite data loc
				inc			hl
				ld			d,(hl)
				inc			hl
				ex			de,hl						; rom loc -> hl
				ld			c,(hl)					; Read sprite size
				inc			hl
				ld			b,(hl)
				inc			hl
				ex			(sp),hl					; hl = screen loc
				ex			de,hl						; hl Back to ram table
				ld			(hl),e
				inc			hl
				ld			(hl),d
				inc			hl
				ld			(hl),c					; Width
				inc			(hl)						; +1 wide for shifting?
				inc			hl							
				ld			(hl),b					; Height
				inc			hl
				ld			($201C),hl			; Store next
				
				ex			de,hl						; hl = screen loc
				pop			de							; de = sprite data in ROM
				ret

				
				;; Sprite draw, normal
L0192:
				push		bc							; bc = bytes wide, pix high
				push		hl							; hl = screen loc
L0194:
				ld			a,(de)					; Sprite byte
				inc			de
				out			($03),a					; MB12421 data write
				in			a,($03)					; MB12421 data read
				ld			(hl),a					; Write to RAM
				inc			hl
				dec			c
				jp			nz,L0194				; Loop for width
				
				xor			a
				out			($03),a					; MB12421 data write
				in			a,($03)					; MB12421 data read
				ld			(hl),a					; Final write
				ld			bc,$0020				; Row increment
				pop			hl
				add			hl,bc						; Next row
				pop			bc
				ld			a,l
				and			$E0
				jp			nz,L0192				; Not end of screen
				ld			a,h
				rra
				jp			c,L0192					; Not end of screen
				ret

				;; Sprite draw, flipped
L01B8:
				push		bc
				push		hl
L01BA:
				ld			a,(de)
				inc			de
				out			($03),a					; Shifter input
				in			a,($00)					; Shifter output
				ld			(hl),a					; Write to screen
				dec			hl
				dec			c
				jp			nz,L01BA				; Loop for row
	
				xor			a
				out			($03),a					; Shifter input 
				in			a,($00)					; Shifter output
				ld			(hl),a					; Write to screen
				ld			bc,$0020				; Next line
				pop			hl
				add			hl,bc
				pop			bc
				ld			a,l
				and			$E0
				jp			nz,L01B8				; Not end of screen
	
				ld			a,h
				rra
				jp			c,L01B8					; Not end of screen
				ret

			
				;; 
L01DE:
				ld			a,(hl)
				and			a
				ret			p								; High bit clear = inactive
	
				push		hl
				inc			hl							; hl now delta X
				and			$07							; Mask low 3 bits 
				jp			nz,L01ED				; (is a ship)

				;; This is a missle?
				inc			hl
				inc			hl
				jp			L0237
	
L01ED:
				ld			a,(hl)					; Delta X
				ld			de,$215F				; Table for +
				and			a
				jp			p,L01F8
	
				ld			de,$2181				; Table for -
L01F8:
				ld			b,a							; b = delta x
				inc			hl							; (hl) = X
				add			a,(hl)					; a = x + dx
				ld			(hl),a					; store x
				ld			a,b							; a = delta X
				and			a
				ld			a,(hl)					; a = X
				jp			p,L0210					; (left to right)
	
				cp			$01
				jp			nc,L0216
	
L0207:
				ex			(sp),hl
				ld			a,(hl)
				and			$BF							; Clear bit 5 (Ship done?)
				ld			(hl),a
				ex			(sp),hl
				jp			L0216
	
L0210:
				inc			hl
				cp			(hl)						; End X
				dec			hl
				jp			nc,L0207
				
L0216:
				ld			a,(hl)
				rrca
				rrca
				rrca
				and			$1F							; High 5 bits of (hL)
				add			a,e
				ld			e,a
				ex			(sp),hl
				ld			a,(hl)
				ex			(sp),hl
				and			$07
				ld			b,a
				inc			hl
				ld			a,(hl)
				cpl
				inc			a
				rrca
				rrca
				rrca
				and			$07
				add			a,$03
				ex			de,hl
				
L0230:
				ld			(hl),b
				inc			hl
				dec			a
				jp			nz,L0230
				
				ex			de,hl

				;; Handle missiles?
L0237:
				ld			de,$202F				; Ship launch dir?
				ld			a,(de)
				cpl											; Invert it
				ld			(de),a
				jp			nz,L0247
				
				inc			hl
				ld			a,(hl)					; Delta X
				inc			hl
				add			a,(hl)					; X Pos
				ld			(hl),a					; X Pos
				inc			hl
				cp			(hl)						; End X?
L0247:
				pop  hl
				scf
				ret  nz
				
				ld			a,(hl)					; Flags
				and			$BF							; Clear bit 5
				ld			(hl),a					; Flags
				scf
				ret

				
				;; Handle torpedo
L0250:
				ld			a,(hl)
				and			a
				ret			p								; D7 clear = inactive
				
				push		hl
				inc			hl
				inc			hl
				ld			c,(hl)					; +2
				inc			hl
				inc			hl
				ld			a,(hl)					; +4 dx?
				inc			hl
				ld			b,(hl)					; +5 y?
				add			a,b
				ld			(hl),a					; +5
				ld			a,b
				cp			$C0
				jp			nc,L0309				; Bigger
				
				cp			$30
				jp			nc,L0275
				
				ld			a,($2024)				; Explosion timer?
				and			a
				jp			z,L0275
				
				inc			a
				inc			a
				ld			($2024),a				; Explosion timer?
				
L0275:
				ld			a,(hl)					; +5
				inc			hl
				cp			(hl)						; +6
				jp			nc,L029C
				
				ld			a,$C0
				add			a,(hl)					; +6
				ld			(hl),a					; +6
				dec			hl
				dec			hl
				inc			(hl)						; +4
				inc			(hl)						; +4
				ld			a,(hl)					; +4
				inc			hl
				inc			hl
				inc			hl
				jp			z,L0296					; +7
				
				ld			(hl),SHOT1&$ff	; Change missile to SHOT1
				cp			$FC
				jp			z,L029C
				
				ld			(hl),SHOT2&$ff	; Change missile to SHOT2
				jp			L029C
				
L0296:
				ex			(sp),hl
				ld			a,(hl)					; Flags 
				and			$BF							; Clear bit 5 
				ld			(hl),a
				ex			(sp),hl
				
L029C:
				ld			de,$2030				; Sprite shift
				ld			a,(de)
				and			a
				jp			nz,L0309				; Shifted
				
				inc			a
				ld			(de),a					; Sprite shift
				ld			a,b							; What is b?
				and			$10
				jp			z,L0309
				
				ld			de,$0007				; ?? Increment
				add			hl,de
				ld			a,(hl)
				and			a
				jp			nz,L02C3
				
				add			hl,de
				ld			a,b
				add			a,e
				ld			b,a
				and			$10
				jp			z,L0309
				
				ld			a,(hl)
				and			a
				jp			z,L0309
				
L02C3:
				ex			(sp),hl
				ld			a,(hl)					; Flags
				and			$BF							; Clear bit 5
				ld			(hl),a					; Flags
				ex			(sp),hl
				ld			a,b
				sub			$40
				ld			b,a
				jp			c,L02E0
				
				ld			hl,$21A1				; ??
L02D3:
				inc			hl
				inc			hl
				ld			a,(hl)
				and			a
				jp			nz,L02D3
				
				ld			(hl),b
				inc			hl
				ld			(hl),c
				jp			L0309
				
L02E0:
				ld			hl,$21BE				; ??
L02E3:
				inc			hl
				inc			hl
				inc			hl
				ld			a,(hl)
				and			a
				jp			nz,L02E3
				
				ld			a,b
				add			a,$20
				ld			de,$2160
				jp			m,L02F7
				
				ld			de,$2182
L02F7:
				ld			a,c
				rrca
				rrca
				rrca
				and			$1F
				add			a,e
				ld			e,a
				ld			a,(de)
				and			a
				jp			z,L0309
				ld			(hl),a
				inc			hl
				ld			(hl),c
				inc			hl
				ld			(hl),b
L0309:
				scf
				pop			hl
				ret

				
				;; Erase ship from hl
L030C:
				ld			a,(hl)					; Sprite flags
				and			a
				ret			p								; D7 clear = inactive
	
				and			$20
				ret			z								; D5 clear = not sunk
	
				call		L035B						; Get de, bc from bytes 9-d
	
				ex			de,hl						; hl = read de
				ld			b,c
				
L0317:
				xor			a
				push		hl							; Store loc

				
				;; Clear c bytes at hl
L0319:
				ld			(hl),a
				inc			hl
				dec			c
				jp			nz,L0319
	
				ld			de,$0020				; Line increment
				pop			hl							; Get loc
				add			hl,de						; Next line
				ld			c,b
				ld			a,l
				and			$E0
				jp			nz,L0317				; Loop if not end of screen
				
				ld			a,h
				rra
				jp			c,L0317					; Loop if not end of screen
				
				ret

				
				;; Update sprites
L0331:
				ld			hl,($2014)
				ld			b,$0A						; Loop counter = 10 sprites
				ld			a,l
				or			h
				jp			nz,L033E
				
				ld			hl,$2072				; If 0 reset to $2072
L033E:
				ld			de,$000D				; Sprite increment
L0341:
				add			hl,de
				dec			b
				ret			z								; End of loop
	
				ld			a,l
				cp			$E7							; hl == $20E7?
				jp			nz,L034D
	
				ld			hl,$207F				; Reset to $207F
L034D:
				ld			a,(hl)					; X flags
				and			a
				jp			p,L0341					; D7 clear = not active
	
				ld			($2014),hl
				inc			hl
				ld			a,(hl)					; Delta X
				inc			hl
				add			a,(hl)					; Add to X
				ld			(hl),a					; Store X
				ret

				
				;; Load de, bc from ship data
L035B:
				ld			de,$0009
				add			hl,de
				ld			e,(hl)
				inc			hl
				ld			d,(hl)
				inc			hl
				ld			c,(hl)
				inc			hl
				ld			b,(hl)
				inc			hl
				ret

				
				;; Called from ISR
L0368:
				ld			a,($2020)
				and			a
				ret			nz
				
				ld			b,a							; No ret, so a=0, b=0
				ld			hl,$2003				; Counter address
				dec			(hl)						; Decrement counter
				jp			nz,L038E

				;; $2003 Counter zero
				ld			(hl),$1E				; Reset counter
				ld			hl,GTIME				; Game timer
				ld			a,(hl)				
				and			a
				jp			z,L0388					; Game over
			
				add			a,$99
				daa
				ld			(hl),a					; Decrement game timer
				jp			nz,L0388
				
				ld			b,$01						; set d7 (eventually) = Game over
L0388:
				ld			hl,$2010
				call		L03AE						; Handle $2010 timer d6

				;; Counter non-zero
L038E:
				ld			hl,$2011 			
				call		L03AE						; Handle $2011 timer d5
				ld			hl,$2021
				call		L03AE						; Handle $2021 timer d4
				inc			hl
				call		L03AE						; Handle $2022 timer d3
				inc			hl
				call		L03AE						; Handle $2023 timer d2
				inc			hl
				call		L03AE 					; Handle $2024 timer d1
				inc			hl
				call		L03AE						; Handle $2025 timer d0
				ld			($2020),a
				ret

				
				;; Decrement timer, set bit if 0
L03AE:
				ld			a,(hl)
				and			a
				jp			z,L03B8
				
				dec			(hl)
				jp			nz,L03B8				; Carry clear since (hl) != 0
				
				scf											; Set carry
L03B8:
				ld			a,b			
				rla											; Shift 0 into b unless carry set above
				ld			b,a
				ret

				
				;; Called from both interrupt routines
				;; Updates and redraw "wave"
L03BC:
				ld			bc,$2027				; Wave state
				ld			a,(bc)
				add			a,$0A						; $00 -> $0A -> $14 -> $1E = $00
				cp			$1E
				jp			nz,L03C8
				
				xor			a								; A=0
L03C8:
				ld			(bc),a					; Store state
				inc			bc							; $2028
				ld			e,a
				ld			d,$00
				ld			hl,WATER0				; Start of waves
				add			hl,de
				ex			de,hl						; de = wave table entry
				
				ld			a,(bc)					; Get state
				inc			a
				and			$1F							; Loops $00 to $1F
				ld			(bc),a					; Save state

				;; Screen location
				ld			hl,$27E0
				add			a,l
				ld			l,a
				ld			bc,$0020				; Row increment
L03DF:
				ld			a,(de)					; Get byte
				inc			de
				ld			(hl),a					; Write byte
				add			hl,bc						; Next row
				ld			a,l
				and			$E0
				cp			$60							; Only 4 rows used?
				jp			nz,L03DF				; Loop
				
				ret

				;; Test mode
L03EC:
				ld			hl,L0000				; Start address
				ld			de,$0000				; Offset 0
				ld			c,$02						; Until $0200
L03F4:
				xor  a									; Clear checksum
L03F5:
				add			a,(hl)
				inc			hl
				ld			b,a
				ld			a,c
				cp			h
				ld			a,b
				jp			nz,L03F5				; Loop
	
				push		hl							; Push address
				ld			hl,L0429				; Checksum table
				add			hl,de
				cp			(hl)						; Compare checksum
				ld			a,$40						; (Space)
				jp			z,L040E					; Checksum good!
				
				ld			hl,L0432				; Bad checksum table
				add			hl,de
				ld			a,(hl)
				
L040E:
				ld			hl,TXTBUF				; Text buffer
				add			hl,de
				ld			(hl),a					; Store char
	
				pop			hl							; Get address back
				inc			de							; Next rom
				inc			c								; $2 more pages
				inc			c
				ld			a,$12
				cp			c
				jp			nz,L03F4				; Loop if not done
	
				ld			hl,TXTBUF				; Text buffer
				ld			de,$3008				; Location
				ld			a,$08						; Length
				call		L0B30						; Draw string hl @ de, length a
				halt										; Stop!
				

				;; $200 block checksums
L0429:
				.db			$8D, $79, $00, $1F, $58, $6D, $EA, $C5	; Checksums
	
				.db			$2A							; Patch byte for $400 checksum

				;; Error locations
L0432:
				.db			$48, $48, $47, $47, $46, $46, $45, $45	; HHGGFFEE

				;; Initial jump
L043A:
				call		 L08A2					; (End of game routine)
				in			a,($02)					; IN2
				and			$E0							; Test mode bits
				cp			$E0
				call		z,L03EC					; Go to test mode

				;; Clear $2002-$200a
				ld			hl,GTIME
				ld			a,$09
				ld			b,$00
L044D:
				ld			(hl),b
				inc			hl
				dec			a
				jp			nz,L044D
	
				ld			hl,L0929				; Attract mode loop
				ld			($2000),hl
				
L0459:
				ei											; Enable interrupts
				ld			hl,L0459				; Return address
				push		hl
				ld			hl,($2000)
				ld			a,(hl)					; Get command
				and			a
				jp			nz,L047D				; Non-zero command

				;; a=(($2000)) == 0
				;; Command 0
				call		L06A4
				call		L04CE
				call		L04BF
				ld			a,(GTIME)				; Game timer
				and			a
				ret			z								; Skip rest if game over
	
				call		L074C
				call		L08B8
				jp			L048C

				
				;; Do command from jump table
				;; a=(($2000)) != 0
L047D:
				inc			hl
				ex			de,hl						; ($2000+1) --> de
				ld			hl,TBLJMP-2			; Jump table
				rlca										; a = ($2000)<<1
				ld			c,a							; c = ($2000)<<1
				ld			b,$00
				add			hl,bc						; hl = L09e8 + ($2000)<<1
				ld			a,(hl)
				inc			hl
				ld			h,(hl)
				ld			l,a
				jp			(hl)
				
	
L048C:
				ld			a,($2003)
				cp			$1D
				ret			m								; Only update once per loop
				
				ld			bc,GTIME				; Game time
				ld			de,TXTBUF				; Text buffer
				call		L0A82						; BCD to buffer
				ex			 de,hl
				call		L0A7A
				
				inc			hl
				ld			(hl),$2C				; Space
				inc			hl
				ex			de,hl
				ld			bc,PSCORE				; Player score
				
				call		L0A82						; BCD to buffer
				ex			de,hl
				call		L0A7A
				inc			hl
				ld			(hl),$30				; Postpend zero
				inc			hl
				ld			(hl),$30				; Postpend zero
				
				ld			hl,TXTBUF				; Text buffer
				ld			de,$3E2F				; Screen location
				ld			a,$06						; Length
				jp			L0B30						; Draw string hl @ de, length a

								
L04BF:
				ld			hl,$202A				; Duplicate game time
				ld			a,(hl)
				and			a
				ret			z								; Already zero
				
				ld			(hl),$00				; Clear
				ld			hl,L09A6				; Game over mode
				ld			($2000),hl			; Write mode
				ret

				;; Choose subroutine based on $2020 bits
L04CE:
				ld			hl,$2020
				ld			a,(hl)
				and			a
				ret			z								; Nothing to do
				ld			(hl),$00				; Clear all bits
				
				rra
				call		c,L0601					; Bit 0 set = Clear explosion lights
				
				rra
				call		c,L060E					; Bit 1 set = Clear explosion on screen
				
				rra
				call		c,L04F7					; Bit 2 set = Trigger bit 2 sound
				
				rra
				call		c,L0634					; Bit 3 set = Launch new ship
				
				rra
				call		c,L05E9					; Bit 4 set = Reload torpedos
				
				rra
				call		c,L0573					; Bit 5 set = Increment $2000 address
				
				rra
				call		c,L056C					; Bit 6 set = Initialize $2000 address
				
				rra
				call		c,L0511					; Bit 7 set = Game time over
				ret

				
				;; Bit 2 set on $2020
				;; Trigger bit 2 sound and set timers
L04F7:
				push		af
				ld			hl,$2026
				ld			a,(hl)
				and			a
				jp			z,L050F					; Do nothing
	
				dec			(hl)
				ld			a,$04						; Sound bit 2
				out			($05),a					; Audio outputs
				ld			a,$19
				ld			($2023),a				; Set timer
				ld			a,$0F
				ld			($2025),a				; Set timer
L050F:
				pop  af
				ret

				
				;; Bit 7 set on $2020
L0511:
				ld			hl,$202E
				ld			a,(hl)
				and			a
				jp			nz,L053D				; Jump if already extended time
	
				ld			(hl),$01				; Only 1 extend
				ld			a,(IN1)					; Last IN1
				rrca
				and			$70							; Base score for extended time (00 = none)
				jp			z,L053D					; Jump if no extended time
	
				add			a,$09						; $20 dip = $19(00) score
				ld			hl,PSCORE				; Player score
				cp			(hl)
				jp			nc,L053D				; Jump if score lower than metric
	
				ld			a,$20						; 20 extra seconds
				ld			(GTIME),a				; Set game time
				ld			hl,LTEXT				; EXTENDED_TIME
				ld			de,$3C03				; Location
				ld			a,$0C						; Length
				jp			L0B30						; Draw string hl @ de, length a
	
L053D:
				ld			hl,TORPS-TINC		; (Offset) Torp base
				ld			bc,TINC					; Torp increment
L0543:
				add			hl,bc
				ld			a,l
				cp			$5F							; LSB past end of torps
				jp			z,L055C					; Done with torps
	
				ld			a,(hl)					; Load flags
				and			a
				jp			p,L0543					; Loop if not active
	
				xor			a
				ld			($2021),a
				ld			($202D),a				; Torpedo status
				ld			a,$01
				ld			(GTIME),a				; Why are we adding a second?
				ret

				;; Check if new high score
L055C:
				ld			hl,L0929
				ld			($2000),hl			; Next command
				ld			a,(PSCORE)			; Player score
				ld			hl,HSCORE				; High score
				cp			(hl)
				ret			c
				ld			(hl),a					; Write new score
				ret

				
				;; Bit 6 set on $2020
				;; Initialize $2000 address
L056C:
				ld			hl,L0963				; End of game
				ld			($2000),hl
				ret

				
				;; Bit 5 set on $2020
				;; Increment $2000 address
L0573:
				ld			hl,($2000)			; After 2011 timer?
				inc			hl
				ld			($2000),hl
				ret

				
				;; Handle change in fire button
HFIRE:
				ret			z								; Not pressed
				
				ld			a,(GTIME)				; Game timer
				and			a	
				ret			z								; Not in game mode
	
				ld			a,($2021)				; Timer between torps
				and			a
				ret			nz							; Missile already active? 
	
				ld			hl,$202D				; Torpedo status
				ld			a,(hl)
				and			$1F
				ret			z								; Reloading...
	
				ld			a,(hl)					; Torpedo status
				and			$0F							; Mask torp bits
				rra
				ld			b,$20						; Bit 5 = Reload
				and			a
				jp			z,L0599
	
				ld			b,$10						; Bit 4 = Ready
L0599:
				or			b
				ld			(hl),a
				out			($02),a					; Torpedo display
				ld			hl,$2021				; Timer between torps
				ld			(hl),$08				; Short timer between shots
				and			$10
				jp			nz,L05A9	
	
				ld			(hl),$3C				; Long timer to reload
L05A9:
				ld			a,$02						; Sound bit 1 
				out			($05),a					; Audio outputs
				ld			a,$0F
				ld			($2025),a				; Set timer

				;; Find empty slot
				ld			hl,TORPS-TINC 	; (Offset) Torp base
				ld			de,TINC 				; Torpedo increment
L05B8:
				add			hl,de
				ld			a,(hl)
				and			a
				jp			m,L05B8					; D7 high = used, try again

				;; New torpedo
				ld			de,$0008
				add			hl,de						; Move ahead in sprite table
				ld			(hl),SHOT0>>8		; SHOT0 MSB
				dec			 hl
				ld			(hl),SHOT0&$FF	; SHOT0 LSB
				dec			hl
				ld			(hl),$9C				; ??
				dec			hl
				ld			(hl),$E0				; Y pos
				dec			hl
				ld			(hl),$FA				; Delta y
				dec			hl
				dec			hl

				;; Caculate shot X location
				ld			de,TGREY				; Grey code table?
				ex			de,hl
				ld			a,(IN0)					; Last IN0
				and			$1F							; Mask periscope bits
				ld			c,a
				ld			b,$00
				add			hl,bc
				ld			a,(hl)					; Location from grey code
				ex			de,hl
				
				ld			(hl),a					; X Pos
				dec			hl
				ld			(hl),$00				; Delta X
				dec			hl
				ld			(hl),$C0				; Set active
				ret

				
				;; Bit 4 set on $2020
				;; Reset torpedo status after reload
L05E9:
				push		af
				ld			hl,$202D				; Torpedo status
				ld			a,(hl)
				and			$10							; Check ready
				jp			nz,L05FF
	
				ld			a,$1F						; Reset torpedo status
				out			($02),a					; Torpedo lamps
				ld			(hl),a
				ld			a,$08						; Sound bit 3
				out			($05),a					; Audio outputs
				call		L07EA						; Redraw mines
				
L05FF:
				pop			af
				ret

				;; Bit 0 set on $2020
				;; Clear explosions
L0601:
				push		af
				xor			a								; Clear sounds
				out			($05),a					; Audio outputs
				out			($01),a					; Explosion lamp
				ld			a,($202D)				; Torpedo status
				out			($02),a					; Periscope lamp
				pop  af
				ret

				
				;; Bit 1 set on $2020
				;; Clear sprites?
L060E:
				push		af
				ld			hl,$21F0
L0612:
				ld			a,(hl)
				and			a
				jp			z,L0632					; Already cleared

				;; (hl) -> de, clear (hl)
				ld			(hl),$00
				inc			hl
				ld			d,a
				ld			e,(hl)
				ld			(hl),$00
				inc			hl
				
				cp			$2C
				ld			bc,$0A03				; 10 x 3 byte area  (after ship hit)
				jp			c,L062A
				
				ld			bc,$2005				; 32 x 5 byte area  (after mine hit)
L062A:
				ex			de,hl
				call		L0A3F						; Clear area at hl
				ex			de,hl
				jp			L0612						; Loop
L0632:
				pop			af
				ret

				;; Bit 3 set on $2020
				;; Launch new ship
L0634:
				push		af
				ld			a,($2003)
				and			$0F							; Mask low 4 bits
				or			$50							; Set bits 6,4
				ld			($2022),a				; Set counter
	
				ld			bc,$2029				; Ship type loc
				ld			a,(bc)					; Get ship index
				inc			a								; Increment
				cp			$07							; Max = 6
				jp			nz,L064A
				
				xor			a								; Set to 0
L064A:
				ld			(bc),a					; Store ship index
	
				ld			hl,L0FDE				; Ship type table
				add			a,l
				ld			l,a
				ld			a,(hl)					; Get ship type
				ld			b,a							; Stash in b
				cp			$06							; Is small / fast?
				jp			nz,L066B				; No = jump
	
				ld			a,$04						; Sound bit 2
				out			($05),a					; Audio outputs
				ld			a,$19
				ld			($2023),a				; Set timer
				ld			a,$02
				ld			($2026),a				; Set timer
				ld			a,$0F
				ld			($2025),a				; Set timer
				ld			a,b							; Ship type
	
				;; hl = $202c + $0d * a 
L066B:
				ld			hl,$202C
				ld			de,$000D				; Sprite increment
L0671:
				add			hl,de
				dec			a
				jp			nz,L0671
	
				ld			a,b
				ex			de,hl
	
				ld			hl,$201E				; Current ship move index
				ld			a,(hl)					; Read ship move index
				inc			(hl)						; Increment ship move index
				ld			hl,L0F7E				; Even ship move table?
				rra
				jp			nc,L068B
	
				ld			hl,L0FAE				; Odd ship move table?
				ld			a,b
				or			$10							; Set direction bit
				ld			b,a
	
L068B:
				ld			a,b

				;; Index into ship type table
				dec  a									; a = 0-5 / 10-15
				rlca
				rlca
				rlca
				and			$38							; Clear low bits
				add			a,l
				ld			l,a

				;; Copy ship table data to sprite block
				ld   c,$08
L0696:
				ld			a,(hl)
				inc			hl
				ld			(de),a
				dec			de
				dec			c
				jp			nz,L0696
	
				ld			a,b
				or			$C0							; B7 = moving, B6 = don't clear, B5 = ??
				ld			(de),a					; Store ship type?
				pop			af
				ret

				;; Called when (($2000)) == 0
L06A4:
				ld			hl,$21C1				; Start of sprite index list
L06A7:
				ld			a,(hl)
				and			a
				ret			z								; Done if this sprite inactive
	
				ld			(hl),$00				; Clear active flag
				inc			hl
				ld			d,(hl)					; Get index into sprite table
				push		hl

				;; hl = $2024 + $d * a
				ld			hl,SHIPA0-SINC	; No 0 element
				ld			bc,$000D				; Sprite entry length
L06B5:
				add			hl,bc
				dec			a
				jp			nz,L06B5
	
				ld			bc,$0008				; Middle of sprite table and work back
				add			hl,bc

				;; Change sprite to sinking ship
				ld			(hl),SINK>>8		; SINK MSB
				dec			hl
				ld			(hl),SINK&$FF		; SINK LSB
				dec			hl
				dec			hl							; hl = Y pos
				dec			hl
				ld			(hl),$01				; Delta y (?)
				dec			hl							; hl = Y flags
				dec			hl
				ld			(hl),d					; X position
				dec			hl
				ld			(hl),$00				; Delta x (?)
				dec			hl
				ld			b,(hl)					; Get flags + ship type
				ld			(hl),$E0				; Flags
	
				ld			a,(GTIME)				; Game time
				and			a
				jp			nz,L06DB				; Add score if time is left
				pop			hl
				ret


				;; Score sunk ship
L06DB:
				ld   a,b

				;; Draw sunk ship score
				ld			bc,TSCORE-1			; Ship hit score table
				and			$07
				add			a,c
				ld			c,a							; bc = index into table	
	
				ld			de,TXTBUF				; Text buffer
				call		L0A82						; BCD to buffer
				ld			a,$30
				ld			(de),a					; Append 0
				inc			de
				ld			(de),a					; Append 0
				
				ld			a,(bc)
				ld			hl,PSCORE				; Player score
				add			a,(hl)					; Add a
				daa
				ld			(hl),a					; Store
				pop			hl
				ld			c,(hl)					; Get bc from table
				inc			hl
				ld			b,(hl)
				inc			hl
				
				push		hl
				ld			a,b
				add			a,$20
				ld			hl,L09C2				; Explosion lamp 0-7 table
				jp			c,L0707
				
				ld			hl,L09BA				; Explosion lamp 8-F table
L0707:
				;; Use 3 MSBs of c to index into table
				ld			a,c
				rlca
				rlca
				rlca
				and			$07
				add			a,l
				ld			l,a
				ld			a,(hl)
				out			($01),a					; Explosion lamp
				ld			a,$01						; Sound bit 0
				out			($05),a					; Audio write
				ld			a,$1E
				ld			($2025),a				; Set audio timer

				;; Calculate score draw location
				ld			a,b
				ld			d,$24
				add			a,$20
				jp			m,L0725
				ld			d,$28
L0725:
				ld			a,c
				rrca
				rrca
				rrca
				and			$1F
				jp			z,L072F
				dec			a
L072F:
				cp			$1E
				jp			nz,L0735
				dec			a
L0735:
				or			$A0							; Set bits 7,5 
				ld			e,a
				
				call		L07DB						; Find first de?
				
				ld			a,$2D
				ld			($2024),a				; Set timer (for showing score)
				ld			hl,TXTBUF1			; Buffer?
				ld			a,$03						; Length
				call		L0B30						; Draw string hl @ de, length a
				
				pop			hl
				jp			L06A7
	
L074C:
				ld			hl,$21A3				; ??
L074F:
				ld			a,(hl)
				and			a
				ret			z
	
				inc			hl
				add			a,$10
				rlca
				rlca
				rlca
				and			$07
				ld			de,$2067				; ??
				ld			bc,$000D				; Sprite increment
				ex			de,hl
L0761:
				add			hl,bc
				add			hl,bc
				dec			a
				jp			nz,L0761
	
				ld			a,(de)
				sub			$08
				sub			(hl)
				cp			$EC
				jp			nc,L0771
	
				add			hl,bc
L0771:
				dec			hl
				dec			hl
				ld			(hl),$00
				ex			de,hl
				dec			hl
				ld			a,(hl)
				add			a,$30
				and			$F0
				ld			d,a
				ld			(hl),$00
				inc			hl
				ld			e,(hl)
				inc			hl
				push		hl
				call		L0A00
	
				ld			a,e
				and			$1F
				jp			z,L0796
	
				dec			a
				jp			z,L0796
	
L0790:
				dec			a
				cp			$1C
				jp			p,L0790
				
L0796:
				ld			e,a
				call		L07DB						; de to first empty slot
				
				ld			b,d
				inc			b
				inc			b
				ld			c,e
				inc			c
				push		bc

				;; 3 rows up for middle char?
				ld			a,e
				add			a,$60
				ld			e,a
				push		de
				
				ld			b,d
				inc			c
				push		bc
				
				ld			a,$1E
				ld			($2025),a				; Set timer (audio)
				ld			a,$0F
				ld			($2024),a				; Set timer (show explosion)
				ld			a,$10						; Sound bit 4
				out			($05),a					; Sound write
				
				ld			a,e							; No idea what e is here, but used as PRNG
				and			$02							; Mask bit (a=0 or 28)
				ld			hl,TEMINE
				add			a,l
				ld			l,a							; hl = ZAP or WAM

				;; Get address from table -> hl
				ld			e,(hl)
				inc			hl
				ld			d,(hl)
				ex			de,hl						; hl = Table entry
				
				;; "Middle" letter or ZAP/WAM
				pop			de
				ld			a,(hl)
				inc			hl
				call		L0B30					; Draw string hl @ de, length a

				;; Rest of ZAP/WAM
				pop			de
				ld			a,(hl)
				inc			hl
				call		L0B30					; Draw string hl @ de, length a

				;; Bottom of mine explosion
				pop			de
				ld			hl,MINEEXP
				ld			a,$03
				call		L0B30					; Draw string hl @ de, length a
				
				pop			hl
				jp			L074F


				;; Write de to first empty slot
L07DB:
				ld			hl,$21F0
L07DE:
				ld			a,(hl)
				inc			hl
				or			(hl)
				inc			hl
				jp			nz,L07DE
				
				dec			hl
				ld			(hl),e
				dec			hl
				ld			(hl),d
				ret

				
				;; Draw mines after reload
L07EA:
				ld			a,(PSCORE)			; Player score
				cp			$40			
				jp			c,L07F4
				ld			a,$39						; Min of score or $39
				
L07F4:
				ld			($202C),a				; Mine counter
	
				ld			hl,$207F				; 1st mine sprite
				ld			de,$5050				; Initial Mine X,Y
	
L07FD:
				ld			a,(hl)
				and			a
				jp			m,L0835					; Mine needs to be erased

				;; Launch mine?
L0802:
				ld			bc,$0008
				add			hl,bc						; Advance in sprite table
				ld			(hl),MINE>>8		; Mine MSB (+8)
				dec			hl
				ld			(hl),MINE&$FF 	; Mine LSB (+7)
				dec			hl
				dec			hl
				ld			(hl),e					; Y Pos (+5)
				dec			hl
				ld			(hl),b					; Delta Y (+4)
				dec			hl
				dec			hl
				ld			(hl),d					; X Pos (+2)
				dec			hl
				ld			(hl),$01				; Delta X (+1)
				dec			hl
				ld			(hl),$80				; Flags
				
				ld			a,d
				add			a,$51
				ld			d,a
				rra
				jp			c,L082E
	
				ld			a,($202C)				; Mine counter
				sub			$10
				ret			m								; Don't add more mines
	
				ld			($202C),a				; Store count
				ld			a,e
				add			a,$20
				ld			e,a
	
L082E:
				ld			bc,$000D				; Sprite table increment
				add			hl,bc						; Next mine
				jp			L07FD						; More mines!


				;; Erase mine area before launch
L0835:
				push		hl
				push		de
				inc			hl
				inc			hl
				ld			e,(hl)
				inc			hl
				inc			hl
				inc			hl
				ld			d,(hl)
				call		L0A00
				ex			de,hl
				ld			bc,$1002				; 16 x 2 byte area
				call		L0A3F						; Clear area at hl
				pop			de
				pop			hl
				jp			L0802

				
				;; Handle high score erase
HERASE:	
				ret			z
				xor			a
				ld			(HSCORE),a			; Clear high score
				ld			a,($2010)
				and			a
				ret			z
				
				ld			hl,TXTBUF				; Text buffer
				push		hl

				;; Write 4x '0' to buffer
				ld			bc,$0430				; b=loop counter, c=data
L085E:
				ld			(hl),c
				inc			hl
				dec			b
				jp			nz,L085E				; Loop
				
				pop			hl
				ld			de,$3E25				; Screen location
				ld			a,$04						; Length = 4
				jp			L0B30						; Draw string hl @ de, length a
				

				;; $09E8 Entry B = Write low 3 bits of $2003 to $2029?
JTBLB:													; $086D
				ex			de,hl						; Sequence back to hl
				ld			($2000),hl			; Store
	
				ld			a,($2003)				; 
				and			$07							; Mask low 3 bits
				cp			$07							; == $07?
				jp			nz,L087C
				
				xor			a								; Clear
L087C:
				ld			($2029),a				; Write
				ret

				;; End of game clears
L0880:
				di
				ex			de,hl						; Stash hl in de
				ld			($2000),hl
				xor			a
				out			($02),a					; Clear periscope lamp
				out			($05),a					; Clear audio latches
				out			($01),a					; Clear explosion lamp
				pop			hl							; (Return address)
				ld			bc,$0000
				ld			de,$0000
				ld			a,$10
				ld			sp,$4010				; Clear $4010 down to $2011
L0898:
				push		bc
				inc			de
				cp			d
				jp			nz,L0898									; Loop
				ld			sp,$2400
				jp			(hl)

				
				;; $09E8 Entry 3 (End game)
JTBL3:	
L08A2:
				pop			hl							; Return address
				ld			($2009),hl			; Stash in ($2009-200a)
				call		L0880						; Does this ever return?
				ld			hl,($2009)			; Get return address back
				push		hl							; Push back to stack
				
				ld			hl,L0F04				; Water
				ld			de,$27E0
				ld			a,$20
				jp			L0B30						; Draw string hl @ de, length a
				
L08B8:
				in			a,($01)					; IN0
				ld			b,a
				in			a,($01)					; IN0
				ld			hl,IN0 					; Last IN0
				ld			de,TBLIN0				; Jump table for IN0
				cp			b								; Inputs stable?
				call		z,L0B05					; Handle inputs

				;; Jump table do nothing "routine"
				;; (and end of this one)
HRET:		
				ret											; (reset)

				
				;; Handle coin
HCOIN:
				ret			z								; No coin
				ld			a,$20						; Sound bit 5
				out			($05),a					; Audio outputs
				ld			a,$0F
				ld			($2025),a				; Set timer

				ld			a,(IN1)					; Last IN1
				ld			b,a
				ld			hl,$2004				; Half credits
				inc			(hl)						; Increment
				and			$04							; DSW2 = coinage
				jp			z,L08E2

				ld			a,(hl)
				rrca
				ret			c								; Only 1 half ccredit

L08E2:
				ld			(hl),$00				; Clear half credit
				inc			hl
				inc			(hl)						; Add credit

				ld			a,b							; Last IN1
				and			$08							; DSW3 = coinage
				jp			z,L08F4

				inc			(hl)						; Add credit
				ld			a,b							; Last IN1
				and			$04							; DSW2 = coinage
				jp			z,L08F4

				inc			(hl)						; Add credit (2C, 3C)

L08F4:	
				ld			a,(hl)					; Get credits
				and			$0F							; Useless
				ld			(hl),a					; Store credits
				
				;; Falls through to start game when credits added
HPUSH:	
				ret			z
				ld			a,(GTIME)				; Game time
				and			a
				ret			nz							; Skip if game active

				ld			hl,CREDIT				; Credits?
				ld			a,(hl)
				and			a
				jp			z,L091A					; No credits, ignore start
				
L0906:
				dec			(hl)
	
				in			a,($01)					; IN1
				rlca
				rlca
				and			$03							; Game time dips
				ld			de,LDTIME				; $0F54 
				add			a,e							; Index into table
				ld			e,a
				ld			a,(de)
				ld			(GTIME),a				; Store time
				ld			($202A),a				; Store time
				ret
	
L091A:
				ld			a,(IN1)					; Last IN1
				and			$0C							; Mask coinage
				cp			$0C							; 2C / 3Credit?
				ret			nz
				
				dec			hl
				ld			a,(hl)					; Half credits
				and			a
				ret			z
				jp			L0906

				
				;; $2000 at reset
				;; Attract mode loop
L0929:
				.db			$04							; Command 4 = String
				.db			$01							; Length
				.dw			LTBLANK					; String src address
				.dw			$3E30						; Screen dst address

				.db			$09							; Commnad 9
				.dw			CREDIT					; ($2005) -> a   (select string)
				.dw			$3833						; Location
				.dw			LTCOIN					; "Insert Coin"
				.dw			LTPUSH					; "Push Button"

				.db			$04							; Command 4 = String
				.db			$1A							; Length 
				.dw			LTHIGH					; String src address
				.dw			$3C02						; Screen dst address
	
				.db			$0A							; Command A = BCD @ loc
				.dw			HSCORE					; bc = 2006 = high score
				.dw			TXTBUF					; Buffer loc
				.dw			$3E25						; Screen loc
	
				.db			$0A							; Command A = BCD @ loc
				.dw			PSCORE					; bc = 202b = score
				.dw			TXTBUF					; Buffer loc
				.dw			$3E35						; Screen loc
	
				.db			$02							; Command 2 = arg to 2010
				.db			$0F							; arg

L094E:	
				.db			$04							; Command 4 = String
				.db			$09							; Length
				.dw			LTOVER					; String src address
				.dw			$2C0B						; Screen dst address
        
				;; Delay timer
				.db			$01							; Command 1 = arg to 2011
				.db			$1E							; arg
				
				.db			$00							; Command 0 = Wait for $2011 timer


				.db			$04							; Command 4 = String
				.db			$09							; Length
				.dw			LTBLANK					; String src address
				.dw			$2C0B						; Screen dst address

				;; Delay timer
				.db			$01							; Command 1 = arg to 2011
				.db			$1E							; arg
				
				.db			$00							; Command 0 = Wait for $2011 timer

				.db			$06							; Command 6 = Set ($2000)
				.dw			L094E						; Next command address
	
L0963:
				.db			$03							; Do end of game sequence
	
				.db			$04							; Command 4 = String
				.db			$08							; Length
				.dw			LTSEA						; String src address (SEA WOLF)
				.dw			$2C0C						; Screen dst address

				.db			$04							; Command 4 = String
				.db			$0A							; Length
				.dw			LTHIGH					; String src address (HIGH SCORE)
				.dw			$3C02						; Screen dst address
	
				.db			$0A							; Command A = BCD @ loc
				.dw			HSCORE					; bc = 2006 = high score
				.dw			TXTBUF					; Buffer loc
				.dw			$3E25						; Screen loc
	
				.db			$09							; Commnad 9
				.dw			CREDIT					; ($2005) -> a   (select string)
				.dw			$3833						; Location
				.dw			LTCOIN					; "Insert Coin"
				.dw			LTPUSH					; "Push Button"

				;; Delay timer
				.db			$01							; Command 1 = arg to 2011
				.db			$5A							; arg
				
				.db			$00							; Command 0 = Wait for $2011 timer

				;; Launch ship in attract
				.db			$08							; Command 8 (Data backwards to loc)
				.db			$09							; Count
				.dw			$2060						; de = $2060
				.dw			SHIP3						; $0DBE = Ship address
				.db			$20							; $20 = ???
				.db			$15							; $15 = Y Pos
				.db			$00							; $00 = Delta y
				.db			$E0							; $E0 = Y flags
				.db			$00							; $00 = X pos
				.db			$01							; $01	= Delta x
				.db			$C4							; $C4	= Flags (Ship 4, active)

				;; Delay timer
				.db			$01							; Command 1 = arg to 2011
				.db			$5A							; arg
				
				.db			$00							; Command 0 = Wait for $2011 timer

				;; Launch missile in attract
				.db			$08							; Command 8 (Data backwards to loc)
				.db			$09							; Count
				.dw			$20EF						; de = $20EF
				.dw			SHOT0						; $0E75 = Shot address
				.db			$9C							; $9C = ???
				.db			$E0							; $E0	= Y Pos
				.db			$FA							; $FA	= Delta y
				.db			$00							; $00	= Y flags
				.db			$A8							; $A8	= X pos
				.db			$00							; $00	= Delta X
				.db			$C0							; $C0	= Flags (Non-ship, active)

				;; Delay timer
				.db			$01							; Command 1 = arg to 2011
				.db			$B4							; arg
				
				.db			$00							; Command 0 = Wait for $2011 timer
	
				.db			$06							; Command 6 = Set ($2000)
				.dw			L0963						; Next command address


				;; Game play control loop
L09A6:
				;; Delay timer
				.db			$01							; Command 1 = arg to 2011
				.db			$0F							; arg

				.db			$00							; Command 0 = Wait for $2011 timer
	
				.db			$03							; Command 3 = End game
       	
				.db			$04							; Command 4 = String
				.db			$09							; Length
				.dw			LTTIME					; String src address (TIME/SCORE)
				.dw			$3C0E						; Screen dst address
	
				.db			$07							; Command 7 = Store a to bc
				.db			$28							; a
				.dw			$2022						; bc

				.db			$07							; Command 7 = Store a to bc
				.db			$0A							; a
				.dw			$2021						; bc

				.db			$0B							; Command B = Write $2029?
				
				.db			$00							; Command 0 = Wait for $2011 timer

				
				;; Explosion lamp tables!
L09BA:
				.db			$48, $44, $42, $41, $88, $84, $82, $81		; 
L09C2:
				.db			$18, $14, $12, $11, $28, $24, $22, $21		; 


				;; Jump table for IN1 changes (8 entries)
TBLIN1:	
				.dw			HCOIN						; 0 = 08C8 = Coin
				.dw			HPUSH						; 1 = 08F8 = Start
				.dw			HRET						; 2 = 08C7 = (ret) Coinage
				.dw			HRET						; 3 = 08C7 = (ret) Coinage
				.dw			HERASE					; 4 = 084D = Erase highs
				.dw			HRET						; 5 = 08C7 = (ret) Extended time
				.dw			HRET						; 6 = 08C7 = (ret) Extended time
				.dw			HRET						; 7 = 08C7 = (ret) Extended time

				;; Jump table for IN0 changes (8 entries)
TBLIN0:	
				.dw			HRET						; 0 = 08C7 = (ret) Turret
				.dw			HRET						; 1 = 08C7 = (ret) Turret
				.dw			HRET						; 2 = 08C7 = (ret) Turret
				.dw			HRET						; 3 = 08C7 = (ret) Turret
				.dw			HRET						; 4 = 08C7 = (ret) Turret
				.dw			HFIRE						; 5 = 057B = Fire button
				.dw			HRET						; 6 = 08C7 = (ret) Time
				.dw			HRET						; 7 = 08C7 = (ret) Time

				;; Jump table for $047F (0 entry not used)
				;; Used for attract mode sequence
TBLJMP:	
				.dw			JTBL1						; 1 = 0B7C = Arg to 2011
				.dw			JTBL2						; 2 = 0B72 = Arg to 2010
				.dw			JTBL3						; 3 = 08A2 = End of game + reset
				.dw			JTBL4						; 4 = 0B22 = String
				.dw			JTBL5						; 5 = 0AED = (Not used)
				.dw			JTBL6						; 6 = 0B86 = (de) -> $2000 
				.dw			JTBL7						; 7 = 0AE1 = val -> addr
				.dw			JTBL8						; 8 = 0A9F = Arg to loc
				.dw			JTBL9						; 9 = 0ABC = Select String
				.dw			JTBLA						; A = 0A53 = BCD @ location
				.dw			JTBLB						; B = 086D = LSBs of $2003 to $2029 (?)

				;; e&$07 -> c,  de = de >> 3 + $2400,
				;; Get address for shifted data
L0A00:
				ld			a,e							; Mask e
				and			$07
				ld			c,a							; Stash in c

				;; de>>3
				ld			b,$03						; Loop counter
L0A06:
				xor			a								; CLC
				ld			a,d							; LSB of d to carry
				rra
				ld			d,a
				ld			a,e
				rra
				ld			e,a
				dec			b
				jp			nz,L0A06				; Loop
				
				ld			a,d
				add			a,$24
				ld			d,a
				ret
				

L0A16:
				push		af							; Store count
				ld			a,(hl)					; Get value
				ld			(bc),a					; Store value
				inc			bc			
				ex			de,hl
				or			(hl)
				inc			hl
				ld			(de),a
				pop			af							; Restore count
				push		hl
				ld			hl,$0020				; Row increment
				add			hl,de						; hl = de+$0020
				pop			de							; de = old hl
				dec			a
				jp			nz,L0A16				; loop
				ret

	
				;; Draw b x c block from de to screen at hl
L0A2A:
				push		bc
				push		hl
L0A2C:
				ld			a,(de)
				inc			de
				ld			(hl),a
				inc			hl
				dec			c
				jp			nz,L0A2C				; Loop for col
				
				pop			hl
				ld			bc,$0020				; Row increment
				add			hl,bc
				pop			bc
				dec			b
				jp			nz,L0A2A				; Loop for row
				ret


				;; Clear (hl - hl+c-1)  b times with row offsets
L0A3F:
				xor			a
L0A40:
				push		bc
				push		hl
L0A42:
				ld			(hl),a
				inc			hl
				dec			c
				jp			nz,L0A42				; Loop for col
				
				pop			hl
				ld			bc,$0020				; Row increment
				add			hl,bc
				pop			bc
				dec			b
				jp			nz,L0A40				; Loop for row
				
				ret

	
				;; $09E8 Entry A
JTBLA:													; $0A53
				ex			de,hl
				ld			c,(hl)					; Read bc
				inc			hl
				ld			b,(hl)
				inc			hl
				ld			e,(hl)					; Read de
				inc			hl
				ld			d,(hl)
				dec			hl							; Back up to use de again
				call		L0A82						; Draw BCD from bc at buffer at de
				ex			de,hl						; Last address now in hl
				call		L0A7A						; Replace space with zero
				inc			hl
				ex			de,hl						; Last address now in de
				ld			a,$30
				ld			(de),a					; Append zero
				inc			de
				ld			(de),a					; Append zero
				call		L0ADC						; (hl, hl+1) -> de, hl+=2
				push		de
				call		L0ADC						; (hl, hl+1) -> de, hl+=2
				ld			($2000),hl			; Next command 
				pop			hl
				ld			a,$04						; Length
				jp			L0B30						; Draw string hl @ de, length a


				;; Replace space with a zero
L0A7A:
				dec			hl
				ld			a,(hl)
				and			$40
				ret			z
				ld			(hl),$30
				ret

				;; BCD at (bc) to string at (de)
L0A82:
				ld			a,(bc)	
				rra
				rra
				rra
				rra
				and			$0F							; Mask high nybble
				jp			nz,L0A8E	
				ld			a,$10						; $40 -> blank
L0A8E:
				add			a,$30						; Decimal to ascii
				ld			(de),a					; Store digit
				inc			de							; Inc buffer pointer
				ld			a,(bc)			
				and			$0F							; Mask low nybble
				jp			nz,L0A9A
				ld			a,$10						; $40 -> blank
L0A9A:
				add			a,$30						; Decimal to ascii
				ld			(de),a					; Store digit
				inc			de							; Inc buffer pointer
				ret

			
				;; $09E8 Entry 8 -- Copy data from sequence to address (backwards)
JTBL8:													; $0A9F
				ex			de,hl						; Sequence address back to hl
				ld			b,(hl)					; Get count
				inc			hl
				dec			b
				dec			b
				call		L0ADC						; (hl, hl+1) -> de, hl+=2  (address)
				ld			c,(hl)					; Read first byte
				inc			hl
				ld			a,(hl)					; Read second byte
				inc			hl
				ld			(de),a					; Write first byte
				dec			de
				ld			a,c
				ld			(de),a					; Write second byte
				dec			de
	
L0AB0:
				ld			a,(hl)					; Loop for rest of count
				inc			hl
				ld			(de),a
				dec			de
				dec			b
				jp			nz,L0AB0
				ld			($2000),hl			; Next command
				ret

	
				;; $09E8 Entry 9 -- Draw INSERT COIN or PUSH BUTTON
JTBL9:													; $0ABC
				ex			de,hl
				call		L0ADC						; (hl, hl+1) -> de, hl+=2
				ld			a,(de)
				call		L0ADC						; (hl, hl+1) -> de, hl+=2
				push		de
				call		L0ADC						; (hl, hl+1) -> de, hl+=2
				push		de
				call		L0ADC						; (hl, hl+1) -> de, hl+=2
				ld			($2000),hl			; Next command
	
				ex			de,hl
				and			a
				jp			z,L0AD5					; Draw first string?
				ex			(sp),hl
				
L0AD5:
				pop			hl
				pop			de
				ld			a,$0B						; Length
				jp			L0B30						; Draw string hl @ de, length a

				
				;; (hl, hl+1) -> de, hl+=2
L0ADC:
				ld			e,(hl)					; LSB from table
				inc			hl
				ld			d,(hl)					; MSB from table
				inc			hl
				ret

				;; $9EA8 Entry 7 -- arg -> addr
JTBL7:													; $0AE1
				ld			a,(de)					; Next entry
				inc			de
				ex			de,hl
				ld			c,(hl)					; Next entry
				inc			hl
				ld			b,(hl)					; Next entry
				inc			hl
				ld			($2000),hl			; Store command
				ld			(bc),a					; a -> (bc)
				ret

				;; $09E8 Entry 5
				;; This is apparently never called
				;; Read from de table into b, c, a, e, d
JTBL5:													; $0AED
				ex			de,hl			
				ld			b,(hl)					; get b,c,a from (hl) [was (de)]
				inc			hl
				ld			c,(hl)
				inc			hl
				ld			a,(hl)
				inc			hl
				call		L0ADC						; (hl, hl+1) -> de, hl+=2
				ld   ($2000),hl					; Store command
				
				ex			de,hl
				ld			(hl),$DB				; ?? constant?
				inc			hl
				ld			(hl),c
				inc			hl
				ld			(hl),$C9				; ?? constant?
				dec			hl
				dec			hl
				jp			(hl)						; Jump

				
				;; Deal with inputs (when stable)
L0B05:
				xor			(hl)						; XOR with stored value
				ret			z								; No changes
	
				ld			c,a							; Stash changed bits
				ld			b,$01						; Bit being checked
	
L0B0A:
				ld			a,c							; Restore changed bits	
				rrca
				jp			c,L0B18					; Bit is high
	
				ld			c,a							; Stash changed bits
				ld			a,b							; Shift check bit
				rlca
				ld			b,a
				inc			de							; Advance jump table
				inc			de
				jp			L0B0A						; Loop
	
L0B18:
				ld			a,b							; Bit found to a
				xor			(hl)						; Clear bit
				ld			(hl),a					; Store back
				and			b								; Value of changed bit

				;; Get jump address from table
				ex			de,hl
				ld			c,(hl)
				inc			hl
				ld			h,(hl)
				ld			l,c
				jp			(hl)						; Jump to handler

				
				;; $09E8 Entry 4 (Draw string))
JTBL4:													; $0E22
				ex			de,hl						; 
				ld			a,(hl)					; Length
				inc			hl
				call		L0ADC						; (hl, hl+1) -> de, hl+=2
				push		de
				call		L0ADC						; (hl, hl,1) -> de, hl+=2
				ld			($2000),hl			; Next command
				pop			hl							; String src address

				;; Write string length a from hl to de
L0B30:
				push		af
L0B31:
				ld			a,(hl)					; Get byte
				inc			hl
				sub			$30							; Ascii -> tbl
				jp			p,L0B49					; Jump if >=$30

				;; Blank space = $30-a (?)
				ld			b,a
L0B39:
				inc			e
				ld			a,e
				and			$1F
				jp			nz,L0B42				; No wrap
				inc			d
				inc			d
L0B42:
				inc			b
				jp			nz,L0B39				; Loop for space
				
				jp			L0B31						; Loop for chars

				;; ASCII
L0B49:
				push		hl
				push		de
				;; hl = CHARS + a * $0A
				ld			hl,CHARS				; Start of char table
				jp			z,L0B59					; (no need to add)
				ld			bc,$000A				; Add a*$0a
L0B54:
				add			hl,bc
				dec			a
				jp			nz,L0B54
	
L0B59:
				ex			de,hl
				ld			bc,$0020				; Row increment
				ld			a,$0A						; Loop $a times
				
L0B5F:
				push		af
				ld			a,(de)					; Load byte
				inc			de							; Inc index
				ld			(hl),a					; Store to screen
				add			hl,bc						; Next row
				pop			af
				dec			a
				jp			nz,L0B5F				; Loop for this char
				
				pop			de
				pop			hl
				inc			de							; Next screen loc
				pop			af
				dec			a
				jp			nz,L0B30				; Next char
				
				ret

				
				;; $09E8 Entry 2  (argument to 2010)
JTBL2:													; $0B72
				ex			de,hl
				ld			a,(hl)					; Argument
				inc			hl
				ld			($2000),hl			; Next command
				ld			($2010),a				; Store arg
				ret

				;; $09E8 Entry 1 (argument to 2011)
JTBL1:													; $0B7C
				ex			de,hl
				ld			a,(hl)					; Argument
				inc			hl
				ld			($2000),hl			; Next command
				ld			($2011),a				; Store arg
				ret

				;; $09E8 Entry 6 (de) -> $2000
JTBL6:													; $0B86
				ex			de,hl
				ld			e,(hl)
				inc			hl
				ld			d,(hl)
				ex			de,hl
				ld			($2000),hl			; Store command
				ret

				
				;; Character table
CHARS:													; $0B8F
#include "swfont.asm"

				
				;; Sprites
GFX:														; $0D3D
#include "swgfx.asm"

				
				;; Table for $07CF
MINEEXP:																									; $0EB5
				.db			$3D, $3E, $3F															; Mine explosion

LTBLANK:																									; $0EB8
				.db			$40, $40, $40, $40, $40, $40, $40, $40		; ________
				.db			$40, $40, $40															; ___

LTOVER:																										; $0EC3
				.db			$47, $41, $4D, $45, $40, $4F, $56, $45		; GAME_OVE
				.db			$52																				; R

LTHIGH:																										; $0ECC 
				.db			$48, $49, $47, $48, $40, $53, $43, $4F		; HIGH_SCO
				.db			$52, $45, $40, $40, $40, $40, $40, $40		; RE______
				.db			$59, $4F, $55, $52, $40, $53, $43, $4F		; YOUR_SCO
				.db			$52, $45																	; RE

LTCOIN:																										; $0EE6
				.db			$49, $4E, $53, $45, $52, $54, $40, $43		; INSERT_C
				.db			$4F, $49, $4E															; OIN

LTPUSH:																										; $0EF1 
				.db			$50, $55, $53, $48, $40, $42, $55, $54		; PUSH_BUT
				.db			$54, $4F, $4E															; TON

LTSEA:																									  ; $0EFC 
				.db			$53, $45, $41, $40, $57, $4F, $4C, $46		; SEA_WOLF

				;; Water
L0F04:
				.db			$3A, $3B, $3C, $3B, $3C, $3A, $3B, $3C		; All
				.db			$3A, $3C, $3B, $3C, $3A, $3B, $3A, $3C		; Water
				.db			$3B, $3A, $3C, $3A, $3B, $3C, $3A, $3C		; Codes
				.db			$3B, $3C, $3A, $3B, $3C, $3A, $3B, $3C		; Here

LTBONUS:																									; $0F24 
				.db			$42, $4F, $4E, $55, $53										; BONUS

LTTIME:																										; $0F29
				.db			$54, $49, $4D, $45												; TIME
				.db			$2D																				; <space>
				.db			$53, $43, $4F, $52, $45										; SCORE

LTEXT:																					; $0F33 
				.db			$45, $58, $54, $45, $4E, $44, $45, $44		; EXTENDED
				.db			$16																				; <space>
				.db			$54, $49, $4D, $45     										; TIME


				;; Addresses of mine hit data
TEMINE:
				.dw			TZAP																			; ZAP
				.dw			TWAM																			; WAM
				
				;; Table from $0F40	(For ZAP)
TZAP:		
				.db			$01, $41, $04, $3D, $5A, $2F, $50, $3F		; *ZAP*

				;; Table from $0F42	(For WAM)
TWAM:
				.db			$01, $41, $04, $3D, $57, $2F, $4D, $3F		; *WAM*
				
				;; 4-byte table (time per credit)
LDTIME:																					; $0F54 
				.db			$61, $71, $81, $91												; (Seconds) 

				;; $0F57 = 8-byte score table (0,7 not used)
TSCORE:																										; $0F58
				.db			$03, $03, $03, $01, $01, $07							; 

				;; Table for $05D2	(0x20 long)
				;; Grey code decode
TGREY:																										; $0F5E 
				.db			$00, $08, $18, $10, $38, $30, $20, $28		; 
				.db			$78, $70, $60, $68, $40, $48, $58, $50		; 
				.db			$F8, $F0, $E0, $E8, $C0, $C8, $D8, $D0		; 
				.db			$80, $88, $98, $90, $B8, $B0, $A0, $A8		; 


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
				.db			(SHIP0>>8), SHIP0&$ff
				.db			$20, $14, $00, $D8, $00, $02		; Ship 0
				.db			(SHIP1>>8), SHIP1&$ff
				.db			$20, $14, $00, $E0, $00, $02		; Ship 1
				.db			(SHIP2>>8), SHIP2&$ff
				.db			$20, $14, $00, $D8, $00, $02		; Ship 2
				.db			(SHIP3>>8), SHIP3&$ff
				.db			$20, $15, $00, $E0, $00, $01		; Ship 3
				.db			(SHIP4>>8), SHIP4&$ff
				.db			$20, $15, $00, $E0, $00, $01		; Ship 4
				.db			(SHIP5>>8), SHIP5&$ff
				.db			$20, $1A, $00, $F0, $00, $03		; Ship 5

				;; Odd ship table
L0FAE:
				.db			(SHIP0>>8), SHIP0&$ff
				.db			$40, $34, $00, $D8, $D8, $FE		; Ship 0
				.db			(SHIP1>>8), SHIP1&$ff
				.db			$40, $34, $00, $E0, $E0, $FE		; Ship 1
				.db			(SHIP2>>8), SHIP2&$ff
				.db			$40, $34, $00, $D8, $D8, $FE		; Ship 2
				.db			(SHIP3>>8), SHIP3&$ff
				.db			$40, $35, $00, $E0, $E0, $FF		; Ship 3
				.db			(SHIP4>>8), SHIP4&$ff
				.db			$40, $35, $00, $E0, $E0, $FF		; Ship 4
				.db			(SHIP5>>8), SHIP5&$ff
				.db			$40, $3A, $00, $F0, $F0, $FD		; Ship 5

	
				;; Ship type table
L0FDE:
				.db			$06															; Small, fast
				.db			$04															; Mid, 2 towers
				.db			$02															; Cross in back
				.db			$06															; Small, fast
				.db			$03															; Big, flat top
				.db			$05															; Tower in back
				.db			$01															; Battleship
	
	.org $0fff
				.db			$ff
			
.end
			