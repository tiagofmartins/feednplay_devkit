boolean makeUpData = true;
boolean debug = false;

DataTransmitter transmitter;

void setup() {
  size(444, 222);
  frameRate(60);
  
  transmitter = new DataTransmitter(this, 23000, makeUpData);
}

void draw() {
  transmitter.run();
  
  if (debug) {
    image(transmitter.topCamera.getLastFrame(), 0, 0, 200, 200);
  } else {
    background(200);

    textAlign(LEFT, TOP);
    textSize(30);
    fill(32);

    translate(g.textSize * 0.5, g.textSize * 0.5);
    text("Do NOT close this program.", 0, 0);
    textSize(20);
    translate(0, g.textSize * 2);
    text("Requests received: " + transmitter.requestsReceived, 0, 0);
    translate(0, g.textSize * 2);
    text("Requests replied: " + transmitter.requestsReplied, 0, 0);
  }
}

void keyPressed() {
  if (key == ' ') {
    debug = !debug;
    if (debug) {
      surface.setSize(1000, 750);
    } else {
      surface.setSize(400, 150);
    }
  }
}
