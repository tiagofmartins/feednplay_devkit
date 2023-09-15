import java.util.Arrays;
import processing.video.*;

abstract class FnpMedia {
  
  PApplet p5;
  ContentArea bounds;
  String path;
  boolean loaded = false;
  int millisFadeIn = 1000;
  int millisFadeOut = 1000;
  
  FnpMedia(PApplet p5, ContentArea bounds, String path) {
    this.p5 = p5;
    this.bounds = bounds;
    this.path = path;
  }
  
  void setFadeInOutDuration(int millisFadeIn, int millisFadeOut) {
    assert millisFadeIn == 0 || millisFadeIn >= 100;
    assert millisFadeOut == 0 || millisFadeOut >= 100;
    this.millisFadeIn = millisFadeIn;
    this.millisFadeOut = millisFadeOut;
  }

  void setPath(String path) {
    dispose();
    this.path = path;
    load();
  }
  
  abstract void load();
  
  abstract void display();
  
  abstract boolean finished();
  
  void dispose() {
    path = null;
    loaded = false;
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
}

// ================================================================================

class FnpImg extends FnpMedia {
  
  PImage image = null;
  int timeWhenLoaded;
  int millisDuration;

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
    if (!loaded) {
      if (image != null && image.width > 0 && image.height > 0) {
        bounds.setContentDim(image.width, image.height);
        loaded = true;
        timeWhenLoaded = millis();
      } else {
        return;
      }
    }
    
    // Change opacity to achieve the fade in or fade out effect
    if (millisDuration > 0) {
      float opacity = getOpacityToFadeInOut(millis() - timeWhenLoaded, millisDuration);
      if (opacity < 255) {
        tint(255, opacity);
      }
    }
    
    p5.image(image, bounds.getContentX(), bounds.getContentY(), bounds.getContentW(), bounds.getContentH());
  }
  
  void dispose() {
    super.dispose();
    image = null;
  }
  
  boolean finished() {
    return loaded && millisDuration > 0 && (millis() - timeWhenLoaded) >= millisDuration;
  }
}

// ================================================================================

class FnpVid extends FnpMedia {
  
  Movie video;
  boolean loop;
  float volume;
  
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
  
  void display() {
    if (!loaded) {
      if (video != null && video.width > 0 && video.height > 0) {
        bounds.setContentDim(video.width, video.height);
        loaded = true;
      } else {
        return;
      }
    }
    
    // Change opacity to achieve the fade in or fade out effect
    float opacity = getOpacityToFadeInOut(video.time() * 1000, video.duration() * 1000);
    if (opacity < 255) {
      tint(255, opacity);
    }
    
    // Draw current video frame
    p5.image(video, bounds.getContentX(), bounds.getContentY(), bounds.getContentW(), bounds.getContentH());
    
    // Workaround to loop the video
    // https://github.com/processing/processing-video/issues/182
    if (loop && finished()) {
      video.jump(0);
    }
  }
  
  void dispose() {
    super.dispose();
    video.dispose();
    video = null;
  }
  
  boolean finished() {
    return loaded && video.duration() - video.time() < 0.05;
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
  private Rect boundsContent;
  private float contentW;
  private float contentH;
  private float marginHor;
  private float marginVer;
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
  
  void setContentDim(float contentW, float contentH) {
    if (this.contentW != contentW || this.contentH != contentH) {
      this.contentW = contentW;
      this.contentH = contentH;
      calculateContentBounds();
    }
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
