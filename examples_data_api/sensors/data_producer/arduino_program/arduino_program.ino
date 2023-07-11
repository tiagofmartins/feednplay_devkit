#define PIN_POT A3
#define PIN_BUTTON 7

void setup() {
  Serial.begin(9600);
  pinMode(PIN_BUTTON, INPUT_PULLUP);
}

void loop() {
  Serial.print("p");
  Serial.print(analogRead(PIN_POT));
  Serial.print(" b");
  Serial.println(digitalRead(PIN_BUTTON) == LOW);
  delay(100);
}