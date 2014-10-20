public class Note extends Thread {
  int channel;
  int velocity;
  int pitch;
  double duration;
  int index;
  MidiBus bus;
  
  Note(MidiBus bus) {
    this.bus = bus;
  }
  
  void run() {
    try {
      // Send the note
      bus.sendNoteOn(channel, pitch, velocity);
      // Sleep keeps the note playing
      if (duration > 0) {
        this.sleep((long)duration);
      }
      // Stop playing the note
      bus.sendNoteOff(channel, pitch, velocity);
      
      if (index == lastIndex) {
        this.sleep(5000);
        isComplete = true;
      }
    }
    catch(Exception e){
      println(e);
    }
  }
}
