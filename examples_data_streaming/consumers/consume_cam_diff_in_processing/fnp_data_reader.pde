/*
 ┌──────────────────────────────────────────────────────────┐
 │ FeedNPlay                                     2023.07.26 │
 │ Code that allows the easy use of data that comes from    │
 │ different sources (e.g. sensors, cameras or web).        │
 │ This data is streamed by a Kafka server, enabling the    │
 │ use of the same data by many contents simultaneously.    │
 │ Please DO NOT change any of the code below.              │
 │ If you have any suggestions or special requests          │
 │ please contact the FeedNPlay team. We will be happy      │
 │ to improve the system for you and all users.             │
 └──────────────────────────────────────────────────────────┘
 */

import java.util.Arrays;
import java.util.Properties;
import java.time.Duration;
import java.io.ByteArrayInputStream;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;
import java.util.concurrent.locks.ReentrantLock;

class FnpDataReader implements Runnable {

  private static final String KAFKA_SERVER_HOST_AND_PORT = "localhost:9092";
  private static final float DEFAULT_READINGS_PER_SECOND = 30;

  private String[] topics;
  private Object[] values;
  private long[] timestamps;
  
  private KafkaConsumer<String, Object>[] consumers;
  private boolean[] expectImage;
  private long[] lastReading;
  private ReentrantLock[] locks;
  
  private float readingsPerSecond = DEFAULT_READINGS_PER_SECOND;
  private int pollTimeout;
  private Thread thread = new Thread(this);
  private boolean receivedAnyRecord = false;
  
  FnpDataReader(String... topics) {
    // Set array with topics to consume
    if (topics.length == 0) {
      throw new RuntimeException("No topics passed.");
    }
    this.topics = topics;

    // Create other arrays (same length as the array of topics)
    values = new Object[topics.length];
    timestamps = new long[topics.length];
    consumers = new KafkaConsumer[topics.length];
    expectImage = new boolean[topics.length];
    lastReading = new long[topics.length];
    locks = new ReentrantLock[topics.length];

    // For each passed topic
    for (int t = 0; t < topics.length; t++) {

      // Check if this topic expects values which are images
      expectImage[t] = topics[t].contains("_rgb_") || topics[t].contains("_grayscale_");

      // Create Kafka consumer
      Properties props = new Properties();
      props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, KAFKA_SERVER_HOST_AND_PORT);
      props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
      props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, expectImage[t] ? ByteArrayDeserializer.class : StringDeserializer.class);
      props.put(ConsumerConfig.GROUP_ID_CONFIG, "consumer_" + System.nanoTime());
      consumers[t] = new KafkaConsumer<>(props);
      consumers[t].subscribe(Arrays.asList(topics[t]));
      
      locks[t] = new ReentrantLock();
    }
    
    // Set how long each consumer will wait for messages before returning an empty response.
    // This value is calculated by dividing the target maximum number of readings per second by the number of consumers.
    pollTimeout = (int) Math.floor(1000 / 60f / (float) consumers.length);
  }

  void run() {
    while (true) {
      
      // For each topic to be consumed
      for (int t = 0; t < topics.length; t++) {

        // Get new records.
        // Even if it is not necessary to read new values (due to the target number of readings per second),
        // we have to discard accumulated records.
        ConsumerRecords<String, Object> records = consumers[t].poll(Duration.ofMillis(pollTimeout));

        // Continue to next topic if it is not necessary to read new values
        if ((System.currentTimeMillis() - lastReading[t]) < (1000 / (float) readingsPerSecond)) {
          continue;
        }

        // Get most recent record
        ConsumerRecord<String, Object> lastRecord = null;
        for (ConsumerRecord<String, Object> r : records) {
          lastRecord = r;
        }
        
        // Continue to next topic if no record was found for current topic
        if (lastRecord == null) {
          continue;
        }
        
        // Parse record value to PImage or JSON
        Object value = null;
        if (expectImage[t]) {
          PImage pImage = null;
          try {
            byte[] imageBytes = (byte[]) lastRecord.value();
            ByteArrayInputStream bais = new ByteArrayInputStream(imageBytes);
            BufferedImage bi = ImageIO.read(bais);
            pImage = new PImage(bi.getWidth(), bi.getHeight(), RGB);
            bi.getRGB(0, 0, pImage.width, pImage.height, pImage.pixels, 0, pImage.width);
            pImage.updatePixels();
            value = pImage;
          }
          catch(IOException e) {
            System.err.println("Unable to create image from buffer");
            e.printStackTrace();
          }
        } else {
          JSONObject json = parseJSONObject((String) lastRecord.value());
          value = json;
        }

        // Update value and timestamp of current topic
        locks[t].lock();
        try {
          values[t] = value;
          timestamps[t] = lastRecord.timestamp();
        }
        finally {
          locks[t].unlock();
        }
        
        // Save current time to achieve the target number of readings per second
        lastReading[t] = System.currentTimeMillis();

        // Signal that a record has already been received
        if (!receivedAnyRecord) {
          receivedAnyRecord = true;
        }
      }
    }
  }

  /*───────────────────────────────────────────────────────────────────────────┐
   │ Methods to return the value of a topic.                                   │
   │ When no topic is provided, the value of the first topic will be returned. │
   └───────────────────────────────────────────────────────────────────────────*/

  Object getValue(String... topic) {
    if (topic.length > 1) {
      throw new IllegalArgumentException("This method expects zero or one argument");
    }

    // Start thread if it is not yet running
    if (!thread.isAlive()) {
      thread.start();
    }

    // Return value of the passed topic
    int topicIndex = topic.length == 0 ? 0 : getTopicIndex(topic[0]);
    locks[topicIndex].lock();
    try {
      return values[topicIndex];
    }
    finally {
      locks[topicIndex].unlock();
    }
  }

  PImage getValueAsPImage(String... topic) {
    return (PImage) getValue(topic);
  }

  JSONObject getValueAsJSON(String... topic) {
    return (JSONObject) getValue(topic);
  }

  /*──────────────────────────────────────────────────────────────────────────┐
   │ Methods to return the time of the last value of a topic.                 │
   │ When no topic is provided, the time of the first topic will be returned. │
   └──────────────────────────────────────────────────────────────────────────*/

  long getValueTime(String... topic) {
    if (topic.length > 1) {
      throw new IllegalArgumentException("This method expects zero or one argument");
    }

    // Start thread if it is not yet running
    if (!thread.isAlive()) {
      thread.start();
    }

    // Return timestamp of the last value of the passed topic
    int topicIndex = topic.length == 0 ? 0 : getTopicIndex(topic[0]);
    locks[topicIndex].lock();
    try {
      return timestamps[topicIndex];
    }
    finally {
      locks[topicIndex].unlock();
    }
  }

  long getValueAge(String... topic) {
    return System.currentTimeMillis() - getValueTime(topic);
  }

  boolean receivedAnyRecord() {
    return receivedAnyRecord;
  }

  /*─────────────┐
   │ Set methods │
   └─────────────*/

  void setReadingsPerSecond(float readingsPerSecond) {
    this.readingsPerSecond = readingsPerSecond;
  }

  /*──────────────────┐
   │ Internal methods │
   └──────────────────*/

  private int getTopicIndex(String topic) {
    for (int t = 0; t < topics.length; t++) {
      if (topics[t].equals(topic)) {
        return t;
      }
    }
    throw new RuntimeException("Topic '" + topic + "' not found.");
  }
}
