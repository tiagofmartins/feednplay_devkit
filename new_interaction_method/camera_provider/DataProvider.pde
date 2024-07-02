import processing.net.*;
import java.util.Random;
import java.util.Map;

final String HOST = "127.0.0.1";
final int PORT = 23000;

class DataProvider {
  // https://github.com/processing/processing/tree/459853d0dcdf1e1648b1049d3fdbb4bf233fded8/java/libraries/net/src/processing/net

  private Server server;
  private Map<String, ArrayList<Client>> clientsByTopic = new HashMap<String, ArrayList<Client>>();
  private Map<String, Long> lastRequestTimeByTopic = new HashMap<String, Long>();
  private boolean newRequestReceived = false;
  
  DataProvider(PApplet parent) {
    server = new Server(parent, PORT);
  }

  public void run() {
    processIncomingRequests();
    replyToRequests();
  }

  private void processIncomingRequests() {
    // Go through available clients
    while (true) {

      // Get next client
      Client nextClient = server.available();
      if (nextClient == null) {
        break;
      }

      // Read topic name
      String receivedMessage = nextClient.readString();
      String receiverName = receivedMessage.split(":")[0];
      println(receiverName);
      String topic = receivedMessage.split(":")[1];
      
      // If this client is not yet in the queue for the requested topic, add it to the queue
      clientsByTopic.putIfAbsent(topic, new ArrayList<Client>());
      ArrayList<Client> clientsWaiting = clientsByTopic.get(topic);
      if (!clientsWaiting.contains(nextClient)) {
        clientsWaiting.add(nextClient);
      }
      
      // Register time to topic
      lastRequestTimeByTopic.put(topic, System.currentTimeMillis());
      
      newRequestReceived = true;
    }
  }

  private void replyToRequests() {
    // Nothing to do here if no requests exist
    if (!newRequestReceived) {
      return;
    }
    
    // iterate through each requested topic
    // and send data to the clients who requested it
    for (Map.Entry e : clientsByTopic.entrySet()) {
      String topic = (String) e.getKey();
      if (topic.equals("INT_RANDOM")) {
        for (Client c : clientsByTopic.get(topic)) {
          if (c.active()) {
            println("[replying] " + c);
            c.write(int(random(100)) + "");
          }
          clientsByTopic.remove(c);
        }
      } else if (topic.equals("STR_RANDOM")) {
        for (Client c : clientsByTopic.get(topic)) {
          if (c.active()) {
            println("[replying] " + c);
            c.write(getSaltString());
          }
          clientsByTopic.remove(c);
        }
      } else {
        println("Error: Unknown topic");
      }
    }
    
    newRequestReceived = false;
  }
}

String getCurrentSketchName() {
  return new File(sketchPath("")).getName();
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
