public class MemoryManager {
  MemoryManager() {
    registerDraw(this);
  } 
  
  void draw() {
   if (millis()%10==0) {
     System.gc(); 
   } 
  }
}
