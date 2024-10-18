import processing.net.*;
import java.util.Random;
import java.util.Map;
import java.util.Iterator;
import java.io.*;
import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;

class DataTransmitter {
  // https://github.com/processing/processing/tree/459853d0dcdf1e1648b1049d3fdbb4bf233fded8/java/libraries/net/src/processing/net

  private Server server;
  private Map<String, ArrayList<Client>> clients = new HashMap<String, ArrayList<Client>>();
  public int requestsReceived = 0;
  public int requestsReplied = 0;
  private InputCameraTop topCamera;

  DataTransmitter(PApplet parent, int port, boolean useRealData) {
    server = new Server(parent, port);
    topCamera = new InputCameraTop(parent, useRealData);
  }

  public void run() {
    topCamera.run();
    readRequests();
    replyToRequests();
  }

  private void readRequests() {
    // Go through available clients
    while (true) {
      
      // Get next client available
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
    //for (Map.Entry e : clientsByTopic.entrySet()) {
    Iterator<Map.Entry<String, ArrayList<Client>>> iterator = clients.entrySet().iterator();
    while (iterator.hasNext()) {
      Map.Entry<String, ArrayList<Client>> entry = iterator.next();
      String topic = (String) entry.getKey();
      ArrayList<Client> clients = entry.getValue();

      // Get data for current topic
      byte[] data = null;
      if (topic.equals("INT_RANDOM")) {
        data = ByteConverter.intToBytes(int(random(100)));
      } else if (topic.equals("STR_RANDOM")) {
        data = ByteConverter.stringToBytes("HELLO " + frameCount);
      } else if (topic.equals("JSON_TEST")) {
        JSONObject json = new JSONObject();
        json.setString("name", "Alice");
        json.setInt("age", int(random(1000)));
        data = ByteConverter.JSONObjectToBytes(json);
      } else if (topic.equals("IMG_CAMTOP_RGB_720H")) {
        println(frameCount + " ----- IMG_CAMTOP_RGB_720H");
        //PImage img = topCamera.getLastFrame();
        PImage img = topCamera.getData("IMG_RGB");
        if (img != null) {
          data = ByteConverter.PImageToBytes(img, 3);
        }
      } else {
        println("Error: Unknown topic (" + topic + ")");
      }

      // If data is not null, send it to the clients who requested it
      // and remove them from the waiting queue
      if (data != null) {
        for (Client c : clients) {
          if (c.active()) {
            c.write(data);
            requestsReplied += 1;
          }
        }
        iterator.remove();
      }
    }
  }
}
