#!/bin/bash
function join_by { local IFS="$1"; shift; echo "$*"; }
while read line
do
line1=$(echo "$line" |  
 sed 's/[[:space:]]\+/ /g' |
 sed 's%^N/A%%Ig' |
 sed 's/^no meds.*//Ig' | 
 sed 's/ na $//g' |
 sed 's/^same.*//Ig' | 
 sed 's/^nsaids.*/nsaids/Ig' |
 sed 's%^Hydrocodone \([0-9]\+/[0-9A-Za-z]\+\)%Norco \1%Ig')

    myurl="https://rxnav.nlm.nih.gov/REST/approximateTerm.json?term="
    line2=${line1// /'%20'}

    if [ "$line2" != "%20" ]; then
    if [ "$line1" != "nsaids" ]; then
    maxEnt="&maxEntries=1"
    fullUrl=$myurl$line2$maxEnt
	rxcui=($(curl --max-time 20 $fullUrl | jq -r '.approximateGroup.candidate[0]["rxcui","score"]')) 
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

	if [ "$rxclass" = "," ] && [ ! -z $rxcuiID ]; then
         line4="&relaSource=DAILYMED&relas=has_EPC"
         fullUrl2=$myUrl2$rxcuiID$line4
         rxclass=$(curl --max-time 20 $fullUrl2 | 
                   sed 's%\([^{}"]\),\([^{}"]\)%\1 \2%g' | 
		   jq -r '[.rxclassDrugInfoList.rxclassDrugInfo[0].minConcept.name, 
		           .rxclassDrugInfoList.rxclassDrugInfo[0].rxclassMinConceptItem.className] | 
			   join(",")')
        fi
	
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
