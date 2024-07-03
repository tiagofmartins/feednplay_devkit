DataTransmitter dataTx;

void setup() {
  size(444, 222);
  frameRate(60);
  dataTx = new DataTransmitter(this);
}

void draw() {
  dataTx.run();
  //if (frameCount % 60 == 0) {
    background(200);

    textAlign(LEFT, TOP);
    textSize(30);
    fill(32);

    translate(g.textSize * 0.5, g.textSize * 0.5);
    text("Do NOT close this program.", 0, 0);
    textSize(20);
    translate(0, g.textSize * 2);
    text("Requests received: " + dataTx.requestsReceived, 0, 0);
    translate(0, g.textSize * 2);
    text("Requests replied: " + dataTx.requestsReplied, 0, 0);
  //}

  if (dataTx.cameraInput.lastFrame != null) {
    image(dataTx.cameraInput.lastFrame, 0, 0, 200, 200);
  }
}
