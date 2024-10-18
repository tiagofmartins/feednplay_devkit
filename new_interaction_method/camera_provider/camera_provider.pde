boolean useRealData = false;
boolean debug = true;
DataTransmitter transmitter;

void settings() {
  size(1000, 800);
  smooth(8);
}

void setup() {
  frameRate(60);
  transmitter = new DataTransmitter(this, 23000, useRealData);
}

void draw() {
  transmitter.run();

  if (debug) {
    PImage frame = transmitter.topCamera.getData("IMG_RGB");
    if (frame != null) {
      image(frame, 0, 0, 200, 200);
    }
    PImage frame2 = transmitter.topCamera.getData("IMG_CROP");
    if (frame2 != null) {
      image(frame2, mouseX, mouseY, 200, 200);
    }
  } else {
    background(220);
    
    push();
    translate(width - height / 2, height / 2);
    rotate(frameCount / 20f);
    noFill();
    stroke(transmitter.topCamera.isCapturing() ? color(100, 220, 100) : color(200));
    strokeWeight(height * 0.1);
    arc(0, 0, height * 0.5, height * 0.5, 0, PI);
    pop();
    
    String text = "DO NOT CLOSE THIS PROGRAM.\n\n";
    text += "Capturing: " + (transmitter.topCamera.isCapturing() ? "yes" : "no") + "\n";
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
