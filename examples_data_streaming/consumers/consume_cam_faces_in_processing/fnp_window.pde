/*
 ┌──────────────────────────────────────────────────────────┐
 │ FeedNPlay                                     2023.09.19 │
 │ Code that allows the automatic display of content.       │
 │ Please DO NOT change any of the code below.              │
 │ If you have any suggestions or special requests          │
 │ please contact the FeedNPlay team. We will be happy      │
 │ to improve the system for you and all users.             │
 └──────────────────────────────────────────────────────────┘
 */

import java.util.concurrent.*;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Arrays;

StringDict fnpArguments = new StringDict();
boolean fnpRunAutomated = false;
boolean fnpSizeCalled = false;

void fnpSize(int x, int y, int w, int h, String renderer, boolean undecorated) {
  // Check if this function was called in settings() and not in setup()
  boolean calledFromSettings = false;
  StackTraceElement[] stackTraceElements = Thread.currentThread().getStackTrace();
  for (StackTraceElement element : stackTraceElements) {
    if (element.getMethodName().equals("settings")) {
      calledFromSettings = true;
      break;
    }
  }
  if (!calledFromSettings) {
    throw new RuntimeException("Function fnpSize() must be called in the function settings()");
  }

  // Check if this method is called only once
  if (fnpSizeCalled) {
    throw new RuntimeException("This method should be called only once.");
  }
  fnpSizeCalled = true;

  // Check if the selected rendered can be used
  if (!Arrays.asList(JAVA2D, FX2D, P2D, P3D).contains(renderer)) {
    throw new RuntimeException("Renderer " + renderer + " cannot be used.");
  }

  // Parse input arguments when they exist (sketch launched from command line)
  if (args != null) {
    fnpRunAutomated = true;
    for (String arg : args) {
      String[] param = split(arg, "=");
      if (param.length != 2) {
        throw new RuntimeException("Unable to parse the argument '" + arg + "'.");
      }
      fnpArguments.set(param[0], param[1]);
    }
  }

  // Check if sketch x and y were both passed as arguments or not
  if (fnpArguments.hasKey("x") != fnpArguments.hasKey("y")) {
    throw new RuntimeException("Sketch x or y was not passed as argument.");
  }

  // Check if sketch width and height were both passed as arguments or not
  if (fnpArguments.hasKey("w") != fnpArguments.hasKey("h")) {
    throw new RuntimeException("Sketch width or height was not passed as argument.");
  }

  // When sketch position is not passed as arguments, use the function parameters
  if (!fnpArguments.hasKey("x")) {
    if (x != Integer.MIN_VALUE && y != Integer.MIN_VALUE) {
      fnpArguments.set("x", Integer.toString(x));
      fnpArguments.set("y", Integer.toString(y));
    }
  }

  // When sketch size is not passed as arguments, use the function parameters
  if (!fnpArguments.hasKey("w")) {
    fnpArguments.set("w", Integer.toString(w));
    fnpArguments.set("h", Integer.toString(h));
  }

  // Create sketch window
  if (undecorated || fnpRunAutomated) {
    fullScreen(renderer);
  } else {
    size(int(fnpArguments.get("w")), int(fnpArguments.get("h")), renderer);
  }

  // Create object to execute some actions automatically
  new CustomMethodsHandler(this);
}

void fnpSize(int x, int y, int w, int h, String renderer) {
  fnpSize(x, y, w, h, renderer, false);
}

void fnpSize(int w, int h, String renderer, boolean undecorated) {
  fnpSize(Integer.MIN_VALUE, Integer.MIN_VALUE, w, h, renderer, undecorated);
}

void fnpSize(int w, int h, String renderer) {
  fnpSize(w, h, renderer, false);
}

void fnpFullScreen(String renderer) {
  fnpSize(0, 0, displayWidth, displayHeight, renderer, true);
}

public class CustomMethodsHandler {

  private PApplet parent;
  private long timeLastPing = 0;

  CustomMethodsHandler(PApplet parent) {
    this.parent = parent;
    parent.registerMethod("pre", this);
    parent.registerMethod("dispose", this);
  }

  void pre() {
    // Perform some actions at the beginning of the sketch
    if (parent.frameCount <= 5) {

      // Set sketch window position
      if (fnpArguments.hasKey("x") && fnpArguments.hasKey("y")) {
        surface.setLocation(int(fnpArguments.get("x")), int(fnpArguments.get("y")));
      }

      // Set sketch window size
      if (fnpArguments.hasKey("w") && fnpArguments.hasKey("h")) {
        surface.setSize(int(fnpArguments.get("w")), int(fnpArguments.get("h")));
      }

      // Sketch closing mechanism using a proxy file
      if (fnpRunAutomated && parent.frameCount == 1) {
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

    // Print ping message to console periodically so we can check if the sketch is running
    // when it was launched from command line
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

/*───────────────────────────────────────────────────────────────────────┐
 │ The code below allows to get the name of the communication port       │
 │ to which an Arduino board with a given serial number is connected to. │
 └───────────────────────────────────────────────────────────────────────*/

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

  // Run script from the command line and get the result
  Process process = exec("python3", scriptFile.getPath());
  BufferedReader outReader = new BufferedReader(new InputStreamReader(process.getInputStream()));
  BufferedReader errReader = new BufferedReader(new InputStreamReader(process.getErrorStream()));
  String out = "";
  String err = "";
  String line;
  try {
    while ((line = outReader.readLine()) != null) {
      out += line + "\n";
    }
    while ((line = errReader.readLine()) != null) {
      err += line + "\n";
    }
  }
  catch (IOException e) {
    printStackTrace(e);
  }
  out = out.strip();
  err = err.strip();

  // Delete script file
  if (scriptFile.exists()) {
    scriptFile.delete();
  }

  // Make sure no errors were obtained
  if (!err.isEmpty()) {
    throw new RuntimeException("Error obtained when running the command line:\n" + err);
  }

  // Parse list of found ports
  StringDict arduinoPorts = new StringDict();
  String[] outLines = out.split("\n");
  for (String l : outLines) {
    if (!l.isEmpty() && l.contains(":")) {
      String[] portInfo = l.split(":");
      arduinoPorts.set(portInfo[0], portInfo[1]);
    }
  }

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
