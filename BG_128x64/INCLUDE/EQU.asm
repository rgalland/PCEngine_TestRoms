

_si	= $20EE	; source address
_di	= $20F0	; destination address

_irq_m	= $20F5	; interrupt control flags
_vsr	= $20F6	; the VDC status register
_vreg	= $20F7	; the current selected VDC register

_ax	= $20F8
_al	= $20F8
_ah	= $20F9
_bx	= $20FA
_bl	= $20FA
_bh	= $20FB
_cx	= $20FC
_cl	= $20FC
_ch	= $20FD
_dx	= $20FE
_dl	= $20FE
_dh	= $20FF


; --------
; This block defines names for standard
; devices and equipment on the PC-Engine.
; (they should be self-explanatory...)
;

    ; ----
    ; VDC (Video Display Controller)

videoport    .equ $0000

video_reg    .equ videoport
video_reg_l  .equ video_reg
video_reg_h  .equ video_reg+1

video_data   .equ videoport+2
video_data_l .equ video_data
video_data_h .equ video_data+1

; VRAM register index
MAWR 	= $00
MARR 	= $01
VRR	 	= $02	; read and write use the same register
VWR	 	= $02	;
CR 		= $05
CRC		= $06
BXR		= $07
BYR		= $08
MWR		= $09
MWR		= $09
; Display register index
HPR		= $0A
HDR		= $0B
VSR		= $0C
VDR		= $0D
VCR		= $0E
; DMA register index
DCR		= $0F
SOUR	= $10
DESR	= $11
LENR	= $12
SATB	= $13

    ; ----
    ; VCE (Video Color Encoder)

colorport    .equ $0400
color_ctrl   .equ colorport

color_reg    .equ colorport+2
color_reg_l  .equ color_reg
color_reg_h  .equ color_reg+1

color_data   .equ colorport+4
color_data_l .equ color_data
color_data_h .equ color_data+1

             .ifdef HUC
_color_reg   .equ colorport+2
_color_data  .equ colorport+4
             .endif

    ; ----
    ; PSG (Programmable Sound Generator)

psgport      .equ $0800
psg_ch       .equ psgport
psg_mainvol  .equ psgport+1
psg_freqlo   .equ psgport+2
psg_freqhi   .equ psgport+3
psg_ctrl     .equ psgport+4
psg_pan      .equ psgport+5
psg_wave     .equ psgport+6
psg_noise    .equ psgport+7
psg_lfofreq  .equ psgport+8
psg_lfoctrl  .equ psgport+9


    ; ----
    ; TIMER

timerport    .equ $0C00
timer_cnt    .equ timerport
timer_ctrl   .equ timerport+1        


    ; ----
    ; I/O port

joyport      .equ $1000


    ; ----
    ; IRQ ports

irqport      .equ $1400
irq_disable  .equ irqport+2
irq_status   .equ irqport+3


; --------
; This block defines names for macro
; argument types (\?x).
;

ARG_NONE	.equ 0
ARG_REG		.equ 1
ARG_IMMED	.equ 2
ARG_ABS		.equ 3
ARG_ABSOLUTE	.equ 3
ARG_INDIRECT	.equ 4
ARG_STRING	.equ 5
ARG_LABEL	.equ 6

