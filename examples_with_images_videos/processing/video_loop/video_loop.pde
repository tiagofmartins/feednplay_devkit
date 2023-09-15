FnpMedia media;

void settings() {
  fnpSize(444, 777);
  //fnpFullScreen(P2D);
}

void setup() {
  frameRate(60);
  ContentArea area = new ContentArea(new Rect(0, 0, width, height), 20, 20);
  media = new FnpVid(this, area, getFiles(new File(dataPath("")), ".mp4")[0].getPath(), true, 0);
  media.setFadeInOutDuration(1000, 1000);
  fnpEndSetup();
}

void draw() {
  if (frameCount == 2) {
    media.load();
  }
  background(0);
  media.display();
}
