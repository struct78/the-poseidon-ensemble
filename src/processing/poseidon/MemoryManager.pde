public class MemoryManager {
  MemoryManager() {
    registerDraw(this);
  } 
  
  void draw() {
   if (millis()%5000==0) {
     System.gc(); 
   } 
  }
}
