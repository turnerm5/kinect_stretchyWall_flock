// The Flock (a list of Boid objects)
PVector target;

class Flock {

  ArrayList<Boid> boids; // An ArrayList for all the boids
  
    Flock() {
    boids = new ArrayList<Boid>(); // Initialize the ArrayList

  }

  void run() {
    for (Boid b : boids) {
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