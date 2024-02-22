#include <Arduino.h>
#include <avr/io.h>
#include <ss_oled.h>


#define SDA_PIN 20
#define SCL_PIN 21
// no reset pin needed
#define RESET_PIN -1
// let ss_oled find the address of our display
#define OLED_ADDR -1
#define FLIP180 0
#define INVERT 0
// Use the default Wire library
#define USE_HW_I2C 0

void oled_init();
void oled_send(int button_presses, int led_delay, int led_uptime);