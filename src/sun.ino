#include <FastLED.h>

#define NUM_LEDS 300 // 2 strips with 150 LEDs each
#define DATA_PIN 4
#define CLOCK_PIN 5
#define NUM_SUNS 80 // store a maximum of 80 indiviual "sun"s

uint8_t leds_id = 255; //sheldon's ID is 255, nicolas's ID is 254

CRGB leds[NUM_LEDS]; // LED strip

uint16_t suns[NUM_SUNS][2]; // an array to keep 80 suns' starting LED-positions and lengths

void setup() { 
  pinMode(LED_BUILTIN, OUTPUT); // initialize digital pin LED_BUILTIN as an output.
  digitalWrite(LED_BUILTIN, LOW);    // turn the LED off 
  Serial.begin(115200); // I chose 115200, but maybe higher would also work well
  FastLED.addLeds<DOTSTAR, DATA_PIN, CLOCK_PIN, BGR>(leds, NUM_LEDS);
  FastLED.clear(true); // turn all LEDs off
  FastLED.show();
  for(int i = 0; i < NUM_SUNS; i++) { // set all suns to zero to start with
    suns[i][0] = 0;
    suns[i][1] = 0;
  }
}

void loop() {
  uint8_t buff[7]; // buffer for reading in the instructions from the computer
  uint8_t nbytes = Serial.readBytes(buff, 7);
  if(nbytes == 7) {
    uint8_t i = buff[0]; // this will either be the sun's index/ID to be set, or it'll be equal to 255
    if (i == 255){ // if it's 255 then the computer wants to know what this LED strip's ID number is
      Serial.write(leds_id);
    }
    else { // if it's <255 then the rest of the message is the instructions about the sun
    fill_solid( &(leds[suns[i][0]]), suns[i][1], CRGB::Black); // turn sun `i` off 
    
    uint16_t start = (buff[2] << 8) + buff[1]; // get the starting LED position
    uint8_t len = buff[3]; // get the length
    fill_solid( &(leds[start]), len, CRGB( buff[4], buff[5], buff[6]) ); // set it
    
    suns[i][0] = start; // store these location 
    suns[i][1] = len;  // and length for the next round of instructions
    
    FastLED.show();
    }
  }
}
