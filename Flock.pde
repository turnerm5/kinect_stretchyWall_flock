// The Flock (a list of Boid objects)
PVector target;

class Flock {

  int resolution = 100;
  int numOfBoids = 600;
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
