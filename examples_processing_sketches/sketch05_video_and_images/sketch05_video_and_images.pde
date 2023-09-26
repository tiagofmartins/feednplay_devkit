FnpMedia[] media;

void settings() {
  fnpSize(972, 192, P2D);
  //fnpFullScreen(P2D);
}

void setup() {
  frameRate(60);
  background(0);
}

void draw() {
  if (frameCount == 2) {
    // Set media areas in the second frame since the window
    // is only properly resized after the first draw loop.
    media = new FnpMedia[3];
    ContentArea[] areas = new ContentArea[media.length];
    float areaWidth = width / float(areas.length);
    float areaMargin = areaWidth * 0.03;
    for (int i = 0; i < areas.length; i++) {
      areas[i] = new ContentArea(new Rect(i * areaWidth, 0, areaWidth, height), areaMargin, areaMargin);
    }
    media[1] = new FnpVid(this, areas[1], "vidh09.mp4", true, 1);
    media[0] = new FnpImg(this, areas[0], "imgh03.png");
    media[2] = new FnpImg(this, areas[2], "imgh05.png");
    // Load media after the first frame to prevent
    // Processing to rise a timeout exception of 5000 ms.
    for (FnpMedia m : media) {
      m.load();
    }
  } else if (frameCount > 2) {
    background(0);
    for (FnpMedia m : media) {
      m.display();
    }
  }
}
