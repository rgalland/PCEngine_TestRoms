;
; Graphics routines that I write will go here
;

Clear_BAT:
	vreg	#$00
	stwz	video_data
	vreg	#$02

	ldx	#LOW(BATWIDTH*BATHEIGHT)
	ldy     #HIGH(BATWIDTH*BATHEIGHT)
.clrlp:
	st1	#$20	;"whitespace character"
	st2	#$01
	dex
	bne     .clrlp
	dey
	bne	.clrlp
	rts


Print_Byte:	;Prints a byte as HEX
	pha
	lsr a
	lsr a
	lsr a
	lsr a
		;store char # (0-F) of high nyb
	ora	#LOW(HEX_VRAM/16)
	sta	video_data
	lda	#$00+(HEX_VRAM/4096) ;font pal + tile no.
	sta	video_data+1
	pla
Print_Nyb:
	pha
	and	#$0F	;isolate low nyb.
	ora	#LOW(HEX_VRAM/16)
	sta	video_data
	lda	#$00+(HEX_VRAM/4096) ;font pal + tile no.
	sta	video_data+1
	pla
	rts

Print_Text:			;_si points to zero-terminated text
	jsr	set_write       ;_di points to VRAM add.
Print_Tex2:
	cly
	ldx	#$00+(ASCII_VRAM/4096)	;Palette 0, $1000 VRAM
.loop1:
	lda	[_si],Y
	beq	.finish
	sta	video_data
	stx	video_data+1
	incw	<_si
	bra	.loop1
.finish:
	rts


Draw_BonkBG:	;draws 16x16 tile box w/ graphics on-screen
	stw	#(1*$1000)+(BONKBG_VRAM/16),<_si ;Pal 1 + Tile No.
	stw	#$00E8,<_di
	jsr	set_write	;set VRAM address

	ldy	#16		;outer loop (vert. lines)
.bonklp0:
	ldx	#16		;inner loop (horiz. tiles)
.bonklp1:
	stw	<_si,video_data	;lay down tile definition
	incw	<_si
	dex
	bne	.bonklp1
	addw	#BATWIDTH,<_di	;then jump down to next line
	jsr	set_write
	dey
	bne     .bonklp0

	rts
