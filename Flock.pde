// The Flock (a list of Boid objects)
PVector target;

class Flock {

  int resolution = 20;
  int numOfBoids = 500;
  int cols = width / resolution;
  int rows = height / resolution;

  ArrayList<Boid> boids; // An ArrayList for all the boids
  ArrayList<Boid>[][] grid; // An grid of the boids

    Flock() {
    boids = new ArrayList<Boid>(); // Initialize the ArrayList



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
    
    // Every time through draw clear all the lists
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        grid[i][j].clear();
      }
    }

      // Register every boid object in the grid according to it's location
    for (Boid b : boids) {      
      int x = int(b.location.x) / resolution; 
      int y = int(b.location.y) / resolution;
      
      // It goes in 9 cells, i.e. every Boid is tested against other Boids in its cell
      // as well as its 8 neighbors 
      
      for (int n = -1; n <= 1; n++) {
        for (int m = -1; m <= 1; m++) {
          if (x+n >= 0 && x+n < cols && y+m >= 0 && y+m< rows) {
            grid[x+n][y+m].add(b);
            ArrayList<Boid> temp = grid[x+n][y+m];
            b.flock(temp);
          }
        }
      }
    }



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