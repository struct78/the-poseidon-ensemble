public class LabelThread extends Thread {
   String label = "";
   ArrayList<Label> labels;
   
   LabelThread(ArrayList<Label> labels) {
     this.labels = labels;
   }
   
   void run() {
    try {
     for ( Label l : labels ) {
      label = l.date;
      Thread.sleep(l.delay);
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
