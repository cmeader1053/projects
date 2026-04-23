<#
Title:  create-exchange-dist-list.ps1
Description:  Powershell script to create new Microsoft Exchange distribution lists. This script will only create the lists. No users will be added. 
Directions:  Replace the default values in the "groups" array  with appropriate group details. 
#>

# Install module
Install-Module ExchangeOnlineManagement

# Connect to Exchange 
Connect-ExchangeOnline

# Create Distribution Groups
$groups = @(
    @{ DisplayName = "grp_name_1"; Alias = "grp_name_1"; PrimarySmtpAddress = "grp_name_1@yourdomain.com" },
    @{ DisplayName = "grp_name_2"; Alias = "grp_name_2"; PrimarySmtpAddress = "grp_name_2@yourdomain.com" },
    @{ DisplayName = "grp_name_3"; Alias = "grp_name_3"; PrimarySmtpAddress = "grp_name_3@yourdomain.com" }
)

foreach ($group in $groups) {
    New-DistributionGroup `
        -Name $group.DisplayName `
        -DisplayName $group.DisplayName `
        -Alias $group.Alias `
        -PrimarySmtpAddress $group.PrimarySmtpAddress `
        -Type Distribution

    Write-Host "Created: $($group.DisplayName)" -ForegroundColor Green
}

# Disconnect from Exchange
Disconnect-ExchangeOnline -Confirm:$false
