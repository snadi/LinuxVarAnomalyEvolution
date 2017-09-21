# Copyright (C) 2012-2013 Christian Dietrich <dietrich@cs.fau.de>
# Copyright (C) 2012-2013 Sarah Nadi <snadi@uwaterloo.ca>

import subprocess
import re, os
import sys
import pprint
import traceback

try:
    import fuzzy
except:
    print "Sorry no fuzzy module was found, please copy the fuzzy.so in the current folder"

patch_line_regex = re.compile("^[+-][^+-]")
cpp_remove_line_regex = re.compile("^-#\s*(if.*CONFIG_|elif.*CONFIG)")
cpp_add_line_regex = re.compile("^([+])#\s*(if.*CONFIG_|elif.*CONFIG)")
cpp_line_regex = re.compile("^([+-])#\s*(if.*CONFIG_|elif.*CONFIG)")
kconfig_feature_regex = re.compile("CONFIG_[a-zA-Z0-9_]+")

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

def extract_features(commit_line):
	if ("CONFIG_" not in commit_line):
		return set()
	return set(kconfig_feature_regex.findall(commit_line))

def getRenames(removed, added):
	renames = []
	i = 0
	while i < len(removed):
		if removed[i] != added[i]: #diff features
			renames.append([removed[i]] + [added[i]])
		i = i + 1

	return renames

def find_rename_in_stream(stream):
	renames = []
	if len(stream) < 2:
		return renames

	index = 0

	while index < len(stream) - 1:
		first = stream[index]
		second = stream[index + 1]
		# a rename must have the same number of features, features must be different, and must be a remove followed by an add
		if len(first) == len(second) and first[0] != second[0] and first[0] == 'remove' and \
		   second[0] == 'add' and set(first[1:]) != set(second[1:]):
			renames.append(getRenames(first[1:], second[1:]))			

		index = index + 1                   	

	return renames

def cpp_classify_commit(patch, commit_hash):

    	source_files = []
    	changes =[]

    	partitions = partition_patch(patch)	

	for (filename, at_line, patch_lines) in partitions:
		if not ".c" in filename and not ".S" in filename and not ".h" in filename:
		    continue

    		config_minus = set()
    		config_plus = set()

        	source_files.append(filename)

                feature_stream = []

                one_more_line = False
		for line_ in patch_lines:
                    # Multi line merge
                    if one_more_line:
                        one_more_line = False
                        line += " " + line_
                    else:
                        line = line_
                    if len(line.strip()) > 0 and line.strip()[-1] == '\\':
                        one_more_line = True
                        continue

		    if cpp_remove_line_regex.match(line):
                        minus = extract_features(line)
			config_minus = config_minus | minus
                        feature_stream.append(['remove'] + list(minus))

		    if cpp_add_line_regex.match(line):
                        plus = extract_features(line)
			config_plus = config_plus | plus
                        feature_stream.append(['add'] + list(plus))
		
 

    		minus_unique = config_minus - config_plus
		plus_unique  = config_plus  - config_minus
    		common = config_minus & config_plus

    		change_type = None
		renamed_features = find_rename_in_stream(feature_stream)
	

    		if len(config_minus) > 0 and len(config_minus) == len(config_plus) and set(config_minus) == set(config_plus):
			change_type = "Feature move"
			
		elif len(renamed_features) > 0:
			change_type = "Feature rename"		    
    	
    		elif len(config_minus - config_plus) > 0:
			change_type = "Features removed"
	
		elif len(config_plus - config_minus) > 0:
			change_type = "Features added"

		elif len(config_plus | config_minus) > 0:
       			change_type = "Unclassified"
		
    		if change_type:
				change={"file":filename, 
                                "feature change stream": feature_stream,
                                "features removed":list(minus_unique), 
                                "features common": list(common), 
                                "features added": list(plus_unique), 
				"features renamed": renamed_features,
                                "change-type": change_type}
				changes.append(change)
		

	if changes:
		return {"changes":changes}	
	

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

def does_only_touch_cpp(patch):
    difference_lines = [l for l in patch if patch_line_regex.match(l)]
    if all([cpp_line_regex.match(x) for x in difference_lines]) \
            and len(difference_lines) > 0:
        return True
    return False

def process_commit(commit):
    patch = extract_patch(commit)
    commit_hash = ""
    if commit:
	commit_hash = commit[0].split()[1]

   # if commit_hash != '2984b52b07ce45495700ce82f085800431b79cdc':
	#return	

    try:
	action = cpp_classify_commit(patch, commit_hash)
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
	    if count > 100 and False:
		break

	    ret = process_commit(commit)
	    if ret:
		commit_list.append(ret)		
		#pprint.pprint(ret, stream = sys.stderr)	

	    commit = [line.strip()]
	else:
	    commit.append(line.strip())

    pprint.pprint(commit_list)

if __name__ == "__main__":
    main()

