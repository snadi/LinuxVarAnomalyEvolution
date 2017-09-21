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
	
def find_pairs(featureRenames, refDefects, releaseDate):
	matchedPairs = []
	for defect in refDefects:
		missingFeatures = defect['Actual Missing']
		#missingFeatures = defect['All Missing Features']
	
		relationType = ""
		for missingFeature in missingFeatures:				
			commitsFeatureAdded = [x for x in featureRenames if missingFeature in x['features added']]
			commitsFeatureRemoved = [x for x in featureRenames if missingFeature in x['features removed']]

			if commitsFeatureAdded:
				#if the matched feature is in the added features and the commit date is beyond the 
				#defect date then this patch might be a possible fix
				for commit in commitsFeatureAdded:
					commitDate = datetime.strptime(commit['date'], '%a %b %d %H:%M:%S %Y')
						

					if(commitDate < releaseDate):
						relationType="maybe related"
					else:
						relationType="possible fix"
						

					toPrint = {"defect": defect['defect'], "commit": commit['commit'], "commit-date":commit['date'], "relation-type":relationType, "matched feature": missingFeature, 'commit type': commit['commit-type']}
					matchedPairs.append(toPrint)

			if commitsFeatureRemoved:
				#if the matched feature is in the removed features and the commit date is before the 
				#defect date then this patch might be a possible cause
				for commit in commitsFeatureRemoved:
					commitDate = datetime.strptime(commit['date'], '%a %b %d %H:%M:%S %Y')

					if(commitDate < releaseDate):
						relationType="possible cause"
					else:
						relationType="maybe related"
						
					toPrint = {"defect": defect['defect'], "commit": commit['commit'], "commit-date":commit['date'], "relation-type":relationType, "matched feature": missingFeature, 'commit type': commit['commit-type']}
					matchedPairs.append(toPrint)
	
	pprint.pprint(matchedPairs)


def main():
 	parser = argparse.ArgumentParser(

        description='Matches the missing features in undertaker defects to the feature changes in git commits',
        	epilog="Run in a directory containing dict file with missing features and dict file with git commits")

	parser.add_argument('--release', metavar='release', required=True,help='Release for which matching is made')
    	parser.add_argument(
        	'--renames', metavar='renames', required=True,
        	help='Feature Renames File')

	parser.add_argument(
        	'--missing', metavar='missing', required=True,
        	help='Missing Features File')

	args = parser.parse_args()
	
	releaseDates = getReleaseDates()

	featureRenames = eval(open(args.renames).read())
	refDefects = eval(open(args.missing).read())

	find_pairs(featureRenames, refDefects, releaseDates[args.release])
			

	
if __name__ == "__main__":
    main()
        

       
