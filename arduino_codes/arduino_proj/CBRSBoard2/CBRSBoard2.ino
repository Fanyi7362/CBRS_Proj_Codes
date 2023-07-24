#include <SPI.h>


// rf switch
// pin 11 is used to control Board1's switch
// low: RF2 antenna to J3, high: RF1 J1 to J3
#define SWITCH  11

// analog
#define analog  A0


void setup() {
  // initialize SPI:
  SPI.begin(); 
  pinMode(SWITCH, OUTPUT); 
  analogWriteResolution(10);  //Change the DAC resolution to 10-bits
  analogWrite(analog, 0);         // Initialize Dac  to Zero

}

uint8_t ctrl_word1, ctrl_word2;

void loop() {
  digitalWrite(SWITCH, HIGH); 

  analogWrite(analog, 512);

}



