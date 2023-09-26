# FeedNPlay devkit

In this repository you can find different examples and code templates that you can use to build new contents to be displayed on [FeedNPlay](https://feednplay.dei.uc.pt).

Currently, most of the dynamic content displayed on FeedNPlay is implemented in Processing. However, the idea is to expand the repository with more examples, possibly in other programming languages.

To automate the launch of each Processing sketch and its positioning on the large screen of FeedNPlay, it is necessary to use a pre-designed code template that follows the following structure:

```processing
void settings() {
  fnpSize(500, 500, P2D); // This line must the first one of settings()
  smooth(8);
  // ...
}

void setup() {
  // Do not use the width and height variables in the setup()
  // because the window size may change during its positioning
  frameRate(60);
  // ...
}

void draw() {
  if (frameCount == 2) {
    // Load files or data here if needed,
    // otherwise you can remove this condition
  } else {
    background(0);
    // ...
  }
}
```
We recommend that you download and use as a starting point the code example or template that is most compatible with the type of content you want to develop.

Why not start with the simplest example we have available? Take a look at the example [/examples_processing_sketches/simple sketch01_basic](/examples_processing_sketches/simple sketch01_basic).


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
