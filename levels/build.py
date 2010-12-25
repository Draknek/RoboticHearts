#!/usr/bin/python

from struct import *
import os

def bin (num): 
	return pack('>i', num)

input = open('levels.list')

levels = input.read().split("\n\n")

input.close()

filenames = []
special = []
story = []

for info in levels:
	info = info.strip()
	
	if not info or info.startswith('#'):
		continue
	
	parts = info.split("\n")
	
	if (len(parts) > 1):
		leveldata = parts[1]
		story.append(parts[0])
	else:
		leveldata = parts[0]
		story.append("")
	
	leveldata = leveldata.split("|")
	
	filename = leveldata[0].strip()
	flags = 0
	
	if len(leveldata) > 1:
		flags = int(leveldata[1])
	
	filenames.append(filename + '.lvl')
	special.append(flags)


output = open('all.lvl', 'wb')

output.write(bin(len(filenames)))

i = 0

for filename in filenames:
	flags = special[i]
	
	i+=1
	
	output.write(bin(flags))
	
	filesize = os.path.getsize(filename)
	
	output.write(bin(filesize));
	
	file = open(filename, 'rb')
	
	output.write(file.read())
	
	file.close()

output.close()


output = open('story.txt', 'w')

for line in story:
	output.write(line.strip())
	output.write("\n")

output.close()

