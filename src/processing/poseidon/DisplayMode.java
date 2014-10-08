enum DisplayMode {
  RETINA(1f), TV(1.6f);
  private float value;
  DisplayMode(float value) {
    this.value = value;
  }
  
  public float get() {
   return this.value; 
  }
}
