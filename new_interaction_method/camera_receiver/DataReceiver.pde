import processing.net.*;
import java.util.Dictionary;
import java.util.Hashtable;
import java.net.ConnectException;


static final String HOST = "127.0.0.1";
static final int PORT = 23000;

static enum DataTopic {
  IMG_CAMTOP_RGB_1080H,
    IMG_CAMTOP_RGB_720H,
    IMG_CAMTOP_RGB_480H,
    IMG_CAMTOP_GRAY_1080H,
    IMG_CAMTOP_GRAY_720H,
    IMG_CAMTOP_GRAY_480H,
    IMG_CAMTOP_DIFF_480H,
    INT_RANDOM,
    STR_RANDOM
}


class DataReceiver {

  private PApplet parent;
  private DataTopic topic;
  private String id;
  private Class<?> dataClass;
  private Client client = null;
  private Object data = null;
  private long waitingResponseSince = 0;

  DataReceiver(PApplet parent, DataTopic topic) {
    this.parent = parent;
    this.topic = topic;

    // Set ID string of this receiver using the name of the program, thread ID and topic
    String currProgramName = new File(parent.sketchPath("")).getName();
    String currThreadID = String.valueOf(Thread.currentThread().getId());
    this.id = currProgramName + "-" + currThreadID + ":" + topic.name();

    // Detect the type of data (class) associated to the topic
    String topicPreffix = topic.name().split("_")[0];
    if (topicPreffix.equals("STR")) {
      this.dataClass = String.class;
    } else if (topicPreffix.equals("INT")) {
      this.dataClass = Integer.class;
    } else if (topicPreffix.equals("FLOAT")) {
      this.dataClass = Float.class;
    } else if (topicPreffix.equals("IMG")) {
      this.dataClass = PImage.class;
    } else {
      System.err.println("Unable to detect data type for topic " + topic.name());
      System.exit(1);
    }
  }

  private void checkConnection() {
    // Nothing to do here if client is active
    if (client != null && client.active()) {
      return;
    }
    // Connect to server
    println("Connecting to data provider at " + HOST + ":" + PORT + " to request " + topic.name());
    client = new Client(parent, HOST, PORT);
    delay(500);
  }

  void requestData() {
    // Nothing to do here if we are waiting for a response to a previous request
    if (waitingResponseSince > 0) {
      return;
    }
    // Send data request
    checkConnection();
    client.write(id);
    waitingResponseSince = System.currentTimeMillis();
  }

  boolean newDataAvailable() {
    // Nothing to do here if we are not waiting for a response
    if (waitingResponseSince <= 0) {
      return false;
    }

    // Set output boolean to false
    boolean newDataAvailable = false;

    // Check if data has been received
    checkConnection();
    if (client.available() > 0) {

      // Attempt to parse received data
      try {
        if (dataClass == Integer.class) {
          data = Integer.valueOf(client.readString());
        } else if (dataClass == Float.class) {
          data = Float.valueOf(client.readString());
        } else {
          data = client.readString();
        }
        newDataAvailable = true;
        waitingResponseSince = 0;
      }
      catch (Exception e) {
        println("Unable to parse received data:");
        println(e);
        newDataAvailable = false;
      }
      
    } else if (System.currentTimeMillis() - waitingResponseSince > 2000) {
      println("Data request timeout. Creating new connection.");
      client = null; // Force the creation of a new client
      waitingResponseSince = 0; // Force new request
      requestData();
    }

    return newDataAvailable;
  }

  <Any>Any getData() {
    return data != null ? (Any) dataClass.cast(data) : null;
  }
}
