FnpDataReader reader;

void settings() {
  fnpSize(444, 444, JAVA2D);
  smooth(8);
}

void setup() {
  reader = new FnpDataReader("button_pressed", "potentiometer_value");
}

void draw() {
  // Get button state
  JSONObject json = reader.getValueAsJSON("button_pressed");
  boolean buttonPressed = false;
  if (json != null) {
    buttonPressed = json.getBoolean("value");
  }
  
  // Get potentiometer value
  json = reader.getValueAsJSON("potentiometer_value");
  int potentiometerValue = 0;
  if (json != null) {
    potentiometerValue = json.getInt("value");
  }
  
  // Create a visual representation of the data from the sensors
  background(128);
  noStroke();
  if (buttonPressed) {
    fill(0);
  } else {
    fill(255);
  }
  circle(width / 2, height / 2, map(potentiometerValue, 0, 1023, 0, min(width, height)));
}
