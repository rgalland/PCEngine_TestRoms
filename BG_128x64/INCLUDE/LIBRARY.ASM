;
; LIBRARY.ASM  -  MagicKit Standard Library
;
;

; ----
; set_palette
; ----
; initialize one or more sub-palette
; ----
; IN :  _AL = index of the first sub-palette (0-31)
;       _SI = address of the color table
;       _CL = number of sub_palette to copy
; ----

set_palette:
	lda   <_al		; multiply the sub-palette index by 16
	stz   <_ah		; and set the color index of the VCE
	asl   A
	asl   A
	asl   A
	asl   A
	rol   <_ah
	sta   color_reg
	lda   <_ah
	sta   color_reg+1
	cly
.loop_a:
	ldx   #16
.loop_b:
	lda   [_si],Y		; set a color
	iny
	sta   color_data
	lda   [_si],Y
	sta   color_data+1
	iny
	bne   .next
	inc   <_si+1
.next:  dex			; next color
	bne   .loop_b

	dec   <_cl		; next sub-palette
	bne   .loop_a
	rts

; ----
; load_bat
; ----
; transfer a bloc attribute table into VRAM
; ----
; IN :  _DI = VRAM base address
;       _DX = width of the virtual screen
;       _SI = memory location
;       _CL = nb of column to copy
;       _CH = nb of row
; ----

load_bat:
	cly
.l1:	jsr   set_write
	ldx   <_cl
.l2:	lda   [_si],Y
	sta   video_data
	iny
	lda   [_si],Y
	sta   video_data+1
	iny
	bne   .n1
	inc   <_si+1
.n1:	dex
	bne   .l2
	
	addw  <_dx,<_di
	dec   <_ch
	bne   .l1
	rts


; ----
; load_vram
; ----
; copy a block of memory to the VRAM
; ----
; IN :  _DI = VRAM location
;       _SI = memory location
;       _CX = number of words to copy
; ----

load_vram:
	jsr   set_write
	cly
.loop:	lda   [_si],Y
	sta   video_data
	iny
	lda   [_si],Y
	sta   video_data+1
	iny
	bne   .next
	inc   <_si+1
.next:	decw  <_cx
	lda   <_cl
	ora   <_ch
	bne   .loop
	rts


; ----
; set_read
; ----
; set the VDC VRAM read address
; ----
; IN :  _DI = VRAM location
; ----

set_read:
	vreg  #$01
	lda   <_di 
	sta   video_data
	lda   <_di+1
	sta   video_data+1
	vreg  #$02
	rts 


; ----
; set_write
; ----
; set the VDC VRAM write address
; ----
; IN :  _DI = VRAM location
; ----

set_write:
	vreg  #$00
	lda   <_di
	sta   video_data
	lda   <_di+1
	sta   video_data+1
	vreg  #$02
	rts