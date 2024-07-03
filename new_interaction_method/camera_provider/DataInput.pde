import processing.video.*;

abstract class DataInput {

  protected PApplet parent;
  protected long timeLastUse = 0;

  DataInput(PApplet parent) {
    this.parent = parent;
  }

  protected abstract void startCapture();

  protected abstract void stopCapture();
  
  protected abstract boolean isCapturing();
  
  protected void controlStartAndStop() {
    if (System.currentTimeMillis() - timeLastUse < 10000) {
      if (isCapturing() == false) {
        startCapture();
      }
    } else {
      if (isCapturing() == true) {
        stopCapture();
      }
    }
  }
  
  protected void updateTimeLastUse() {
    timeLastUse = System.currentTimeMillis();
  }
  
  public void run() {
    controlStartAndStop();
  }
}




class CameraInput extends DataInput {
  
  Capture camera; // https://github.com/processing/processing-video/blob/main/src/processing/video/Capture.java
  PImage lastFrame = null;

  CameraInput(PApplet parent) {
    super(parent);
  }

  protected void startCapture() {
    camera = new Capture(parent, 1920, 1080, "FaceTime HD Camera", 30);
    camera.start();
  }

  protected void stopCapture() {
    camera.stop();
    camera.dispose();
    camera = null;
  }
  
  protected boolean isCapturing() {
    return camera != null && camera.isCapturing();
  }

  public void run() {
    super.run();
    if (camera != null && camera.available()) {
      camera.read();
      lastFrame = camera.get();
    }
  }

  PImage getLastFrame() {
    updateTimeLastUse();
    return lastFrame;
  }
}
