import processing.net.*;
import java.io.*;
import java.util.Dictionary;
import java.util.Hashtable;

enum Topic {
  IMG_RGB, IMG_CAMTOP_GRAY, IMG_CAMTOP_DIFF, IMG_CAMTOP_RGB_720H
}

class DataReceiver {

  private final String SERVER_ADDRESS = "127.0.0.1";

  private PApplet parent;
  private int port;
  private Topic topic;
  private String id;
  private Class<?> dataClass;
  private Client client = null;
  private Object data = null;
  private long timeLastRequestSent = -1;

  DataReceiver(PApplet parent, int port, Topic topic) {
    this.parent = parent;
    this.port = port;
    this.topic = topic;

    // Set class for incoming data based on the preffix of the topic
    String topicPreffix = topic.name().split("_")[0];
    this.dataClass = preffixDataClass.get(topicPreffix);

    // Set ID string using the name of the program, thread ID, and topic
    String programName = new File(parent.sketchPath("")).getName();
    String threadId = String.valueOf(Thread.currentThread().getId());
    this.id = programName + "-" + threadId + ">" + topic.name();
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
      client.write(this.id);
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
      println("Data reception timeout");
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
          data = Decoder.toInt(incomingBytes);
        } else if (dataClass == Float.class) {
          data = Decoder.toFloat(incomingBytes);
        } else if (dataClass == JSONObject.class) {
          data = Decoder.toJSONObject(incomingBytes);
        } else if (dataClass == PImage.class) {
          PImage dataTemp = Decoder.toPImage(parent, incomingBytes, 3);
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
        println("Unable to parse incoming data:\n" + e);
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

static HashMap<String, Class<?>> preffixDataClass = new HashMap<String, Class<?>>();

static {
  preffixDataClass.put("STR", String.class);
  preffixDataClass.put("INT", int.class);
  preffixDataClass.put("FLOAT", float.class);
  preffixDataClass.put("JSON", JSONObject.class);
  preffixDataClass.put("IMG", PImage.class);
}

// ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
// Encoder to convert different types of data to bytes
// ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

static class Encoder {

  static byte[] get(String text) {
    return text.getBytes();
  }

  static byte[] get(int value) {
    return new byte[] {(byte)(value >> 24), (byte)(value >> 16), (byte)(value >> 8), (byte)value};
  }

  static byte[] get(float value) {
    int intBits = Float.floatToIntBits(value);
    return new byte[] {(byte)(intBits >> 24), (byte)(intBits >> 16), (byte)(intBits >> 8), (byte)(intBits)};
  }

  static byte[] get(JSONObject json) {
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    try {
      baos.write(json.toString().getBytes("UTF-8"));
    }
    catch (IOException e) {
      e.printStackTrace();
    }
    return baos.toByteArray();
  }

  static byte[] get(PImage img, int channels) {
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

  /*static byte[] get(PImage img, float compression) throws IOException {
    ByteArrayOutputStream baos = new ByteArrayOutputStream();

    ImageWriter writer = ImageIO.getImageWritersByFormatName("jpeg").next();
    ImageWriteParam param = writer.getDefaultWriteParam();
    param.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
    param.setCompressionQuality(compression);

    // ImageIO.write((BufferedImage) img.getNative(), "jpg", baos);
    writer.setOutput(new MemoryCacheImageOutputStream(baos));

    writer.write(null, new IIOImage((BufferedImage) img.getNative(), null, null), param);

    return baos.toByteArray();
  }*/
}

// ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
// Decoder to convert bytes to different types of data
// ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬

static class Decoder {

  static String toString(byte[] bytes) {
    return new String(bytes);
  }

  static int toInt(byte[] bytes) {
    return (bytes[0] << 24) | ((bytes[1] & 0xFF) << 16) | ((bytes[2] & 0xFF) << 8) | (bytes[3] & 0xFF);
  }

  static float toFloat(byte[] bytes) {
    int intBits = bytes[0] << 24 | (bytes[1] & 0xFF) << 16 | (bytes[2] & 0xFF) << 8 | (bytes[3] & 0xFF);
    return Float.intBitsToFloat(intBits);
  }

  static JSONObject toJSONObject(byte[] bytes) {
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

  static PImage toPImage(PApplet parent, byte[] bytes, int channels) {
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

  /*static PImage toPImageJPEG(byte[] imgbytes) throws IOException, NullPointerException {
   BufferedImage bimg = ImageIO.read(new ByteArrayInputStream(imgbytes));
   PImage pimg = new PImage(bimg.getWidth(), bimg.getHeight(), RGB);
   bimg.getRGB(0, 0, pimg.width, pimg.height, pimg.pixels, 0, pimg.width);
   pimg.updatePixels();
   return pimg;
   }*/
}
