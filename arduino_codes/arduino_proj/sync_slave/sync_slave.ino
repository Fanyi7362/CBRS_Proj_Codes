#include <SPI.h>

const byte SS_PIN = 10;  // Slave Select pin for MKR WiFi 1010
const byte TRIGGER_PIN = A1; // Pin to receive trigger from master
const uint32_t SPI_CLOCK = 4000000; // 4 MHz

void setup() {
  // set the Slave Select pin as output:
  pinMode(SS_PIN, OUTPUT);

  // set the trigger pin as input:
  pinMode(TRIGGER_PIN, INPUT);

  // initialize SPI:
  SPI.begin();
  
  // Attach an interrupt to the trigger pin
  attachInterrupt(digitalPinToInterrupt(TRIGGER_PIN), sendData, RISING);
}

void loop() {
  // No action in main loop
}

void sendData() {
  byte data1 = 0x01;  // Data to be sent
  byte data2 = 0x02;  // Data to be sent

  SPI.beginTransaction(SPISettings(SPI_CLOCK, MSBFIRST, SPI_MODE0));

  digitalWrite(SS_PIN, LOW);

  SPI.transfer(data1);
  SPI.transfer(data2);

  digitalWrite(SS_PIN, HIGH);
  
  SPI.endTransaction();
}