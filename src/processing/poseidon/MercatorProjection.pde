import java.awt.Point;

static class MercatorProjection {
  public static Point CoordinatesToPoint(int width, int height, double latitude, double longitude) {
    double x = (longitude+180)*(width/360);
    double y = (height/2)-(width*Math.log(Math.tan((PI/4)+((latitude*PI/180)/2)))/(TWO_PI));
    return new Point((int)x, (int)y); 
  }
}
