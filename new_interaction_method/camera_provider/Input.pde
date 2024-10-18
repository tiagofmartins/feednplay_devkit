abstract class Input {

  protected PApplet parent;
  protected boolean useRealData;
  private long timePauseInput;
  private long timePauseTopic;

  protected HashMap<String, Class> topicsAndClasses = new HashMap<String, Class>();
  protected HashMap<String, Long> topicsAndTimes = new HashMap<String, Long>();

  Input(PApplet parent, boolean useRealData, long timePauseInput, long timePauseTopic) {
    assert timePauseInput >= timePauseTopic;
    this.parent = parent;
    this.useRealData = useRealData;
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
  
  protected abstract <Any>Any getData(String topic);

  protected abstract void startCapture();

  protected abstract void stopCapture();

  protected abstract boolean isCapturing();

  void run() {
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
