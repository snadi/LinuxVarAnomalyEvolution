#!/usr/bin/env python

# Copyright (C) 2012-2013 Sarah Nadi <snadi@uwaterloo.ca>

import re, os
import sys
import pprint
import argparse
import logging
import collections

try:
    import fuzzy
except:
    print "Sorry no fuzzy module was found, please copy the fuzzy.so in the current folder"


def permutation_equal(str1, str2):
    """Check if two strings are equal when the substrings (splitted by _) are permuated"""
    return set(str1.split("_")) == set(str2.split("_"))

def phonetic_equal(str1, str2):
    """Check if two strings are equal when the substrings (splitted by _) are permuated"""
    if "fuzzy" in dir():
	return False

    dm = fuzzy.DMetaphone()

    if [dm(x) for x in str1.split("_")] == [dm(x) for x in str2.split("_")]:
	return True

def feature_rename_fuzzy(feature1, feature2, equal):
    if equal(feature1, feature2):
	return True
    return False


def words(text): return re.findall('[a-z]+', text.lower()) 

def train(features):
    model = collections.defaultdict(lambda: 1)
    for f in features:
        model[f] += 1
    return model

alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_'

def edits1(word):
   splits     = [(word[:i], word[i:]) for i in range(len(word) + 1)]
   deletes    = [a + b[1:] for a, b in splits if b]
   transposes = [a + b[1] + b[0] + b[2:] for a, b in splits if len(b)>1]
   replaces   = [a + c + b[1:] for a, b in splits for c in alphabet if b]
   inserts    = [a + c + b     for a, b in splits for c in alphabet]
   return set(deletes + transposes + replaces + inserts)
  
def known_edits2(word1, word2):
    return set(e2 for e1 in edits1(word1) for e2 in edits1(e1) if e2 == word2)

def known(words, word2): 
	for word in words:
		if word == word2:
			return word

def correct(word1,word2):
    #give priorities to one edits
    oneEdit = known(edits1(word1), word2)
    twoEdits = known_edits2(word1,word2)
    if oneEdit:
	return oneEdit
    elif twoEdits:
	return twoEdits
    else:
	return None      

def get_rename_commits(commits):
	rename_commits = []
	for commit in commits:
		for change in commit['changes']:
			if 'rename' in change['change-type']:
				rename_commits.append(commit)
				break
	print >> sys.stderr, len(rename_commits)
	return rename_commits

def find_typos(commits):
	matchedPairs = []
	commitNum = 0
	rename_commits = get_rename_commits(commits)
	count = 0
	for commit in rename_commits:
		count = count + 1
		print >> sys.stderr, count
		possibleTypos= []
		for change in commit['changes']:
			if 'rename' in change['change-type']:
				for rename_pair in change['features renamed']:
					if feature_rename_fuzzy(rename_pair[0], rename_pair[1], equal = permutation_equal):
						possibleTypos.append({'addedFeature':rename_pair[0], 'removedFeature': rename_pair[1]})
					elif correct(rename_pair[0],  rename_pair[1]):				
						possibleTypos.append({'addedFeature': rename_pair[0], 'removedFeature': rename_pair[1]})					
			
		if(len(possibleTypos) > 0):
			pair = {"commit":commit['commit'], "possible typos":list(possibleTypos), "classification": "''"}
			matchedPairs.append(pair)			

	pprint.pprint(matchedPairs)

def main():
 	parser = argparse.ArgumentParser(

        description='Find if the renames in commits were correcting typos',
        	epilog="Run after git history is already extracted")


	parser.add_argument('--commits', metavar='commits', required=True, help='File with extracted commits')

    	args = parser.parse_args()

	commits = eval(open(args.commits).read())

	find_typos(commits)
			

	
if __name__ == "__main__":
    main()
        

       
