//import org.openkinect.*;
//import org.openkinect.processing.*;
import controlP5.*;
ControlP5 controlP5;
// Global Settings

//turns off the Kinect sensing, uses the mouse as input
Boolean debugMode = true;

// Classes
KinectTracker tracker;
//Kinect kinect;
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

void setup() {
  size(1024, 768);
  noStroke();
  frameRate(30);

  flock = new Flock();
  repellers = new Repellers();
  controlP5 = new ControlP5(this);

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
  fill(backColor, 80);
  rect(0, 0, width, height);
  
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

void mousePressed(){
  repellers.add(new PVector(mouseX, mouseY));
}

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

  
// The Boid class

class Boid {

  PVector location;
  PVector velocity;
  PVector acceleration;
  float r;
  float maxforce;    // Maximum steering force
  float maxspeed;    // Maximum speed

  Boid(float x, float y) {
    acceleration = new PVector(0, 0);
    velocity = PVector.random2D();
    location = new PVector(x, y);
    r = 3;
    maxspeed = globalSpeed;
    maxforce = globalTurning;
  }

  void run(ArrayList<Boid> boids) {
    
    update();
    borders();
    render();
  }

  void applyForce(PVector force) {
    // We could add mass here if we want A = F / M
    acceleration.add(force);
  }

  // We accumulate a new acceleration each time based on three rules
  void flock(ArrayList<Boid> boids, ArrayList<PVector> repellers_) {
    
    // repel(repellers.get());
    repel(repellers_);
    
    PVector sep = separate(boids);   // Separation
    PVector ali = align(boids);      // Alignment
    PVector coh = cohesion(boids);   // Cohesion
    // Arbitrarily weight these forces
    sep.mult(1.8);
    ali.mult(1.2);
    coh.mult(1.5);
    // Add the force vectors to acceleration
    applyForce(sep);
    applyForce(ali);
    applyForce(coh);
  }

  // Method to update location
  void update() {
    // Update velocity
    velocity.add(acceleration);
    // Limit speed
    velocity.limit(maxspeed);
    location.add(velocity);
    // Reset acceleration to 0 each cycle
    acceleration.mult(0);
  }

  // A method that calculates and applies a steering force towards a target
  // STEER = DESIRED MINUS VELOCITY
  PVector seek(PVector target) {
    // A vector pointing from the location to the target
    PVector desired = PVector.sub(target, location);  
    desired.setMag(maxspeed);
    // Steering = Desired minus Velocity
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxforce);  // Limit to maximum steering force
    return steer;
  }

  void render() {
    float theta = velocity.heading() - PI/2;
    fill(175,200);
    noStroke();
    pushMatrix();
      translate(location.x,location.y);
      rotate(theta);
      beginShape();
      fill(175,190);
      vertex(0, 2 * r);
      vertex(-r * sin((4 * PI ) / 3),r * cos((4 * PI) / 3));
      vertex(-r * sin((2 * PI ) / 3),r * cos((2 * PI) / 3));
      endShape(CLOSE);
    popMatrix();
  }

  void borders() {
    if (location.x < -r) location.x = width+r;
    if (location.y < -r) location.y = height+r;
    if (location.x > width+r) location.x = -r;
    if (location.y > height+r) location.y = -r;
  }

  void repel(ArrayList<PVector> repellers) {
    //go through each of our repellers
    for (PVector r : repellers) {
      PVector r_ = r.get();
      float repelFactor = 1200;
      PVector v = velocity.get();
      v.normalize();
      v.mult(75);
      v = PVector.add(location, v);
      r_.sub(v);
      float distance = r_.mag();
      r_.normalize();
      r_.mult((-1 * repelFactor / sq(distance)));
      acceleration.add(r_);
    }
  }

  // Separation
  // Method checks for nearby boids and steers away
  PVector separate (ArrayList<Boid> boids) {
    float desiredseparation = globalSep;
    PVector steer = new PVector(0, 0, 0);
    int count = 0;
    // For every boid in the system, check if it's too close
    for (Boid other : boids) {
      float d = PVector.dist(location, other.location);
      // If the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
      if ((d > 0) && (d < desiredseparation)) {
        // Calculate vector pointing away from neighbor
        PVector diff = PVector.sub(location, other.location);
        diff.normalize();
        diff.div(d);        // Weight by distance
        steer.add(diff);
        count++;            // Keep track of how many
      }
    }
    
    // Average -- divide by how many
    if (count > 0) {
      steer.div((float)count);
    }

    // As long as the vector is greater than 0
    if (steer.magSq() > 0) {
      steer.setMag(maxspeed);
      steer.mult(maxspeed);
      steer.sub(velocity);
      steer.limit(maxforce);
    }
    return steer;
  }

  // Alignment
  // For every nearby boid in the system, calculate the average velocity
  PVector align (ArrayList<Boid> boids) {
    float neighbordist = globalAlign;
    PVector sum = new PVector(0, 0);
    int count = 0;
    for (Boid other : boids) {
      float d = PVector.dist(location, other.location);
      if ((d > 0) && (d < neighbordist)) {
        sum.add(other.velocity);
        count++;
      }
    }
    if (count > 0) {
      sum.div((float)count);
      sum.setMag(maxspeed);
      PVector steer = PVector.sub(sum, velocity);
      steer.limit(maxforce);
      return steer;
    } 
    else {
      return new PVector(0, 0);
    }
  }

  // Cohesion
  // For the average location (i.e. center) of all nearby boids, calculate steering vector towards that location
  PVector cohesion (ArrayList<Boid> boids) {
    float neighbordist = globalCoherence;
    PVector sum = new PVector(0, 0);   // Start with empty vector to accumulate all locations
    int count = 0;
    for (Boid other : boids) {
      float d = PVector.dist(location, other.location);
      if ((d > 0) && (d < neighbordist)) {
        sum.add(other.location); // Add location
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      return seek(sum);  // Steer towards the location
    } 
    else {
      return new PVector(0, 0);
    }
  }
}
/*
 * Easing.pde - brings Robert Penner's easing functions into Processing
 * (c) 2015 cocopon.
 *
 * See the following to learn more about these famous functions:
 * http://www.robertpenner.com/easing/
 *
 * License:
 * http://www.robertpenner.com/easing_terms_of_use.html
 */

/*
 * Usage:
 *
 * 1. Put this file in the same folder as your sketch.
 *   + your_sketch/
 *   |-- your_sketch.pde
 *   |-- Easing.pde
 *   |-- ...
 *
 * 2. Enjoy!
 *   // Easier way to use an easing function
 *   // (t: 0.0 ~ 1.0)
 *   float value = easeOutBack(t);
 *   ...
 *
 *   // You can also instanciate an easing function
 *   Easing easing = new EasingOutBack();
 *   float value = easing.get(t);
 *   ...
 *
 *   // Or using an anonymous class to instanciate a custom easing function
 *   Easing easing = new Easing() {
 *     public float get(float t) {
 *       return sqrt(t);
 *     }
 *   };
 *   float value = easing.get(t);
 *   ...
 */

public interface Easing {
  public float get(float t);
}

public class EasingLinear implements Easing {
  public float get(float t) {
    return t;
  }
}

public class EasingInBack implements Easing {
  public float get(float t, float s) {
    return t * t * ((s + 1) * t - s);
  }

  public float get(float t) {
    return get(t, 1.70158);
  }
}

public class EasingInBounce implements Easing {
  public float get(float t) {
    t = 1.0 - t;

    if (t < 1 / 2.75) {
      return 1.0 - (7.5625 * t * t);
    }
    if (t < 2 / 2.75) {
      t -= 1.5 / 2.75;
      return 1.0 - (7.5625 * t * t + 0.75);
    }
    if (t < 2.5 / 2.75) {
      t -= 2.25 / 2.75;
      return 1.0 - (7.5625 * t * t + 0.9375);
    }

    t -= 2.625 / 2.75;
    return 1.0 - (7.5625 * t * t + 0.984375);
  }
}

public class EasingInCirc implements Easing {
  public float get(float t) {
    return -(sqrt(1 - t * t) - 1);
  }
}

public class EasingInCubic implements Easing {
  public float get(float t) {
    return t * t * t;
  }
}

public class EasingInElastic implements Easing {
  public float get(float t, float s) {
    float p = 0.3;
    float a = 1.0;

    if (t == 0) {
      return 0;
    }
    if (t == 1.0) {
      return 1.0;
    }

    if (a < 1.0) {
      a = 1.0;
      s = p / 4;
    }
    else {
      s = p / (2 * 3.1419) * asin(1.0 / a);
    }

    --t;
    return -(a * pow(2, 10 * t) * sin((t - s) * (2 * 3.1419) / p));
  }

  public float get(float t) {
    return get(t, 1.70158);
  }
}

public class EasingInExpo implements Easing {
  public float get(float t) {
    return (t == 0)
      ? 0 
      : pow(2, 10 * (t - 1));
  }
}

public class EasingInQuad implements Easing {
  public float get(float t) {
    return t * t;
  }
}

public class EasingInQuart implements Easing {
  public float get(float t) {
    return t * t * t * t;
  }
}

public class EasingInQuint implements Easing {
  public float get(float t) {
    return t * t * t * t * t;
  }
}

public class EasingInSine implements Easing {
  public float get(float t) {
    return -cos(t * (PI / 2)) + 1.0;
  }
}

public class EasingOutBack implements Easing {
  public float get(float t, float s) {
    --t;
    return t * t * ((s + 1.0) * t + s) + 1.0;
  }

  public float get(float t) {
    return get(t, 1.70158);
  }
}

public class EasingOutBounce implements Easing {
  public float get(float t) {
    if (t < 1 / 2.75) {
      return 7.5625 * t * t;
    }
    if (t < 2 / 2.75) {
      t -= 1.5 / 2.75;
      return 7.5625 * t * t + 0.75;
    }
    if (t < 2.5 / 2.75) {
      t -= 2.25 / 2.75;
      return 7.5625 * t * t + 0.9375;
    }

    t -= 2.625 / 2.75;
    return 7.5625 * t * t + 0.984375;
  }
}

public class EasingOutCirc implements Easing {
  public float get(float t) {
    --t;
    return sqrt(1 - t * t);
  }
}

public class EasingOutCubic implements Easing {
  public float get(float t) {
    --t;
    return t * t * t + 1;
  }
}

public class EasingOutElastic implements Easing {
  public float get(float t, float s) {
    float p = 0.3;
    float a = 1.0;

    if (t == 0) {
      return 0;
    }
    if (t == 1.0) {
      return 1.0;
    }

    if (a < 1.0) {
      a = 1.0;
      s = p / 4;
    }
    else {
      s = p / (2 * 3.1419) * asin(1.0 / a);
    }
    return a * pow(2, -10 * t) * sin((t - s) * (2 * 3.1419) / p) + 1.0;
  }

  public float get(float t) {
    return get(t, 1.70158);
  }
}

public class EasingOutExpo implements Easing {
  public float get(float t) {
    return (t == 1.0)
      ? 1.0
      : (-pow(2, -10 * t) + 1);
  }
}

public class EasingOutQuad implements Easing {
  public float get(float t) {
    return -t * (t - 2);
  }
}

public class EasingOutQuart implements Easing {
  public float get(float t) {
    --t;
    return 1.0 - t * t * t * t;
  }
}

public class EasingOutQuint implements Easing {
  public float get(float t) {
    --t;
    return t * t * t * t * t + 1;
  }
}

public class EasingOutSine implements Easing {
  public float get(float t) {
    return sin(t * (PI / 2));
  }
}

public class EasingInOutBack implements Easing {
  public float get(float t, float s) {
    float k = 1.525;

    t *= 2;
    s *= k;

    if (t < 1) {
      return 0.5 * (t * t * ((s + 1) * t - s));
    }
    t -= 2;
    return 0.5 * (t * t * ((s + 1) * t + s) + 2);
  }

  public float get(float t) {
    return get(t, 1.70158);
  }
}

public class EasingInOutBounce implements Easing {
  Easing inBounce_ = new EasingInBounce();
  Easing outBounce_ = new EasingOutBounce();

  public float get(float t) {
    return (t < 0.5)
      ? (inBounce_.get(t * 2) * 0.5)
      : (outBounce_.get(t * 2 - 1.0) * 0.5 + 0.5);
  }
}

public class EasingInOutCirc implements Easing {
  public float get(float t) {
    t *= 2;

    if (t < 1) {
      return -0.5 * (sqrt(1 - t * t) - 1);
    }

    t -= 2;
    return 0.5 * (sqrt(1 - t * t) + 1);
  }
}

public class EasingInOutCubic implements Easing {
  public float get(float t) {
    t *= 2;

    if (t < 1) {
      return 0.5 * t * t * t;
    }

    t -= 2;
    return 0.5 * (t * t * t + 2);
  }
}

public class EasingInOutElastic implements Easing {
  public float get(float t, float s) {
    float p =  0.3 * 1.5;
    float a = 1.0;

    if (t == 0) {
      return 0;
    }
    if (t == 1.0) {
      return 1.0;
    }

    if (a < 1.0) {
      a = 1.0;
      s = p / 4;
    }
    else {
      s = p / (2 * 3.1419) * asin(1.0 / a);
    }

    if (t < 1) {
      --t;
      return -0.5 * (a * pow(2, 10 * t) * sin((t - s) * (2 * 3.1419) / p));
    }
    --t;
    return a * pow(2, -10 * t) * sin((t - s) * (2 * 3.1419) / p) * 0.5 + 1.0;
  }

  public float get(float t) {
    return get(t, 1.70158);
  }
}

public class EasingInOutExpo implements Easing {
  public float get(float t) {
    if (t == 0) {
      return 0;
    }
    if (t == 1.0) {
      return 1.0;
    }

    t *= 2;
    if (t < 1) {
      return 0.5 * pow(2, 10 * (t - 1));
    }

    --t;
    return 0.5 * (-pow(2, -10 * t) + 2);
  }
}

public class EasingInOutQuad implements Easing {
  public float get(float t) {
    t *= 2;

    if (t < 1) {
      return 0.5 * t * t;
    }

    --t;
    return -0.5 * (t * (t - 2) - 1);
  }
}

public class EasingInOutQuart implements Easing {
  public float get(float t) {
    t *= 2;

    if (t < 1) {
      return 0.5 * t * t * t * t;
    }

    t -= 2;
    return -0.5 * (t * t * t * t - 2);
  }
}

public class EasingInOutQuint implements Easing {
  public float get(float t) {
    t *= 2;

    if (t < 1) {
      return 0.5 * t * t * t * t * t;
    }

    t -= 2;
    return 0.5 * (t * t * t * t * t + 2);
  }
}

public class EasingInOutSine implements Easing {
  public float get(float t) {
    return -0.5 * (cos(PI * t) - 1);
  }
}

Easing easeInBack__    = new EasingInBack();
Easing easeInBounce__  = new EasingInBounce();
Easing easeInCirc__    = new EasingInCirc();
Easing easeInCubic__   = new EasingInCubic();
Easing easeInElastic__ = new EasingInElastic();
Easing easeInExpo__    = new EasingInExpo();
Easing easeInQuad__    = new EasingInQuad();
Easing easeInQuart__   = new EasingInQuart();
Easing easeInQuint__   = new EasingInQuint();
Easing easeInSine__    = new EasingInSine();

Easing easeOutBack__    = new EasingOutBack();
Easing easeOutBounce__  = new EasingOutBounce();
Easing easeOutCirc__    = new EasingOutCirc();
Easing easeOutCubic__   = new EasingOutCubic();
Easing easeOutElastic__ = new EasingOutElastic();
Easing easeOutExpo__    = new EasingOutExpo();
Easing easeOutQuad__    = new EasingOutQuad();
Easing easeOutQuart__   = new EasingOutQuart();
Easing easeOutQuint__   = new EasingOutQuint();
Easing easeOutSine__    = new EasingOutSine();

Easing easeInOutBack__    = new EasingInOutBack();
Easing easeInOutBounce__  = new EasingInOutBounce();
Easing easeInOutCirc__    = new EasingInOutCirc();
Easing easeInOutCubic__   = new EasingInOutCubic();
Easing easeInOutElastic__ = new EasingInOutElastic();
Easing easeInOutExpo__    = new EasingInOutExpo();
Easing easeInOutQuad__    = new EasingInOutQuad();
Easing easeInOutQuart__   = new EasingInOutQuart();
Easing easeInOutQuint__   = new EasingInOutQuint();
Easing easeInOutSine__    = new EasingInOutSine();

float easeInBack(float t, float s) {
  return ((EasingInBack)easeInBack__).get(t, s);
}

float easeInBack(float t) {
  return easeInBack__.get(t);
}

float easeInBounce(float t) {
  return easeInBounce__.get(t);
}

float easeInCirc(float t) {
  return easeInCirc__.get(t);
}

float easeInCubic(float t) {
  return easeInCubic__.get(t);
}

float easeInElastic(float t, float s) {
  return ((EasingInElastic)easeInElastic__).get(t, s);
}

float easeInElastic(float t) {
  return easeInElastic__.get(t);
}

float easeInExpo(float t) {
  return easeInExpo__.get(t);
}

float easeInQuad(float t) {
  return easeInQuad__.get(t);
}

float easeInQuart(float t) {
  return easeInQuart__.get(t);
}

float easeInQuint(float t) {
  return easeInQuint__.get(t);
}

float easeInSine(float t) {
  return easeInSine__.get(t);
}

float easeOutBack(float t, float s) {
  return ((EasingOutBack)easeOutBack__).get(t, s);
}

float easeOutBack(float t) {
  return easeOutBack__.get(t);
}

float easeOutBounce(float t) {
  return easeOutBounce__.get(t);
}

float easeOutCirc(float t) {
  return easeOutCirc__.get(t);
}

float easeOutCubic(float t) {
  return easeOutCubic__.get(t);
}

float easeOutElastic(float t, float s) {
  return ((EasingOutElastic)easeOutElastic__).get(t, s);
}

float easeOutElastic(float t) {
  return easeOutElastic__.get(t);
}

float easeOutExpo(float t) {
  return easeOutExpo__.get(t);
}

float easeOutQuad(float t) {
  return easeOutQuad__.get(t);
}

float easeOutQuart(float t) {
  return easeOutQuart__.get(t);
}

float easeOutQuint(float t) {
  return easeOutQuint__.get(t);
}

float easeOutSine(float t) {
  return easeOutSine__.get(t);
}

float easeInOutBack(float t, float s) {
  return ((EasingInOutBack)easeInOutBack__).get(t, s);
}

float easeInOutBack(float t) {
  return easeInOutBack__.get(t);
}

float easeInOutBounce(float t) {
  return easeInOutBounce__.get(t);
}

float easeInOutCirc(float t) {
  return easeInOutCirc__.get(t);
}

float easeInOutCubic(float t) {
  return easeInOutCubic__.get(t);
}

float easeInOutElastic(float t, float s) {
  return ((EasingInOutElastic)easeInOutElastic__).get(t, s);
}

float easeInOutElastic(float t) {
  return easeInOutElastic__.get(t);
}

float easeInOutExpo(float t) {
  return easeInOutExpo__.get(t);
}

float easeInOutQuad(float t) {
  return easeInOutQuad__.get(t);
}

float easeInOutQuart(float t) {
  return easeInOutQuart__.get(t);
}

float easeInOutQuint(float t) {
  return easeInOutQuint__.get(t);
}

float easeInOutSine(float t) {
  return easeInOutSine__.get(t);
}
// The Flock (a list of Boid objects)
PVector target;

class Flock {

  int resolution = 100;
  int numOfBoids = 500;
  int cols = (int)width / resolution;
  int rows = (int)height / resolution;

  ArrayList<Boid> boids; // An ArrayList for all the boids
  ArrayList<Boid>[][] grid; // An grid of the boids

  Flock() {
    boids = new ArrayList<Boid>(numOfBoids); // Initialize the ArrayList
    
    grid = new ArrayList[cols][rows];
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        grid[i][j] = new ArrayList<Boid>();
      }
    }

    for (int i = 0; i < numOfBoids; i++) {
      addBoid(new Boid(width/2, height/2));
    }
  }
  
  void run() {
     
    //using bin-lattice spatial subdivision 

    // Every time through draw clear all the lists
    for (int i = 0; i < cols; i++) {
      stroke(100);
      // draw the lines, to help debug
      // line(i*resolution,0,i*resolution,height);
      for (int j = 0; j < rows; j++) {
        //draw the lines, to help debug
        // line(0,j*resolution,width,j*resolution);
        grid[i][j].clear();
      }
    }

    // Register every boid object in the grid according to its location
    for (Boid b : boids) {      
      int column = int(b.location.x) / resolution; 
      int row = int(b.location.y) / resolution;
      
      // It goes in 9 cells. An easy way for every boid to be tested against 
      // other Boids in its cell, as well as its 8 neighbors 
      
      for (int n = -1; n <= 1; n++) {
        for (int m = -1; m <= 1; m++) {
          if (column+n >= 0 && column+n < cols && row+m >= 0 && row+m< rows) {
            grid[column+n][row+m].add(b);
          }
        }
      }

      if (column >= 0 && column < cols && row >= 0 && row < rows) {
        
        // reduce the number of times our boids have to think.
        // thanks Craig Reynolds for the tip!

        if (frameCount % 2 == 0) {
          b.flock(grid[column][row], repellers.get());
        }
      }
      
      //
      b.run(boids);

    }
  
  }

  void addBoid(Boid b) {
    boids.add(b);
  }

  void changeValue() {
    for (Boid b : boids) {
      b.maxspeed = globalSpeed;
      b.maxforce = globalTurning;
    }
  }
}
class KinectTracker {
  
  // Size of kinect depth image
  int kw = 640;
  int kh = 480;
  
  //depth threshold
  int threshold = 790;
  
  //how hard is someone pushing into the screen?
  float force;  

  //what is the range of forces that are allowed?
  int minForce = 1;
  int maxForce = 5;

  //Are we tracking something?
  boolean tracking = false;

  // location of tracked point
  PVector[] locArray = new PVector[4];

  // Depth data
  int[] depth;
  
  //how much does the kinect tilt?
  float deg = 20;

  // how far past the trigger threshold can someone push in?
  int distancePastThreshold = 70;

  //a layer to nicely display our depth data
  PImage display;

  //misalignment correction settings
  int currentMode; // -1 = no correction
  int[] offset = {0,kh,0,kw};
  String[] mode = {"Top", "Bottom", "Left", "Right"};

  
  //Construct!

  KinectTracker() {
    
    if (!debugMode){
      kinect.start();
      kinect.enableDepth(true);
      kinect.tilt(deg);
      kinect.processDepthImage(false);
    }
    
    display = createImage(width,height,PConstants.RGB);

    for (int i = locArray.length - 1; i >= 0; i--){
      locArray[i] = new PVector(0,0);
    }

    //our screen correction variables
    correctionMode = false;
    currentMode = -1;

  }


  //primary functions

  void track() {
    
    //Main tracking function.
    //Finds closest point past a threshold
    //Returns nothing.
    
    //track where we found the deepest value
    int deepX = 0;
    int deepY = 0;

    // Get the raw depth as array of integers
    depth = kinect.getRawDepth();

    // Being overly cautious here
    if (depth == null) return;

    //reset our closest depth
    int depthMax = 99999;
    
    //default to false, unless we're tracking something
    tracking = false;    

    //for every value in the Kinect depth array.
    for(int x = 0; x < kw; x++) {
      for(int y = 0; y < kh; y++) {
        
        // Mirror the image
        int pixelOffset = kw-x-1+y*kw;
        
        // Grab the raw depth value
        int rawDepth = depth[pixelOffset];
        
        // Test against threshold
        if (rawDepth < threshold) {
          //if we found something, we're tracking!
          if (frameCount > 30){
            tracking = true;
          }
          
          //if it's the closest value, remember it, and its coordinates
          if (rawDepth < depthMax) {
            depthMax = rawDepth;
            deepY = y;
            deepX = x;
          }
        }
      }
    }

    force = threshold - depthMax;

    // If we found something...
    if (tracking) {
      
      //correct the location point for the misalignment of the kinect and proj.
      //should we be correcting the whole image, not just the point?
      //this will only work for one point.
      int correctedY = (int)map(deepY, offset[0], offset[1], 0, height);
      int correctedX = (int)map(deepX, offset[2], offset[3], 0, width);
      
      
      for (int i = locArray.length - 1; i > 0; i--){
        locArray[i] = locArray[i-1];
      }
      //save the location, corrected to the screen
      locArray[0] = new PVector(correctedX,correctedY);
    }
  }

  //super cool, but CPU intensive
  void display() {
    
    // Being overly cautious here
    if (!debugMode){
      if (depth == null) return;
    }

    //Load all of the displayed pixels
    display.loadPixels();
    
    for(int x = 0; x < display.width; x++) {
      for(int y = 0; y < display.height; y++) {
        
        //Running through all of the pixels on the big screen and getting 
        //their corresponding locations in the depth array
        int mappedX = (int)map(x,0,display.width,0,kw);
        int mappedY = (int)map(y,0,display.height,0,kh);

        // mirroring image
        int offset = kw-mappedX-1+mappedY*kw;
        
        if (!debugMode){
          // Raw depth
          int rawDepth = depth[offset];

          //What is the index of the pixel array?
          int pix = x + y * display.width;

          if (rawDepth < threshold) {

            int redValue = (int)map(rawDepth, threshold, threshold - distancePastThreshold, 0, 255);
            int greenValue = 0;
            int blueValue = (int)map(rawDepth, threshold, threshold - distancePastThreshold, 255, 0);


            display.pixels[pix] = color(redValue,greenValue,blueValue);

          } else {
            //A dark gray
            display.pixels[pix] = color(100);
          }
        }

        if (debugMode) {
          //What is the index of the pixel array?
          int pix = x + y * display.width;
          display.pixels[pix] = color(100);
        }
      }
    }
    
    //Always update the pixels at the end
    display.updatePixels();

    // Draw the image
    image(display,0,0);
  }


  //remaps the force, so when you push in more, the force returned is greater
  float getForce(){

    //remap
    force = map(force, 0, distancePastThreshold, minForce, maxForce);
    
    return force;
  }


  //utility functions

  PVector getPos() {
    
    //gets the average of the last 3 frames, to smooth things out

    int avgX = 0;
    int avgY = 0;

    for (int i=0; i < locArray.length; i++){
      avgX += locArray[i].x;
      avgY += locArray[i].y;
    }

    avgX = avgX / locArray.length;
    avgY = avgY / locArray.length;

    PVector loc = new PVector(avgX, avgY);
    return loc;

  }


  int getThreshold() {
    return threshold;
  }

  void setThreshold(int t) {
    threshold = t;
  }

  int getCurrentMode(){
    return currentMode;
  }

  void setCurrentMode(int m){
    currentMode = m;
  }

  String getModeName(){
    return mode[currentMode];
  }

  int getOffset(){
    return offset[currentMode];
  }

  void setOffset(int offsetChange){
    offset[currentMode] += offsetChange;
  }

  void quit() {
    kinect.quit();
  }
}
class Repellers{

	ArrayList<PVector> repellerArray; // An ArrayList for all the repellers
	int timer = 0;
	int timerLength = 500;

	Repellers(){
		  repellerArray = new ArrayList<PVector>(); // Initialize the ArrayList
	}

	void run(){
		display();
		if (timer < 1){
			clear();
		}
	}

	void display(){
	  for (PVector r : repellerArray) {
	    noStroke();
	    fill(80);
	    float t = constrain(map(timer,30,0,1,0),0,1);
	    float radius = map(easeOutBounce(t),0,1,0,50);
	    float offset = map(noise(frameCount * (r.x / 5000)),0,1,-12,12);
	    float offset2 = map(noise(frameCount * (r.y / 5000)),0,1,-12,12);
	    ellipse(r.x, r.y, radius + offset, radius + offset2);
	  }

	  timer -= 1;
	}

	void clear(){
	  repellerArray.clear();
	}

	void add(PVector location){
	  if (repellerArray.size() < 10){
		  repellerArray.add(location);
		  timer = timerLength;
	  }
	}

	ArrayList<PVector> get(){
		return repellerArray;
	}

}

