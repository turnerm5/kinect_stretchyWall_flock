// The Boid class

class Boid {

  PVector location;
  PVector velocity;
  PVector acceleration;
  float r;
  float maxforce;    // Maximum steering force
  float maxspeed;    // Maximum speed
  color fillColor;

  Boid(float x, float y) {
    acceleration = new PVector(0, 0);
    velocity = PVector.random2D();
    location = new PVector(x, y);
    r = 2;
    maxspeed = globalSpeed;
    maxforce = globalTurning;

    fillColor = color(20);
  
  }

  void run() {
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
    PVector view = view(boids);      // View
    // Arbitrarily weight these forces
    sep.mult(1.8);
    ali.mult(1.2);
    coh.mult(1.5);
    view.mult(1.2);
    // Add the force vectors to acceleration
    applyForce(sep);
    applyForce(ali);
    applyForce(coh);
    applyForce(view);
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
    float expansion = constrain( map(velocity.mag(),4.0,8.0,0,10.0) ,0,10);
    fill(fillColor, 80);
    noStroke();
    pushMatrix();
      translate(location.x,location.y);
      rotate(theta);
      beginShape();
      vertex(0, 3 * r);
      vertex(-r * sin((4 * PI ) / 3) + expansion,r * cos((4 * PI) / 3));
      vertex(-r * sin((2 * PI ) / 3) - expansion,r * cos((2 * PI) / 3));
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
      
      int factor = 1;

      if (repel){
        factor *= -1;
        v.mult(75);
      } else {
        v.mult(20);
      }

      v = PVector.add(location, v);
      r_.sub(v);
      float distance = r_.mag();
      r_.normalize();
    

      r_.mult((factor * repelFactor / sq(distance)));
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

  // Alignment
  // For every nearby boid in the system, calculate the average velocity
  PVector view (ArrayList<Boid> boids) {
    
    float neighbordist = globalAlign;   
    PVector v = velocity.get();
    v.normalize();
    //a point 25 pixels out in front of the boid
    v.mult(8);
    
    int count = 0;
    
    for (Boid other : boids) {
      float d = PVector.dist(location, other.location);
      
      if ((d > 0) && (d < neighbordist)) {
        if (blockingView(v,other.location,5.0)) {
          PVector steer = velocity.get();
          
          int test = (int)random(-1,1);

          steer.rotate(HALF_PI * test);
          steer.limit(maxforce);
          return steer;
        }
      }
    }
    return new PVector(0, 0);
  }

  boolean blockingView(PVector a, PVector b, float diameter) {
    return (dist(a.x, a.y, b.x, b.y) < diameter * 0.5);
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