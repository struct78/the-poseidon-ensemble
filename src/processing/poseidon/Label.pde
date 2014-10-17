public class Label  {
  Date date;
  SimpleDateFormat format;
  long delay;
  
  Label(SimpleDateFormat format, Date date, long delay) {
    this.format = format;
    this.date = date;
    this.delay = delay;
  }
}
