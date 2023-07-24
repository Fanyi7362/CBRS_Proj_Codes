void setup() {
  // Set A1 as input for the trigger from the master
  pinMode(A1, INPUT);

  // Set A2 as output for the trigger pin
  pinMode(A2, OUTPUT);

  // Attach an interrupt to A1
  attachInterrupt(digitalPinToInterrupt(A1), ISR_masterTrigger, RISING);
}

void loop() {
  // Nothing to do in the main loop
}

void ISR_masterTrigger() {
  digitalWrite(A2, HIGH);  // Set A2 HIGH to trigger master
  delayMicroseconds(100);  // delay 100 microseconds for trigger signal
  digitalWrite(A2, LOW);  // Set A2 LOW
}