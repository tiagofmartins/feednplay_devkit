FnpMedia media;
File[] videoFiles;
int indexCurrVideo = 0;

void settings() {
  fnpSize(777, 555, P2D);
  //fnpFullScreen(P2D);
  smooth(8);
}

void setup() {
  frameRate(60);
  background(0);
}

void draw() {
  if (frameCount == 2) {
    videoFiles = getFiles(new File(dataPath("")), ".mp4");
    // Set video area in the second frame since the window
    // is only properly resized after the first draw loop.
    ContentArea area = new ContentArea(new Rect(0, 0, width, height), 20, 20);
    media = new FnpVid(this, area, videoFiles[indexCurrVideo].getPath(), false, 0);
    media.setFadeInOutDuration(1000, 1000);
    // Load the first video file after the first frame to prevent
    // Processing to rise a timeout exception of 5000 ms.
    media.load();
  } else if (frameCount > 2) {
    if (media.finished()) {
      indexCurrVideo = (indexCurrVideo + 1) % videoFiles.length;
      media.setPath(videoFiles[indexCurrVideo].getPath());
      media.load();
    }
    background(0);
    media.display();
  }
}
