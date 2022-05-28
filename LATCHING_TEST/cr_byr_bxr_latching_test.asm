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

TOP_LINE	= $0077
BOT_LINE	= $0086

TOP_BYR  	= $005A
BOT_BYR  	= $00BA

LFT_BXR  	= $0008

UP          = $00
DOWN        = $01


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
direction:	.ds 1
vb_count:	.ds 1



;==============================
	.code
	.bank	$0
	.org	$E000


MAIN:
	INTS_OFF		;DISABLE INTERRUPTS!
	stz	<direction
	stw	#TOP_LINE,<hsync_line

	map	BonkBG
	vload	BONKBG_VRAM, BonkBG, $1000
	map	MyFont
	vload	ASCII_VRAM, MyFont, $0800
	vload	BONKSP_VRAM, SprCHR, $0200	;Load 2 32x32 sprites

	set_bgpal #0, FontPal, #2
	set_sprpal #0, SPRPal, #1

	jsr	Clear_BAT

	stw	#Intro_Text,<_si ;Point to text string
	stw	#$0020,<_di	 ;Point on-screen
	jsr	Print_Text

	jsr	Draw_BonkBG


	BG_GREEN
	BORD_BLUE
	SCREEN_ON

	vreg	#6	;Scanline compare register
	stw		<hsync_line,video_data
	

.loop            	;Here's an infinite loop...
	bra	.loop


MY_VSYNC:
	BORD_RED
	pha
	pla
	pha
	pla
	BORD_BLUE
	
	inc	<vb_count
	bbs0	<vb_count,.no_move


;---- increase scanline position
	bbs7	<direction,.dec_line
	bne	.line_moved
	bra	.line_moved
;----
;---- decrease scanline position
.dec_line:
	bne     .line_moved
;----
.line_moved:
.no_move:

	stw	#$005D,<_di
	jsr	set_write
	lda	<hsync_line+1
	jsr	Print_Nyb
	lda	<hsync_line
	jsr	Print_Byte

	; reset BYR and BXR
	vreg	#8	;BYR
	stwz	video_data
	
	vreg	#7	;BXR
	stwz	video_data
	
	; reenable BG
	vreg	#5	;CR
	stw		#$00CC,video_data
	
	
	rts


MY_HSYNC:
	BORD_WHITE
	;BG_CYAN
	; load current direction value and inc for next time
	lda 	<direction
	inc 	<direction
	and #DOWN
	; if dir flag = 0, this is top line so: 1) set dir flag, 2) set hsync for bottom line int, 3) make BG grey 4) adjust BYR to test flag latching leading
	; else 1) clear flag, 2) make BG black 3) adjust BYR to test flag latching leading
	beq 	.top_line
	jmp 	BOT_LINE_ACTIONS

.top_line	
	BG_CYAN
	stw 	#BOT_LINE,<hsync_line
	vreg	#6	;Scanline compare register
	stw		<hsync_line,video_data
	BORD_DKBLU
	
	; 455 cpu cycles per scanline
	; adjust BYR to hide the red box 
	ldx #$30	;	0x30 gives 1 * 4 cy (no loop) + 0x2F * 6 cy (loops) = 286 cy  
.top_line_delay
	dex
	bne .top_line_delay 
	nop
	
	;BYR test on top line
	BG_GREY2	
	; 1 nop max adjust BYR on time
	; Comparison - expected result is previous line
	; PCE	   : 0, 1, = previous line; 2, 3, 4 = next line
	; Mednafen : 0 = previous line, 1 = unstable, 2, 3, 4 = next line
	; me:	   : 0, 1, = previous line,  2, 3, 4 = next line
	nop
	;nop
	;nop
	;nop
	
	; APPLY new BYR value to see top of red box	
	vreg	#8	;BYR
	stw		#TOP_BYR,video_data

	; BXR tests
	; add more delay for another line and test BXR latch
	; write a shift then remove it and make sure that second command is actioned 
	ldx #$44	;	0x44 gives 1 * 4 cy (no loop) + 0x43 * 6 cy (loops) = 406 cy  
.bxr_left_delay
	dex
	bne .bxr_left_delay 
	
	; Supercede BXR value to avoid left shift of the red box	
	vreg	#7	;BXR
	stw		#LFT_BXR,video_data
	
	; 1 nop max to adjust BXR on time
	; Comparison - expected result is no shift
	; PCE	   : 0, 1, = no shift; 2, 3 = shift
	; Mednafen : 0, 1, = no shift; 2, 3 = shift
	; me:	   : 0, 1, = no shift; 2, 3 = shift
	nop
	;nop
	;nop
	;nop
	;nop
	;nop
		
	; reset BXR
	vreg	#7	;BXR
	stwz	video_data

	; add more delay for another 3 lines and test BXR latch
	; reset BXR, then add shift and make sure that second command is ignored 
	ldx #$DB	;	0x44 gives 1 * 4 cy (no loop) + 0x43 * 6 cy (loops) = 406 cy  
.bxr_right_delay
	dex
	bne .bxr_right_delay 

	; Second BXR is ignored to avoid left shift of the red box	
	vreg	#7	;BXR
	stwz	video_data
	
	; 2 nops min to ignore wrong BXR latching
	; Comparison - expected result is no shift
	; PCE	   : 0, 1 = shift; 2, 3 = no shift
	; Mednafen : 0, 1, 2 = shift; 3 = no shift
	; me:	   : 0, 1 = shift; 2, 3 = no shift
	
	;nop
	nop
	nop
	
	
	vreg	#7	;BXR
	stw		#LFT_BXR,video_data
	
	nop
	nop
	nop
		
	; reset BXR
	vreg	#7	;BXR
	stwz	video_data
	
	; CR tests
	; add more delay for another 3 lines and test CR latch
	; disable BG (bit 7) in CR, reaneble it and make sure that second command is actionned 
	ldx #$D3	;	0x44 gives 1 * 4 cy (no loop) + 0x43 * 6 cy (loops) = 406 cy  
.cr_left_delay
	dex
	bne .cr_left_delay 
	
	; disable BG
	vreg	#5	;CR
	stw		#$004C,video_data
	
	; 3 nops max to register BG enable
	; Comparison - expected result is BG enabled
	; PCE	   : 0, 1, 2, 3 = enabled; 4, 5, 6 = disabled
	; Mednafen : 0, 1, 2 = enabled; 3, 4 = unstable; 5, 6 = disabled
	; me:	   : 0, 1, 2, 3 = enabled; 4, 5, 6, 7, 8 = disabled
	nop
	nop
	nop
	;nop
	;nop
	 
	; renable BG
	vreg	#5	;CR
	stw		#$00CC,video_data

	; add more delay for another 3 lines and test CR latch
	; disable it and make sure that second command is ignored 
	ldx #$DE	;	0x44 gives 1 * 4 cy (no loop) + 0x43 * 6 cy (loops) = 406 cy  
.cr_right_delay
	dex
	bne .cr_right_delay 
	
	; 4 nops min to ignore BG disable
	; Comparison - expected result is BG enabled
	; PCE	   : 0, 1, 2, 3 = disabled; 4, 5, 6 = enabled
	; Mednafen : 0, 1, 2 = disabled; 3, 4 = unstable; 5, 6 = enabled
	; me:	   : 0, 1, 2, 3 = disabled; 4, 5, 6, 7, 8 = enabled
	nop
	nop
	nop
	nop
	;nop
	;nop
	;nop
	;nop
		
	; disable BG
	vreg	#5	;CR
	stw		#$004C,video_data
		
	nop
	nop
	nop
	
	 
	; renable BG
	vreg	#5	;CR
	stw		#$00CC,video_data

	
	
	rts
	

BOT_LINE_ACTIONS:
	stw 	#TOP_LINE,<hsync_line
	vreg	#6	;Scanline compare register
	stw		<hsync_line,video_data
	ldx #$40
.bot_line_delay
	dex
	bne .bot_line_delay 
	
	;BYR test on bottom line
	; 3 nops min to ignore BYR
	; Comparison when adding nops	-- expected result is previous line
	; PCE	   : 0, 1, 2 = next line, 3, 4, 5 = previous line
	; Mednafen : 0, 1 = next line; 2, 3 = unstable; 4, 5 = previous line
	; me:	   : 0, 1, 2 = next line, 3, 4, 5 = previous line
	nop
	nop
	nop
	;nop
	;nop

	; apply new BYR value to stop at bottom of red box	
	vreg	#8	;BYR
	stw		#BOT_BYR,video_data

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
	stw		#$004C,video_data
		
	rts


Intro_Text:
     ;0123456789ABCDEF0123456789ABCDEF
 .db "BYR LATCH TEST: RED BOX STABLE  "
 .db "BETWEEN BLUE LINES, TOP RCR: XXX"
 .db "BXR LATCH TEST: NO X SHIFT      "
 .db "CR LATCH TEST: ALL LINES VISIBLE",0


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
