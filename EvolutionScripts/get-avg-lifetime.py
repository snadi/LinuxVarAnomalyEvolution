#!/usr/bin/env python

# Copyright (C) 2012-2013 Sarah Nadi <snadi@uwaterloo.ca>

import re, os
import sys
import pprint
import argparse
import csv
import numpy

def percentage(part, whole):
  return round(100.00 * float(part)/float(whole))

def get_int_version_num(version):

	int_version = -1

	if version[1] == '3':
		int_version = version[(version.rfind('.') + 1):]
		int_version = 40 + int(int_version)
	elif version[1] == '2':
		int_version = version[version.rfind('.') + 1:]

	return int(int_version)

def get_lifetime_stats(herodotos_data, start_release, end_release, tex_file):

	#format of data: ['defect_no', 'classification', 'filename', 'firstversion', 'lastversion', 'line_in_first_version']

	
	lifetimes = 0
	counted_anomalies = 0
	full_history = 0
	no_end = 0
	lifetime_array = []
	missing_anomalies =0

	for anomaly in herodotos_data:

		#only look at referential anomalies
		if 'Missing' not in anomaly['classification']:
			continue

		missing_anomalies = missing_anomalies  + 1
		anomaly_start_version = get_int_version_num(anomaly['firstversion'])
		anomaly_end_version  = get_int_version_num(anomaly['lastversion'])

		#only analyze entries within our range (start_release to end_release)
		#this means that the anomaly's end release should not be before our start_release
		#and its start release should not be after our end_release

		if anomaly_end_version >= start_release and anomaly_start_version <= end_release:
		
			#anomalies ending in the end_release means they have not been fixed yet
			if True:#anomaly_end_version != end_release:
				full_history = full_history + 1
				#add 1 so anomaly appearing in only one release still gets a lifetime of 1
				anomaly_lifetime = anomaly_end_version - anomaly_start_version + 1
	
				if(anomaly_lifetime != 0):
					counted_anomalies = counted_anomalies + 1 
					lifetimes = lifetimes + anomaly_lifetime
					lifetime_array.append(anomaly_lifetime)

			else:
				no_end = no_end + 1

			
	print 'full history', full_history
	print 'no end', no_end
	print 'counted anomalies', counted_anomalies
	print 'std dev','{0:.0g}'.format(round(numpy.std(lifetime_array),0))
	print 'max', numpy.max(lifetime_array)
	print 'min', numpy.min(lifetime_array)
	print 'average lifetime', '{0:.3g}'.format(round(numpy.mean(lifetime_array),0))
	
	def emit(key, value):
               print "\pgfkeyssetvalue{/versuchung/herodotos/%s}{%d}" % \
        		            (key, value)

	def emit(key, value):
               print "\pgfkeyssetvalue{/versuchung/herodotos/%s}{%s}" % \
        		            (key, value)
        
	

	texfile = open(tex_file, 'a')
	sys.stdout = texfile

	emit("full_hist_anomalies", full_history)  
	emit("total_missing", missing_anomalies)
	emit("no_end_anomalies", no_end)
	emit("avg_lifetime", '{0:.3g}'.format(round(numpy.mean(lifetime_array),0)))
	emit("max",numpy.max(lifetime_array) )
	emit("min", numpy.min(lifetime_array))
	emit("stdev",  '{0:.0g}'.format(round(numpy.std(lifetime_array))))

	
def main():
 	parser = argparse.ArgumentParser(description='Get avg lifetime of referential anomalies from Herodotos data',
        	epilog="Needs Herodotos data to be extracted")
 
	parser.add_argument('--herodotos', metavar='herodotos', required=True,help='csv file containing Herodotos data')
	parser.add_argument('--lastrelease',metavar='lastrelease', required=True, help='last release examined to indicate those that have not been fixed yet')
	parser.add_argument('--startrelease',metavar='startrelease', required=True, help='first release we want to start examining')
	parser.add_argument('--tex',metavar='tex', required=True, help='Tex file with paper data')
	args = parser.parse_args()

	
	herodotos_data = csv.DictReader(open(args.herodotos), delimiter='\t')

	get_lifetime_stats(herodotos_data, get_int_version_num(args.startrelease),get_int_version_num(args.lastrelease), args.tex)
	
		

	
if __name__ == "__main__":
    main()
        

       
