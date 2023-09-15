const int potentiometerPin = A3;
const int buttonPin = 7;

void setup() {
  Serial.begin(9600);
  pinMode(buttonPin, INPUT_PULLUP);
}

void loop() {
  Serial.print("p");
  Serial.print(analogRead(potentiometerPin));
  Serial.print(" b");
  Serial.println(digitalRead(buttonPin) == LOW);
  delay(33);
}