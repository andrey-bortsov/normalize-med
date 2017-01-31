#!/bin/bash
# This is a wrapper script for normMed.sh to process medication files in batches.
# List of medication files (one filename per line) should be saved in 
# inputFileList.txt in the same directory.
# The script iterates through the list of files and saves the output for each
# file in normalizedMed*.csv, where *=1,2,3...
#
# Author: Andrey Bortsov bortzov@gmail.com
#
# Created: Jan 15, 2017
# Last modified: Jan 27, 2017

inputList="inputFileList.txt"
i=1
while read inputfile
do
   outputfile="normalizedMed"
   extension=".csv"
   ./normMed.sh <"$inputfile" >>"$outputfile$i$extension"
   i=$((i+1))
done < "$inputList"
