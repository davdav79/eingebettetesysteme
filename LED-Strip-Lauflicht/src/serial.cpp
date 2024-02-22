#include "serial.h"

unsigned long last_debug_print;

void serial_init(){
    Serial.begin(115200);
}

void serial_send_with_delay(int print_text){
    if(millis() - last_debug_print >(unsigned long)DEBUG_DELAY){  
      Serial.println((String)print_text);
      last_debug_print = millis();
    }
}