import gab.opencv.*;
import processing.video.*;
import org.opencv.imgproc.Moments;
import org.opencv.imgproc.Imgproc;
import org.opencv.core.Rect;
import org.opencv.core.Point;
import org.opencv.core.Mat;
import org.opencv.core.Core;
import org.opencv.core.Size;
import org.opencv.core.CvType;
import org.opencv.core.MatOfPoint2f;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Map.Entry;
import java.util.AbstractMap.SimpleEntry;

TopCamera cam;

void setup() {
  size(800, 600);
  smooth(8);
  cam = new TopCamera(this, false);
}

void draw() {
  cam.run();
  background(220);

  if (cam.frameRGB != null) {
    image(cam.frameRGB, mouseX, mouseY, 300, 200);
  }
  if (cam.frameGray != null) {
    image(cam.frameGray, mouseX + 300, mouseY, 300, 200);
  }
  if (cam.roiRGB != null) {
    image(cam.roiRGB, mouseX, mouseY + 200, 300, 200);
  }
  if (cam.roiGray != null) {
    image(cam.roiGray, mouseX + 300, mouseY + 200, 300, 200);
  }
  if (cam.debugBg != null) {
    image(cam.debugBg, 0, 0, 400, 300);
  }
  
  textSize(40);
  textAlign(LEFT, TOP);
  fill(32);
  text(int(frameRate) + " FPS", 20, 20);


  /*background(220);
   if (!debugImages.isEmpty()) {
   int imgW = 500;
   int imgH = round(video.height * (imgW / (float) video.width));
   int numCols = min(2, debugImages.size());
   int numRows = ceil(debugImages.size() / (float) numCols);
   if (width != numCols * imgW || height != numRows * imgH) {
   surface.setSize(numCols * imgW, numRows * imgH);
   }
   int imageCounter = 0;
   for (Map.Entry<String, PImage> entry : debugImages.entrySet()) {
   PImage img = entry.getValue();
   //String imgTitle = entry.getKey();
   image(img, (imageCounter % numCols) * imgW, (imageCounter / numCols) * imgH, imgW, imgH);
   imageCounter += 1;
   }
   }*/
}
