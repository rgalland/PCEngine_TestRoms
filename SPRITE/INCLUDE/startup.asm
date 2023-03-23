	.bank $0
	.org $FE00
	.code

	.include "INCLUDE/EQU.asm"
	.include "INCLUDE/MACRO.asm"
	.include "INCLUDE/LIBRARY.ASM"
	.include "INCLUDE/LIBRARY.INC"


RESET:
	sei
	csh
	cld
	lda #$ff	;map in I/O
	tam #0
	tax
	lda #$f8	;map in RAM
	tam #1

	txs
	lda videoport
	lda #$07
	sta irq_disable	;IRQ mask, INTS OFF
	sta irq_status	;ACK TIMER
	stz timer_ctrl	;Turn off timer

	st0 #5		;Disable VDC ints, Screen OFF
	st1 #0
	st2 #0

	stz <$00
	tii $2000,$2001,$1fff

	bsr	Init_VDC

	lda #%00000101          ;IRQ2, TIMER ints OFF
	sta irq_disable		;VDC INTS ON
	vreg #5
	st1 #$CC
	cli

	jmp MAIN


;=================================================================

;*************  INIT ROUTINES  ******************************
Init_VDC:
    stw   #vdc_table,<_si 	; register table address in '_si'
	cly
.l1:
	lda   [_si],Y		; select the VDC register
	bmi	.init_end
	iny
	sta   <_vreg
	sta   video_reg
	lda   [_si],Y		; send the 16-bit data
	iny
	sta   video_data
	lda   [_si],Y
	iny
	sta   video_data+1
	bra   .l1
.init_end:

	lda  #%00000100		;Low res, Colourburst shuffling
	sta  color_ctrl		; set the pixel clock frequency
	rts

	; VDC register data
vdc_table:
 ;	.db $05,$00,$00		; CR    control register
	.db $06,$00,$00		; RCR   scanline interrupt counter
	.db $07,$00,$00		; BXR   background horizontal scroll offset
	.db $08,$00,$00		; BYR        "     vertical     "      "
	.db $09
	    .db ((BATWIDTH/64)<<4)+((BATHEIGHT/64)<<6)
	        .db $00		; MWR   size of the virtual screen
	.db $0A,$02,$02		; HSR +                 [$02,$02]
	.db $0B,$1F,$04		; HDR | display size    [$1F,$04]
	.db $0C,$07,$0D		; VPR |
	.db $0D,$DF,$00		; VDW | $DF gives 224 lines
	.db $0E,$03,$00		; VCR +
	.db $0F,$00,$00		; DCR   DMA control register
	.db $13
		.db LOW(SATB_ADDR)
			.db HIGH(SATB_ADDR)
;	.dw SATB_VRAM		; SATB  address of the SATB
	.db -1			; end of table!

;---------------------------------------------------------------





;!!!!!!!!!!!!!! INTERRUPT ROUTINES !!!!!!!!!!!!!!!!!!!!!!!!!!!

vdc_int:
	pha
	phx
	phy
	lda	video_reg
	sta	<_vsr
.hsync_test:
	bbr2    <_vsr,.vsync_test
	jsr	MY_HSYNC
	bra	.exit
;--------
.vsync_test:
	bbr5	<_vsr,.exit
	jsr	MY_VSYNC
.exit:
	lda	<_vreg
	sta	video_reg
	ply
	plx
	pla
	rti




timer_int:
	sta irq_status	;ACK TIMER
	stz timer_ctrl	;Turn off timer
my_rti:	rti


	.org $fff6
	.dw my_rti
	.dw vdc_int
	.dw timer_int
	.dw my_rti
	.dw RESET
