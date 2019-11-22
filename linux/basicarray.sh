#!/bin/bash

array=()
count=0
while read line; do
	array[$((count++))]=$line	
#	array+="$line"
done <<< "$(ps aux | awk '{print $11}' | awk -F"/" '{print $NF}')"
echo "${array[1]}"
