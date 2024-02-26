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


;******************************* LED_init *******************************
;just for testing purposes
.global LED_init
LED_init:

  ;Data Direction Register DDR for Port C
  ser TEMP ;Set all bits to 1 --> Port C as Output
  out	DDRC, TEMP ;DDRC: Data Direction Register C

  ;all LEDs off
  ser TEMP ;Set all bits to 1
  out PORTC, TEMP ;PORTC: Port C Data Register
ret


;******************************* TOGGLE_LED *******************************
;just for testing purposes
.global TOGGLE_LED
TOGGLE_LED:
  SBI PINC, PC0
ret


;******************************* STRIP_SPI_init *******************************
; Arduino MEGA2560 PIN51 -- DATA  -- PB2
; Arduino MEGA2560 PIN52 -- CLOCK -- PB1
; Arduino MEGA2560 PIN53 -- SS    -- PB0
; STRIP_com: initializes the SPI
; Parameter: none

; Connect the LED-Strip to the SPI-Pins of the Arduino (MOSI, SCK, SS)
; MOSI for data output to the LED-Strip
; SCK for clock signal (to synchronize the data, it is dependend on the LED how fast the clock signal has to be)
; we do not need SS, because we only have one SPI device
; we de not need MISO, because we only send data to the LED-Strip (no data is received)
; SPCR: SPI Control Register (basic settings for the SPI communication, like clock speed, master/slave-mode, etc.)
; SPSR: SPI Status Register (contains the SPIF-flag, which is set, when the SPI communication is finished, etc.)
; SPDR: SPI Data Register (contains the data to be sent or received)
; DDRB: Data Direction Register B (we have to set the MOSI and SCK pins to output) (be aware: GPIO Pins 51 and 52 are Arduino specific, they are not the same as the pin numbers of the ATmega2560, you can find the SPI pins in the documentation of the ATmega2560 (its Port B)))
.global STRIP_SPI_init 
STRIP_SPI_init:
  ;Set MOSI and SCK to output in DDRB (Data Direction Register B, because the SPI pins are located in Port B on the ATmega2560)
  ldi TEMP, (1<<DDB2) | (1<<DDB1) | (1<<DDB0);Set MOSI(PB2) and SCK(PB1) and SS(PB0) to output (SS would only be input, if we would use the ATmega2560 as a slave)
  out DDRB, TEMP ;DDRB: Data Direction Register B
  ;Set the SPI Control Register (SPCR) to the following settings: Master mode and clock rate fck/16 (16MHz/16=1MHz)
  ldi TEMP, (1<<SPE) | (1<<MSTR) | (1<<SPR0);Enable SPI, Master mode, fck/16 (CPOL=0, CPHA=0 is that the clock is low when idle and data is sampled on the rising edge) (idle is the state, when the clock is not used for data transmission)
  out SPCR, TEMP ;SPCR: SPI Control Register
  ;Set the SPI Status Register (SPSR) to the following settings: double speed
  ldi TEMP, (1<<SPI2X);Enable double speed (fck/8 means 2MHz)
  out SPSR, TEMP ;SPSR: SPI Status Register
ret


;******************************* STRIP_com *******************************
; STRIP_com: implements the protocol to communicate with the LED-Strip
; Parameter: R24
; Values:
;   0 - 255: data

; as soon as data is written to SPDR, the SPI hardware will start sending the data
; the SPIF-flag in SPSR will be set, when the transmission is complete
; sbsr Rr, b: is a command to skip the next instruction, if the bit in the register is set (If Rr(b) == 1 then PC ← PC + 2 else PC ← PC + 1)
.global STRIP_com
STRIP_com:
  out SPDR, R24

  ; Wait for transmission complete
  Wait_Transmit:
    IN TEMP, SPSR
    sbrs TEMP, SPIF
    rjmp Wait_Transmit
ret


;******************************* STRIP_show *******************************
; STRIP_show: sets a single pixel to the specified color (and switches off all others before it)
; Parameter: r25-r16
; Values:
;   R25, R24 (MSB, LSB)   0 - 2^16: index of pixel to set
;   R22, R20, R18 (R,G,B) 0 - 255:  RGB colors
;   R16                   0-31:     Brigthness

;R27:R26 can be used for porgramming because this register is not used by the C-compiler
.global STRIP_show
STRIP_show:  
  push R24
  push R25

  MOVW R26,R24 ;save the index of the pixel because R24 is used for the STRIP_com call

  ;send start frame 4x 0x0
  LDI R24, 0x0
  RCALL STRIP_com
  RCALL STRIP_com
  RCALL STRIP_com
  RCALL STRIP_com
  
  _Strip_show_loop1:
    SBIW R26, 1 ;subtract 1 from R26 ;sets the C flag: if(R26 < 1) then: C=1
    BRCC _STRIP_show_loop2 ;if(C==0) then: jump to _STRIP_show_loop2
          
  ;send brightness 
  ;xor R16 with 11100000 to set the first 3 bits to 1 and put it in R24 for the STRIP_com call
  MOV R24, R16 ;R24 is used for the STRIP_com call ;R16 has only 5 bits (LSBs) 
  SBR R24, 0xE0 ;0xE0 = 11100000 ;sbr sets the bits in R24 to 1, if the corresponding bit in the second parameter is 1
  RCALL STRIP_com
  
  ; send led frame
  MOV R24,R22 ;blue
  RCALL STRIP_com
  MOV R24,R20 ;green
  RCALL STRIP_com
  MOV R24,R18 ;red
  RCALL STRIP_com
  
 ;END_frame: implements the variable bytes for the End-Frame
  pop R25
  pop R24
  RCALL END_frame
ret

_STRIP_show_loop2:
  ;all the LEDs before the index should be turned off
  ;send brightness 
  ;11100000 because we only want to send one LED-framte according to the protocol (first 3 bits are 1, and for brightness = 0 the other 5 bits have to be 0)
  ldi R24, 0xE0 ;0xE0 = 11100000
  RCALL STRIP_com
  ; send led frame
  ldi R24,0x0
  RCALL STRIP_com ;blue
  RCALL STRIP_com ;green
  RCALL STRIP_com ;red
  rjmp _Strip_show_loop1


;******************************* END_frame *******************************
;Parameter R25, R24 (MSB, LSB)

; R27:R26 can be used for porgramming because this register is not used by the C-compiler
; ((R25:R24) - 1)/16 is the number of STRIP_com calls with 0x0 as parameter (R24 is 0x0):
.global END_frame
END_frame:
  movw R26, R24
  ldi R24,0x0
  SBIW R26,1 ;subtract 1 from R26 ;sets the C flag: if(R26 < 1) then: C=1
  BRCS END_frame_jmp ;if(C==1) then: jump to END_frame_jmp
 
  END_frame_loop1:  
    RCALL STRIP_com
    SBIW R26, 16 ;subtract 16 from R26 ;sets the C flag: if(R26 < 16) then: C=1
    BRCC END_frame_loop1 ;if(C==0) then: jump to END_frame_loop1
ret

END_frame_jmp:
    RCALL STRIP_com
ret
  