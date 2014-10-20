public class ShapeCollection {
  ArrayList<Shape> shapes;
  long numRendered = 0;
  
  ShapeCollection() {
    shapes = new ArrayList<Shape>();
  }

  void addShape(Shape shape) {
    shapes.add(shape);
  }
  
  void kill() {
    for (int i = shapes.size()-1; i >= 0; i--) {
      Shape s = shapes.get(i);
      s.kill();
    }
  }
  
  void run() {
    numRendered = 0;
    for (int i = shapes.size()-1; i >= 0; i--) {
      Shape s = shapes.get(i);
      if (!s.canStart())
        break;
        
      if (s.isDead()) {
        numRendered--;
        shapes.remove(i);
      }
      else {
        numRendered++;
        s.run(); 
      }
    }
  
    if (numRendered > MAX_SHAPES){
      int i = shapes.size()-1; 
      while(numRendered > MAX_SHAPES) {
        Shape s = shapes.get(i);
        s.kill();
        numRendered--;
        i--;
      }
    }
  }
}

