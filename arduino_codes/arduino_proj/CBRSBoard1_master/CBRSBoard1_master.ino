#include <SPI.h>

// amplifier
// pin 13 is used to enable Board1 amplifier
// high: amplifier on, low: amplifier bypass
#define EN_AMP  13

// rf switch
// pin 4 is used to control Board1's switch
// high: antenna to J1F, low: J3F to J1F
#define SWITCH  14

// phase shifter
#define SPI_LE21  7
#define SPI_LE11  6

#define SPI_LE22  A3
#define SPI_LE12  A4

#define SPI_LE23  A5
#define SPI_LE13  A6

#define SPI_LE24  0
#define SPI_LE14  1

#define SPI_LE25  2
#define SPI_LE15  3

#define SPI_LE26  4
#define SPI_LE16  5

// Pin to trigger the slave
#define TRIGGER_PIN  A1

// try SPI_MODE 0-3
// SPI_CLOCK: should be a fraction of the processor's clock speed 48MHz
// min Clock Period for phase shifter is 100ns
const uint32_t SPI_CLOCK = 8000000; // 8 MHz
SPISettings settingsA(SPI_CLOCK, MSBFIRST, SPI_MODE1);

#define CTRL_WORD_COUNT 4 // Number of control words
uint8_t ctrl_word[CTRL_WORD_COUNT]; // Control word array
int currentWord = 0; // Keeps track of which control word to use next
unsigned long lastMillis = 0; // Store the time of the last data send

void setup() {
  // initialize SPI:
  SPI.begin();
  
  pinMode(SPI_LE11, OUTPUT); 
  pinMode(SPI_LE21, OUTPUT); 
  pinMode(SPI_LE12, OUTPUT); 
  pinMode(SPI_LE22, OUTPUT);   
  pinMode(SPI_LE13, OUTPUT); 
  pinMode(SPI_LE23, OUTPUT); 
  pinMode(SPI_LE14, OUTPUT); 
  pinMode(SPI_LE24, OUTPUT);   
  pinMode(SPI_LE15, OUTPUT); 
  pinMode(SPI_LE25, OUTPUT); 
  pinMode(SPI_LE16, OUTPUT); 
  pinMode(SPI_LE26, OUTPUT);       
  
  pinMode(EN_AMP, OUTPUT); 
  pinMode(SWITCH, OUTPUT); 
  pinMode(TRIGGER_PIN, OUTPUT);

  digitalWrite(SWITCH, LOW); 
  digitalWrite(EN_AMP, LOW);

  // 0x00:  0 deg
  // 0x08: 45 deg
  // 0x10: 90 deg
  // 0x20: 180 deg
  // 0x30: 270 deg
  // 0x3f: 337.5 deg
  // Initialize control words
  ctrl_word[0] = 0x00; // 0 deg
  ctrl_word[1] = 0x10; // 90 deg
  ctrl_word[2] = 0x20; // 180 deg
  ctrl_word[3] = 0x30; // 270 deg 

  phaseShifterWrite(SPI_LE11, 0x00);
  phaseShifterWrite(SPI_LE21, 0x08);
  phaseShifterWrite(SPI_LE12, 0x00);
  phaseShifterWrite(SPI_LE22, 0x08);
  phaseShifterWrite(SPI_LE13, 0x00);
  phaseShifterWrite(SPI_LE23, 0x08);
  phaseShifterWrite(SPI_LE14, 0x00);
  phaseShifterWrite(SPI_LE24, 0x08);
  phaseShifterWrite(SPI_LE15, 0x00);
  phaseShifterWrite(SPI_LE25, 0x08);  
  phaseShifterWrite(SPI_LE16, 0x00);
  phaseShifterWrite(SPI_LE26, 0x08);
}



void loop() {
  // delay() is also in milliseconds
  // change millis() to micros(), and compare synchronization accuracy
  unsigned long currentMillis = millis();
  if (currentMillis - lastMillis >= 20) {
    lastMillis = currentMillis;

    // Cycle through control words
    // phaseShifterWrite(SPI_LE16, ctrl_word[currentWord % CTRL_WORD_COUNT]);
    uint8_t data1 = 0x08;
    uint8_t data2 = ctrl_word[currentWord % CTRL_WORD_COUNT] + 0x08;
    // phaseShifterWrite(SPI_LE26, data1);

    // Trigger the slave to send data
    digitalWrite(TRIGGER_PIN, HIGH);
    delayMicroseconds(50);  // Ensure the slave has time to recognize the trigger
    digitalWrite(TRIGGER_PIN, LOW);

    // Cycle to the next control word for the next iteration
    currentWord = (currentWord + 1) % CTRL_WORD_COUNT;
  }

}


void phaseShifterWrite(uint8_t device_id, uint8_t ctrl_word) {
  //  send ctrl_word via SPI:
  
  SPI.beginTransaction(settingsA);
  // take the device_id pin low to de-select the chip:
  digitalWrite(device_id, LOW);  
  SPI.transfer(ctrl_word);
  // take the device_id pin high to select the chip:
  digitalWrite(device_id, HIGH);
  digitalWrite(device_id, LOW);   
  SPI.endTransaction();  
}

