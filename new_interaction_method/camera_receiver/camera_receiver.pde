DataReceiver receiver1;
DataReceiver receiver2;
int incomingData1 = 0;
String incomingData2 = "-";

void setup() {
  size(444, 444);
  frameRate(3);
  fill(255, 120, 0);
  textSize(50);
  textAlign(LEFT, TOP);
  
  receiver1 = new DataReceiver(this, DataTopic.INT_RANDOM);
  receiver1.requestData();
  receiver2 = new DataReceiver(this, DataTopic.STR_RANDOM);
  receiver2.requestData();
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
  
  text(incomingData1, 20, 20);
  text(incomingData2, 20, 100);
}
