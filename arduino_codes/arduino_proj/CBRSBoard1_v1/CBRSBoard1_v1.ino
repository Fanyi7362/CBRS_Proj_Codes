#include <SPI.h>

// amplifier
// pin 4 is used to enable Board1 amplifier
// high: amplifier on, low: amplifier bypass
#define EN_AMP  4

// rf switch
// pin 5 is used to control Board1's switch
// high: J1, low: antenna
#define SWITCH  5

// phase shifter
#define SPI_LE2  7
#define SPI_LE1  6


// try SPI_MODE0-3
// a fraction of the processor's clock speed 48MHz
// min Clock Period for phase shifter is 100ns
SPISettings settingsA(8000000, MSBFIRST, SPI_MODE1);
uint8_t ctrl_word1, ctrl_word2;

void setup() {
  // initialize SPI:
  SPI.begin();
  pinMode(SPI_LE1, OUTPUT); 
  pinMode(SPI_LE2, OUTPUT); 
  pinMode(SWITCH, OUTPUT); 
  pinMode(EN_AMP, OUTPUT); 

  digitalWrite(SWITCH, HIGH); 
  digitalWrite(EN_AMP, LOW);
  
  ctrl_word1 &= ~0xff; // clear bits
  ctrl_word2 &= ~0xff;
  digitalWrite(SPI_LE1, LOW);
  digitalWrite(SPI_LE2, LOW);
}



void loop() {
  
  // 0x08: 45 deg
  // 0x10: 90 deg
  // 0x20: 180 deg
  // 0x30: 270 deg
  // 0x3f: 337.5 deg
  ctrl_word1 = 0x00; 
  ctrl_word2 = 0x20; 
  phaseShifterWrite(SPI_LE1, ctrl_word1);
  phaseShifterWrite(SPI_LE2, ctrl_word2);
  delay(10);            // waits for a 10ms

  ctrl_word1 = 0x00; 
  ctrl_word2 = 0x00; 
  phaseShifterWrite(SPI_LE1, ctrl_word1);
  phaseShifterWrite(SPI_LE2, ctrl_word2);
  delay(10);            // waits for a 10ms

}


void phaseShifterWrite(uint8_t device_id, uint8_t ctrl_word) {
  //  send ctrl_word via SPI:
  SPI.beginTransaction(settingsA);
  // take the device_id pin low to de-select the chip:
  digitalWrite(device_id, LOW);  
  SPI.transfer(ctrl_word);
  // take the device_id pin high to select the chip:
  digitalWrite(device_id, HIGH);

  SPI.endTransaction();  
}

