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

BYRB_LINE	= $0077
BYRA_LINE	= $007A
BXRB_LINE	= $007D
BXRA_LINE	= $0080
CRB_LINE	= $0086
CRA_LINE	= $008A
BOT_LINE	= $0095


TOP_BYR  	= $003F
BOT_BYR  	= $0043

LFT_BXR  	= $0008

CR_BGON		= $00CC
CR_BGOFF	= $004C


BYRB_TEST   = $00
BYRA_TEST   = $01
BXRB_TEST   = $02
BXRA_TEST   = $03
CRB_TEST    = $04
CRA_TEST    = $05

;PAD 
PAD_UP		= $10
PAD_RIGHT	= $20
PAD_DOWN	= $40
PAD_LEFT	= $80
PAD_I		= $01
PAD_II 		= $02


NOP_ARRAY_LEN = $06
NOPS_MAX      = $09	; 10 possible values

PAL_LEN      = 224 / 32

BG_MAP_ADDR	 = $0000
BG_MAP_LEN 	 = $0E00
BG_VRAM_ADDR = $0800
BG_VRAM_LEN  = $4620


BATWIDTH	= 64	;Set to 32, 64, or 128
BATHEIGHT	= 32	;Set to 32 or 64.

ASCII_VRAM      = $0000
HEX_VRAM      = ASCII_VRAM+$100

; Zero-page variables
	.zp
pad_prev:   .ds 1
pad_cur:    .ds 1


;==============================
	.code
	.bank	$0
	.org	$E000


MAIN:
	INTS_OFF		;DISABLE INTERRUPTS!
	
	
	stz <pad_prev
	
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



;BonkBG: .incchr "INCLUDE/bonkBG.pcx"
