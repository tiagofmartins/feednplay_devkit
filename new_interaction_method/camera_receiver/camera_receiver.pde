DataReceiver receiver;
PImage cameraImage = null;

void settings() {
  size(1000, 800);
}

void setup() {
  frameRate(60);
  receiver = new DataReceiver(this, 23000, Topic.IMG_CAMTOP_RGB_720H);
  receiver.requestData();
}

void draw() {
  if (receiver.newDataAvailable()) {
    cameraImage = receiver.getData();
    receiver.requestData();
  }

  background(0);
  if (cameraImage != null) {
    image(cameraImage, 0, 0);
  } else {
    textAlign(CENTER, CENTER);
    text("No data received yet", width / 2, height / 2);
  }
}
