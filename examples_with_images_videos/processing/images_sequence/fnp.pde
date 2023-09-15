/*
 ┌───────────────────────────────┐
 │ FeedNPlay                     │
 │                               │
 └───────────────────────────────┘
 Please DO NOT change any of the code below.
 If you have any suggestions or special requests,
 please contact the FeedNPlay team.
 We will be happy to improve the system for you and all users.
 */

import java.util.concurrent.*;
import java.io.BufferedReader;
import java.io.InputStreamReader;

final StringDict arguments = new StringDict();

void fnpSize(int w, int h, String renderer) {
  assert renderer.endsWith(".PGraphicsJava2D") || renderer.endsWith(".PGraphics2D") || renderer.endsWith(".PGraphics3D");
  if (args != null) {
    for (String arg : args) {
      String[] entry = split(arg, "=");
      assert entry.length == 2;
      arguments.set(entry[0], entry[1]);
    }
  }
  if (arguments.hasKey("w") && arguments.hasKey("h")) {
    size(int(arguments.get("w")), int(arguments.get("h")), renderer);
  } else {
    size(w, h, renderer);
  }
}

void fnpSize(int w, int h) {
  fnpSize(w, h, JAVA2D);
}

void fnpSize(int x, int y, int w, int h, String renderer) {
  if (!arguments.hasKey("x") || !arguments.hasKey("y")) {
    arguments.set("x", x + "");
    arguments.set("y", y + "");
  }
  fnpSize(w, h, renderer);
}

void fnpFullScreen(String renderer) {
  fnpSize(0, 0, displayWidth, displayHeight, renderer);
  PApplet.hideMenuBar();
}

void fnpEndSetup() {
  if (arguments.size() > 0) {
    if (arguments.hasKey("x") && arguments.hasKey("y")) {
      surface.setLocation(int(arguments.get("x")), int(arguments.get("y")));
    }

    ScheduledExecutorService executor = Executors.newScheduledThreadPool(2);

    Runnable periodicPing = new Runnable() {
      public void run() {
        System.out.println("ping " + System.currentTimeMillis());
      }
    };
    executor.scheduleAtFixedRate(periodicPing, 0, 5000, TimeUnit.MILLISECONDS);

    if (arguments.hasKey("proxy-dir")) {
      Runnable checkProxyFiles = new Runnable() {
        File proxyClose = new File(arguments.get("proxy-dir"), "close");
        File proxyClosed = new File(arguments.get("proxy-dir"), "closed");
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
      executor.scheduleAtFixedRate(checkProxyFiles, 0, 1000, TimeUnit.MILLISECONDS);
    }
  }
}

PSurface initSurface() {
  PSurface ps = super.initSurface();
  String renderer = getRenderer(this);
  if (renderer == P2D || renderer == P3D) {
    com.jogamp.newt.opengl.GLWindow window = (com.jogamp.newt.opengl.GLWindow) surface.getNative();
    window.setUndecorated(true);
  } else if (renderer == JAVA2D) {
    java.awt.Frame frame = ((processing.awt.PSurfaceAWT.SmoothCanvas) ((processing.awt.PSurfaceAWT) surface).getNative()).getFrame();
    frame.setUndecorated(true);
  } else {
    assert false;
  }
  //ps.setAlwaysOnTop(true);
  //ps.hideCursor();
  return ps;
}

static String getRenderer(PApplet p) {
  PGraphics pg  = p.getGraphics();
  if (pg.isGL()) {
    if (pg.is3D()) {
      return P3D;
    } else {
      return P2D;
    }
  } else {
    return JAVA2D;
  }
}

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

String getArduinoSerialPortsOverview() {
  String output = "";
  StringDict arduinoPorts = getArduinoSerialPorts();
  for (String sn : arduinoPorts.keys()) {
    output += "[" + sn + "] " + arduinoPorts.get(sn) + "\n";
  }
  return !output.isEmpty() ? output.strip() : "none";
}
