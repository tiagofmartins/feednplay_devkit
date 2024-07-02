FnpMedia media = null;
File[] mediaFiles;
int indexCurrFile = 0;

void settings() {
  fnpSize(777, 555, P2D);
  //fnpFullScreen(P2D);
  smooth(8);
}

void setup() {
  frameRate(60);
  background(0);
  mediaFiles = getFiles(new File(dataPath("")), ".png");
}

void draw() {
  if (frameCount == 2) {
    // Set media areas in the second frame since the window
    // is only properly resized after the first draw loop.
    ContentArea area = new ContentArea(new Rect(0, 0, width, height), 20, 20);
    media = new FnpImg(this, area, mediaFiles[indexCurrFile].getPath(), 4000);
    media.setFadeInOutDuration(500, 500);
    media.load();
  } else if (frameCount > 2) {    
    if (media.finished()) {
      indexCurrFile = (indexCurrFile + 1) % mediaFiles.length;
      media.setPath(mediaFiles[indexCurrFile].getPath());
      media.load();
    }
    background(0);
    media.display();
  }
}
