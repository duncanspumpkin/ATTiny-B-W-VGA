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

.equ OUTPUTFRAME = SRAM_START ;This is 10 bytes long and address to what we are outputing

.def VERTLINENOL=r0 ;Permantly used for Vertical line no.
.def VERTLINENOH=r1

.def TILELINEL=r2
.def TILELINEH=r3
;Register r6-r8 & r17 are also used by interrupt do not use.

.org 0
rjmp RESET

.org OC1Aaddr
; This is used to equalise interrupt latency
	sei ;1
	nop ;1 OVF1addr
	nop ;1 OVF0addr
	nop ;1 ERDYaddr
	nop	;1 ACIaddr
; Note do not use Timer 0/1 overflow, EEPROM ready and Analog Comparator interrupts
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
	ldi r16,2
	out OCR1B,r16
LOOP:
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
;******************************
;* We have just left the HFP after 18 cycles now in HSP for 76 cycles
;******************************
	; Setup
	; Time  = 11 cycles
	cbi VGAPORT,HSYNC ;2
	;Save the status register
	push r16 ;2
	pop r16 ;2
	pop r16 ;2	
	push r19 ;2
	in r17,sreg ;1

	;Increment line
	; TIME = 3 cycles
	inc VERTLINENOL;1
	brne VERTADD ;2/1
	 inc VERTLINENOH;1
	VERTADD:
	
	;Reset Line count
	; Time = 11
	ldi r19,low(VERTICALLINES) ;1
	ldi r16,high(VERTICALLINES) ;1
	; Check to see if we need to start from the
	; begining.
	cp r19,VERTLINENOL ;1
	cpc r16,VERTLINENOH ;1
	breq restartVertCount ;1/2
	 nop ;-
	 nop ;-
	 nop ;3
	 rjmp noRestartVertCount ;2
	restartVertCount:
	 clr VERTLINENOL ;1
	 clr VERTLINENOH ;1
	 cbi VGAPORT,VSYNC ;2
	noRestartVertCount:
	clr r19 ;1

	; VERTICAL SYNC OFF AT LINE 2
	; TIME = 7 CYCLES
	ldi r16,low(VERTICALSYNCPULSE) ;1
	;ldi r17,high(VERTICALSYNCPULSE) ;1
	cp r16,VERTLINENOL ;1
	cpc r19,VERTLINENOH ;1
	breq s3 ;1/2
	 nop ;1
	 rjmp s4 ;2
	s3:
	sbi VGAPORT,VSYNC ;2
	s4:

	; Stop doing work if this is a blank
	; line.
	; ACTIVE PIXELS ON AT LINE 34
	; TIME = 6 CYCLES
	ldi r16,low(VERTICALACTIVESTART) ;1
	;ldi r17,high(VERTICALACTIVESTART) ;1
	cp r16,VERTLINENOL ;1
	cpc r19,VERTLINENOH ;1
	brlo activePixOn;2/1
	 rjmp activePixOnEnd ;2
activePixOn:
	set ;1
activePixOnEnd:

	; ACTIVE PIXELS OFF AT LINE 514
	; Time = 7 Cyclces
	ldi r16,low(VERTICALACTIVEEND) ;1
	ldi r19,high(VERTICALACTIVEEND) ;1
	cp r16,VERTLINENOL ;1
	cpc r19,VERTLINENOH ;1
	brlo activePixOff ;2/1
	 rjmp activePixOffEnd
activePixOff:
	clt ;1
activePixOffEnd:

 	; Fix timer
	; Time = 4 cycles
	clr r16 ;1
	out TCCR1,r16 ;1
	ldi r16,(1<<CS10)|(1<<CS11)|(1<<CTC1);1
	out TCCR1,r16 ;1
	; 49 Cycles
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
	nop ;26
	sbi VGAPORT,HSYNC ;2
; ****************************************************************************************
; **** HORIZONTAL BACK PORCH = 36 CYCLES
; ****************************************************************************************
	brts novid1;2/1
	rjmp novid ;2 Doesn't matter as this wont be run if there is vid
novid1:
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
	nop
	nop
	nop
	nop
	nop
	ldi r16,4 ;There are 512 cycles we only output on 500 with 5 characters
; ****************************************************************************************
; **** HORIZONTAL ACTIVE LINE = 512 CYCLES / 4 = 128 PIXELS
; ****************************************************************************************
	in r7,VGAPORT ;1
	bst r8,0 ;1
	bld r7,BWHITE ;1
vidOut:	
	out VGAPORT,r7 ;1 - 1	
	bst r8,1 ;1
	bld r7,BWHITE ;1
	bst r8,2 ;1
	nop ;1
	out VGAPORT,r7 ;1 - 2
	lpm r6,Z+ ;3
	bld r7,BWHITE ;1
	out VGAPORT,r7 ;1 - 3
	bst r8,3 ;1
	bld r7,BWHITE ;1
	nop ;1
	nop ;1
	out VGAPORT,r7 ;1 - 4
	bst r8,4 ;1
	bld r7,BWHITE ;1
	nop ;1
	nop ;1
	out VGAPORT,r7 ;1 - 5
	bst r8,5 ;1
	bld r7,BWHITE ;1
	nop ;1
	nop ;1
	out VGAPORT,r7 ;1 - 6
	bst r8,6 ;1
	bld r7,BWHITE ;1
	nop ;1
	nop ;1
	out VGAPORT,r7 ;1 - 7
	bst r8,7 ;1
	bld r7,BWHITE ;1
	mov r8,r6 ;1
	nop ;1
	out VGAPORT,r7 ;1 - 8
	bst r8,0 ;1
	bld r7,BWHITE ;1
	nop ;1
	nop ;1
	out VGAPORT,r7 ;1 - 9
	bst r8,1 ;1
	bld r7,BWHITE ;1
	nop ;1
	nop ;1
	out VGAPORT,r7 ;1 - 10
	bst r8,2 ;1
	bld r7,BWHITE ;1
	nop ;1
	nop ;1
	out VGAPORT,r7 ;1 - 11
	bst r8,3 ;1
	bld r7,BWHITE ;1
	bst r8,4 ;1
	nop ;1
	out VGAPORT,r7 ;1 - 12
	bld r7,BWHITE ;1
	lpm r6,Z+ ;3
	out VGAPORT,r7 ;1 - 13
	bst r8,5
	bld r7,BWHITE ;1
	ld ZL,X+ ;2
	out VGAPORT,r7 ;1 - 14
	bst r8,6 ;1
	bld r7,BWHITE ;1
	ld ZH,X+ ;2
	out VGAPORT,r7 ;1 - 15
	bst r8,7;1
	bld r7,BWHITE ;1
	mov r8,r6
	bst r8,0;1
	out VGAPORT,r7 ;1 - 16
	bld r7,BWHITE ;1
	bst r8,1
	add ZL,TILELINEL ;1
	adc ZH,TILELINEH ;1	
	out VGAPORT,r7 ;1 - 17
	bld r7,BWHITE ;1
	bst r8,2 ;1
	dec r16 ;1
	nop ;1
	out VGAPORT,r7 ;1 - 18
	bld r7,BWHITE ;1
	lpm r6,Z+ ;3
	out VGAPORT,r7 ;1 - 19
	bst r8,3 ;1
	bld r7,BWHITE ;1 
	mov r8,r6 ;1
	bst r8,0 ;1
	out VGAPORT,r7 ;1 - 20
	bld r7,BWHITE ;1
	breq noVid ;2/1
	rjmp vidOut ;2
novid:
	pop r19 ;2
	pop r16 ;2
	out sreg,r17 ;1
	reti ;4

