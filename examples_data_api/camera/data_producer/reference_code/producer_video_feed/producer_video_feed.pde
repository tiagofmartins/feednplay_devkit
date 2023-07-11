import processing.video.*;

int capture_max_width = 1280;
int capture_max_height = 720;

Capture video;

void setup() {
  size(640, 480, P2D);
  video = new Capture(this, capture_max_width, capture_max_height);
  video.start(); 
}

void draw() {
  if (video.available()) {
    video.read();
    image(video, 0, 0);
    //video.loadPixels();
    PImage res = video.copy();
    res.resize(200, 200);
    image(res, 0, 0);
  }
}
