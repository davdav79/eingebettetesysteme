/*
 * your comment
 */

#include <Arduino.h>
#include <avr/io.h>

#define LED_NUM_MAX 30

// The extern "C" block is used to tell the compiler that the functions inside it are C functions, not C++ functions. This is important because C++ mangles function names, which means that the linker can't find the functions in the C library. By using extern "C", you tell the compiler not to mangle the function names, so that the linker can find them.
// Strip.S implements all these functions and with .global it makes them available to the linker. The linker then links the C++ code with the assembly code.
// platformio builds the C++ code and the assembly code together, so that the C++ code can call the assembly code.
// .global is important because it makes the functions available to the linker. Without it, the linker would not be able to find the functions in the assembly code.
// extern "C" is important because it tells the compiler not to mangle the function names. Without it, the linker would not be able to find the functions in the assembly code.
// depending on the compiler the function arguments are passed in different registers. The assembly code must be written to expect the arguments in the correct registers.
// here the gcc compiler is used, which passes the first argument in r25 to r8.
extern "C"
{
  // function prototypes debug
  void TOGGLE_LED(void);
  void LED_init(void);
  // function prototypes
  void STRIP_SPI_init(void);
  void STRIP_com(uint8_t one_byte);
  void STRIP_show(uint16_t index, char r, char g, char b, char bright);
  void END_frame(uint16_t count);
}

void setup()
{
  LED_init();
  STRIP_SPI_init();
}
// void loop()
// {
//   TOGGLE_LED();
//   // LED-ON
//   // Start-Frame
//   STRIP_com(0);
//   STRIP_com(0);
//   STRIP_com(0);
//   STRIP_com(0);
//   // LED-Frame
//   STRIP_com(0xE5); // Brigtness 5
//   STRIP_com(0x0A); // Blue
//   STRIP_com(0);    // Green
//   STRIP_com(0);    // Red
//   // END-Frame
//   STRIP_com(0);
//   delay(500);
//   // LED-OFF
//   // Start-Frame
//   STRIP_com(0);
//   STRIP_com(0);
//   STRIP_com(0);
//   STRIP_com(0);
//   // LED-Frame
//   STRIP_com(0xE0); // Brigtness 0
//   STRIP_com(0);    // Blue
//   STRIP_com(0);    // Green
//   STRIP_com(0);    // Red
//   // END-Frame
//   STRIP_com(0);
//   delay(500);
// }

void loop()
{
  //LED - ON
  STRIP_show(LED_NUM_MAX - 1, 0, 0, 10, 5);
  STRIP_show(0, 0, 0, 10, 5);
  delay(20);
  //LED - OFF
  STRIP_show(LED_NUM_MAX, 0, 0, 0, 0);
  delay(20);
}

// void loop()
// {
//     END_frame(0); // 1 x End-Frame
//     delay(200);
//     END_frame(16); // 1 x End-Frame
//     delay(200);
//     END_frame(17); // 2 x End-Frame
//     delay(200);
//     END_frame(33); // 3 x End-Frame
//     delay(200);
//     END_frame(241); // 16 x End-Frame
//     delay(200);
//     END_frame(256); // 16 x End-Frame
//     delay(200);
// }