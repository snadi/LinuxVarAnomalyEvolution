#!/usr/bin/env python

# Copyright (C) 2012-2013 Sarah Nadi <snadi@uwaterloo.ca>

import re, os
import sys
import pprint
import argparse

def percentage(part, whole):
  return "{0:.0f}".format(100.00 * float(part)/float(whole))

def get_rename_commits(commits):
	rename_commits = []
	for commit in commits:
		for change in commit['changes']:
			if 'rename' in change['change-type']:
				rename_commits.append(commit)
				break
	return rename_commits

def get_stats(cppCommits, kconfigCommits, typos):
		
	def emit(key, value):
                print "\pgfkeyssetvalue{/versuchung/typos/%s}{%s}" % \
                    (key, value)
	
	numOfCPPCommits = len(cppCommits)
	numOfRenames = len(get_rename_commits(cppCommits))
	percOfRenames= percentage(numOfRenames, numOfCPPCommits)
	numOfPossibleTypos = len(typos)
	numOfVerifiedTypos = len([x for x in typos if 'typo' in x['classification']])
	
	emit("numOfCPPCommits", "{:,}".format(numOfCPPCommits))
	emit("numOfCPPRenames", "{:,}".format(numOfRenames))
	emit("numOfKconfigCommits", "{:,}".format(len(kconfigCommits)))
	emit("numOfPossibleTypos", numOfPossibleTypos)
	emit("numOfVerifiedTypos", numOfVerifiedTypos)
	emit("percOfPossibleTypos", percentage(numOfPossibleTypos, numOfRenames))
	emit("percOfVerifiedTypos", percentage(numOfVerifiedTypos, numOfPossibleTypos))
	emit("percOfTypoCommits", percentage(numOfVerifiedTypos, numOfRenames))

def main():

 	parser = argparse.ArgumentParser(

        description='Extracts statistics for typo analysis and also number of cpp and kconfig commits ',
        	epilog="Expects typos and cpp commits files")

	parser.add_argument('--cppCommits', metavar='cppCommits', required=True,help='CPP commits dict')
	parser.add_argument('--typos', metavar='typos', required=True,help='CPP typo commits dict')
	parser.add_argument('--kconfigCommits', metavar='kconfigCommits', required=True,help='Kconfig commits dict')
	
	args = parser.parse_args()
	
	cppCommits = eval(open(args.cppCommits).read())
	kconfigCommits =eval(open(args.kconfigCommits).read())
	typos = eval(open(args.typos).read())

	get_stats(cppCommits, kconfigCommits, typos)




if __name__ == "__main__":
    main()



