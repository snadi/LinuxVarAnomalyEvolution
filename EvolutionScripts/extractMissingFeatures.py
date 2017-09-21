#!/usr/bin/env python

# Copyright (C) 2012-2013 Sarah Nadi <snadi@uwaterloo.ca>
# Copyright (C) 2011-2012 Reinhard Tartler <tartler@informatik.uni-erlangen.de>
# Copyright (C) 2012-2013 Christian Dietrich <dietrich@cs.fau.de>

import logging
import os.path
import errno
import re
import sys
import pprint
import subprocess
import argparse

def find_deads(source_tree):
    deads = set()
    missing_file_regex = re.compile(".*missing.globally.*dead")
    for root, _, files in os.walk(source_tree):
	for f in files:
	    if missing_file_regex.match(f):
			d=os.path.join(root, f)
			deads.add(os.path.normpath(d))

    logging.info("detected %d defects", len(deads))
    return deads

def extractMissingFeatures(filename):
    with open(filename, 'r') as f:
		for line in f:
			if line.startswith('( !'):
				config_feature_regex = re.compile("CONFIG_[^\s]*")
				missing_features = config_feature_regex.findall(line)
				return missing_features

def reader(socket):
	for line in socket:
	    yield line

def getRealMissing(all_defined_features, missing_features):
    actual_missing = set()
    for i in missing_features:
        flag = i
        if flag.endswith("_MODULE"):
            flag = i[:-len("_MODULE")]
        if not flag in all_defined_features:
            actual_missing.add(i) # With the _MODULE suffix

    return actual_missing


def process_referential_defect(all_defined_features, defect):
    missing_features = extractMissingFeatures(dead)
    actual_missing = getRealMissing(all_defined_features, missing_features)
    return {"defect": dead, "All Missing Features": list(missing_features), "Actual Missing": list(actual_missing)}

def shell(command, *args):
    os.environ["LC_ALL"] = "C"
    command = command % args
    p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
    (stdout, _)  = p.communicate() # ignore stderr
    p.wait()
    if len(stdout) > 0 and stdout[-1] == '\n':
        stdout = stdout[:-1]

    return (stdout.__str__().rsplit('\n'), p.returncode)


def find_all_features():
    """Read all the defined symbols from the model files"""
    cmd = "find -type f -name '*Kconfig*' -exec egrep '^\s*(menu)?config\s+' {} \; | sed 's/^.*config\s*/CONFIG_/;'"
    features_defined = set(shell(cmd)[0])
    pprint.pprint(len(features_defined), stream = sys.stderr)
    assert len(features_defined) > 1000
    return features_defined # This contains not the the "_MODULE"
    # features. Therefore its len is < 12000. Don't be surprised!

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)

    all_defined_features = find_all_features()
    logging.info("Found %d declared features", len(all_defined_features))

    defect_list = []
    deads = find_deads(os.curdir)
    for dead in deads:
        ret = process_referential_defect(all_defined_features, dead)
        if ret:
		    defect_list.append(ret)
		    pprint.pprint(ret, stream = sys.stderr)

    pprint.pprint(defect_list)


