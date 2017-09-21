#!/usr/bin/env python

# Copyright (C) 2012-2013 Sarah Nadi <snadi@uwaterloo.ca>

import subprocess
import re, os
import sys
import pprint
import argparse
import datetime
from datetime import datetime

#each release gets two lines of stats. First line is totals, and second is categories
#1st line: Release,Num of Referential Defects, Number of possible cause commits,Number of possible fix commits,Number of unclassified matched commits
#2nd line: 3 columns for each of Matched Possible Cause,Matched Possible Fix,Matched Unclassified to classify the type of commit in each as rename, remove, added

def percentage(part, whole):
  return "{0:.0f}".format(100.00 * float(part)/float(whole))


def get_stats(release, matchedDefectCommits, missingResults, stats_type):

	#only count referential defects that have a non-empty 'Actual Missing' field. Otherwise, they are do not really have missing features,
	#and they will affect the %'s at the end
	actual_missing = [x for x in missingResults if x['Actual Missing'] !=[]]


	poss_cause = [x for x in matchedDefectCommits if x['relation-type'] == "possible cause"]
	poss_fix = [x for x in matchedDefectCommits if x['relation-type'] == "possible fix"]
	unmatched = [x for x in matchedDefectCommits if x['relation-type'] == "maybe related"]

	poss_cause_rename = [x for x in poss_cause if "rename" in x['commit type']]
	poss_cause_remove = [x for x in poss_cause if x['commit type'] == "Features removed"]
	poss_cause_added = [x for x in poss_cause if x['commit type'] == "Features added"]

	poss_fix_rename = [x for x in poss_fix if "rename" in x['commit type']]
	poss_fix_remove = [x for x in poss_fix if x['commit type'] == "Features removed"]
	poss_fix_added = [x for x in poss_fix if x['commit type'] == "Features added"]

	unmatched_rename = [x for x in unmatched if "rename" in x['commit type']]
	unmatched_remove = [x for x in unmatched if x['commit type'] == "Features removed"]
	unmatched_added = [x for x in unmatched if x['commit type'] == "Features added"]

        def emit(key, value):
                print "\pgfkeyssetvalue{/versuchung/defects/correlate/%s/%s}{%s}" % \
                    (release, key, value)


        def count_defects(dicts):
                return len(set(p['defect'] for p in dicts))

        emit("referential defects",   len(actual_missing))

        emit(stats_type + " causing commits/total", count_defects(poss_cause))
	emit(stats_type + " percentage causing commits", percentage( count_defects(poss_cause), len(actual_missing) ) )
        emit(stats_type + " causing commits/rename", count_defects(poss_cause_rename))
        emit(stats_type + " causing commits/remove", count_defects(poss_cause_remove))
        emit(stats_type + " causing commits/added", count_defects(poss_cause_added))


        emit(stats_type + " fix commits/total",     count_defects(poss_fix))
	emit(stats_type + " percentage fix commits", percentage( count_defects(poss_fix), len(actual_missing) ) )
        emit(stats_type + " fix commits/rename", count_defects(poss_fix_rename))
        emit(stats_type + " fix commits/remove", count_defects(poss_fix_remove))
        emit(stats_type + " fix commits/added", count_defects(poss_fix_added))

        emit(stats_type + " unclassified commits/total", count_defects(unmatched))
        emit(stats_type + " unclassified commits/rename", count_defects(unmatched_rename))
        emit(stats_type + " unclassified commits/remove", count_defects(unmatched_remove))
        emit(stats_type + " unclassified commits/added", count_defects(unmatched_added))

#	print release, len(set(p['defect'] for p in poss_cause_rename)), len(set(p['defect'] for p in poss_cause_remove)), len(set(p['defect'] for p in poss_cause_added)), len(set(p['defect'] for p in poss_fix_rename)), len(set(p['defect'] for p in poss_fix_remove)), len(set(p['defect'] for p in poss_fix_added)), len(set(p['defect'] for p in unmatched_rename)), len(set(p['defect'] for p in unmatched_remove)), len(set(p['defect'] for p in unmatched_added))


def main():

 	parser = argparse.ArgumentParser(

        description='Extracts statistics of matched commit-defect pairs ',
        	epilog="Expects to have the matching results ready before running. Also expects file with extracted missing features")

	parser.add_argument('--release', metavar='release', required=True,help='Release')
	parser.add_argument('--matches', metavar='matches', required=True,help='File name with matched results')
	parser.add_argument('--missing', metavar='missing', required=True,help='File name with extracted missing features for each defect')
	parser.add_argument('--type', metavar='type', required=True,help='What are these stats for? CPP or Kconfig matches')

	args = parser.parse_args()

	release = args.release
	matchedDefectCommits = eval(open(args.matches).read())
	missingResults = eval(open(args.missing).read())

	get_stats(release, matchedDefectCommits, missingResults, args.type)




if __name__ == "__main__":
    main()



