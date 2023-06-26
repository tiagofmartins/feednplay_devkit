MovingImage[] images = new MovingImage[100];

void setup() {
  size(9720 / 4, 1920 / 4, P2D);
  smooth(8);
  blendMode(ADD);
  for (int i = 0; i < images.length; i++) {
    images[i] = new MovingImage();
  }
}

void draw() {
  background(0);
  for (MovingImage mi : images) {
    mi.update();
    mi.display();
  }
}

class MovingImage {

  PImage image;
  float x, y, w, h;
  float speedX, speedY;
  color colour;
  
  MovingImage() {
    image = loadImage("dvd_logo.png");
    h = height / 10f;
    w = h * (image.width / (float) image.height);
    x = random(width - w);
    y = random(height - h);
    speedX = random(0.5, 2) * (random(1) < 0.5 ? 1 : -1);
    speedY = random(0.5, 2) * (random(1) < 0.5 ? 1 : -1);
    colour = color(random(100, 255), random(100, 255), random(100, 255));
  }

  void update() {
    x += speedX;
    y += speedY;
    if (x > width - w || x < 0) {
      speedX *= -1;
      colour = color(random(100, 255), random(100, 255), random(100, 255));
    }
    if (y > height - h || y < 0) {
      speedY *= -1;
      colour = color(random(100, 255), random(100, 255), random(100, 255));
    }
  }

  void display() {
    pushStyle();
    tint(colour);
    image(image, x, y, w, h);
    popStyle();
  }
}
