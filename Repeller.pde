class Repeller{

	PVector location;
	int timer = 90;
	boolean alive = true;

	Repeller(PVector location_){
	  location = location_; // Initialize the ArrayList
	}

	void run(){
		display();
		timer--;
		if (timer < 0){
			alive = false;
		}
	}

	void display(){
    noStroke();
    fill(200,50);
    float t = constrain(map(timer,30,0,1,0),0,1);
    float radius = map(easeOutBounce(t),0,1,0,50);
    float offset = map(noise(frameCount * (location.x / 5000)),0,1,-3,3);
    float offset2 = map(noise(frameCount * (location.y / 5000)),0,1,-3,3);
    ellipse(location.x, location.y, radius + offset, radius + offset2);
	}

	PVector get(){
		return location;
	}
}