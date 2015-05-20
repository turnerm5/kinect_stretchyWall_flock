import org.openkinect.*;
import org.openkinect.processing.*;


//turns off the Kinect sensing, uses the mouse as input
Boolean debugMode = true;

//don't start off in correction mode
Boolean correctionMode = false;

// Showing how we can farm all the kinect stuff out to a separate class
KinectTracker tracker;

// Kinect Library object
Kinect kinect;

float xSize, ySize, x, y;
color pixelFill;
color backColor = #343434;

float force;
float baseForce = 8;

float globalSep;
float globalSpeed;
float globalTurning;
float globalCoherence;
float globalAlign;

Flock flock;

ArrayList<PVector> repellerArray; // An ArrayList for all the repellers

void setup() {
  size(1024, 768);
  noStroke();

  flock = new Flock();

  //our flock settings
  globalSep = 24;
  globalSpeed = 7.93;
  globalTurning = .04477;
  globalCoherence = 228.43;
  globalAlign = 21.58;

  repellerArray = new ArrayList<PVector>(); // Initialize the ArrayList

  //if we're not in debug mode, initialize the Kinect
  if (!debugMode){
    kinect = new Kinect(this);
  }

  tracker = new KinectTracker();

  for (int i = 0; i < 500; i++) {
    flock.addBoid(new Boid(width/2, height/2));
  }

}

void draw() {
  
  background(backColor);
  
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

  displayRepellers();

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

  if (key == 's'){
    removeRepellers();
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
        println("Threshold: "+t);
        tracker.setThreshold(t);
      } 
      else if (keyCode == DOWN) {
        t-=1;
        println("Threshold: "+ t);
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

void displayRepellers(){
  for (PVector r : repellerArray) {
    stroke(255);
    noFill();
    ellipse(r.x, r.y, 50, 50);
  }
}

void removeRepellers(){
  repellerArray.clear();
}

void mousePressed(){
  repellerArray.add(new PVector(mouseX, mouseY));
  println("New repeller!");
  println("repellerArray.size(): "+repellerArray.size());
}

void stop() {
  tracker.quit();
  super.stop();
}

  
