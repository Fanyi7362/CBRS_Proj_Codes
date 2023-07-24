#include <SPI.h>

const byte SS_PIN = 10;  // Slave Select pin for MKR WiFi 1010
const byte TRIGGER_PIN = A1; // Pin to trigger the slave
const uint32_t SPI_CLOCK = 4000000; // 4 MHz
unsigned long lastMillis = 0; // Store the time of the last data send

void setup() {
  // set the Slave Select pin as output:
  pinMode(SS_PIN, OUTPUT);

  // set the trigger pin as output:
  pinMode(TRIGGER_PIN, OUTPUT);
  
  // initialize SPI:
  SPI.begin();
}

void loop() {
  // delay() is also in milliseconds
  // change millis() to micros(), and compare synchronization accuracy
  unsigned long currentMillis = millis();
  if (currentMillis - lastMillis >= 10) {
    lastMillis = currentMillis;

    byte data1 = 0x01;  // Data to be sent
    byte data2 = 0x02;  // Data to be sent

    SPI.beginTransaction(SPISettings(SPI_CLOCK, MSBFIRST, SPI_MODE0));

    digitalWrite(SS_PIN, LOW);

    SPI.transfer(data1);
    SPI.transfer(data2);

    digitalWrite(SS_PIN, HIGH);
    
    SPI.endTransaction();

    // Trigger the slave to send data
    digitalWrite(TRIGGER_PIN, HIGH);
    delay(1);  // Ensure the slave has time to recognize the trigger
    digitalWrite(TRIGGER_PIN, LOW);
  }
}