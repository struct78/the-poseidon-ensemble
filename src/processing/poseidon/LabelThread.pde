public class LabelThread extends Thread {
   String label = "";
   ArrayList<Label> labels;
   
   LabelThread(ArrayList<Label> labels) {
     this.labels = labels;
   }
   
   void run() {
    try {
     for ( Label l : labels ) {
      Thread.sleep(l.delay);
      label = l.date;
     }
    }
    catch(Exception e){
      println(e);
    }
   }
  
   String getCurrentLabel() {
     return label;
   } 
}
