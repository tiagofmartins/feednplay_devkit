FnpDataReader reader;
PImage frame = null;
PImage[] facesImages = null;

void settings() {
  fnpSize(999, 666, P2D);
  smooth(8);
}

void setup() {
  reader = new FnpDataReader("cam1_frame_grayscale_full", "cam1_face_detections");
  //reader2.setReadingsPerSecond(5);
}

void draw() {
  PImage newFrame = reader.getValueAsPImage("cam1_frame_grayscale_full");
  if (newFrame != null) {
    frame = newFrame.copy();
  }
  
  JSONObject facesData = reader.getValueAsJSON("cam1_face_detections");
  if (facesData != null && frame != null) {
    JSONArray facesBounds = facesData.getJSONArray("detections");
    facesImages = new PImage[facesBounds.size()];
    for (int i = 0; i < facesBounds.size(); i++) {
      JSONObject detection = facesBounds.getJSONObject(i);
      int faceX = int(detection.getFloat("x") * frame.width);
      int faceY = int(detection.getFloat("y") * frame.height);
      int faceW = int(detection.getFloat("w") * frame.width);
      int faceH = int(detection.getFloat("h") * frame.height);
      facesImages[i] = frame.get(faceX, faceY, faceW, faceH);
    }
  } else {
    facesImages = null;
  }
  
  background(255);
  scale(0.4);
  if (frame != null && facesImages != null) {
    image(frame, 0, 0);
    pushMatrix();
    translate(0, frame.height + 10);
    for (PImage faceImage : facesImages) {
      image(faceImage, 0, 0);
      translate(faceImage.width + 10, 0);
    }
    popMatrix();
  }
}
