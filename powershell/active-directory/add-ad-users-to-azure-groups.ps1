<#
Script Name:  Add Missing AD Users to Azure Group
Author:  Chris Meader, Cloud Sys Admin
Author Date:  04/16/2025
Description:
This script will pull all AD users and check if they are currently members of a specified Azure AD group. 
If the AD user is not found in the specified Azure AD group, it will then add them to the group. 
#>

# Define OUs to target
$OUs = @(

)

# Set Azure AD Group
$AzureGroupName = ""
$AzureGroup = Get-AzureADGroup -SearchString $AzureGroupName

if ($null -eq $AzureGroup) {
    Write-Host "Azure AD group not found!" -ForegroundColor Red
    exit
}

# Loop through each OU
foreach ($ou in $OUs) {
    Write-Host "Processing users in OU: $ou" -ForegroundColor Cyan

    # Get users in OU
    $adUsers = Get-ADUser -Filter * -SearchBase $ou -Properties SamAccountName, UserPrincipalName, Enabled | Where-Object {$_.Enabled -eq $true -and $_.UserPrincipalName -ne $null}
    
    # Loop through each user and check if member of Azure AD group
    foreach ($user in $adUsers) {
        # Get the User's UPN
        $userUPN = $user.UserPrincipalName

        # Check if the user is a member of the Azure AD group
        $AzureGroupMember = Get-AzureADGroupMember -ObjectId $AzureGroup.ObjectId | Where-Object { $_.UserPrincipalName -eq $userUPN }

        $AzureADUser = Get-AzureADUser -ObjectId $userUPN

        # Add user if not in the group
        if ($null -eq $AzureGroupMember) {
            Write-Host "Adding user $($user.SamAccountName) to Azure AD group $($AzureGroup.DisplayName)..."
            try {
                # Add user to Azure AD group
                Add-AzureADGroupMember -ObjectId $AzureGroup.ObjectId -RefObjectId $AzureADUser.ObjectId
                Write-Host "User $($user.SamAccountName) added to group."
            } catch {
                Write-Host "Error adding user $($user.SamAccountName) to group: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "User $($user.SamAccountName) is already a member of the Azure AD group $($AzureGroup.DisplayName)."
        }
    }
}

# Confirm script completion
Write-Host "Done" -ForegroundColor Green
