import java.awt.Point;

static class MercatorProjection {
  public static Point CoordinatesToPoint(int width, int height, double latitude, double longitude) {
    double x = (width * (180 + longitude) / 360) % width;
    double radlat =latitude * Math.PI / 180;
    double y = Math.log(Math.tan((radlat/2) + (Math.PI/4)));
    y = (height/2) - (width * y / (2 * Math.PI));
    return new Point((int)x, (int)y); 
  }
}
