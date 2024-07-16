import gab.opencv.*;
import processing.video.*;
import org.opencv.imgproc.Moments;
import org.opencv.imgproc.Imgproc;
import org.opencv.core.Rect;
import org.opencv.core.Point;
import org.opencv.core.Mat;
import org.opencv.core.Size;
import org.opencv.core.CvType;
import org.opencv.core.MatOfPoint2f;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Map.Entry;
import java.util.AbstractMap.SimpleEntry;

TopCamera cam;

void setup() {
  size(200, 200);
  cam = new TopCamera(this, false);
}

void draw() {
  background(0);
  
  cam.run();
  
  
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
