DataReceiver receiver1;
DataReceiver receiver2;
DataReceiver receiver3;
DataReceiver receiver4;
int incomingData1 = 0;
String incomingData2 = "-";
PImage incomingData3 = null;
JSONObject incomingData4 = null;

void setup() {
  size(444, 444);
  frameRate(60);
  fill(255, 120, 0);
  textSize(50);
  textAlign(LEFT, TOP);
  
  receiver1 = new DataReceiver(this, DataTopic.INT_RANDOM);
  receiver1.requestData();
  receiver2 = new DataReceiver(this, DataTopic.STR_RANDOM);
  receiver2.requestData();
  receiver3 = new DataReceiver(this, DataTopic.IMG_CAMTOP_RGB_720H);
  receiver3.requestData();
  receiver4 = new DataReceiver(this, DataTopic.JSON_TEST);
  receiver4.requestData();
}

void draw() {
  background(200);
  
  if (receiver1.newDataAvailable()) {
    incomingData1 = receiver1.getData();
    receiver1.requestData();
  }
  if (receiver2.newDataAvailable()) {
    incomingData2 = receiver2.getData();
    receiver2.requestData();
  }
  if (receiver3.newDataAvailable()) {
    incomingData3 = receiver3.getData();
    receiver3.requestData();
  }
  if (receiver4.newDataAvailable()) {
    incomingData4 = receiver4.getData();
    receiver4.requestData();
  }
  
  if (incomingData3 != null) {
    image(incomingData3, 0, 0, 100, 100);
  }
  text(incomingData1, 20, 20);
  text(incomingData2, 20, 100);
  if (incomingData4 != null) {
    text(incomingData4.toString(), 20, 150);
  }
}
