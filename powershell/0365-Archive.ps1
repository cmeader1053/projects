# Description:  Powershell script to archive TERMINATED employees O365 mailboxes exporting them to a PST file located on the Z: drive

 
# Get Primary Domain Controller (PDC) Server
$pdc=(Get-ADForest |Select-Object -ExpandProperty RootDomain |Get-ADDomain |Select-Object -Property PDCEmulator).PDCEmulator

# Set Destination Varibales for Output Files
$Root_Disk = "Z:"
$PSTArchive = "$($Root_Disk)\O365-Archive"
$SharePath = "\\[Enter-Share-Drive-Path]"

if (!(Test-Path $PSTArchive)) {New-Item $PSTArchive -ItemType Directory}

# Gets the current date and formats it to Year Month Day Hour Minute format as a time stamp
$Time= (Get-Date).ToString("yyyyMMddhhmm")

#################################################################################################
# Setup Output Logging
#################################################################################################
     
# Gets current name for script execution for logging.
[string]$script_name = $myInvocation.MyCommand
Write-host "`nScript that is executing: $([string]$script_name)`n"

# Checks if path exist if not creates the directory
if (!(Test-Path "C:\scripts\log")) { New-Item "C:\scripts\log" -ItemType Directory }

#specify Log path
$log_directory = "C:\scripts\log\$(($script_name).Substring(0,(($script_name).length-4)))"

# Creates directory if it doesn't exists
if (!(Test-Path $log_directory)) { New-item -Path $log_directory -ItemType Directory }  

# This sets the default path to C:\scripts\logs\script_name-datetime.log

Write-Host "Default Log file is $($log_directory)-$($time).log"
$log_path = "$($log_directory)-$($time).log"

# Logs all output to log path
Start-Transcript $log_path
Write-Host "


     "
Write-Host ([Environment]::UserDomainName + "\" + [Environment]::UserName) " Executed the script at $(Get-Date)`n`n"

#################################################################################################
#################################################################################################

# Set OU path to target employees
$Terminated_Users_OU = "OU=[Enter],DC=[Dopmain],DC=[Here]"

# Get terminanted users from AD with extensionAttribute4 set to null
$TerminatedUsers = Get-ADUser -properties extensionAttribute4,enabled -Filter {enabled -eq $false -and -not(extensionAttribute4 -like "*") } -SearchBase $Terminated_Users_OU | select -First 20
#$TerminatedUsers = Get-ADUser -properties extensionAttribute4,enabled -Filter {enabled -eq $false  } -SearchBase $Terminated_Users_OU 

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement

$tenant_name = "[Exchange-Tenant-Name]"
$app_id = "[Exchange-App-ID]"
$certificate_thumbprint = "[Exhcnage-certificate-thumbprint]"

Write-Host "Connecting to Exchange Online`n`n" 
Connect-ExchangeOnline -UserPrincipalName exchangesvc@solomoninsight.com -ShowBanner:$false
#Connect-ExchangeOnline -AppId $app_id -CertificateThumbprint $certificate_thumbprint -Organization $tenant_name

Write-Host "Connect to Exhcnage Security `n`n"
Connect-IPPSSession -UserPrincipalName exchangesvc@solomoninsight.com -ShowBanner:$false
#Connect-IPPSSession -AppId $app_id -CertificateThumbprint $certificate_thumbprint -Organization $tenant_name

$connection_id = (Get-ConnectionInformation).ConnectionId

# Loop through each terminated user
foreach ($user in $TerminatedUsers) 
{
    write-host "$($user.displayname) checks"
	# Use Try catch to check for emails
	try {
		Get-EXOMailbox -identity $user.UserPrincipalName -ErrorAction Stop
		# Create PST file name with users UPN
		$Formatted_User_Name = ($user.UserPrincipalName).Substring(0,($user.UserPrincipalName).indexof("@"))

		# $PSTFileName = "$($user.UserPrincipalName.Replace("@","_"))_Archive.pst"
		$PSTFileName = "$($Formatted_User_Name)_$($Time)_Archive.pst"
		$PSTFilePath = Join-Path -Path $PSTArchive -ChildPath $PSTFileName

		# Start Client Search 

        # Export mailbox to PST file
		try {
            Write-Host "Exporting Mailbox to pst for $($user.UserPrincipalName) `n`n"
			#New-MailboxExportRequst -Mailbox $user.UserPrincipalName -FilePath $PSTFilePath -ErrorAction Stop
            $description = "Automated Content Search for Archival executed on: $((Get-Date).ToString("yyyy-MM-dd"))"
            New-ComplianceSearch "$($user.GivenName)_$($user.Surname)_archive_box" -Description $description -exchangelocation $user.UserPrincipalName | Start-ComplianceSearch 
			Get-ADUser $user.SamAccountName | Set-ADObject -Server $pdc -Replace @{extensionAttribute4 = "Exported"}
            #Get-ADUser $user.SamAccountName | Set-ADObject -Server $pdc -Clear extensionAttribute4 
            
		}
		catch {
			# Do not flag the user as Exported since the job didn't complete
            Write-Host "Exception happened `n`n"
		}
	}
	catch {
		# Flag the user for NoMailBox since it can't be found in exchange online
        Write-Host "User: $($user.UserPrincipalName) has no mailbox"
		Get-ADUser $user.SamAccountName | Set-ADObject -Server $pdc -Replace @{extensionAttribute4 = "NoMailBox"}
	}
}

# Move PST files to designated path
$PSTs = Get-Childitem -Path $PSTArchive -File

Write-Host "Moving $($PSTs.count) PST Files`n"

foreach($PST in $PSTs.FullName)
{
    Write-Host "Moving $($PST.FullName) to $($SharePath)`n`n"
	Move-Item -Path $PST -Destination $SharePath -Force
}

# Disconnect from Exchange Online
Write-Host "Disconnecting Session From Exchange Online`n"
Disconnect-ExchangeOnline -ConnectionId $connection_id -Confirm:$false

Stop-Transcript
