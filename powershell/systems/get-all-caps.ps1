<#
Script_Name:  GetAllCAPS.ps1
Script_Author:  Chris Meader, Cloud System Admin
Script_Description:  Powershell scripts gets all conditional access policies (CAPs) and exports them in JSON format to a specified file location.
#>


# Connect to Microsoft Graph
Connect-MgGraph -Scopes 'Policy.Read.All'

# Export path
$export_path = "<enter_export_path>"

try {
    # Retrieve all CAPs from Microsoft Graph
    $all_caps = Get-MgIdentityConditionalAccessPolicy -All

    if ($all_caps.Count -eq 0) {
        Write-Host "There are no CA policies found to export." -ForegroundColor Yellow
    }
    else {
        # Iterate through each CAP
        foreach ($cap_policy in $all_caps) {
            try {
                # Get the display name of the policy
                $cap_policyName = $cap_policy.DisplayName
            
                # Convert the policy object to JSON with a depth of 6
                $cap_policyJSON = $cap_policy | ConvertTo-Json -Depth 6
            
                # Write the JSON to a file in the export path
                $cap_policyJSON | Out-File "$export_path\$cap_policyName.json" -Force
            
                # Print a success message for the policy backup
                Write-Host "Successfully backed up CA policy: $($cap_policyName)" -ForegroundColor Green
            }
            catch {
                # Print an error message for the policy backup
                Write-Host "Error occurred while backing up CA policy: $($cap_policy.DisplayName). $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}
catch {
    # Print a generic error message
    Write-Host "Error occurred: $($_.Exception.Message)" -ForegroundColor Red
}
