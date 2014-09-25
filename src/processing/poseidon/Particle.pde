public class Particle  {
  Point location;
  Point offset;
  color fill;
  int radius;
  int opacity;
  long start;
  int count;
  int totalKeyframes;
  int keyframes;
  boolean expanding = true;
  long delay;
  int x;
  int currentRadius;
  float lifespan;
 
  Particle(Point loc, Point off, int rad) {
    location = loc;
    offset = off;
    radius = rad;
    currentRadius = rad/2;
    count = 0;
    x = 0;
    lifespan = 1000;
  }
 
  void run() {
    if (millis() > delay) {
      update();
      display();
    }
  }
  
  void update() {
    if (x < totalKeyframes) {
      if (expanding) {
        currentRadius += (radius/keyframes);
      }
      else {
        currentRadius -= (radius/keyframes);
      }
      
      if (count > keyframes) {
        expanding = !expanding;
        count = 0;
      }
      count++; 
      x++; 
    }
    lifespan -= 1.0;
  }
  
  void display() {
    ellipseMode(CENTER);
    fill(this.fill, this.opacity);
    ellipse((int)location.x+offset.x, (int)location.y+offset.y, 1, 1);
    ellipse((int)location.x+offset.x, (int)location.y+offset.y, 2, 2);
    ellipse((int)location.x+offset.x, (int)location.y+offset.y, currentRadius, currentRadius);
  }
  
  boolean isDead() {
    if (lifespan < 0.0) {
      return true;
    } else {
      return false;
    }
  }
}
