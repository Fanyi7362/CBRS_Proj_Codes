volatile unsigned long t1, t2;

void setup() {
  // Initialize Serial
  Serial.begin(9600);
  
  // Set A1 as output for the trigger pin
  pinMode(A1, OUTPUT);
  
  // Set A2 as input for the trigger from the slave
  pinMode(A2, INPUT);

  // Attach an interrupt to A2
  attachInterrupt(digitalPinToInterrupt(A2), ISR_slaveTrigger, RISING);
}

void loop() {
  t1 = micros();  // get timestamp t1
  digitalWrite(A1, HIGH);  // Set A1 HIGH to trigger slave
  delay(1);  // delay 1ms for trigger signal
  digitalWrite(A1, LOW);  // Set A1 LOW
  delay(9);  // delay 9ms to complete 10ms cycle
}

void ISR_slaveTrigger() {
  t2 = micros();  // get timestamp t2 when the slave triggers back
  Serial.println(t2 - t1);  // send t2-t1 to PC
}