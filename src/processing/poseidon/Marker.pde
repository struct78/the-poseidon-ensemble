public class Marker extends Shape {
  PVector location;
  PVector offset;
  boolean expanding = true;
  float currentDiameter = 0;
  
 
  Marker(PVector location, PVector offset, float diameter) {
    this.location = location;
    this.offset = offset;
    this.diameter = diameter;
  }
  
  PVector getVector() {
    return new PVector(location.x+offset.x, location.y+offset.y); 
  }
  
  void update() {
    if (x < (diameter/2)) {
      if (currentDiameter >= diameter || currentDiameter < 0) {
        expanding = !expanding;
        if (!expanding) {
          x++;
        }
      }
      
      if (expanding) {
        currentDiameter+=(diameter*0.1);
      }
      else {
        currentDiameter-=(diameter*0.1);
      }
    }
    
    if (kill) {
      currentDiameter--;
    }
  }
    
  boolean isDead() {
    if (isStarted && kill && currentDiameter <= 0) {
      return true;
    } else {
      return false;
    }
  }
  
  void display() {
    translate(0, 0);
    ellipseMode(CENTER);
    
    PVector v = getVector();
    
    int z = 2;
    ellipse(v.x, v.y, z, z);
    
    while( z < 8 && z < currentDiameter) {
      noFill();
      stroke(fill, opacity);
      ellipse(v.x, v.y, z, z);
      z+=4;
    }
    
    noStroke();
    fill(fill, opacity);
    
    ellipse(v.x, v.y, currentDiameter, currentDiameter);
  }
}

class MarkerSystem extends ShapeCollection {

}

