abstract class DataSource {

  protected PApplet parent;
  protected boolean makeUpData;
  protected long timeLastUse = 0;

  DataSource(PApplet parent, boolean makeUpData) {
    this.parent = parent;
    this.makeUpData = makeUpData;
  }

  protected abstract void startCapture();

  protected abstract void stopCapture();

  protected abstract boolean isCapturing();
  
  public void run() {
    controlStartAndStop();
  }
  
  protected void controlStartAndStop() {
    if (System.currentTimeMillis() - timeLastUse < 10000) {
      if (!isCapturing()) {
        startCapture();
      }
    } else {
      if (isCapturing()) {
        stopCapture();
      }
    }
  }
  
  protected void updateTimeLastUse() {
    timeLastUse = System.currentTimeMillis();
  }
}
