#!/usr/bin/env python

# Copyright (C) 2012-2013 Sarah Nadi <snadi@uwaterloo.ca>

import subprocess
import re, os
import sys
import pprint
import argparse
import sqlite3
import inflect


def get_stats(database):
	
	inflictEngine = inflect.engine()
	
	def emit(key, value):
                print "\pgfkeyssetvalue{/versuchung/exploratory/%s}{%s}" % \
                    (key, value)
	
	conn = sqlite3.connect(database)

	curser = conn.cursor()
	
	referentialFilter =  'and defects.filename LIKE \'%missing%\''

	# number of anomalies solved by patches
	curser.execute('SELECT count(ticket) from defects where ticket IS NOT NULL ' + referentialFilter)
	numOfAnomalies =curser.fetchone()[0]

	#number of patches submitted
	curser.execute('select COUNT(*) from ticket where id IN (SELECT ticket from defects where ticket IS NOT NULL ' + referentialFilter + 				')')
	numOfPatches =curser.fetchone()[0]

	#number of patches accepted	
	curser.execute('select COUNT(*) from ticket where id IN (SELECT ticket from defects where ticket IS NOT NULL ' + referentialFilter +  				') and ticket.resolution = \'accepted\'')
	numOfAccepted = curser.fetchone()[0] 

	#number of no reply
	curser.execute('select COUNT(*) from ticket where id IN (SELECT ticket from defects where ticket IS NOT NULL ' + referentialFilter +  				') and ticket.resolution = \'no_reply\'')
	numOfNoReply = curser.fetchone()[0] 

	#number of rejected
	curser.execute('select COUNT(*) from ticket where id IN (SELECT ticket from defects where ticket IS NOT NULL ' + referentialFilter +  				') and ticket.resolution = \'rejected\'')
	numOfRejected = curser.fetchone()[0] 

	#number of ack_diffpatch
	curser.execute('select COUNT(*) from ticket where id IN (SELECT ticket from defects where ticket IS NOT NULL ' + referentialFilter +  				') and ticket.resolution = \'ack_diffpatch\'')
	numOfAckDiffPatch = curser.fetchone()[0] 

	#number of ack_willkeep
	curser.execute('select COUNT(*) from ticket where id IN (SELECT ticket from defects where ticket IS NOT NULL ' + referentialFilter +  				') and ticket.resolution = \'ack_willkeep\'')
	numOfAckWillKeep = curser.fetchone()[0] 

	#number of ack_under_progress
	curser.execute('select COUNT(*) from ticket where id IN (SELECT ticket from defects where ticket IS NOT NULL ' + referentialFilter +  				') and ticket.resolution = \'ack_under_progress\'')
	numOfAckUnderProgress = curser.fetchone()[0] 

	#number of patches removing dead code
	curser.execute('select COUNT(*) from ticket where id IN (SELECT ticket from defects where ticket IS NOT NULL ' + referentialFilter +  				') and patch_type=\'RM_DEAD_CODE\'')
	numRemoveDeadCode = curser.fetchone()[0] 


	#number of patches correcting feature name
	curser.execute('select COUNT(*) from ticket where id IN (SELECT ticket from defects where ticket IS NOT NULL ' + referentialFilter +  				') and patch_type=\'CORRECT_FEATURE_NAME\'')
	numCorrectFeatureName = curser.fetchone()[0] 

	#number of accepted patches correcting feature name
	curser.execute('select COUNT(*) from ticket where id IN (SELECT ticket from defects where ticket IS NOT NULL ' + referentialFilter +  				') and patch_type=\'CORRECT_FEATURE_NAME\' and resolution=\'accepted\'')
	numCorrectFeatureNameAccepted = curser.fetchone()[0] 

	#number of patches removing dead code and dead feature
	curser.execute('select COUNT(*) from ticket where id IN (SELECT ticket from defects where ticket IS NOT NULL ' + referentialFilter +  				') and patch_type=\'RM_DEAD_FEATURE_RM_DEAD_CODE\'')
	numRemoveDeadCodeFeature = curser.fetchone()[0] 

	#number of patches removing redundant code
	curser.execute('select COUNT(*) from ticket where id IN (SELECT ticket from defects where ticket IS NOT NULL ' + referentialFilter +  				') and patch_type=\'RM_REDUNDANT_CODE\'')
	numRemoveRedundant = curser.fetchone()[0] 

	#number of patches removing dead code and editing kconfig dep
	curser.execute('select COUNT(*) from ticket where id IN (SELECT ticket from defects where ticket IS NOT NULL ' + referentialFilter +  				') and patch_type=\'RM_DEAD_CODE_EDIT_KCONFIG_DEP\'')
	numRemoveDeadEditKconfig = curser.fetchone()[0] 	


	emit("numOfAnomalies", numOfAnomalies)
	emit("numOfPatches", numOfPatches)
	emit("numOfAccepted", numOfAccepted)
	emit("numOfAcceptedText", inflictEngine.number_to_words(numOfAccepted))
	emit("numOfRejected", numOfRejected)
	emit("numOfRejectedText", inflictEngine.number_to_words(numOfRejected))
	emit("numOfAck", numOfAckDiffPatch + numOfAckWillKeep + numOfAckUnderProgress)
	emit("numOfAckText", inflictEngine.number_to_words(numOfAckDiffPatch + numOfAckWillKeep + numOfAckUnderProgress))
	emit("numOfAckDiffPatch", numOfAckDiffPatch)
	emit("numOfAckDiffPatchText", inflictEngine.number_to_words(numOfAckDiffPatch))
	emit("numOfAckWillKeep", numOfAckWillKeep)
	emit("numOfAckWillKeepText", inflictEngine.number_to_words(numOfAckWillKeep))
	emit("numOfNoReply", numOfNoReply)
	emit("numOfNoReplyText", inflictEngine.number_to_words(numOfNoReply))
	emit("numOfAckUnderProgress", numOfAckUnderProgress)
	emit("numOfAckUnderProgressText", inflictEngine.number_to_words(numOfAckUnderProgress))	
	emit("numRemoveDeadCode", numRemoveDeadCode)
	emit("numCorrectFeatureName", numCorrectFeatureName)
	emit("numCorrectFeatureNameAccepted", numCorrectFeatureNameAccepted)
	emit("numCorrectFeatureNameAcceptedText", inflictEngine.number_to_words(numCorrectFeatureNameAccepted))
	emit("numRemoveDeadCodeFeature", numRemoveDeadCodeFeature)
	emit("numRemoveRedundant", numRemoveRedundant)
	emit("numRemoveDeadEditKconfig", numRemoveDeadEditKconfig)


def main():

 	parser = argparse.ArgumentParser(

        description='Extracts statistics for exploratory study from defect database ',
        	epilog="Expects database file")

	parser.add_argument('--database', metavar='database', required=True,help='Database file with submitted defects')
	
	args = parser.parse_args()

	get_stats(args.database)




if __name__ == "__main__":
    main()



