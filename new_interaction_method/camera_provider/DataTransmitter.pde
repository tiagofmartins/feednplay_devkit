import processing.net.*;
import java.util.Random;
import java.util.Map;
import java.util.Iterator;
import java.io.*;
import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;

class DataTransmitter {
  
  private Server server;
  private Input input;
  private Map<String, ArrayList<Client>> clients = new HashMap<String, ArrayList<Client>>();
  public int requestsReceived = 0;
  public int requestsReplied = 0;

  DataTransmitter(PApplet parent, Input input, int port) {
    this.server = new Server(parent, port);
    this.input = input;
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
    //for (Map.Entry e : clientsByTopic.entrySet()) {
    Iterator<Map.Entry<String, ArrayList<Client>>> iterator = clients.entrySet().iterator();
    while (iterator.hasNext()) {
      Map.Entry<String, ArrayList<Client>> entry = iterator.next();
      String topic = (String) entry.getKey();

      byte[] data = null;
      if (input.hasTopic(topic)) {
        Object obj = input.getTopic(topic);
        if (obj instanceof String) {
          data = Encoder.stringToBytes((String) obj);
        } else if (obj instanceof Integer) {
          data = Encoder.integerToBytes((Integer) obj);
        } else if (obj instanceof Float) {
          data = Encoder.floatToBytes((Float) obj);
        } else if (obj instanceof JSONObject) {
          data = Encoder.jsonToBytes((JSONObject) obj);
        } else if (obj instanceof PImage) {
          data = Encoder.pimageToBytes((PImage) obj, 3);
        } else {
          System.err.println("ERROR - Unable to convert " + obj.getClass() + " to bytes");
          System.exit(1);
        }
      } else {
        System.err.println("ERROR - Unknown topic: " + topic);
      }

      if (data != null) {
        ArrayList<Client> clients = entry.getValue();
        for (Client c : clients) {
          if (c.active()) {
            c.write(data);
            requestsReplied += 1;
          }
        }
      }
      
      iterator.remove();
    }
  }
}
