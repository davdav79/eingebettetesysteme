;your comment

;The following is needed to subtract 
;0x20 from I/O addresses
#define __SFR_OFFSET 0

#include "avr/io.h"

;define a name for Register 16 and 17
#define TEMP R19
#define DD_MOSI DDB2
#define DD_SCK DDB1
#define DD_SS DDB0
#define DDR_SPI DDRB

.global LED_init
LED_init:
  ;Data Direction Register DDR for Port C
  ser TEMP ;Set all bits to 1 --> Port C as Output
  out	DDRC, TEMP ;DDRC: Data Direction Register C

  ;all LEDs off
  ser TEMP ;Set all bits to 1
  out PORTC, TEMP ;PORTC: Port C Data Register
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
  ldi TEMP,(1<<DD_MOSI) | (1<<DD_SCK) | (1<<DD_SS)
  out DDR_SPI,TEMP
  ; Enable SPI, Master, set clock rate fck/16
  ldi TEMP,(1<<SPE)|(1<<MSTR)|(1<<SPR0) | (0<<CPHA) | (0<<CPOL) ;|(0<<DORD)
  out SPCR,TEMP
  ; clock teiler halbieren
  ldi TEMP, (1<<SPI2X)
  out SPSR, TEMP
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
; save index of pixel
  MOVW R26,R24
  ; send start frame 4x 0x0
  LDI R24, 0x0
  RCALL STRIP_com
  RCALL STRIP_com
  RCALL STRIP_com
  RCALL STRIP_com
  
  _Strip_show_loop1:
    SBIW R26, 1
    BRCC _STRIP_show_loop2
  
  _if_zero:
  ; send brightness         
  ;send brightness 
  ; mit 11100000 verodern damit die ersten 3 bit immer 1 sind
  MOV R24, R16
  SBR R24, 0xE0 
  RCALL STRIP_com
  ; send led frame
  MOV R24,R22
  RCALL STRIP_com
  MOV R24,R20
  RCALL STRIP_com
  MOV R24,R18
  RCALL STRIP_com
  
 ;END_frame: implements the variable bytes for the End-Frame
  RCALL END_frame
ret
_STRIP_show_loop2:
  ;send brightness 
  ; mit 11100000 verodern damit die ersten 3 bit immer 1 sind
  ldi R24, 0xE0 
  RCALL STRIP_com
  ; send led frame
  ldi R24,0x0
  RCALL STRIP_com
  RCALL STRIP_com
  RCALL STRIP_com
  rjmp _Strip_show_loop1


 ;Parameter R25, R24 (MSB, LSB)
.global END_frame
END_frame:

  MOVW R26,R24
  ldi R24,0x0
  SBIW R26,1
  BRCC END_frame_jmp
 
  END_frame_loop1:  
    SBIW R26, 16
    RCALL STRIP_com
    
    BRCC END_frame_loop1
    END_frame_jmp:
    RCALL STRIP_com
  ret
  