import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;
import java.util.Arrays;
import java.text.SimpleDateFormat;
import java.awt.Rectangle;
import java.awt.geom.Point2D;
import java.awt.Point;
import themidibus.*;

boolean isFullScreen = false;
int width;
int height;
int padding = 50;
int circlekeyframes = 3;
long speed = 10000;

Table table;

String dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS";
Date d1, d2;

String date, previousDate;
SimpleDateFormat format = new SimpleDateFormat(dateFormat);


Timer timer = new Timer();
long start, delay, elapsed;
long startOffset = 5000; // 5 second delay

// CSV
double latitude, longitude, depth, magnitude, dmin;

ArrayList<QuakeTask> tasks = new ArrayList();
QuakeTask task;
Note note;

ArrayList<Rectangle> grid = new ArrayList();
ArrayList<Integer> colours = new ArrayList();
ArrayList<Effect> effects = new ArrayList();

Particle circle;
ParticleSystem ps;

int scaleFactor = 10;

void setup() {
  width = displayWidth;
  height = displayHeight;
  size(width, height);
  
  // Colours are seasonal
  // Left -> Right = January - December
  colours.addAll(Arrays.asList(#e31826, #881832, #942aaf, #ce1a9a, #ffb93c, #00e0c9, #234baf, #47b1de, #b4ef4f, #26bb12, #3fd492, #f7776d));

  // Effects rack
  // Cello Section 
  effects.add(new Effect(1, 1f, 0.05)); 
  // Doule Bass Section Pizzicato / Cello Solo Staccato
  effects.add(new Effect(2, 0.75, 0.2)); 
  // Double Bass Section / Bb Clarinet Section Legato LE
  effects.add(new Effect(3, 0.75, 0.75)); 
  // Violin Solo
  effects.add(new Effect(4, 0.9, 0.4)); 
  // Double Bass Solo LE
  effects.add(new Effect(5, 0.9, 0.2)); 
  // Glockenspiel
  effects.add(new Effect(9, 1f, 0.4)); 
  
  // Set the delay between notes
  // We start after 5 seconds
  delay = startOffset;
  
  // Create the particle system
  ps = new ParticleSystem();
  
  for ( int i = 0; i <= 360; i+=90) {
    // Northern hemisphere
    grid.add(new Rectangle(i, 0, 90, 90));
    //Southern Hemisphere
    grid.add(new Rectangle(i, 90, 90, 90));
  }
  
  // Load the data
  table = loadTable("quakes.csv", "header");
  
  // Start timestamp
  start = millis();
  
  int x = 0;
  int count = table.getRowCount();
  
  for (TableRow row : table.rows()) {
    // Extract the data
    date = row.getString("time");
    latitude = row.getDouble("latitude");
    longitude = row.getDouble("longitude");
    depth = row.getDouble("depth");
    magnitude = row.getDouble("mag");
    dmin = row.getDouble("dmin");
  
    // On the first iteration previousDate will be null
    if (previousDate == null) {
      previousDate = date;
    }
    
    try {
      d1 = format.parse(previousDate);
      d2 = format.parse(date);
      
      // Diff in milliseconds
      long diff = d2.getTime() - d1.getTime();
      
      // Increase the delay
      delay += diff/speed;
      
      // Create the note
      note = new Note();
      // Each instrument/section represents 1/8th of the globe
      note.channel = getChannelFromCoordinates(latitude, longitude); 
      // How hard the note is hit
      note.velocity = (int)map((float)depth, 0, 1000, 127, 1); 
      // Pitch of the note
      note.pitch = (int)map((float)magnitude, 0, 10, 108, 21); 
      // MidiBus needs an applet as its parent
      note.parent = this; 
      // Note index. For debugging purposes only
      note.index = x; 
      // Total number of notes. For debugging purposes only.
      note.total = count; 
      // Add effects
      note = processEffects(note); 
      
      // Sometimes dmin is null so just default to 1
      if (Double.isNaN(dmin)) {
        dmin = 1d;
      }
      // How long the note is played for, on some instruments this makes no difference
      note.duration = map((float)magnitude, 2, 10, 50, 500) * scaleFactor;
      
      // Add the note to a task schedule
      task = new QuakeTask(note);
      timer.schedule(task, delay);
      tasks.add(task);
      
      // Drawing task
      // This draws a circle where the earthquake originated from
      Point point = MercatorProjection.CoordinatesToPoint(width-(padding*2), height-(padding*2), latitude, longitude);
      
      // Get the colour from the month
      color fill = getColourFromMonth(d2.getMonth());
      Point offset = new Point(padding, padding);
      
      // Exponential radius
      int radius = (int)(pow((float)magnitude, 2.2)/TWO_PI);
      
      // Create the particle
      circle = new Particle(point, offset, radius);
      // Colour
      circle.fill = fill;
      // Opacity is determined by depth. Lower = less opaque.
      circle.opacity = (int)map((float)depth, 0, 1000, 60, 20);
      // When the circle appears
      circle.delay = delay;
      // Number of keyframes per cycle. Lower = quicker.
      circle.keyframes = circlekeyframes;
      // Exponential length of animation
      circle.totalKeyframes = circlekeyframes*(int)(pow((float)magnitude, 3)/TWO_PI);
      
      // Add the particle to the particle system
      ps.addParticle(circle);
      
      // Major/Great earthquakes
      // Low drone/kick
      if (magnitude >= 6) {
        note = new Note();
        note.channel = 8;
        note.velocity = 127;
        note.pitch = 36;
        note.duration = 200;
        note.parent = this;
        note.index = x;
        note.total = count;
     
        note = processEffects(note);
        
        task = new QuakeTask(note);
        timer.schedule(task, delay);
        tasks.add(task);
      }
      
      // Shallow earthquake
      // Glockenspeil
      if (depth < 5) {
        
        note = new Note();
        note.channel = 9;
        note.velocity = 127;
        note.pitch = 70;
        note.duration = 100;
        note.parent = this;
        note.index = x;
        note.total = count;
        
        note = processEffects(note);
        
        task = new QuakeTask(note);
        timer.schedule(task, delay);
        tasks.add(task);
      }
   }
   catch(Exception e) {
     println(e);
   }
   // Update the previous date to the current date for the next iteration
   previousDate = date;
   x++;
  }
  
  println("Estimated song length: " + delay/100/60 + " minutes");
  
  // Augment the delay due to the above code taking so long!
  for (int i = ps.particles.size()-1; i >= 0; i--) {
    Particle p = ps.particles.get(i);
    p.delay += (millis()-start);
  }
}

Note processEffects(Note note) {
    for (Effect effect : effects) {
      if (note.channel == effect.channel) {
        note.pitch = (int)(note.pitch*effect.pitch);
        note.velocity = (int)(note.velocity*effect.velocity);
      }
    }
    return note;
}

/* 
Channel 1: Piano (West + Mid US/Canada/Alaska)
Channel 2: Cello Section (Antartica/Pacfic Ocean)
Channel 3: Double Bass Section Pizzicato/Cello Solo (Greenland/East US)
Channel 4: Bb Clarinet Section Legato LE/Double Bass Section (South America)
Channel 5: Violin Solo (Europe/Russia)
Channel 6: Double Bass Solo LE (South Africa)
Channel 7: Low Bass (China)
Channel 8: Bassoon/Violin Section Pizzicato (Australia/NZ/SE Asia)
*/
int getChannelFromCoordinates(double latitude, double longitude) {
  int x = 0;
  latitude = latitude+90;
  longitude = longitude+180;
 
  for ( Rectangle rectangle : grid) {
    Point2D.Double point = new Point2D.Double(longitude, latitude);
    if (rectangle.contains(point)) {
       return x; 
    }
    x++;
  }
  return 7;
}


color getColourFromMonth(int month) {
  return color(colours.get(month));
}

boolean sketchFullScreen() {
  return isFullScreen;
}

void draw() {
  background(20);
  blendMode(BLEND);
  ps.run();
}
