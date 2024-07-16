float[][] backgroundPixels = null;
ArrayList<Blob> blobs = new ArrayList<Blob>();
PImage pimageDif = null;
long iterations = 0;

LinkedHashMap<String, PImage> detectBlobs(OpenCV cv, PImage frame, boolean outputDebugImages) {
  LinkedHashMap<String, PImage> output = new LinkedHashMap<>();
  if (outputDebugImages) {
    output.put("frame", frame.copy());
  }

  PImage frameProcessed;
  int blurSizeForFrame = 0;
  //int blurSizeForFrame = max(round(frame.height * 0.01), 3);
  if (blurSizeForFrame > 0) {
    cv.useColor();
    cv.loadImage(frame);
    cv.blur(blurSizeForFrame);
    frameProcessed = cv.getSnapshot();
  } else {
    frameProcessed = frame;
  }

  iterations += 1;
  float newFrameWeight = max(1 / (float) iterations, 0.0001);
  if (pimageDif == null || pimageDif.width != frame.width || pimageDif.height != frame.height) {
    pimageDif = createImage(frame.width, frame.height, RGB);
  }
  pimageDif.loadPixels();
  frameProcessed.loadPixels();
  if (backgroundPixels == null) {
    backgroundPixels = new float[3][frame.pixels.length];
    newFrameWeight = 1;
  }

  int r, g, b, dif;
  for (int p = 0; p < frame.pixels.length; p++) {
    // Get pixel channels from input frame
    r = frameProcessed.pixels[p] >> 16 & 0xFF;
    g = frameProcessed.pixels[p] >> 8 & 0xFF;
    b = frameProcessed.pixels[p] & 0xFF;

    // Update background pixel
    backgroundPixels[0][p] = backgroundPixels[0][p] * (1 - newFrameWeight) + r * newFrameWeight;
    backgroundPixels[1][p] = backgroundPixels[1][p] * (1 - newFrameWeight) + g * newFrameWeight;
    backgroundPixels[2][p] = backgroundPixels[2][p] * (1 - newFrameWeight) + b * newFrameWeight;

    // Calculate abs difference between input frame pixel and background pixel
    dif = int(max(abs(backgroundPixels[0][p] - r), abs(backgroundPixels[1][p] - g), abs(backgroundPixels[2][p] - b)));
    pimageDif.pixels[p] = 0xff000000 | (dif << 16) | (dif << 8) | dif;
  }
  pimageDif.updatePixels();
  output.put("difference", pimageDif);

  if (outputDebugImages) {
    PImage pimageBackground = createImage(frame.width, frame.height, RGB);
    pimageBackground.loadPixels();
    for (int p = 0; p < frame.pixels.length; p++) {
      pimageBackground.pixels[p] = 0xff000000 | ((int) backgroundPixels[0][p] << 16) | ((int) backgroundPixels[1][p] << 8) | (int) backgroundPixels[2][p];
    }
    pimageBackground.updatePixels();
    output.put("background", pimageBackground);
  }

  cv.useGray();
  cv.loadImage(pimageDif);
  cv.dilate(); // Reduce noise (dilate and erode to close holes)
  cv.erode(); // Reduce noise (dilate and erode to close holes)
  cv.blur(round(cv.height * 0.05)); // Apply blur
  cv.threshold(); // Apply threshold to the image using the Otsu's method
  if (outputDebugImages) {
    output.put("threshold", cv.getSnapshot());
  }

  ArrayList<Contour> allContours = cv.findContours();
  ArrayList<Contour> contours = new ArrayList<Contour>();
  for (Contour c : allContours) {
    if (min(c.getBoundingBox().width, c.getBoundingBox().height) >= cv.height * 0.06) {
      MatOfPoint2f pointsSimplified = new MatOfPoint2f();
      Imgproc.approxPolyDP(new MatOfPoint2f(c.pointMat.toArray()), pointsSimplified, cv.height * 0.004, true);
      contours.add(new Contour(this, pointsSimplified));
    }
  }

  // Set existing blobs as available to be updated
  for (Blob blob : blobs) {
    blob.setAsUpdatable();
  }
  // Match detected contours with existing blobs
  for (int c = 0; c < contours.size(); c++) {
    Rect contourBoundingRect = calculateBoundingRect(contours.get(c));
    Blob bestMatch = null;
    float maxIoU = 0;
    for (Blob blob : blobs) {
      if (!blob.updated()) {
        float iou = calculateIoU(blob.getBoundingRect(), contourBoundingRect);
        if (iou > 0.333 && iou > maxIoU) {
          maxIoU = iou;
          bestMatch = blob;
        }
      }
    }
    if (bestMatch != null) {
      bestMatch.update(contours.get(c));
    } else {
      int newBlobId = blobs.isEmpty() ? 1 : (blobs.get(blobs.size() - 1).id + 1);
      blobs.add(new Blob(this, newBlobId, contours.get(c)));
    }
  }
  // Remove blobs not updated for a while
  for (int i = blobs.size() - 1; i >= 0; i--) {
    if (blobs.get(i).dead()) {
      blobs.remove(i);
    }
  }

  // Create debug image with the blobs
  if (outputDebugImages) {
    PGraphics pg = createGraphics(cv.width, cv.height);
    pg.beginDraw();
    pg.background(255);
    pg.noStroke();
    for (Blob blob : blobs) {
      pg.fill(blob.colour, blob.getStrength() * 255);
      pg.beginShape();
      for (PVector p : blob.contour.getPoints()) {
        pg.vertex(p.x, p.y);
      }
      pg.endShape(CLOSE);
    }
    pg.noStroke();
    pg.textSize(pg.height * 0.04);
    pg.textAlign(CENTER, CENTER);
    for (Blob blob : blobs) {
      pg.fill(32, blob.getStrength() * 255);
      pg.text(blob.id + "", blob.getCentroid().x, blob.getCentroid().y);
    }
    pg.endDraw();
    output.put("blobs", pg.get());
  }

  return output;
}



static float calculateIoU(Rect rect1, Rect rect2) {
  // Calculate the intersection rectangle
  int xLeft = Math.max(rect1.x, rect2.x);
  int yTop = Math.max(rect1.y, rect2.y);
  int xRight = Math.min(rect1.x + rect1.width, rect2.x + rect2.width);
  int yBottom = Math.min(rect1.y + rect1.height, rect2.y + rect2.height);

  // Check if there is no intersection
  if (xRight < xLeft || yBottom < yTop) {
    return 0;
  }

  // Calculate the area of the intersection rectangle
  int intersectionArea = (xRight - xLeft) * (yBottom - yTop);

  // Calculate the area of both rectangles
  int rect1Area = rect1.width * rect1.height;
  int rect2Area = rect2.width * rect2.height;

  // Calculate Intersection over Union (IoU)
  float iou = intersectionArea / (float) (rect1Area + rect2Area - intersectionArea);
  return iou;
}
