#!/bin/bash
currentDir=$(pwd)
resourcesDir="$currentDir/menuResources"
RED='\033[0;41;30m'
STD='\033[0;0;39m'
packageManager="apt-get"

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
	echo  "### SERVICES #############################################" 
	#running processes
	psaux=`ps aux 2>/dev/null`
	if [ "$psaux" ]; then
		echo -e "[-] Running processes:"
		awk '{
			if ($5 != 0)
				print $1, $11
		}' <<< $psaux
		echo -e "\n"
	fi
	pause
}

strippedServices() {
	echo "[+] Checking services.............."
	local serviceArray=()
 	local count=0
	while read line;do
		serviceArray[$((count++))]=$line
	done <<< $(ps aux | awk '{if ($5!=0) print $11}' <<< "$(ps aux)" | awk -F "/" '{print $NF}' | grep -v -e "^\[" -e "COMMAND" | grep -v -e "bash" -e "awk" -e "ps") #get  list of all currently running services
	#Sort service array
	IFS=$'\n' sorted=($(sort <<< "${serviceArray[*]}")) #Put EVERY element of serviceArray into the sort command -> put it into new array sorted.
	#it breaks it into individual indicies because of IFS (internal field seperator)
	
	#uniq sorted array 
	services=($(uniq <<< "${sorted[*]}"))
	unset IFS 

	local arrayLength=${#services[@]}
	
	for i in $(seq 0 $arrayLength); do
		echo ${services[$i]}
		i=$((i++))
	done
	echo ${services[*]} > "$resourcesDir/runningServices"
	pause

}

packageChecks() {
	check=`which dpkg`
	if [ $check ]; then
		dpkgPresent=0
	fi
	
}

serviceVersions() {
	trap - SIGINT
	local serviceFile="$resourcesDir/runningServices"
	local versionFile="$resourcesDir/serviceVersions"
	echo '' > $versionFile
	

	ls $serviceFile >/dev/null 2>&1
	if [[ $? -ne 0 ]];then
		echo "Services has not yet been checked, doing so now." 
		strippedServices
	fi

	remainingServices=(${services[@]})
	local i=0
	for service in ${remainingServices[@]}; do



		echo -e "${RED}[$service]--------------------------------------${STD}\t[$i]"
	
		if [ $dpkgPresent -eq 0 ]; then
			package=$(dpkg -S $service | cut -d":" -f 1 | head -n 1)
			dpkg -s $package | grep -e "Package" -e "Version"
			unset remainingServices[$i]
		elif [ $packageManager == "apt" ];then
			version=`apt-get list $service --installed 2>/dev/null`
			if [ "$version" ];then
				echo $version
				unset remainingServices[$i]
			fi
			
		#check based on the individual commands --version, output can be unpredictable.
		verCheck=`$service --version 2>/dev/null | head -n 3`
		echo $?
		elif [ "$verCheck" ]; then
			echo -e "\t $verCheck"
			unset remainingServices[$i]
		fi
	
	i=$((i+1))
	done	
	if [ ${#remainingServices[@]} -gt 0 ]; then
		echo "The versions of the following packages was not found:"
		echo "${remainingServices[@]}:${#remainingServices[@]}"
	fi
	pause
}

portInfo() {
	tcpserv=`netstat -ntpl`
	if [ "$tcpserv" ]; then
		echo "Listening TCP Services (Generally these are gonna be more important the UDP)"
		echo "$tcpserv"
	fi
	udpserv=`netstat -nupl`
	if [ "$udpserv" ]; then
		echo "Listening UDP Services (be careful with these)"
		echo "$udpserv"
	fi
	pause
}

installedPackages() {
	echo "[+]Installed packages:"
	if [ $dpkgPresent ]; then 	
		dpkg -s | grep -e "Package:" -e "Version" | awk '{print;} NR % 2 == 0 {print "";}'

	fi

	pause

}

checkIntegrity() {
	if [ $dpkgPresent ]; then
		debsumsCheck=`which debsums`
		if [ $? -ne 0 ] && [ $packageManager == "apt-get"]; then
			apt-get install debsums -y
		fi
		debsums -c 
		echo 
		echo
		echo "Note: You can mostly ignore missing files, you should look out for files that were modified/have a different hash."
	fi	

}

changePasswords() {
	echo "Users on system"
	trap - SIGINT
	cat /etc/passwd | grep -v -e nologin | cut -d":" -f 1 
	read -p "Enter password to change all users to: " password
	while read line; 
	do
		stauts=$((passwd $line 2>/dev/null ) <<< `echo $password && echo $password`)

		echo "$line,$password"

	done <<< `cat /etc/passwd | grep -v -e nologin | cut -d":" -f 1`
	
	pause 
}

installSnort() {
	if [ $packageManager == "apt-get" ]; then
		apt-get install snort -y
	fi
}
showMenu() {
	clear 
	echo "------------------"
	echo "       Menu       "
	echo "------------------"
	uname -a
	cat /etc/lsb-release
	echo
	echo "1) Run linenum.sh (this should be done first)"
	echo "2) Check Running Service"
	echo "3) Check Service Versions"
	echo "4) Show listening Ports"
	echo "5) Show Installed Packages"
	echo "6) Check File Integrity/Check for backdoors"
	echo "7) Install snort"
	echo "8) Change passwords"
	echo "x) Exit"
	
}

readInput() {
	local choice
	read -p "Enter options [1-5] " choice
	case $choice in
	        x) exit ;;	
		1) runLinEnum ;;
		2) strippedServices;;
		3) serviceVersions   ;;
		4) portInfo   ;;
		5) installedPackages ;;
		6) checkIntegrity   ;;
		7) echo "Not implemented fully";;
		8) changePasswords ;;
		*) echo -e "${RED}Not Recognized..${STD}"; sleep 1; ;;
	esac
}

checkExisting() {
	ls -D $resourcesDir
	if [[ $? -eq 2 ]]; then
		echo "$resourcesDir not created, creating.."
		mkdir $resourcesDir
	fi
	resourcesExists=true
}


#Trap ctl+z and ctrl+c
trap '' SIGINT SIGQUIT SIGTSTP

#make folder we will put our resources into
checkExisting
packageChecks

if [ $resourcesExists ]; then
	echo "Ingesting last run data"
	IFS=$' ' services=($(cat $resourcesDir/runningServices))
fi


#Menu Persistence
while true
do 
	showMenu
	readInput
done
