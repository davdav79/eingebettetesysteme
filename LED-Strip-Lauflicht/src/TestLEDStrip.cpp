/*
 * your comment
 */

#include <Arduino.h>
#include <avr/io.h>

#define TST_1 2
#define TST_2 3
#define BUZZER 8
#define LED_1 5
#define LED_2 6
#define LED_NUM_MAX 30
#define LED_NUM_START 0
#define LED_START_DELAY 495
#define LED_MAX_DELAY 500
#define LED_MIN_DELAY 5
#define LED_STEP_SIZE_DELAY 10
#define LED_DIR_FORWARD 1
#define LED_DIR_BACK -1
#define DEBOUNCE_DELAY 300
#define DEBUG_DELAY 500
#define BUZZER_DELAY 200
int display_led;
int led_dir;
int led_delay;
int send_buzzer;
unsigned long last_interrupt_led;
unsigned long last_debug_print;
unsigned long last_buzzer;
volatile unsigned long last_interrupt_time1;
volatile unsigned long last_interrupt_time2;

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

void setup()
{
  LED_init();
  Serial.begin(115200);
  STRIP_SPI_init();
  send_buzzer = 0;
  display_led = LED_NUM_START;
  led_dir = LED_DIR_FORWARD; 
  led_delay = LED_START_DELAY;
  pinMode(BUZZER,OUTPUT);
  pinMode(TST_1, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(TST_1),inc_speed,FALLING);
  pinMode(TST_2, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(TST_2),dec_speed,FALLING);
}

void loop()
{
  
    show_led();
    buzzer();
    if(millis() - last_debug_print >(unsigned long)DEBUG_DELAY){  
      Serial.println((String)led_delay);
      last_debug_print = millis();
    }
   
}
void show_led(){
  //LED - ON
  if(millis() - last_interrupt_led >(unsigned long)led_delay){
    if(display_led == LED_NUM_MAX-1 && led_dir == LED_DIR_FORWARD){
      led_dir = LED_DIR_BACK;
    }else if(display_led == LED_NUM_START && led_dir == LED_DIR_BACK){
      led_dir = LED_DIR_FORWARD;
    }
    STRIP_show(LED_NUM_MAX-1, 0, 0, 0, 0);
    STRIP_show(display_led, 0, 0, 10, 10);//warum verändert sich die display_led variable, wenn wir ein register verändern? 
    display_led += led_dir;
    last_interrupt_led = millis();
   }
}
void inc_speed(){
  unsigned long current_millis = millis();
  if(current_millis - last_interrupt_time1 > (unsigned long)DEBOUNCE_DELAY){
    if(led_delay-LED_STEP_SIZE_DELAY <= LED_MIN_DELAY){
      if(send_buzzer == 0 && led_delay == 5)
        send_buzzer = 1;
      led_delay = 5;
      last_interrupt_time1 = millis();
      return;
    }
    led_delay -= LED_STEP_SIZE_DELAY;
    last_interrupt_time1 = millis();
  }
}
void dec_speed(){
  unsigned long current_millis = millis();
  if(current_millis - last_interrupt_time2 > (unsigned long)DEBOUNCE_DELAY){
    if(led_delay+LED_STEP_SIZE_DELAY >= LED_MAX_DELAY){
      if(send_buzzer == 0 && led_delay == 500)
        send_buzzer = 1;
      led_delay = 500;
      last_interrupt_time2 = millis();
      return;
    }
    led_delay += LED_STEP_SIZE_DELAY;
    last_interrupt_time2 = millis();
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