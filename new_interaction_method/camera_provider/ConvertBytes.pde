byte[] intToBytes(int value) {
  return new byte[] {(byte) (value >> 24), (byte) (value >> 16), (byte) (value >> 8), (byte) value};
}

byte[] stringToBytes(String text) {
  return text.getBytes();
}

byte[] JSONObjectToBytes(JSONObject json) {
  ByteArrayOutputStream baos = new ByteArrayOutputStream();
  try {
    baos.write(json.toString().getBytes("UTF-8"));
  }
  catch (IOException e) {
    e.printStackTrace();
  }
  return baos.toByteArray();
}

byte[] PImageToBytes(PImage img) {
  ByteArrayOutputStream baos = new ByteArrayOutputStream();
  try {
    ImageIO.write((BufferedImage) img.getNative(), "jpg", baos);
  }
  catch (IOException e) {
    e.printStackTrace();
  }
  return baos.toByteArray();
}

byte[] PImageToBytes2(PImage img, int channels) {
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
