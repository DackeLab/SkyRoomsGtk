void setup(void)
{
  pinMode(LED_BUILTIN, OUTPUT); // initialize digital pin LED_BUILTIN as an output.
  digitalWrite(LED_BUILTIN, LOW);    // turn the LED off
  Timer1.initialize(40);  // 40 us = 25 kHz
  Serial.begin(115200);
  Timer1.pwm(PIN_PWM, 0); // kill the fans
}

void loop(void)
{
  if (Serial.available() > 0) {
    uint8_t input = Serial.read(); // this will either be the duty the fan should be set at, or it'll be equal to 255
    if (input == 255) { // if it's 255 then the computer wants to know what this fan's ID number is
      Serial.write(fanid);
    }
    else { // if it's <255 then it's the duty
      noInterrupts(); // I think we need this to successfully copy the input
      duty = input;
      interrupts();
    }
  }
  // The maximum duty we can set is 1023. The minimum value that moves the fans is 55 (just by experimentation). Input is a byte so it can only be 0--255. We use 255 as a flag to get the fan's ID. So that leaves us with 0--254. Therefore, the maximum value we have is 254, which explains the following calculation (I didn't normalize for the low bound of 55, cause I think it's ok that we have a dead safe zone at the bottom):
  Timer1.pwm(PIN_PWM, (float)duty / 254.0 * 1023.0); // from 55 to 1023
}
