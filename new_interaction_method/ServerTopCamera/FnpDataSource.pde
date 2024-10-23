abstract class FnpDataSource {

  private long timePauseSource; // Time (ms) to pause this source after any topic was used for the last time
  private long timePauseTopic; // Time (ms) to pause the calculation of a topic after it was used for the last time
  private Map<String, Long> timesLastUse = new HashMap<String, Long>();

  FnpDataSource(long timePauseSource, long timePauseTopic) {
    assert timePauseSource >= timePauseTopic;
    this.timePauseSource = timePauseSource;
    this.timePauseTopic = timePauseTopic;
  }

  public void update() {
    boolean pause = true;
    for (long t : timesLastUse.values()) {
      if (System.currentTimeMillis() - t < timePauseSource) {
        pause = false;
        break;
      }
    }
    if (pause && isCapturing()) {
      stopCapture();
    } else if (!pause && !isCapturing()) {
      startCapture();
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
