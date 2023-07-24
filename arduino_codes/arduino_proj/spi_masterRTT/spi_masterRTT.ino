// #include <SPI.h>

// unsigned long t1, t2;

// void setup() {
//   Serial.begin(9600);
//   SPI.begin();
// }

// void loop() {
//   byte returnedByte;

//   t1 = micros();
//   returnedByte = SPI.transfer(0xff);  // send data to the slave
//   if(returnedByte == 0x00) {
//     t2 = micros();
//     Serial.println(t2 - t1);
//   }
//   delay(10);
// }

#include <SPI.h>
const byte SS_PIN = 10;  // Slave Select pin for MKR WiFi 1010
const uint32_t SPI_CLOCK = 4000000; // 4 MHz

void setup() {
  pinMode(SS_PIN, OUTPUT);  
  Serial.begin(9600);
  SPI.begin();
}

void loop() {
  byte data = 0xAA; // Arbitrary data
  unsigned long start, end, elapsed;

  start = micros(); 
  SPI.beginTransaction(SPISettings(SPI_CLOCK, MSBFIRST, SPI_MODE0));
  digitalWrite(SS_PIN, LOW);
  SPI.transfer(data);
  digitalWrite(SS_PIN, HIGH);
  SPI.endTransaction();
  end = micros();

  elapsed = end - start;
  Serial.println(elapsed);

  delay(10); // Wait for a second before next measurement
}