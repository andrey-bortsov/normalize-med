#!/bin/bash
inputList="inputFileList.txt"
i=1
while read inputfile
do
outputfile="normalizedMed"
extension=".csv"
./normMed.sh <"$inputfile" >>"$outputfile$i$extension"
i=$((i+1))
done < "$inputList"
