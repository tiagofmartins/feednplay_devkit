PImage image = null;

void setup() {
  size(640, 480);
}

void draw() {
  if (image != null) {
    image(image, 0, 0);
  }
}
