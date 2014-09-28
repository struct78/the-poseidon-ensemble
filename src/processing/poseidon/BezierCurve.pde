public class BezierCurve {
  PVector a, b, m;
  long lifespan;
  boolean isStarted = false;
  color fill;
  int opacity;
  long delay;
  float progress;
  
  BezierCurve(PVector a, PVector b) {
    this.a = a;
    this.b = b;
    this.progress = 0;
  }
  
  void run() {
    if (millis() > delay) {
      if (!isStarted) {
        isStarted = true;
      }
      display();
    }
  }
  
  void display() {
    PVector m = PVector.lerp(a, b, 0.5f);
    PVector p = PVector.sub(a, b);
    PVector n = new PVector(-p.y, p.x);
    
    int l = (int)Math.sqrt((n.x*n.x)+(n.y*n.y));
    n.x /= l;
    n.y /= l;
    
    m = PVector.add(m, PVector.mult(n, PVector.dist(a, b)*0.1));
    

    float t = 0.1;
    float d1 = (float)Math.sqrt(Math.pow(m.x-a.x, 2) + Math.pow(m.y-a.y, 2));
    float d2 = (float)Math.sqrt(Math.pow(b.x-m.x, 2) + Math.pow(b.y-m.y, 2));
    
    float fa = t*d1/(d1+d2);
    float fb = t*d2/(d1+d2);
    
    PVector c = new PVector(m.x-fa*(b.x-a.x), m.y-fa*(b.y-a.y));
    PVector d = new PVector(m.x+fb*(b.x-a.x), m.y+fb*(b.y-a.y));
    
    
    noFill();
    stroke(fill, opacity);
    bezier(a.x, a.y, c.x, c.y, d.x, d.y, b.x, b.y);
    
    lifespan -= (1000/frameRate);
  }
  
  
  
  boolean isDead() {
    if (lifespan < 0.0) {
      return true;
    } else {
      return false;
    }
  }
}
