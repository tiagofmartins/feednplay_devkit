FnpDataReader reader;
ArrayList<Body> bodies = new ArrayList<Body>();
PImage frame = null;

void settings() {
  fnpSize(666, 444, JAVA2D);
  smooth(8);
}

void setup() {
  reader = new FnpDataReader("camtop_image_roi_grayscale_full", "camtop_presences");
  textSize(16);
}

void draw() {
  background(255);
  //scale(0.5);

  PImage newFrame = reader.getValueAsPImage("camtop_image_roi_grayscale_full");
  JSONObject presencesData = reader.getValueAsJSON("camtop_presences");

  if (newFrame != null) {
    frame = newFrame;
  }
  if (frame != null) {
    if (presencesData != null) {
      for (Body b : bodies) {
        b.alive = false;
      }
      JSONArray presences = presencesData.getJSONArray("presences");
      for (int i = 0; i < presences.size(); i++) {
        JSONObject p = presences.getJSONObject(i);
        String pId = p.getString("id");
        JSONObject centroid = p.getJSONObject("centroid");
        float cX = centroid.getFloat("x") * frame.width;
        float cY = centroid.getFloat("y") * frame.height;
        JSONObject bounds = p.getJSONObject("bounds");
        float bX = bounds.getFloat("x") * frame.width;
        float bY = bounds.getFloat("y") * frame.height;
        float bW = bounds.getFloat("w") * frame.width;
        float bH = bounds.getFloat("h") * frame.height;
        boolean existingId = false;
        for (Body b : bodies) {
          if (b.id.equals(pId)) {
            existingId = true;
            b.alive = true;
            b.update(cX, cY, bX, bY, bW, bH);
            break;
          }
        }
        if (!existingId) {
          Body newBody = new Body(pId);
          newBody.update(cX, cY, bX, bY, bW, bH);
          bodies.add(newBody);
        }
      }
      for (int i = bodies.size() - 1; i >= 0; i--) {
        if (!bodies.get(i).alive) {
          bodies.remove(i);
        }
      }
    }
  }
  
  if (frame != null) {
    image(frame, 0, 0);
  }
  for (Body b : bodies) {
    noFill();
    stroke(b.randomColor);
    strokeWeight(10);
    point(b.centroidX, b.centroidY);
    strokeWeight(2);
    rect(b.boundsX, b.boundsY, b.boundsW, b.boundsH);
    fill(255);
    text(b.id, b.boundsX, b.boundsY);
  }
}

class Body {

  String id;
  float centroidX, centroidY;
  float boundsX, boundsY, boundsW, boundsH;
  boolean alive;
  color randomColor;
  
  Body(String id) {
    this.id = id;
    this.alive = true;
    this.randomColor = color(random(255), random(255), random(255));
  }

  void update(float centroidX, float centroidY, float boundsX, float boundsY, float boundsW, float boundsH) {
    this.centroidX = centroidX;
    this.centroidY = centroidY;
    this.boundsX = boundsX;
    this.boundsY = boundsY;
    this.boundsW = boundsW;
    this.boundsH = boundsH;
  }

  Body getCopy() {
    Body copy = new Body(this.id);
    copy.update(this.centroidX, this.centroidY, this.boundsX, this.boundsY, this.boundsW, this.boundsH);
    copy.alive = this.alive;
    copy.randomColor = this.randomColor;
    return copy;
  }
}
