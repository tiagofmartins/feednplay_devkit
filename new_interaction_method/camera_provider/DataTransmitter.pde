import processing.net.*;
import java.util.Random;
import java.util.Map;
import java.util.Iterator;
import java.io.*;
import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;

final String HOST = "127.0.0.1";
final int PORT = 23000;

class DataTransmitter {
  // https://github.com/processing/processing/tree/459853d0dcdf1e1648b1049d3fdbb4bf233fded8/java/libraries/net/src/processing/net

  private Server server;
  private Map<String, ArrayList<Client>> clientsByTopic = new HashMap<String, ArrayList<Client>>();
  public int requestsReceived = 0;
  public int requestsReplied = 0;
  private CameraInput cameraInput;

  DataTransmitter(PApplet parent) {
    server = new Server(parent, PORT);
    cameraInput = new CameraInput(parent);
  }

  public void run() {
    cameraInput.run();
    processIncomingRequests();
    replyToRequests();
  }

  private void processIncomingRequests() {
    // Go through available clients
    while (true) {
      Client nextClient = server.available();
      if (nextClient == null) {
        break;
      }

      // Read request text sent by current client
      String receivedMessage = nextClient.readStringUntil('\n');
      if (receivedMessage != null) {
        receivedMessage = receivedMessage.trim();
      } else {
        continue;
      }

      // Get topic requested by the client
      //String receiverName = receivedMessage.split(">")[0];
      String topic = receivedMessage.split(">")[1];

      // Add client to waiting queue of the requested topic only if it is not already there
      clientsByTopic.putIfAbsent(topic, new ArrayList<Client>());
      ArrayList<Client> clientsWaiting = clientsByTopic.get(topic);
      if (clientsWaiting.contains(nextClient) == false) {
        clientsWaiting.add(nextClient);
      }
      requestsReceived += 1;
    }
  }

  private void replyToRequests() {


    // Remova o elemento se o valor for menor que 3
    /*if (entry.getValue().size() < 3) {
     iterator.remove();
     }*/

    // Iterate through each requested topic
    //for (Map.Entry e : clientsByTopic.entrySet()) {
    Iterator<Map.Entry<String, ArrayList<Client>>> iterator = clientsByTopic.entrySet().iterator();
    while (iterator.hasNext()) {
      Map.Entry<String, ArrayList<Client>> entry = iterator.next();
      String topic = (String) entry.getKey();
      ArrayList<Client> clients = entry.getValue();

      // Get data for current topic
      byte[] data = null;
      if (topic.equals("INT_RANDOM")) {
        data = intToBytes(int(random(100)));
      } else if (topic.equals("STR_RANDOM")) {
        data = stringToBytes(getSaltString());
      } else if (topic.equals("JSON_TEST")) {
        JSONObject json = new JSONObject();
        json.setString("name", "Alice");
        json.setInt("age", int(random(1000)));
        data = JSONObjectToBytes(json);
      } else if (topic.equals("IMG_CAMTOP_RGB_720H")) {
        PImage img = cameraInput.getLastFrame();
        if (img != null) {
          data = PImageToBytes(img);
        }
      } else {
        println("Error: Unknown topic (" + topic + ")");
      }
      
      if (data != null) {
        for (Client c : clients) {
          if (c.active()) {
            c.write(data);
            requestsReplied += 1;
          }
        }
        iterator.remove();
      }

      // If data is not null, send it to the clients who requested it
      // and remove them from the waiting queue
      /*if (data != null) {
        ArrayList<Client> clientsWaiting = clientsByTopic.remove(topic);
        for (Client c : clientsWaiting) {
          if (c.active()) {
            c.write(data);
            requestsReplied += 1;
          }
        }
      }*/
    }
  }
}

protected String getSaltString() {
  String SALTCHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
  StringBuilder salt = new StringBuilder();
  Random rnd = new Random();
  while (salt.length() < 18) { // length of the random string.
    int index = (int) (rnd.nextFloat() * SALTCHARS.length());
    salt.append(SALTCHARS.charAt(index));
  }
  String saltStr = salt.toString();
  return saltStr;
}





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
