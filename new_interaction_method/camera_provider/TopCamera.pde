import processing.video.*;
import gab.opencv.*;
import org.opencv.core.Mat;
import org.opencv.core.Point;
import org.opencv.core.Size;
import org.opencv.core.Core;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.CvType;
import org.opencv.imgproc.Imgproc;
import org.opencv.core.RotatedRect;

class TopCamera extends DataSource {

  Capture camera; // https://github.com/processing/processing-video/blob/main/src/processing/video/Capture.java
  Movie video; // https://github.com/processing/processing-video/blob/main/src/processing/video/Movie.java
  OpenCV opencv = null; // https://github.com/atduskgreg/opencv-processing/tree/master/src/gab/opencv
  PImage lastFrame = null;
  PImage roi = null;

  float[][] relativeRoiCorners = {
    {0.12, 0.32},
    {0.87, 0.30},
    {0.83, 0.87},
    {0.16, 0.88}
  };

  TopCamera(PApplet parent, boolean makeUpData) {
    super(parent, makeUpData);
  }

  protected void startCapture() {
    if (makeUpData) {
      video = new Movie(parent, "top-camera-sample.mp4");
      video.loop();
      video.play();
      video.volume(0);
    } else {
      camera = new Capture(parent, 1920, 1080, "FaceTime HD Camera", 30);
      camera.start();
    }
  }

  protected void stopCapture() {
    if (makeUpData) {
      video.stop();
      video.dispose();
      video = null;
    } else {
      camera.stop();
      camera.dispose();
      camera = null;
    }
    opencv = null;
  }

  protected boolean isCapturing() {
    if (makeUpData) {
      return video != null && video.isPlaying();
    } else {
      return camera != null && camera.isCapturing();
    }
  }

  public void run() {
    super.run();
    PImage newFrame = null;
    if (makeUpData) {
      if (video != null && video.available()) {
        video.read();
        newFrame = video.get();
      }
    } else {
      if (camera != null && camera.available()) {
        camera.read();
        newFrame = camera.get();
      }
    }
    if (newFrame == null) {
      return;
    }

    if (opencv == null) {
      opencv = new OpenCV(parent, newFrame.width, newFrame.height);
    }

    opencv.useColor();
    opencv.loadImage(newFrame);
    opencv.flip(OpenCV.BOTH); // Rotate 180 degrees

    //opencv.gray();
    //opencv.invert();
    //opencv.dilate();
    //opencv.erode();
    //opencv.blur(6);

    Mat matRoi = warpPerspective(opencv.getColor(), relativeRoiCorners);

    lastFrame = createImage(matRoi.cols(), matRoi.rows(), ARGB);
    opencv.toPImage(matRoi, lastFrame);

    //lastFrame = opencv.getSnapshot();

    //lastFrame = newFrame;

    /*Point[] canonicalPoints = new Point[4];
     canonicalPoints[0] = new Point(0.1 * newFrame.width, 0.1 * newFrame.height);
     canonicalPoints[1] = new Point();
     canonicalPoints[2] = new Point(0, h);
     canonicalPoints[3] = new Point(w, h);
     
     roi*/

    //float[][] pointROI = new float[][]{{0.12, 0.32], {0.87, 0.30}, {0.83, 0.87}, {0.16, 0.88}};
  }

  PImage getLastFrame() {
    updateTimeLastUse();
    return lastFrame;
  }

  PImage getROI() {
    updateTimeLastUse();
    return roi;
  }
}

Mat warpPerspective(Mat m, float[][] relCorners) {

  // Calculate absolute coordinates from relative ones
  Point[] absCorners = new Point[relCorners.length];
  for (int i = 0; i < relCorners.length; i++) {
    absCorners[i] = new Point(relCorners[i][0] * m.cols(), relCorners[i][1] * m.rows());
  }

  //RotatedRect rotatedRect = Imgproc.minAreaRect(new MatOfPoint2f(absCorners));
  //int roiW = (int) rotatedRect.size.height;
  //int roiH = (int) rotatedRect.size.width;
  int roiW = (int) Math.min(Math.abs(absCorners[0].x - absCorners[1].x), Math.abs(absCorners[2].x - absCorners[3].x));
  int roiH = (int) Math.min(Math.abs(absCorners[0].y - absCorners[3].y), Math.abs(absCorners[1].y - absCorners[2].y));

  Point[] canonicalPoints = new Point[]{new Point(roiW, 0), new Point(0, 0), new Point(0, roiH), new Point(roiW, roiH)};

  MatOfPoint2f canonicalMarker = new MatOfPoint2f(canonicalPoints);
  MatOfPoint2f marker = new MatOfPoint2f(absCorners);
  Mat transform = Imgproc.getPerspectiveTransform(marker, canonicalMarker);

  Mat unWarpedMarker = new Mat(roiW, roiH, CvType.CV_8UC1);
  Imgproc.warpPerspective(m, unWarpedMarker, transform, new Size(roiW, roiH));

  return unWarpedMarker;
}
