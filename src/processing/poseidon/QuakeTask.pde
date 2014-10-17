public class QuakeTask extends TimerTask { 
 Thread thread;
 QuakeTask(Thread thread) {
   this.thread = thread;
 } 
 
 public void run() {
   thread.setDaemon(true);
   thread.start();
 }
}
