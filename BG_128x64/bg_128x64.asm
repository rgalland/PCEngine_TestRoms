;
;  TUTORIAL.ASM  -  single Hsync moving on-screen
;

;----- HEADER & INCLUDES ----------------------
	.nolist
	.nomlist
	.include "INCLUDE/startup.asm"
	.list
	.mlist
;--------------- END INCLUDES ------------------

;PAD 
PAD_LEFT	= $80
PAD_DOWN	= $40
PAD_RIGHT	= $20
PAD_UP		= $10
PAD_RUN 	= $08
PAD_SELECT	= $04
PAD_II 		= $02
PAD_I		= $01

; graphics cosntants
PAL_LEN      = 96 / 32
BG_MAP_ADDR	 = $0000
BG_MAP_LEN 	 = $3FFF	; will require 2 banks in ROM
BG_VRAM_ADDR = $2000
BG_VRAM_LEN  = $6920	; will require 4 banks in ROM

; tilemap dimensions
BATWIDTH	= 128	;Set to 32, 64, or 128
BATHEIGHT	= 64	;Set to 32 or 64.

SCREEN_HEIGHT = 224	; physical screen height i.e number of scanlines
SCREEN_WIDTH  = 256	; physical screen height i.e number of scanlines
TILE_W		= 8
TILE_H		= 8

MAX_X		= (BATWIDTH * TILE_W) - SCREEN_WIDTH	; Maximum value for bxr ($300) ; was $0300
MAX_Y		= (BATHEIGHT * TILE_H) - SCREEN_HEIGHT	; Maximum value for byr ($120) ; was $0100


; unused but called in subroutines
ASCII_VRAM    = $0000
HEX_VRAM      = ASCII_VRAM+$100

; Zero-page variables
	.zp
pad_prev:   .ds 1
pad_cur:    .ds 1
xpos:		.ds 2
ypos:		.ds 2



;==============================
	.code
	.bank	$0
	.org	$E000


MAIN:
	INTS_OFF		;DISABLE INTERRUPTS!
	
	
	stz pad_prev
	stwz xpos
	stz ypos
	
	jsr	Clear_BAT

	; palette stored in 1 bank
	map	BGPal
	set_bgpal 	#0, BGPal, #PAL_LEN
	
	; 128x64 map is stored in 2 banks
	map	BGMap
	map	BGMap2	
	vload		BG_MAP_ADDR, BGMap, #BG_MAP_LEN
	
	; tiles are stored in 4 banks
	map	BGTiles
	map	BGTiles2
	map	BGTiles3
	map	BGTiles4
	
	; tia to transfer $4620 bytes from rom to vram
	; set MAWR to 0 and then switch to VRAM DATA reg 
	st0 #$0
	st1 #LOW(BG_VRAM_ADDR)
	st2 #HIGH(BG_VRAM_ADDR)
	st0 #$2
	
	tia BGTiles, $2, BG_VRAM_LEN
	;vload		BG_VRAM_ADDR, BGTiles, BG_VRAM_LEN
	
	;BG_GREEN
	BORD_BLUE
	SCREEN_ON
	
	

.loop            	;Here's an infinite loop...
	bra	.loop
	

MY_VSYNC:
	lda #$0 
	sta joyport
	lda #$2 
	sta joyport
	lda joyport	; Run, Select, II, I
	and #$0F
	sta pad_cur
	lda #$1 
	sta joyport
	lda #$3 
	sta joyport	
	lda joyport	; Left, Down, Right, Up
	asl a
	asl a
	asl a
	asl a
	ora pad_cur
	eor #$FF		; invert so 1 means button pressed
	sta pad_cur
	;eor pad_prev
	;and pad_cur	; each bit set one means 0-1 transition

test_PAD_DOWN:
	lda pad_cur
	bit #PAD_DOWN
	beq test_PAD_UP
	sec		; carry should be set at the end when ypos = MAX_Y
	lda ypos
	sbc #LOW(MAX_Y)
	lda ypos+1
	sbc #HIGH(MAX_Y)
	bcs test_PAD_UP
	sec
	lda ypos
	adc #0
	sta ypos
	lda ypos+1	
	adc #0
	sta ypos+1
	setvdcreg #BYR, ypos		

test_PAD_UP:
	lda pad_cur
	bit #PAD_UP
	beq test_PAD_RIGHT
	clc		; clear carry flag to ensure that flag is cleared when ypos = ypos+1 = 0
	lda ypos
	sbc #$0
	lda ypos+1
	sbc #$0
	bcc test_PAD_RIGHT
	clc
	lda ypos
	sbc #0
	sta ypos
	lda ypos+1
	sbc #0
	sta ypos+1
	setvdcreg #BYR, ypos
	
test_PAD_RIGHT:
	lda pad_cur
	bit #PAD_RIGHT
	beq test_PAD_LEFT
	lda xpos+1
	cmp #$03
	beq test_PAD_LEFT
 	ldx xpos	
	inx
	bne .stxposr
	lda xpos+1
	inc a
	sta xpos+1
 .stxposr: 	
	stx xpos
	setvdcreg #BXR, xpos
			
test_PAD_LEFT:	
	lda pad_cur
	bit #PAD_LEFT
	beq save_pad
	ldx xpos	
	bne .stxposl
	lda xpos+1
	dec a
	cmp #$FF
	beq save_pad
	sta xpos+1
.stxposl:
	dex	
	stx xpos
	setvdcreg #BXR, xpos
			
save_pad:
	; save crrent rreading to previous reading for next interrupt
	lda pad_cur
	sta pad_prev
	rts

MY_HSYNC:
	rts


;============================================================
; Other includes / banks go here (for now)

	.include "INCLUDE/gfx_work.asm"
;============================================================
;============================================================
	.bank $1
	.org $4000
BGPal: 		.incbin "graphics/Night_1024x512.pal"

	.bank $2
	.org $4000
BGMap:		.incbin "graphics/Night_1024x512.map"

	.bank $3
	.org $6000
BGMap2:

	.bank $4
	.org $4000
BGTiles:   	.incbin "graphics/Night_1024x512.tiles"

	.bank $5
	.org $6000
BGTiles2:

	.bank $6
	.org $8000
BGTiles3:

	.bank $7
	.org $A000
BGTiles4:


