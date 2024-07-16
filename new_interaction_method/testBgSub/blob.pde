class Blob {

  final static long MAX_MILLIS_WITHOUT_UPDATE = 2000;

  PApplet parent;
  int id;
  Contour contour;
  PVector centroid;
  Rect boundingRect;
  long timeLastUpdate;
  boolean updated;
  color colour;

  Blob(PApplet parent, int id, Contour contour) {
    this.parent = parent;
    this.id = id;
    this.colour = color(random(128, 255), random(128, 255), random(128, 255));
    update(contour);
  }

  void update(Contour newContour) {
    contour = new Contour(parent, newContour.pointMat);
    centroid = calculateCentroid(contour);
    boundingRect = calculateBoundingRect(contour);
    timeLastUpdate = System.currentTimeMillis();
    updated = true;
  }

  void setAsUpdatable() {
    updated = false;
  }

  boolean updated() {
    return updated;
  }

  boolean dead() {
    return getStrength() <= 0;
  }

  float getStrength() {
    long millisSinceLastUPDATE = System.currentTimeMillis() - timeLastUpdate;
    float strength = constrain(map(millisSinceLastUPDATE, 0, MAX_MILLIS_WITHOUT_UPDATE, 1, 0), 0, 1);
    return strength;
  }

  PVector getCentroid() {
    return centroid;
  }

  Rect getBoundingRect() {
    return boundingRect;
  }

  boolean contains(PVector p) {
    return contour.containsPoint((int) p.x, (int) p.y);
  }

  JSONObject getJSON(int maxWidth, int maxHeight) {
    JSONObject json = new JSONObject();
    json.setInt("id", id);
    JSONArray jsonPoints = new JSONArray();
    for (PVector p : contour.getPoints()) {
      JSONObject jsonPoint = new JSONObject();
      jsonPoint.setFloat("x", p.x / (float) maxWidth);
      jsonPoint.setFloat("y", p.y / (float) maxHeight);
      jsonPoints.append(jsonPoint);
    }
    json.setJSONArray("contour", jsonPoints);
    JSONObject jsonCentroid = new JSONObject();
    jsonCentroid.setFloat("x", centroid.x / (float) maxWidth);
    jsonCentroid.setFloat("y", centroid.y / (float) maxHeight);
    json.setJSONObject("centroid", jsonCentroid);
    JSONObject jsonBoundingRect = new JSONObject();
    jsonBoundingRect.setFloat("x", boundingRect.x / (float) maxWidth);
    jsonBoundingRect.setFloat("y", boundingRect.y / (float) maxHeight);
    jsonBoundingRect.setFloat("width", boundingRect.width / (float) maxWidth);
    jsonBoundingRect.setFloat("height", boundingRect.height / (float) maxHeight);
    json.setJSONObject("bounding_rect", jsonBoundingRect);
    json.setFloat("strength", getStrength());
    return json;
  }
}



static PVector calculateCentroid(Contour c) {
  Moments moments = Imgproc.moments(c.pointMat);
  return new PVector((float) (moments.m10 / moments.m00), (float) (moments.m01 / moments.m00));
}



static Rect calculateBoundingRect(Contour c) {
  return Imgproc.boundingRect(c.pointMat);
}
