class Repellers{


	ArrayList<PVector> repellerArray; // An ArrayList for all the repellers
	int timer = 0;
	int timerLength = 300;

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
	    stroke(255);
	    noFill();

	    float t = constrain(map(timer,30,0,1,0),0,1);

	    float radius = map(easeOutBounce(t),0,1,0,50);

	    ellipse(r.x, r.y, radius, radius);
	  }
	  timer -= 1;
	}

	void clear(){
	  repellerArray.clear();
	}

	void add(PVector location){
	  repellerArray.add(location);
	  timer = timerLength;
	}

	ArrayList<PVector> get(){
		return repellerArray;
	}

}