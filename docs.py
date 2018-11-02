#!/usr/bin/env python

import sys
import os
from os import path, getcwd
from glob import glob
import subprocess

DOC_DIR=path.normpath(path.join(os.environ['HOME'],"GDrive","Reference"))

# print(DOC_DIR)

start_dir = getcwd()
os.chdir(DOC_DIR)

doc_type = sys.argv[1].lower() if len(sys.argv) > 1 else 'k8'

match_strings = {
	'k8' : ['kube'],
	'dock' : ['dock'],
	'bash' : ['bash'],
	'rst' : ['rst'],
	'cheat': ['cheat']
}

docs = []
matches = 0

for doc_name in glob('*.pdf'):
	if doc_type in match_strings:
		strings_to_match = match_strings[doc_type]
	else:
		strings_to_match = [doc_type]
		
	for match_string in strings_to_match:
		if match_string in doc_name.lower():
			docs.append(doc_name)


docs.sort()

for doc in docs:
	matches += 1
	print("{0}: {1}".format(matches, doc))

leave = False
try:
	raw_input = input(": ")
	if raw_input.lower() == 'q':
		leave = True
except EOFError:
	leave = True

if leave:	
	os.chdir(start_dir)
	sys.exit(0)

selection = int(raw_input)
doc = docs[selection - 1]

doc  = path.normpath(path.join(DOC_DIR,doc))
subprocess.call(["open",doc])

os.chdir(start_dir)

sys.exit(0)

