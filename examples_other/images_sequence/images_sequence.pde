FnpMedia media;
File[] mediaFiles;
int indexCurrFile = 0;

void settings() {
  fnpSize(777, 555);
  //fnpFullScreen(P2D);
}

void setup() {
  frameRate(60);
  mediaFiles = getFiles(new File(dataPath("")), ".png");
  assert mediaFiles.length > 0;
  ContentArea area = new ContentArea(new Rect(0, 0, width, height), 20, 20);
  media = new FnpImg(this, area, mediaFiles[indexCurrFile].getPath(), 4000);
  media.setFadeInOutDuration(500, 500);
  fnpEndSetup();
}

void draw() {
  if (frameCount == 2) {
    media.load();
  }
  if (media.finished()) {
    indexCurrFile = (indexCurrFile + 1) % mediaFiles.length;
    media.setPath(mediaFiles[indexCurrFile].getPath());
  }
  background(0);
  media.display();
}
