enum DisplayMode {
  RETINA(1f), TV(0.75f), BACKLIT_TV(0.5f);
  private float value;
  DisplayMode(float value) {
    this.value = value;
  }
  
  public float get() {
   return this.value; 
  }
}
