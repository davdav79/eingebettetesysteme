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

;******************************* MAIN ************************************
.global main
main:

    ;Data Direction Register DDR for Port C as Output
    ser TEMP
    out	DDRC, TEMP
    ;all LEDs off
    ser TEMP
    out PORTC, TEMP

    clr LED_COUNTER 
    ;endless loop
    _mloop:
        rcall setLED
        ;increment LED_COUNTER
        rcall wait_450ms
	    inc LED_COUNTER
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

wait_15ms:
    ;Store Status Registers on Stack
    push r24 ;2
	in r24, SREG ;1
	push r24 ;2 
    push r25 ;2 
	in r25, SREG ;1
	push r25 ;2
    ldi r25,0xEA ;1
    ldi r24,0x59 ;1
    
    ;12
wait_15_loop: ;1
    sbiw r24,1 ;2
    brne wait_15_loop ;2
    ;restore status Register
    pop r24 ;2
	out SREG, r24 ;1			
	pop r24 ;2
    pop r25 ;2
	out SREG, r25 ;1			
	pop r25 ;2
    ;10
ret ;5

wait_450ms: 
    ;Store Status Registers on Stack
    push TEMP
	in TEMP, SREG
	push TEMP 
    ldi TEMP,0x1E
    
wait_450_loop:
    rcall wait_15ms
    dec TEMP ;2
    brne wait_450_loop ;2
    ;restore status Register
    pop TEMP
	out SREG, TEMP			
	pop TEMP
ret