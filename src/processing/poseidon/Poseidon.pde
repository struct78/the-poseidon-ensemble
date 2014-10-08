import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;
import java.util.*;
import java.util.Arrays;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.text.SimpleDateFormat;
import java.awt.Rectangle;
import java.awt.geom.Point2D;
import java.awt.Point;
import themidibus.*;
import javax.sound.midi.*;

// TODO
// Check size of TV
// Dashed/dotted lines on bezier curves
// Improve design/create fonts
// Look into randomising appregator
// Put border around map?
// Adjust vibraphone scale
// Move double bass/bassoon to channel 3?

/* 
==================================
INSTRUMENT LIST
==================================
   Channel 1: Piano (Pacific ocean. Bottom row, first square)
   Channel 2: Tuba/Trombone (Alaska. Top row, first square)
   Channel 3: Cello/Violin/Double Bass section (South America. Bottom row, second square)
   Channel 4: Double Bass Section (North America/Greenland. Top row, second square)
   Channel 5: Clarinet/Flute (Southern Africa. Bottom row, third square)
   Channel 6: Vibraphone (Europe/Middle East. Top row, third square)
   Channel 7: Bassoon/Contrabassoon (Australia/New Zealand. Bottom row, fourth square)
   Channel 8: French Horn/Bass Trombone (China/Japan. Top row, fourth square.)
*/
 
// Debug flag. Hit 'd' key to enable.
boolean DEBUG = false;

// Frames per second
int FPS = 60;

// Display Mode
DisplayMode DISPLAY_MODE = DisplayMode.RETINA;

// Time compression
int SPEED = 2000;

// Approximate time to parse CSV file (milliseconds)
int START_OFFSET = 15000;

// How long circle/bezier should live for in days
int CIRCLE_LIFETIME = 2;

// Introduction length
int INTRO_LIFETIME = 5000;

// Lowest opacity for circles/bezier
int OPACITY_FLOOR = 40;

// Highest opacity for circles/bezier
int OPACITY_CEILING = 90;

// Note scale factor
int SCALE_FACTOR = 10;

// Radius = magnitude^CIRCLE_SCALE_FACTOR
float CIRCLE_SCALE_FACTOR = 1.8;

// Minimum pitch
int PITCH_MIN = 35;

// Maximum pitch
int PITCH_MAX = 80;

// Minimum velocity
int VELOCITY_MIN = 30;

// Maximum velocity
int VELOCITY_MAX = 127;

// Minimum note duration in milliseconds
int NOTE_MIN = 40;

// Maximum note duration in milliseconds
int NOTE_MAX = 90;

// Channel isolation
boolean CHANNEL_ISOLATION = false;

// Channel to isolate
int CHANNEL_ISOLATED = 1;

/* 
 Database of seismic events
 quakes.csv = 110 years worth of data
 quakes-2014.csv = 1 year worth of data
 quakes-sample.csv = 3 seismic events
 */
String QUAKES_CSV = "quakes.csv";

// Start date offset
Calendar startDate = new GregorianCalendar(2002, 3, 19);

boolean isFullScreen = true;
boolean visualsOnly = false;
boolean saveFrames = false;
int width;
int height;

Table table;
TableRow previousRow;

String dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS";
String dateFormatLabel = "d MMMM, yyyy";
Date d1, d2;

String date, previousDate, type;
SimpleDateFormat format = new SimpleDateFormat(dateFormat);
SimpleDateFormat simpleFormat = new SimpleDateFormat(dateFormatLabel);

Timer timer = new Timer();
long start, delay, elapsed, graphicsDelay = 0;

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
ArrayList<Label> labels = new ArrayList();

Particle circle;
ParticleSystem ps;
BezierCurveSystem bs;
Rectangle canvas;

PFont fontBold;
PFont fontLight;
PImage map;


void setup() {
  width = displayWidth;
  height = displayHeight;
  frameRate(FPS);

  size(width, height, P3D);

  //canvas = new Rectangle(50, 100, width-100, height-150);
  canvas = new Rectangle(20, 20, width-40, height-40);
  fontBold = loadFont("BebasNeueBold-48.vlw");
  fontLight = loadFont("BebasNeueLight-48.vlw");
  map = loadImage("map-low-res.jpg");

  // Colours are seasonal
  // Left -> Right = January - December
  colours.addAll(Arrays.asList(#e31826, #881832, #942aaf, #ce1a9a, #ffb93c, #00e0c9, #234baf, #47b1de, #b4ef4f, #26bb12, #3fd492, #f7776d));

  // Set the delay between notes
  // We start after 5 seconds
  delay = START_OFFSET;

  // Create the particle system
  ps = new ParticleSystem();
  bs = new BezierCurveSystem();

  for (int x = 0 ; x < 360; x += 90) {
    for (int y = 0 ; y < 180 ; y += 90) {
      grid.add(new Rectangle(x, y, 90, 90));
    }
  }

  // Load the data
  table = loadTable(QUAKES_CSV, "header");

  int x = 0, y = 0;
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
        note.velocity = mapMagnitude(magnitude);
        // Pitch of the note
        note.pitch = mapDepth(depth); 
        // How long the note is played for, on some instruments this makes no difference
        note.duration = mapMagnitudeToLength(magnitude);
  
        if (CHANNEL_ISOLATION) {
          if (note.channel!=CHANNEL_ISOLATED) {
            delay -= (diff/SPEED);
            continue;
          }
        }
  
        if (!visualsOnly) {
          // Add the note to task schedule
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
        int radius = abs(int(pow(magnitude, CIRCLE_SCALE_FACTOR)));

        // Create the particle
        circle = new Particle(point, offset, radius);
        // Colour
        circle.fill = fill;
        // Opacity is determined by depth. Lower = less opaque.
        circle.opacity = mapDepth(depth, int(OPACITY_CEILING*DISPLAY_MODE.get()), int(OPACITY_FLOOR*DISPLAY_MODE.get()));
        // When the circle appears
        circle.delay = delay;
        // Time offset
        circle.timeOffset = millis();
        // How long the circle lives for before being removed
        circle.lifespan = ((1000*60*60*24)*CIRCLE_LIFETIME)/SPEED;

        // Add the particle to the particle system
        ps.addParticle(circle);


        if (x > 0) {
          previousRow = table.getRow(y-1);
          Point previousPoint = MercatorProjection.CoordinatesToPoint(canvas.width, canvas.height, previousRow.getDouble("latitude"), previousRow.getDouble("longitude"));

          BezierCurve curve = new BezierCurve(new PVector(point.x+offset.x, point.y+offset.y), new PVector(previousPoint.x+offset.x, previousPoint.y+offset.y));
          curve.fill = circle.fill;
          curve.opacity = int((OPACITY_FLOOR/2)*DISPLAY_MODE.get());
          curve.lifespan = circle.lifespan;
          curve.delay = circle.delay;
          curve.timeOffset = millis();
          bs.addBezierCurve(curve);
        }

        x++;

        label = new Label(simpleFormat.format(d2).toString(), (diff/SPEED));
        labels.add(label);


        // Major/Great earthquakes
        // Kettle Drum
        // Tuba
        // Drone
        if (magnitude >= 6) {
          note = new Note(bus);
          note.channel = 8;
          note.velocity = 127;
          note.pitch = 36;
          note.duration = 200;

          if (!visualsOnly) {
            task = new QuakeTask(note);
            timer.schedule(task, delay);
          }
        }
        
        
        // Small earthquakes
        if (magnitude <= 2) {
          note = new Note(bus);
          note.channel = 9;
          note.velocity = mapMagnitude(magnitude);
          note.pitch = mapDepth(depth); 
          note.duration = mapMagnitudeToLength(magnitude);

          if (!visualsOnly) {
            task = new QuakeTask(note);
            timer.schedule(task, delay+500);
          }
        }
      }
      // TODO??
      //mining_explosion
      //explosion
      //landslide
      //quarry
      //rock_burst
    }
    catch(Exception e) {
      println(e);
    }
    // Update the previous date to the current date for the next iteration
    previousDate = date;
    y++;
  }

  // This is important!
  // If you don't reverse the particle and bezier systems, performance will be seriously degraded
  // Each system bails out of the run() method called in draw() below if elements aren't ready to animate yet
  // instead of unnecessarily iterating through elements that won't be displayed on screen
  Collections.reverse(ps.particles);
  Collections.reverse(bs.beziers);

  labelThread = new LabelThread(labels);
  task = new QuakeTask(labelThread);
  timer.schedule(task, START_OFFSET-(millis()-start));

  addShutdownHook();
  //memory();

  table = null;
  println("Estimated song length: " + delay/100/60 + " minutes");


  long end = millis();
  println("Setup lasted " + end + "ms");
}


int getChannelFromCoordinates(double latitude, double longitude) {
  latitude = latitude+90;
  longitude = longitude+180;

  for ( Rectangle rectangle : grid) {
    Point2D.Double point = new Point2D.Double(longitude, latitude);
    if (rectangle.contains(point)) {
      return grid.indexOf(rectangle);
    }
  }

  return 0;
}


color getColourFromMonth(int month) {
  return color(colours.get(month));
}

boolean sketchFullScreen() {
  return isFullScreen;
}

int mapDepth(float depth) {
  return invert(int(map(depth, 0, 750, PITCH_MIN, PITCH_MAX)), PITCH_MIN, PITCH_MAX);
}

int mapDepth(float depth, int min, int max) {
  return invert(int(map(depth, 0, 750, min, max)), min, max);
}

int mapMagnitude(float magnitude) {
  return int(map(magnitude, 0, 10, VELOCITY_MIN, VELOCITY_MAX));
}

int mapMagnitude(float magnitude, int min, int max) {
  return int(map(magnitude, 0, 10, min, max));
}

int mapMagnitudeToLength(float magnitude) {
  return int(map(magnitude, 0, 10, NOTE_MIN, NOTE_MAX) * SCALE_FACTOR);
}

int invert(int n, int min, int max) {
  return (max-n)+min;
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
      System.out.println("Daisy, Daisy, give me your answer do. I'm half crazy, all for the love of you.");
    }
  }
  ));
}


void draw() {
  background(0);
  image(map, canvas.x, canvas.y, canvas.width, canvas.height);

  blendMode(ADD);
  smooth(8);
  
  

  ps.run();
  bs.run();
  
  noFill();
  noStroke();
  fill(5, 5, 15);
  textFont(fontLight, 25);
  textAlign(CENTER, BOTTOM);
  text(labelThread.getCurrentLabel(), canvas.width/2, canvas.height-30);

  
  // Start only
  float endFrame = (frameRate*(INTRO_LIFETIME/1000)/2);
  if (frameCount < endFrame) {
    fill(255, map(frameCount, 0, (endFrame/2), 0, 255));
    noStroke();
    textFont(fontLight, 48);
    textAlign(CENTER, CENTER);
    text("The Poseidon Ensemble", width/2, height/2);
  }

  ps.run();
  bs.run();

  if (saveFrames) {
    saveFrame("frameGrabs/frame-########.tga");
  }
  
  if (DEBUG) {
    debug(); 
  }
}

void keyPressed() {
  if (key == 'd') {
    DEBUG = !DEBUG;
  }
  
  if (Character.isDigit(key)) {
    CHANNEL_ISOLATION = !CHANNEL_ISOLATION;
    CHANNEL_ISOLATED = Character.digit(key, 10);
  }
}

void debug() {
  fill(5, 5, 15);
  textAlign(RIGHT, TOP);
  text(round(frameRate)+"fps", canvas.x+canvas.width-20, 20);
  
  for ( Rectangle rectangle : grid) {
    noFill();
    stroke(255, 50);
    rect(map(rectangle.x, 0, 90, 0, width/4), map(rectangle.y, 0, 90, 0, height/2), map(rectangle.width, 0, 90, 0, width/4), map(rectangle.height, 0, 90, 0, height/2));
    fill(255, 125);
    noStroke();
    textFont(fontLight, 28);
    textAlign(LEFT, TOP);
    text("Channel " + (grid.indexOf(rectangle)), map(rectangle.x, 0, 90, 0, width/4)+20, map(rectangle.y, 0, 90, 0, height/2)+20);
  }
}
