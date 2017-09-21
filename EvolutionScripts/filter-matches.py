#!/usr/bin/env python

# Copyright (C) 2012-2013 Sarah Nadi <snadi@uwaterloo.ca>

import re, os
import sys
import pprint
import argparse
import datetime
from datetime import datetime

def filter_fixes(matches, new_matches):
	matched_fixes = [p for p in matches if p['relation-type'] == "possible fix"]
	matched_defects = set(p['defect'] for p in matched_fixes)
	
	for defect in matched_defects:
		related_matches = [x for x in matched_fixes if x['defect'] == defect]
		earliest_fix = None
		earliest_date = None
		seenCommits = set()
		for related_match in related_matches:
			if(related_match['commit'] in seenCommits):
				continue

			seenCommits.add(related_match['commit'])

			commitDate = datetime.strptime(related_match['commit-date'], '%a %b %d %H:%M:%S %Y')
			if earliest_fix:				
				if (commitDate < earliest_date):
					earliest_date = commitDate
					earliest_fix = related_match['commit']
			else: #first commit
				earliest_date = commitDate
				earliest_fix = related_match['commit']

		filtered_results = [x for x in related_matches if x['commit'] == earliest_fix]

		matched_features = set()
		for result in filtered_results:
			toPrint = result
			matched_features.add(result['matched feature'])

		new_matches.append({"defect": toPrint['defect'], "commit": toPrint['commit'], "commit-date":toPrint['commit-date'], "relation-type":toPrint['relation-type'], "matched feature": list(matched_features), 'commit type': toPrint['commit type']})
		
	return new_matches

def filter_causes(matches):
	new_matches = []
	matched_causes = [p for p in matches if p['relation-type'] == "possible cause"]
	matched_defects = set(p['defect'] for p in matched_causes)
	
	for defect in matched_defects:
		related_matches = [x for x in matched_causes if x['defect'] == defect]
		latest_cause = None
		latest_date = None
		for related_match in related_matches:
			commitDate = datetime.strptime(related_match['commit-date'], '%a %b %d %H:%M:%S %Y')
			if latest_cause:				
				if (commitDate > latest_date):
					latest_date = commitDate
					latest_cause = related_match['commit']
			else: #first commit
				latest_date = commitDate
				latest_cause = related_match['commit']

		filtered_results = [x for x in related_matches if x['commit'] == latest_cause]

		matched_features = set()

		for result in filtered_results:
			toPrint = result
			matched_features.add(result['matched feature'])

		new_matches.append({"defect": toPrint['defect'], "commit": toPrint['commit'], "commit-date":toPrint['commit-date'], "relation-type":toPrint['relation-type'], "matched feature": list(matched_features), 'commit type': toPrint['commit type']})
		
	return new_matches

def main():
 	parser = argparse.ArgumentParser(

        description='Filters the mapping of defects and commits such that defects get matched to the most recent commit',
        	epilog="Run after mapping occurs")

	parser.add_argument('--release', metavar='release', required=True,help='Release for which matching is made')
    	parser.add_argument(
        	'--matches', metavar='matches', required=True,
        	help='Feature Renames File')

	args = parser.parse_args()

	matches = eval(open(args.matches).read())
	
	new_matches = filter_fixes(matches, filter_causes(matches))

	pprint.pprint(new_matches)
	
			

	
if __name__ == "__main__":
    main()
        

       
