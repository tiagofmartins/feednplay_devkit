class TopCamera {

  PApplet parent; // https://github.com/ruby-processing/processing-core/blob/master/src/main/java/processing/core/PApplet.java
  Capture camera; // https://github.com/processing/processing-video/blob/main/src/processing/video/Capture.java
  Movie video; // https://github.com/processing/processing-video/blob/main/src/processing/video/Movie.java
  OpenCV opencv; // https://github.com/atduskgreg/opencv-processing/tree/master/src/gab/opencv
  boolean useLiveData;
  TopicsManager topics = new TopicsManager();

  TopCamera(PApplet parent, boolean useLiveData) {
    this.parent = parent;
    this.useLiveData = useLiveData;

    topics.setRecentUseLimit(10000);
    topics.setTopic("IMG_CAMTOP_FRAME_RGB", PImage.class);
    topics.setTopic("IMG_CAMTOP_FRAME_GRAY", PImage.class);
    topics.setTopic("IMG_CAMTOP_FRAME_DIF", PImage.class);
    topics.setTopic("IMG_CAMTOP_ROI_RGB", PImage.class);
    topics.setTopic("IMG_CAMTOP_ROI_GRAY", PImage.class);
    topics.setTopic("IMG_CAMTOP_ROI_DIF", PImage.class);
    topics.setTopic("JSON_CAMTOP_ROI_BLOBS", JSONObject.class);
    
    // JSON_CAMTOP_ROI_BLOBS -> IMG_CAMTOP_ROI_DIF
    // IMG_CAMTOP_ROI_DIF -> IMG_CAMTOP_ROI_RGB
    // IMG_CAMTOP_ROI_RGB -> IMG_CAMTOP_FRAME_RGB
    // IMG_CAMTOP_FRAME_GREY -> IMG_CAMTOP_FRAME_RGB
  }

  void start() {
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

  void stop() {
    if (useLiveData) {
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

  boolean isStopped() {
    if (useLiveData) {
      return camera == null || !camera.isCapturing();
    } else {
      return video == null || !video.isPlaying();
    }
  }

  void run() {
    // Control start and stop
    boolean usedRecently = topics.anyTopicUsedRecently();
    boolean stopped = isStopped();
    if (usedRecently && stopped) {
      start();
    } else if (!usedRecently && !stopped) {
      stop();
    }
    if (stopped) {
      return;
    }

    // Get new frame
    PImage frame = null;
    if (useLiveData) {
      if (camera != null && camera.available()) {
        camera.read();
        frame = camera.get();
      }
    } else {
      if (camera != null && video.available()) {
        video.read();
        frame = video.get();
      }
    }
    if (frame == null || frame.width == 0 || frame.height == 0) {
      return;
    }

    // Prepare OpenCV object
    if (opencv == null || opencv.width != frame.width || opencv.height != frame.height) {
      opencv = new OpenCV(parent, frame.width, frame.height);
    }

    // Load frame into OpenCV
    opencv.useColor();
    opencv.loadImage(frame);

    // Rotate image 180 degrees (displays on top)
    opencv.flip(OpenCV.BOTH);

    // Extract region of interest and adjust perspective
    Point[] roiCorners = new Point[]{
      new Point(0.12 * opencv.width, 0.32 * opencv.height), // top left
      new Point(0.87 * opencv.width, 0.30 * opencv.height), // top right
      new Point(0.83 * opencv.width, 0.87 * opencv.height), // bottom right
      new Point(0.16 * opencv.width, 0.88 * opencv.height)  // bottom left
    };
    int roiW = (int) Math.min(Math.abs(roiCorners[0].x - roiCorners[1].x), Math.abs(roiCorners[2].x - roiCorners[3].x));
    int roiH = (int) Math.min(Math.abs(roiCorners[0].y - roiCorners[3].y), Math.abs(roiCorners[1].y - roiCorners[2].y));
    Point[] canonicalPoints = new Point[]{new Point(roiW, 0), new Point(0, 0), new Point(0, roiH), new Point(roiW, roiH)};
    MatOfPoint2f canonicalMarker = new MatOfPoint2f(canonicalPoints);
    MatOfPoint2f marker = new MatOfPoint2f(roiCorners);
    Mat transform = Imgproc.getPerspectiveTransform(marker, canonicalMarker);
    Mat unWarpedMarker = new Mat(roiW, roiH, CvType.CV_8UC1);
    Imgproc.warpPerspective(opencv.getColor(), unWarpedMarker, transform, new Size(roiW, roiH));
    Mat matRoi = unWarpedMarker;
    PImage pimageRoi = createImage(matRoi.cols(), matRoi.rows(), ARGB);
    opencv.toPImage(matRoi, pimageRoi);

    if (topics.usedRecently()) {
      LinkedHashMap<String, PImage> debugImages = detectBlobs(opencv, pimageRoi, true);
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
