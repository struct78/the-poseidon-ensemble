public class LabelThread extends Thread {
   String label = "";
   Date date;
   ArrayList<Label> labels;
   
   LabelThread(ArrayList<Label> labels) {
     this.labels = labels;
   }
   
   void run() {
    try {
     for ( Label l : labels ) {
      date = l.date;
      label = l.format.format(date);
      if (l.delay>1) {
        Thread.sleep(l.delay);
      }
     }
    }
    catch(Exception e){
      println(e);
    }
   }
  
  String getCurrentLabel() {
    return label;
  } 
  
  Date getDate() {
    return date;
  }
}
