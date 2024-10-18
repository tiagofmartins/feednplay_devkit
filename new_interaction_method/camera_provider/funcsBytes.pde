static class ByteConverter {

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

  static byte[] PImageToBytes(PImage img, int channels) {
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
