import org.openkinect.*;
import org.openkinect.processing.*;
import controlP5.*;
import java.util.Iterator;
ControlP5 controlP5;
// Global Settings

//turns off the Kinect sensing, uses the mouse as input
Boolean debugMode = true;

// Classes
KinectTracker tracker;
Kinect kinect;
Flock flock;
Repellers repellers;

// Kinect options
float force           = 0;
float baseForce       = 8;


// Display options
float xSize, ySize, x, y;
color pixelFill;
color backColor       = #343434;

// Flock settings
float globalSep       = 24.25;
float globalSpeed     = 5.02;
float globalTurning   = .18;
float globalCoherence = 4500.43;
float globalAlign     = 75.58;

//don't start off in correction mode
Boolean correctionMode = false;

PVector mouse;


void setup() {
  size(1024, 768, P2D);
  noStroke();
  frameRate(60);

  flock = new Flock();
  repellers = new Repellers();
  controlP5 = new ControlP5(this);

  mouse = new PVector();

  // controlP5.addSlider("Separation", 0, 50, globalSep, 10, 10, 200, 10);
  // controlP5.addSlider("Speed", 1, 8, globalSpeed, 10, 25, 200, 10);
  // controlP5.addSlider("Turning", .001, .300, globalTurning, 10, 40, 200, 10);
  // controlP5.addSlider("Coherence", 1, 5000, globalCoherence, 10, 55, 200, 10);
  // controlP5.addSlider("Alignment", 1, 175, globalAlign, 10, 70, 200, 10);

  //if we're not in debug mode, initialize the Kinect
  if (!debugMode){
    kinect = new Kinect(this);
  }

  tracker = new KinectTracker();

}

void draw() {
  fill(backColor, 50);
  rect(0, 0, width, height);
  
  mouse = new PVector(mouseX, mouseY);

  //if we're in correction mode
  if (correctionMode){
    fill(25);
    text(tracker.getModeName() + " Correction", 10, 20);
    text("Offset: " + tracker.getOffset(), 10, 35);
  }

  if(!debugMode){
    tracker.track();
    //only do stuff if we're actually tracking something
    if (tracker.tracking){
      float force = tracker.getForce(); 
      PVector position = tracker.getPos(); 
    }
  }  
  
  if (debugMode){
    force = baseForce;
  }

  flock.run();
  repellers.run();

  frame.setTitle(int(frameRate) + " fps");
}

//if we hit a key
void keyPressed() {
  
  //if we hit c, toggle between correction modes
  if (key == 'c') {
    int n = tracker.getCurrentMode();
    
    //toggle through our different adjustment modes
    n += 1;
    tracker.setCurrentMode(n);
    if (n <= 3){
      correctionMode = true;
    }
    
    //if we get past the last one, reset back to normal
    if (n > 3) {
      tracker.setCurrentMode(-1);
      correctionMode = false;
    }
  
  }

  if (key == 's') {
    save("normal.png");
    saveHiRes(3);
    exit();
  }


  if (correctionMode){
    if (key == CODED) {
      if (keyCode == UP || keyCode == RIGHT) {
        tracker.setOffset(1);
      } 
      else if (keyCode == DOWN || keyCode == LEFT) {
        tracker.setOffset(-1);
      }
    }
  }

  //make it easy to adjust our threshold
  if (!debugMode &&! correctionMode){
    int t = tracker.getThreshold();
    if (key == CODED) {
      if (keyCode == UP) {
        t+=1;
        println("Threshold: " + t);
        tracker.setThreshold(t);
      } 
      else if (keyCode == DOWN) {
        t-=1;
        println("Threshold: " + t);
        tracker.setThreshold(t);
      }
    }
  }
  
  //make it easy to adjust our force while debugging
  if (debugMode &&! correctionMode){
    if (key == CODED) {
      if (keyCode == UP) {
        baseForce += 1;
        println("baseForce: "+baseForce);
      } 
      else if (keyCode == DOWN) {
        baseForce -= 1;
        println("baseForce: "+baseForce);
      }
    }
  }
}

void mousePressed(){
  repellers.add(mouse);
}

// void mouseDragged(){
//   repellers.update(mouse);
// }

// void mouseReleased(){
//   repellers.clear();
// }

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isController()) { 
    if (theEvent.controller().name()=="Separation") {
      globalSep = theEvent.controller().value();
    }

    if (theEvent.controller().name()=="Speed") {
      globalSpeed = theEvent.controller().value();
      flock.changeValue();
    }

    if (theEvent.controller().name()=="Turning") {
      globalTurning = theEvent.controller().value();
      flock.changeValue();
    }

    if (theEvent.controller().name()=="Coherence") {
      globalCoherence = theEvent.controller().value();
    }
    
    if (theEvent.controller().name()=="Alignment") {
      globalAlign = theEvent.controller().value();
    }
  }
}

void saveHiRes(int scaleFactor) {
  PGraphics hires = createGraphics(width*scaleFactor, height*scaleFactor, JAVA2D);
  beginRecord(hires);
    hires.scale(scaleFactor);
    for (int i = 0; i < 5; ++i) {
      draw();
    }
  endRecord();
  hires.save("hires.png");
}

void stop() {
  tracker.quit();
  super.stop();
}

  
