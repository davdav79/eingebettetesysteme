#include <Arduino.h>
#include <avr/io.h>


#define DEBUG_DELAY 500

void serial_init();
void serial_send_with_delay(int print);