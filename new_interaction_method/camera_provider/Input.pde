abstract class Input {

  protected PApplet parent;
  protected boolean useRealData;
  private long timePauseInput;
  private long timePauseTopic;

  protected HashMap<String, Class> topicsAndClasses = new HashMap<String, Class>();
  protected HashMap<String, Long> topicsAndTimes = new HashMap<String, Long>();

  Input(PApplet parent, boolean useRealData, long timePauseInput, long timePauseTopic) {
    this.parent = parent;
    this.useRealData = useRealData;
    assert timePauseInput >= timePauseTopic;
    this.timePauseInput = timePauseInput;
    this.timePauseTopic = timePauseTopic;
  }

  protected void addTopic(String t, Class c) {
    topicsAndClasses.put(t, c);
    topicsAndTimes.put(t, -Long.MAX_VALUE);
  }

  protected boolean needCalculation(String topic) {
    return System.currentTimeMillis() - topicsAndTimes.get(topic) < timePauseTopic;
  }

  protected long getTimeLastUseOfAnyTopic() {
    long timeMax = 0;
    for (long t : topicsAndTimes.values()) {
      if (t > timeMax) {
        timeMax = t;
      }
    }
    return timeMax;
  }

  protected <Any>Any getTopic(Topic topic) {
    return getTopic(topic.name());
  }

  protected abstract <Any>Any getTopic(String topic);

  protected abstract void startCapture();

  protected abstract void stopCapture();

  protected abstract boolean isCapturing();

  public void update() {
    boolean capturing = isCapturing();
    boolean recentlyUsed = System.currentTimeMillis() - getTimeLastUseOfAnyTopic() < timePauseInput;
    if (capturing) {
      if (!recentlyUsed) {
        stopCapture();
      }
    } else {
      if (recentlyUsed) {
        startCapture();
      }
    }
  }

  public boolean hasTopic(String topic) {
    return topicsAndClasses.containsKey(topic);
  }

  public String getTopicsInfo() {
    String info = "";
    for (HashMap.Entry<String, Class> t : topicsAndClasses.entrySet()) {
      String topicName = t.getKey();
      Class topicClass = t.getValue();
      info += "[" + topicName + " : " + topicClass.getSimpleName() + "]";
    }
    return info;
  }
}
