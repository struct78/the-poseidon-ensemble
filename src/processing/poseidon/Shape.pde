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
  
  float getLifespanReduction() {
    return (1000/frameRate); 
  }
  
  float invert( float n, float min, float max ) {
    return (max+min)-n;
  }
  
  void kill() {
    this.kill = true;
  }
  
  void shortenLifespan(long index, long size) {
    float min = frameRate;
    float max = min*60;
    
    if (!hasShortenedLifespan) {
      if (index > 0) {
        currentLifespan = int(getLifespanReduction()*invert(map(index, 0, size, min, max), min, max));
        hasShortenedLifespan = true;
      }
    }
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

