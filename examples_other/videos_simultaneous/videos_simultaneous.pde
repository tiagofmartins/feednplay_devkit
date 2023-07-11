int numMediaToShow = 5;
FnpMedia[] media;

void settings() {
  fnpSize(777, 777);
  //fnpFullScreen(P2D);
}

void setup() {
  frameRate(60);

  File[] mediaFiles = getFiles(new File(dataPath("")), ".mp4");
  assert mediaFiles.length > 0;
  media = new FnpMedia[mediaFiles.length];
  for (int i = 0; i < media.length; i++) {
    media[i] = new FnpVid(this, new ContentArea(new Rect(0, 0, 100, 100)), mediaFiles[i].getPath(), false, 0);
    media[i].setFadeInOutDuration(1000, 1000);
  }

  fnpEndSetup();
}

void draw() {
  if (frameCount == 2) {
    for (FnpMedia m : media) {
      m.load();
    }
  }
  for (FnpMedia m : media) {
    if (m.isLoaded() && (m.bounds.getContentBounds() == null || m.finished())) {
      placeAtRandom(m);
      ((FnpVid) m).restart();
    }
  }
  background(0);
  for (FnpMedia m : media) {
    m.display();
    //m.bounds.preview(getGraphics());
  }
}

void placeAtRandom(FnpMedia m) {
  //for (int attempt)
  float maxDim = random(200, 400);
  float[] dim = resizeToFitInside(m.getOriginalWidth(), m.getOriginalHeight(), maxDim, maxDim);
  float padding = 20;
  ContentArea area = new ContentArea(new Rect(random(0, width - dim[0]), random(0, height - dim[1]), dim[0], dim[1]), padding, padding);
  m.setBounds(area);
}
