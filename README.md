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
Either way, we think the best approach is to select the code example or template that is most compatible with your idea and and use is as a starting point.

Why not start with the simplest example we have available? Take a look at the example  [`/examples_processing_sketches/sketch01_basic`](/examples_processing_sketches/sketch01_basic)