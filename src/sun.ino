#include <FastLED.h>

#define NUM_LEDS 300
#define DATA_PIN 4
#define CLOCK_PIN 5
#define NUM_SUNS 80

uint8_t leds_id = 255; //sheldon: 255, nicolas:254

CRGB leds[NUM_LEDS];

uint16_t suns[NUM_SUNS][2];

void setup() { 
  pinMode(LED_BUILTIN, OUTPUT); // initialize digital pin LED_BUILTIN as an output.
  digitalWrite(LED_BUILTIN, LOW);    // turn the LED off 
  Serial.begin(115200);
  FastLED.addLeds<DOTSTAR, DATA_PIN, CLOCK_PIN, BGR>(leds, NUM_LEDS);
  FastLED.clear(true);
  FastLED.show();
  for(int i = 0; i < NUM_SUNS; i++) {
    suns[i][0] = 0;
    suns[i][1] = 0;
  }
}

void loop() {
  uint8_t buff[7];
  uint8_t nbytes = Serial.readBytes(buff, 7);
  if(nbytes == 7) {
    uint8_t i = buff[0];
    if (i == 255){
      Serial.write(leds_id);
    }
    else {
    fill_solid( &(leds[suns[i][0]]), suns[i][1], CRGB::Black);
    
    uint16_t start = (buff[2] << 8) + buff[1];
    uint8_t len = buff[3];
    fill_solid( &(leds[start]), len, CRGB( buff[4], buff[5], buff[6]) );
    
    suns[i][0] = start;
    suns[i][1] = len;
    
    FastLED.show();
    }
  }
}
