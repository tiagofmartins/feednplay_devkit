/*
 ┌──────────────────────────────────────────────────────────┐
 │ FeedNPlay                                     2023.07.07 │
 │ Code to enable the automatic display of content.         │
 │ Please DO NOT change any of the code below.              │
 │ If you have any suggestions or special requests          │
 │ please contact the FeedNPlay team. We will be happy      │
 │ to improve the system for you and all users.             │
 └──────────────────────────────────────────────────────────┘
 */

import java.util.concurrent.*;
import java.io.BufferedReader;
import java.io.InputStreamReader;

StringDict fnpArguments = new StringDict();
boolean fnpRunAutomated = false;
boolean fnpSizeCalled = false;

void fnpSize(int w, int h, String renderer, boolean undecorated) {
  assert fnpSizeCalled == false;
  fnpSizeCalled = true;

  assert renderer.equals(JAVA2D) || renderer.equals(P2D) || renderer.equals(P3D) || renderer.equals(FX2D);

  if (args != null) {
    fnpRunAutomated = true;
    for (String arg : args) {
      String[] param = split(arg, "=");
      assert param.length == 2;
      fnpArguments.set(param[0], param[1]);
    }
  }

  if (!fnpArguments.hasKey("w")) fnpArguments.set("w", Integer.toString(w));
  if (!fnpArguments.hasKey("h")) fnpArguments.set("h", Integer.toString(h));

  if (undecorated || fnpRunAutomated) {
    fullScreen(renderer);
  } else {
    size(int(fnpArguments.get("w")), int(fnpArguments.get("h")), renderer);
  }

  new CustomMethodsHandler(this);
}

void fnpSize(int x, int y, int w, int h, String renderer, boolean undecorated) {
  if (!fnpArguments.hasKey("x")) fnpArguments.set("x", Integer.toString(x));
  if (!fnpArguments.hasKey("y")) fnpArguments.set("y", Integer.toString(y));
  fnpSize(w, h, renderer, undecorated);
}

void fnpSize(int x, int y, int w, int h, String renderer) {
  fnpSize(x, y, w, h, renderer, false);
}

void fnpSize(int w, int h, String renderer) {
  fnpSize(w, h, renderer, false);
}

void fnpFullScreen(String renderer) {
  fnpSize(0, 0, displayWidth, displayHeight, renderer, true);
}

// ────────────────────────────────────────────────────────────────────────────────────────────────────

public class CustomMethodsHandler {

  private PApplet parent;
  private long timeLastPing = 0;

  CustomMethodsHandler(PApplet parent) {
    this.parent = parent;
    parent.registerMethod("pre", this);
    parent.registerMethod("dispose", this);
  }

  void pre() {
    if (parent.frameCount == 1) {
      if (fnpArguments.hasKey("x") && fnpArguments.hasKey("y")) {
        surface.setLocation(int(fnpArguments.get("x")), int(fnpArguments.get("y")));
      }
      if (fnpArguments.hasKey("w") && fnpArguments.hasKey("h")) {
        surface.setSize(int(fnpArguments.get("w")), int(fnpArguments.get("h")));
      }
      if (fnpRunAutomated) {
        if (fnpArguments.hasKey("proxy-dir")) {
          Runnable proxyFilesChecker = new Runnable() {
            File proxyClose = new File(fnpArguments.get("proxy-dir"), "close");
            File proxyClosed = new File(fnpArguments.get("proxy-dir"), "closed");
            public void run() {
              if (proxyClose.exists()) {
                try {
                  proxyClosed.createNewFile();
                }
                catch (IOException e) {
                  e.printStackTrace();
                }
                exit();
              }
            }
          };
          ScheduledExecutorService executor = Executors.newScheduledThreadPool(1);
          executor.scheduleAtFixedRate(proxyFilesChecker, 0, 1000, TimeUnit.MILLISECONDS);
        }
      }
    }
    if (fnpRunAutomated && System.currentTimeMillis() - timeLastPing >= 5000) {
      timeLastPing = System.currentTimeMillis();
      System.out.println("ping " + timeLastPing);
    }
  }

  void dispose() {
    // Stop the program when using FX2D renderer
    // https://github.com/processing/processing4-javafx/issues/2#issuecomment-1101799438
    exitActual();
  }
}

// ────────────────────────────────────────────────────────────────────────────────────────────────────

String getArduinoPortBySerialNumber(String serialNumber) {
  StringDict arduinoPorts = getArduinoSerialPorts();
  for (String sn : arduinoPorts.keys()) {
    if (sn.equals(serialNumber)) {
      return arduinoPorts.get(sn);
    }
  }
  return null;
}

StringDict getArduinoSerialPorts() {
  // Create Python script file
  File scriptFile = new File(sketchPath("script_temp.py"));
  String[] scriptLines = {
    "import serial.tools.list_ports",
    "for port in serial.tools.list_ports.comports():",
    "  if port.manufacturer and 'arduino' in port.manufacturer.lower():",
    "    print('{}:{}'.format(port.serial_number, port.device))"
  };
  saveStrings(scriptFile.getPath(), scriptLines);

  // Execute script
  Process process = exec("python3", scriptFile.getPath());
  BufferedReader readerInput = new BufferedReader(new InputStreamReader(process.getInputStream()));
  BufferedReader readerError = new BufferedReader(new InputStreamReader(process.getErrorStream()));

  // Get output of the command line
  StringDict arduinoPorts = new StringDict();
  try {
    String line = null;
    while ((line = readerInput.readLine()) != null) {
      String[] portInfo = line.split(":");
      arduinoPorts.set(portInfo[0], portInfo[1]);
    }
  }
  catch(IOException e) {
    e.printStackTrace();
  }

  // Get possible errors of the command line
  String error = "";
  try {
    String line = null;
    while ((line = readerError.readLine()) != null) {
      error += line + "\n";
    }
    error = error.strip();
  }
  catch(IOException e) {
    e.printStackTrace();
  }

  // Delete script file
  if (scriptFile.exists()) {
    scriptFile.delete();
  }

  // Make sure no errors were obtained
  assert error.isEmpty():
  "Error obtained when running the command line:\n" + error;

  // Return result
  return arduinoPorts;
}

String getStringWithArduinoSerialPorts() {
  String output = "";
  StringDict arduinoPorts = getArduinoSerialPorts();
  for (String sn : arduinoPorts.keys()) {
    output += "[" + sn + "] " + arduinoPorts.get(sn) + "\n";
  }
  return !output.isEmpty() ? output.strip() : "none";
}
