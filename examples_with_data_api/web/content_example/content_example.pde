void settings() {
  fnpSize(500, 500, P2D);
  smooth(8);
}

void setup() {
  frameRate(60);
  textAlign(CENTER, CENTER);
  textSize(min(width, height) / 10f);
  fill(0);
  fnpEndSetup();
}

void draw() {
  background(240);
  text(getBitcoinPrice() + "$", width / 2, height / 2);
}

float getBitcoinPrice() {
  // TODO >>>>>>>>>>>>>>>>>>>>>>>>>>>>>> get data from API here <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  return round(1000 * noise(millis() / 100000f));
}
