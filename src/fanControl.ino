/*************************************************** 
  This is an example for our Adafruit 16-channel PWM & Servo driver
  PWM test - this will drive 16 PWMs in a 'wave'
  Pick one up today in the adafruit shop!
  ------> http://www.adafruit.com/products/815
  These drivers use I2C to communicate, 2 pins are required to  
  interface.
  Adafruit invests time and resources providing this open source code, 
  please support Adafruit and open-source hardware by purchasing 
  products from Adafruit!
  Written by Limor Fried/Ladyada for Adafruit Industries.  
  BSD license, all text above must be included in any redistribution
 ****************************************************/

#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>

// called this way, it uses the default address 0x40
Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver();
// you can also call it with a different address you want
//Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver(0x41);
// you can also call it with a different address and I2C interface
//Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver(0x40, Wire);

/*
Command structure:
Byte 3:  Command ID
Byte 2:  parameter 1
Byte 1:  Parameter 2
Byte 0:  Response, command response status

The Arduino responds to every command with 4 bytes, Command ID, parameter 1 & 2 and CMD_OK/COMMAND_ERROR
*/

#define FAN_ID 5

#define CMD_UNKNOWN 0x00  //  Unknown command received
#define CMD_SPEED  0x01   //  Set duty cycle/pulse width
#define CMD_RELAY  0x02   //  Set/Reset the relay
#define CMD_FAN_ID 0x03   //  Send a custom ID number.
#define CMD_ERROR  0xFF   //  Error in command parameters
#define CMD_OK 0x01       //  Command was successfully handled

#define PIN_RELAY_1 0x08
#define PIN_RELAY_2 0x09
#define PIN_RELAY_3 0x0A
#define PIN_RELAY_4 0x0B
#define PIN_RELAY_5 0x0C
#define PIN_RELAY_6 0x0D


#define RELAY_SET 0x01
#define RELAY_RESET 0x00

uint8_t inBuf[4];
uint8_t outBuf[4];
uint8_t channel = 0;  // PWM channel id
uint8_t duty = 0;     // Duty cycle for the fan.

//uint32_t cmd, response;

void setup() 
{
  pinMode(LED_BUILTIN, OUTPUT); // initialize digital pin LED_BUILTIN as an output.
  digitalWrite(LED_BUILTIN, LOW);    // turn the LED off
  pinMode(PIN_RELAY_1, OUTPUT);   
  pinMode(PIN_RELAY_2, OUTPUT);   
  pinMode(PIN_RELAY_3, OUTPUT);    
  pinMode(PIN_RELAY_4, OUTPUT);    
  pinMode(PIN_RELAY_5, OUTPUT);    
  pinMode(PIN_RELAY_6, OUTPUT);    
  Serial.begin(115200);
  //Serial.println("PWM 0 ready");
  pwm.begin();
  /*
   * In theory the internal oscillator (clock) is 25MHz but it really isn't
   * that precise. You can 'calibrate' this by tweaking this number until
   * you get the PWM update frequency you're expecting!
   * The int.osc. for the PCA9685 chip is a range between about 23-27MHz and
   * is used for calculating things like writeMicroseconds()
   * Analog servos run at ~50 Hz updates, It is importaint to use an
   * oscilloscope in setting the int.osc frequency for the I2C PCA9685 chip.
   * 1) Attach the oscilloscope to one of the PWM signal pins and ground on
   *    the I2C PCA9685 chip you are setting the value for.
   * 2) Adjust setOscillatorFrequency() until the PWM update frequency is the
   *    expected value (50Hz for most ESCs)
   * Setting the value here is specific to each individual I2C PCA9685 chip and
   * affects the calculations for the PWM update frequency. 
   * Failure to correctly set the int.osc value will cause unexpected PWM results
   */
  pwm.setOscillatorFrequency(27000000);
  pwm.setPWMFreq(1600);  // This is the maximum PWM frequency

  // if you want to really speed stuff up, you can go into 'fast 400khz I2C' mode
  // some i2c devices dont like this so much so if you're sharing the bus, watch
  // out for this!
  Wire.setClock(400000);
}

void loop() 
{
  int i = 0;
  while (Serial.available() > 0) 
  {
    i = i + Serial.readBytes(inBuf, 4);
//    i++;
//    i = 4;
    if (i == 4) 
    {
      i = 0;
//      Serial.println("4 bytes read!");
      if (inBuf[3] == CMD_FAN_ID)
      {
//        Serial.println("CMD_FAN_ID");
        // Send Fan ID
        outBuf[3] = CMD_FAN_ID;
        outBuf[2] = FAN_ID;
        outBuf[1] = 0;
        outBuf[0] = CMD_OK;
      }
      else if (inBuf[3] == CMD_RELAY)
      {
//        Serial.println("CMD_RELAY");
        outBuf[3] = CMD_RELAY;
        outBuf[2] = inBuf[2]; // channel
        outBuf[1] = inBuf[1];  // relay set/reset
        outBuf[0] = CMD_OK;
        if ((inBuf[1] == RELAY_SET) || (inBuf[1] == RELAY_RESET))
        {
          if ((inBuf[2] < 14) && (inBuf[2] > 7))   // channel no.
          {
            digitalWrite(inBuf[2], inBuf[1]);
          }
          else
          {
            outBuf[0] = CMD_ERROR;        
          }
        }
        else
        {
          outBuf[0] = CMD_ERROR;
        }
      }
      else if (inBuf[3] == CMD_SPEED)
      {
  //      Serial.println("CMD_SPEED");
        noInterrupts(); // I think we need this to successfully copy the input
        channel = inBuf[2];
        duty = inBuf[1];
        interrupts();
        outBuf[3] = CMD_SPEED;
        outBuf[2] = channel;
        outBuf[1] = duty;
        outBuf[0] = CMD_OK;

        if (channel < 16) // There are 16 channels on the Adafruit PWM board
        {
          if (duty == 0)
          {
            // PWM fully off command, fully on is pwm.setPWM(pin, 4096, 0)
            pwm.setPWM(channel, 0, 4096);
          }
          else
          {
            pwm.setPWM(channel, 0, (float) duty/254.0*4095);
          }
        }
        else
        {
          outBuf[0] = CMD_ERROR;
        }
      }
      else
      {
//        Serial.println("Other command");
        outBuf[3] = 6;
        outBuf[2] = 0;
        outBuf[1] = 0;
        outBuf[0] = CMD_ERROR;        
      }  
    }
    else
    {
//      Serial.println("CMD_UNKNOWN");
      outBuf[3] = 7;
      outBuf[2] = 0;
      outBuf[1] = 0;
      outBuf[0] = CMD_ERROR;
    }
    Serial.write(outBuf, 4);  // Send command response 
  }
}
/*   
    if (isDigit(inChar)) 
    {
      // convert the incoming byte to a char and add it to the string:
      inString += (char)inChar;
    }
    // if you get a newline, print the string, then the string's value:
    if (inChar == '\r') 
    {
      Serial.print("Value:");
      Serial.println(inString.toInt());
      Serial.print("String: ");
      Serial.println(inString);
      uint16_t input = inString.toInt();
      if (input > 255) // Select channel 0 - 15 
      {
        channel = input - 256;  
        Serial.print("Channel: ");
        Serial.println(channel);
      }      
      if (input == 255)  // if it's 255 then the computer wants to know what this fan's ID number is
      {
        Serial.write(fanid);
        Serial.print("Fan id: ");
        Serial.println(inString.toInt());
      }
      if (input < 255) // if it's <255 then it's the duty
      {
        noInterrupts(); // I think we need this to successfully copy the input
        duty = input;
        interrupts();
        Serial.write(duty);
        Serial.print(duty);
        if (duty == 0)
        {
          // PWM fully off command, fully on is pwm.setPWM(pin, 4096, 0)
          pwm.setPWM(channel, 0, 4096);
        }
        else
        {
          pwm.setPWM(channel, 0, (float) duty/254.0*4095);
        }
      }
      // clear the string for new input:
      inString = "";
    }
  }

*/
/*toInt(  
  {
    uint8_t input = Serial.read(); // this will either be the duty the fan should be set at, or it'll be equal to 255
    if (input == 255) { // if it's 255 then the computer wants to know what this fan's ID number is
      Serial.write(fanid);
    }
    else { // if it's <255 then it's the duty
      noInterrupts(); // I think we need this to successfully copy the input
      duty = input;
      interrupts();
      Serial.write(duty);
    }
  }
  // The maximum duty we can set is 1023. The minimum value that moves the fans is 55 (just by experimentation). Input is a byte so it can only be 0--255. We use 255 as a flag to get the fan's ID. So that leaves us with 0--254. Therefore, the maximum value we have is 254, which explains the following calculation (I didn't normalize for the low bound of 55, cause I think it's ok that we have a dead safe zone at the bottom):
  pwm.setPWM(0, 0, (float) duty/254.0*4095);
  pwm.setPWM(1, 0, (float) duty/254.0*4095);
*/  
 //Timer1.pwm(PIN_PWM, (float)duty / 254.0 * 1023.0); // from 55 to 1023 */
//}

/*  
  pwm.setPWM(0, 0, 2000 );
  pwm.setPWM(1, 0, 2000 );
  while(1)
  {
  }
  
  // Drive each PWM in a 'wave'
  for (uint16_t i=0; i<4096; i += 8) {
    for (uint8_t pwmnum=0; pwmnum < 16; pwmnum++) {
      pwm.setPWM(pwmnum, 0, (i + (4096/16)*pwmnum) % 4096 );
    }
#ifdef ESP8266
    yield();  // take a breather, required for ESP8266
#endif
  }
}
*/
