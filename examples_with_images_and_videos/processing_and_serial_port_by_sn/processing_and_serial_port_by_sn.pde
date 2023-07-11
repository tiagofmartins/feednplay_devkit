import processing.serial.*;

String arduinoSerialNumber = "85036313530351304291";
Serial port;
String dataReceived = "";

void settings() {
  fnpSize(444, 222, P2D);
  smooth(8);
}

void setup() {
  String portName = getArduinoPortBySerialNumber(arduinoSerialNumber);
  if (portName == null) {
    println("Port of device with serial number " + arduinoSerialNumber + " not found");
    println("Available ports:\n" + getStringWithArduinoSerialPorts());
    exit();
    return;
  }
  println("Connecting serial port " + portName);
  port = new Serial(this, portName, 9600);
}

void draw() {
  if (port.available() > 0) {
    String newData = port.readStringUntil('\n');
    if (newData != null) {
      dataReceived = newData;
    }
  }
  
  background(0);
  fill(255);
  textSize(40);
  text(dataReceived, 30, 60);
}
