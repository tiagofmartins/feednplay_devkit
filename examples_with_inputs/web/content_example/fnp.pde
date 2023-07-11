/*
┌───────────────────────────────┐
│ FeedNPlay                     │
│                               │
└───────────────────────────────┘
Please DO NOT change any code contained in this tab.
*/

import java.util.concurrent.*;

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
            } catch (IOException e) {
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
