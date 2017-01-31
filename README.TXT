Author: Andrey Bortsov
Date: 1 31 2017

The purpose of the scripts normalizeMed.sh and normInBatch.sh is to normalize and classify medication data using the online RxNorm and RxClass API.

Input: one medication per line, brand names are allowed, may (but not need to)
have strength (dose) and form (tablet, pill etc). Misspells are allowed.

Output: normalized medication name, strength and form; medication VA class (or DAILYMED class
if VA class is not retrieved); one medication per line.
Only one entry with the highest match score is returned.

Setup instructions:
-setup a Unix machine with internet access
-install jq, a JSON parsing library for bash
-copy the medication files to a directory (medication files are text files, one medication per line, brand names and misspells are allowed)
-create inputFileList.txt, with all medication files listed (one per line)
-copy normalizeMed.sh and normInBatch.sh to the same directory and make them executable 
   chmod +x *.sh
-run the wrapper script normalizeMed.sh
  ./normalizeMed.sh

The output is saved in normalizedMed1.csv, normalizedMed2.csv, etc, one file per input file.

