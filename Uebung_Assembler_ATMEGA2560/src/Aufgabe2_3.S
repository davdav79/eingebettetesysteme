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

;Interrupt ISR
.global TIMER3_COMPA_vect
TIMER3_COMPA_vect:
    ;toggle LED6
    ;SBI PINC, PC6 
    inc CNTR
    
    RCALL shift_led
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


;******************************* MAIN ************************************
.global main
main:
    ;Stack Pointer
    ldi TEMP, hi8(RAMEND) ;Set Stack Pointer to top of RAM
	out SPH, TEMP ;SPH: Stack Pointer High Byte
	ldi TEMP, lo8(RAMEND)  ;Set Stack Pointer to top of RAM     
	out SPL, TEMP ;SPL: Stack Pointer Low Byte

    ;Data Direction Register DDR for Port C
    ser TEMP ;Set all bits to 1 --> Port C as Output
    out	DDRC, TEMP ;DDRC: Data Direction Register C

    ;all LEDs off
    ser TEMP ;Set all bits to 1
    out PORTC, TEMP ;PORTC: Port C Data Register

    ;initialize LED_COUNTER
	ldi LED_COUNTER,0x1

    ;initialize DIRECTION
    ldi DIRECTION, 0x0
    ldi CNTR, 0x0
    
    ;Power Reduction Timer/Counter3 (Writing a logic one to this bit shuts down the Timer/Counter3 module)
    LDI TEMP, (0<<PRTIM3)
    STS PRR1, TEMP
    
    ;Configuration Timer/Counter 3 Control Register B
    LDI TEMP, (1<<WGM32) |(1<<CS32) ;WGM32: Waveform Generation Mode CTC, CS32: Clock Select prescaler 256 16MHz/256 = 62500Hz
    STS TCCR3B, TEMP ;TCCR3B: Timer/Counter 3 Control Register B

    ;Configuration Timer/Counter 3 Interrupt Mask Register
    LDI TEMP, (1<<OCIE3A) ;OCIEnA: Output Compare A Match Interrupt Enable
    STS TIMSK3, TEMP ;TIMSK3: Timer/Counter 3 Interrupt Mask Register

    ;Configuration Timer/Counter 3 Output Compare Register A (because 0CIE3A is set in TIMSK3, the interrupt will be triggered when the counter reaches the value in OCR3A)
    cli
    LDI TEMP, 0x6D ;(16MHz/256)*450ms = 28125 
    STS OCR3AH, TEMP ;Output Compare Register 3 A High Byte
    LDI TEMP, 0xDD 
    STS OCR3AL, TEMP ;Output Compare Register 3 A Low Byte
    
    ;enable  the global interrupts
    sei
    
    ;endless loop
    _mloop:
    rjmp _mloop

;****************************OUT LED*****************************************
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

shift_led:
    ;SBI PINC, PC0
    TST DIRECTION ; if DIRECTION == 0, shift_left ; else shift_right
    BREQ shift_left
    BRNE shift_right
ret

shift_left:
    ;SBI PINC, PC1
    rcall setLED
    lsl LED_COUNTER
    lsl LED_COUNTER
ret

shift_right:
    ;SBI PINC, PC2
    rcall setLED
    lsr LED_COUNTER 
    lsr LED_COUNTER
ret