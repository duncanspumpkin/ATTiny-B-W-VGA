.include "tn45def.INC"

.equ BWHITE=2
.equ HSYNC=1
.equ VSYNC=0
.equ VGADDR=DDRB
.equ VGAPIN=PINB
.equ VGAPORT=PORTB
.equ HORIZONTALLINES = 636
.equ VERTICALLINES = 525 ;0x20d
.equ VERTICALSYNCPULSE = 2 ;0x002
.equ VERTICALACTIVESTART = 34 ;0x022
.equ VERTICALACTIVEEND = 514 ;0x202

.org 0
rjmp RESET

.org OC1Aaddr
rjmp VIDEO

RESET:
	ldi r16,(1<<BWHITE)|(1<<HSYNC)|(1<<VSYNC)
	out VGADDR,r16

	ldi r16,low(RAMEND)
	out SPL,r16
	ldi r16,high(RAMEND)
	out SPH,r16

	; SET TIMER1 to fire interrupt on OCR1A match
	ldi r16,(1<<OCIE1A)
	out TIMSK,r16

	;Note that I am filling in OCR1C with values not OCR1A its
	;stupid but the only way this will work.

	; SET TIMER1 INTERRUPT TIME A VALUE
	ldi r16,HORIZONTALLINES/4
	out OCR1C,r16

	; SET TIMER1 TO SCLK WITH RESET COMPARING AGAINST OCR1C
	ldi r16,(1<<CS10)|(1<<CS11)|(1<<CTC1)
	out TCCR1,r16

	sei

LOOP:
	rjmp LOOP

VIDEO:
	reti
