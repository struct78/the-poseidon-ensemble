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
  PApplet parent;
  
  Note() {
  }
  
  void run() {
    try {
      // Open the MIDI Bus
      MidiBus bus = new MidiBus(parent, 1, "Poseidon");
      // Send the note
      bus.sendNoteOn(this.channel, this.pitch, this.velocity);
      // Sleep keep the note playing
      Thread.sleep((long)duration);
      // Stop playing the note
      bus.sendNoteOff(this.channel, this.pitch, this.velocity);
    }
    catch(Exception e){
      println(e);
    }
  }
}
