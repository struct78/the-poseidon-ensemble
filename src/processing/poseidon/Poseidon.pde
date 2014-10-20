import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;
import java.util.Collections;
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
// Create pause feature
// Create array list of previous n events 
// Change label thread to be time worker

/* 
==================================
INSTRUMENT LIST
1. Location triggered
==================================
   Channel 1: Piano/Glass Clavi (Pacific ocean. Bottom row, first square)
   Channel 2: Double Bass Section Pizzicato/Cello Section Pizzicato (Alaska. Top row, first square)
   Channel 3: Cello/Violin/Double Bass section (South America. Bottom row, second square)
   Channel 4: Double Bass Section Pizzicato/String Ensemble (North America/Greenland. Top row, second square)
   Channel 5: Bb Clarinet/Concert Flute Section (Southern Africa. Bottom row, third square)
   Channel 6: Vibraphone (Europe/Middle East. Top row, third square)
   Channel 7: Bassoon/Contrabassoon (Australia/New Zealand. Bottom row, fourth square)
   Channel 8: French Horn/Bass Trombone (China/Japan. Top row, fourth square.)
   
==================================
2. Event triggered
==================================
   Channel 9: French Horn/Trumpet/Tuba (Earthquakes > 7.0)
   Channel 10: Double Bass Section/French Horn/Tuba/Timpani (Earthquakes > 8.0)
   Channel 11: Sandman Ambient Drone (Earthquakes <= 1.0)
   Channel 12: All Alone Pad (Low RMS)
   Channel 13: Chimes (High RMS)
*/
 
// Debug flag. Hit 'd' key to enable.
boolean DEBUG = false;

// Frames per second
int FPS = 60;

// Display Mode
DisplayMode DISPLAY_MODE = DisplayMode.RETINA;

// Approximate time to parse CSV file (milliseconds)
int START_OFFSET = 30000;

// How many channels are open
int NUM_CHANNELS = 13;

// Padding
int PADDING = 40;

// Start date offset
Calendar startDate = new GregorianCalendar(1900, 0, 1, 0, 0, 0);

// End date
Calendar endDate = new GregorianCalendar(2014, 9, 20, 23, 59, 59);

// Introduction length
int INTRO_LIFETIME = 5000;

// Lowest opacity for markers/bezier
int OPACITY_FLOOR = 50;

// Highest opacity for markers/bezier
int OPACITY_CEILING = 100;

// Note scale factor
int SCALE_FACTOR = 10;

// Diameter = magnitude^MARKER_SCALE_FACTOR/5
float MARKER_FACTOR = 5;

// Minimum pitch
int PITCH_MIN = 35;

// Maximum pitch
int PITCH_MAX = 80;

// Minimum velocity
int VELOCITY_MIN = 10;

// Maximum velocity
int VELOCITY_MAX = 127;

// Minimum note duration in milliseconds
int NOTE_MIN = 25;

// Maximum note duration in milliseconds
int NOTE_MAX = 125;

// Save out frames when recording
boolean SAVE_FRAMES = false;

// Full screen presentation
boolean IS_FULLSCREEN = true;

// Just visuals
boolean NO_AUDIO = false;

// Database of seismic events
String QUAKES_CSV = "quakes.csv";

// Default amount of shapes visible
int MAX_SHAPES = 200;

// Font size
int FONT_SIZE = 30;

boolean isComplete = false;

int width, height;
int tint = 255;

Table table;
TableRow previousRow;

String dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS";
String dateFormatLabel = "d MMMM, yyyy";
Date d1, d2;

String date, previousDate;
SimpleDateFormat format = new SimpleDateFormat(dateFormat);
SimpleDateFormat simpleFormat = new SimpleDateFormat(dateFormatLabel);

Timer timer = new Timer();
long start, delay, timeOffset, lastIndex;

// CSV
double latitude, longitude;
float depth, magnitude, rms;

QuakeTask task;
Note note;
Label label;
MidiBus bus;
LabelThread labelThread;

ArrayList<Rectangle> grid = new ArrayList();
ArrayList<Integer> colours = new ArrayList();
ArrayList<Label> labels = new ArrayList();

TempoCollection timekeeper;
Marker marker;
MarkerSystem ms;
BezierCollection bs;
Rectangle canvas;

PFont font;
PFont fontSmall;
PImage map;
color fontColor;

void setup() {
  width = displayWidth;
  height = displayHeight;
  
  frameRate(FPS);
  size(width, height, P2D);

  fontColor = color(255);
  canvas = new Rectangle(PADDING/2, PADDING/2, width-PADDING, height-PADDING);
  font = loadFont("BebasNeueLight-48.vlw");
  fontSmall = loadFont("BebasNeueLight-30.vlw");
  map = loadImage("map-" + DISPLAY_MODE.name().toLowerCase() + ".jpg");

  // Colours are seasonal
  // Left -> Right = January - December
  colours.addAll(Arrays.asList(#e31826, #881832, #942aaf, #ce1a9a, #ffb93c, #00e0c9, #234baf, #47b1de, #b4ef4f, #26bb12, #3fd492, #f7776d));

  // Set the delay between notes
  // We start after 5 seconds
  delay = START_OFFSET;


  // Create the Time Keeper
  timekeeper = new TempoCollection();
  timekeeper.add(new Tempo(0,     1939,    500000,    20));
  timekeeper.add(new Tempo(1940,  1959,    250000,    30));
  timekeeper.add(new Tempo(1960,  1972,    100000,    60));
  timekeeper.add(new Tempo(1973,  1989,    10000,     70));
  timekeeper.add(new Tempo(1990,  1999,    5000,      80));
  timekeeper.add(new Tempo(2000,  2009,    1250,      150));
  timekeeper.add(new Tempo(2010,  Calendar.getInstance().get(Calendar.YEAR), 500, 225));
  
  // Create the marker system
  ms = new MarkerSystem();
  bs = new BezierCollection();

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
  
  // Create the MIDI Bus
  bus = new MidiBus(this, -1, "Poseidon");
  
  for (TableRow row : table.rows ()) {
    // Extract the data
    date = row.getString("time");
    latitude = row.getDouble("latitude");
    longitude = row.getDouble("longitude");
    depth = row.getFloat("depth");
    magnitude = row.getFloat("mag");
    rms = row.getFloat("rms");

    // On the first iteration previousDate will be null
    if (previousDate == null) {
      previousDate = date;
    }

    try {
      d1 = format.parse(previousDate);
      d2 = format.parse(date);

      // If the date is before the start time we want then skip to the next iteration
      if (d2.after(startDate.getTime()) && d2.before(endDate.getTime())) {
        int speed = timekeeper.getSpeed(d2);
        
        // Diff in milliseconds
        long diff = d2.getTime() - d1.getTime();

        // Increase the delay
        delay += (diff/speed);
        
        if (x == 0) {
          timeOffset = delay; 
        }
        
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
        // Index
        note.index = x;
        
        if (!NO_AUDIO) {
          // Add the note to task schedule
          task = new QuakeTask(note);
          timer.schedule(task, delay);
        }

        // Drawing task
        // This draws a marker where the earthquake originated from
        PVector point = Geography.CoordinatesToPVector(canvas.width, canvas.height, latitude, longitude);

        // Get the colour from the month
        color fill = getColourFromMonth(d2.getMonth());
        PVector offset = new PVector(canvas.x, canvas.y);

        // Exponential diameter
        float diameter = abs(pow(map(magnitude, 0, 10, 1, 2.5), MARKER_FACTOR));
        
        // Create the marker
        marker = new Marker(point, offset, diameter);
        // Colour
        marker.fill = fill;
        // Opacity is determined by depth. Lower = less opaque.
        marker.opacity = mapDepth(depth, OPACITY_CEILING, OPACITY_FLOOR);
        // When the marker appears
        marker.delay = delay;
        // Time offset
        marker.timeOffset = millis();

        // Add the marker to the marker system
        ms.addShape(marker);

        if (x > 0) {
          previousRow = table.getRow(y-1);
          PVector previousPoint = Geography.CoordinatesToPVector(canvas.width, canvas.height, previousRow.getDouble("latitude"), previousRow.getDouble("longitude"));

          Bezier curve = new Bezier(new PVector(point.x+offset.x, point.y+offset.y), new PVector(previousPoint.x+offset.x, previousPoint.y+offset.y));
          curve.fill = marker.fill;
          curve.opacity = int((OPACITY_FLOOR/2)*DISPLAY_MODE.get());
          curve.delay = marker.delay;
          curve.diameter = marker.diameter;
          curve.timeOffset = millis();
          bs.addShape(curve);
        }
        
        x++;
        
        label = new Label(simpleFormat, d2, (diff/speed));
        labels.add(label);
  
        // Major/Great earthquakes
        // Tubas
        if (magnitude >= 7) {
          note = new Note(bus);
          note.channel = 8;
          note.velocity = mapMagnitude(magnitude);
          note.pitch = mapDepth(depth); 
          note.duration = 1000;

          if (!NO_AUDIO) {
            task = new QuakeTask(note);
            timer.schedule(task, delay);
          }
        }
        
        // Major/Great earthquakes
        // Kettle Drum
        // Drone
        // Tuba
        // French Horn
        // Trombone
        if (magnitude >= 8) {
          note = new Note(bus);
          note.channel = 9;
          note.velocity = 127;
          note.pitch = 36;
          note.duration = 200;

          if (!NO_AUDIO) {
            task = new QuakeTask(note);
            timer.schedule(task, delay);
          }
          
          note = new Note(bus);
          note.channel = 9;
          note.velocity = 127;
          note.pitch = 56;
          note.duration = 200;

          if (!NO_AUDIO) {
            task = new QuakeTask(note);
            timer.schedule(task, delay);
          }
        }
        
        
        // Small earthquakes
        if (magnitude <= 1) {
          note = new Note(bus);
          note.channel = 10;
          note.velocity = 255;
          note.pitch = mapDepth(depth, 40, 80); 
          note.duration = mapMagnitudeToLength(5000, magnitude);

          if (!NO_AUDIO) {
            task = new QuakeTask(note);
            timer.schedule(task, delay);
          }
        }
        
        // Low RMS (root-mean-square)
        if (rms < 0.01) { 
          note = new Note(bus);
          note.channel = 11;
          note.velocity = mapMagnitude(magnitude);
          note.pitch = mapDepth(depth); 
          note.duration = 2000;

          if (!NO_AUDIO) {
            task = new QuakeTask(note);
            timer.schedule(task, delay-500);
          }
        }
        
        // Big RMS (root-mean-square)
        if (rms > HALF_PI) { 
          note = new Note(bus);
          note.channel = 12;
          note.velocity = mapMagnitude(magnitude);
          note.pitch = mapDepth(depth); 
          note.duration = 1000;

          if (!NO_AUDIO) {
            task = new QuakeTask(note);
            timer.schedule(task, delay-500);
          }
        }
      }
    }
    catch(Exception e) {
      println(e);
    }
    
    // Update the previous date to the current date for the next iteration
    previousDate = date;
    y++;
  }

  // This is important!
  // If you don't reverse the marker and bezier systems, performance will be seriously degraded
  // Each system bails out of the run() method called in draw() below if elements aren't ready to animate yet
  // instead of unnecessarily iterating through elements that won't be displayed on screen
  Collections.reverse(ms.shapes);
  Collections.reverse(bs.shapes);
  
  lastIndex = (x-1);
  
  labelThread = new LabelThread(labels);
  task = new QuakeTask(labelThread);
  
  long end = millis();
  timer.schedule(task, START_OFFSET-(end-start));

  addShutdownHook();
  println("Estimated song length: " + delay/1000/60 + " minutes // " + delay/1000/60/60 + " hours // " + delay/1000/60/60/24 + " days");
  println("Setup lasted " + end + "ms");
}


void draw() {
  noCursor();
  background(0);
  blendMode(ADD);
  smooth(8);
  
  if (DEBUG) {
    debug(); 
  }
  
  // Run the marker/bezier systems
  if (labelThread.getDate() != null) {
    MAX_SHAPES = timekeeper.getMaxObjects(labelThread.getDate());
  }
  
  if (isComplete) {
    bs.kill();
    ms.kill(); 
  }
  
  bs.run();
  ms.run();
  
  // Intro frames
  float endFrame = (frameRate*(INTRO_LIFETIME/1000));
  if (frameCount < (endFrame/2)) {
    fill(255, map(frameCount, 0, (endFrame/2), 0, 255));
    noStroke();
    textFont(font, 48);
    textAlign(CENTER, CENTER);
    text("The Poseidon Ensemble", width/2, height/2);
  }
  else {
    // Draw the date    
    if (frameCount < endFrame) {
      tint(map(frameCount, (endFrame/2), (endFrame), 0, 255));
    }
    
    
    if (isComplete) {
      if (tint > 0) {
        tint(tint);
        tint-=5;
      }
    }
    
    image(map, canvas.x, canvas.y, canvas.width, canvas.height);

    if (labelThread.getCurrentLabel()!="") {
      noFill();
      noStroke();
      fill(fontColor, tint);
      textFont(fontSmall, FONT_SIZE);
      textAlign(RIGHT, TOP);
      text(labelThread.getCurrentLabel(), canvas.width+canvas.x-(PADDING/2), canvas.y+(PADDING/2)+(FONT_SIZE*0.05));
      
      
      // Poseidon Ensemble label
      textFont(fontSmall, FONT_SIZE);
      textAlign(LEFT, TOP);
      text("THE POSEIDON ENSEMBLE", canvas.x+(PADDING/2), canvas.y+(PADDING/2)+(FONT_SIZE*0.05));
    }
  }
  
  // If we're saving frames, same them to the frameGrabs folder
  if (SAVE_FRAMES) {
    saveFrame("frameGrabs/frame-########.tga");
  }
}

void keyPressed() {
  if (key == 'd') {
    DEBUG = !DEBUG;
  }
}

void debug() {
  fill(fontColor);
  textAlign(RIGHT, TOP);
  text(round(frameRate)+"fps", canvas.x+canvas.width-PADDING, canvas.y+canvas.height-PADDING);
  text("Objects on screen: " + (ms.numRendered+bs.numRendered), canvas.x+canvas.width-PADDING, canvas.y+canvas.height-PADDING*2);
  
  for ( Rectangle rectangle : grid) {
    noFill();
    stroke(fontColor);
    rect(map(rectangle.x, 0, 90, 0, width/4), map(rectangle.y, 0, 90, 0, height/2), map(rectangle.width, 0, 90, 0, width/4), map(rectangle.height, 0, 90, 0, height/2));
    fill(fontColor);
    noStroke();
    textAlign(LEFT, TOP);
    text("Channel " + (grid.indexOf(rectangle)), map(rectangle.x, 0, 90, 0, width/4)+20, map(rectangle.y, 0, 90, 0, height/2)+20);
  }
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
  return IS_FULLSCREEN;
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

int mapMagnitudeToLength(float base, float magnitude) {
  return int(base+map(magnitude, 0, 10, NOTE_MIN, NOTE_MAX) * SCALE_FACTOR);
}

int invert(int n, int min, int max) {
  return (max-n)+min;
}

void addShutdownHook () {
  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
    public void run () {
      System.out.println("Shutting Down");
      for (int x = 0; x < NUM_CHANNELS; x++) {
        bus.sendMessage(ShortMessage.CONTROL_CHANGE, x, 0x7B, 0);
      }

      bus.close();
      System.out.println("Daisy, Daisy, give me your answer do. I'm half crazy, all for the love of you.");
    }
  }
  ));
}
