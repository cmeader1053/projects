# Finds failed login attempts for a specified AD user exporting results to csv

# Define the user you want to investigate
$targetUser = "[enter_username]"

# Define the output CSV file path
$outputFile = "[enter_file_name_here].csv"

# Query the Security event log for logon failure events for the specified user
$events = Get-WinEvent -LogName Security | Where-Object {
    $_.Id -eq 4625 -and
    $_.Properties[5].Value -eq $targetUser
}

# Create an empty array to store logon events
$logonEvents = @()

# Calculate the total number of logon events
$totalEvents = $events.Count
$counter = 0

# Iterate through the events and display a loading bar
foreach ($event in $events) {
    $logonEvents += $event | Select-Object TimeCreated, Id, Message
    $counter++
    $progress = ($counter / $totalEvents) * 100
    Write-Progress -Activity "Exporting Logon Events" -Status "Progress: $counter out of $totalEvents" -PercentComplete $progress
}

# Export the logon events to a CSV file
$logonEvents | Export-Csv -Path $outputFile -NoTypeInformation

Write-Host "Failed logon attempts for $targetUser have been exported to $outputFile."
