FnpDataReader r;

void settings() {
  fnpSize(555, 555, JAVA2D);
  smooth(8);
}

void setup() {
  r = new FnpDataReader("roi_diff_90cols");
  //r.setReadingsPerSecond(10);
}

void draw() {
  background(128);
  
  JSONObject json = r.getValueAsJSON("roi_diff_90cols");
  if (json != null) {
    int[][] entireMatrix = getVerticalRegion(json, 1, 0);
    //int[][] subMatrix = getVerticalRegion(json, 9, 8);
    int[][] subMatrix = getVerticalRegion(json, 0.5, 0.75);

    drawMatrix(entireMatrix, 4);

    pushMatrix();
    translate(mouseX, mouseY);
    drawMatrix(subMatrix, 4);
    popMatrix();
  }
}

int[][] getVerticalRegion(JSONObject matrixData, float leftLimit, float rightLimit) {
  assert leftLimit >= 0;
  assert rightLimit <= 1;
  assert leftLimit < rightLimit;
  
  int matrixW = matrixData.getInt("w");
  int matrixH = matrixData.getInt("h");
  JSONArray matrix = matrixData.getJSONArray("matrix");

  int colBegin = int(matrixW * leftLimit);
  int numCols = int(matrixW * (rightLimit - leftLimit));
  assert numCols >= 1;
  
  int[][] subMatrix = new int[matrixH][numCols];
  for (int row = 0; row < matrixH; row++) {
    JSONArray diffRow = matrix.getJSONArray(row);
    for (int col = 0; col < numCols; col++) {
      subMatrix[row][col] = diffRow.getInt(colBegin + col);
    }
  }
  return subMatrix;
}

int[][] getVerticalRegion(JSONObject matrixData, int slices, int indexSlice) {
  int matrixW = matrixData.getInt("w");
  int matrixH = matrixData.getInt("h");
  JSONArray matrix = matrixData.getJSONArray("matrix");

  assert slices >= 1;
  assert slices <= matrixW;
  assert indexSlice >= 0;
  assert indexSlice < slices;

  int numCols = int(matrixW / (float) slices);
  int colBegin = indexSlice * numCols;
  
  int[][] subMatrix = new int[matrixH][numCols];
  for (int row = 0; row < matrixH; row++) {
    JSONArray diffRow = matrix.getJSONArray(row);
    for (int col = 0; col < numCols; col++) {
      subMatrix[row][col] = diffRow.getInt(colBegin + col);
    }
  }
  return subMatrix;
}

void drawMatrix(int[][] matrix, int cellSize) {
  noStroke();
  for (int row = 0; row < matrix.length; row++) {
    for (int col = 0; col < matrix[row].length; col++) {
      fill(matrix[row][col]);
      rect(col * cellSize, row * cellSize, cellSize, cellSize);
    }
  }
}
