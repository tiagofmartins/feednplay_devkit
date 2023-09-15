void settings() {
  fnpSize(100, 100, 333, 555, P2D, true);
  smooth(8);
}

void setup() {
  frameRate(60);
  background(random(150, 255), random(150, 255), random(150, 255));
  stroke(random(100, 200), random(100, 200), random(100, 200));
  strokeWeight(random(10, 40));
  strokeCap(SQUARE);
}

void draw() {
  background(g.backgroundColor);
  translate(width / 2f, height / 2f);
  rotate(map(cos(frameCount / 25f), -1, 1, -QUARTER_PI, QUARTER_PI));
  line(-0.4f * min(width, height), 0, 0.4f * min(width, height), 0);
}
