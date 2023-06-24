#define PIN_POT A3
#define PIN_BUTTON 7

void setup() {
  Serial.begin(9600);
  pinMode(PIN_BUTTON, INPUT_PULLUP);
}

void loop() {
  int potValue = analogRead(PIN_POT);
  Serial.print("p");
  Serial.println(potValue);
  int buttonValue = digitalRead(PIN_BUTTON);
  Serial.print("b");
  Serial.println(buttonValue);
  delay(100);
}