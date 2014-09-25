public class QuakeTask extends TimerTask { 
 Thread thread;
 QuakeTask(Thread t) {
   this.thread = t;
 } 
 
 public void run() {
   thread.setDaemon(true);
   thread.start();
 }
}
