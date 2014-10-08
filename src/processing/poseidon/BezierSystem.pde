class BezierCurveSystem {
  ArrayList<BezierCurve> beziers;
  PShape group;
  
  BezierCurveSystem() {
    beziers = new ArrayList<BezierCurve>();
  }

  void addBezierCurve(BezierCurve bezier) {
    beziers.add(bezier);
  }
  
  void run() {
    for (int i = beziers.size()-1; i >= 0; i--) {
      BezierCurve b = beziers.get(i);
      if (!b.canStart())
        return;
        
      if (b.isDead()) {
        beziers.remove(i);
      }
      else {
        b.run(); 
      }
    }
  }
  
  void delay(long delay) {
    for (int i = beziers.size()-1; i >= 0; i--) {
      BezierCurve b = beziers.get(i);
      b.delay += delay;
    }
  }
}

