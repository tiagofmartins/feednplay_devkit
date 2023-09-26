This Processing sketch demonstrates the communication with an Arduino board using its serial number.

This method solves the problem of finding the name of the serial port which is set by the operating system randomly and it changes every time the board is (re)connected to the computer.

### Requirements

This sketch internally runs a Python script to determine the name of the serial port used by the board with the given serial number. This script requires the pyserial lib which can be installed by running the following command line:

```console
python -m pip install pyserial
```

### How to find the serial number of a Arduino board

1. Connect the Arduino board to the computer
2. Open the Arduino IDE application
3. Make sure the correct board is selected
4. Go to the menu Tools
5. Select the option Get Board Info
6. Copy the SN number (the one with several digits)