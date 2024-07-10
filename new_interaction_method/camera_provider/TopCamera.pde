import processing.video.*;
import gab.opencv.*;

class TopCamera extends DataSource {

  Capture camera; // https://github.com/processing/processing-video/blob/main/src/processing/video/Capture.java
  Movie video; // https://github.com/processing/processing-video/blob/main/src/processing/video/Movie.java
  PImage lastFrame = null;

  TopCamera(PApplet parent, boolean makeUpData) {
    super(parent, makeUpData);
  }

  protected void startCapture() {
    if (makeUpData) {
      video = new Movie(parent, "top-camera-sample.mp4");
      video.loop();
      video.play();
      video.volume(0);
    } else {
      camera = new Capture(parent, 1920, 1080, "FaceTime HD Camera", 30);
      camera.start();
    }
    delay(2000);
  }

  protected void stopCapture() {
    if (makeUpData) {
      video.stop();
      video.dispose();
      video = null;
    } else {
      camera.stop();
      camera.dispose();
      camera = null;
    }
  }

  protected boolean isCapturing() {
    if (makeUpData) {
      return video != null && video.isPlaying();
    } else {
      return camera != null && camera.isCapturing();
    }
  }

  public void run() {
    super.run();
    if (makeUpData) {
      if (video != null && video.available()) {
        video.read();
        lastFrame = video.get();
      }
    } else {
      if (camera != null && camera.available()) {
        camera.read();
        lastFrame = camera.get();
      }
    }
  }

  PImage getLastFrame() {
    updateTimeLastUse();
    return lastFrame;
  }
}
