#include <SPI.h>

void setup (void) {
  SPI.begin(); 
  pinMode(MISO, OUTPUT); 
}

byte x = 0;

void loop (void) {
  byte a = SPI.transfer (0);
  if (a == 0xff) {
    SPI.transfer(x);
  }
}