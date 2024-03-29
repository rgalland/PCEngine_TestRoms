;
; MACRO.INC  -  MagicKit standard MACRO definitions
;

map	.macro			; map a memory bank into
	 lda   #bank(\1)	; addressable memory
	 tam   #page(\1)
	.endm

vreg	.macro
	lda	\1
	sta	<_vreg
	sta	video_reg
	.endm

INTS_OFF	.macro
	st0  #5
	st1   #$00
	st2   #$00
		.endm

SCREEN_OFF	.macro
	st0  #5
	st1   #$0C
	st2   #$00
		.endm
SCREEN_ON	.macro
	st0  #5
	st1   #$CC
	st2   #$00
		.endm
BG_ON	.macro
	st0  #5
	st1   #$8C
	st2   #$00
		.endm




;
; STWZ - store a word-sized zero value at stated memory location
;
stwz	.macro
	 stz	LOW_BYTE \1
	 stz	HIGH_BYTE \1
	.endm

;
; STW - store a word-sized value at stated memory location
;
stw	.macro
	 lda	LOW_BYTE \1
	 sta	LOW_BYTE \2
	 lda	HIGH_BYTE \1
	 sta	HIGH_BYTE \2
	.endm

stb	.macro
	 lda	\1
	 sta	\2
	.endm

;
; ADDW - add word-sized value to value at stated memory location,
;        storing result back into stated memory location (or into
;        another destination memory location - third arg)
;
addw	.macro
	.if	(\# = 3)
	 ; 3-arg mode
	 ;
	 clc
	 lda	LOW_BYTE \2
	 adc	LOW_BYTE \1
	 sta	LOW_BYTE \3
	 lda	HIGH_BYTE \2
	 adc	HIGH_BYTE \1
	 sta	HIGH_BYTE \3
	.else
	 ; 2-arg mode
	 ;
	 clc
	 lda	LOW_BYTE \2
	 adc	LOW_BYTE \1
	 sta	LOW_BYTE \2
	 lda	HIGH_BYTE \2
	 adc	HIGH_BYTE \1
	 sta	HIGH_BYTE \2
	.endif
	.endm

;
; ADCW - add word-sized value plus carry to value at stated memory location,
;        storing result back into stated memory location
;
adcw	.macro
	 lda	LOW_BYTE \2
	 adc	LOW_BYTE \1
	 sta	LOW_BYTE \2
	 lda	HIGH_BYTE \2
	 adc	HIGH_BYTE \1
	 sta	HIGH_BYTE \2
	.endm

;
; SUBW - substract word-sized value from value at stated memory location,
;        storing result back into stated memory location
;
subw	.macro
	 sec
	 lda	LOW_BYTE \2
	 sbc	LOW_BYTE \1
	 sta	LOW_BYTE \2
	 lda	HIGH_BYTE \2
	 sbc	HIGH_BYTE \1
	 sta	HIGH_BYTE \2
	.endm

;
; SBCW - substract word-sized value plus carry from value at stated memory
;        location, storing result back into stated memory location
;
sbcw	.macro
	 lda	LOW_BYTE \2
	 sbc	LOW_BYTE \1
	 sta	LOW_BYTE \2
	 lda	HIGH_BYTE \2
	 sbc	HIGH_BYTE \1
	 sta	HIGH_BYTE \2
	.endm

cmpw	.macro
	 lda	HIGH_BYTE \2
	 cmp	HIGH_BYTE \1
	 bne	.x_\@
	 lda	LOW_BYTE \2
	 cmp	LOW_BYTE \1
.x_\@:
	.endm

tstw	.macro			; test if the word-sized 
	 lda   \1		; value at stated memory
	 ora   \1+1		; location is zero
	.endm

incw	.macro			; increment a word-sized
	 inc	\1		; value at stated memory
	 bne	.x_\@		; location
	 inc	\1+1
.x_\@:
	.endm

decw	.macro			; decrement a word-sized
	 sec			; value at stated memory
	 lda	\1		; location
	 sbc	#1
	 sta	\1
	 lda	\1+1
	 sbc	#0
	 sta	\1+1
	.endm

rolw	.macro			; rotate word-sized value
	 rol	\1		; (at stated memory location)
	 rol	\1+1
	.endm

aslw	.macro			; arithmetic shift-left
	 asl	\1		; word-sized value (at stated
	 rol	\1+1		; memory location)
	.endm

lsrw	.macro			; logical shift-right word-sized
	 lsr	\1+1		; value (at stated memory
	 ror	\1		; location)
	.endm

rorw	.macro			; rotate right word-sized value
	 ror	\1+1		; (at stated memory location)
	 ror	\1
	.endm

negw	.macro			; negate word-sized value
	 cla			; (at stated memory location)
	 sub	\1		; 2's complement
	 sta	\1
	 cla
	 sbc	\1+1
	 sta	\1+1
	.endm

neg	.macro			; negate byte-sized value
	 eor	#$FF		; in register A
	 inc	A		; 2's complement
	.endm

add	.macro			; add byte-sized value to
	.if (\# = 2)		; register A (handle carry
	 lda	\2		; flag)
	 clc
	 adc	\1
	 sta	\2
	.else
	 clc
	 adc	\1
	.endif
	.endm

sub	.macro			; subtract byte-sized value
	.if (\# = 2)		; from register A (handle
	 lda	\2		; carry flag)
	 sec
	 sbc	\1
	 sta	\2
	.else
	 sec
	 sbc	\1
	.endif
	.endm

blo	.macro			; branch if 'lower'
	 bcc	\1
	.endm

bhs	.macro			; branch if 'higher or same'
	 bcs	\1
	.endm

bhi	.macro			; branch if 'higher'
	 beq	.x_\@
	 bcs	\1
.x_\@:
	.endm

;-------------------------------

;
; Long branch MACROs
;

lbne	.macro
	 beq	.x_\@
	 jmp	\1
.x_\@
	.endm

lbeq	.macro
	 bne	.x_\@
	 jmp	\1
.x_\@
	.endm

lbpl	.macro
	 bmi	.x_\@
	 jmp	\1
.x_\@
	.endm

lbmi	.macro
	 bpl	.x_\@
	 jmp	\1
.x_\@
	.endm

lbcc	.macro
	 bcs	.x_\@
	 jmp	\1
.x_\@
	.endm

lbcs	.macro
	 bcc	.x_\@
	 jmp	\1
.x_\@
	.endm

lblo	.macro
	 bcs	.x_\@
	 jmp	\1
.x_\@
	.endm

lbhs	.macro
	 bcc	.x_\@
	 jmp	\1
.x_\@
	.endm


;-------------------------------

;
; These MACROs are the same as the MACROs
; without an underscore; the difference
; is these MACROs preserve the state of
; the registers they use (at the expense
; of speed)
;

_stw	.macro
	 pha
	 stw	\1,\2
	 pla
	.endm

_addw	.macro
	 pha
	 addw	\1,\2
	 pla
	.endm

_adcw	.macro
	 pha
	 adcw	\1,\2
	 pla
	.endm

_subw	.macro
	 pha
	 subw	\1,\2
	 pla
	.endm

_sbcw	.macro
	 pha
	 sbcw	\1,\2
	 pla
	.endm

_cmpw	.macro
	 pha
	 cmpw	\1,\2
	 pla
	.endm

_tstw	.macro
	 pha
	 tstw	\1
	 pla
	.endm

_incw	.macro
	 incw	\1
	.endm

_decw	.macro
	 pha
	 decw	\1
	 pla
	.endm

	; set BG colour to GREEN
BG_GREEN .macro
	stwz	color_reg
	stw	#%0000_000_111_000_000,color_data
	.endm

	; set BG colour to CYAN
BG_CYAN .macro
	stwz	color_reg
	stw	#%0000_000_111_000_111,color_data
	.endm

BG_BLACK .macro
	stwz	color_reg
	stw	#%0000_000_000_000_000,color_data
	.endm

BG_GREY2 .macro
	stwz	color_reg
	stw	#%0000_000_010_010_010,color_data
	.endm

	; set BG colour to Dk.GREEN
BG_DKGRN .macro
	stwz	color_reg
	stw	#%0000_000_101_000_000,color_data
	.endm

	; set BORDER colour to Dk.BLUE
BORD_DKBLU .macro
	stw	#$0100,color_reg
	stw	#%0000_000_000_000_100,color_data
	.endm


	; set BORDER colour to BLUE
BORD_BLUE .macro
	stw	#$0100,color_reg
	stw	#%0000_000_000_000_111,color_data
	.endm

	; set BORDER colour to RED
BORD_RED .macro
	stw	#$0100,color_reg
	stw	#%0000_000_000_111_000,color_data
	.endm

	; set BORDER colour to WHITE
BORD_WHITE .macro
	stw	#$0100,color_reg
	stw	#%0000_000_111_111_111,color_data
	.endm
	

; set colour 1 to GRB value 
; SET_COLOUR_ONE(#grb)
SET_COLOUR_ONE .macro
	lda		$02
	sta		color_reg
	stw	#\1,color_data
	.endm
	
	
