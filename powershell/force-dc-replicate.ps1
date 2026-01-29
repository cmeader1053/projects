# Powershell script to force replicate multiple domain controllers 
# script will identify current DC logged in and skip that DC that changes were made on and only replicate to other DC's

# Import the Active Directory module
Import-Module ActiveDirectory

# Specify the domain controllers you want to replicate
$domainControllers = @("DC1", "DC2", "DC3")

# Get the current hostname
$currentHostname = $env:COMPUTERNAME

foreach ($dc in $domainControllers) {
    # Skip the current domain controller running the script
    if ($dc -eq $currentHostname) {
        Write-Host "Skipping replication on $dc (current host)"
        continue
    }

    Write-Host "Forcing replication on $dc"

    # Replicate Active Directory
    $null = repadmin /syncall /AdeP $dc 2>&1
    
    # Replicate Group Policy
    $null = Invoke-GPUpdate -Computer $dc -Force 2>&1

    if ($?) {
        Write-Host "Replication on $dc completed successfully."
    } else {
        Write-Host "Replication on $dc failed."
    }
}

Write-Host "Replication completed for all specified domain controllers."

# Add a pause to keep the PowerShell window open
Write-Host "Press any key to close this window..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
