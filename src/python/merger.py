import os.path
import os
import unicodecsv
import datetime

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
rowcount = 0

with open('merged.csv', 'wb') as f:
	a = unicodecsv.writer(f, encoding='utf-8')
	i = 0
		
	startRange = datetime.date(1900, 1, 1)
	endRange = datetime.date(2014, 12, 31)
	
	for i in daterange(startRange, endRange, step):
		start = i.strftime(date_format)
		end = (i+datetime.timedelta(days=step-1)).strftime(date_format)
		query = os.path.join(DOWNLOADS_DIR, start + "_" + end + ".csv")
		
		with open(query) as csv:
			next(csv)
			for line in csv:
				f.write(line)