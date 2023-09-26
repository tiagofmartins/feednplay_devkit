String pathToVideo = "vidv02.mp4";

FnpMedia media;

void settings() {
  fnpSize(444, 777, P2D);

  // Allow the video path to be passed by argument.
  // This only has an effect when the sketch is executed from the command line.
  if (fnpArguments.hasKey("video")) {
    pathToVideo = fnpArguments.get("video");
  }
}

void setup() {
  frameRate(60);
  background(0);
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
  } else if (frameCount > 2) {
    background(0);
    media.display();
    //media.bounds.preview(getGraphics());
  }
}
