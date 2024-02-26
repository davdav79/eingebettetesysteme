;**************************************************************************
;Universitaet der Bundeswehr Muenchen
;02.12.2020 UN Version for VS-Code
;2011       Klaus Buchenrieder Initial version
;
;your comment
;
;**************************************************************************
/* The following is needed to subtract 0x20 from I/O addresses */ 
#define __SFR_OFFSET 0 

#include <avr/io.h>

.section .text

;define a name for Register 16 and 17
#define TEMP R16
#define LED_COUNTER R17
#define CNTR R18
#define DIRECTION R19

;******************************* MAIN ************************************
.global main
main:
    ;********** Stack Pointer **********
    ;set Stack Pointer to the top of the RAM (good practice)
    ldi TEMP, hi8(RAMEND) ;Set Stack Pointer to top of RAM
	out SPH, TEMP ;SPH: Stack Pointer High Byte
	ldi TEMP, lo8(RAMEND)  ;Set Stack Pointer to top of RAM     
	out SPL, TEMP ;SPL: Stack Pointer Low Byte

    ;********** Port C - Configuration **********
    ;set Port C as output (LEDs are connected to Port C)
    ser TEMP ;set all bits of TEMP to 1
    out DDRC, TEMP ;set all pins of port C as output

    ;all LEDs off (Port C is low active)
    ser TEMP ;Set all bits to 1
    out PORTC, TEMP ;PORTC: Port C Data Register
    
    ;********** Timer3 - Configuration for a 450ms delay **********
    ;enable Timer 3 in the Power Reduction Register 1 (PRR1) (in PRR1 is a register that controls the power to the peripherals in order to save power)
    ldi TEMP,(0<<PRTIM3) ;PRTIM3 must be 0 to enable Timer3
    sts PRR1,TEMP ;sts = store direct to Data Space ;out = out to I/O location ;PRR1 is a register on the CPU not an I/O location
    ;Timers are used to generate time delays, measure time, count events, and generate PWM signals therefore they have different modes
    ;CTC (Clear Timer on Compare Match) mode is used to generate a time delay by comparing the value in the Timer/Counter Register (TCNT) with the value in the Output Compare Register (OCR)
    ;The OCR can be configured with a value, the cpu increments the TCNT with each clock cycle and when the TCNT is equal to the value in the OCR the Timer generates an interrupt
    ;To configure Timer3 the TCCR3A and TCCR3B registers must be set
    ldi TEMP,(1<<WGM32) | (1<<CS32) ;WGM32 = 1 to set Timer3 to CTC mode ;CS32 = 1 to set the prescaler to 256: 16MHz/256 = 62.5kHz because we want 450ms delay: 62.5kHz * 450ms = 28125 and 16 bit Timer3 can count up to 65535
    sts TCCR3B,TEMP ;configure Timer3
    ;Interrupt mask register
    ldi TEMP,(1<<OCIE3A) ;OCIE3A = 1 to enable the Timer3 compare match A interrupt ;there are different registers the timer can use to generate an interrupt ;here we use the Output Compare A Match Interrupt Enable
    sts TIMSK3,TEMP 
    ;Output Compare Register A (OCR3A) is used to set the value the Timer3 is compared with ; we have to load 0x6DDD in the OCR3A Register: (16MHz/256) * 450ms = 28125 = 0x6DDD
    ;cli ;cli = clear global interrupt flag
    ldi TEMP, 0x6D ;load the high byte of 0x6DDD
    sts OCR3AH,TEMP ;OCR3AH is the high byte of the OCR3A register
    ldi TEMP, 0xDD ;load the low byte of 0x6DDD
    sts OCR3AL,TEMP ;OCR3AL is the low byte of the OCR3A register
    
    ;enable  the global interrupts
    sei ;sei = set global interrupt flag

    ;********** init for the programm logic of SHIFT LED **********
    ;initialize LED_COUNTER
	ldi LED_COUNTER,0x1

    ;initialize DIRECTION
    ldi DIRECTION, 0x0
    ldi CNTR, 0x0

    ;********** Main Loop **********
    ;endless loop
    _mloop:
    rjmp _mloop

;******************************* ISR for Timer3 ************************************
;An Interrupt Service Routine (ISR) is a function that is called when an interrupt occurs:
;At first the CPU saves the current program counter on the stack (PUSH) 
;and then jumps to the ISR that is triggerd and executes the code in the ISR. The interrupt that is triggered does this by setting the program counter to the address of the ISR 
;and then returns to the main program (POP)

;If the Timer3 compare match A interrupt is enabled, the ISR is called when the counter reaches the value in the OCR3A register
.global TIMER3_COMPA_vect
TIMER3_COMPA_vect:
    ;toggle LED6
    ;SBI PINC, PC6 
    inc CNTR ;we use counter to switch the DIRECTION every 5th time
    
    RCALL shift_led ;shift_led uses the DIRECTION to shift the LED_COUNTER to the left or right
    CPI CNTR, 0x5 ;CPI Compare with Immediate (if CNTR == 5, reset_cntr)
    BREQ reset_cntr 
reti

reset_cntr:
;SBI PINC, PC6 
    ldi CNTR,0x0
    com DIRECTION
    ;rcall led_start_high
    TST DIRECTION
        BREQ led_start_low
        BRNE led_start_high
reti

led_start_low:
	ldi LED_COUNTER,0x1
reti

led_start_high:
	ldi LED_COUNTER,0x80
reti

;**************************** OUT LED *****************************************
setLED:
    ;Store Status Registers on Stack
    push TEMP
	in TEMP, SREG
	push TEMP

    ;One’s Complement
    com	LED_COUNTER			
    ;set PORTC	
	out PORTC,LED_COUNTER
    ;One’s Complement
	com LED_COUNTER
    
    ;restore status Register
    pop TEMP
	out SREG, TEMP			
	pop TEMP
ret

;**************************** SHIFT LED *****************************************
shift_led:
    ;SBI PINC, PC0
    TST DIRECTION ; if DIRECTION == 0, shift_left ; else shift_right
    BREQ shift_left
    BRNE shift_right
ret

shift_left:
    ;SBI PINC, PC1
    rcall setLED
    lsl LED_COUNTER ;lsl = logical shift left
    lsl LED_COUNTER
ret

shift_right:
    ;SBI PINC, PC2
    rcall setLED
    lsr LED_COUNTER 
    lsr LED_COUNTER
ret