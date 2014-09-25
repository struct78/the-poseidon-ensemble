class ParticleSystem {
  ArrayList<Particle> particles;
  PShape group;
  
  ParticleSystem() {
    particles = new ArrayList<Particle>();
  }

  void addParticle(Particle particle) {
    particles.add(particle);
  }
  
  void run() {
    for (int i = particles.size()-1; i >= 0; i--) {
      Particle p = particles.get(i);
      p.run(); 
      
      if (p.isDead()) {
        particles.remove(i);
      }
    }
  }
  
  void delay(long delay) {
    for (int i = particles.size()-1; i >= 0; i--) {
      Particle p = particles.get(i);
      p.delay += delay;
    }
  }
}

