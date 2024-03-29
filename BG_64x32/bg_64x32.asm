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

PAL_LEN      = 224 / 32

BG_MAP_ADDR	 = $0000
BG_MAP_LEN 	 = $0E00
BG_VRAM_ADDR = $0800
BG_VRAM_LEN  = $4620

BATWIDTH	= 64	;Set to 32, 64, or 128
BATHEIGHT	= 32	;Set to 32 or 64.

; leave this for now as used in subroutines
ASCII_VRAM    = $0000
HEX_VRAM      = ASCII_VRAM+$100

; Zero-page variables
	.zp
pad_prev:   .ds 1
pad_cur:    .ds 1
xpos:		.ds 1


;==============================
	.code
	.bank	$0
	.org	$E000


MAIN:
	INTS_OFF		;DISABLE INTERRUPTS!
	
	
	stz pad_prev
	stz xpos
	
	jsr	Clear_BAT

	; load bg tile map, tiles and palette
	map	BGPal
	map	BGTiles
	map	BGTiles2
	map	BGTiles3
	map	BGTiles4
	
	vload		BG_MAP_ADDR, BGMap, #BG_MAP_LEN
	set_bgpal 	#0, BGPal, #PAL_LEN
	
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
test_PAD_RIGHT:
	bit #PAD_RIGHT
	beq test_PAD_LEFT
	lda xpos
	inc a
	beq test_PAD_LEFT
	sta xpos
	setvdcregl #BXR, xpos		
test_PAD_LEFT:	
	lda pad_cur
	bit #PAD_LEFT
	beq save_pad
	lda xpos
	beq save_pad
	dec a
	sta xpos
	setvdcregl #BXR, xpos		
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
	.bank $2
	.org $4000
BGPal: 		.incbin "graphics/Waifu_locolor.pal"
	.org $5000
BGMap:		.incbin "graphics/Waifu_locolor.map"

	.bank $3
	.org $6000
BGTiles:   	.incbin "graphics/Waifu_locolor.chr"

	.bank $4
	.org $8000
BGTiles2:

	.bank $5
	.org $A000
BGTiles3:

	.bank $6
	.org $C000
BGTiles4:


