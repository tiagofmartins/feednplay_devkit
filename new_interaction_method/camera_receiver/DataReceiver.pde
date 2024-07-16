import processing.net.*;
import java.util.Dictionary;
import java.util.Hashtable;
import java.net.ConnectException;
import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.*;
import java.util.function.Function;

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
    STR_RANDOM,
    JSON_TEST
}


class DataReceiver {

  private PApplet parent;
  private DataTopic topic;
  private String id;
  private Class<?> dataClass;
  private Client client = null;
  private Object data = null;
  private long waitingResponseSince = -1;

  DataReceiver(PApplet parent, DataTopic topic) {
    this.parent = parent;
    this.topic = topic;

    // Set ID string using the name of the program, thread ID, and topic
    String programName = new File(parent.sketchPath("")).getName();
    String threadId = String.valueOf(Thread.currentThread().getId());
    this.id = programName + "-" + threadId + ">" + topic.name();

    // Detect the type (class) of the data expected for this topic
    String preffix = topic.name().split("_")[0];
    if (preffix.equals("STR")) {
      this.dataClass = String.class;
    } else if (preffix.equals("INT")) {
      this.dataClass = Integer.class;
    } else if (preffix.equals("FLOAT")) {
      this.dataClass = Float.class;
    } else if (preffix.equals("JSON")) {
      this.dataClass = JSONObject.class;
    } else if (preffix.equals("IMG")) {
      this.dataClass = PImage.class;
    } else {
      System.err.println("Unable to detect the type of data expected for topic " + topic.name());
      System.exit(1);
    }
  }

  private void checkConnection() {
    // Nothing to do here if client is active
    if (client != null && client.active()) {
      return;
    }

    // Connect to server
    println("Connecting to server at " + HOST + ":" + PORT + " to request " + topic.name());
    client = new Client(parent, HOST, PORT);
  }

  void requestData() {
    // Nothing to do here if we are waiting for a response to a previous request
    if (waitingResponseSince != -1) {
      return;
    }

    // Send data request
    checkConnection();
    //client.write(this.id + "\n");
    client.write(this.id);
    client.write('\n');
    waitingResponseSince = System.currentTimeMillis();
  }

  boolean newDataAvailable() {
    // If not waiting for a response...
    if (waitingResponseSince == -1) {
      return false; // Return false (new data NOT available)
    }

    // Check connection
    checkConnection();

    // If data has been received...
    if (client.available() > 0) {

      // Attempt to parse received data
      try {
        if (dataClass == Integer.class) {
          data = ByteUtils.bytesToInt(client.readBytes());
        } else if (dataClass == Float.class) {
          data = ByteUtils.bytesToString(client.readBytes());
        } else if (dataClass == JSONObject.class) {
          data = ByteUtils.bytesToJSONObject(client.readBytes());
        } else if (dataClass == PImage.class) {
          //data = ByteUtils.bytesToPImage(bytes);
          PImage dataTemp = ByteUtils.bytesToPImage2(parent, client.readBytes(), 3);
          if (dataTemp != null) {
            data =  dataTemp;
          }
        } else {
          data = client.readString();
        }
        waitingResponseSince = -1; // No longer waiting for a response
        return true; // Return true => new data available
      }
      catch (Exception e) {
        println("Unable to parse received data:\n" + e);
      }

      // If no data was received for some time...
    } else if (System.currentTimeMillis() - waitingResponseSince > 5000) {
      println("Data request without response for a long time. Creating new connection.");
      client = null; // Force the creation of a new client object
      waitingResponseSince = -1; // Force new request to be sent
      requestData();
    }

    // Return false (new data NOT available)
    return false;
  }

  /**
   * Returns the data cast to the specified type.
   * If data is null, it returns null.
   */
  <Any>Any getData() {
    return data != null ? (Any) dataClass.cast(data) : null;
  }
}

// ----------------------------------------------------------------------------------------------------
// Class with functions to convert different types of data to bytes and the other way around
// ----------------------------------------------------------------------------------------------------

static class ByteUtils {

  // Convert String to byte[]
  static byte[] stringToBytes(String text) {
    return text.getBytes();
  }

  // Convert int to byte[]
  static byte[] intToBytes(int value) {
    return new byte[] {(byte)(value >> 24), (byte)(value >> 16), (byte)(value >> 8), (byte)value};
  }

  // Convert float to byte[]
  static byte[] floatToBytes(float value) {
    int intBits = Float.floatToIntBits(value);
    return new byte[] {(byte)(intBits >> 24), (byte)(intBits >> 16), (byte)(intBits >> 8), (byte)(intBits)};
  }

  // Convert JSONObject to byte[]
  static byte[] JSONObjectToBytes(JSONObject json) {
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    try {
      baos.write(json.toString().getBytes("UTF-8"));
    }
    catch (IOException e) {
      e.printStackTrace();
    }
    return baos.toByteArray();
  }

  // Convert PImage to byte[]
  static byte[] PImageToBytes(PImage img) {
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    try {
      ImageIO.write((BufferedImage) img.getNative(), "jpg", baos);
    }
    catch (IOException e) {
      e.printStackTrace();
    }
    return baos.toByteArray();
  }

  // Convert byte[] to String
  static String bytesToString(byte[] bytes) {
    return new String(bytes);
  }

  // Convert byte[] to int
  static int bytesToInt(byte[] bytes) {
    return (bytes[0] << 24) | ((bytes[1] & 0xFF) << 16) | ((bytes[2] & 0xFF) << 8) | (bytes[3] & 0xFF);
  }

  // Convert byte[] to float
  static float bytesToFloat(byte[] bytes) {
    int intBits = bytes[0] << 24 | (bytes[1] & 0xFF) << 16 | (bytes[2] & 0xFF) << 8 | (bytes[3] & 0xFF);
    return Float.intBitsToFloat(intBits);
  }

  // Convert byte[] to JSONObject
  static JSONObject bytesToJSONObject(byte[] bytes) {
    ByteArrayInputStream bais = new ByteArrayInputStream(bytes);
    JSONObject json = null;
    byte[] buffer = new byte[bytes.length];
    bais.read(buffer, 0, buffer.length);
    try {
      String jsonString = new String(buffer, "UTF-8");
      json = JSONObject.parse(jsonString);
    }
    catch (IOException e) {
      e.printStackTrace();
    }
    return json;
  }

  // Convert byte[] to PImage
  static PImage bytesToPImage(byte[] bytes) {
    ByteArrayInputStream bais = new ByteArrayInputStream(bytes);
    PImage img = null;
    try {
      img = new PImage(ImageIO.read(bais));
    }
    catch (IOException e) {
      e.printStackTrace();
    }
    return img;
  }

  static PImage bytesToPImage2(PApplet parent, byte[] bytes, int channels) {
    //System.gc();

    assert channels == 1 || channels == 3;

    int imgWidth = (bytes[0] << 24) | ((bytes[1] & 0xFF) << 16) | ((bytes[2] & 0xFF) << 8) | (bytes[3] & 0xFF);
    int imgHeight = (bytes[4] << 24) | ((bytes[5] & 0xFF) << 16) | ((bytes[6] & 0xFF) << 8) | (bytes[7] & 0xFF);
    int bytesHeader = 8;
    int bytesExpected = bytesHeader + imgWidth * imgHeight * channels;
    if (bytesExpected != bytes.length) {
      return null;
    }

    PImage img = parent.createImage(imgWidth, imgHeight, channels == 3 ? RGB : ALPHA);
    
    if (channels == 3) {
      int r, g, b;
      for (int i = 0; i < img.pixels.length; i++) {
        r = bytes[8 + i * channels + 0] & 0xFF;
        g = bytes[8 + i * channels + 1] & 0xFF;
        b = bytes[8 + i * channels + 2] & 0xFF;
        img.pixels[i] = 0xff000000 | (r << 16) | (g << 8) | b;
      }
    } else {
      int grey;
      for (int i = 0; i < img.pixels.length; i++) {
        grey = bytes[8 + i] & 0xFF;
        img.pixels[i] = 0xff000000 | (grey << 16) | (grey << 8) | grey;
      }
    }
    img.updatePixels();
    return img;
  }
}
