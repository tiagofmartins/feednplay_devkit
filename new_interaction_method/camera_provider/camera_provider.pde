DataProvider provider;

void setup() {
  size(333, 333);
  frameRate(60);
  provider = new DataProvider(this);
}

void draw() {
  provider.run();
}
