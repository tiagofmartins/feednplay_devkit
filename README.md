# feednplay_templates

To develop a Processing sketch to run in FeedNPlay, one of the following options is recommended:

```console
processing-java --sketch=/path/to/sketch/folder --run x=0 y=0 w=9720 h=1920
```

### Option 1

1. Download this repository;
2. Open the [examples_other/simple example/](/examples_other/basic_sketch);
3. Build your content from it.

```processing
void settings() {
  fnpSize(500, 500, P2D); // This line must the first one of settings()
  smooth(8);
  // Insert your settings code here
}

void setup() {
  frameRate(60);
  // Insert your setup code here
  fnpEndSetup(); // This line must the last one of setup()
}

void draw() {
  // Insert your draw code here
}
```

## Recommendations

### Loading data in Processing sketches properly

If your Processing sketch needs to load files or any data at startup, we recommend that you don't do it in the `setup()` function as it may take a few seconds and thus trigger a Processing timeout error (_RuntimeException: Waited 5000ms …_). Instead, we recommend that you load all the required data in the second drawing frame (not the first). To do this, you can adapt your `draw()` function based on the following code:

```processing
void draw() {
  if (frameCount <= 2) {
    if (frameCount == 2) {
      // Insert your load code here
    }
  } else {
    // Insert your draw code here
  }
}
```
