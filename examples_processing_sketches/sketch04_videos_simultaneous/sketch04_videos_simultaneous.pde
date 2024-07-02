import java.util.*;

int numVideosSimultaneous = 3;

File[] videoFiles;
FnpVid[] videos;

void settings() {
  fnpSize(777, 777, P2D);
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
    videos = new FnpVid[numVideosSimultaneous];
    for (int i = 0; i < videos.length; i++) {
      videos[i] = new FnpVid(this, getRandomArea(), getRandomVideoPath(), false, 0);
      videos[i].setFadeInOutDuration(1000, 1000);
      videos[i].load();
    }
  } else if (frameCount > 2) {
    for (int i = 0; i < videos.length; i++) {
      if (videos[i].isLoaded() &&  videos[i].finished()) {
        videos[i] = new FnpVid(this, getRandomArea(), getRandomVideoPath(), false, 0);
        videos[i].setFadeInOutDuration(1000, 1000);
        videos[i].load();
      }
    }
    background(0);
    for (FnpVid v : videos) {
      v.display();
      //v.bounds.preview(getGraphics());
    }
  }
}

String getRandomVideoPath() {
  ArrayList<File> videoFilesShuffled = new ArrayList<File>();
  for (File f : videoFiles) {
    videoFilesShuffled.add(f);
  }
  Collections.shuffle(videoFilesShuffled);
  File randomVideoFile = null;
  for (File f : videoFilesShuffled) {
    boolean alreadyPlaying = false;
    for (FnpVid v : videos) {
      if (v != null && v.path.equals(f.getPath())) {
        alreadyPlaying = true;
        break;
      }
    }
    if (!alreadyPlaying) {
      randomVideoFile = f;
    }
  }
  assert randomVideoFile != null;
  return randomVideoFile.getPath();
}

ContentArea getRandomArea() {
  float areaW = random(0.2, 0.4) * width;
  float areaH = random(0.2, 0.4) * height;
  float areaX = random(0, width - areaW);
  float areaY = random(0, height - areaH);
  float areaM = min(areaW, areaH) * 0.05;
  return new ContentArea(new Rect(areaX, areaY, areaW, areaH), areaM);
}
