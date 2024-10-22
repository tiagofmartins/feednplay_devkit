abstract class Input {

  private long timePauseInput; // Pause input if no topic has been requested for x milliseconds
  private long timePauseTopic; // Pause topic calculation if it has not been requested for x milliseconds
  private Map<String, Long> timesLastUse = new HashMap<String, Long>();

  Input(long timePauseInput, long timePauseTopic) {
    assert timePauseInput >= timePauseTopic;
    this.timePauseInput = timePauseInput;
    this.timePauseTopic = timePauseTopic;
  }

  public void update() {
    long timeLastUse = 0;
    for (long t : timesLastUse.values()) {
      if (t > timeLastUse) {
        timeLastUse = t;
      }
    }
    boolean recentlyUsed = System.currentTimeMillis() - timeLastUse < timePauseInput;
    boolean capturing = isCapturing();
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

  protected void updateLastTimeUse(String topic) {
    timesLastUse.put(topic, System.currentTimeMillis());
  }

  protected boolean topicIsNeeded(String topic) {
    if (timesLastUse.containsKey(topic)) {
      return System.currentTimeMillis() - timesLastUse.get(topic) < timePauseTopic;
    } else {
      return true;
    }
  }

  public <Any>Any getTopic(Enum topic) {
    return getTopic(topic.name());
  }

  public abstract <Any>Any getTopic(String topic);

  protected abstract void startCapture();

  protected abstract void stopCapture();

  protected abstract boolean isCapturing();
}
