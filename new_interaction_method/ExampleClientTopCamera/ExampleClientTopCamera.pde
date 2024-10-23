FnpDataReceiver receiver;
PImage image = null;

void settings() {
  size(1000, 800);
}

void setup() {
  frameRate(60);
  receiver = new FnpDataReceiver(this, 23000, Topic.IMG_CAMTOP_RGB);
  receiver.requestData();
}

void draw() {
  if (receiver.newDataAvailable()) {
    image = receiver.getData();
    receiver.requestData();
  }

  background(255);
  if (image != null) {
    image(image, 0, 0);
  } else {
    textAlign(CENTER, CENTER);
    text("No data received yet", width / 2, height / 2);
  }
}
