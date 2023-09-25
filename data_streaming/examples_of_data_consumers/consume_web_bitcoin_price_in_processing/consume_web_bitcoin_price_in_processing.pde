FnpDataReader reader;

void settings() {
  fnpSize(555, 222, JAVA2D);
  smooth(8);
}

void setup() {
  reader = new FnpDataReader("bitcoin_price_usd");
  reader.setReadingsPerSecond(1);
}

void draw() {
  JSONObject json = reader.getValueAsJSON("bitcoin_price_usd");
  float price = 0;
  if (json != null) {
    price = json.getFloat("value");
  }
  
  background(0);
  textAlign(CENTER, CENTER);
  textSize(height * 0.4);
  fill(255);
  text(price + "$", width * 0.5, height * 0.425);
}
