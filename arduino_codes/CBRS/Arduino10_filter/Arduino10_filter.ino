/*
##############     Wiring Information         #############
┌───────────────────────────────┬────────┬────────────────┐
│     Arduino MKR WiFi 1010     │        │  EVAL-AD5370   │
├───┬───────┬──────────┬────────┤ Wire   ├────────┬───────┤
│ # │ Pin#  │ Type     │ Name   │ Colour │ Name   │ Pin#  │
├───┼───────┼──────────┼────────┼────────┼────────┼───────┤
│ 1 │ 1     │ GPIO     │ LDAC   │ WHITE  │ /LDAC  │ 8     │
│ 2 │ 2     │ GPIO     │ CLR    │ BLACK  │ /CLR   │ 10    │
│ 3 │ 3     │ GPIO     │ BUSY   │ BROWN  │ /BUSY  │ 12    │
│ 4 │ 4     │ GPIO     │ RESET  │ RED    │ /RESET │ 14    │
│ 5 │ 8     │ SPI/MOSI │ MOSI   │ BLUE   │ DIN    │ 1     │
│ 6 │       │ SPI/MISO │ MISO   │        │ SDO    │ T6    │
│ 7 │ 9     │ SPI/SCLK │ SCLK   │ PURPLE │ SCLK   │ 3     │
│ 8 │ GND   │ Ground   │ GND    │ BLACK  │ DGND   │ 19/20 │
│ 9 │ 0     │ SPI/CE0  │ SS/CE0 │ GREY   │ /SYNC  │ 6     │
└───┴───────┴──────────┴────────┴────────┴────────┴───────┘
** T6 is a test point for EVAL-AD5370
** Pin# for EVAL-AD5370 is from J3 Header
** Pin numbering for Arduino MKR WiFi 1010: Always use the names 
   that are printed on the board. Except the digital pins D0-D14 
   can be called by just their number without the prefix "D".
** Connect at least two grounds for stable connection

*/

#include <SPI.h>

#define SYNC_pin  0
#define LDAC_pin  1
#define BUSY_pin  2
#define CLR_pin   3
#define RESET_pin  4

// try SPI_MODE0-3
SPISettings settingsA(500000, MSBFIRST, SPI_MODE1);
uint32_t ctrl_word1;

void setup() {
  
  SPI.begin();                   //Initialize SPI
  pinMode(SYNC_pin , OUTPUT);    //Setup AD5370 Pins
	pinMode(LDAC_pin , OUTPUT);    //Setup AD5370 Pins
	pinMode(BUSY_pin , INPUT);     //Setup AD5370 Pins
	pinMode(CLR_pin  , OUTPUT);    //Setup AD5370 Pins
	pinMode(RESET_pin, OUTPUT);    //Setup AD5370 Pins

  ctrl_word1 = 0x000000; // clear bits
	//Perform a Reset Activity
	digitalWrite(RESET_pin, LOW);
	delay(1);    // waits for a 1ms
	digitalWrite(RESET_pin, HIGH);
	
	//Perform a Clear Activity
	digitalWrite(CLR_pin, LOW);
	delay(1);
	digitalWrite(CLR_pin, HIGH);

}

void loop() {
  digitalWrite(LDAC_pin, LOW);
  // index: 0xC8 is channel 0
  ctrl_word1 = 0xc9f000;
  if(digitalRead(BUSY_pin) == HIGH) //Ensuring the system (AD5370) is not busy so that we can write to the register, not important for one channel, but might be important for multi channel, if we remove this IF statement we get ~ 8kHz. See Prologue Note on SPEED
    phaseShifterWrite(SYNC_pin, ctrl_word1);

  delay(1); //Sleep to stabilize the loop, so far we have achieved 7.7 kHz, but it flickers around 7.5 to 7.8 kHz, to stabilize the loop, the usleep timer is used, may be more precision timers may be required for the future.

  ctrl_word1 = 0xf2f000;
  if(digitalRead(BUSY_pin) == HIGH)
    phaseShifterWrite(SYNC_pin, ctrl_word1);

  delay(1);
}

void phaseShifterWrite(uint8_t device_id, uint32_t ctrl_word) {
  SPI.beginTransaction(settingsA);

  digitalWrite(device_id, LOW);  

  // Transfer 3 bytes, MSB first
  SPI.transfer((ctrl_word >> 16) & 0xFF); // MSB
  SPI.transfer((ctrl_word >> 8) & 0xFF);
  SPI.transfer(ctrl_word & 0xFF); // LSB

  digitalWrite(device_id, HIGH);

  SPI.endTransaction(); 
}
