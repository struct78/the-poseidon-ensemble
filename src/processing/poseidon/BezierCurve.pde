public class Bezier extends Shape {
  PVector a, b, m;
  
  Bezier(PVector a, PVector b) {
    this.a = a;
    this.b = b;
  }
  
  void display() {
    PVector m = PVector.lerp(a, b, 0.5f);
    PVector p = PVector.sub(a, b);
    PVector n = new PVector(-p.y, p.x);
    
    int l = int(sqrt((n.x*n.x)+(n.y*n.y)));
    n.x /= l;
    n.y /= l;
    
    m = PVector.add(m, PVector.mult(n, PVector.dist(a, b)*0.1));
    

    float t = 0.1;
    float d1 = sqrt(pow(m.x-a.x, 2) + pow(m.y-a.y, 2));
    float d2 = sqrt(pow(b.x-m.x, 2) + pow(b.y-m.y, 2));
    
    float fa = t*d1/(d1+d2);
    float fb = t*d2/(d1+d2);
    
    PVector c = new PVector(m.x-fa*(b.x-a.x), m.y-fa*(b.y-a.y));
    PVector d = new PVector(m.x+fb*(b.x-a.x), m.y+fb*(b.y-a.y));
    
    
    noFill();
    stroke(fill, opacity);
    bezier(a.x, a.y, c.x, c.y, d.x, d.y, b.x, b.y);
    
    currentLifespan -= (1000/frameRate);
    
    if (kill) {
      opacity--;
    }
  }
    
  boolean isDead() {
    if (isStarted && kill && opacity <= 0) {
      return true;
    } else {
      return false;
    }
  }
}

class BezierCollection extends ShapeCollection {
}
