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
    Iterator<Map.Entry<String, ArrayList<Client>>> iterator = clients.entrySet().iterator();
    while (iterator.hasNext()) {
      Map.Entry<String, ArrayList<Client>> entry = iterator.next();

      // Get value for current topic
      String topic = (String) entry.getKey();
      Object value = input.getTopic(topic);

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
        System.err.println("ERROR - Unable to convert " + (value != null ? value.getClass(): null) + " to bytes");
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
