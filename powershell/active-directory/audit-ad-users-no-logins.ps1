<#
Description: Powershell script used to audit AD accounts with no logins in 180 days or more. This script will disable those accounts and relocate them to a new Inactive OU in AD allowing further investigating. Accounts will be exported to a CSV report. 
#>


#############################
# Preliminary Setup
#############################

# Set destinations for output files 
$Root_Disk = "c:"
$ReportFolder = "$($Root_Disk)\scripts\reports"

# Check if path exists. If not, create it
# if (!(Test-Path $ADReport)) {New-Item $ADReport -ItemType Directory}

# Get current date formatting to year/month/day/hour/minute format for timestamp
$Time = (Get-Date).ToString("yyyyMMddhhmm")

# Set File Name
$ADReport = "$($ReportFolder)\$("inactive_user_export")_$($Time).csv"

################################
# Setup script output logging 
################################

# Get current script name for execution logging
[string]$script_name = $MyInvocation.CommandOrigin
Write-Host "`nExecuting Script: $([string]$script_name)`n'"

# Check if path exists for log files. If not, create path
if (!(Test-Path "C:\scripts\log")) { New-Item "C:\scripts\log" -ItemType Directory }

# Specifying log path. Create directory if it does not exist. Output log being created and where to find it
$log_directory = "C:\scripts\log\$(($script_name).Substring(0,(($script_name).length-4)))"

if (!(Test-Path $log_directory)) { New-Item -Path $log_directory -ItemType Directory } 

Write-Host = "log file: $($log_directory)-$($time).log"
$log_path = "$($log_directory)-$($time).log"

Start-Transcript $log_path 

#############################
# Find inactive users 
#############################

# Define AD search by excluding Terminated OU
$excluded_ou = "DC=[Enter],DC=[Domain],DC=[Here]"

# set inactive account OU for where disabled and inactive accounts will be moved to
$inactive_accounts_ou = "DC=[Enter],DC=[Domain],DC=[Here]"

# Define period (days) for no login activity 
$daysInactive = 180
$currentdate = (Get-Date).AddDays( - ($daysInactive))

# Get AD accounts that have no logins for 180 days or more
Write-Host "Finding inactive accounts..."
$inactive_logins = Get-ADUser -Filter { lastlogonTimeStamp -lt $currentdate -and enabled -eq $true -and DistinguishedName -notlike $excluded_ou } -Properties * | Select-Object Name, SamAccountName, DistinguishedName, Enabled, lastlogondate

##################################
# Generate CSV Report
##################################

# Export accounts to CSV file 
$inactive_logins | Export-Csv $ADReport -NoTypeInformation -Force


##################################
# Move all users to Inactive OU
##################################

# Get Today's date
$today = (Get-Date).ToString("yyyyMMdd")

Write-Host "Moving accounts to inactive OU located: $($inactive_accounts_ou)"

# Inactive Users
foreach ($inactive_user in $inactive_logins)
{
    
    # Disabled AD Account
    Disable-ADAccount -Identity $inactive_user.samaccountname

    # Outputs the account was disabled for transaction log
    Write-Host "User $($inactive_user.samaccountname) has been disabled"

    # Create a description to be added to the user in AD properties
    $inactive_user_description = "[Moved by Script] Inactive User moved on $($today) LastLogin: $($inactive_user.lastlogondate) Original OU: $($inactive_user.DistinguishedName)"

    $executionuser = ([Environment]::UserDomainName + "\" + [Environment]::UserName)
    $scriptname = [Environment]::GetCommandLineArgs()[0]
    $info = "This was disabled and moved by $($executionuser) from $($env:ComputerName) by script $($scriptname)"

    # Moves user to new OU
    Move-ADObject -identity $inactive_user.DistinguishedName -targetpath $inactive_accounts_ou
    
    # Add description to moved user accounts
    Get-ADUser $inactive_user.SamAccountName | Set-ADUser -Description $inactive_user_description -replace @{comment = $info }
}
