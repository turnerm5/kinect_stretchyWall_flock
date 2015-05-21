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
	    float offset = map(noise(frameCount * (r.x / 5000)),0,1,-3,3);
	    float offset2 = map(noise(frameCount * (r.y / 5000)),0,1,-3,3);
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

	void update(PVector location){
		repellerArray.clear();
		repellerArray.add(mouse);
	}

	ArrayList<PVector> get(){
		return repellerArray;
	}
}