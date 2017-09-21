# Copyright (C) 2012-2013 Christian Dietrich <dietrich@cs.fau.de>


import subprocess
import re, os
import sys
import pprint
import traceback

try:
    import fuzzy
except:
    print "Sorry no fuzzy module was found, please copy the fuzzy.so in the current folder"

def git_log(args = "-p --format=fuller"):
    return subprocess.Popen("git log %s 2>&1" % args, shell=True, stdout=subprocess.PIPE)

def extract_patch(commit):
    patch = []
    match = False
    for line in commit:
	if match:
	    patch.append(line)
	if line.startswith("diff --git"):
	    patch.append(line)
	    match = True
    return patch

def remove_prefixes(string, prefixes):
    touched = True
    while touched:
        touched = False
        for prefix in prefixes:
            if string.startswith(prefix):
                string = string[len(prefix):]
                touched = True
    return string

def lspatch(patch):
    """Get all files that are touched by this patch"""
    return set([remove_prefixes(x, ["+++ ", "--- ", "b/", "a/"])
                for x in patch
                if x.startswith("+++ ") or x.startswith("--- ")]) - set(["/dev/null"])

def partition_patch(patch):
    """Partition patch into the hunks. Return a list of (filename, at_line, [patch lines])"""

    hunks = []
    actual_hunk = None
    for line in patch:
	if line.startswith("diff --git") and actual_hunk:
	    hunks.append(tuple(actual_hunk))
	    actual_hunk = None
	elif line.startswith("--- "):
	    removed_filename = remove_prefixes(line, ["--- ", "a/"]).strip()
	elif line.startswith("+++ "):
	    added_filename = remove_prefixes(line, ["+++ ", "b/"]).strip()
            filename = added_filename
            if filename == "/dev/null":
                filename = removed_filename
	    actual_hunk = [filename, None,[]]
	elif actual_hunk:
	    if actual_hunk[1] is None:
		actual_hunk[1] = line
	    else:
		actual_hunk[2].append(line)
    if actual_hunk:
	hunks.append(tuple(actual_hunk))
    return hunks

def first_whitespace_in_string(string):
    first_whitespace = 0
    try:
	first_whitespace = string.index(" ")
    except ValueError:
	try:
	    first_whitespace = string.index("\t")
	except ValueError:
	    pass
    return first_whitespace

def permuation_equal(str1, str2):
    """Check if two strings are equal when the substrings (splitted by _) are permuated"""
    return set(str1.split("_")) == set(str2.split("_"))

def phonetic_equal(str1, str2):
    """Check if two strings are equal when the substrings (splitted by _) are permuated"""
    if "fuzzy" in dir():
	return False

    dm = fuzzy.DMetaphone(4)

    if [dm(x) for x in str1.split("_")] == [dm(x) for x in str2.split("_")]:
	return True

def feature_rename_fuzzy(config_minus, config_plus, equal):
    minus_unique = config_minus - config_plus
    plus_unique  = config_plus  - config_minus

    for minus in minus_unique:
	for plus in plus_unique:
	    if equal(minus, plus):
		return True
    return False

def feature_rename_commit(patch):
    config_minus = set()
    config_plus  = set()
    for (filename, at_line, patch_lines) in partition_patch(patch):
	if not "Kconfig" in filename:
	    continue
	for line in patch_lines:
	    if line.startswith("-config") or line.startswith("-menuconfig"):
		config_minus.add("CONFIG_" + line[first_whitespace_in_string(line):].strip())
	    if line.startswith("+config") or line.startswith("+menuconfig"):
		config_plus.add("CONFIG_" + line[first_whitespace_in_string(line):].strip())

    filenames = lspatch(patch)
    if all(["Kconfig" in x for x in filenames]):
	only_kconfig = True
    else:
	only_kconfig = False

    minus_unique = config_minus - config_plus
    plus_unique  = config_plus  - config_minus
    common = config_minus & config_plus

    commit_type = None

    if len(config_minus) > 0 and len(config_minus) == len(config_plus):
	if set(config_minus) == set(config_plus):
	    commit_type = "Feature move"
	else:
	    commit_type = "Feature rename"

    elif feature_rename_fuzzy(config_minus, config_plus, equal = permuation_equal):
	commit_type = "Feature rename (permutation)"

    elif feature_rename_fuzzy(config_minus, config_plus, equal = phonetic_equal):
	commit_type = "Feature rename (sound similar)"

    elif len(config_minus - config_plus) > 0:
	commit_type = "Features removed"

    elif len(config_plus - config_minus) > 0:
	commit_type = "Features added"

    elif len(config_plus | config_minus) > 0:
        commit_type = "Unclassified"



    if commit_type:
	return {"commit-type": commit_type, "Only Kconfig files": only_kconfig,
		"features removed": list(minus_unique), "features common": list(common),
		"features added": list(plus_unique)}

def extract_date(commit):
	date = ""
    	for line in commit:
		if line.startswith("CommitDate:"):
			label, delim, date = line.partition(' ')
			if date.find('-') != -1:
			 	date = date[:date.find('-')].strip()
			elif date.find('+') != -1:
				date = date[:date.find('+')].strip()
	return date


def process_commit(commit):
    patch = extract_patch(commit)
    try:
	action = feature_rename_commit(commit)
    except RuntimeError as e:
        
        print traceback.print_stack(e, file=sys.stderr)
        return
    if action:
	commit_hash = commit[0].split()[1]
	action['commit'] = commit_hash
	date = extract_date(commit)
	action['date'] = date
	return action

def main():
    logger = git_log()
    count = 0
    commit = []

    def reader(socket):
	for line in socket:
	    yield line


    commit_list = []

    for line in reader(logger.stdout):
	if line.startswith("commit") and re.match("commit [0-9a-fA-F]+", line):
	    count += 1
	    if count > 1000 and False:
		break

	    ret = process_commit(commit)
	    if ret:
		commit_list.append(ret)
		pprint.pprint(ret, stream = sys.stderr)

	    commit = [line.strip()]
	else:
	    commit.append(line.strip())

    pprint.pprint(commit_list)

if __name__ == "__main__":
    main()

