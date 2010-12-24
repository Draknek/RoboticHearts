#!/usr/bin/python

from struct import *
import os

def bin (num): 
	return pack('>i', num)

input = open('levels.list')

levels = input.read().split("\n\n")

filenames = []
story = []

for info in levels:
	info = info.strip()
	
	if not info or info.startswith('#'):
		continue
	
	parts = info.split("\n")
	
	if (len(parts) > 1):
		filename = parts[1]
		story.append(parts[0])
	else:
		filename = parts[0]
		story.append("")
	
	filename = filename.strip()
	
	filenames.append(filename + '.lvl')

input.close()

output = open('story.txt', 'w')

for line in story:
	output.write(line.strip())
	output.write("\n")

output.close()

output = open('all.lvl', 'wb')

output.write(bin(len(filenames)))

for filename in filenames:
	filesize = os.path.getsize(filename)
	
	output.write(bin(filesize));
	
	file = open(filename, 'rb')
	
	output.write(file.read())
	
	file.close()

output.close()

