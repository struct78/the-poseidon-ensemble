import java.awt.Point;

public static class Geography {
  public static PVector CoordinatesToPVector(int width, int height, double latitude, double longitude) {
    double x = (width * (180 + longitude) / 360) % width;
    double radlat = latitude * Math.PI / 180;  // convert from degrees to radians
    double y = Math.log(Math.tan((radlat/2) + (PI/4)));  // do the Mercator projection (w/ equator of 2pi units)
    y = (height / 2) - (width * y / (2 * PI));   // fit it to our map   

    // Some have negative px values
    if (y < 0) {
      y = height+y;
    }
    return new PVector((float)x, (float)y);
  }
}

