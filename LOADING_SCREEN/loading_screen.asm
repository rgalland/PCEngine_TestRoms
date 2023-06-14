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

PAL_LEN      = 32 / 32

MAP_WIDTH = 20
MAP_HEIGHT = 2
MAP_X_POS = 6
MAP_Y_POS = 13

BG_MAP_ADDR	 = MAP_X_POS + (MAP_Y_POS<<5)

BG_MAP_LEN 	 = $0028
BG_VRAM_ADDR = $0800
BG_VRAM_LEN  = $04A0

BATWIDTH	= 32	;Set to 32, 64, or 128
BATHEIGHT	= 32	;Set to 32 or 64.

; in this programme we will flash the loading screen text by changing colour 1 in VCE
; colours is GRB on 9 bits
WHITE 		= ($7<<6) | ($7<<3) | $7
YELLOW 		= ($7<<6) | ($7<<3) | $0
ORANGE 		= ($4<<6) | ($7<<3) | $0
RED 		= ($0<<6) | ($7<<3) | $0
DARK_RED 	= ($0<<6) | ($4<<3) | $0


; Zero-page variables
	.zp
frame_counter:   .ds 1


;==============================
	.code
	.bank	$0
	.org	$F800

; code must be as small as possible
BGTiles:	.incbin "graphics/loading.chr"
BGMap:		.incbin "graphics/loading.map"
BGPal: 		.incbin "graphics/loading.pal"


MAIN:
	INTS_OFF		;DISABLE INTERRUPTS!
	
	stz frame_counter
	
	jsr	Clear_BAT

	; load bg tile map, tiles and palette
	
	vload		BG_MAP_ADDR, BGMap, #BG_MAP_LEN/2
	vload		BG_MAP_ADDR+32, BGMap+BG_MAP_LEN, #BG_MAP_LEN/2
	
	set_bgpal 	#0, BGPal, #PAL_LEN
	
	; tia to transfer $4620 bytes from rom to vram
	; set MAWR to 0 and then switch to VRAM DATA reg 
	st0 #$0
	st1 #LOW(BG_VRAM_ADDR)
	st2 #HIGH(BG_VRAM_ADDR)
	st0 #$2
	
	tia BGTiles, $2, BG_VRAM_LEN
	
	BORD_BLUE
	SCREEN_ON
	
.loop            	;Here's an infinite loop...
	bra	.loop
	

MY_VSYNC:
	inc frame_counter
	lda frame_counter
	cmp #120
	bne check_frame
	stz frame_counter
	lda #$00
check_frame:
	lsr
	lsr
	lsr
	asl
	tax
	cpx #11
	bcs leave_my_vsync  
	lda	#$01
	sta	color_reg	; point at colour 1
	stz	color_reg+1	; to make sure we are changing bg colours and not sprite colours
	lda title_colour_table,x
	sta color_data
	lda title_colour_table+1,x
	sta color_data+1
	
leave_my_vsync:	rts

MY_HSYNC:
	rts


;============================================================
; Other includes / banks go here (for now)

	.include "INCLUDE/gfx_work.asm"
;============================================================
title_colour_table:
	.dw YELLOW, ORANGE, RED, DARK_RED, WHITE 
	
