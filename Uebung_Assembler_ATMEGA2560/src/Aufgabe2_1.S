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
.global main ;.global makes the main function visible to the linker ;the linker is a program that combines object files into an executable program
main:

    ;Data Direction Register DDR for Port C as Output
    ser TEMP ; set all bits to 1
    out	DDRC, TEMP ; set all bits to 1 in DDRC (Port C is output/GPIO)
    ;all LEDs off
    ser TEMP
    out PORTC, TEMP ; PORTx is the register to write to the GPIO pins; PINx is the register to read from the GPIO pins

    clr LED_COUNTER 
    ;endless loop
    _mloop:
        rcall setLED
        ;increment LED_COUNTER
        rcall wait_450ms
	    inc LED_COUNTER
    rjmp _mloop

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

;******************************* wait_15ms ************************************
;The Arduino has a clock speed of 16 MHz. In order to wait 15 ms, we need to wait 240,000 cycles (16x10^6 Hz * 15x10^-3 s).
;sbiw: Subtract Immediate from Word -> takes 2 cycles
;brne: looks at the zero flag (Z) and jumps if it is not set -> 1 cycle if the jump is not taken and 2 cycles if the jump is taken. (if(Z==0) PC = PC + k + 1)
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
    
    wait_15_loop: ;1
        sbiw r24,1 ;2
        brne wait_15_loop ;2
        ; 1 if not taken

    ;one loop takes 4 cycles
    ;240,000 cycles - (2+1+2+2+1+2+)*2 - (1+1) - 1 - 5 = 239,972 cycles in hex
    ;239,972 cycles / 4 = 59,993 cycles in hex = 0xEA59 --> 16 bit number --> 2 registers needed --> fill the high byte first

    ;restore status Register
    pop r24 ;2
	out SREG, r24 ;1			
	pop r24 ;2
    pop r25 ;2
	out SREG, r25 ;1			
	pop r25 ;2
ret ;5

;******************************* wait_450ms ************************************
;The Arduino has a clock speed of 16 MHz. In order to wait 450 ms, we need to wait 7,200,000 cycles (16x10^6 Hz * 450x10^-3 s).
wait_450ms: 
    ;Store Status Registers on Stack
    push TEMP ;2
	in TEMP, SREG ;1
	push TEMP ;2

    ldi TEMP,0x1E ;1
    
    wait_450_loop:
        rcall wait_15ms ;2
        dec TEMP ;1
        brne wait_450_loop ;2 
        ; 1 if not taken
    ;one loop iteration takes 240,000 + 5 = 240,005 cycles
    ;7,200,000 - (2+1+2)*2 - 1 - 1 - 5 = 7,199,983 cycles
    ;7,199,983 / 240,005 = 29.999 cycles in hex = 0x1E --> 8 bit number --> 1 register enough

    ;restore status Register
    pop TEMP ;2
    out SREG, TEMP ;1
    pop TEMP ;2
ret ;5