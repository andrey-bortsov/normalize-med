#!/bin/bash
#
#Normalize and classify medication data using the online RxNorm and RxClass API.
#
#Input: one medication per line, brand names are allowed, may (but not need to)
#have strength (dose) and form (tablet, pill etc). Misspells are allowed.
#
#Output: normalized medication name, strength and form; medication VA class (or DAILYMED class
#if VA class is not retrieved); one medication per line.
#Only one entry with the highest match score is returned.
#See README file for setup instructions.
#
#Author: Andrey Bortsov, bortzov@gmail.com
#Last modified: Jan 31,2017
#
###############################################################################################

function join_by { local IFS="$1"; shift; echo "$*"; }
while read line
do
	#preprocess the string 
	line1=$(echo "$line" |  
		 sed 's/[[:space:]]\+/ /g' |
		 sed 's%^N/A%%Ig' |
		 sed 's/^no meds.*//Ig' | 
		 sed 's/ na $//g' |
		 sed 's/^same.*//Ig' | 
		 sed 's/^nsaids.*/nsaids/Ig' |
		 sed 's%^Hydrocodone \([0-9]\+/[0-9A-Za-z]\+\)%Norco \1%Ig')
 
    #build URL for RxNorm request of JSON file
    myurl="https://rxnav.nlm.nih.gov/REST/approximateTerm.json?term="
    line2=${line1// /'%20'}

    if [ "$line2" != "%20" ]; then
		if [ "$line1" != "nsaids" ]; then
			maxEnt="&maxEntries=1"
			fullUrl=$myurl$line2$maxEnt
			rxcui=($(curl --max-time 20 $fullUrl | jq -r '.approximateGroup.candidate[0]["rxcui","score"]')) 
			#if more than 20 requests per second the IP will be blocked! Therefore sleep.
			sleep 0.051
			myUrl2="https://rxnav.nlm.nih.gov/REST/rxclass/class/byRxcui.json?rxcui="
			line4="&relaSource=NDFRT&relas=has_VAclass"
			rxcuiID=${rxcui[0]}
			fullUrl2=$myUrl2$rxcuiID$line4
			rxclass=$(curl --max-time 20 $fullUrl2 |
						  sed 's%\([^{}"]\),\([^{}"]\)%\1 \2%g' | 
					jq -r '[.rxclassDrugInfoList.rxclassDrugInfo[0].minConcept.name,
						  .rxclassDrugInfoList.rxclassDrugInfo[0].rxclassMinConceptItem.className] | 
					  join(",")')
			
			#if no VA class retrieved, try DAILYMED
			if [ "$rxclass" = "," ] && [ ! -z $rxcuiID ]; then
				line4="&relaSource=DAILYMED&relas=has_EPC"
				fullUrl2=$myUrl2$rxcuiID$line4
				rxclass=$(curl --max-time 20 $fullUrl2 | 
						   sed 's%\([^{}"]\),\([^{}"]\)%\1 \2%g' | 
						jq -r '[.rxclassDrugInfoList.rxclassDrugInfo[0].minConcept.name, 
						   .rxclassDrugInfoList.rxclassDrugInfo[0].rxclassMinConceptItem.className] | 
						join(",")')
			fi
			
			#if no DAILYMED class retrieved, request RxNorm name only
			if [ "$rxclass" = "," ] && [ ! -z $rxcuiID ]; then
				myUrl3="https://rxnav.nlm.nih.gov/REST/rxcui/"
				line4="/property.json?propName=RxNorm%20Name"
				fullUrl3=$myUrl3$rxcuiID$line4
				rxclass=$(curl --max-time 20 $fullUrl3 | 
					   sed 's%\([^{}"]\),\([^{}"]\)%\1 \2%g' | 
					   jq -r '.propConceptGroup.propConcept[0].propValue')
			fi

			fullArray=("${rxcui[@]}" "$rxclass")
			join_by , "${fullArray[@]}" 
			sleep .051
		else echo ",,undefined NSAID,NON-OPIOID ANALGESICS"
		fi
	else echo ",,," 
    fi
done 
