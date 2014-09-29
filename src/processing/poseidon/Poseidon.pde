import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;
import java.util.Arrays;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.text.SimpleDateFormat;
import java.awt.Rectangle;
import java.awt.geom.Point2D;
import java.awt.Point;
import themidibus.*;
import javax.sound.midi.*;

int SPEED = 7500;
int START_OFFSET = 20000;
int CIRCLE_KEYFRAMES = 2;
int CIRCLE_LIFETIME = 15000;
int INTRO_LIFETIME = 5000;
int OPACITY_FLOOR = 20;
int OPACITY_CEILING = 70;
int SCALE_FACTOR = 8;

boolean isFullScreen = false;
boolean visualsOnly = false;
boolean saveFrames = false;
int width;
int height;
Calendar startDate = new GregorianCalendar(2004, 11, 12);

Table table;
TableRow previousRow;

String dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS";
String dateFormatLabel = "d MMMM, yyyy";
Date d1, d2;

String date, previousDate, type;
SimpleDateFormat format = new SimpleDateFormat(dateFormat);
SimpleDateFormat simpleFormat = new SimpleDateFormat(dateFormatLabel);

Timer timer = new Timer();
long start, delay, elapsed;

// CSV
double latitude, longitude;
float depth, magnitude;

QuakeTask task;
Note note;
Label label;
MidiBus bus;
LabelThread labelThread;

ArrayList<Rectangle> grid = new ArrayList();
ArrayList<Integer> colours = new ArrayList();
ArrayList<Effect> effects = new ArrayList();
ArrayList<Label> labels = new ArrayList();

Particle circle;
ParticleSystem ps;
BezierCurveSystem bs;
Rectangle canvas;

PFont fontBold;
PFont fontLight;
PImage image;


void setup() {
  width = displayWidth;
  height = displayHeight;
  frameRate(30);
  
  size(width, height, P3D);

  canvas = new Rectangle(50, 100, width-100, height-150);
  fontBold = loadFont("BebasNeueBold-48.vlw");
  fontLight = loadFont("BebasNeueLight-48.vlw");

  // Colours are seasonal
  // Left -> Right = January - December
  colours.addAll(Arrays.asList(#e31826, #881832, #942aaf, #ce1a9a, #ffb93c, #00e0c9, #234baf, #47b1de, #b4ef4f, #26bb12, #3fd492, #f7776d));


  // Effects rack
  // Piano 
  effects.add(new Effect(0, 0.75f, 1)); 
  // Cello Section 
  effects.add(new Effect(1, 1, 0.125)); 
  // Doule Bass Section Pizzicato / Cello Solo Staccato
  effects.add(new Effect(2, 1, 1.2)); 
  // Double Bass Section / Bb Clarinet Section Legato LE
  effects.add(new Effect(3, 1, 0.8)); 
  // Violin Solo
  effects.add(new Effect(4, 0.4, 0.8)); 
  // Double Bass Solo LE
  effects.add(new Effect(5, 1, 0.8));
  // Bassoon / Contrabassoon
  effects.add(new Effect(6, 0.8, 0.75));
  // French Horn
  effects.add(new Effect(7, 0.8, 0.5));
  // Glockenspeil
  effects.add(new Effect(9, 1, 0.2));
  // Tuba
  effects.add(new Effect(10, 0.6, 0.5));

  // Set the delay between notes
  // We start after 5 seconds
  delay = START_OFFSET;

  // Create the particle system
  ps = new ParticleSystem();
  bs = new BezierCurveSystem();

  for ( int i = 0; i <= 360; i+=90) {
    // Northern hemisphere
    grid.add(new Rectangle(i, 0, 90, 90));
    //Southern Hemisphere
    grid.add(new Rectangle(i, 90, 90, 90));
  }

  // Load the data
  table = loadTable("quakes.csv", "header");

  int x = 0;
  int count = table.getRowCount();

  // Start timestamp
  start = millis();
  bus = new MidiBus(this, -1, "Poseidon");
  
  for (TableRow row : table.rows ()) {
    // Extract the data
    date = row.getString("time");
    latitude = row.getDouble("latitude");
    longitude = row.getDouble("longitude");
    depth = row.getFloat("depth");
    magnitude = row.getFloat("mag");
    type = row.getString("type");

    // On the first iteration previousDate will be null
    if (previousDate == null) {
      previousDate = date;
    }

    try {
      d1 = format.parse(previousDate);
      d2 = format.parse(date);
      
      // If the date is before the start time we want then skip to the next iteration
      if (d2.after(startDate.getTime())) {
  
        // Diff in milliseconds
        long diff = d2.getTime() - d1.getTime();
  
        // Increase the delay
        //delay += ((diff/SPEED) + ((millis()-start)/1000));
        delay += (diff/SPEED);
  
        // Create the note
        note = new Note(bus);
        // Each instrument/section represents 1/8th of the globe
        note.channel = getChannelFromCoordinates(latitude, longitude); 
        // How hard the note is hit
        note.velocity = mapDepth(depth);
        // Pitch of the note
        note.pitch = mapMagnitude(magnitude); 
        // Note index. For debugging purposes only
        note.index = x; 
        // MIDIBus needs a parent
        //note.parent = this;
        // Total number of notes. For debugging purposes only.
        note.total = count; 
        // Add effects
        note = processEffects(note); 
        // How long the note is played for, on some instruments this makes no difference
        note.duration = mapMagnitudeToLength(magnitude);
  
        if (!visualsOnly) {
          // Add the note to a task schedule
          task = new QuakeTask(note);
          timer.schedule(task, delay);
        }
  
        // Drawing task
        // This draws a circle where the earthquake originated from
  
        Point point = MercatorProjection.CoordinatesToPoint(canvas.width, canvas.height, latitude, longitude);
  
        // Get the colour from the month
        color fill = getColourFromMonth(d2.getMonth());
        Point offset = new Point(canvas.x, canvas.y);
  
        // Exponential radius
        int radius = abs((int)(pow((float)magnitude, 1.2)));
  
        // Create the particle
        circle = new Particle(point, offset, radius);
        // Colour
        circle.fill = fill;
        // Opacity is determined by depth. Lower = less opaque.
        circle.opacity = mapDepth(depth, OPACITY_CEILING, OPACITY_FLOOR);
        // When the circle appears
        circle.delay = delay;
        // Number of keyframes per cycle. Lower = quicker.
        circle.keyframes = CIRCLE_KEYFRAMES;
        // Exponential length of animation
        circle.totalKeyframes = CIRCLE_KEYFRAMES*(int)(pow(abs((float)magnitude), 2));
        // How long the circle lives for before being removed
        circle.lifespan = CIRCLE_LIFETIME;
  
        // Add the particle to the particle system
        ps.addParticle(circle);
        
        
        if (x >= 1) {
          previousRow = table.getRow(x-1);
          if (previousRow != null) {
            Point previousPoint = MercatorProjection.CoordinatesToPoint(canvas.width, canvas.height, previousRow.getDouble("latitude"), previousRow.getDouble("longitude"));
            
            if (previousPoint.x!=point.x && previousPoint.y!=point.x) {
              BezierCurve curve = new BezierCurve(new PVector(point.x+offset.x, point.y+offset.y), new PVector(previousPoint.x+offset.x, previousPoint.y+offset.y));
              curve.fill = circle.fill;
              curve.opacity = OPACITY_FLOOR;
              curve.lifespan = circle.lifespan;
              curve.delay = circle.delay;
              bs.addBezierCurve(curve);
            }
          }
        }
  
  
        label = new Label(simpleFormat.format(d2).toString(), (long)(abs(diff/SPEED)));
        labels.add(label);
  
  
        // Major/Great earthquakes
        // Low drone/kick
        if (magnitude >= 6) {
          note = new Note(bus);
          note.channel = 8;
          note.velocity = 127;
          note.pitch = 36;
          note.duration = 200;
          note.index = x;
          note.total = count;
  
          note = processEffects(note);
  
          if (!visualsOnly) {
            task = new QuakeTask(note);
            timer.schedule(task, delay);
          }
        }
  
        // Shallow earthquake
        // Glockenspeil
        if (depth < 5) {
  
          note = new Note(bus);
          note.channel = 9;
          note.velocity = mapDepth(depth);
          note.pitch = mapMagnitude(magnitude);
          note.duration = mapMagnitudeToLength(magnitude);
          note.index = x;
          note.total = count;
  
          note = processEffects(note);
          
          
          if (!visualsOnly) {
            task = new QuakeTask(note);
            timer.schedule(task, delay);
          }
        }
  
        // Same magnitude
        // Tuba
        if (previousRow != null) {
          if (magnitude == previousRow.getFloat("mag")) {
            note = new Note(bus);
            note.channel = 10;
            note.velocity = mapDepth(depth);
            note.pitch = mapMagnitude(magnitude, 60, 100);
            note.duration = mapMagnitudeToLength(magnitude);
            note.index = x;
            note.total = count;
    
            note = processEffects(note);
            
            if (!visualsOnly) {
              task = new QuakeTask(note);
              timer.schedule(task, delay);
            }
          }
        }
      }
      //mining_explosion
      //explosion
      //landslide
      //quarry
      //rock_burst
      x++;
    }
    catch(Exception e) {
      println(e);
    }
    // Update the previous date to the current date for the next iteration
    previousDate = date;
  }

  
  labelThread = new LabelThread(labels);
  task = new QuakeTask(labelThread);
  timer.schedule(task, START_OFFSET-(millis()-start));

  addShutdownHook();
  memory();
  
  table = null;
  println("Estimated song length: " + delay/100/60 + " minutes");
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
 Channel 7: Bassoon (China)
 Channel 8: Violin Section Pizzicato (Australia/NZ/SE Asia)
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

int mapDepth(float depth) {
  return (int)map(depth, 0, 750, 127, 1); 
}

int mapDepth(float depth, int min, int max) {
  return (int)map((float)depth, 0, 750, min, max);
}

int mapMagnitude(float magnitude) {
  return (int)map(magnitude, 0, 10, 21, 108);
}

int mapMagnitude(float magnitude, int min, int max) {
  return (int)map(magnitude, 0, 10, min, max);
}

int mapMagnitudeToLength(float magnitude) {
  return (int)map(magnitude, 0, 10, 50, 500) * SCALE_FACTOR;
}


void memory() {
  MemoryManager mem = new MemoryManager(); 
}

void addShutdownHook () {
  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
    public void run () {
      System.out.println("Shutting Down");
      for (int x = 0; x < 10; x++) {
        bus.sendMessage(ShortMessage.CONTROL_CHANGE, x, 0x7B, 0);
      }

      bus.close();
      System.out.println("Daisy Daisy, give me your answer do. I'm half crazy, all for the love of you.");
    }
  }
  ));
}


void draw() {
  if (frameCount == 1) {
    long end = millis()-start;
    ps.delay(end);
    bs.delay(end);
    println(end + "ms elapsed");
  }

  background(2, 2, 15);
  blendMode(ADD);
  smooth(8);
  noFill();
  rect(canvas.x, canvas.y, canvas.width, canvas.height);

  // Start only
  float endFrame = (frameRate*(INTRO_LIFETIME/1000)/2);
  if (frameCount < endFrame) {
    fill(255, map(frameCount, 0, (endFrame/2), 0, 255));
    noStroke();
    textFont(fontLight, 48);
    textAlign(CENTER, CENTER);
    text("The Poseidon Ensemble", width/2, height/2);
  }
  else {
    ps.run();
    bs.run();
  }

  fill(230);
  textFont(fontLight, 48);
  textAlign(LEFT, TOP);
  text(labelThread.getCurrentLabel(), canvas.x, 50);
  
  if (saveFrames) {
    saveFrame("frameGrabs/frame-########.tga");
  }
}


