class BezierCurveSystem {
  ArrayList<BezierCurve> BezierCurves;
  PShape group;
  
  BezierCurveSystem() {
    BezierCurves = new ArrayList<BezierCurve>();
  }

  void addBezierCurve(BezierCurve BezierCurve) {
    BezierCurves.add(BezierCurve);
  }
  
  void run() {
    for (int i = BezierCurves.size()-1; i >= 0; i--) {
      BezierCurve p = BezierCurves.get(i);
      p.run(); 
      
      if (p.isDead()) {
        BezierCurves.remove(i);
      }
    }
  }
  
  void delay(long delay) {
    for (int i = BezierCurves.size()-1; i >= 0; i--) {
      BezierCurve b = BezierCurves.get(i);
      b.delay += delay;
    }
  }
}

