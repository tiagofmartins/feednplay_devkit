# feednplay_templates

To develop a Processing sketch to run in FeedNPlay, one of the following options is recommended:

### Option 1

1. Download this repository;
2. Open the [examples_other/simple example/](/examples_other/basic_sketch);
3. Build your content from it.

<pre>
void settings() {
  <b>fnpSize(500, 500, P2D);</b> // This line must the first one of settings()
  smooth(8);
  // Insert settings code here
}

void setup() {
  frameRate(60);
  // Insert setup code here
  <b>fnpEndSetup();</b> // This line must the last one of setup()
}

void draw() {
  // Insert draw code here
}
</pre>

## Recommendations

### Loading data in Processing sketches properly

If your Processing sketch needs to load files or any data at startup, we recommend that you don't do it in the `setup()` function as it may take a few seconds and thus trigger a Processing timeout error (_RuntimeException: Waited 5000ms …_). Instead, we recommend that you load all the required data in the second drawing frame (not the first). To do this, you can adapt your `draw()` function based on the following code:

<pre>
void draw() {
  if (frameCount <= 2) {
    if (frameCount == 2) {
      // Insert load code here
    }
  } else {
    // Insert draw code here
  }
}
</pre>
