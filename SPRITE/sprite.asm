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
PAL_LEN      = 1
;BG_MAP_ADDR	 = $0000
;BG_MAP_LEN 	 = $3FFF	; will require 2 banks in ROM
SP_VRAM_ADDR = $4000
SP_VRAM_LEN  = $768
SATB_ADDR    = $7F00

; tilemap dimensions
BATWIDTH	= 32	;Set to 32, 64, or 128
BATHEIGHT	= 32	;Set to 32 or 64.

;SCREEN_HEIGHT = 224	; physical screen height i.e number of scanlines
;SCREEN_WIDTH  = 256	; physical screen height i.e number of scanlines
;TILE_W		= 8
;TILE_H		= 8

; sprite constants
MIN_X		= $20	; Minimum xpos for spr
MAX_X		= $100	; Maximum xpos for spr
MIN_Y		= $40	; Minimum ypos for spr
MAX_Y		= $F0	; Maximum ypos for spr

SPRITE_TILE_Y = $10
SPRITE_TILE_X = $10
SPRITE_PATTERN_ADDR = SP_VRAM_ADDR >> 5


; unused but called in subroutines
ASCII_VRAM    = $0000
HEX_VRAM      = ASCII_VRAM+$100

; Zero-page variables
	.zp
pad_prev:   .ds 1
pad_cur:    .ds 1
xpos:		.ds 2
ypos:		.ds 2
spx:		.ds 2
spy:		.ds 2
next_spx:   .ds 2
next_spy:   .ds 2

;Higher RAM variables
	.bss
satb:		.ds 512	;Sprite Attribute Table Buffer

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

	; palette and sprite tiles stored in 1 bank
	map	SpritePal
	set_sprpal 	#$0, SpritePal, #PAL_LEN
	
	; tia to transfer $4620 bytes from rom to vram
	; set MAWR to 0 and then switch to VRAM DATA reg 
	st0 #$0
	st1 #LOW(SP_VRAM_ADDR)
	st2 #HIGH(SP_VRAM_ADDR)
	st0 #$2
	
	tia SpriteTiles, $2, SP_VRAM_LEN
	
	; sprite #0 rough in the centre of the screen 
	; init sprite pos
	lda #128
	sta spx
	stz spx+1
	lda #112
	sta spy
	sta next_spy
	stz spy+1
	stz next_spy+1

	stz	satb	;zero out sprite table
	tii	satb,satb+1,511
	
	; loop 3 times to copy data in satb copy in RAM for sprite made of 3 32x16 sprites
	ldx #$0	
load_sprite_table:
	lda next_spy
	sta satb,x		; yl pos
	lda next_spy+1
	sta satb+1,x	; yh pos
	lda spx
	sta satb+2,x	; xl pos
	lda spx+1
	sta satb+3,x	; xh pos
	txa
	lsr
	adc #LOW(SPRITE_PATTERN_ADDR)
	sta satb+4,x	; pattern al
	lda #HIGH(SPRITE_PATTERN_ADDR)
	sta satb+5,x	; pattern ah
	stz satb+6,x	; attr al
	lda #$1
	sta satb+7,x	; attr ah x = 32
	clc
	; increase y offset
	lda next_spy
	adc #SPRITE_TILE_Y
	sta next_spy
	lda next_spy+1
	adc #0
	sta next_spy+1
	txa
	adc #$8
	tax	
	cmp #8*3 
	bne load_sprite_table

	jsr copy_satb_to_vram
	
	; enable sprite automatic update	
	st0 #$F		; DCR index in VDC
	st1 #$10	; start auto sprite DMA 
	
	BORD_BLUE
	SCREEN_ON

.loop            	;Here's an infinite loop...
	bra	.loop



copy_satb_to_vram:
	; write sat table to 7F00 in VRAM
	st0 #$0	; addr reg in VDC
	st1 #LOW(SATB_ADDR)
	st2 #HIGH(SATB_ADDR)
	st0 #$2	; data rw reg in VDC
	tia satb, $2, 512
	rts


	

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
	sta pad_prev
	and #$F0			;only check directions
	bne test_PAD_DOWN
	rts
	
test_PAD_DOWN:
	lda pad_cur
	bit #PAD_DOWN
	beq test_PAD_UP
	lda satb	;	yl 
	cmp #MAX_Y
	bcs	test_PAD_UP	;
	inc satb+8*0
	; TODO fix issue when sprite get to the bottom as they disappear
	inc satb+8*1
	inc satb+8*2
	
test_PAD_UP:
	lda pad_cur
	bit #PAD_UP
	beq test_PAD_RIGHT
	lda satb	;	yl 
	cmp #MIN_Y
	beq	test_PAD_RIGHT	;
	dec satb+8*0
	dec satb+8*1
	dec satb+8*2
	
test_PAD_RIGHT:
	lda pad_cur
	bit #PAD_RIGHT
	beq test_PAD_LEFT
	lda satb+3	;	xh 
	bne test_PAD_LEFT	; MAX_X	= $100	; Maximum xpos for spr
	inc satb+2+8*0	; xl
	inc satb+2+8*1
	inc satb+2+8*2
	bne test_PAD_LEFT
	inc satb+3+8*0	; xh
	inc satb+3+8*1
	inc satb+3+8*2
			
test_PAD_LEFT:	
	lda pad_cur
	bit #PAD_LEFT
	beq update_vram
	sec
	lda satb+2	;	xl 
	sbc #MIN_X
	lda satb+3	;	xh
	sbc #$0
	bcc update_vram
	stz satb+3+8*0	;	xh
	stz satb+3+8*1	;	xh
	stz satb+3+8*2	;	xh
	dec satb+2+8*0	; xl
	dec satb+2+8*1
	dec satb+2+8*2

			
update_vram:
	jsr copy_satb_to_vram
	; save crrent rreading to previous reading for next interrupt
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
SpritePal: 		.incbin "graphics/robot.pal"
;SpriteTiles: 	.incbin "graphics/robot.tiles"
SpriteTiles: 	.incspr "graphics/robot.png",0,0,2,3	;x=y=0 width =2, height = 1
			;	.incspr "graphics/robot.png",0,16,2,1	;x=y=0 width =2, height = 1
			;	.incspr "graphics/robot.png",0,32,2,1	;x=y=0 width =2, height = 1



