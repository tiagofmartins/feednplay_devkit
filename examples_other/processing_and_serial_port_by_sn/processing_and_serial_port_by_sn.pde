import processing.serial.*;

/*
How to find the serial number of your Arduino board?
 1. Open the Arduino IDE
 2. Make sure the correct board is selected
 3. Go to the menu Tools
 4. Select the option Get Board Info
 5. Copy the serial number and use it here
 */

String boardSerialNumber = "TODO";
Serial port;

void settings() {
  fnpSize(555, 555, P2D);
  smooth(8);
}

void setup() {
  String portName = getPortOfArduinoWithSerialNumber(boardSerialNumber);
  if (portName == null) {
    println("Port with serial number " + boardSerialNumber + " not found");
    exit();
    return;
  }
  port = new Serial(this, portName, 9600);
  // Insert your code here
  fnpEndSetup();
}

void draw() {
  // Insert your code here
}
