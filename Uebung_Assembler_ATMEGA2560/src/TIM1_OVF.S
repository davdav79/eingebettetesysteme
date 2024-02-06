;************************************
;Universitaet der Bundeswehr Muenchen
;25.01.2021 UN Initial version
;
;Toggle LED0 with Timmer1 Overflow
;************************************
;The following is needed to subtract 
;0x20 from I/O addresses
#define __SFR_OFFSET 0

#include <avr/io.h>

;Code segment for the flash memory
.section .text

;define a name for Register 16
#define TEMP R16

;Interrupt ISR
.global TIMER1_OVF_vect
TIMER1_OVF_vect:
	;toggle LED0
	SBI PINC, PC0
	reti
	
.global main
main:
	;Set stack pointer to the highest 
	;free memory location SPH,SPL=(RAMEND)
	ldi TEMP, hi8(RAMEND)           
	out SPH, TEMP 
	ldi TEMP, lo8(RAMEND)       
	out SPL, TEMP 
	;disables the global interrupts
	cli
	;Data Direction Register DDR for 
	;Port C Bit 0 as Output
	SBI	DDRC, PC0
	;LED0 off
	SBI PORTC, PC0	
	;Configuration Timer/Counter 1 Control Register B
	;Clock Select precaler 256
	LDI TEMP, (1<<CS12)
	STS TCCR1B, TEMP
	;Configuration Timer/Counter 1 Interrupt Mask Register
	;Timer/Countern, Overflow Flag Enable
	LDI TEMP, (1<<TOIE1)
	STS TIMSK1, TEMP
	
	;enable the global interrupts
	sei
	LOOP:
	;endless loop
	rjmp LOOP

.end