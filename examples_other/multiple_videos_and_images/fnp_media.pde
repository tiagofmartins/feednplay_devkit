abstract class FnpMedia {
  PApplet p5;
  ContentArea bounds;
  String path;
  boolean loaded = false;
  long timeFirstDisplayed = -1;
  
  FnpMedia(PApplet p5, ContentArea bounds, String path) {
    this.p5 = p5;
    this.bounds = bounds;
    this.path = path;
  }

  abstract void loadFromDisk();

  void display() {
    if (timeFirstDisplayed == -1) {
      timeFirstDisplayed = millis();
    }
  }
  
  boolean ready() {
    return true;
  }
  
  float getMillisPlaying() {
    return timeFirstDisplayed != -1 ? (millis() - timeFirstDisplayed) / 1000f : 0;
  }
}

class FnpVid extends FnpMedia {
  Movie video;
  boolean loop;

  FnpVid(PApplet p5, ContentArea bounds, String path, boolean loop) {
    super(p5, bounds, path);
    this.loop = loop;
  }

  void loadFromDisk() {
    video = new Movie(p5, path);
    if (loop) {
      video.loop();
    } else {
      video.play();
    }
    video.volume(0);
  }

  void display() {
    super.display();
    if (!loaded) {
      if (video != null && video.width > 0 && video.height > 0) {
        bounds.setContentDim(video.width, video.height);
        loaded = true;
      } else {
        return;
      }
    }
    p5.image(video, bounds.getContentX(), bounds.getContentY(), bounds.getContentW(), bounds.getContentH());

    if (path.equals("diapositivo2.mp4")) {
      println(video.duration() + "  " + video.time());
      println(video.sourceFrameRate);
    }

    // Workaround to loop the video
    // https://github.com/processing/processing-video/issues/182
    if (loop && finished()) {
      video.jump(0);
    }
  }

  boolean finished() {
    return loaded && video.duration() - video.time() < 0.05;
  }

  void setLoop(boolean loop) {
    this.loop = loop;
  }
}

class FnpImg extends FnpMedia {
  PImage image = null;
  boolean drawOnlyOnce = false;
  boolean drawn = false;

  FnpImg(PApplet p5, ContentArea bounds, String path) {
    super(p5, bounds, path);
  }

  FnpImg(PApplet p5, ContentArea bounds, String path, boolean drawOnlyOnce) {
    super(p5, bounds, path);
    this.drawOnlyOnce = drawOnlyOnce;
  }

  void loadFromDisk() {
    image = requestImage(path);
  }

  void display() {
    super.display();
    if (!loaded) {
      if (image != null && image.width > 0 && image.height > 0) {
        bounds.setContentDim(image.width, image.height);
        loaded = true;
      } else {
        return;
      }
    }
    if (drawOnlyOnce) {
      if (drawn) {
        return;
      } else {
        drawn = true;
      }
    }
    p5.image(image, bounds.getContentX(), bounds.getContentY(), bounds.getContentW(), bounds.getContentH());
  }
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

class ContentArea {

  private Rect boundsBase;
  private Rect boundsContent = null;
  private float contentW = -1;
  private float contentH = -1;
  private float marginHor = 0;
  private float marginVer = 0;
  private Alignment alignHor = Alignment.CENTER;
  private Alignment alignVer = Alignment.CENTER;
  private boolean allowEnlargement = true;
  
  ContentArea(Rect boundsBase) {
    this(boundsBase, 0, 0);
  }
  
  ContentArea(Rect boundsBase, float margin) {
    this(boundsBase, margin, margin);
  }
  
  ContentArea(Rect boundsBase, float marginHor, float marginVer) {
    this.boundsBase = new Rect(boundsBase);
    contentW = boundsBase.w;
    contentH = boundsBase.h;
    setMargin(marginHor, marginVer);
  }

  private void calculateContentBounds() {
    float marginHorReal = marginHor >= 1 ? marginHor : marginHor * boundsBase.w;
    float marginVerReal = marginVer >= 1 ? marginVer : marginVer * boundsBase.h;
    assert marginHorReal >= 0;
    assert marginVerReal >= 0;
    assert marginHorReal <= boundsBase.w * 0.45;
    assert marginVerReal <= boundsBase.h * 0.45;
    
    float contentMaxW = boundsBase.w - marginHorReal * 2;
    float contentMaxH = boundsBase.h - marginVerReal * 2;
    float[] contentDim;
    if (allowEnlargement == false && contentMaxW > contentW && contentMaxH > contentH) {
      contentDim = new float[]{contentW, contentH};
    } else {
      contentDim = resizeToFitInside(contentW, contentH, contentMaxW, contentMaxH);
    }
    boundsContent = new Rect(boundsBase.x + marginHorReal, boundsBase.y + marginVerReal, contentDim[0], contentDim[1]);

    if (alignHor == Alignment.RIGHT) {
      boundsContent.x = (boundsBase.x + boundsBase.w) - boundsContent.w - marginHorReal;
    } else if (alignHor == Alignment.CENTER) {
      boundsContent.x = boundsBase.x + (boundsBase.w - boundsContent.w) / 2f;
    }
    if (alignVer == Alignment.BOTTOM) {
      boundsContent.y = (boundsBase.y + boundsBase.h) - boundsContent.h - marginVerReal;
    } else if (alignVer == Alignment.CENTER) {
      boundsContent.y = boundsBase.y + (boundsBase.h - boundsContent.h) / 2f;
    }
  }

  void setContentDim(float contentW, float contentH) {
    if (this.contentW == contentW && this.contentH == contentH) {
      return;
    }
    this.contentW = contentW;
    this.contentH = contentH;
    calculateContentBounds();
  }
  
  void setMargin(float margin) {
    setMargin(margin, margin);
  }

  void setMargin(float marginHor, float marginVer) {
    this.marginHor = marginHor;
    this.marginVer = marginVer;
    calculateContentBounds();
  }
  
  void setAlignHor(Alignment alignHor) {
    assert alignVer == Alignment.LEFT || alignVer == Alignment.CENTER || alignVer == Alignment.RIGHT;
    this.alignHor = alignHor;
    calculateContentBounds();
  }

  void setAlignVer(Alignment alignVer) {
    assert alignVer == Alignment.TOP || alignVer == Alignment.CENTER || alignVer == Alignment.BOTTOM;
    this.alignVer = alignVer;
    calculateContentBounds();
  }

  void allowEnlargement(boolean allowEnlargement) {
    this.allowEnlargement = allowEnlargement;
    calculateContentBounds();
  }
  
  void preview(PGraphics pg) {
    pg.pushStyle();
    pg.noFill();
    pg.strokeWeight(1);
    pg.stroke(255, 0, 0);
    pg.rect(boundsBase.x, boundsBase.y, boundsBase.w, boundsBase.h);
    if (boundsContent != null) {
      pg.stroke(0, 255, 0);
      pg.rect(boundsContent.x, boundsContent.y, boundsContent.w, boundsContent.h);
      pg.line(boundsContent.x, boundsContent.y, boundsContent.x + boundsContent.w, boundsContent.y + boundsContent.h);
      pg.line(boundsContent.x + boundsContent.w, boundsContent.y, boundsContent.x, boundsContent.y + boundsContent.h);
    }
    pg.popStyle();
  }

  Rect getBaseBounds() {
    return boundsBase;
  }

  Rect getContentBounds() {
    return boundsContent;
  }
  
  float getContentX() {
    return boundsContent.x;
  }

  float getContentY() {
    return boundsContent.y;
  }

  float getContentW() {
    return boundsContent.w;
  }

  float getContentH() {
    return boundsContent.h;
  }
}

enum Alignment {
  LEFT, CENTER, RIGHT, TOP, BOTTOM
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

class Rect {
  
  float x, y, w, h;

  Rect(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }

  Rect(Rect r) {
    this.x = r.x;
    this.y = r.y;
    this.w = r.w;
    this.h = r.h;
  }
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

float[] resizeToFitInside(float inputW, float inputH, float maxW, float maxH) {
  float aspectRatioInput = inputW / inputH;
  float aspectRatioMax = maxW / maxH;
  float outputW, outputH;
  if (aspectRatioMax >= aspectRatioInput) {
    outputW = maxH * aspectRatioInput;
    outputH = maxH;
  } else {
    outputW = maxW;
    outputH = maxW / aspectRatioInput;
  }
  return new float[]{outputW, outputH};
}
