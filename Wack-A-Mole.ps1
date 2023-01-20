Write-Host "Wack-a-Mole" -ForegroundColor Green
Write-Host "2022-2023 ASU CCDC Team"
Write-Host "Author: Epi AKA David Lee"
Write-Host "Periodically checks service status and enables services that are disabled, if the service cannot be enabled the script stops the responder is alerted"
Write-Host "This tactic that is meant top the bleeding while defenders can identify root cause and eradicate the threat actor."


#configure execution policy so script runs
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force

$monitoredServiceList = [System.Collections.ArrayList]::new()

class ServiceListEntry {
    [ValidateNotNullOrEmpty()][string]$DisplayName      #eg. 'FTP' for FTP related services
    [ValidateNotNullOrEmpty()][string[]]$Services       #eg. 'filezilla-server'
}

$servicesList = [ServiceListEntry[]]@(
    [ServiceListEntry]@{
        DisplayName = "FTP"
        Services    = @(
            "FTPSVC",           #IIS FTP Server
            "filezilla-server"  #Filezilla FTP Server
        )
    },
    [ServiceListEntry]@{
        DisplayName = "HTTP/HTTPS"
        Services    = @(
            "HTTP",             #the HTTP 'service' is actually a driver needed for the Print Spooler, see https://superuser.com/questions/1059068/no-http-service-windows-10
            
            #IIS Services
            "W3SVC",
            "W3LOGSVC",
            "WAS"
        )
    },
    [ServiceListEntry]@{
        DisplayName = "SMB"
        Services    = @("SMB")
    },
    [ServiceListEntry]@{
        DisplayName = "DNS"
        Services    = @("DNS")
    },
    [ServiceListEntry]@{
        DisplayName = "VNC"
        Services    = @("VNC")
    },
    [ServiceListEntry]@{
        DisplayName = "telnet"
        Services    = @("Telnet")
    }
)

#list of services to monitor, Last item is entering manual name
Write-Host "Select which services to monitor (separated by commas)"

$servicesList | ForEach-Object { $index = 1 } { Write-Host "#$($index)" $_.DisplayName; $index++ }  #Print display name of all registered services 

Write-Host "#$($servicesList.Length + 1) Custom" #Custom option

#prompt user for number
$optionNumbers = read-host "Select a number from above list: "

foreach ($option in $optionNumbers.Split(",")) {
    $option = $option.trim() #remove whitespace left over from Split()

    if ($option -le $servicesList.Length) {

        #true if any of the group of services under the display name exist on the system 
        $displayNameHasExistentServices = $false;

        #get all services listed under the display name
        $servicesList[[int]$option - 1].Services | ForEach-Object {

            #assigns the service under the display name to the watched services list if it exists on the system 
            # (eg. When selecting the 'FTP' option, fillezilla-server will be added to the list but FTPSrv won't if the IIS FTP Server feature isn't installed); ignores silently if service doesn't exist
            $serviceExists = Get-Service -Name $_ -ErrorAction SilentlyContinue
            if ($null -ne $serviceExists) {
                $monitoredServiceList.Add($_) #add previously existing service name to monitoring list

                $displayNameHasExistentServices = $true
            }
        }

        #warn the user when attempting to add a set of services that don't exist
        if ($displayNameHasExistentServices -eq $false) {
            $serviceListEntry = $servicesList[[int]$option - 1]
            $displayName = $serviceListEntry.DisplayName

            Write-Warning "No services under group '$displayName' are present on this system! ($($serviceListEntry.Services -join ", "))"
            Write-Warning "Check selection(s) from above are entered correctly."
        }
    }
    else {
        #This last option promps user for custom service not listed above
        $serviceName = Read-Host "Enter Service Name (not display name), confirm after setup that script is running correctly"
        $monitoredServiceList.Add($serviceName) #add custom service name to monitoring list
    }
    
}
#formatting
Write-host "---------------------------------------------------------------------------------------------------------"

#while true loop
$wack = "true"
while ($wack -eq "true") {
    foreach ($serviceName in $monitoredServiceList) {

        #check if service is up, 
        if ((Get-Service $serviceName).Status -eq "Running") {

            #display artifacts
            Write-Host $serviceName" is Running"
            (Get-Date).ToString('G')
            Get-Service $serviceName | Format-Table serviceName, displayName, startType, status


        }

        #if service is Not enabled
        if ((Get-Service $serviceName).Status -ne "Running") {

            #display artifacts
            write-host $serviceName" is not running. Attempting to start service."
            (Get-Date).ToString('G')
            Get-Service $serviceName | Format-Table serviceName, displayName, startType, status

            #try to start service
            Start-Service -Name $serviceName

            #if service is now starting or running
            if ((Get-Service $serviceName).Status -Match "Running|StartPending") { 

                #display artifacts
                write-host $serviceName" is now running."
                (Get-Date).ToString('G')
                Get-Service $serviceName | Format-Table serviceName, displayName, startType, status
            }
        
            #if service is still not running after the above attempt to get it running
            if ((Get-Service $serviceName).Status -ne "Running") {

                #display artifacts
                write-host "Unable to start "$serviceName". Investigate before the mole wacks you."
                (Get-Date).ToString('G')

                Get-Service $serviceName | Format-Table serviceName, displayName, startType, status

                #stops while loop so Incident responder can investigate
                $wack = "false"

                #wacked ascii art here
            }
        }
    }

    #sleep 30 seconds
    Write-host "---------------------------------------------------------------------------------------------------------"
    Start-Sleep -Seconds 30


    #potental new features
    #write output to log
    #user can pause loop to look at output
    #check for input, timeout
    
} # end of while loop

#reference
#https://social.technet.microsoft.com/Forums/windowsserver/en-US/79bf9de7-1c17-45c0-a02b-7558af89807a/powershell-script-to-check-service-status
#IIS Services 
# https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/jj635851(v=ws.11), 
# https://docs.oracle.com/en/industries/health-sciences/inform/cognos1117-install/index.html?toc.htm?226411.htm)