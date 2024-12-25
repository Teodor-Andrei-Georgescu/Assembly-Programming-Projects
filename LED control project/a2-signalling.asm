; a2-signalling.asm
; University of Victoria
; CSC 230: Spring 2023
; Instructor: Ahmad Abdullah
;
; Student name:Teodor Andrei Georgescu
; Student ID: *********
; Date of completed work: 2/27/23
;
; *******************************
; Code provided for Assignment #2 
;
; Author: Mike Zastre (2022-Oct-15)
;
 
; This skeleton of an assembly-language program is provided to help you
; begin with the programming tasks for A#2. As with A#1, there are "DO
; NOT TOUCH" sections. You are *not* to modify the lines within these
; sections. The only exceptions are for specific changes changes
; announced on Brightspace or in written permission from the course
; instructor. *** Unapproved changes could result in incorrect code
; execution during assignment evaluation, along with an assignment grade
; of zero. ****

.include "m2560def.inc"
.cseg
.org 0

; ***************************************************
; **** BEGINNING OF FIRST "STUDENT CODE" SECTION ****
; ***************************************************

	; Initializion code is written in this section

	; Preparing ports to be able turn on leds
	ldi r16, 0xFF 
	sts DDRL, r16
	out DDRB, r16
	clr r16
	
	clr r20 

	; Intatizing stack pointer
	ldi r20, low(RAMEND)
	out SPL, r20
	ldi r20, high(RAMEND)
	out SPH, r20
	

; ***************************************************
; **** END OF FIRST "STUDENT CODE" SECTION **********
; ***************************************************

; ---------------------------------------------------
; ---- TESTING SECTIONS OF THE CODE -----------------
; ---- TO BE USED AS FUNCTIONS ARE COMPLETED. -------
; ---------------------------------------------------
; ---- YOU CAN SELECT WHICH TEST IS INVOKED ---------
; ---- BY MODIFY THE rjmp INSTRUCTION BELOW. --------
; -----------------------------------------------------

	rjmp test_part_e

	; Test code


test_part_a:
	ldi r16, 0b00100001
	rcall set_leds
	rcall delay_long

	clr r16
	rcall set_leds
	rcall delay_long

	ldi r16, 0b00111000
	rcall set_leds
	rcall delay_short

	clr r16
	rcall set_leds
	rcall delay_long

	ldi r16, 0b00100001
	rcall set_leds
	rcall delay_long

	clr r16
	rcall set_leds

	rjmp end


test_part_b:
	ldi r17, 0b00101010
	rcall slow_leds
	ldi r17, 0b00010101
	rcall slow_leds
	ldi r17, 0b00101010
	rcall slow_leds
	ldi r17, 0b00010101
	rcall slow_leds

	rcall delay_long
	rcall delay_long

	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds
	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds
	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds
	ldi r17, 0b00101010
	rcall fast_leds
	ldi r17, 0b00010101
	rcall fast_leds

	rjmp end

test_part_c:
	ldi r16, 0b11111000
	push r16
	rcall leds_with_speed
	pop r16

	ldi r16, 0b11011100
	push r16
	rcall leds_with_speed
	pop r16

	ldi r20, 0b00100000
test_part_c_loop:
	push r20
	rcall leds_with_speed
	pop r20
	lsr r20
	brne test_part_c_loop

	rjmp end


test_part_d:
	ldi r21, 'E'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long

	ldi r21, 'A'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long


	ldi r21, 'M'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long

	ldi r21, 'H'
	push r21
	rcall encode_letter
	pop r21
	push r25
	rcall leds_with_speed
	pop r25

	rcall delay_long

	rjmp end


test_part_e:
	ldi r25, HIGH(WORD02 << 1)
	ldi r24, LOW(WORD02 << 1)
	rcall display_message
	rjmp end

end:
    rjmp end






; ****************************************************
; **** BEGINNING OF SECOND "STUDENT CODE" SECTION ****
; ****************************************************

; This is a function that will turn on the correct LEDs based on the given letter
set_leds:

	; Creating a mask to set the coresponding bits 
	clr r18
	ldi r18, 0b10000000
	.def bit_to_set = r18

	;Predefining bits to be check that will indicate to set LEDS on or off
	clr r19
	ldi r19, 0b00000001 
	.def bit_to_check = r19
	
	; Defining a count to keep track of how many bit I have checked
	clr r20
	.def count = r20
	
	; Set the coresponding bits for LEDs in portL
	clr r21
	.def L = r21

	; Set coresponding bit for LEDS in portB
	clr r22 
	.def B = r22

	; Defining a temporary register things to do certain operations without altering original argument 
	clr r23
	.def temp = r23

	; This is a loop that check if we need to set LEDs in portL
	loopL: 
		mov temp, r16
		and temp, bit_to_check ; Check if the bit needs to be set and branch to set the bit if needed
		brne add_bitL
		lsr bit_to_set ; Right shift over to next the bit for the next loop iteration, done twice because only odd bits set LEDs
		lsr bit_to_set
		lsl bit_to_check ; Left shift to have correct bit for checking next loop iteration
		inc count 
		cpi count, 4 ; After checking 3 bits we are done with portL and must go to portB
		brne loopL
		ldi bit_to_set, 0b00001000 ; Geting ready to set bits in portB
		rjmp loopB

	; This is a loop that sets LED bits in portL
	add_bitL:
		add L, bit_to_set ; The same as loopL above but bits get set here not just checked
		lsr bit_to_set
		lsr bit_to_set
		lsl bit_to_check
		inc count
		cpi count, 4
		brne loopL
		ldi bit_to_set, 0b00001000

	; This is a loop that checks if we need to set LEDs in portB
	; This loop behaves exactly like the one for portL
	loopB:
		mov temp, r16 
		and temp, bit_to_check
		brne add_bitB
		lsr bit_to_set
		lsr bit_to_set
		lsl bit_to_check
		inc count
		cpi count, 6 ; If count is 6 then all 5 bits that corespond to turning on LEDs (bit_to_check) have been checked
		brne loopB
		rjmp finish
	
	; This is a loop that sets LED bits in portB
	; It works just like its counterpart for portL
	add_bitB:
		add B, bit_to_set 
		lsr bit_to_set
		lsr bit_to_set
		lsl bit_to_check
		inc count
		cpi count, 6
		brne loopB

	; This unsets alll defined registers and turns on LEDs controlled by their ports
	finish:
		sts PORTL, L 
		out PORTB, B 
		.undef bit_to_set
		.undef bit_to_check
		.undef count
		.undef L
		.undef B
		.undef temp 
		ret 

; This function makes the LEDs have long delay between turning on
slow_leds:
	mov r16, r17 ; Copy r17 into r16 for set_leds to work
	rcall set_leds
	rcall delay_long ; Call delay_long to have 1 second delay
	
	clr r16
	ldi r16, 0 ; Loading r16 with 0 and call set_leds to turn off the leds
	rcall set_leds

	ret

; This function makes the LEDs have a short delay before turning on
; This works exactly the same as slow_leds but calls a different delay
fast_leds:
	mov r16, r17 
	rcall set_leds
	rcall delay_short 

	clr r16
	ldi r16, 0 
	rcall set_leds

	ret

; This function is used to dictate the delay between led light ups
leds_with_speed:
	
	; Preserving Z register to Load pointer
	push ZL 
	push ZH

	; Preserving this register to copy desired argument from stack
	push r18
	
	; Loading stack pointers into register to copy argument
	in ZH, SPH 
	in ZL, SPL

	ldd r18, Z+7 ; Offset stack pointer to point in memory where argument is stored
	mov r17, r18 ; Copy paramater into r17 which is needed for the slow or fast led call

	sbrs r18, 6  ; Since bits 6 and 7 are only ever both set or both unset we check if bit 6 is set
	rjmp fast    ; If bit 6 is set then we want to call slow_leds and not fast so we skip this jump
	rcall slow_leds
	
	done:	     ; Restoring stack to what original state
		pop r18	
		pop ZH
		pop ZL
		ret
	
	fast:	     ; Used by rjmp command in the case where we want to call fast_leds
		rcall fast_leds
		rjmp done


; Note -- this function will only ever be tested
; with upper-case letters, but it is a good idea
; to anticipate some errors when programming (i.e. by
; accidentally putting in lower-case letters). Therefore
; the loop does explicitly check if the hyphen/dash occurs,
; in which case it terminates with a code not found
; for any legal letter.

; This function grabs the letters from the stack and endcode them into a hexadecimal value for functions above
encode_letter:
	
	; Preserving this register to set stack pointer 
	push YH 
	push YL

	; Preserving register for usage
	push ZH	
	push ZL

	; Defining and preserving a register where I will store my letter
	push r18
	.def letter = r18 

	; Defining and preserving a register to store hexidecimal value
	; This will include the LEDs to turn on and the speed
	push r19
	.def LedEncoding = r19 

	; Defining and preserving the encoding that indicates a led is off
	push r23
	.def LedOff = r23 

	; Defining and preserving register to do opertations without altering orginal arguments 
	push r22
	.def TempUse = r22 

	ldi ZL, low(PATTERNS << 1)   ; Loading registers with necessary values
	ldi ZH, high(PATTERNS << 1 ) ; Z register will hold the Letter encodings
	in YH, SPH                   ; Defining my stack pointer 
	in YL, SPL
	ldd letter, Y+12             ; Grabing arugment from corrected adress in memory
	ldi LedEncoding, 0b00100000  ; Value to turn on leds from left to right, also doubles down as a mask
	lpm TempUse, Z               ; Loading first letter from PATTERNS list into a temp register
	ldi LedOff, 0x2E             ; This is the endcoding for "." which means off
	clr r25
	ldi r25, 0b11000000          ; Loading r25 with long delay, can unset it later if necssary

	FindLetter:
		cp letter, TempUse   ; Comparing to see if I have found the same argument letter in the PATTERNS list
		breq LedPattern      ; When I find the right letter I branch to start setting leds 
		adiw Z, 8            ; If I made it here then the letters don't match
		lpm TempUse, Z       ; Update temp register for next iteration of "loop"
		rjmp FindLetter

	LedPattern:
		cpi LedEncoding, 0   ; If this vlaue is 0 then I have looped through the 6 bits to set corresponding LEDs
		breq EncodeLength    ; While setting LED values speeds must also be set
		adiw Z, 1            ; Moving pointer to next byte to which will be either a "." or a "o" (off or on)
		lpm TempUse, Z
		cp TempUse, LedOff   ; Checking if I need to turn LED off
		brne SetBit          ; Otherwise I turn LED on
		lsr LedEncoding      ; Bit is off we want to shift over by 1 to prepare for next interation
		rjmp LedPattern
	
	EncodeLength:
		adiw Z,1             ; Once here all bits for LEDs are set, now check if letter is long or short delay
		lpm TempUse, Z
		cpi TempUse, 2       ; If length duration is 2 (indates short) go mask r25 to short cause it is currently set to long
		breq MakeShort
		rjmp DoneLetter

	SetBit:
		add r25, LedEncoding ; Since r25 = 0b11000000 the 6 bits for leds are all off so we can just add with LedEncoding which has all needed LED bits set
		lsr LedEncoding	     ; Now we shift LedEncoding bit over by 1 to match encodings from Patterns
		rjmp LedPattern

	MakeShort:
		andi r25, 0b00111111 ; Set Leds to short duration using this mask

	DoneLetter:                  ; Restoring stack to original state and unset registers
		pop r22
		pop r23
		pop r19
		pop r18
		pop ZL
		pop ZH
		pop XL
		pop XH
		.undef letter
		.undef LedEncoding
		.undef LedOff
		.undef TempUse

		ret

; This function puts all fuctions above together and lights up a given phrase with its LED encoding
; This will light up on letter at a time.
display_message:
	
	; Preserving registers for use
	push r25 
	push r24
	push r27
	push ZH
	push ZL

	; Copying agrument from memory address into Z register
	mov ZL, r24 
	mov ZH, r25

	LoopThroughWord:
		lpm r27, Z+       ; Move stack memory to next letter
		cpi r27, 0        ; If 0 is loaded then the word has ended
		breq EndOfWord

		push r27          ; Push letter that needs to be encoded to stack
		rcall encode_letter
		pop r27

		push r25          ; Push encoded letter and turn on its LEDs
		rcall leds_with_speed
		pop r25

		rcall delay_short
		rjmp LoopThroughWord

	EndOfWord:                ; Restore stack to original state
		pop ZL
		pop ZH
		pop r27
		pop r24
		pop r25
		ret


; ****************************************************
; **** END OF SECOND "STUDENT CODE" SECTION **********
; ****************************************************




; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

; about one second
delay_long:
	push r16

	ldi r16, 14
delay_long_loop:
	rcall delay
	dec r16
	brne delay_long_loop

	pop r16
	ret


; about 0.25 of a second
delay_short:
	push r16

	ldi r16, 4
delay_short_loop:
	rcall delay
	dec r16
	brne delay_short_loop

	pop r16
	ret

; When wanting about a 1/5th of a second delay, all other
; code must call this function
;
delay:
	rcall delay_busywait
	ret


; This function is ONLY called from "delay", and
; never directly from other code. Really this is
; nothing other than a specially-tuned triply-nested
; loop. It provides the delay it does by virtue of
; running on a mega2560 processor.
;
delay_busywait:
	push r16
	push r17
	push r18

	ldi r16, 0x08
delay_busywait_loop1:
	dec r16
	breq delay_busywait_exit

	ldi r17, 0xff
delay_busywait_loop2:
	dec r17
	breq delay_busywait_loop1

	ldi r18, 0xff
delay_busywait_loop3:
	dec r18
	breq delay_busywait_loop2
	rjmp delay_busywait_loop3

delay_busywait_exit:
	pop r18
	pop r17
	pop r16
	ret


; Some tables
.cseg
//.org 0x600 ; Commented this out because it clears byte mismatch error that would appear with it left uncommented
				;This causes my code to work on more of the boards in this room when its commented out

PATTERNS:
	; LED pattern shown from left to right: "." means off, "o" means
    ; on, 1 means long/slow, while 2 means short/fast.
	.db "A", "..oo..", 1
	.db "B", ".o..o.", 2
	.db "C", "o.o...", 1
	.db "D", ".....o", 1
	.db "E", "oooooo", 1
	.db "F", ".oooo.", 2
	.db "G", "oo..oo", 2
	.db "H", "..oo..", 2
	.db "I", ".o..o.", 1
	.db "J", ".....o", 2
	.db "K", "....oo", 2
	.db "L", "o.o.o.", 1
	.db "M", "oooooo", 2
	.db "N", "oo....", 1
	.db "O", ".oooo.", 1
	.db "P", "o.oo.o", 1
	.db "Q", "o.oo.o", 2
	.db "R", "oo..oo", 1
	.db "S", "....oo", 1
	.db "T", "..oo..", 1
	.db "U", "o.....", 1
	.db "V", "o.o.o.", 2
	.db "W", "o.o...", 2
	.db "W", "oo....", 2
	.db "Y", "..oo..", 2
	.db "Z", "o.....", 2
	.db "-", "o...oo", 1   ; Just in case!

WORD00: .db "HELLOWORLD", 0, 0
WORD01: .db "THE", 0
WORD02: .db "QUICK", 0
WORD03: .db "BROWN", 0
WORD04: .db "FOX", 0
WORD05: .db "JUMPED", 0, 0
WORD06: .db "OVER", 0, 0
WORD07: .db "THE", 0
WORD08: .db "LAZY", 0, 0
WORD09: .db "DOG", 0

; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================

