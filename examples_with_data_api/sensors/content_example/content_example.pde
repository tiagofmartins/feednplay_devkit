color c1 = color(random(150, 255), random(150, 255), random(150, 255));
color c2 = color(random(100, 200), random(100, 200), random(100, 200));

void settings() {
  fnpSize(500, 500, P2D);
  smooth(8);
}

void setup() {
  frameRate(60);
  fnpEndSetup();
}

void draw() {
  background(c1);
  stroke(c2);
  strokeWeight(10);
  if (buttonIsPressed()) {
    fill(c2);
  } else {
    noFill();
  }
  circle(width / 2, height / 2, map(getPotentiometerValue(), 0, 1024, 0, min(width, height)));
}

boolean buttonIsPressed() {
  // TODO >>>>>>>>>>>>>>>>>>>>>>>>>>>>>> get data from API here <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  return noise(11111 + millis() / 1000f) < 0.5;
}

int getPotentiometerValue() {
  // TODO >>>>>>>>>>>>>>>>>>>>>>>>>>>>>> get data from API here <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  //return round(map(cos(frameCount / 10f), -1, 1, 0, 1024));
  return round(noise(22222 + millis() / 1000f) * 1024);
}
