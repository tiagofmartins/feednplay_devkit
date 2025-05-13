color bgColor = color(random(150, 255), random(150, 255), random(150, 255));
color lineColor = color(random(100, 200), random(100, 200), random(100, 200));

void settings() {
  fnpSize(333, 555, P2D);
  //fnpSize(100, 100, 333, 555, P2D, true);
  //fnpFullScreen(P2D);
  smooth(8);
}

void setup() {
  frameRate(60);
}

void draw() {
  background(bgColor);
  translate(width / 2f, height / 2f);
  rotate(map(cos(frameCount / 25f), -1, 1, -QUARTER_PI, QUARTER_PI));
  stroke(lineColor);
  strokeWeight(0.1 * min(width, height));
  strokeCap(SQUARE);
  line(-0.4f * min(width, height), 0, 0.4f * min(width, height), 0);
}
