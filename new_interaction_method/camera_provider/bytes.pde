import java.nio.ByteBuffer;

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

  /*static byte[] pimageJPEGToBytes(PImage img, float compression) throws IOException {
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

  /*static PImage bytesToPImageJPEG(byte[] imgbytes) throws IOException, NullPointerException {
   BufferedImage bimg = ImageIO.read(new ByteArrayInputStream(imgbytes));
   PImage pimg = new PImage(bimg.getWidth(), bimg.getHeight(), RGB);
   bimg.getRGB(0, 0, pimg.width, pimg.height, pimg.pixels, 0, pimg.width);
   pimg.updatePixels();
   return pimg;
   }*/
}


/*static class TopicHelper {

  static HashMap<String, Class<?>> preffixDataClass = new HashMap<String, Class<?>>();

  static {
    preffixDataClass.put("STR", String.class);
    preffixDataClass.put("INT", Integer.class);
    preffixDataClass.put("FLOAT", Float.class);
    preffixDataClass.put("JSON", JSONObject.class);
    preffixDataClass.put("IMG", PImage.class);
  }

  static String getPreffix(String topic) {
    return topic.split("_")[0];
  }

  static Class<?> getClass(String topic) {
    String p = getPreffix(topic);
    return preffixDataClass.get(p);
  }

  static byte[] valueToBytes(String topic, Object value) {
    Class c = getClass(topic);
    if (c == String.class) {
      return Encoder.stringToBytes((String) value);
    } else if (c == Integer.class) {
      return Encoder.integerToBytes((Integer) value);
    } else if (c == Float.class) {
      return Encoder.floatToBytes((Float) value);
    } else if (c == JSONObject.class) {
      return Encoder.jsonToBytes((JSONObject) value);
    } else if (c == PImage.class) {
      return Encoder.pimageToBytes((PImage) value, 3);
    } else {
      return null;
    }
  }

  static <Any>Any bytesToValue(String topic, byte[] bytes) {
    //return output == null ? null : (Any) topicsAndClasses.get(topic).cast(output);
    return null;
  }
}
*/
