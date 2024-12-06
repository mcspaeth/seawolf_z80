				;; @2024 Mark Spaeth -- mspaeth@gmail.com
				;; Whitespace for emacs asm mode w/ tab width 2

				;; Programmed for tasm z80 mode using only 8080 instructions

				;; Config variables
				;; Original release: SC3DIG=0, OLDDIP=1, OLDINT=1, OLDTEST=1, GETMAC=0, MINEFIX=0, FANCY=0, SEAMISS=0
				;; 3 digit scoring:  SC3DIG=1, OLDDIP=1, OLDINT=0, OLDTEST=0, GETMAC=0, MINEFIX=0, FANCY=0, SEAMISS=0

SC3DIG	= 1											; 3 digit scoring, simplified coinage
OLDDIP	= 0											; Table lookup vs calculated DIPs
OLDINT	= 0											; Exclude interpreter changes that save bytes
OLDTEST	= 0											; Use $0200 byte self test routine
GETMAC	= 0											; Use jsr for GETBC, GETDE (saves 1 byte per)
MOREEXP	= 1											; More mine explosion text
MINEFIX	= 1											; Fix the mines jumping on reload
FANCY		= 1											; Bidirectional / multi-speed mines
DOCOPY	= 1											; Add copyright to self test
HSSAVE	= 0											; Prevent HS from being cleared at reset
SEAMISS	= 1											; Count down misses instead of time

				;; Graphics changes
OLDMINE	= 1-FANCY								; Use original mine gfx
SW2024	= 1											; Change Q to '24

				;; Generic variables
SINC		= $000D									; Ship entry length
MINC		= $000D									; Mine entry length
RINC		= $0020									; Row increment
TINC		= $001E									; Torpedo entry length

				;; Memory locations
PRGPTR	= $2000									; $2000-2001

#IF SC3DIG
HSCORE	= $2002									; Was $2006
HSCOREH	= HSCORE+1							; High byte
GTIME		= $2004									; Was $2002
TIMER		= $2005									; Was $2003
CREDIT	= $2006									; Was $2005, half credit not used
MISSED	= $200E									; (Previously unused)
PSCORE	= $2012									; Was $202B
PSCOREH	= PSCORE+1							; High byte
TXTBUF	= $21E8									; Space for 1 more digit
#ELSE
GTIME		= $2002
TIMER		= $2003
HCREDIT	= $2004
CREDIT	= $2005									; Was $2005, half credit not used
HSCORE	= $2006
PSCORE	= $202B									; Was $202B
TXTBUF	= $21E9
#ENDIF


IN1			= $2007
IN0			= $2008
TIMER1	= $2010
TIMER2	= $2011
HMINE		= $2014									; Next mine to update
HTORP		= $2016									; Next torp to update
HSHIPA	= $2018									; SHIPA handle
HSHIPB	= $201A									; SHIPB handle
HSUNK		= $201C									; SUNK handle (?)

ATIMER	= $2025									; Audio timer

SHIPA0	= $2031									; Base address of ship A
SHIPA1	= SHIPA0+SINC						; $203E ($0d block)
SHIPA2	= SHIPA1+SINC						; $204B ($0d block)
SHIPAX	= SHIPA2+SINC						; Reset to $2031 if here

SHIPB0	= $2058									; Base address of ship B
SHIPB1	= SHIPB0+SINC						; $2065 ($0d block)
SHIPB2	= SHIPB1+SINC						; $2072 ($0d block)
SHIPBX	= SHIPB2+SINC						; Reset to $2058 if here

MINES		= $207F									; Base address of mines
MINEX		= MINES+(8*MINC)				; $20E7 (8x $0d blocks)

TORPS		= $20E7									; Base address of torpedos
TORPX		= TORPS+(4*TINC)				; $215F (4x $1e blocks)

HMISS		= $21F0


				;; Screen addresses for text
WAVLOC	= $27E0									; Loc for "Wave"
GOTLOC	= $2C0B									; Loc for GAME OVER text
SWLTOC	= $2C0C									; Loc for SEA WOLF text
ERRLOC	= $3008									; Loc for ROM errors
COPYLOC	= $3408									; Loc for Copyright
ICTLOC	= $3833									; Loc for Insert Coin / Press Start
HSTLOC	= $3C02									; Loc for HIGH SCORE text
TSTLOC	= $3C0E									; Loc for TIME/SCORE text
HSLOC		= $3E25									; Loc for high score
PSLOC		= $3E36									; Loc for player score

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
				;; 2008      = Last IN0
				;; 2009-200a = End game hl pointer store (deprecated)
				;; 200e-200f = Unused?
				;; 2010      = Down counter (when $2003 == 0)
				;; 2011      = Down counter
				;; 2012-2013 = (Not used?)
				;; 2014-2015 = MINE table pointer (last updated)
				;; 2016-2017 = TORP table pointer (last updated)
				;; 2018-2019 = SHIPA table pointer
				;; 201a-201b = SHIPB Table pointer
				;; 201c      = Next sprite?
				;; 201e      = ??
				;; 201f      = Later interrupt called ($00 = rst $08, $FF = rst $10)

				;; 2020      = Mask for subs to call at 04ce (when [[$2000]] == 00)
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
				;;		Byte 9-A = Calculated screen location
				;;		Byte C-D = Calculated sprite size
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

				;; Torpedo control
				;; 20e7-2104 = $1e data block
				;; 2105-2122 = $1e data block
				;; 2123-2140 = $1e data block
				;; 2140-21r3 = $1e data block

				;; 215f-21a3 = $44 data block, cleared at $0088

				;; 21e8-21ef = 8 character buffer for time+score
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

				ld			hl,(HTORP)			; Torpedo handle
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
				ld			hl,(HTORP)			; Torpedo handle
				ld			a,(hl)
				and			a
				jp			p,L0062					; D7=0 = inactive

				and			$40
				jp			nz,L0050				; Jump if not set to clear
				ld			(hl),$00				; Clear sprite
				jp			L0062

L0050:
				ld			a,(hl)					; Flags
				or			$20							; Set SUNK flag
				ld			(hl),a
				call		L0165						; Update sprite
				ld			a,b
				push		hl
				ld			hl,(HSUNK)			; (HSUNK) to bc
				ld			b,h
				ld			c,l
				pop			hl
				call		L0A16

L0062:
				call		L0368						; Handle ($2020) flags
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

				ld			hl,(HSHIPA)			; SHIPA handle
				ld			a,$03						; Loop counter 
L0099:
				push		af
				ld			a,l
				cp			SHIPAX&$FF			; Cycles $2031 / $203E / $204B
				jp			nz,L00A3

L00A0:
				ld			hl,SHIPA0				; Resets to $2031
L00A3:
				or			h
				jp			z,L00A0					; If was $0000, init as $2013

				push		hl
				call		L01DE						; Handle sprite
				pop			hl
				jp			nc,L00B2

				ld			(HSHIPA),hl			; SHIPA handle
L00B2:
				ld			de,SINC					; Sprite increment
				add			hl,de
				pop			af
				dec			a
				jp			nz,L0099				; Loop back

				ld			hl,(HSHIPA)			; SHIPA handle
				call		L030C						; Erase if sunk
				ld			hl,(HSHIPB)			; SHIPB handle

				ld			a,$03						; Loop counter
L00C6:
				push		af
				ld			a,l
				cp			SHIPBX&$FF			; Cycloes $2058 / $2065 / $2072
				jp			nz,L00D0
L00CD:
				ld			hl,SHIPB0				; Reset to $2058
L00D0:
				or			h
				jp			z,L00CD					; If was $0000, init as $2058

				push		hl
				call		L01DE						; Handle sprite
				pop			hl
				jp			nc,L00DF

				ld			(HSHIPB),hl			; SHIPB handle
L00DF:
				ld			de,SINC					; Sprite increment
				add			hl,de
				pop			af
				dec			a
				jp			nz,L00C6				; Loop back

				xor			a
				ld			($2030),a				; Clear sprite shift

				ld			hl,(HTORP)			; Torpedo handle
				ld			a,$04						; Loop counter
L00F1:
				push		af
				ld			a,l
				cp			TORPX&$FF				; Cycles $20E7 / $2105 / $2123 / $2140
				jp			nz,L00FB

L00F8:
				ld			hl,TORPS				; Reset to $20E7
L00FB:
				or			h
				jp			z,L00F8					; If was $0000, init to $20E7

				push		hl
				call		L0250						; Handle torpedo
				pop			hl
				jp			nc,L010A

				ld			(HTORP),hl			; Torpedo handle
L010A:
				ld			de,TINC					; Torp increment
				add			hl,de
				pop			af
				dec			a
				jp			nz,L00F1				; Loop back

				call		L0331						; Update mines
				jp			L0069						; End of interrupt routine


L0119:
				ld			hl,(HSHIPB)			; SHIPB handle
				call		L030C						; Erase if sunk

				ld			hl,(HSHIPB)			; SHIPB handle
				call		L013A

				ld			hl,(HSHIPA)			; SHIPA handle
				call		L013A

				jp			L0069						; End of interrupt routine

				;; Called from rst $10
				;; Update and draw a single mine
L012E:
				ld			hl,(HMINE)
				ld			a,(hl)
				and			a
				ret			p								; D7 clear = inactive

#IF MINEFIX
				jp			DRAWOBJ
#ELSE
				call		L0165						; Update mine
				jp			L0192						; Draw mine
#ENDIF

				;; Handle SHIPA / SHIPB entries
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

DRAWOBJ:
				push		af
				call		L0165						; Update sprite params
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
				call		L0A00						; Get address for shifted data

				ld			a,c							; (shift)
				ld			($2030),a				; Shift value
				out			($04),a					; Shifter count
				push		de							; Push screen loc

#IF GETMAC
				call		GETDE
#ELSE
				ld			e,(hl)					; Get spite data loc
				inc			hl
				ld			d,(hl)
				inc			hl
#ENDIF

				ex			de,hl						; rom loc -> hl

#IF GETMAC
				call		GETBC
#ELSE
				ld			c,(hl)					; Read sprite size
				inc			hl
				ld			b,(hl)
				inc			hl
#ENDIF

				ex			(sp),hl					; hl = screen loc
				ex			de,hl						; hl Back to ram table

#IF GETMAC
				call		GETDE
#ELSE
				ld			(hl),e
				inc			hl
				ld			(hl),d
				inc			hl
#ENDIF

				ld			(hl),c					; Width
				inc			(hl)						; +1 wide for shifting?
				inc			hl
				ld			(hl),b					; Height
				inc			hl
				ld			(HSUNK),hl			; Store next

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
				ld			(hl),a					; Write to screen
				inc			hl
				dec			c
				jp			nz,L0194				; Loop for width

				xor			a
				out			($03),a					; MB12421 data write
				in			a,($03)					; MB12421 data read
				ld			(hl),a					; Final write
				ld			bc,RINC					; Row increment
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
				jp			nz,L01BA				; Loop for width

				xor			a
				out			($03),a					; Shifter input 
				in			a,($00)					; Shifter output
				ld			(hl),a					; Write to screen
				ld			bc,RINC					; Row increment
				pop			hl
				add			hl,bc						; Next line
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
				and			$BF							; Clear bit 5 (Ship done)
				ld			(hl),a
				ex			(sp),hl

#IF SEAMISS
				ld			a,(GTIME)
				and			a
				jp			z,L0216					; Game over

				ld			(MISSED),a			; Set to non-zero value
#ELSE
				jp			L0216
#ENDIF

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
				and			$1F							; High 5 bits of (hl)
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


				;; Erase ship from hl if sunk
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

				ld			de,RINC					; Row increment
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

				;; Update mines
L0331:
				ld			hl,(HMINE)
;				ld			b,$0A						; Loop counter = 10 mines
				ld			b,$08						; Loop counter =  8 mines
				ld			a,l
				or			h
				jp			nz,L033E

				ld			hl,MINES-MINC		; If 0 reset to $2072
L033E:
				ld			de,MINC					; Mine increment
L0341:
				add			hl,de						; $207F / $207C / $2099 / $20A6 / $20B3 / $20C0 / $20CD / $20DA
				dec			b
				ret			z								; End of loop

				ld			a,l
				cp			MINEX&$FFF			; hl == $20E7?
				jp			nz,L034D

				ld			hl,MINES				; Reset to $207F
L034D:
				;; Check logic here
#IF 1-MINEFIX
				ld			a,(hl)					; X flags
				and			a
				jp			p,L0341					; D7 clear = not active
#ENDIF

				ld			(HMINE),hl
				inc			hl
				ld			a,(hl)					; Delta X
				inc			hl
				add			a,(hl)					; Add to X
				ld			(hl),a					; Store X

#IF MINEFIX
				dec			hl
				dec			hl
				ld			a,(hl)
				and			a
				jp			p,L0341					; Loop until we get an active mine
#ENDIF

				ret

				;; Load de, bc from ship data
L035B:
				ld			de,$0009
				add			hl,de

#IF GETMAC
				call		GETDE
#ELSE
				ld			e,(hl)
				inc			hl
				ld			d,(hl)
				inc			hl
#ENDIF

GETBC:
				ld			c,(hl)
				inc			hl
				ld			b,(hl)
				inc			hl
				ret

				;; Called from ISR
L0368:
				ld			a,($2020)				; ISR flags
				and			a
				ret			nz

				ld			b,a							; No ret, so a=0, b=0
				ld			hl,TIMER				; Counter address
				dec			(hl)						; Decrement counter
				jp			nz,L038E

				;; $2003 Counter zero
				ld			(hl),$1E				; Reset counter

#IF SEAMISS
				;; Handle MISSED flag
				ld			a,(MISSED)
				and			a
				jp			z,L0388					; No miss

				xor			a
				ld			(MISSED),a
#ENDIF

				ld			hl,GTIME				; Game timer
				ld			a,(hl)
				and			a
				jp			z,L0388					; Game over

				add			a,$99						; BCD derement
				daa
				ld			(hl),a					; Store timer
				and			a								; Z should be set by daa (!)
				jp			nz,L0388

				ld			b,$01						; set d7 (eventually) = Game over
L0388:
				ld			hl,TIMER1
				call		L03AE						; Handle $2010 timer d6

				;; Counter non-zero
L038E:
				ld			hl,TIMER2
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

				xor			a								; a=0
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
				ld			hl,WAVLOC
				add			a,l
				ld			l,a
				ld			bc,RINC					; Row increment
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
#IF DOCOPY
				ld			hl,COPYRGHT
				ld			de,COPYLOC
				ld			a,$0C						; Length
				call		L0B30						; Draw string
#ENDIF

				ld			hl,L0000				; Start address
				ld			de,$0000				; Offset 0
#IF OLDTEST
				ld			c,$02						; 2 pages
#ELSE
				ld			c,$04						; 4 pages
#ENDIF

L03F4:
				xor			a								; Clear checksum
L03F5:
				add			a,(hl)
				inc			hl
				ld			b,a
				ld			a,c
				cp			h
				ld			a,b
				jp			nz,L03F5				; Loop

				push		hl							; Push address
				ld			hl,CHKS					; Checksum table
				add			hl,de
				cp			(hl)						; Compare checksum
				ld			a,$40						; (Space)
				jp			z,L040E					; Checksum good!

				ld			hl,ERRS					; Bad checksum table
				add			hl,de
				ld			a,(hl)

L040E:
				ld			hl,TXTBUF				; Text buffer
				add			hl,de
				ld			(hl),a					; Store char

				pop			hl							; Get address back
				inc			de							; Next rom
				inc			c								; $02 more pages
				inc			c
#IF OLDTEST
				ld			a,$12
#ELSE
				inc			c								; $02 more pages
				inc			c
				ld			a,$14
#ENDIF
				cp			c
				jp			nz,L03F4				; Loop if not done

				ld			hl,TXTBUF				; Text buffer
				ld			de,ERRLOC				; Location
#IF OLDTEST
				ld			a,$08						; Length
#ELSE
				ld			a,$04						; Length
#ENDIF
				call		L0B30						; Draw string hl @ de, length a
				halt										; Stop!

#IF OLDTEST
				;; $200 block checksums
L0429:
CHKS:
				.db			$8D, $79, $00, $1F, $58, $6D, $EA, $C5	; Checksums

				.db			$2A							; Patch byte for $400 checksum

				;; Error locations
L0432:
ERRS:
				.db			$48, $48, $47, $47, $46, $46, $45, $45	; HHGGFFEE
#ENDIF

				;; Initial jump
L043A:
				call		L08A2						; (End of game routine)
				in			a,($02)					; IN2

#IF OLDDIP
				and			$E0							; Test mode bits
				cp			$E0
#ELSE
				and			$08							; Dip 4 = Test
				cp			$08
#ENDIF

				call		z,L03EC					; Go to test mode

				;; Clear $2002-$200a
				;; Change this for HS Save?

#IF SC3DIG
#IF HSSAVE
				ld			hl,GTIME				; $2004
				ld			a,$07						; $2004-$200a
#ELSE
				ld			hl,HSCORE				; $2002
				ld			a,$09						; $2002-$200a
#ENDIF
#ELSE
				ld			hl,GTIME				; $2002
				ld			a,$09						; $2002-$200a
#ENDIF

				ld			b,$00
L044D:
				ld			(hl),b
				inc			hl
				dec			a
				jp			nz,L044D

#IF SC3DIG
				call		CHKFP
#ENDIF

				ld			hl,L0929				; Attract mode loop
				ld			(PRGPTR),hl

L0459:
				ei											; Enable interrupts
				ld			hl,L0459				; Return address
				push		hl
				ld			hl,(PRGPTR)
				ld			a,(hl)					; Get command
				and			a
				jp			nz,L047D				; Non-zero command

				;; a=(($2000)) == 0
				;; Command 0
				call		L06A4
				call		L04CE
				call		L04BF						; Start game
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
				ld			a,(TIMER)
				cp			$1D
				ret			m								; Only update once per loop

				;; Update game time
				ld			bc,GTIME				; Game time
				ld			de,TXTBUF				; Text buffer

#IF SC3DIG
				call		BCD2_0					; BCD to buffer

				ld			a,$2B						; Space
				ld			(de),a					; Store
				inc			de

				ld			bc,PSCORE				; Player score
				call		BCD300					; 3 nybble BCD+00 to string
#ELSE
				call		L0A82						; BCD to buffer
				ex			de,hl
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
#ENDIF

				ld			hl,TXTBUF				; Text buffer
				ld			de,$3E2F				; Screen location
#IF SC3DIG
				ld			a,$07						; Length
#ELSE
				ld			a,$06						; Length
#ENDIF
				jp			L0B30						; Draw string hl @ de, length a

L04BF:
				ld			hl,$202A				; Duplicate game time
				ld			a,(hl)
				and			a
				ret			z								; Already zero

				ld			(hl),$00				; Clear
				ld			hl,L09A6				; Game over mode
				ld			(PRGPTR),hl			; Write mode
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
				ld			(ATIMER),a			; Set timer
L050F:
				pop  af
				ret


				;; Bit 7 set on $2020
L0511:
				ld			hl,$202E
				ld			a,(hl)
				and			a
				jp			nz,NOEXT				; Jump if already extended time

				ld			(hl),$01				; Only 1 extend
				ld			a,(IN1)					; Last IN1
				rrca
				and			$70							; Base score for extended time (00 = none)
				jp			z,NOEXT					; Jump if no extended time

				add			a,$09						; $20 dip = $19(00) score
				ld			hl,PSCORE				; Player score
				cp			(hl)

#IF SC3DIG
				jp			c,DOEXT					; Jump if score higher than metric

				;; Extended score if >10k
				inc			hl							; Player score hi
				ld			a,(hl)
				and			a
				jp			z,NOEXT
#ELSE
				jp			nc,NOEXT				; Jump if score lower than metric
#ENDIF

DOEXT:
#IF SEAMISS
				ld			a,$04						; 4 extra misses
#ELSE
				ld			a,$20						; 20 extra seconds
#ENDIF
				ld			(GTIME),a				; Set game time
				ld			hl,LTEXT				; EXTENDED_TIME
				ld			de,$3C03				; Location
				ld			a,$0C						; Length
				jp			L0B30						; Draw string hl @ de, length a

L053D:
NOEXT:
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
				ld			(GTIME),a				; Let torps finish
				ret

				;; Check if new high score
L055C:
				ld			hl,L0929				; Attract mode
				ld			(PRGPTR),hl			; Next command

#IF SC3DIG
				ld			a,(PSCORE+1)		; Score hi byte
				ld			hl,HSCORE+1			; High  hi byte
				cp			(hl)
				ret			c								; Score lower

				ld			(hl),a					; Write new hi byte
#ENDIF

				ld			a,(PSCORE)			; Player score
				ld			hl,HSCORE				; High score

#IF SC3DIG
				jp			nz,HSDOLO				; Higher hi byte -> write low
#ENDIF
				cp			(hl)
				ret			c

HSDOLO:
				ld			(hl),a					; Write new score
				ret


				;; Bit 6 set on $2020
				;; Initialize $2000 address
L056C:
				ld			hl,L0963				; Game over
				ld			(PRGPTR),hl
				ret

				;; Bit 5 set on $2020
				;; Increment $2000 address
L0573:
				ld			hl,(PRGPTR)			; After 2011 timer?
				inc			hl
				ld			(PRGPTR),hl
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
				ld			(ATIMER),a			; Set timer

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
				pop			af
				ret


				;; Bit 1 set on $2020
				;; Clear sprites?
L060E:
				push		af
				ld			hl,HMISS
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
				ld			a,(TIMER)
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
				ld			(ATIMER),a			; Set timer
				ld			a,b							; Ship type

				;; hl = $2031 - $0d + $08 + $0d * a 
L066B:
				ld			hl,SHIPA0-SINC+$08			; ROM loc in sprite table
				ld			de,SINC					; Sprite increment
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
				ld			bc,SINC					; Sprite entry length
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
				ld			a,b

				;; Draw sunk ship score
				ld			bc,TSCORE-1			; Ship hit score table
				and			$07
				add			a,c
				ld			c,a							; bc = index into table

				ld			de,TXTBUF				; Text buffer

#IF SC3DIG
				call		BCD2__					; BCD to string
				call		ADD00						; Append 00
#ELSE
				call		L0A82						; BCD to buffer
				ld			a,$30
				ld			(de),a					; Append 0
				inc			de
				ld			(de),a					; Append 0
#ENDIF

				ld			a,(bc)
				ld			hl,PSCORE				; Player score
				add			a,(hl)					; Add a
				daa
				ld			(hl),a					; Store

#IF SC3DIG
				jp			nc,NOCARRY
				inc			hl							; Store MSB
				inc			(hl)						; Increment

NOCARRY:
#ENDIF
				pop			hl

#IF GETMAC
				call		GETBC
#ELSE
				ld			c,(hl)					; Get bc from table
				inc			hl
				ld			b,(hl)
				inc			hl
#ENDIF

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
				ld			(ATIMER),a			; Set audio timer

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

				call		L07DB						; de to first empty missle slot

				ld			a,$2D
				ld			($2024),a				; Set timer (for showing score)
				ld			hl,TXTBUF+1			; Buffer?
				ld			a,$03						; Length
				call		L0B30						; Draw string hl @ de, length a

				pop			hl
				jp			L06A7


				;; Mine collision detection?
L074C:
				ld			hl,$21A3				; $44 long data block
L074F:
				ld			a,(hl)
				and			a
				ret			z								; Skip if zero

				inc			hl							; $21A4
				add			a,$10
				rlca										; 65432107
				rlca										; 54321076
				rlca										; 43210765
				and			$07							; Mines to to 7

				;; hl= X position of mine
				ld			de,MINES - (2*MINC) + $02	; ($2067 = XPOS)
				ld			bc,MINC					; Mine increment
				ex			de,hl
L0761:
				add			hl,bc
				add			hl,bc
				dec			a
				jp			nz,L0761

				ld			a,(de)					; $21A4
				sub			$08
				sub			(hl)
				cp			$EC
				jp			nc,L0771

				add			hl,bc
L0771:
				dec			hl
				dec			hl

#IF MINEFIX
				ld			a,(hl)
				and			$7F							; Clear active bit
				ld			(hl),a
#ELSE
				ld			(hl),$00
#ENDIF

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
				call		L0A00						; Get address for shifted data

				;; Make sure explosion fits on screen
				;; 0-11   -> 0
				;; 1D-1F -> 1C
				ld			a,e
				and			$1F
				jp			z,L0796					; e=$00

				dec			a
				jp			z,L0796					; e=$01

L0790:
				dec			a
				cp			$1C
				jp			p,L0790					; Loop

				;; Draw mine explosion
L0796:
				ld			e,a
				call		L07DB						; de to first empty missile slot

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
				ld			(ATIMER),a			; Set timer (audio)
				ld			a,$0F
				ld			($2024),a				; Set timer (show explosion)
				ld			a,$10						; Sound bit 4
				out			($05),a					; Sound write

				ld			a,e							; No idea what e is here, but used as PRNG

#IF OLDINT
				and			$02							; Mask bit (a=0 or 2)
				ld			hl,TEMINE
				add			a,l
				ld			l,a							; hl = ZAP or WAM

				;; Get address from table -> hl
				ld			e,(hl)
				inc			hl
				ld			d,(hl)
				ex			de,hl						; hl = Table entry
#ELSE
#IF MOREEXP
				and			$18							; Mask bit (a=0/8/10/18)
#ELSE
				and			$08							; Mask bit (a=0/8)
#ENDIF
				ld			hl,TZAP					; First mine explosion entry
				ld			d,$00
				ld			e,a							; Use de in case we cross a page boundry
				add			hl,de						; hl = Table entry
#ENDIF

				;; "Middle" letter or ZAP/WAM
				pop			de
				ld			a,(hl)
				inc			hl
				call		L0B30						; Draw string hl @ de, length a

				;; Rest of ZAP/WAM
				pop			de
				ld			a,(hl)
				inc			hl
				call		L0B30						; Draw string hl @ de, length a

				;; Bottom of mine explosion
				pop			de
				ld			hl,MINEEXP
				ld			a,$03
				call		L0B30						; Draw string hl @ de, length a

				pop			hl
				jp			L074F


				;; Write de to first empty missile slot
L07DB:
				ld			hl,HMISS				; Missile table
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
#IF SC3DIG
				ld			hl,PSCORE+1			; Score MSB
				ld			a,(hl)
				and			a
				jp			nz,MAXMINE			; >10k points

				dec			hl							; Score LSB
				ld			a,(hl)
#ELSE
				ld			a,(PSCORE)			; Player score
#ENDIF

				cp			$40

#IF MINEFIX
				jp			c,LT40

MAXMINE:
				ld			a,$30						; Min of score or $30
LT40:
				and			$30							; Clear LSBs
				add			a,$10
				ld			hl,MINES
				ld			bc,MINC

NEWMINE:
				ld			e,a							; Stash a
				ld			a,(hl)					; Mine status
				and			a
				jp			m,NMEND					; Already active

				or			$80							; Activate mine
				ld			(hl),a					; Mine status
				inc			hl
				inc			hl
				ld			a,(hl)					; Mine X pos
				add			a,$80						; Reposition
				ld			(hl),a					; Mine X pos
				dec			hl
				dec			hl

NMEND:
				add			hl,bc						; Next mine
				ld			a,e							; Restore a
				sub			$08
				jp			nz,NEWMINE			; Loop
				ret

#ELSE
				jp			c,L07F4					; <$40

MAXMINE:
				ld			a,$39						; Min of score or $39
L07F4:
				ld			($202C),a				; Mine counter

				ld			hl,MINES				; 1st mine sprite
				ld			de,$5050				; Initial Mine X,Y

L07FD:
				ld			a,(hl)
				and			a
				jp			m,L0835					; Mine needs to be erased

				;; Launch mine
NEWMINE:
L0802:
				ld			bc,$0008
				add			hl,bc						; Advance in sprite entry
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

NOMINE:
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
				ld			bc,SINC					; Sprite table increment
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
				call		L0A00						; Get address for shifted data
				ex			de,hl
				ld			bc,$1002				; 16 x 2 byte area
				call		L0A3F						; Clear area at hl
				pop			de
				pop			hl
				jp			L0802
#ENDIF

				;; Handle high score erase
HERASE:
				ret			z
				xor			a								; a=0

#IF SC3DIG
				ld			hl,HSCORE
				ld			(hl),a					; High score LSB
				inc			hl
				ld			(hl),a					; High score MSB
#ELSE
				ld			(HSCORE),a			; Clear high score
#ENDIF

				ld			a,(TIMER1)
				and			a
				ret			z

#IF SC3DIG
				ld			bc,HSCORE
				ld			de,TXTBUF
				push		de
				call		BCD300
#ELSE
				ld			hl,TXTBUF				; Text buffer
				push		hl

				;; Write 4x '0' to buffer
				ld			bc,$0430				; b=loop counter, c=data
L085E:
				ld			(hl),c
				inc			hl
				dec			b
				jp			nz,L085E				; Loop
#ENDIF

				pop			hl
				ld			de,$3E25				; Screen location

#IF SC3DIG
				ld			a,$05						; Length = 5
#ELSE
				ld			a,$04						; Length = 4
#ENDIF

				jp			L0B30						; Draw string hl @ de, length a

				;; $09E8 Entry B = Write low 3 bits of $2003 to $2029?
JTBLB:													; $086D
				ex			de,hl						; Sequence back to hl
				ld			(PRGPTR),hl			; Store

				ld			a,(TIMER)				; 
				and			$07							; Mask low 3 bits
				cp			$07							; == $07?
				jp			nz,L087C

				xor			a								; Clear
L087C:
				ld			($2029),a				; Write
				ret

#IF OLDINT
				;; End of game clears
L0880:
				di
				ex			de,hl						; Stash hl in de
				ld			(PRGPTR),hl
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
#ENDIF

				;; $09E8 Entry 3 (End game)
JTBL3:
L08A2:
				pop			hl							; Return address (SP trashed)
#IF OLDINT
				ld			($2009),hl			; Stash in ($2009-200a)
				call		L0880						; End of game clears
				ld			hl,($2009)			; Get return address back
#ELSE
				;; Embedded end of game clears
				di
				ex			de,hl						; hl = program stack
				ld			(PRGPTR),hl			; Next command
				ex			de,hl						; hl = return address  REDO THIS
				xor			a
				out			($02),a					; Clear periscope lamp
				out			($05),a					; Clear audio latches
				out			($01),a					; Clear explosion lamp

				;; Clear $400F down to $2010
				ld			bc,$0000
				ld			de,$0000
				ld			a,$10
				ld			sp,$4010				; Push it real good
CLRLOOP:
				push		bc
				inc			de
				cp			d
				jp			nz,CLRLOOP			; Loop

				ld			sp,$2400				; Reset stack pointer
#ENDIF
				push		hl							; Restore return address

#IF MINEFIX
				;; Initial X,Y = d,e = $50,$50
				;; For Mine fix:
				;; $00, $20:		Y=$50, dX= 1, Flags=$00
				;; $40, $60:		Y=$70, dx= 1, Flags=$00
				;; $80, $A0:		Y=$90, dX= 1, Flags=$00
				;; $C0, $E0:		Y=$B0, dx= 1, Flags=$00
				
				;; For Seawolf '24:
				;; $00, $20:		Y=$50, dX= 1, Flags=$00
				;; $40, $60:		Y=$70, dx=-1, Flags=$40
				;; $80, $A0:		Y=$90, dX= 2, Flags=$00
				;; $C0, $E0:		Y=$B0, dx=-2, Flags=$40

SETMINES:
				ld			a,$00						; Loop counter
				ld			hl,MINES				; First mine
				ld			d,$50						; Initial mine x
SMLOOP:
				ld			e,a							; Stash counter
				inc			hl							; +1 = Delta X
				inc			(hl)						; +/-1

#IF FANCY
				and			a								; High bit set = +/2
				jp			p,SMROW01				; Rows 0 and 1

SMROW23:
				inc			(hl)						; +/-2
SMROW01:
				and			$40

				jp			z,SMROW02				; Rows 0 and 2
SMROW13:
				dec			hl							; +0 = Flags
				ld			(hl),$10				; Direction flag
				inc			hl							; +1 = Delta X
				xor			a								; a=0
				sub			(hl)						; Invert
				ld			(hl),a
SMROW02:
#ENDIF

				inc			hl							; +2 = X Pos
				ld			(hl),d
				inc			hl							; +3 = Y flags
				inc			hl							; +4 = Delta Y
				inc			hl							; +5 = Y Pos
				ld			a,e
				and			$DF							; $00/$00/$40/$40/$80/$80/$C0/$C0
				rra											; $00/$00/$20/$20/$40/$40/$60/$60
				add			a,$50						; $50/$50/$70/$70/$90/$90/$B0/$B0
				ld			(hl),a
				inc			hl							; +6 = ???
				inc			hl							; +7 = ROM LSB
				ld			(hl),MINE&$FF
				inc			hl							; +8 = ROM MSB
				ld			(hl),MINE>>8

				ld			a,c							; Restore a
				ld			bc,MINC-$08			; At $08, advance to $0d
				add			hl,bc
				ld			c,a							; Stash a

				ld			a,d							; X Pos
				add			a,$50						; +$50
				ld			d,a

				ld			a,e
				add			a,$20						; Next mine
				jp			nz,SMLOOP
#ENDIF

				;; Fresh water
				ld			hl,L0F04				; Water
				ld			de,WAVLOC				; Screen location
				ld			a,$20						; Length
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
				ret

#IF SC3DIG
				;; Check free play
CHKFP:
				in			a,($02)					; IN1 (DIPs)
				and			$04
				ret			z

				ld			(CREDIT),a			; 4 credits
				ret
#ENDIF

				;; Handle coin
HCOIN:
				ret			z								; No coin
				ld			a,$20						; Sound bit 5
				out			($05),a					; Audio outputs
				ld			a,$0F
				ld			(ATIMER),a			; Set timer

#IF SC3DIG
				ld			hl,CREDIT				; Credits
				inc			(hl)						; Add credit

				ld			de,$3833				; Screen location
				ld			hl,LTPUSH				; PRESS START
				ld			a,$0B						; Length
				jp			L0B30						; Draw string hl @ de, length a
				ret
#ELSE
				ld			a,(IN1)					; Last IN1
				ld			b,a
				ld			hl,HCREDIT			; Half credits
				inc			(hl)						; Increment
				and			$04							; DSW2 = coinage
				jp			z,L08E2

				ld			a,(hl)
				rrca
				ret			c								; Only 1 half credit

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
#ENDIF


HPUSH:
				ret			z
				ld			a,(GTIME)				; Game time
				and			a
				ret			nz							; Skip if game active

#IF SC3DIG
				call		CHKFP
#ENDIF
				ld			hl,CREDIT				; Credits?
				ld			a,(hl)
				and			a

#IF SC3DIG
				ret			z
#ELSE
				jp			z,L091A					; No credits, ignore start
#ENDIF

L0906:
				dec			(hl)
				in			a,($01)					; IN1

#IF OLDDIP
				rlca										; 65432107
				rlca										; 54321076
				and			$03							; Game time dips =
				ld			de,LDTIME				; $0F54 
				add			a,e							; Index into table
				ld			e,a
				ld			a,(de)
#ELSE
#IF SEAMISS
				rlca										; 65432107
				rlca										; 54321076
				rlca										; 43210765
				and			$06							; Miss DIPs
				add			a,$10						; $10/$12/$14/$16
#ELSE
				rrca										; 076543210
				rrca										; 107654321
				and			$30							; Game time DIPs
				add			a,$61						; $61/$71/$81/$91
#ENDIF
#ENDIF

				ld			(GTIME),a				; Store time
				ld			($202A),a				; Store time

#IF SEAMISS
				xor			a
				ld			(MISSED),a			; Clear missed flag
#ENDIF

				ret

#IF 1-SC3DIG
				;; 	(original code, not used for 3 dig)?
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
#ENDIF


				;; $2000 at reset
				;; Attract mode loop

				;; Clear 1 char for unknown reason
L0929:
				.db			$04							; Command 4 = String
				.db			$01							; Length
				.dw			LTBLANK					; String src address
				.dw			$3E30						; Screen dst address

				;; INSERT COIN or PUSH BUTTOM
				.db			$09							; Commnad 9
				.dw			CREDIT					; ($2005) -> a   (select string)
				.dw			$3833						; Location
				.dw			LTCOIN					; "Insert Coin"
				.dw			LTPUSH					; "Push Button"

				;; HIGH SCORE / YOUR SCORE
				.db			$04							; Command 4 = String
#IF SC3DIG
				.db			$1B							; Length
#ELSE
				.db			$1A							; Length
#ENDIF
				.dw			LTHIGH					; String src address
				.dw			$3C02						; Screen dst address

				;; Draw high score
				.db			$0A							; Command A = BCD @ loc
				.dw			HSCORE					; bc = 2006 = high score
#IF OLDINT
				.dw			TXTBUF					; Buffer loc
#ENDIF
				.dw			$3E25						; Screen loc

				;; Draw player score
				.db			$0A							; Command A = BCD @ loc
				.dw			PSCORE					; bc = 202b = score
#IF OLDINT
				.dw			TXTBUF					; Buffer loc
#ENDIF
#IF SC3DIG
				.dw			$3E36						; Screen loc
#ELSE
				.dw			$3E35						; Screen loc
#ENDIF

				;; Delay
				.db			$02							; Command 2 = arg to 2010
				.db			$0F							; arg

				;; GAME OVER
L094E:
				.db			$04							; Command 4 = String
				.db			$09							; Length
				.dw			LTOVER					; String src address
				.dw			$2C0B						; Screen dst address

				;; Delay timer
				.db			$01							; Command 1 = arg to 2011
				.db			$1E							; arg

				.db			$00							; Command 0 = Wait for $2011 timer

				;; Clear GAME OVER
				.db			$04							; Command 4 = String
				.db			$09							; Length
				.dw			LTBLANK					; String src address
				.dw			$2C0B						; Screen dst address

				;; Delay timer
				.db			$01							; Command 1 = arg to 2011
				.db			$1E							; arg

				.db			$00							; Command 0 = Wait for $2011 timer

				;; Loop
				.db			$06							; Command 6 = Set ($2000)
				.dw			L094E						; Next command address

				;; End of game
L0963:
				.db			$03							; Do end of game sequence

				;; SEA WOLF
				.db			$04							; Command 4 = String
				.db			$08							; Length
				.dw			LTSEA						; String src address (SEA WOLF)
				.dw			$2C0C						; Screen dst address

				;; HIGH SCORE / YOUR SCORE
				.db			$04							; Command 4 = String
				.db			$0A							; Length
				.dw			LTHIGH					; String src address (HIGH SCORE)
				.dw			$3C02						; Screen dst address

				;; Draw high score
				.db			$0A							; Command A = BCD @ loc
				.dw			HSCORE					; bc = 2006 = high score
#IF OLDINT
				.dw			TXTBUF					; Buffer loc
#ENDIF
				.dw			$3E25						; Screen loc

				;; INSERT COIN / PUSH BUTTOM
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
				.db			$01							; $01 = Delta x
				.db			$C4							; $C4 = Flags (Ship 4, active)

				;; Delay
				.db			$01							; Command 1 = arg to 2011
				.db			$5A							; arg

				.db			$00							; Command 0 = Wait for $2011 timer

				;; Launch missile in attract
				.db			$08							; Command 8 (Data backwards to loc)
				.db			$09							; Count
				.dw			$20EF						; de = $20EF
				.dw			SHOT0						; $0E75 = Shot address
				.db			$9C							; $9C = ???
				.db			$E0							; $E0 = Y Pos
				.db			$FA							; $FA = Delta y
				.db			$00							; $00 = Y flags
				.db			$A8							; $A8 = X pos
				.db			$00							; $00 = Delta X
				.db			$C0							; $C0 = Flags (Non-ship, active)

				;; Delay
				.db			$01							; Command 1 = arg to 2011
				.db			$B4							; arg

				.db			$00							; Command 0 = Wait for $2011 timer

				;; Loop
				.db			$06							; Command 6 = Set ($2000)
				.dw			L0963						; Next command address


				;; Game play control loop
L09A6:
				;; Delay timer
				.db			$01							; Command 1 = arg to 2011
				.db			$0F							; arg

				.db			$00							; Command 0 = Wait for $2011 timer

				.db			$03							; Command 3 = End game

				;; TIME / SCORE
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

#IF OLDINT
				.db			$0B							; Command B = Write $2029
#ELSE
				.db			$05							; Command 5 = Write $2029
#ENDIF

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
#IF OLDINT
				.dw			JTBL5						; 5 = 0AED = (Not used)
#ELSE
				.dw			JTBLB						; 5 = 086D = LSBs of $2003 to $2029 (?)
#ENDIF
				.dw			JTBL6						; 6 = 0B86 = (de) -> $2000 
				.dw			JTBL7						; 7 = 0AE1 = val -> addr
				.dw			JTBL8						; 8 = 0A9F = Arg to loc
				.dw			JTBL9						; 9 = 0ABC = Select String
				.dw			JTBLA						; A = 0A53 = BCD @ location
#IF OLDINT
				.dw			JTBLB						; B = 086D = LSBs of $2003 to $2029 (?)
#ENDIF

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


				;; a = loop counter
				;; Copy a bytes from (hl) to (bc)
				;; OR   a bytes from (hl) to 
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
				ld			hl,RINC					; Row increment
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
				ld			bc,RINC					; Row increment
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
				ld			bc,RINC					; Row increment
				add			hl,bc
				pop			bc
				dec			b
				jp			nz,L0A40				; Loop for row

				ret


				;; $09E8 Entry A
				;; Print high score / player score
JTBLA:													; $0A53
				ex			de,hl

#IF GETMAC
				call		GETBC
#ELSE
				ld			c,(hl)					; Read bc (address of score)
				inc			hl
				ld			b,(hl)
				inc			hl
#ENDIF

#IF OLDINT
				ld			e,(hl)					; Read de
				inc			hl
				ld			d,(hl)
				dec			hl							; Back up to use de again
#ELSE
				ld			de,TXTBUF				; This was a constant
				push		de							; Store TXTBUF
#ENDIF

#IF SC3DIG
				call		BCD300					; 3 nybble BCD+00 to string
				call		GETDE						; (hl, hl+1) -> de, hl+=2
#ELSE
				call		L0A82						; Draw BCD from bc at buffer at de
				ex			de,hl						; Last address now in hl
				call		L0A7A						; Replace space with zero
				inc			hl
				ex			de,hl						; Last address now in de
				ld			a,$30
				ld			(de),a					; Append zero
				inc			de
				ld			(de),a					; Append zero

				;; #ENDIF
				;; #IF OLDINT*(1-SC3DIG)
#IF OLDINT
				call		GETDE						; (hl, hl+1) -> de, hl+=2
				push		de
#ENDIF

				;; #IF (1-SC3DIG)
				call		GETDE						; (hl, hl+1) -> de, hl+=2
#ENDIF

				ld			(PRGPTR),hl			; Next command 
				pop			hl
#IF SC3DIG
				ld			a,$05						; Length for 5 digit
#ELSE
				ld			a,$04						; Length
#ENDIF
				jp			L0B30						; Draw string hl @ de, length a


#IF SC3DIG
				;; 3 digit BCD from bc to de
				;; #?? -> #00
				;; 0#? -> _#0
				;; 00# -> __#
				;; 000 -> ___
BCD3:
				inc			bc							; To high byte
				ld			a,(bc)
				and			$0F
				jp			nz,BCD3NZ

				ld			a,$40						; Space
				ld			(de),a					; Store
				inc			de
				dec			bc							; To Low byte

				ld			a,(bc)
				and			$F0
				jp			nz,BCD2_0				; High byte non-zero
				jp			BCD2__					; High byte zero

BCD3NZ:
				add			a,$30						; To ASCII
				ld			(de),a					; Store digit
				inc			de
				dec			bc							; To Low byte
				;; Continue with 2 leading zeros

				;; 2 digit BCD with 2 leading zeros
BCD200:
				ex			de,hl
				ld			(hl),$30				; 0
				jp			BCD2_0X

				;; 2 digit BCD with no leading zeros
BCD2__:
				ex			de,hl
				ld			(hl),$40				; Space
				inc			hl
				ld			(hl),$40				; Space
				jp			BCD2

				;; 2 digit BCD with 1 leading zero
BCD2_0:
				ex			de,hl
				ld			(hl),$40				; Space
BCD2_0X:
				inc			hl
				ld			(hl),$30				; 0
				jp			BCD2

				;; Common routine
BCD2:
				dec			hl
				ex			de,hl						; Undo swap

				;; Do MSB
				ld			a,(bc)					; Get BCD
				rra
				rra
				rra
				rra
				call		BCDDIG

				;; Do LSB
				ld			a,(bc)					; Get BCD
BCDDIG:
				and			$0F							; Mask high nybble
				jp			z,BCDDONE

				add			a,$30						; Decimal to ascii
				ld			(de),a					; Store digit

BCDDONE:
				inc			de
				ret


				;; 3 nybble BCD with trailing zeros
BCD300:
				call		BCD3

				;; Append zeros
ADD00:
				ld			a,$30
				ld			(de),a					; Append 0
				inc			de
				ld			(de),a					; Append 0
				ret

#ELSE
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
#ENDIF


				;; $09E8 Entry 8 -- Copy data from sequence to address (backwards)
JTBL8:													; $0A9F
				ex			de,hl						; Sequence address back to hl
				ld			b,(hl)					; Get count
				inc			hl
				dec			b
				dec			b
				call		GETDE						; (hl, hl+1) -> de, hl+=2  (address)
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
				ld			(PRGPTR),hl			; Next command
				ret

				;; $09E8 Entry 9 -- Draw INSERT COIN or PUSH BUTTON
JTBL9:													; $0ABC
				ex			de,hl
				call		GETDE						; (hl, hl+1) -> de, hl+=2
				ld			a,(de)
				call		GETDE						; (hl, hl+1) -> de, hl+=2
				push		de							; Screen loc to stack
				call		GETDE						; (hl, hl+1) -> de, hl+=2
				push		de							; 1st string pointer to stack
				call		GETDE						; (hl, hl+1) -> de, hl+=2
				ld			(PRGPTR),hl			; Next command

				ex			de,hl
				and			a
				jp			z,L0AD5					; Draw first string?
				ex			(sp),hl					; Swap 2nd pointer w/ 1st

L0AD5:
				pop			hl							; String pointer
				pop			de							; Screen location
				ld			a,$0B						; Length
				jp			L0B30						; Draw string hl @ de, length a

				;; (hl, hl+1) -> de, hl+=2
GETDE:
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

#IF GETMAC
				call		GETBC
#ELSE
				ld			c,(hl)					; Next entry
				inc			hl
				ld			b,(hl)					; Next entry
				inc			hl
#ENDIF

				ld			(PRGPTR),hl			; Store command
				ld			(bc),a					; a -> (bc)
				ret


#IF OLDINT
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
				call		GETDE						; (hl, hl+1) -> de, hl+=2
				ld			(PRGPTR),hl			; Store command

				ex			de,hl
				ld			(hl),$DB				; ?? constant?
				inc			hl
				ld			(hl),c
				inc			hl
				ld			(hl),$C9				; ?? constant?
				dec			hl
				dec			hl
				jp			(hl)						; Jump
#ENDIF

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

				;; $09E8 Entry 4 (Draw string)
JTBL4:													; $0E22
				ex			de,hl						; 
				ld			a,(hl)					; Length
				inc			hl
				call		GETDE						; (hl, hl+1) -> de, hl+=2
				push		de
				call		GETDE						; (hl, hl,1) -> de, hl+=2
				ld			(PRGPTR),hl			; Next command
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
				ld			bc,RINC					; Row increment
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

				;; $09E8 Entry 2  (set TIMER1)
JTBL2:													; $0B72
				ex			de,hl
				ld			a,(hl)					; Argument
				inc			hl
				ld			(PRGPTR),hl			; Next command
				ld			(TIMER1),a			; Store arg
				ret

				;; $09E8 Entry 1 (set TIMER2)
JTBL1:													; $0B7C
				ex			de,hl
				ld			a,(hl)					; Argument
				inc			hl
				ld			(PRGPTR),hl			; Next command
				ld			(TIMER2),a			; Store arg
				ret

				;; $09E8 Entry 6 (de) -> $2000
JTBL6:													; $0B86
				ex			de,hl
				ld			e,(hl)
				inc			hl
				ld			d,(hl)
				ex			de,hl
				ld			(PRGPTR),hl			; Store command
				ret

				;; Character table
CHARS:													; $0B8F
#INCLUDE "swfont.asm"


				;; Sprites
GFX:														; $0D3D
#INCLUDE "swgfx.asm"


				;; Table for $07CF
MINEEXP:																									; $0EB5
				.db			$3D, $3E, $3F															; Mine explosion

LTBLANK:																									; $0EB8
				.db			"@@@@@@@@@@@"															; ___________

LTOVER:																										; $0EC3
				.db			"GAME@OVER"																; GAME_OVER

LTHIGH:																										; $0ECC 
				.db			"HIGH@SCORE"															; HIGH_SCORE
#IF SC3DIG
				.db			"@@@@@@@"																	; _______
#ELSE
				.db			"@@@@@@"																	; ______
#ENDIF
				.db			"YOUR@SCORE"															; YOUR_SCORE

LTCOIN:																										; $0EE6
				.db			"INSERT@COIN"															; INSERT_COIN

LTPUSH:																										; $0EF1
#IF SC3DIG
				.db			"PRESS@START"															; PRESS_START
#ELSE
				.db			"PUSH@BUTTON"															; PUSH_BUTTON
#ENDIF

LTSEA:																										; $0EFC
#IF SW2024
				.db			"SEAWOLFQ"																; SEAWOLF24
#ELSE
				.db			"SEA@WOLF"																; SEA_WOLF
#ENDIF

				;; Water
L0F04:
				.db			$3A, $3B, $3C, $3B, $3C, $3A, $3B, $3C		; All
				.db			$3A, $3C, $3B, $3C, $3A, $3B, $3A, $3C		; Water
				.db			$3B, $3A, $3C, $3A, $3B, $3C, $3A, $3C		; Codes
				.db			$3B, $3C, $3A, $3B, $3C, $3A, $3B, $3C		; Here

#IF OLDINT
LTBONUS:																									; $0F24 
				.db			"BONUS"																		; BONUS
#ENDIF

LTTIME:																										; $0F29
#IF SEAMISS
				.db			"MISS"																		; MISS
#ELSE
				.db			"TIME"																		; TIME
#ENDIF
#IF SC3DIG
				.db			$2C																				; <space>
#ELSE
				.db			$2D																				; <space>
#ENDIF
				.db			"SCORE"																		; SCORE

LTEXT:																					; $0F33 
				.db			"EXTENDED"																; EXTENDED
				.db			$16																				; <space>
#IF SC3DIG
				.db			"PLAY"																		; PLAY
#ELSE
				.db			"TIME"																		; TIME
#ENDIF

#IF OLDINT
				;; Addresses of mine hit data
TEMINE:
				.dw			TZAP																			; ZAP
				.dw			TWAM																			; WAM
#ENDIF

TZAP:
				.db			$01, "A", $04, $3D, "Z", $2F, "P", $3F		; *ZAP*
TWAM:
				.db			$01, "A", $04, $3D, "W", $2F, "M", $3F		; *WAM*

#IF MOREEXP
TPOW:
				.db			$01, "O", $04, $3D, "P", $2F, "W", $3F		; *POW*
TOOF:
				.db			$01, "O", $04, $3D, "O", $2F, "F", $3F		; *OOF*
#ENDIF

#IF OLDDIP
				;; 4-byte table (time per credit)
LDTIME:																										; $0F54
				.db			$61, $71, $81, $91												; (Seconds)
#ENDIF

				;; $0F57 = 8-byte score table (0,7 not used)
TSCORE:																										; $0F58
				.db			$03, $03, $03, $01, $01, $07							; 

				;; Table for $05D2 (0x20 long)
				;; Periscope grey code decode
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

#IF DOCOPY
COPYRGHT:
				.db			"MSPAETH@2024"
#ENDIF

#IF OLDTEST
				.org		$0fff
				.db			$ff
#ELSE
				.org		$0ff7

				;; $400 block checksums
				;; Recalculate these with 'swaddchk'
				.db			$9A											; Patch byte for $c00 checksum
CHKS:
				.db			$EC, $3C, $10, $00			; Checksums

				;; Error locations
ERRS:
				.db			$48, $47, $46, $45			; HGFE
#ENDIF

.end
