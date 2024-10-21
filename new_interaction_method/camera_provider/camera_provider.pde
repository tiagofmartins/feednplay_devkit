boolean useRealData = false;
boolean debug = true;

InputCameraTop camera;
DataTransmitter transmitter;

void settings() {
  size(1000, 800);
  smooth(8);
}

void setup() {
  frameRate(60);
  
  camera = new InputCameraTop(this, useRealData);
  transmitter = new DataTransmitter(this, camera, 23000);
}

void draw() {
  camera.update();
  transmitter.update();

  if (debug) {
    PImage img1 = camera.getTopic(Topic.IMG_CAMTOP_RGB);
    if (img1 != null) {
      image(img1, 0, 0, 200, 200);
    }
    PImage img2 = camera.getTopic(Topic.IMG_CAMTOP_CROP_RGB);
    if (img2 != null) {
      image(img2, mouseX, mouseY, 200, 200);
    }
  } else {
    background(220);
    
    push();
    translate(width - height / 2, height / 2);
    rotate(frameCount / 20f);
    noFill();
    stroke(camera.isCapturing() ? color(100, 220, 100) : color(200));
    strokeWeight(height * 0.1);
    arc(0, 0, height * 0.5, height * 0.5, 0, PI);
    pop();
    
    String text = "DO NOT CLOSE THIS PROGRAM.\n\n";
    text += "Capturing: " + (camera.isCapturing() ? "yes" : "no") + "\n";
    text += "Requests received: " + transmitter.requestsReceived + "\n";
    text += "Requests replied: " + transmitter.requestsReplied + "\n";
    fill(32);
    textSize(20);
    textAlign(LEFT, TOP);
    text(text, 15, 20);
  }
}

void keyReleased() {
  if (key == 'd') {
    debug = !debug;
    if (debug) {
      surface.setSize(1000, 750);
    } else {
      surface.setSize(450, 150);
    }
  }
}
