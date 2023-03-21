;
; LIBRARY.INC  -  MagicKit include-interface to LIBRARY.ASM
;

;
; These MACROs are just simple one-line setups to the
; back-end library subroutines.  They simply setup
; calling parameters, and call the subroutine
;

; set video memory read and write address:
;
; setvraddr(addr)
; ----
; addr,  new address in VRAM to read at
;
	.macro setvraddr
	 stw  #\1,<_di
	 jsr  set_read
	.endm
	
	.macro setvraddr2
	 stw  #\1,<_di
	 jsr  set_read
	.endm

	.macro setvraddr3
	 stw  #\1,<_di
	 jsr  set_read
	.endm


; setvwaddr(addr)
; ----
; addr,  new address in VRAM to write at
;
	.macro setvwaddr
	 stw  #\1,<_di
	 jsr  set_write
	.endm

; set_bgpal(#index, data [, #nb])
; ----
; index, sub-palette index (0-15)
; data,  palette data memory address
; nb,    number of sub-palette to update (optional, one by default)

	.macro set_bgpal
	 lda   \1
	 sta   <_al
	 stw   #\2,<_si
	.if \?3
	 lda   \3
	.else
	 lda   #1
	.endif
	 sta   <_cl
	 jsr   set_palette
	.endm

; set_sprpal(#index, data [, #nb])
; ----
; index, sub-palette index (0-15)
; data,  palette data memory address
; nb,    number of sub-palette to update (optional, one by default)

	.macro set_sprpal
	 lda   \1
	 add   #16
	 sta   <_al
	 stw   #\2,<_si
	.if \?3
	 lda   \3
	.else
	 lda   #1
	.endif
	 sta   <_cl
	 jsr   set_palette
	.endm

; setcolor(#index, #r, #g, #b)
; ----
; index, color index
; r,     red   (0-7)
; g,     green (0-7)
; b,     blue  (0-7)

	.macro setcolor
	 stw   \1,color_reg
	 stw   #(((\3) << 6) + ((\2) << 3) + (\4)),color_data
	.endm

; vload([vram,] data, #size)
; ----
; vram, VRAM base address
; data, video data memory address
; size, number of words to copy

	.macro vload
	.if (\# = 3)
	 stw   #\1,<_di
	 stw   #\2,<_si
	 stw   #\3,<_cx	    ;WTF is this??? ERRORS!!! "stw   \3,<_cx"
	.else
	 stw   #VRAM(\1),<_di
	 stw   #\1,<_si
	 stw   #\2,<_cx
	.endif
	 jsr   load_vram
	.endm

; batcpy(vram, #vwidth, bat, #w, #h)
; ----
; vram,   VRAM base address
; vwidth, width of the virtual BG map
; bat,    BAT address in memory
; w,      nb of column to copy
; h,      nb of row

	.macro batcpy
	 stw   #\1,<_di
	 stw    \2,<_dx
	 stw   #\3,<_si
	 lda   \4
	 sta   <_cl
	 lda   \5
	 sta   <_ch
	 jsr   load_bat
	.endm


	

; setvdcreg(#reg_num, reg_value_addr)
	.macro setvdcreg
	 st0 #\1
	 lda \2
	 sta video_data_l
	 lda \2+1
	 sta video_data_h
	.endm

; setvdcregl(#reg_num, reg_value_addr)
	.macro setvdcregl
	 st0 #\1
	 lda \2
	 sta video_data_l
	.endm

; setvdcregh(#reg_num, #reg_value_addr)
	.macro setvdcregh
	 st0 #\1
	 lda \2
	 sta video_data_h
	.endm		
	
	
