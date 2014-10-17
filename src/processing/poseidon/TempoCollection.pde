public class TempoCollection {
  ArrayList<Tempo> tempos;
  TempoCollection() {
    tempos = new ArrayList<Tempo>();
  }

  void add(Tempo tempo) {
    tempos.add(tempo);
  }
  
  int getSpeed(Date date) {
   for (int i = 0 ; i < tempos.size(); i++) {
     Tempo tempo = tempos.get(i);
     Calendar calendar = Calendar.getInstance();
     calendar.setTime(date);
     if (calendar.get(Calendar.YEAR) >= tempo.startYear && calendar.get(Calendar.YEAR) <= tempo.endYear) {
       return tempo.speed;
     }
   } 
   return 1;
  }
  
  int getMaxObjects(Date date) {
   for (int i = 0 ; i < tempos.size(); i++) {
     Tempo tempo = tempos.get(i);
     Calendar calendar = Calendar.getInstance();
     calendar.setTime(date);
     if (calendar.get(Calendar.YEAR) >= tempo.startYear && calendar.get(Calendar.YEAR) <= tempo.endYear) {
       return tempo.maxObjects;
     }
   } 
   return 100;
  }
}
