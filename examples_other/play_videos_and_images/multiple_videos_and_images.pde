import processing.video.*;

ContentArea[] areas;
FnpMedia[] media;

void settings() {
  fnpSize(1500, 500, P2D);
  //fnpFullScreen(P2D);
}

void setup() {
  frameRate(60);
  background(0);
  
  areas = new ContentArea[9];
  for (int i = 0; i < areas.length; i++) {
    areas[i] = new ContentArea(new Rect(i * width / 9f, 0, width / 9f, height), 20, 20);
  }
  media = new FnpMedia[areas.length];
  media[0] = new FnpImg(this, areas[0], "diapositivo1.png", true);
  media[1] = new FnpVid(this, areas[1], "diapositivo2.mp4", true);
  media[2] = new FnpImg(this, areas[2], "diapositivo3.png", true);
  media[3] = new FnpVid(this, areas[3], "diapositivo4.mp4", true);
  media[4] = new FnpImg(this, areas[4], "diapositivo5.png", true);
  media[5] = new FnpVid(this, areas[5], "diapositivo6.mp4", true);
  media[6] = new FnpImg(this, areas[6], "diapositivo7.png", true);
  media[7] = new FnpImg(this, areas[7], "diapositivo8.png", true);
  media[8] = new FnpVid(this, areas[8], "diapositivo9.mp4", true);
  
  fnpEndSetup();
}

void draw() {
  // No need to clear window (slower) when the videos and images don't move
  //background(0);
  
  // Load media in the second frame to void the 5000ms timeout error
  if (frameCount == 2) {
    for (FnpMedia m : media) {
      m.loadFromDisk();
    }
  }
  
  for (FnpMedia m : media) {
    m.display();
  }
  for (ContentArea a : areas) a.preview(getGraphics());
  if (frameCount % 500 == 0) println(round(frameRate));
  
  println(((FnpVid) media[1]).finished());
}

void movieEvent(Movie m) {
  m.read();
}

/*
Implementar método que devolve o tempo que um dado conteudo esta a ser mostrado 
*/
