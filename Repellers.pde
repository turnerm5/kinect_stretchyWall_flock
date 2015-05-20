class Repellers{


	ArrayList<PVector> repellerArray; // An ArrayList for all the repellers

	Repellers(){
		  repellerArray = new ArrayList<PVector>(); // Initialize the ArrayList
	}

	void display(){
	  for (PVector r : repellerArray) {
	    stroke(255);
	    noFill();
	    ellipse(r.x, r.y, 50, 50);
	  }
	}

	void clear(){
	  repellerArray.clear();
	}

	void add(PVector location){
	  repellerArray.add(location);
	}

	ArrayList<PVector> get(){
		return repellerArray;
	}

}