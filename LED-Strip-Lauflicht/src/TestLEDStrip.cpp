/*
 * your comment
 */

#include <Arduino.h>
#include <avr/io.h>
#include "oled.h"
#include "serial.h"

#define TST_1 2
#define TST_2 3
#define BUZZER 8
#define LED_1 5
#define LED_2 6
#define LED_NUM_MAX 30
#define LED_NUM_START 0
#define LED_START_DELAY 255
#define LED_MAX_DELAY 500
#define LED_MIN_DELAY 5
#define LED_STEP_SIZE_DELAY 10
#define LED_DIR_FORWARD 1
#define LED_DIR_BACK -1
#define DEBOUNCE_DELAY 300
#define TURN_OFF_LED_DELAY 18000//0

#define BUZZER_DELAY 200
int led_number = LED_NUM_START;
int led_dir = LED_DIR_FORWARD; 
int led_delay = LED_START_DELAY;
int send_buzzer = 0;
int start_led_run = 0;
int button_counter = 0;
int led_uptime = 0;
unsigned long last_interrupt_led;
unsigned long last_buzzer = 0;
unsigned long last_led_start_time = 0;
volatile unsigned long last_interrupt_time1 = 0;
volatile unsigned long last_interrupt_time2 = 0;




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
void inc_speed();
void dec_speed();
void show_led();
void buzzer();
void set_uptime();

void setup()
{
  LED_init();
  serial_init();
  STRIP_SPI_init();
  pinMode(BUZZER,OUTPUT);
  pinMode(TST_1, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(TST_1),inc_speed,FALLING);
  pinMode(TST_2, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(TST_2),dec_speed,FALLING);
  oled_init();
  //alles leds vom strip ausschalten
  STRIP_show(LED_NUM_MAX-1, 0, 0, 0, 0); 
}

void loop()
{
  
    show_led();
    buzzer();
    serial_send_with_delay(led_delay);
    if(millis() - last_led_start_time >= TURN_OFF_LED_DELAY){
      start_led_run = 0;
      STRIP_show(LED_NUM_MAX-1, 0, 0, 0, 0); 
    }
    set_uptime();  
    oled_send(button_counter,led_delay,led_uptime,led_number);
   
}
void set_uptime(){
  if(start_led_run == 0){
    led_uptime = 0;
  }else{
    led_uptime = (millis()- last_led_start_time)/1000;
  }
}
void show_led(){
  //LED - ON
  if(millis() - last_interrupt_led <=(unsigned long)led_delay)
    return;
  last_interrupt_led = millis();
  if(start_led_run == 0){
    return;
  }
  if(led_number == LED_NUM_MAX-1 && led_dir == LED_DIR_FORWARD){
    led_dir = LED_DIR_BACK;
  }else if(led_number == LED_NUM_START && led_dir == LED_DIR_BACK){
    led_dir = LED_DIR_FORWARD;
  }
  STRIP_show(LED_NUM_MAX-1, 0, 0, 0, 0);
  STRIP_show(led_number, 0, 0, 10, 10); //warum verändert sich die led_number variable, wenn wir ein register verändern? 
  led_number += led_dir;
  
}
void inc_speed(){
  unsigned long current_millis = millis();
  if(current_millis - last_interrupt_time1 > (unsigned long)DEBOUNCE_DELAY){
    last_interrupt_time1 = current_millis;
    if(start_led_run == 0){
      last_led_start_time = current_millis;
      start_led_run = 1;
      return;
    }
    
    button_counter++;
    last_led_start_time = current_millis;
    if(led_delay-LED_STEP_SIZE_DELAY <= LED_MIN_DELAY){
      if(send_buzzer == 0 && led_delay == LED_MIN_DELAY)
        send_buzzer = 1;
      led_delay = LED_MIN_DELAY;
      return;
    }
    led_delay -= LED_STEP_SIZE_DELAY;
  }
}
void dec_speed(){
  unsigned long current_millis = millis();
  if(current_millis - last_interrupt_time2 > (unsigned long)DEBOUNCE_DELAY){
    last_interrupt_time2 = current_millis;
    if(start_led_run == 0){
      last_led_start_time = current_millis;
      start_led_run = 1;
      return;
    }
    button_counter++;
    last_led_start_time = current_millis;
    if(led_delay+LED_STEP_SIZE_DELAY >= LED_MAX_DELAY){
      if(send_buzzer == 0 && led_delay == LED_MAX_DELAY)
        send_buzzer = 1;
      led_delay = LED_MAX_DELAY;
      return;
    }
    led_delay += LED_STEP_SIZE_DELAY;
  }
}

void buzzer(){
  if(send_buzzer == 1){
    digitalWrite(BUZZER, 1);
    send_buzzer = 2;
    last_buzzer = millis();
  }
  else if(send_buzzer == 2){
    if(millis() - last_buzzer > (unsigned long)BUZZER_DELAY){
      digitalWrite(BUZZER, 0);
      send_buzzer = 0;
    }
  }
}