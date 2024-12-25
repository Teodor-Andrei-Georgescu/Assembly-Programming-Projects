;
; a3part-D.asm
;
; Part D of assignment #3
;
;
; Student name:Teodor Andrei Georgescu
; Student ID: V00979120
; Date of completed work: 03/21/2023
;
; **********************************
; Code provided for Assignment #3
;
; Author: Mike Zastre (2022-Nov-05)
;
; This skeleton of an assembly-language program is provided to help you 
; begin with the programming tasks for A#3. As with A#2 and A#1, there are
; "DO NOT TOUCH" sections. You are *not* to modify the lines within these
; sections. The only exceptions are for specific changes announced on
; Brightspace or in written permission from the course instruction.
; *** Unapproved changes could result in incorrect code execution
; during assignment evaluation, along with an assignment grade of zero. ***
;


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================
;
; In this "DO NOT TOUCH" section are:
; 
; (1) assembler direction setting up the interrupt-vector table
;
; (2) "includes" for the LCD display
;
; (3) some definitions of constants that may be used later in
;     the program
;
; (4) code for initial setup of the Analog-to-Digital Converter
;     (in the same manner in which it was set up for Lab #4)
;
; (5) Code for setting up three timers (timers 1, 3, and 4).
;
; After all this initial code, your own solutions's code may start
;

.cseg
.org 0
	jmp reset

; Actual .org details for this an other interrupt vectors can be
; obtained from main ATmega2560 data sheet
;
.org 0x22
	jmp timer1

; This included for completeness. Because timer3 is used to
; drive updates of the LCD display, and because LCD routines
; *cannot* be called from within an interrupt handler, we
; will need to use a polling loop for timer3.
;
; .org 0x40
;	jmp timer3

.org 0x54
	jmp timer4

.include "m2560def.inc"
.include "lcd.asm"

.cseg
#define CLOCK 16.0e6
#define DELAY1 0.01
#define DELAY3 0.1
#define DELAY4 0.5

#define BUTTON_RIGHT_MASK 0b00000001	
#define BUTTON_UP_MASK    0b00000010
#define BUTTON_DOWN_MASK  0b00000100
#define BUTTON_LEFT_MASK  0b00001000

#define BUTTON_RIGHT_ADC  0x032
#define BUTTON_UP_ADC     0x0b0   ; was 0x0c3
#define BUTTON_DOWN_ADC   0x160   ; was 0x17c
#define BUTTON_LEFT_ADC   0x22b
#define BUTTON_SELECT_ADC 0x316

.equ PRESCALE_DIV=1024   ; w.r.t. clock, CS[2:0] = 0b101

; TIMER1 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP1=int(0.5+(CLOCK/PRESCALE_DIV*DELAY1))
.if TOP1>65535
.error "TOP1 is out of range"
.endif

; TIMER3 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP3=int(0.5+(CLOCK/PRESCALE_DIV*DELAY3))
.if TOP3>65535
.error "TOP3 is out of range"
.endif

; TIMER4 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP4=int(0.5+(CLOCK/PRESCALE_DIV*DELAY4))
.if TOP4>65535
.error "TOP4 is out of range"
.endif

reset:
; ***************************************************
; **** BEGINNING OF FIRST "STUDENT CODE" SECTION ****
; ***************************************************

; This section is just initalizing many different registers for use throughout the file
; PLEASE NOTE the lower number register will be low byte of each threshold

; Defining registers for button threshold which is 900
; This will indicate if a button is pushed
.def BL=r0       
.def BH=r1       

; Defining registers for Left button threshold (Biggest threshold beside 900)
.def LeftL=r2   
.def LeftH=r3  

; Defining registers for Right button threshold (Smallest threshold)
.def RightL=r4 
.def RightH=r5

; Defining registers for Up button threshold (Second smallest threshold)
.def UpL=r6 
.def UpH=r7

; Defining registers for down button threshold (Third smallest threshold)
.def DownL=r8 
.def DownH=r9 

; Intialzing all button boundaries into predefined registers 
ldi r16, low(BUTTON_LEFT_ADC)
mov LeftL, r16
ldi r16, high(BUTTON_LEFT_ADC)
mov LeftH, r16

ldi r16, low(BUTTON_RIGHT_ADC)
mov RightL, r16
ldi r16, high(BUTTON_RIGHT_ADC)
mov RightH, r16

ldi r16, low(BUTTON_UP_ADC)
mov UpL, r16
ldi r16, high(BUTTON_UP_ADC)
mov UpH, r16

ldi r16, low(BUTTON_DOWN_ADC)
mov DownL, r16
ldi r16, high(BUTTON_DOWN_ADC)
mov DownH, r16

ldi r16,0
; Setting current character index to 0, will update as I iterate through AVAILABLE_CHARSET
sts CURRENT_CHARSET_INDEX, r16 

; This is where I will store the column of each character
; Specifically this is a "list" of sorts where each "index" will represent a column on the LCD 
; Each "index" will just hold another value which indicates what leter from AVAILABLE_CHARSET that column holds
sts CURRENT_CHAR_INDEX, r16 


ldi YL, low(CURRENT_CHARSET_INDEX)
ldi YH, High(CURRENT_CHARSET_INDEX) ; Loading charset into Y
ldi XL, low(TOP_LINE_CONTENT)
ldi XH, High(TOP_LINE_CONTENT)      ; Loading topline content into X
clr r10                             ; Ensuring register is cleared
ldi r16, 0                          ; Ensuring counter is at 0
ldi r17, '0'                        

prep_board:
	st Y+, r10                  ; Loading each column with index value of 0
	st X+, r17                  ; Loading all topline content to 0 
	inc r16                     ; Incrementing counter
	cpi r16, 16                 ; 16 indicates iteration through all 15 bytes
	brlt prep_board

rcall lcd_init                      ; Intializing lcd, function from lcd.asm which is included in this project


; ***************************************************
; ******* END OF FIRST "STUDENT CODE" SECTION *******
; ***************************************************

; =============================================
; ====  START OF "DO NOT TOUCH" SECTION    ====
; =============================================

	; initialize the ADC converter (which is needed
	; to read buttons on shield). Note that we'll
	; use the interrupt handler for timer 1 to
	; read the buttons (i.e., every 10 ms)
	;
	ldi temp, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
	sts ADCSRA, temp
	ldi temp, (1 << REFS0)
	sts ADMUX, r16

	; Timer 1 is for sampling the buttons at 10 ms intervals.
	; We will use an interrupt handler for this timer.
	ldi r17, high(TOP1)
	ldi r16, low(TOP1)
	sts OCR1AH, r17
	sts OCR1AL, r16
	clr r16
	sts TCCR1A, r16
	ldi r16, (1 << WGM12) | (1 << CS12) | (1 << CS10)
	sts TCCR1B, r16
	ldi r16, (1 << OCIE1A)
	sts TIMSK1, r16

	; Timer 3 is for updating the LCD display. We are
	; *not* able to call LCD routines from within an 
	; interrupt handler, so this timer must be used
	; in a polling loop.
	ldi r17, high(TOP3)
	ldi r16, low(TOP3)
	sts OCR3AH, r17
	sts OCR3AL, r16
	clr r16
	sts TCCR3A, r16
	ldi r16, (1 << WGM32) | (1 << CS32) | (1 << CS30)
	sts TCCR3B, r16
	; Notice that the code for enabling the Timer 3
	; interrupt is missing at this point.

	; Timer 4 is for updating the contents to be displayed
	; on the top line of the LCD.
	ldi r17, high(TOP4)
	ldi r16, low(TOP4)
	sts OCR4AH, r17
	sts OCR4AL, r16
	clr r16
	sts TCCR4A, r16
	ldi r16, (1 << WGM42) | (1 << CS42) | (1 << CS40)
	sts TCCR4B, r16
	ldi r16, (1 << OCIE4A)
	sts TIMSK4, r16

	sei

; =============================================
; ====    END OF "DO NOT TOUCH" SECTION    ====
; =============================================

; ****************************************************
; **** BEGINNING OF SECOND "STUDENT CODE" SECTION ****
; ****************************************************

start:
	in temp, TIFR3 
	sbrs temp, OCF3A                  ; Checking if OCR3A bit is set, it indivates a clock cycle has finished for timer3
	rjmp start	                  ; If clock cycle is not finished then we keep looping until it is, then we want to re-update LCD display.
    
	ldi temp, 1<<OCF3A                ; Clear bit 1 in TIFR3 by writing logical one to its bit position, P163 of the Datasheet
	out TIFR3, temp

	ldi r16,high(BUTTON_SELECT_ADC)
	mov BH, r16
	ldi r16,low(BUTTON_SELECT_ADC)     ; Loading high and low ADC bits of from memory to check if buttion is pressed
	mov BL,r16
  
	rjmp timer3                        ; Jump to our polling loop to keep refreshing our LCD display

timer1:                                    ; Interupt timer that is used to check if button is pressed
		
		; Preserving contents of all registers on the stack before I use the registers
		; Also preserving the status registers
		push r16              
		push r17
		push r18
		push ZL
		push ZH
		push r19
		in r19, SREG
		push r19
		
		lds r16, ADCSRA            ; Starting ADC analog conversion
		ori r16, 0b01000000        ; Bit remain as 1 if conversion not done and changea to 0 if conversion is done
		sts ADCSRA, r16

	conversion_status: 
		lds r16, ADCSRA            ; Checking to see if conversion as finished
		andi r16, 0b01000000       ; If value is 1 it means conversion is still occuring so we keep branching until its 0 (done)
		brne conversion_status

		clr r17                    ; Clear resister to preparpare if button is pressed

		lds ZL, ADCL               ; Loading the converted ADC value into the Z register
		lds ZH, ADCH

		cp ZL, BL                  ; Comparing ADC value to boundary threshold value (900)
		cpc ZH, BH	           ; If ADC value is lower than boundary then some button is being pressed
		brlo pressed           
		sts BUTTON_IS_PRESSED, r17 ; If button not pressed we just load 0 value into BUTTON_IS_PRESSED
		rjmp done 

		pressed:                           ; If a button is being pressed then check which one
			ldi r17,1
			sts BUTTON_IS_PRESSED, r17 ; Ensuring value is pressed
			
			cp ZL, RightL
			cpc ZH, RightH             ; Checking if right button is pressed
			brlo R_pressed
			
			cp ZL, UpL
			cpc ZH, UpH                ; Checking if up button is pressed
			brlo U_pressed

			cp ZL, DownL
			cpc ZH, DownH              ; Checking if down button is pressed
			brlo D_pressed

			cp ZL, LeftL
			cpc ZH, LeftH              ; Checking if left button is pressed
			brlo L_pressed
			rjmp done                  ; If we get here it means there is nothing to display on board
			
		; This below all just stores which button was last pressed for later display
		R_pressed:                       
			ldi r18, 'R'
			sts LAST_BUTTON_PRESSED, r18
			rjmp done

		U_pressed: 
			ldi r18, 'U'
			sts LAST_BUTTON_PRESSED, r18
			rjmp done

		D_pressed: 
			ldi r18, 'D'
			sts LAST_BUTTON_PRESSED, r18
			rjmp done

		L_pressed: 
			ldi r18, 'L'
			sts LAST_BUTTON_PRESSED, r18
			rjmp done
	
	; Restoring all registers to values before interrupt
	done: 		
		pop r19
		out SREG, r19 
		pop r19
		pop ZH
		pop ZL
		pop r18
		pop r17
		pop r16
		reti

timer3:
; Note: There is no "timer3" interrupt handler as you must use
; timer3 in a polling style (i.e. it is used to drive the refreshing
; of the LCD display, but LCD functions cannot be called/used from
; within an interrupt handler).

	ldi r16, 1                      ; Row value as required of part A of the assignment 
	ldi r17, 15                     ; Column value as required of part A the assignment 
	push r16
	push r17
	rcall lcd_gotoxy                ; Grabing pushed row and column values that were pushed onto stack
	pop r17
	pop r16

	lds r18, BUTTON_IS_PRESSED	; Storing value of BUTTON_IS_PRESSSED
	sbrc r18,0	                ; If value is 0 we want to output a dash not a star so we skip rjmp to output_star
	rjmp output_star

	ldi r19, '-'	                ; Outputing a dash on LCD
	push r19
	rcall lcd_putchar		; Takes argument passed to stack and outputs it to LCD
	pop r19
	rjmp start


	output_star:                    ; Outputting star on LCD
		ldi r19, '*'
		push r19
		rcall lcd_putchar 
		pop r19
					; No rjmp to start because button is being pressed and we want to display that
	
	lds r20, LAST_BUTTON_PRESSED    ; Loading last char value of button pressed
	clr r17                         ; Making column 0 for diplay purposes (part b requirement)
	ldi r16,1                       ; Ensuring we display in row 1
	push r16
	push r17
	rcall lcd_gotoxy                ; Preparing to disply values at row 1 column 0, pops and pushes used for this function (part d requirement)
	pop r17
	pop r16

	ldi r21, ' '                   ; Preparing for correct disply
	
	; Compring which letter should be to displayed based on last button pressed
	cpi r20, 'R'
	breq display_R

	cpi r20, 'U'
	breq display_U

	cpi r20, 'D'
	breq display_D

	; If here it is letter L
	display_L:
		push r20
		rcall lcd_putchar      ; Outputing letter L
		pop r20
		
		; Outputting spaces after letter to override previous display
		push r21
		rcall lcd_putchar
		pop r21 
		push r21
		rcall lcd_putchar
		pop r21
		push r21
		rcall lcd_putchar
		pop r21

		rjmp start            ; Jump back to our infite loop since left or right button won't update topline content

	display_R:
		; Outputting 3 spaces first
		push r21
		rcall lcd_putchar
		pop r21 
		push r21
		rcall lcd_putchar
		pop r21
		push r21
		rcall lcd_putchar
		pop r21

		push r20
		rcall lcd_putchar     ; Outputing letter R
		pop r20

		rjmp start            ; Jump back to our infite loop since left or right button won't update topline content
		

	display_U:
		; Outputting 2 spaces first to override previous display
		push r21
		rcall lcd_putchar
		pop r21 
		push r21
		rcall lcd_putchar
		pop r21
		
		push r20
		rcall lcd_putchar     ; Outputing letter U
		pop r20

		; Outputting space after letter to override previous display
		push r21
		rcall lcd_putchar
		pop r21

		rjmp Checking_topline ; If up is pressed we want to update display value on topline content

	display_D:
		; Outputting 1 space first to override previous display
		push r21
		rcall lcd_putchar
		pop r21
		
		push r20
		rcall lcd_putchar    ; Outputing letter D
		pop r20

		; Outputting spaces after letter to override previous display
		push r21
		rcall lcd_putchar
		pop r21 
		push r21
		rcall lcd_putchar
		pop r21
		push r21

		rjmp Checking_topline ; If down is pressed we want to update display value on topline content
	
	Checking_topline:
		ldi r16,0                      ; Setting row to 0 to display charset in top row
		lds r17, CURRENT_CHAR_INDEX    ; Getting correct column for letter display
		push r16
		push r17
		rcall lcd_gotoxy               ; Setting the lcd to display at top left index
		pop r17
		pop r16
		
		clr r10
		ldi ZL, low(TOP_LINE_CONTENT)  ; Indirectly loading topline content
		ldi ZH, high(TOP_LINE_CONTENT)
		add ZL, r17                    ; Off setting to correct byte of memory based on current display column value
		adc ZH, r10
		ld r22,Z                       ; Loading the letter at the current display column into r22
		
		push r22
		rcall lcd_putchar              ; Outputting the letter onto LCD
		pop r22

		rjmp start

; This timer is another interupt timer
timer4: 

	; Preserving values of registers onto the stack before I use the registers
	push r16              
	push r17
	push r18
	push ZL
	push ZH
	push YL
	push YH
	push XL
	push XH
	push r19
	in r19, SREG 
	push r19

	ldi ZL, low(AVAILABLE_CHARSET <<1)    ; Loading current letter from charset into Z register
	ldi ZH, high(AVAILABLE_CHARSET <<1)

	lds r16, BUTTON_IS_PRESSED            ; Checking to see if a button is pressed, if its not then we just branch to the reti
	cpi r16, 0
	breq nothing

	lds r16, LAST_BUTTON_PRESSED         ; Loading last button pressed
	lds r18, CURRENT_CHAR_INDEX          ; Loading display row

	; I am indirecetly accessing and offsetting to correct spot in memory for current display column  
	clr r10 
	ldi YL, low(CURRENT_CHARSET_INDEX)
	ldi YH, High(CURRENT_CHARSET_INDEX) ; Loading to first memory location of charset
	add YL, r18                         ; Offesting to corrent spot in memory for current row
	adc YH, r10
	ld r17, Y                           ; Storing value from that spot in memory

	ldi XL, low(TOP_LINE_CONTENT)
	ldi XH, high(TOP_LINE_CONTENT)      ; Loading topline content indirectly
	add XL, r18                         ; Offesetting to correct spot in memory based on currenty display column
	adc XH, r10

	cpi r16, 'L'
	breq left_is_pressed                ; If left is pressed want to decrement display row

	cpi r16,'R'
	breq right_is_pressed               ; If right is pressed we want to increment display row

	cpi r16,'U'
	breq up_is_pressed                  ; If up is pressed we want to increment charset letter to display

	cpi r16, 'D'                        ; If letter it not D then select button is pressed we again we want to do nothing
	brne nothing
					    ; If letter is D we decrement charset doing this right underneath
	
	cpi r17, 0                          ; If 0 then we are at start of string so nothing to decrement
	breq nothing
	dec r17                        
	st Y, r17                           ; Storing new index to offset spot in memeory
	add ZL, r17                         ; Since Z always loads into start of memory we add offset to get to current index
	lpm r18, Z 
	st X, r18                           ; Storing desired character into correct byte of memory in topline content
	rjmp nothing

	up_is_pressed:
		; This first part is checking if we are already at end of string
		add ZL, r17 
		lpm r18, Z 
		cpi r18, 0
		breq nothing

		; Could be at spot before the end so we increment and recheck if we are end of string
		inc r17
		st Y, r17                  ; Store new char index at correct memory location
		ldi r17, 1	           ; r17 here will already loaded with last iterations index so only increment by 1
		add ZL, r17                ; Since Z will now be one iteration behind we add 1 to get to correct index
		lpm r18, Z
		cpi r18, 0	           ; If we are at the end of the string we don't want to store it in TOP_LINE_CONTENT
		breq nothing
		st X, r18                  ; Storing desired char into correct offset byte of memory in topline content

	nothing: 			   ; Restoring all registers to their orignal states 
		pop r19
		out SREG, r19 
		pop r19
		pop XH
		pop XL
		pop YH
		pop YL
		pop ZH 
		pop ZL
		pop r18
		pop r17
		pop r16
		reti

	left_is_pressed:
		cpi r18, 0                   ; Checking to see if we are at left most index 
		breq nothing                 ; If we are there is nowhere else to go on the board so do nothing 
		dec r18
		sts CURRENT_CHAR_INDEX, r18  ; Shift to left, decrement the column and store it

		rjmp nothing

	right_is_pressed:
		cpi r18, 15                  ; Checking if we are at rightmost index 
		breq nothing                 ; If we are we have no where else to go so don't increment index
		inc r18
		sts CURRENT_CHAR_INDEX, r18  ; Shift to the right, increment column and store it
	
		rjmp nothing



; ****************************************************
; ******* END OF SECOND "STUDENT CODE" SECTION *******
; ****************************************************


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

; r17:r16 -- word 1
; r19:r18 -- word 2
; word 1 < word 2? return -1 in r25
; word 1 > word 2? return 1 in r25
; word 1 == word 2? return 0 in r25
;
compare_words:
	; if high bytes are different, look at lower bytes
	cp r17, r19
	breq compare_words_lower_byte

	; since high bytes are different, use these to
	; determine result
	;
	; if C is set from previous cp, it means r17 < r19
	; 
	; preload r25 with 1 with the assume r17 > r19
	ldi r25, 1
	brcs compare_words_is_less_than
	rjmp compare_words_exit

compare_words_is_less_than:
	ldi r25, -1
	rjmp compare_words_exit

compare_words_lower_byte:
	clr r25
	cp r16, r18
	breq compare_words_exit

	ldi r25, 1
	brcs compare_words_is_less_than  ; re-use what we already wrote...

compare_words_exit:
	ret

.cseg
AVAILABLE_CHARSET: .db "0123456789abcdef_", 0


.dseg

BUTTON_IS_PRESSED: .byte 1			; updated by timer1 interrupt, used by LCD update loop
LAST_BUTTON_PRESSED: .byte 1        ; updated by timer1 interrupt, used by LCD update loop

TOP_LINE_CONTENT: .byte 16			; updated by timer4 interrupt, used by LCD update loop
CURRENT_CHARSET_INDEX: .byte 16		; updated by timer4 interrupt, used by LCD update loop
CURRENT_CHAR_INDEX: .byte 1			; ; updated by timer4 interrupt, used by LCD update loop


; =============================================
; ======= END OF "DO NOT TOUCH" SECTION =======
; =============================================


; ***************************************************
; **** BEGINNING OF THIRD "STUDENT CODE" SECTION ****
; ***************************************************


; If you should need additional memory for storage of state,
; then place it within the section. However, the items here
; must not be simply a way to replace or ignore the memory
; locations provided up above.


; ***************************************************
; ******* END OF THIRD "STUDENT CODE" SECTION *******
; ***************************************************
