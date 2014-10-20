public class Shape {
  PVector location;
  PVector offset;
  
  long lifespan;
  long currentLifespan;
  long delay;
  long timeOffset;
  int x = 0;
  boolean hasShortenedLifespan = false;
  boolean isStarted = false;
  boolean kill = false;
  color fill;
  float opacity;
  float diameter;
  
  Shape() {
    
  }
  
  boolean canStart() { 
   return (millis() > delay+timeOffset); 
  }
  
  void kill() {
    this.kill = true;
  }
  
  void run() {
    if (canStart()) {
      if (!isStarted) {
        currentLifespan = lifespan;
        isStarted = true;
      }
      
      display();
      update();
    }
  }
  
  void update() {
    // Do something
  }
  
  void display() {
    // Do something
  }
  
  boolean isDead() {
    // DO something
    return false;
  }
}

