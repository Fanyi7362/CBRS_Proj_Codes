#include <SPI.h>

// AMPLIFIER ENABLE
// high: amplifier on, low: amplifier bypass
#define EN_AMP  13

// PHASE SHIFTER SELECTION
// 12 phase shifters from bottom to top, bottom is the microcontroller side
// their net name are as follows: 
// SPI_LE21, SPI_LE11, SPI_LE22, SPI_LE12, SPI_LE23, SPI_LE13
// SPI_LE24, SPI_LE14, SPI_LE25, SPI_LE15, SPI_LE26, SPI_LE16
#define N_PHASE_SHIFTERS 12
int SPI_LE[N_PHASE_SHIFTERS] = {7, 6, A3, A4, A5, A6, 0, 1, 2, 3, 4, 5};
#define N_PHASE_SET 6
int SPI_LE_set1[N_PHASE_SET] = {7, A3, A5, 0, 2, 4}; // SPI_LE21, SPI_LE22, SPI_LE23, SPI_LE24, SPI_LE25, SPI_LE26
int SPI_LE_set2[N_PHASE_SET] = {6, A4, A6, 1, 3, 5}; // SPI_LE11, SPI_LE12, SPI_LE13, SPI_LE14, SPI_LE15, SPI_LE16
int phase_ind_set1[N_PHASE_SET]; // for even number indexed phase shifters, closer to the microcontroller, SPI_LE21, SPI_LE22, ...
int phase_ind_set2[N_PHASE_SET]; // for odd number indexed phase shifters, further to the microcontroller, SPI_LE11, SPI_LE12, ...

// SYNC PIN
// Pin to trigger the slave
#define TRIGGER_PIN  A1

// try SPI_MODE 0-3
// SPI_CLOCK: should be a fraction of the processor's clock speed 48MHz
// MIN Clock Period for phase shifter is 100ns
const uint32_t SPI_CLOCK = 8000000; // 8 MHz
SPISettings settingsA(SPI_CLOCK, MSBFIRST, SPI_MODE1);

// Control word array
// 4-bit phase shifter, so number of control words is 16
#define N_AVAL_PHASE 16 
uint8_t ctrl_word[N_AVAL_PHASE]; 

// Store the time of the last data send
unsigned long lastMillis = 0; 

#define INDEX_LENGTH 1
#define INDEX_MASK 0b111100 // used to extract the 4-bit phase index
#define ACK_SUCCESS1 0xFF
#define ACK_ERROR1 0xAA
#define ACK_ERROR2 0xBB
#define ACK_ERROR3 0xCC
#define PREAMBLE_LENGTH 2
const uint16_t PREAMBLE_1 = 0xAAAA;
const uint16_t PREAMBLE_2 = 0xBBBB;

void setup() {
  // initialize SPI:
  SPI.begin();
  
  // configure pins
  for (int i = 0; i < N_PHASE_SET; ++i) {
      pinMode(SPI_LE_set1[i], OUTPUT);
      phaseShifterWrite(SPI_LE_set1[i], 0x00);
      pinMode(SPI_LE_set2[i], OUTPUT);
      phaseShifterWrite(SPI_LE_set2[i], 0x00);
  }  
       
  pinMode(EN_AMP, OUTPUT); 
  pinMode(TRIGGER_PIN, OUTPUT);
  digitalWrite(EN_AMP, HIGH);
  digitalWrite(TRIGGER_PIN, LOW);

  // Initialize control words
  // 0x00:    0 deg, 0x04: 22.5 deg
  // 0x08:   45 deg, 0x0c: 67.5 deg
  // 0x10:   90 deg
  // 0x20:  180 deg
  // 0x30:  270 deg
  // 0x38:  315 deg, 0x3c: 337.5 deg
  for(int i = 0; i < 16; ++i) {
      ctrl_word[i] = i * 0x04;
  }

  // Begin the Serial at baud rate 115200, 460800, 921600
  Serial.begin(460800); 
}


void loop() {
  // delay() is in unit of milliseconds

  if (Serial.available() >= PREAMBLE_LENGTH) {
    // Read the preamble
    uint16_t preamble;
    Serial.readBytes((char*)&preamble, PREAMBLE_LENGTH);
    // Serial.println("Data received!\n");

    switch (preamble) {
      case PREAMBLE_1:
        // use phaseIndex for even number indexed phase shifters
        SPI.beginTransaction(settingsA);

        for(int i = 0; i < N_PHASE_SET; ++i) {
          int phaseIndex = readPhaseIndex();
          if(phaseIndex != -1) {
            phase_ind_set1[i] = phaseIndex;
            phaseShifterWrite(SPI_LE_set1[i], ctrl_word[phaseIndex]);
            if(i==N_PHASE_SET-1) {
              Serial.write((byte)ACK_SUCCESS1); // Send a success acknowledgement
            }
          }
          else{
            // error handling
            Serial.write((byte)ACK_ERROR1); 
            // flush to clear the receive buffer
            while(Serial.available() > 0) {
                Serial.read();
            }            
            break;
          }
        }

        SPI.endTransaction(); 
        break;

      case PREAMBLE_2:
        Serial.write((byte)ACK_ERROR2);
        // flush to clear the receive buffer
        while(Serial.available() > 0) {
            Serial.read();
        }               
        // use phaseIndex for odd number indexed phase shifters
        break;

      default:
        // Handle an unknown preamble here
        Serial.write((byte)ACK_ERROR3); // Send an error acknowledgement
        // flush to clear the receive buffer
        while(Serial.available() > 0) {
            Serial.read();
        }                
        break;
    }
  }  

}

//  send ctrl_word to phase shifter via SPI
void phaseShifterWrite(uint8_t device_id, uint8_t ctrl_word) {  
  // take the device_id pin low to de-select the chip:
  digitalWrite(device_id, LOW);  
  SPI.transfer(ctrl_word);
  // take the device_id pin high to select the chip:
  digitalWrite(device_id, HIGH);
  digitalWrite(device_id, LOW);      
}

int readPhaseIndex() {
  const unsigned long TIMEOUT = 1000; // 1000 microseconds  
  unsigned long startTime = micros();

  while(Serial.available() < INDEX_LENGTH) {
    if (micros() - startTime >= TIMEOUT) {
      return -1; // Timeout
    }
  }  

  char buffer;
  Serial.readBytes(&buffer, INDEX_LENGTH);
  int phaseIndex = ((buffer & INDEX_MASK) >> 2); // shift right 2 bits

  if (phaseIndex >= 0 && phaseIndex <= 15) {
    return phaseIndex;
  }
  else {
    return -1;
  }
}

