.include "tn45def.INC"

.equ BWHITE=2
.equ HSYNC=1
.equ VSYNC=0 ;This is used by data input and should be changed to 4 if we want to use the usi
.equ VGADDR=DDRB
.equ VGAPIN=PINB
.equ VGAPORT=PORTB
.equ HORIZONTALLINES = 636
.equ VERTICALLINES = 525 ;0x20d
.equ VERTICALSYNCPULSE = 2 ;0x002
;Vertical should start at 34 but since we are only outputing 20 pixels 
; of 5 times size 100 we start a bit later
.equ VERTICALACTIVESTART = 34 + (514-34-100)/2-1 ;0x022
.equ VERTICALACTIVEEND = 514 - (514-34-100)/2-1 ;0x202

.equ OUTPUTFRAME = SRAM_START ;This is 10 bytes long and address to what we are outputing

.def VERTLINENOL=r0 ;Permantly used for Vertical line no.
.def VERTLINENOH=r1

.def TILELINEL=r2
.def TILELINEH=r3
.def REGSTORE=r5
;Register r0-r12 are used by interrupt do not use.

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

	; Load in a basic frame
	ldi xl,low(OUTPUTFRAME)
	ldi xh,high(OUTPUTFRAME)
	ldi zl,low(2*TILE1)
	ldi zh,high(2*TILE1)
	st X+,ZL
	st X+,ZH	
	ldi zl,low(2*TILE2)
	ldi zh,high(2*TILE2)
	st X+,ZL
	st X+,ZH	
	ldi zl,low(2*TILE11)
	ldi zh,high(2*TILE11)
	st X+,ZL
	st X+,ZH	
	ldi zl,low(2*TILE4)
	ldi zh,high(2*TILE4)
	st X+,ZL
	st X+,ZH	
	ldi zl,low(2*TILE5)
	ldi zh,high(2*TILE5)
	st X+,ZL
	st X+,ZH
	
	;Setup Output stuff
	ser r16;
	mov r4,r16 ;1
	clr TILELINEL;1
	clr TILELINEH;1

	; Set TIME OCR1B we do this after a period of time so that the first
	; interrupt occurs properly
	ldi r16,2
	out OCR1B,r16	
	sei

	; We have now set up all basic output stuff and can focus on doing our output.
	
	ldi r18,1
	; Allocate 4 variables for timer output
	push r18
	push r18
	push r18
	push r18
LOOPRESTART:	
	ldi r19,60
LOOP:
	; We need to decrement a counter every second
	in r16,TCNT1
	ldi r17,0x1C
	cp r17,r16
	; First check to see if output is on a quick cycle
	brlo LOOP
	ldi r16,0
	ldi r17,0
	cp VERTLINENOL,r16
	cpc VERTLINENOH,r17
	; Check to see if we have finished a frame 1/60s
	brne LOOP
	dec r19
	brne LOOP
	; A whole second has passed so we need to change the output.
	rcall decTime ;Decrements the time

	rcall outTime ;Changes memory to the current time

	rjmp LOOPRESTART

decTime:
	pop xl
	pop xh
	pop r16 ;hx:xx
	pop r17 ;xh:xx
	pop r18 ;xx:mx
	pop r19 ;xx:xm
	
	dec r19
	brbc 2,decTimeEnd ;End if not negative
	dec r18
	brbc 2,decTimeEndLMin ;End if not negative
	dec r17
	brbc 2,decTimeEndHMin
	dec r16
	brbc 2,decTimeEndLHour
	ldi r17,0x0
	ldi r16,0x0
	ldi r18,0x0
	ldi r19,0x0
	rjmp decTimeEnd

decTimeEndLHour:
	ldi r17,0x9
decTimeEndHMin:
	ldi r18,0x5
decTimeEndLMin:
	ldi r19,0x9
decTimeEnd:

	push r19
	push r18
	push r17
	push r16
	push xh
	push xl
	ret


outTime:
	pop yl
	pop yh
	
	ldi xl,low(OUTPUTFRAME)
	ldi xh,high(OUTPUTFRAME)

	ldi ZL,low(2*(TILE0))
	ldi ZH,high(2*(TILE0))
	pop r21
	mov r18,r21 ;hx:xx
	rcall offsetmult
	
	st x+,ZL
	st x+,ZH

	ldi ZL,low(2*(TILE0))
	ldi ZH,high(2*(TILE0))
	pop r22
	mov r18,r22 ;xh:xx
	rcall offsetmult	
	
	st x+,ZL
	st x+,ZH
	
	ldi xl,low(OUTPUTFRAME+6);3*2 
	ldi xh,high(OUTPUTFRAME+6)
	ldi ZL,low(2*(TILE0))
	ldi ZH,high(2*(TILE0))
	pop r23 ;xx:mx
	mov r18,r23
	rcall offsetmult	
	
	st x+,ZL
	st x+,ZH
	
	ldi ZL,low(2*(TILE0))
	ldi ZH,high(2*(TILE0))
	pop r24
	mov r18,r24 ;xx:xm
	rcall offsetmult	
	
	st x+,ZL
	st x+,ZH	
	
	push r24
	push r23
	push r22
	push r21
	push yh
	push yl
	ret

offsetmult:
	ldi r16,low(2*(TILE2-TILE1))
	ldi r17,high(2*(TILE2-TILE1))
offsetmultloop:
	tst r18
	breq offsetmultEnd
	add ZL,r16
	adc ZH,r17
	dec r18
	rjmp offsetmultloop
offsetmultEnd:
	ret
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
	pop REGSTORE;2
	pop REGSTORE ;2
	push r16 ;2
	push r19 ;2
	in REGSTORE,sreg ;1

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
	; Time = 10 Cyclces
	ldi r16,low(VERTICALACTIVEEND) ;1
	ldi r19,high(VERTICALACTIVEEND) ;1
	cp r16,VERTLINENOL ;1
	cpc r19,VERTLINENOH ;1
	brlo activePixOff ;2/1
	 nop
	 nop
	 nop
	 nop
	 rjmp activePixOffEnd
activePixOff:
	ser r16	;1
	mov r4,r16 ;1
	clr TILELINEL;1
	clr TILELINEH;1
	clt ;1
activePixOffEnd:

 	; Fix timer
	; Time = 4 cycles
	clr r16 ;1
	out TCCR1,r16 ;1
	ldi r16,(1<<CS10)|(1<<CS11)|(1<<CTC1);1
	out TCCR1,r16 ;1
	; 49 Cycles	
	mov r9,XL ;1
	mov r10,XH;1
	mov r11,ZL;1
	mov r12,ZH;1
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
	nop ;17
	sbi VGAPORT,HSYNC ;2
; ****************************************************************************************
; **** HORIZONTAL BACK PORCH = 36 CYCLES
; ****************************************************************************************
	brts dispvid;2/1
	rjmp novid ;2 Doesn't matter as this wont be run if there is vid
dispvid:
	;11 cycles
	inc r4 ;1
	ldi r16,0x5;1
	cp r4,r16 ;1
	brsh newLine;2/1
	nop ;1
	nop ;1
	nop ;1
	nop ;1
	rjmp noNewLine ;2
newLine:
	clr r4 ;1
	ldi r16,low((TILELINE3-TILELINE1));1 There is a good reason why this is 3
	ldi r19,high((TILELINE3-TILELINE1));1
	add TILELINEL,r16 ;1
	adc TILELINEH,r19 ;1

noNewLine:
	
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	
	

	ldi XL,low(OUTPUTFRAME) ;1
	ldi XH,high(OUTPUTFRAME) ;1
	ld ZL,X+ ;2
	ld ZH,X+ ;2
	add ZL,TILELINEL ;1
	adc ZH,TILELINEH ;1
	lpm r8,Z+ ;3	
	ldi r16,5 ;1 There are 512 cycles we only output on 500 with 5 characters
	in r7,VGAPORT ;1
	bst r8,0 ;1
	bld r7,BWHITE ;1
; ****************************************************************************************
; **** HORIZONTAL ACTIVE LINE = 512 CYCLES / 4 = 128 PIXELS
; ****************************************************************************************	
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
	cbi VGAPORT,BWHITE ;2
	;Check that we have the final black band Should also reset output to off
	mov XL,r9 ;1
	mov XH,r10;1
	mov ZL,r11;1
	mov ZH,r12;1
	pop r19 ;2
	pop r16 ;2
	out sreg,REGSTORE ;1
	reti ;4
    

TILE0:
.db 0x00, 0x00, 0x00, \
    0x00, 0xF0, 0x00, \
    0x00, 0xFC, 0x01, \
    0x00, 0x8C, 0x03, \
    0x00, 0x06, 0x03, \
    0x00, 0x06, 0x06, \
    0x00, 0x06, 0x06, \
    0x00, 0x06, 0x06, \
    0x00, 0x06, 0x06, \
    0x00, 0x06, 0x06, \
    0x00, 0x06, 0x06, \
    0x00, 0x06, 0x06, \
    0x00, 0x06, 0x03, \
    0x00, 0x8C, 0x03, \
    0x00, 0xFC, 0x01, \
    0x00, 0xF0, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00
TILE1:
TILELINE1:
.db 0x00, 0x00, 0x00, \
    0x00, 0x80, 0x00
TILELINE3:
.db 0x00, 0xC0, 0x00, \
    0x00, 0xE0, 0x00, \
    0x00, 0xF8, 0x00, \
    0x00, 0xCC, 0x00, \
    0x00, 0xC0, 0x00, \
    0x00, 0xC0, 0x00, \
    0x00, 0xC0, 0x00, \
    0x00, 0xC0, 0x00, \
    0x00, 0xC0, 0x00, \
    0x00, 0xC0, 0x00, \
    0x00, 0xC0, 0x00, \
    0x00, 0xC0, 0x00, \
    0x00, 0xC0, 0x00, \
    0x00, 0xC0, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00
TILE2:
.db 0x00, 0x00, 0x00, \
    0x00, 0xF0, 0x00, \
    0x00, 0xFC, 0x03, \
    0x00, 0x0C, 0x03, \
    0x00, 0x06, 0x06, \
    0x00, 0x06, 0x06, \
    0x00, 0x00, 0x06, \
    0x00, 0x00, 0x03, \
    0x00, 0x80, 0x01, \
    0x00, 0xC0, 0x00, \
    0x00, 0x60, 0x00, \
    0x00, 0x30, 0x00, \
    0x00, 0x18, 0x00, \
    0x00, 0x0C, 0x00, \
    0x00, 0xFE, 0x07, \
    0x00, 0xFE, 0x07, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00
TILE3:
.db 0x00, 0x00, 0x00, \
    0x00, 0x78, 0x00, \
    0x00, 0xFE, 0x00, \
    0x00, 0x86, 0x01, \
    0x00, 0x83, 0x01, \
    0x00, 0x80, 0x01, \
    0x00, 0xC0, 0x01, \
    0x00, 0x70, 0x00, \
    0x00, 0xF0, 0x01, \
    0x00, 0x80, 0x03, \
    0x00, 0x00, 0x03, \
    0x00, 0x00, 0x03, \
    0x00, 0x03, 0x03, \
    0x00, 0x87, 0x01, \
    0x00, 0xFE, 0x01, \
    0x00, 0x78, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00
TILE4:
.db 0x00, 0x00, 0x00, \
    0x00, 0x80, 0x01, \
    0x00, 0x80, 0x01, \
    0x00, 0xC0, 0x01, \
    0x00, 0xE0, 0x01, \
    0x00, 0xB0, 0x01, \
    0x00, 0x98, 0x01, \
    0x00, 0x88, 0x01, \
    0x00, 0x8C, 0x01, \
    0x00, 0x86, 0x01, \
    0x00, 0xFE, 0x07, \
    0x00, 0xFE, 0x07, \
    0x00, 0x80, 0x01, \
    0x00, 0x80, 0x01, \
    0x00, 0x80, 0x01, \
    0x00, 0x80, 0x01, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00
TILE5:
.db 0x00, 0x00, 0x00, \
    0x00, 0xFC, 0x01, \
    0x00, 0xFC, 0x01, \
    0x00, 0x06, 0x00, \
    0x00, 0x06, 0x00, \
    0x00, 0x06, 0x00, \
    0x00, 0x7E, 0x00, \
    0x00, 0xFE, 0x01, \
    0x00, 0x87, 0x01, \
    0x00, 0x00, 0x03, \
    0x00, 0x00, 0x03, \
    0x00, 0x00, 0x03, \
    0x00, 0x03, 0x03, \
    0x00, 0x87, 0x01, \
    0x00, 0xFE, 0x00, \
    0x00, 0x7C, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00
TILE6:
.db 0x00, 0x00, 0x00, \
    0x00, 0xF0, 0x00, \
    0x00, 0xF8, 0x03, \
    0x00, 0x0C, 0x03, \
    0x00, 0x06, 0x06, \
    0x00, 0x06, 0x00, \
    0x00, 0xF6, 0x00, \
    0x00, 0xFE, 0x03, \
    0x00, 0x0E, 0x03, \
    0x00, 0x06, 0x06, \
    0x00, 0x06, 0x06, \
    0x00, 0x06, 0x06, \
    0x00, 0x06, 0x06, \
    0x00, 0x0C, 0x03, \
    0x00, 0xFC, 0x03, \
    0x00, 0xF0, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00
TILE7:
.db 0x00, 0x00, 0x00, \
    0x00, 0xFE, 0x07, \
    0x00, 0xFE, 0x07, \
    0x00, 0x00, 0x03, \
    0x00, 0x00, 0x01, \
    0x00, 0x80, 0x01, \
    0x00, 0xC0, 0x00, \
    0x00, 0xC0, 0x00, \
    0x00, 0x60, 0x00, \
    0x00, 0x60, 0x00, \
    0x00, 0x20, 0x00, \
    0x00, 0x30, 0x00, \
    0x00, 0x30, 0x00, \
    0x00, 0x38, 0x00, \
    0x00, 0x18, 0x00, \
    0x00, 0x18, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00
TILE8:
.db 0x00, 0x00, 0x00, \
    0x00, 0x78, 0x00, \
    0x00, 0xFE, 0x00, \
    0x00, 0x87, 0x01, \
    0x00, 0x83, 0x01, \
    0x00, 0x83, 0x01, \
    0x00, 0x86, 0x01, \
    0x00, 0xFC, 0x00, \
    0x00, 0xFE, 0x00, \
    0x00, 0x87, 0x01, \
    0x00, 0x03, 0x03, \
    0x00, 0x03, 0x03, \
    0x00, 0x03, 0x03, \
    0x00, 0x87, 0x01, \
    0x00, 0xFE, 0x01, \
    0x00, 0x7C, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00
TILE9:
.db 0x00, 0x00, 0x00, \
    0x00, 0x78, 0x00, \
    0x00, 0xFE, 0x00, \
    0x00, 0x86, 0x01, \
    0x00, 0x03, 0x03, \
    0x00, 0x03, 0x03, \
    0x00, 0x03, 0x03, \
    0x00, 0x03, 0x03, \
    0x00, 0x87, 0x03, \
    0x00, 0xFE, 0x03, \
    0x00, 0x3C, 0x03, \
    0x00, 0x00, 0x03, \
    0x00, 0x83, 0x01, \
    0x00, 0xC7, 0x01, \
    0x00, 0xFF, 0x00, \
    0x00, 0x7C, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00
TILE11:
.db 0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x0C, 0x00, \
    0x00, 0x0C, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x0C, 0x00, \
    0x00, 0x0C, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00, \
    0x00, 0x00, 0x00
