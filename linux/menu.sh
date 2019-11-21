#!/bin/bash
currentDir=$(pwd)
RED='\033[0;41;30m'
STD='\033[0;0;39m'

pause() {
	read -p "Press [Enter] key to continue.." fackEnterKey
}

runScript() {
	fileArg=$1
	./fileArg
}

runLinEnum() {
	echo "Current dir: $currentDir" #check the directory, this is so if I change locations it wont break things.
	local linEnumPath=$currentDir/linenum.sh #path to linenum
	if [[ ! -x $linEnumPath ]] #check if the file is executable, if not then make it so 
	then
		echo "linEnum.sh not executable, chmoding."
		chmod +x $linEnumPath
	fi
	read -p "Do you want a thorough test [y/n]" thorough
	
	trap - SIGINT #untrap ctrl+c, allows people to exit early if need be.	
	
	if [[ $thorough == 'y' ]]
	then
		echo "Executing LinEnum.sh thorough and outputting to report.linEnum"
		$linEnumPath -t -r report.linEnum
	else
		echo "Executing LinEnum.sh and outputting report to report.linEnum"
		$linEnumPath -r report.linEnum
	fi

	trap '' SIGINT
	pause
}

serviceInfo()
{
	echo -e "\e[00;33m### SERVICES #############################################\e[00m" 
	#running processes
	psaux=`ps aux 2>/dev/null`
	if [ "$psaux" ]; then
		echo -e "[-] Running processes:"
		awk '{
			if ($5 == 0)
				print $1, $11
		}'
		echo -e "\n"
	fi
	pause
}

showMenu() {
	clear 
	echo "------------------"
	echo "       Menu       "
	echo "------------------"
	echo "1) Run linenum.sh (this should be done first)"
	echo "2) Check Service Info"
	echo "x) Exit"
	
}

readInput() {
	local choice
	read -p "Enter options [1-5] " choice
	case $choice in
	        x) exit ;;	
		1) runLinEnum ;;
		2) serviceInfo;;
		*) echo -e "${RED}Not Recognized..${STD}"
	esac
}


#Trap ctl+z and ctrl+c
trap '' SIGINT SIGQUIT SIGTSTP

#Menu Persistence
while true
do 
	showMenu
	readInput
done