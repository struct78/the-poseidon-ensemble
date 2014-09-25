class Note extends Thread {
  boolean interval;
  int channel;
  int velocity;
  int pitch;
  double duration;
  boolean isActive = true;
  String line;
  int index;
  int total;
  MidiBus bus;
  
  Note(MidiBus bus) {
    this.bus = bus;
  }
  
  void run() {
    try {
      // Open the MIDI Bus
      //MidiBus bus = new MidiBus(parent, 1, "Poseidon");
      // Send the note
      bus.sendNoteOn(channel, pitch, velocity);
      // Sleep keep the note playing
      Thread.sleep((long)duration);
      // Stop playing the note
      bus.sendNoteOff(channel, pitch, velocity);
    }
    catch(Exception e){
      println(e);
    }
  }
}
