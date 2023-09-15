FnpDataReader reader1;
FnpDataReader reader2;

void settings() {
  fnpSize(666, 666, JAVA2D);
  smooth(8);
}

void setup() {
  reader1 = new FnpDataReader("image_frame_rgb_full");
  reader2 = new FnpDataReader("image_roi_gray_half");
  //reader2.setReadingsPerSecond(5);
}

void draw() {
  background(0);
  
  scale(0.5);

  PImage img1 = reader1.getValueAsPImage("image_frame_rgb_full");
  if (img1 != null) {
    image(img1, 0, 0);
  }

  PImage img2 = reader2.getValueAsPImage("image_roi_gray_half");
  if (img2 != null) {
    image(img2, mouseX, mouseY);
  }

  /*JSONObject json = reader2.getValueAsJSON("avg_color");
  if (json != null) {
    fill(json.getFloat("b"), json.getFloat("g"), json.getFloat("r"));
    stroke(255);
    strokeWeight(2);
    circle(100, 100, 50);
  }*/
}
