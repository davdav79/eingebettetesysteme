;your comment

;The following is needed to subtract 
;0x20 from I/O addresses
#define __SFR_OFFSET 0

#include "avr/io.h"

; Arduino MEGA2560 PIN51 -- DATA  -- PB2
; Arduino MEGA2560 PIN52 -- CLOCK -- PB1
; Arduino MEGA2560 PIN53 -- SS    -- PB0
; STRIP_com: initializes the SPI
; Parameter: none
.global STRIP_SPI_init
STRIP_SPI_init:

  ret

; STRIP_com: implements the protocol to communicate with the LED-Strip
; Parameter: R24
; Values:
;   0 - 255: data
.global STRIP_com
STRIP_com:

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
 