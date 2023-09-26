/*
 ┌──────────────────────────────────────────────────────────┐
 │ FeedNPlay                                     2023.09.26 │
 │ Code to facilitate the exhibition of videos and images.  │
 │ Please DO NOT change any of the code below.              │
 │ If you have any suggestions or special requests          │
 │ please contact the FeedNPlay team. We will be happy      │
 │ to improve the system for you and all users.             │
 └──────────────────────────────────────────────────────────┘*/

import java.util.Arrays;
import java.awt.geom.Rectangle2D;
import java.awt.geom.Rectangle2D.Float;
import processing.video.*;

abstract class FnpMedia {

  protected PApplet p5;
  protected ContentArea bounds;
  protected String path;
  private int millisFadeIn = 1000;
  private int millisFadeOut = 1000;

  FnpMedia(PApplet p5, ContentArea bounds, String path) {
    this.p5 = p5;
    this.bounds = bounds;
    this.path = path;
  }

  void setPath(String path) {
    dispose();
    this.path = path;
  }

  void setBounds(ContentArea bounds) {
    this.bounds = bounds;
    if (isLoaded()) {
      bounds.setContentDim(getOriginalWidth(), getOriginalHeight());
    }
  }

  void setFadeInOutDuration(int millisFadeIn, int millisFadeOut) {
    assert millisFadeIn == 0 || millisFadeIn >= 100;
    assert millisFadeOut == 0 || millisFadeOut >= 100;
    this.millisFadeIn = millisFadeIn;
    this.millisFadeOut = millisFadeOut;
  }

  abstract void load();

  abstract void display();

  void dispose() {
    path = null;
    bounds.setContentDim(0, 0);
  }

  float getOpacityToFadeInOut(float currMillis, float maxMillis) {
    float opacity = 255;
    if (millisFadeIn > 0) {
      assert millisFadeIn < maxMillis / 2f;
      if (currMillis <= millisFadeIn) {
        opacity = map(currMillis, 0, millisFadeIn, 0, 255);
      }
    }
    if (millisFadeOut > 0) {
      assert millisFadeOut < maxMillis / 2f;
      float millisUntilEnd = maxMillis - currMillis;
      if (millisUntilEnd <= millisFadeOut) {
        opacity = map(millisUntilEnd, millisFadeOut, 0, 255, 0);
      }
    }
    return opacity;
  }

  abstract boolean isLoaded();

  abstract boolean finished();

  abstract float getOriginalWidth();

  abstract float getOriginalHeight();
}

// ================================================================================

class FnpImg extends FnpMedia {

  private PImage image = null;
  private int timeWhenLoaded = 0;
  private int millisDuration;

  FnpImg(PApplet p5, ContentArea bounds, String path, int millisDuration) {
    super(p5, bounds, path);
    this.millisDuration = millisDuration;
  }

  FnpImg(PApplet p5, ContentArea bounds, String path) {
    this(p5, bounds, path, 0);
  }

  void load() {
    image = requestImage(path);
  }

  void display() {
    if (bounds.getContentBounds() == null) {
      if (isLoaded()) {
        bounds.setContentDim(image.width, image.height);
        timeWhenLoaded = millis();
      } else {
        return;
      }
    }
    p5.pushStyle();
    if (millisDuration > 0) {
      float opacity = getOpacityToFadeInOut(millis() - timeWhenLoaded, millisDuration);
      if (opacity < 255) {
        p5.tint(255, opacity);
      }
    }
    p5.image(image, bounds.getContentX(), bounds.getContentY(), bounds.getContentW(), bounds.getContentH());
    p5.popStyle();
  }

  void dispose() {
    super.dispose();
    image = null;
    timeWhenLoaded = 0;
  }

  boolean isLoaded() {
    return image != null && image.width > 0 && image.height > 0;
  }

  boolean finished() {
    return timeWhenLoaded > 0 && millisDuration > 0 && (millis() - timeWhenLoaded) >= millisDuration;
  }

  float getOriginalWidth() {
    return image.width;
  }

  float getOriginalHeight() {
    return image.height;
  }
}

// ================================================================================

class FnpVid extends FnpMedia {

  private Movie video;
  private boolean loop;
  private float volume;

  FnpVid(PApplet p5, ContentArea bounds, String path, boolean loop, float volume) {
    super(p5, bounds, path);
    this.loop = loop;
    assert volume >= 0 && volume <= 1;
    this.volume = volume;
  }

  void load() {
    video = new Movie(p5, path);
    video.volume(volume);
    if (loop) {
      video.loop();
    } else {
      video.play();
    }
  }

  void restart() {
    video.jump(0);
  }

  void display() {
    if (bounds.getContentBounds() == null) {
      if (isLoaded()) {
        bounds.setContentDim(video.width, video.height);
      } else {
        return;
      }
    }

    p5.pushStyle();
    float opacity = getOpacityToFadeInOut(video.time() * 1000, video.duration() * 1000);
    if (opacity < 255) {
      p5.tint(255, opacity);
    }
    p5.image(video, bounds.getContentX(), bounds.getContentY(), bounds.getContentW(), bounds.getContentH());
    p5.popStyle();

    // Workaround to loop the video
    // https://github.com/processing/processing-video/issues/182
    if (loop && finished()) {
      restart();
    }
  }

  void dispose() {
    super.dispose();
    video.dispose();
    video = null;
  }

  boolean isLoaded() {
    return video != null && video.width > 0 && video.height > 0;
  }

  boolean finished() {
    return video.duration() - video.time() < 0.05;
  }

  float getOriginalWidth() {
    return video.width;
  }

  float getOriginalHeight() {
    return video.height;
  }
}

void movieEvent(Movie m) {
  m.read();
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
  private float contentW = 0;
  private float contentH = 0;
  private float marginHor;
  private float marginVer;
  private Alignment alignHor = Alignment.CENTER;
  private Alignment alignVer = Alignment.CENTER;
  private boolean allowEnlargement = true;

  ContentArea(Rect boundsBase, float marginHor, float marginVer) {
    this.boundsBase = new Rect(boundsBase);
    setMargin(marginHor, marginVer);
  }

  ContentArea(Rect boundsBase, float margin) {
    this(boundsBase, margin, margin);
  }

  ContentArea(Rect boundsBase) {
    this(boundsBase, 0, 0);
  }

  void setContentDim(float contentW, float contentH) {
    this.contentW = contentW;
    this.contentH = contentH;
    calculateContentBounds();
  }

  void setMargin(float marginHor, float marginVer) {
    this.marginHor = marginHor;
    this.marginVer = marginVer;
    calculateContentBounds();
  }

  void setMargin(float margin) {
    setMargin(margin, margin);
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

  private void calculateContentBounds() {
    if (contentW <= 0 || contentH <= 0) {
      boundsContent = null;
      return;
    }

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

  void preview(PGraphics pg) {
    pg.pushStyle();
    pg.noFill();
    pg.stroke(255, 0, 0);
    pg.strokeWeight(1);
    pg.rect(boundsBase.x, boundsBase.y, boundsBase.w, boundsBase.h);

    float marginHorReal = marginHor >= 1 ? marginHor : marginHor * boundsBase.w;
    float marginVerReal = marginVer >= 1 ? marginVer : marginVer * boundsBase.h;
    pg.strokeWeight(0.5);
    pg.rect(boundsBase.x + marginHorReal, boundsBase.y + marginVerReal, boundsBase.w - marginHorReal * 2, boundsBase.h - marginVerReal * 2);

    if (boundsContent != null) {
      pg.strokeWeight(1);
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

  boolean overlap(Rect rect2) {
    Rectangle2D r1 = new Rectangle2D.Float(x, y, w, h);
    Rectangle2D r2 = new Rectangle2D.Float(rect2.x, rect2.y, rect2.w, rect2.h);
    Rectangle2D intersection = r1.createIntersection(r2);
    if (intersection.getWidth() > 0 && intersection.getHeight() > 0) {
      return true;
    } else {
      return false;
    }

    /*if (x == rect2.x || y == rect2.y || rect2.x + rect2.w == x + w || y + h == rect2.x + rect2.h) {
     return false;
     }
     if (x > rect2.x + rect2.w || x + w > rect2.x) {
     return false;
     }
     if (rect2.y > y + h || rect2.x + rect2.h > y) {
     return false;
     }
     return true;*/
  }

  /*static boolean overlap(Point l1, Point r1, Point l2, Point r2) {
   // https://www.geeksforgeeks.org/find-two-rectangles-overlap/
   // if rectangle has area 0, no overlap
   if (l1.x == r1.x || l1.y == r1.y || r2.x == l2.x || l2.y == r2.y)
   return false;
   
   // If one rectangle is on left side of other
   if (l1.x > r2.x || l2.x > r1.x) {
   return false;
   }
   
   // If one rectangle is above other
   if (r1.y > l2.y || r2.y > l1.y) {
   return false;
   }
   
   return true;
   }*/
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

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
///\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

File[] getFiles(File dir, String extension) {
  return getFiles(dir, new String[]{extension});
}

File[] getFiles(File dir, String[] extensions) {
  assert dir.isDirectory();
  ArrayList<File> targetFiles = new ArrayList<File>();
  File[] allFiles = dir.listFiles();
  for (int i = 0; i < allFiles.length; i++) {
    String path = allFiles[i].getAbsolutePath();
    for (String ext : extensions) {
      if (path.toLowerCase().endsWith(ext)) {
        targetFiles.add(allFiles[i]);
        break;
      }
    }
  }
  File[] output = new File[targetFiles.size()];
  output = targetFiles.toArray(output);
  Arrays.sort(output);
  return output;
}
