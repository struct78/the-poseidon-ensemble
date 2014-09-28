import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;
import java.util.Arrays;
import java.text.SimpleDateFormat;
import java.awt.Rectangle;
import java.awt.geom.Point2D;
import java.awt.Point;
import themidibus.*;
import javax.sound.midi.*;

boolean isFullScreen = false;
boolean visualsOnly = false;
int width;
int height;
int circlekeyframes = 2;
long speed = 100000;
long startOffset = 35000;
long circleLifetime = 8000;
long intro = 4000;
long startRow = 0;

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
float depth, magnitude, dmin;

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

int scaleFactor = 10;
PFont fontBold;
PFont fontLight;
PImage image;


void setup() {
  width = displayWidth;
  height = displayHeight;
  
  frameRate(24);
  
  size(width, height, P3D);
  hint(DISABLE_DEPTH_MASK);

  canvas = new Rectangle(50, 100, width-100, height-150);
  fontBold = loadFont("BebasNeueBold-48.vlw");
  fontLight = loadFont("BebasNeueLight-48.vlw");

  // Colours are seasonal
  // Left -> Right = January - December
  colours.addAll(Arrays.asList(#e31826, #881832, #942aaf, #ce1a9a, #ffb93c, #00e0c9, #234baf, #47b1de, #b4ef4f, #26bb12, #3fd492, #f7776d));


  // Effects rack
  // Piano 
  effects.add(new Effect(0, 1.5f, 1f)); 
  // Cello Section 
  effects.add(new Effect(1, 1, 0.125)); 
  // Doule Bass Section Pizzicato / Cello Solo Staccato
  effects.add(new Effect(2, 1, 0.8)); 
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
  delay = startOffset;

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
    if (x < startRow) {
      x++;
      continue; 
    }
    
    // Extract the data
    date = row.getString("time");
    latitude = row.getDouble("latitude");
    longitude = row.getDouble("longitude");
    depth = row.getFloat("depth");
    magnitude = row.getFloat("mag");
    dmin = row.getFloat("dmin");
    type = row.getString("type");

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
      // delay += diff/speed + (millis()-start);
      delay += diff/speed;


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

      // Sometimes dmin is null so just default to 1
      if (Double.isNaN(dmin)) {
        dmin = 1f;
      }
      // How long the note is played for, on some instruments this makes no difference
      note.duration = mapMagnitude(magnitude, 50, 500) * scaleFactor;

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
      int radius = abs((int)(pow((float)magnitude, 2.2)/TWO_PI));

      // Create the particle
      circle = new Particle(point, offset, radius);
      // Colour
      circle.fill = fill;
      // Opacity is determined by depth. Lower = less opaque.
      circle.opacity = mapDepth(depth, 30, 5);
      // When the circle appears
      circle.delay = delay;
      // Number of keyframes per cycle. Lower = quicker.
      circle.keyframes = circlekeyframes;
      // Exponential length of animation
      circle.totalKeyframes = circlekeyframes*(int)(pow(abs((float)magnitude), 2));
      // How long the circle lives for before being removed
      circle.lifespan = circleLifetime;

      // Add the particle to the particle system
      ps.addParticle(circle);
      
      
      if (x >= 1) {
        previousRow = table.getRow(x-1);
        if (previousRow != null) {
          Point previousPoint = MercatorProjection.CoordinatesToPoint(canvas.width, canvas.height, previousRow.getDouble("latitude"), previousRow.getDouble("longitude"));
          
          if (previousPoint.x!=point.x && previousPoint.y!=point.x) {
            BezierCurve curve = new BezierCurve(new PVector(point.x+offset.x, point.y+offset.y), new PVector(previousPoint.x+offset.x, previousPoint.y+offset.y));
            curve.fill = circle.fill;
            curve.opacity = 5;
            curve.lifespan = circle.lifespan;
            curve.delay = circle.delay;
            bs.addBezierCurve(curve);
          }
        }
      }


      label = new Label(simpleFormat.format(d2).toString(), (long)(abs(diff/speed)));
      labels.add(label);


      // Major/Great earthquakes
      // Low drone/kick
      if (magnitude >= 6) {
        note = new Note(bus);
        note.channel = 8;
        note.velocity = 127;
        note.pitch = 36;
        note.duration = 200;
        //note.parent = this;
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
        note.duration = mapMagnitude(magnitude, 50, 500) * scaleFactor;
        //note.parent = this;
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
          note.pitch = mapMagnitude(magnitude, 50, 500) * scaleFactor;
          note.duration = 500;
          //note.parent = this;
          note.index = x;
          note.total = count;
  
          note = processEffects(note);
          
          if (!visualsOnly) {
            task = new QuakeTask(note);
            timer.schedule(task, delay);
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
  timer.schedule(task, startOffset-(millis()-start));

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
  return (int)map(magnitude, 0, 10, 108, 21);
}

int mapMagnitude(float magnitude, int min, int max) {
  return (int)map(magnitude, 0, 10, min, max);
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
    ps.delay(intro);
    bs.delay(intro);
    println(end + "ms elapsed");
    println(circleLifetime + " lifetime");
  }

  background(2, 2, 10);
  blendMode(ADD);
  ps.run();
  bs.run();
  smooth();
  noFill();
  //stroke(10);
  rect(canvas.x, canvas.y, canvas.width, canvas.height);

  
  // Start only
  float endFrame = (frameRate*(intro/1000)/2);
  if (frameCount < endFrame) {
    fill(255, map(frameCount, 0, (endFrame/2), 0, 255));
    noStroke();
    textFont(fontLight, 48);
    textAlign(CENTER, CENTER);
    text("The Poseidon Ensemble", width/2, height/2);
  } 

  fill(230);
  textFont(fontLight, 48);
  textAlign(LEFT, TOP);
  text(labelThread.getCurrentLabel(), canvas.x, 50);
  
  
  saveFrame("frameGrabs/frame-#########.tga");
}


