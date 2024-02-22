#include "oled.h"

SSOLED ssoled;
unsigned long last_oled_print;

void oled_init(){
    int rc;
    rc = oledInit(&ssoled, OLED_128x64, OLED_ADDR, FLIP180, INVERT, USE_HW_I2C, SDA_PIN, SCL_PIN, RESET_PIN, 400000L);       // Standard HW I2C bus at 400Khz

    if (rc != OLED_NOT_FOUND)
    {
        char *msgs[] =
        {
          (char *)"SSD1306 @ 0x3C",
          (char *)"SSD1306 @ 0x3D",
          (char *)"SH1106 @ 0x3C",
          (char *)"SH1106 @ 0x3D"
        };

        oledFill(&ssoled, 0, 1);
        //oledWriteString(&ssoled, 0, 0, 0, (char*)"", FONT_NORMAL, 0, 1);
        //oledWriteString(&ssoled, 0, 10, 2, msgs[rc], FONT_NORMAL, 0, 1);
        //last_oled_print = millis();
    }
}


void oled_send(int button_presses, int led_delay, int led_uptime){
    if(millis() - last_oled_print >(unsigned long)500){
        char buffer[24];
        sprintf(buffer, "Button Counter: %03d", button_presses);
        oledWriteString(&ssoled, 0, 0, 0,(char *)buffer, FONT_SMALL, 0, 1);
        sprintf(buffer,"LED delay: %03d", led_delay);
        oledWriteString(&ssoled, 0, 0, 2,(char *)buffer, FONT_SMALL, 0, 1);
        sprintf(buffer,"LED run time: %03d", led_uptime);
        oledWriteString(&ssoled, 0, 0, 4,(char *)buffer, FONT_SMALL, 0, 1);


    }

    
}