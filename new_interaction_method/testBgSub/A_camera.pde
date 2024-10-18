/*
OpenCV Java documentation:
 https://docs.opencv.org/4.x/javadoc/index.html
 
 opencv-processing source code:
 https://github.com/atduskgreg/opencv-processing/tree/master/src/gab/opencv
 
 Other source code:
 https://github.com/ruby-processing/processing-core/blob/master/src/main/java/processing/core/PApplet.java
 https://github.com/processing/processing-video/blob/main/src/processing/video/Capture.java
 https://github.com/processing/processing-video/blob/main/src/processing/video/Movie.java
 */

class TopCamera {

  PApplet parent;
  Capture camera;
  Movie video; //
  OpenCV opencv; //
  boolean useLiveData;
  //TopicsManager topics = new TopicsManager();

  // Flags to calculate variables
  public boolean calculateImageRGB = true;
  public boolean calculateImageGray = true;
  public boolean calculateRoiRGB = true;
  public boolean calculateRoiGray = true;
  public boolean calculateRoiBlobs = true;

  // Variables
  public PImage frameRGB = null;
  public PImage frameGray = null;
  public PImage roiRGB = null;
  public PImage roiGray = null;
  public JSONObject roiBlobs = null;

  // Debug
  public PImage debugFrameWithRoiLimits = null;
  public PImage debugBg = null;

  // Inner variables
  private OpenCV cvFrame = null;
  private OpenCV cvRoi = null;
  private int roiBgUpdates;
  //private float[][] roiBgPixels = null;
  private float[] roiBgPixels = null;

  TopCamera(PApplet parent, boolean useLiveData) {
    this.parent = parent;
    this.useLiveData = useLiveData;

    /*topics.setRecentUseLimit(10000);
     topics.setTopic("IMG_CAMTOP_FRAME_RGB", PImage.class);
     topics.setTopic("IMG_CAMTOP_FRAME_GRAY", PImage.class);
     topics.setTopic("IMG_CAMTOP_FRAME_DIF", PImage.class);
     topics.setTopic("IMG_CAMTOP_ROI_RGB", PImage.class);
     topics.setTopic("IMG_CAMTOP_ROI_GRAY", PImage.class);
     topics.setTopic("IMG_CAMTOP_ROI_DIF", PImage.class);
     topics.setTopic("JSON_CAMTOP_ROI_BLOBS", JSONObject.class);*/

    // JSON_CAMTOP_ROI_BLOBS -> IMG_CAMTOP_ROI_DIF
    // IMG_CAMTOP_ROI_DIF -> IMG_CAMTOP_ROI_RGB
    // IMG_CAMTOP_ROI_RGB -> IMG_CAMTOP_FRAME_RGB
    // IMG_CAMTOP_FRAME_GREY -> IMG_CAMTOP_FRAME_RGB
  }

  void startCapturing() {
    if (useLiveData) {
      camera = new Capture(parent, 1920, 1080, "FaceTime HD Camera", 30);
      camera.start();
    } else {
      video = new Movie(parent, "top-camera-sample.mp4");
      video.loop();
      video.play();
      video.volume(0);
    }
  }

  void stopCapturing() {
    if (useLiveData) {
      camera.stop();
      camera.dispose();
      camera = null;
    } else {
      video.stop();
      video.dispose();
      video = null;
    }
    cvFrame = null;
    cvRoi = null;
    frameRGB = null;
    frameGray = null;
    roiRGB = null;
    roiGray = null;
    roiBlobs = null;
  }

  boolean isCapturing() {
    if (useLiveData) {
      return camera != null && camera.isCapturing();
    } else {
      return video != null && video.isPlaying();
    }
  }

  void run() {

    // ****************************************************************************************************
    // START OR STOP CAPTURING

    if (calculateImageRGB || calculateImageGray || calculateRoiRGB || calculateRoiGray || calculateRoiBlobs) {
      if (isCapturing() == false) {
        startCapturing();
      }
    } else {
      if (isCapturing() == true) {
        stopCapturing();
      }
      return;
    }

    // ****************************************************************************************************
    // READ CAMERA OR VIDEO FRAME

    PImage frame = null;
    if (useLiveData) {
      if (camera.available()) {
        camera.read();
        frame = camera.get();
      }
    } else {
      if (video.available()) {
        video.read();
        frame = video.get();
      }
    }
    if (frame == null || frame.width == 0 || frame.height == 0) {
      return;
    }

    // ****************************************************************************************************
    // CALCULATE FRAME IMAGE

    if (cvFrame == null || cvFrame.width != frame.width || cvFrame.height != frame.height) {
      cvFrame = new OpenCV(parent, frame.width, frame.height);
    }
    cvFrame.loadImage(frame);
    cvFrame.flip(OpenCV.BOTH);

    // ****************************************************************************************************
    // UPDATE VARIABLE WITH FRAME IMAGE IN RGB

    if (calculateImageRGB) {
      cvFrame.useColor();
      frameRGB = cvFrame.getSnapshot();
    } else {
      frameRGB = null;
    }

    // ****************************************************************************************************
    // UPDATE VARIABLE WITH FRAME IMAGE IN GRAYSCALE

    if (calculateImageGray) {
      cvFrame.gray();
      frameGray = cvFrame.getSnapshot();
    } else {
      frameGray = null;
    }

    // ****************************************************************************************************
    // CALCULATE ROI IMAGE

    if (calculateRoiRGB || calculateRoiGray || calculateRoiBlobs) {
      // Set source corners
      Point[] srcCorners = new Point[]{
        new Point(0.12 * cvFrame.width, 0.32 * cvFrame.height),
        new Point(0.87 * cvFrame.width, 0.30 * cvFrame.height),
        new Point(0.83 * cvFrame.width, 0.87 * cvFrame.height),
        new Point(0.16 * cvFrame.width, 0.88 * cvFrame.height)
      };

      // Create debug PImage with the ROI limits drawn on the frame
      /*PGraphics pg = parent.createGraphics(cvFrame.width, cvFrame.height);
       pg.beginDraw();
       cvFrame.useColor();
       pg.background(cvFrame.getSnapshot());
       pg.noFill();
       pg.stroke(255);
       pg.beginShape();
       for (Point p : srcCorners) {
       pg.vertex((float) p.x, (float) p.y);
       }
       pg.endShape(PConstants.CLOSE);
       pg.endDraw();
       debugFrameWithRoiLimits = pg.get();*/

      // Set destination corners
      int dstWidth = (int) Math.min(Math.abs(srcCorners[0].x - srcCorners[1].x), Math.abs(srcCorners[2].x - srcCorners[3].x));
      int dstHeight = (int) Math.min(Math.abs(srcCorners[0].y - srcCorners[3].y), Math.abs(srcCorners[1].y - srcCorners[2].y));
      Point[] dstCorners = new Point[]{
        new Point(0, 0),
        new Point(dstWidth, 0),
        new Point(dstWidth, dstHeight),
        new Point(0, dstHeight)
      };

      // Unwarp image
      Mat transform = Imgproc.getPerspectiveTransform(new MatOfPoint2f(srcCorners), new MatOfPoint2f(dstCorners));
      Mat matUnwarped = new Mat(dstWidth, dstHeight, CvType.CV_8UC1);
      Imgproc.warpPerspective(cvFrame.getColor(), matUnwarped, transform, new Size(dstWidth, dstHeight));

      // Load unwarped mat into OpenCV.
      // This OpenCV instance is a different one because it has a smaller size.
      if (cvRoi == null || cvRoi.width != matUnwarped.cols() || cvRoi.height != matUnwarped.rows()) {
        cvRoi = new OpenCV(parent, matUnwarped.cols(), matUnwarped.rows());
      }
      cvRoi.setColor(matUnwarped);
    }

    // ****************************************************************************************************
    // UPDATE VARIABLE WITH ROI IMAGE IN RGB

    if (calculateRoiRGB) {
      roiRGB = cvRoi.getSnapshot();
    } else {
      roiRGB = null;
    }

    // ****************************************************************************************************
    // UPDATE VARIABLE WITH ROI IMAGE IN GRAYSCALE

    if (calculateRoiGray) {
      cvRoi.gray();
      roiGray = cvRoi.getSnapshot();
    } else {
      roiGray = null;
    }

    // ****************************************************************************************************
    // UPDATE BLOBS

    if (calculateRoiBlobs) {
      // Remove noise by applying blur
      cvRoi.blur(3);
      //cvRoi.blur(max(round(cvRoi.height * 0.01), 3));

      //cvRoi.useColor();
      //frameProcessed = cvRoi.getSnapshot();

      // Create arrays to store background pixels
      //if (roiBgPixels == null) {
      //roiBgPixels = new float[frame.pixels.length];
      //roiBgUpdates = 0;
      //}

      

      // Convert image to RGB to calculate the image difference using only 3 channels (ignore alpha channel)
      Mat matRGB = new Mat();
      Imgproc.cvtColor(cvRoi.getColor(), matRGB, Imgproc.COLOR_BGRA2BGR);

      // Create array with channels data (array length = width * height * channels)
      int rows = matRGB.rows();
      int cols = matRGB.cols();
      int channels = matRGB.channels();
      byte[] pixelsDataInBytes = new byte[cols * rows * channels];
      matRGB.get(0, 0, pixelsDataInBytes);

      // Calculate the impact that the new frame will have in updating the background.
      // Over time, the update weight reduces (but not below a given limit).
      roiBgUpdates += 1;
      float weightNewPixels = max(1 / (float) roiBgUpdates, 0.0001);
      float weightOldPixels = 1 - weightNewPixels;

      // Update background pixels
      if (roiBgPixels == null || roiBgPixels.length != pixelsDataInBytes.length) {
        roiBgPixels = new float[pixelsDataInBytes.length];
      }
      for (int i = 0; i < roiBgPixels.length; i++) {
        roiBgPixels[i] = roiBgPixels[i] * weightOldPixels + (pixelsDataInBytes[i] & 0xFF) * weightNewPixels;
      }
      
      byte[] pixelsRoiDif = new byte[roiBgPixels.length];
      float difR, difG, difB;
      for (int i = 0; i < roiBgPixels.length; i += 3) {
        difR = abs(backgroundPixels[0][p] - r);
        pixelsRoiDif[i] = roiBgPixels[i] * weightOldPixels + (pixelsDataInBytes[i] & 0xFF) * weightNewPixels;
      }
      
      Mat matRoiBg = new Mat(matRGB.rows(), matRGB.cols(), CvType.CV_32FC3);
      matRoiBg.put(0, 0, roiBgPixels);
      matRoiBg.convertTo(matRoiBg, CvType.CV_8UC3);
      
      debugBg  = createImage(matRoiBg.cols(), matRoiBg.rows(), RGB);
      cvRoi.toPImage(matRoiBg, debugBg);

      /*Mat mat8bit = new Mat();
      m.convertTo(mat8bit, CvType.CV_8U, 1 / 255f);
      Imgproc.cvtColor(mat8bit, mat8bit, Imgproc.COLOR_GRAY2RGB);

      PImage img = createImage(mat8bit.cols(), mat8bit.rows(), RGB);
      mat8bit.get(0, 0, img.pixels);
      img.updatePixels();
      debugBg = img;*/

      /*Mat mat = new Mat(rows, cols, CvType.CV_8UC3);
       mat.put(0, 0, byteArray);
       
       int pixelIndex, channelIndex;
       for (int row = 0; row < rows; row++) {
       for (int col = 0; col < cols; col++) {
       pixelIndex = (row * cols + col) * channels;
       for (int ch = 0; ch < channels; ch++) {
       channelIndex = pixelIndex + ch;
       int channelValue = pixelsDataInBytes[pixelIndex + ch] & 0xFF;
       roiBgPixels[channelIndex] = roiBgPixels[i] * (1 - bgUpdateWeight) + (pixelsDataInBytes[i] & 0xFF) * bgUpdateWeight;
       }
       }
       }*/

      /*int r, g, b, dif;
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
       }*/
    } else {
      roiBgUpdates = 0;
      roiBgPixels = null;
      roiBlobs = null;
    }
  }
}


/*Mat warpPerspective(Mat m, float[][] relCorners) {
 
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
 }*/
