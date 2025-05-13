import processing.net.*;
import java.io.*;
import java.util.Dictionary;
import java.util.Hashtable;
import java.nio.ByteBuffer;

enum Topic {
  IMG_CAMTOP_RGB, IMG_CAMTOP_CROP_RGB, IMG_CAMTOP_GRAY, IMG_CAMTOP_CROP_GRAY, IMG_CAMTOP_XYZ
}

class FnpDataReceiver {

  private final String SERVER_ADDRESS = "127.0.0.1";

  private PApplet parent;
  private int port;
  private Client client = null;
  
  private Topic topic;
  private Object data = null;
  private Class<?> dataClass;
  
  private String requestMessage;
  private long timeLastRequestSent = -1;

  FnpDataReceiver(PApplet parent, int port, Topic topic) {
    this.parent = parent;
    this.port = port;
    this.topic = topic;

    // Set class for incoming data based on the preffix of the topic
    String preffix = topic.name().split("_")[0];
    if (preffix.equals("INT")) {
      dataClass = Integer.class;
    } else if (preffix.equals("FLOAT")) {
      dataClass = Float.class;
    } else if (preffix.equals("STR")) {
      dataClass = String.class;
    } else if (preffix.equals("JSON")) {
      dataClass = JSONObject.class;
    } else if (preffix.equals("IMG")) {
      dataClass = PImage.class;
    } else {
      System.err.println("ERROR - Unable to determine data class for topic: " + topic);
      System.exit(1);
    }

    // Setup request message using the name of the program, thread ID, and topic
    String programName = new File(parent.sketchPath("")).getName();
    String threadId = String.valueOf(Thread.currentThread().getId());
    requestMessage = programName + "-" + threadId + ">" + topic.name();
  }

  private void checkConnection() {
    if (client == null || client.active() == false) {
      println("Attempting to connect to server at " + SERVER_ADDRESS + ":" + port + " to get " + topic.name());
      client = new Client(parent, SERVER_ADDRESS, port);
    }
  }

  public void requestData() {
    // Send data request only if we are not waiting for one sent previously
    if (timeLastRequestSent == -1) {
      checkConnection();
      client.write(requestMessage);
      client.write('\n');
      timeLastRequestSent = System.currentTimeMillis();
    }
  }

  public boolean newDataAvailable() {
    // Return false when not waiting for a response
    if (timeLastRequestSent == -1) {
      return false;
    }

    // Reconnect to server and send new new data quest if no data is received for some time
    if (System.currentTimeMillis() - timeLastRequestSent > 5000) {
      System.err.println("ERROR - Data reception timeout");
      client = null; // Force the creation of new connection
      timeLastRequestSent = -1; // Force the sending of new data request
      requestData();
      return false;
    }

    // Check connection
    checkConnection();

    // Attempt to parse incoming data
    if (client.available() > 0) {
      byte[] incomingBytes = client.readBytes();
      try {
        if (dataClass == Integer.class) {
          data = Decoder.bytesToInt(incomingBytes);
        } else if (dataClass == Float.class) {
          data = Decoder.bytesToFloat(incomingBytes);
        } else if (dataClass == JSONObject.class) {
          data = Decoder.bytesToJSON(incomingBytes);
        } else if (dataClass == PImage.class) {
          PImage dataTemp = Decoder.bytesToPImage(parent, incomingBytes, 3);
          if (dataTemp != null) {
            data =  dataTemp;
          }
        } else {
          data = client.readString();
        }
        timeLastRequestSent = -1; // No longer waiting for a response
        return true; // Return true, meaning new data is available
      }
      catch (Exception e) {
        System.err.println("ERROR - Unable to parse incoming data:\n" + e);
      }
    }

    // Return false, meaning no new data is available
    return false;
  }

  /**
   * Return last received data cast to the corresponding class.
   * If data is null, return null.
   */
  public <Any>Any getData() {
    return data != null ? (Any) dataClass.cast(data) : null;
  }

  /**
   * Return data while requesting new one.
   */
  public <Any>Any getDataAndResquestNew() {
    newDataAvailable();
    requestData();
    return getData();
  }
}

// ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
// Encoder to convert different types of data to bytes
// ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

static class Encoder {

  static byte[] stringToBytes(String text) {
    return text.getBytes();
  }

  static byte[] integerToBytes(Integer value) {
    //return new byte[] {(byte)(value >> 24), (byte)(value >> 16), (byte)(value >> 8), (byte)value};
    return ByteBuffer.allocate(4).putInt(value).array();
  }

  static byte[] floatToBytes(Float value) {
    //int intBits = Float.floatToIntBits(value);
    //return new byte[] {(byte)(intBits >> 24), (byte)(intBits >> 16), (byte)(intBits >> 8), (byte)(intBits)};
    return ByteBuffer.allocate(4).putFloat(value).array();
  }

  static byte[] jsonToBytes(JSONObject json) {
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    try {
      baos.write(json.toString().getBytes("UTF-8"));
    }
    catch (IOException e) {
      e.printStackTrace();
    }
    return baos.toByteArray();
  }

  static byte[] pimageToBytes(PImage img, int channels) {
    assert channels == 1 || channels == 3;

    // Create array of bytes
    byte[] bytes = new byte[8 + img.pixels.length * channels];

    // Encode image size in the first bytes
    // Two integers (width and height) require 8 bytes
    bytes[0] = (byte) (img.width >> 24);
    bytes[1] = (byte) (img.width >> 16);
    bytes[2] = (byte) (img.width >> 8);
    bytes[3] = (byte) (img.width);
    bytes[4] = (byte) (img.height >> 24);
    bytes[5] = (byte) (img.height >> 16);
    bytes[6] = (byte) (img.height >> 8);
    bytes[7] = (byte) (img.height);

    // Encode image pixels in the remaining bytes
    img.loadPixels();
    if (channels == 3) {
      for (int i = 0; i < img.pixels.length; i++) {
        bytes[8 + i * 3 + 0] = (byte) (img.pixels[i] >> 16 & 0xFF);
        bytes[8 + i * 3 + 1] = (byte) (img.pixels[i] >> 8 & 0xFF);
        bytes[8 + i * 3 + 2] = (byte) (img.pixels[i] & 0xFF);
      }
    } else {
      for (int i = 0; i < img.pixels.length; i++) {
        bytes[8 + i] = (byte) (img.pixels[i] & 0xFF);
      }
    }

    // Return bytes
    return bytes;
  }
}

// ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
// Decoder to convert bytes to different types of data
// ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

static class Decoder {

  static String bytesToString(byte[] bytes) {
    return new String(bytes);
  }

  static Integer bytesToInt(byte[] bytes) {
    return (bytes[0] << 24) | ((bytes[1] & 0xFF) << 16) | ((bytes[2] & 0xFF) << 8) | (bytes[3] & 0xFF);
  }

  static Float bytesToFloat(byte[] bytes) {
    int intBits = bytes[0] << 24 | (bytes[1] & 0xFF) << 16 | (bytes[2] & 0xFF) << 8 | (bytes[3] & 0xFF);
    return Float.intBitsToFloat(intBits);
  }

  static JSONObject bytesToJSON(byte[] bytes) {
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

  static PImage bytesToPImage(PApplet parent, byte[] bytes, int channels) {
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
