import processing.net.*;
import java.util.Map;
import java.util.Iterator;
import java.nio.ByteBuffer;
import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.*;

class FnpDataServer {

  private Server server;
  private FnpDataSource source;
  private Map<String, ArrayList<Client>> clients = new HashMap<String, ArrayList<Client>>();
  public int requestsReceived = 0;
  public int requestsReplied = 0;

  FnpDataServer(PApplet parent, FnpDataSource source, int port) {
    this.server = new Server(parent, port);
    this.source = source;
  }

  public void update() {
    readIncomingRequests();
    replyToRequests();
  }

  private void readIncomingRequests() {
    // Go through available clients
    while (true) {
      Client client = server.available();
      if (client == null) {
        break;
      }

      // Read incoming message
      String incomingMessage = client.readStringUntil('\n');
      if (incomingMessage != null) {
        incomingMessage = incomingMessage.trim();
      } else {
        continue;
      }

      // Read topic
      String topic = incomingMessage.split(">")[1];
      //String clientName = incomingMessage.split(">")[0];

      // Add client to the list of clients that are requesting this topic
      clients.putIfAbsent(topic, new ArrayList<Client>());
      if (!clients.get(topic).contains(client)) {
        clients.get(topic).add(client);
      }
      requestsReceived += 1;
    }
  }

  private void replyToRequests() {
    // Iterate through each requested topic
    Iterator<Map.Entry<String, ArrayList<Client>>> iterator = clients.entrySet().iterator();
    while (iterator.hasNext()) {
      Map.Entry<String, ArrayList<Client>> entry = iterator.next();

      // Get value for current topic
      String topic = (String) entry.getKey();
      Object value = source.getTopic(topic);

      // Convert value to bytes based on its class
      byte[] bytes = null;
      if (value instanceof String) {
        bytes = Encoder.stringToBytes((String) value);
      } else if (value instanceof Integer) {
        bytes = Encoder.integerToBytes((Integer) value);
      } else if (value instanceof Float) {
        bytes = Encoder.floatToBytes((Float) value);
      } else if (value instanceof JSONObject) {
        bytes = Encoder.jsonToBytes((JSONObject) value);
      } else if (value instanceof PImage) {
        bytes = Encoder.pimageToBytes((PImage) value, 3);
      } else {
        System.err.println("ERROR - Invalid data class: " + (value != null ? value.getClass() : null));
        //System.exit(1);
      }

      // Send bytes to clients
      if (bytes != null) {
        ArrayList<Client> clients = entry.getValue();
        for (Client c : clients) {
          if (c.active()) {
            c.write(bytes);
            requestsReplied += 1;
          }
        }
      }

      // Remove clients from queue
      iterator.remove();
    }
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
