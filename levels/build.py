#!/usr/bin/python

from struct import *
import os

def bin (num): 
	return pack('>i', num)

input = open('levels.list')

filenames = []

for line in input:
	filename = line.strip()
	
	if filename and not filename.startswith('#'):
		filenames.append(filename)

input.close()

output = open('all.lvl', 'wb')

output.write(bin(len(filenames)))

for filename in filenames:
	filesize = os.path.getsize(filename)
	
	output.write(bin(filesize));
	
	file = open(filename, 'rb')
	
	output.write(file.read())
	
	file.close()

output.close()

