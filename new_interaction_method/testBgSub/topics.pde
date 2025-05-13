class TopicsManager {

  private long recentUseLimit = 60000;
  private Map<String, Object> values = new HashMap<>();
  private Map<String, Class<?>> classes = new HashMap<>();
  private Map<String, Long> lastUse = new HashMap<>();

  TopicsManager() {
  }

  void setTopic(String topic, Class<?> expectedClass) {
    values.put(topic, null);
    classes.put(topic, expectedClass);
    lastUse.put(topic, 0L);
  }

  void setValue(String topic, Object value) {
    assert classes.containsKey(topic) : "Invalid topic: " + topic;
    if (value.getClass() != classes.get(topic)) {
      System.err.println("Incorrect type of value passed for topic: " + topic);
      System.exit(1);
    }
    values.put(topic, value);
  }

  <Any>Any getValue(String topic) {
    assert values.containsKey(topic) : "Invalid topic: " + topic;
    lastUse.put(topic, System.currentTimeMillis());
    Object value = values.get(topic);
    if (value != null) {
      return (Any) classes.get(topic).cast(value);
    } else {
      return null;
    }
  }

  long getTimeLastUse(String topic) {
    assert lastUse.containsKey(topic) :
    "Invalid topic: " + topic;
    return lastUse.get(topic);
  }

  boolean usedRecently(String topic) {
    return recentUseLimit <= 0 || System.currentTimeMillis() - getTimeLastUse(topic) < recentUseLimit;
  }

  boolean usedRecently(String... topics) {
    for (String t : topics) {
      if (usedRecently(t)) {
        return true;
      }
    }
    return false;
  }

  boolean usedRecentlyStartsWith(String topicBegin) {
    for (String t : values.keySet()) {
      if (t.startsWith(topicBegin) && usedRecently(t)) {
        return true;
      }
    }
    return false;
  }

  boolean anyTopicUsedRecently() {
    for (String t : values.keySet()) {
      if (usedRecently(t)) {
        return true;
      }
    }
    return false;
  }

  void setRecentUseLimit(long recentUseLimit) {
    this.recentUseLimit = recentUseLimit;
  }
}
