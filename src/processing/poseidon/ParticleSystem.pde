class ParticleSystem {
  ArrayList<Particle> particles;
  PShape group;
  long offset;
  
  ParticleSystem() {
    particles = new ArrayList<Particle>();
  }

  void addParticle(Particle particle) {
    particles.add(particle);
  }
  
  void run() {
    for (int i = particles.size()-1; i >= 0; i--) {
      Particle p = particles.get(i);
      
      if (!p.canStart())
        return;
        
      if (p.isDead()) {
        particles.remove(i);
      }
      else {
        p.run(); 
      }
    }
  }
}

