;your comment

;The following is needed to subtract 
;0x20 from I/O addresses
#define __SFR_OFFSET 0

#include "avr/io.h"

;define a name for Register 16 and 17
#define TEMP R16
#define DD_MOSI PINB2
#define DD_SCK PINB1
#define DD_SS PINB0
#define DDR_SPI DDRB

.global SS_ON
SS_ON:
  LDI TEMP,0xFF
  out PORTB, TEMP
ret
.global SS_OFF
SS_OFF:
  LDI TEMP,0xFE
  out PORTB, TEMP
ret
.global TOGGLE_LED
TOGGLE_LED:
  SBI PINC, PC0
ret
; Arduino MEGA2560 PIN51 -- DATA  -- PB2
; Arduino MEGA2560 PIN52 -- CLOCK -- PB1
; Arduino MEGA2560 PIN53 -- SS    -- PB0
; STRIP_com: initializes the SPI
; Parameter: none
.global STRIP_SPI_init 
STRIP_SPI_init:
  ; Set MOSI and SCK output, all others input
  ldi TEMP,(1<<DD_MOSI)|(1<<DD_SCK) | (1<<DD_SS)
  ;ser TEMP
  out DDR_SPI,TEMP
  ; Enable SPI, Master, set clock rate fck/8
  ldi TEMP,(1<<SPE)|(1<<MSTR)|(1<<SPR0) | (0<<CPHA) | (0<<CPOL) |(0<<DORD)
  out SPCR,TEMP
  ldi TEMP, (1>>SPSR)
  out SPSR, TEMP


  ;Data Direction Register DDR for Port C
  ser TEMP ;Set all bits to 1 --> Port C as Output
  out	DDRC, TEMP ;DDRC: Data Direction Register C

  ;all LEDs off
  ser TEMP ;Set all bits to 1
  out PORTC, TEMP ;PORTC: Port C Data Register
ret

; STRIP_com: implements the protocol to communicate with the LED-Strip
; Parameter: R24
; Values:
;   0 - 255: data
.global STRIP_com
STRIP_com:
  out SPDR, R24
  Wait_Transmit:
; Wait for transmission complete
    IN TEMP, SPSR
    sbrs TEMP, SPIF
    rjmp Wait_Transmit
  ret

; STRIP_show: sets a single pixel to the specified color (and switches off all others before it)
; Parameter: r25-r16
; Values:
;   R25, R24 (MSB, LSB)   0 - 2^16: index of pixel to set
;   R22, R20, R18 (R,G,B) 0 - 255:  RGB colors
;   R16                   0-31:     Brigthness
.global STRIP_show
STRIP_show:
 
  ret

 ;END_frame: implements the variable bytes for the End-Frame
 ;Parameter R25, R24 (MSB, LSB)
.global END_frame
END_frame:

  ret
 