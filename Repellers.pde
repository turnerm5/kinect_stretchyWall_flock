class Repellers{

	ArrayList<Repeller> repellerArray; // An ArrayList for all the repellers
	
	Repellers(){
		repellerArray = new ArrayList<Repeller>(); // Initialize the ArrayList
	}

	void clear(){
	  repellerArray.clear();
	}

	void add(PVector location_){
	  if (repellerArray.size() < 10){
		  repellerArray.add(new Repeller(location_));
	  }
	}

	void run(){
		Iterator<Repeller> it = repellerArray.iterator();
		while (it.hasNext()){
			Repeller r = it.next();
			r.run();
			if (!r.alive){
				it.remove();
			}
		}		

	}

	ArrayList<PVector> get(){
		ArrayList<PVector> temp = new ArrayList<PVector>();
		for (Repeller r : repellerArray) {
			temp.add(r.get());
		}
		return temp;
	}

}