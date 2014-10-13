import os
import urllib
import datetime
import csv
import unicodecsv

def daterange(start, stop, step_days=1):
    current = start
    step = datetime.timedelta(step_days)
    if step_days > 0:
        while current < stop:
            yield current
            current += step
    elif step_days < 0:
        while current > stop:
            yield current
            current += step
    else:
        raise ValueError("daterange() step_days argument must not be zero")
        

 
date_format = '%Y-%m-%d'
step = 7
DOWNLOADS_DIR = './cache'
url = "http://comcat.cr.usgs.gov/fdsnws/event/1/query?starttime={0}%2000:00:00&minmagnitude=0.1&format=csv&endtime={1}%2023:59:59&maxmagnitude=10&orderby=time-asc"

startRange = datetime.date(1900, 1, 1)
endRange = datetime.datetime.now().date()

for i in daterange(startRange, endRange, step):
	start = i.strftime(date_format)
	end = (i+datetime.timedelta(days=step-1)).strftime(date_format)
	query = os.path.join(DOWNLOADS_DIR, start + "_" + end + ".csv")
	
	try:
		if not os.path.isfile(query):
			urllib.urlretrieve(url.format(start, end), query)
			print ("Downloading results for " + start + " to " + end)
	except:
		print ("Could not download for " + start + " to " + end)
		
		
		

with open('../processing/poseidon/data/quakes.csv', 'wb') as result:
	a = unicodecsv.writer(result, encoding='utf-8')
	i = 0
	result.write("time,latitude,longitude,depth,mag,rms\r\n") 
	
	for i in daterange(startRange, endRange, step):
		start = i.strftime(date_format)
		end = (i+datetime.timedelta(days=step-1)).strftime(date_format)
		query = os.path.join(DOWNLOADS_DIR, start + "_" + end + ".csv")
		
		
		with open(query, "rb") as source:
			rdr = csv.reader( source )
			wtr = csv.writer( result )
			next(rdr)
			for row in rdr:
				wtr.writerow( (row[0], row[1], row[2], row[3], row[4], row[9]) ) 