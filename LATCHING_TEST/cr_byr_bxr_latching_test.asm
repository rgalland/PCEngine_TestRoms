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

TOP_BYR  	= $005A
BOT_BYR  	= $005E

LFT_BXR  	= $0008

CR_BGON		= $00CC
CR_BGOFF	= $004C


BYRB_TEST   = $01
BYRA_TEST   = $02
BXRB_TEST   = $03
BXRA_TEST   = $04
CRB_TEST    = $05
CRA_TEST    = $06

;PAD 
PAD_UP		= $10
PAD_RIGHT	= $20
PAD_DOWN	= $40
PAD_LEFT	= $80
PAD_I		= $01
PAD_II 		= $02


NOP_ARRAY_LEN = $06
NOPS_MAX      = $09	; 10 possible values


ASCII_VRAM	= $1000
HEX_VRAM	= ASCII_VRAM+$100
BONKBG_VRAM	= $2000
BONKSP_VRAM	= $3000

SATB_VRAM	= $0F00		;where to put the Sprite Table in VRAM

BATWIDTH	= 32	;Set to 32, 64, or 128
BATHEIGHT	= 32	;Set to 32 or 64.



; Zero-page variables
	.zp
hsync_line:	.ds 2
test_nb:	.ds 1
pad_prev:   .ds 1
pad_cur:    .ds 1
nop_count:  .ds 6	; array of 6 values
nop_index:  .ds 1	; index nop_count array	0-5
nop_pos:    .ds 2	; getvalues from nop pos array


;==============================
	.code
	.bank	$0
	.org	$E000


MAIN:
	INTS_OFF		;DISABLE INTERRUPTS!
	
	stz <nop_index
	ldx #NOP_ARRAY_LEN

.clear_nop_count_array	
	dex
	stz <nop_count, x
	bne .clear_nop_count_array	
	
	stz <pad_prev
	stz	<test_nb
	stw	#BYRB_LINE,<hsync_line

	map	BonkBG
	vload	BONKBG_VRAM, BonkBG, $1000
	map		MyFont
	vload	ASCII_VRAM, MyFont, $0800
	vload	BONKSP_VRAM, SprCHR, $0200	;Load 2 32x32 sprites

	set_bgpal 	#0, FontPal, #2
	set_sprpal 	#0, SPRPal, #1

	jsr	Clear_BAT

	stw	#Intro_Text,<_si ;Point to text string
	stw	#$0020,<_di	 ;Point on-screen
	jsr	Print_Text

	jsr	Draw_BonkBG


	BG_GREEN
	BORD_BLUE
	SCREEN_ON

	vreg	#6	;RCR
	stw		#BYRB_LINE,video_data
	

.loop            	;Here's an infinite loop...
	bra	.loop


MY_VSYNC:
	BORD_RED
	pha
	pla
	pha
	pla
	BORD_BLUE

	stw	#$007C,<_di
	jsr	set_write
	lda	<hsync_line+1
	jsr	Print_Nyb
	lda	<hsync_line
	jsr	Print_Byte

	; set RCR ready for next frame
	vreg	#6	;RCR	
	stw 	#BYRB_LINE,video_data

	; reset BYR
	vreg	#8	;BYR
	stwz	video_data
	
	; reset BXR
	vreg	#7	;BXR
	stwz	video_data
	
	; reenable BG
	vreg	#5	;CR
	stw		#CR_BGON,video_data
	
	stz	<test_nb
	

; pad reg $1000
;SEL = 0                SEL = 1
;D3 :   Run             Left
;D2 :   Select          Down
;D1 :   Button II       Right
;D0 :   Button I        Up	
;read pad
; read pad direction
	ldx #$01
	stx $1000
	ldx #$03
	stx $1000
	ldx #$01
	stx $1000
	lda $1000
	asl a
	asl a
	asl a
	asl a
	sta <pad_cur
; read pad buttons
	clx
	stx $1000
	ldx #$02
	stx $1000
	clx
	stx $1000
	lda $1000
	and #$0F
	ora <pad_cur
	eor #$FF 
	sta <pad_cur
; detect changes and only 0 to 1 transitions
	eor <pad_prev
	bne .check_btns
	rts
.check_btns	
	and <pad_cur
	ldx <pad_cur
	stx <pad_prev
	ldx <nop_index
	ldy <nop_count, x
.check_btn_1	
	cmp #PAD_I
	bne .check_btn_2
	cpy #NOPS_MAX
	beq .check_btn_2
	inc <nop_count, x	 
.check_btn_2	
	cmp #PAD_II
	bne .check_btn_up
	cpy #$00
	beq .check_btn_up
	dec <nop_count, x
.check_btn_up
	cmp #PAD_UP
	bne .check_btn_down
	cpx #NOP_ARRAY_LEN - 1
	beq .check_btn_down
	inc <nop_index
.check_btn_down
	cmp #PAD_DOWN
	bne .end_btn_checks
	cpx #$00
	beq .end_btn_checks
	dec <nop_index

; check right	
	cmp #PAD_RIGHT

; check left	
	cmp #PAD_LEFT
		
	
.end_btn_checks

	;stw	#$007D,<_di
	;jsr	set_write
	;lda	<nop_count
	;jsr	Print_Byte

; change value of the position pointed at
; get value from pos array
	lda <nop_index
	asl a
	sax
	lda nop_pos_array,x
	sta <nop_pos  
	inx
	lda nop_pos_array,x
	sta <nop_pos + 1  
; apply new value to position
	ldx <nop_index
	stw	<nop_pos,<_di
	jsr	set_write
	lda	<nop_count,x
	jsr	Print_Byte
	
	rts


MY_HSYNC:
	BORD_WHITE
	;BG_CYAN
	; load current test_nb value and inc for next time
	inc 	<test_nb
	lda 	<test_nb
	cmp 	#BYRB_TEST
	bne 	.check_test2
	jmp		START_TEST1	 
.check_test2	
	cmp 	#BYRA_TEST
	bne 	.check_test3
	jmp		START_TEST2	 
.check_test3	
	cmp 	#BXRB_TEST
	bne 	.check_test4
	jmp		START_TEST3	 
.check_test4	
	cmp 	#BXRA_TEST
	bne 	.check_test5
	jmp		START_TEST4	 
.check_test5	
	cmp 	#CRB_TEST
	bne 	.check_test6
	jmp		START_TEST5	 
.check_test6	
	cmp 	#CRA_TEST
	bne 	.close_test_session
	jmp		START_TEST6	 
.close_test_session
	;end of visible region
	ldx #$3B
.grey_line_delay
	dex
	bne .grey_line_delay 
	BG_CYAN
	ldx #$48
.blue_line_delay
	dex
	bne .blue_line_delay 
	BG_DKGRN
	; disable BG
	vreg	#5	;CR
	stw		#CR_BGOFF,video_data
	rts		; leave int
	
;BYR Before test
START_TEST1:
	BG_CYAN
	vreg	#6	;RCR
	stw		#BYRA_LINE,video_data
	BORD_DKBLU
	; 455 cpu cycles per scanline
	; adjust BYR to hide the red box 
	ldx #$27	;	0x30 gives 1 * 4 cy (no loop) + 0x2F * 6 cy (loops) = 286 cy  
.byrb_delay
	dex
	bne .byrb_delay 
	
	;reset BYR, add nops. Reenable just before latching in second part
	vreg	#8	;BYR
	stwz	video_data
	nop
	nop
	nop	
	BG_GREY2
	lda <nop_count	 
	jmp INSERT_NOPS

;BYR After test
START_TEST2:
	vreg	#6	;RCR
	stw		#BXRB_LINE,video_data
	ldx #$35
.byra_delay
	dex
	bne .byra_delay 
	
	;leave BYR as it is. Add incorrect value in second part
	nop
	nop
	nop	
	BG_CYAN
	lda <nop_count + 1	 
	jmp INSERT_NOPS

;BXR Before test
START_TEST3:
	vreg	#6	;RCR
	stw		#BXRA_LINE,video_data
	ldx #$2E
.bxrb_delay
	dex
	bne .bxrb_delay 
	
	;add BXR offset, add nop. Reset offset just before latching in second part
	vreg	#7	;BXR
	stw		#LFT_BXR,video_data
	nop
	nop
	nop	
	BG_GREY2
	lda <nop_count + 2	 
	jmp INSERT_NOPS

;BXR After test
START_TEST4:
	vreg	#6	;RCR
	stw		#CRB_LINE,video_data
	ldx #$31
.bxra_delay
	dex
	bne .bxra_delay 
	
	;leave BXR as it is. Add incorrect value in second part
	nop
	nop
	nop	
	BG_CYAN
	lda <nop_count + 3	 
	jmp INSERT_NOPS

;CR Before test
START_TEST5:
	vreg	#6	;RCR
	stw		#CRA_LINE,video_data
	ldx #$24
.crb_delay
	dex
	bne .crb_delay 
	; apply new BYR value to stop at bottom of red box	
	vreg	#8	;BYR
	stw		#TOP_BYR,video_data

	;disable BG in CR, add nops. Renable bg in second part
	vreg	#5	;CR
	stw		#CR_BGOFF,video_data
	nop
	nop
	nop
	nop	
	nop	
	BG_GREY2
	lda <nop_count + 4	 
	jmp INSERT_NOPS

;CR After test
START_TEST6:
	vreg	#6	;RCR
	stw		#BOT_LINE,video_data
	ldx #$2C
.cra_delay
	dex
	bne .cra_delay 
	;leave CR as it is. Add incorrect value in second part
	nop	
	nop
	nop
	nop	
	BG_CYAN
	lda <nop_count + 5	 
	jmp INSERT_NOPS

RESUME_TESTING:	
	lda 	<test_nb
	cmp 	#BYRB_TEST
	bne 	.check_test2
	jmp		END_TEST1	 
.check_test2	
	cmp 	#BYRA_TEST
	bne 	.check_test3
	jmp		END_TEST2	 
.check_test3	
	cmp 	#BXRB_TEST
	bne 	.check_test4
	jmp		END_TEST3	 
.check_test4	
	cmp 	#BXRA_TEST
	bne 	.check_test5
	jmp		END_TEST4	 
.check_test5	
	cmp 	#CRB_TEST
	bne 	.check_test6
	jmp		END_TEST5	 
.check_test6	
	cmp 	#CRA_TEST
	bne 	.close_test_session
	jmp		END_TEST6	 
.close_test_session
	rts		; we should never get here in teory

END_TEST1:
	;Reenable just before latching in second part
	vreg	#8	;BYR
	stw		#TOP_BYR,video_data
	rts
END_TEST2:
	;Add incorrect value in second part, a few nops and renable
	vreg	#8	;BYR
	stwz	video_data
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	vreg	#8	;BYR
	stw		#BOT_BYR,video_data
	rts
END_TEST3:
	;Reset offset just before latching in second part
	vreg	#7	;BXR
	stw		#$0000,video_data
	rts
END_TEST4:
	;Add incorrect value in second part, a few nops and correct it again
	vreg	#7	;BXR
	stw	    #LFT_BXR,video_data
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	vreg	#7	;BXR
	stw		#$0000,video_data
	rts
END_TEST5:
	;Renable offset in second part
	vreg	#5	;CR
	stw		#CR_BGON,video_data
	rts
END_TEST6:
	;Add incorrect value in second part
	vreg	#5	;CR
	stw		#CR_BGOFF,video_data
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	;Renable offset in second part
	vreg	#5	;CR
	stw		#CR_BGON,video_data
	rts
	
INSERT_NOPS:	; load acc with corresponding number of nops for the test  	
	; jump to routine corresponding to number of nops
	asl a
	sax	
	jmp [cycle_routine_array,x]	;WRONG as RTS does not work
	
EIGHT_NOPS:
	nop		;2cycles
SIX_NOPS:
	nop		;2cycles
FOUR_NOPS:
	nop		;2cycles
TWO_NOPS:
	nop		;2cycles
ZERO_NOPS:
	nop		;2cycles
	jmp RESUME_TESTING

NINE_NOPS:
	nop		;2cycles
SEVEN_NOPS:
	nop		;2cycles
FIVE_NOPS:
	nop		;2cycles
THREE_NOPS:
	nop		;2cycles
ONE_NOP:
	sax  	;3cycles
	jmp RESUME_TESTING

cycle_routine_array:
	.dw ZERO_NOPS, ONE_NOP, TWO_NOPS, THREE_NOPS, FOUR_NOPS, FIVE_NOPS,\
		SIX_NOPS, SEVEN_NOPS, EIGHT_NOPS, NINE_NOPS


nop_pos_array:
	.dw $00A2, $00A7, $00AD, $00B2, $00B8, $00BD 


Intro_Text:
     ;0123456789ABCDEF0123456789ABCDEF
 .db " - BYR, BXR, CR LATCH TEST -    "
 .db "ADJUST CYCLES BEFORE OR AFTER   "
 .db "LATCHING.               RCR=XXX "
 .db "   BYR        BXR        CR     "
 .db "B<00>A<00> B<00>A<00> B<00>A<00>",0


;============================================================
; Other includes / banks go here (for now)

	.include "INCLUDE/gfx_work.asm"

;============================================================
;============================================================

	.bank $2
	.org $4000
MyFont: .incchr "INCLUDE/parofont.pcx"
SprCHR: .incspr "INCLUDE/bonkSP.pcx"

FontPal: .incpal "INCLUDE/parofont.pcx",0,1
BonkPal: .incpal "INCLUDE/bonkBG.pcx",0,1
SPRPal:	 .incpal "INCLUDE/bonkSP.pcx",0,1


	.bank $3
	.org $4000
BonkBG: .incchr "INCLUDE/bonkBG.pcx"
