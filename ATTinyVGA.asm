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
rjmp EQUAL
.org OC1Baddr
rjmp VIDEO

RESET:
	ldi r16,(1<<BWHITE)|(1<<HSYNC)|(1<<VSYNC)
	out VGADDR,r16

	ldi r16,low(RAMEND)
	out SPL,r16
	ldi r16,high(RAMEND)
	out SPH,r16

	; SET TIMER1 to fire interrupt on OCR1A match
	ldi r16,(1<<OCIE1A)|(1<<OCIE1B)
	out TIMSK,r16

	;Note that I am filling in OCR1C with values not OCR1A its
	;stupid but the only way this will work.

	; SET TIMER1 INTERRUPT TIME A VALUE
	ldi r16,(HORIZONTALLINES/4-1)
	out OCR1C,r16



	; SET TIMER1 TO SCLK WITH RESET COMPARING AGAINST OCR1C
	ldi r16,(1<<CS10)|(1<<CS11)|(1<<CTC1)
	out TCCR1,r16

	sei
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
	ldi r16,3
	out OCR1B,r16
LOOP:
	nop
	lpm r16,Z+
	push r16
	rjmp LOOP

; HORIZONTAL CLOCK TIMING
;HFP:12 (0-11)
;HSP:76 (12-87)
;HBP:36 (88-123)
;HPX:512 (124-635)
;TOT:636

; VERTICAL LINE TIMING
;VSP:2 (0-1)
;VBP:32 (2-33)
;VLN:480 (34-513)
;VFP:11 (514-524) 
;TOT:525 LINES
VIDEO:
	;Save the status register
	in r17,sreg ;2
	pop r16 ;2
	pop r16 ;2
	
	clr r16
	out TCCR1,r16 ;1
	ldi r16,(1<<CS10)|(1<<CS11)|(1<<CTC1);1
	out TCCR1,r16

	reti

EQUAL:
	sei
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
	reti
