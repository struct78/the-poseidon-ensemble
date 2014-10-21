# The Poseidon Ensemble

The Poseidon Ensemble is a project that generates an orchestral composition and data visualisation from over 100 years of global seismic data. 

It is made up of over 780,000 data points and runs for nearly 8 days.

## How it works

The globe is divided into 8 segments with each representing a single or group of instruments. Each seismic event constitutes a single note, with pitch determined by the depth of the event, and the velocity determined by the magnitude.

## Timing

Due to the fact that density of data points increased as the years went on, the composition has been broken up into 7 different tempos.

| Start Year | End Year | Time Acceleration |
|------------|----------|-------------------|
| -          | 1939     |          500,000x |
| 1940       | 1959     |          250,000x |
| 1960       | 1972     |          100,000x |
| 1973       | 1989     |           10,000x |
| 1990       | 1999     |            5,000x |
| 2000       | 2009     |            1,250x |
| 2010       | Present  |              750x |

Bezier curves between sites identify patterns between seismic events. Stronger lines indicate that events in one region tend to follow another.

5 remaining MIDI channels are reserved for special events (earthquakes > magnitude 8, low and high RMS, etc.)

## Processing

The Processing sketch requires the [themidibus](https://github.com/sparks/themidibus) library to run. It uses 13 MIDI channels on a virtual MIDI port named Poseidon, but you can use your own by modifying this line of code in Poseidon.pde

```
bus = new MidiBus(this, -1, "Poseidon");
```

[How to create virtual MIDI ports](https://www.ableton.com/en/articles/using-virtual-MIDI-buses-live/)

## Python

A Python script to download and merge all the seismic data from the [U.S. Geological Survey](http://earthquake.usgs.gov/earthquakes/search/) has been included. 

You can  manipulate the URL query string in get-data.py if you wish to filter the data further. You will need to look at the input names on the search page and adjust the URL accordingly: http://earthquake.usgs.gov/earthquakes/search/

```
url = "http://comcat.cr.usgs.gov/fdsnws/event/1/query?starttime={0}%2000:00:00&minmagnitude=0.1&format=csv&endtime={1}%2023:59:59&maxmagnitude=10&orderby=time-asc"
```

## Ableton Live

To use the Ableton set provided, you will need [Ableton Live 9 Suite](https://www.ableton.com/en/live/new-in-9/) with the [following packs](https://www.ableton.com/en/packs/#?genres=orchestral). 
* Orchestral Brass
* Orchestral Mallets
* Orchestral Strings
* Orchestral Woodwind
* Samplification

Or create your own live set!