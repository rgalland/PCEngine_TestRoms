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

