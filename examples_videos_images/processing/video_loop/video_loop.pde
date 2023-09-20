String pathToVideo = "v02.mp4";
FnpMedia media;

void settings() {
  fnpSize(444, 777, P2D);
}

void setup() {
  frameRate(60);
}

void draw() {
  if (frameCount == 2) {
    // Set video area in the second frame since the window
    // is only properly resized after the first draw loop.
    ContentArea area = new ContentArea(new Rect(0, 0, width, height), 20, 20);
    media = new FnpVid(this, area, pathToVideo, true, 0);
    media.setFadeInOutDuration(1000, 1000);
    // Load the video file after the first frame to prevent
    // Processing to rise a timeout exception of 5000 ms.
    media.load();
  }
  background(0);
  if (media != null) {
    media.display();
    //media.bounds.preview(getGraphics());
  }
}
