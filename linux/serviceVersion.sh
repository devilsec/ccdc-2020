#!/bin/bash
serviceArray=()
count=0
while read line;do
	serviceArray[$((count++))]=$line
done <<< $(ps aux | awk '{if ($5!=0) print $11}' <<< "$(ps aux)" | awk -F "/" '{print $NF}' | grep -v "^\[") #get  list of all currently running services

#Sort service array
IFS=$'\n' sorted=($(sort <<< "${serviceArray[*]}")) #Put EVERY element of serviceArray into the sort command -> put it into new array sorted.
#uniq sorted array 
uniq=($(uniq <<< "${sorted[*]}"))
unset IFS						 #it breaks it into individual indicies because of IFS (internal field seperator)

arrayLength=${#uniq[@]}

for i in $(seq 0 $arrayLength); do
	echo ${uniq[$i]}
	i=$((i++))
done
