#!/usr/bin/env python

# Copyright (C) 2012-2013 Sarah Nadi <snadi@uwaterloo.ca>

import re, os
import sys
import pprint
import argparse
import datetime
from datetime import datetime

def getReleaseDates():
	releaseDates = {}
	dateFile = f = open('tagDates.txt', 'r')
	for line in f:
		release, sep, date = line.partition(' ')
		dateObj = datetime.strptime(date.strip(), '%a %b %d %H:%M:%S %Y')
		releaseDates[release.strip()] = dateObj

	return releaseDates

def get_filename_from_defect(name):
    path, filename = os.path.split(name)
    blockno, what, scope, kind = filename.split('.')[-4:]
    f = "%s" % ('.'.join(filename.split('.')[:-4]))
         
    return os.path.join(path, f)

def find_pairs(cpp_commits, refDefects, releaseDate):
	matchedPairs = []
	for defect in refDefects:
		missingFeatures = defect['Actual Missing']
		filename = get_filename_from_defect(defect['defect'])
		#missingFeatures = defect['All Missing Features']
	
		relationType = ""
		for missingFeature in missingFeatures:
			for commit in cpp_commits:
				for change in commit['changes']:
					if missingFeature in change['features removed']:
						relationType = None
						if not filename == change['file']:
							continue

						commitDate = datetime.strptime(commit['date'], '%a %b %d %H:%M:%S %Y')
										
						if(commitDate >= releaseDate):						
							relationType="possible fix"
						

						if relationType:
							toPrint = {"defect": defect['defect'], "commit": commit['commit'], "commit-date":commit['date'],"relation-type":relationType, "matched feature": missingFeature, 'commit type': change['change-type']}
							matchedPairs.append(toPrint)
							break #already matched with one change in this commit, no need to match the rest since 
								#won't change the stats
			
	
	pprint.pprint(matchedPairs)


def main():
 	parser = argparse.ArgumentParser(

        description='Matches the missing features in undertaker defects to the feature changes in git commits',
        	epilog="Run in a directory containing dict file with missing features and dict file with git commits")

	parser.add_argument('--release', metavar='release', required=True,help='Release for which matching is made')
    	parser.add_argument(
        	'--cpp', metavar='cpp', required=True,
        	help='Feature Renames File')

	parser.add_argument(
        	'--missing', metavar='missing', required=True,
        	help='Missing Features File')

	args = parser.parse_args()
	
	releaseDates = getReleaseDates()

	cpp_commits = eval(open(args.cpp).read())
	refDefects = eval(open(args.missing).read())

	find_pairs(cpp_commits, refDefects, releaseDates[args.release])
			

	
if __name__ == "__main__":
    main()
        

       
