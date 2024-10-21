import processing.video.*;
import gab.opencv.*;
import org.opencv.core.Mat;
import org.opencv.core.Point;
import org.opencv.core.Size;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.CvType;
import org.opencv.imgproc.Imgproc;
import org.opencv.core.RotatedRect;

enum Topic {
  IMG_CAMTOP_RGB, IMG_CAMTOP_CROP_RGB, IMG_CAMTOP_GRAY, IMG_CAMTOP_DIFF, IMG_CAMTOP_RGB_720H
}

class InputCameraTop extends Input {

  final PVector cropTopLeft = new PVector(0.12, 0.32);
  final PVector cropTopRight = new PVector(0.87, 0.30);
  final PVector cropBottomRight = new PVector(0.83, 0.87);
  final PVector cropBottomLeft = new PVector(0.16, 0.882);

  Capture camera; // https://github.com/processing/processing-video/blob/main/src/processing/video/Capture.java
  Movie video; // https://github.com/processing/processing-video/blob/main/src/processing/video/Movie.java
  OpenCV opencv = null; // https://github.com/atduskgreg/opencv-processing/tree/master/src/gab/opencv
  PImage image = null;
  PImage imageCropped = null;



  InputCameraTop(PApplet parent, boolean useRealData) {
    super(parent, useRealData, 30000, 10000);


    addTopic("IMG_RGB", PImage.class);
    addTopic("IMG_CROP", PImage.class);
  }

  void startCapture() {
    println("Starting capture...");
    if (useRealData) {
      //printArray(Capture.list());
      camera = new Capture(parent, 1920, 1080, "Studio Display Camera", 30); // FaceTime HD Camera
      camera.start();
    } else {
      video = new Movie(parent, "top-camera-sample.mp4");
      video.loop();
      video.play();
      video.volume(0);
    }
  }

  void stopCapture() {
    println("Stopping capture...");
    if (useRealData) {
      camera.stop();
      camera.dispose();
      camera = null;
    } else {
      video.stop();
      video.dispose();
      video = null;
    }
    opencv = null;
  }

  boolean isCapturing() {
    if (useRealData) {
      return camera != null && camera.isCapturing();
    } else {
      return video != null && video.isPlaying();
    }
  }

  void update() {
    super.update();

    if (!isCapturing()) {
      return;
    }

    PImage newFrame = null;
    if (useRealData) {
      if (camera != null && camera.available()) {
        camera.read();
        newFrame = camera;
      }
    } else {
      if (video != null && video.available()) {
        video.read();
        newFrame = video;
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

    image = opencv.getSnapshot();

    //opencv.gray();
    //opencv.invert();
    //opencv.dilate();
    //opencv.erode();
    //opencv.blur(6);

    Mat matCrop = warpPerspective(opencv.getColor(), cropTopLeft, cropTopRight, cropBottomRight, cropBottomLeft);

    if (imageCropped == null) {
      imageCropped = createImage(matCrop.cols(), matCrop.rows(), ARGB);
    }
    opencv.toPImage(matCrop, imageCropped);
  }

  <Any>Any getTopic(String topic) {
    assert(topicsAndClasses.containsKey(topic));
    topicsAndTimes.put(topic, System.currentTimeMillis());
    Object output = null;
    if (topic.equals("IMG_RGB")) {
      output = image;
    } else if (topic.equals("IMG_CROP")) {
      output = imageCropped;
    }
    return output == null ? null : (Any) output.getClass().cast(output);

    /*assert(topicsAndClasses.containsKey(topic));
     topicsAndTimes.put(topic, System.currentTimeMillis());
     Object output = 2;
     if (topic.equals("IMG_RGB")) {
     output = image;
     } else if (topic.equals("IMG_CROP")) {
     output = imageCropped;
     } else {
     assert false;
     }
     return output == null ? null : (Any) topicsAndClasses.get(topic).cast(output);*/
  }
}


Mat warpPerspective(Mat m, PVector tl, PVector tr, PVector br, PVector bl) {
  Point[] srcCorners = new Point[]{
    new Point(tl.x * m.cols(), tl.y * m.rows()), new Point(tr.x * m.cols(), tr.y * m.rows()),
    new Point(br.x * m.cols(), br.y * m.rows()), new Point(bl.x * m.cols(), bl.y * m.rows()),
  };

  //RotatedRect minRect = Imgproc.minAreaRect(new MatOfPoint2f(srcCorners));
  //int dstWidth = (int) minRect.size.height;
  //int dstHeight = (int) minRect.size.width;
  int dstWidth = (int) Math.min(Math.abs(srcCorners[0].x - srcCorners[1].x), Math.abs(srcCorners[2].x - srcCorners[3].x));
  int dstHeight = (int) Math.min(Math.abs(srcCorners[0].y - srcCorners[3].y), Math.abs(srcCorners[1].y - srcCorners[2].y));
  Point[] dstCorners = new Point[]{
    new Point(dstWidth, 0), new Point(0, 0),
    new Point(0, dstHeight), new Point(dstWidth, dstHeight)
  };

  MatOfPoint2f srcMarker = new MatOfPoint2f(srcCorners);
  MatOfPoint2f dstMarker = new MatOfPoint2f(dstCorners);
  Mat transform = Imgproc.getPerspectiveTransform(srcMarker, dstMarker);
  Mat unWarpedMarker = new Mat(dstWidth, dstHeight, CvType.CV_8UC1);
  Imgproc.warpPerspective(m, unWarpedMarker, transform, new Size(dstWidth, dstHeight));

  return unWarpedMarker;
}


/**
 * Function to convert Mat to PImage
 */
PImage MatToPImage(Mat mat) {
  PImage img = createImage(mat.width(), mat.height(), RGB);
  int numPixels = mat.width() * mat.height();
  byte[] data = new byte[numPixels * 3];
  mat.get(0, 0, data);
  img.loadPixels();
  for (int i = 0; i < numPixels; i++) {
    int r = data[i * 3] & 0xFF;
    int g = data[i * 3 + 1] & 0xFF;
    int b = data[i * 3 + 2] & 0xFF;
    img.pixels[i] = color(r, g, b);
  }
  img.updatePixels();
  return img;
}
