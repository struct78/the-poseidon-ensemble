public class Particle  {
  Point location;
  Point offset;
  color fill;
  int radius;
  float opacity;
  boolean expanding = true;
  long delay;
  int x = 0;
  int currentRadius = 0;
  long lifespan;
  long currentLifespan;
  boolean isStarted = false;
  long timeOffset;
  
 
  Particle(Point loc, Point off, int rad) {
    location = loc;
    offset = off;
    radius = rad;
  }
  
  PVector getVector() {
    return new PVector(location.x+offset.x, location.y+offset.y); 
  }
  
  boolean canStart() { 
   return (millis() > delay+timeOffset); 
  }
  
  void run() {
    if (canStart()) {
      if (!isStarted) {
        currentLifespan = lifespan;
        isStarted = true;
      }
      update();
      display();
    }
  }
  
  void update() {
    if (x < (radius/2)) {
      if (currentRadius >= radius || currentRadius < 0) {
        expanding = !expanding;
        if (!expanding) {
          x++;
        }
      }
      
      if (expanding) {
        currentRadius+=(radius*0.1);
      }
      else {
        currentRadius-=(radius*0.1);
      }
    }
    currentLifespan -= (1000/frameRate);
  }
  
  void display() {
    translate(0, 0);
    ellipseMode(CENTER);
    
    PVector v = getVector();
    noStroke();
    fill(fill, map(currentLifespan, 0, lifespan, 0, opacity));
    ellipse(v.x, v.y, 1, 1);
    ellipse(v.x, v.y, 2, 2);
    ellipse(v.x, v.y, 3, 3);
    ellipse(v.x, v.y, 4, 4);
    ellipse(v.x, v.y, currentRadius, currentRadius);
  }
  
  boolean isDead() {
    if (isStarted && currentLifespan < 0) {
      return true;
    } else {
      return false;
    }
  }
}
