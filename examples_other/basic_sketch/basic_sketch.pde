color c1;
color c2;

void settings() {
  fnpSize(500, 500, P2D); // <-- Use this line to replace the typical size() function
  //fullScreen(P2D);
  smooth(8);
}

void setup() {
  frameRate(60);
  c1 = color(random(150, 255), random(150, 255), random(150, 255));
  c2 = color(random(100, 200), random(100, 200), random(100, 200));
  fnpEndSetup(); // <-- Insert this line at the end of the setup() function
}

void draw() {
  background(c1);
  translate(width / 2f, height / 2f);
  rotate(map(cos(frameCount / 25f), -1, 1, -QUARTER_PI, QUARTER_PI));
  strokeWeight(30);
  strokeCap(SQUARE);
  stroke(c2);
  float l = min(width, height) * 0.4f;
  line(-l, 0, l, 0);
}
