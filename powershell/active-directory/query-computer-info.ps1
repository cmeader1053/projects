# Query AD for computer information for a specific OU exporting to CSV

# Import the Active Directory module if not already loaded
Import-Module ActiveDirectory

# Specify the OU (Organizational Unit) where you want to search for computer objects
$ouPath = "[OU_Path_Here"

# Get computer objects from Active Directory
$computers = Get-ADComputer -Filter * -SearchBase $ouPath -Properties Name,OperatingSystem,OperatingSystemVersion

# Create an array to store computer information
$computerInfoArray = @()

# Iterate through each computer object and extract desired information
foreach ($computer in $computers) {
    # Get the serial number and last logon timestamp for the computer
    $serialNumber = (Get-ADObject -Filter {ObjectClass -eq 'computer' -and Name -eq $computer.Name} -Properties SerialNumber).SerialNumber
    $lastLogon = $computer | Get-ADComputer | Select-Object -ExpandProperty LastLogon

    # Convert the last logon timestamp to a readable date
    if ($lastLogon -ne $null) {
        $lastLogon = [DateTime]::FromFileTime($lastLogon)
    }

    $computerInfo = [PSCustomObject]@{
        Name                = $computer.Name
        OperatingSystem     = $computer.OperatingSystem
        OperatingSystemVer  = $computer.OperatingSystemVersion
        SerialNumber        = $serialNumber
        LastLogon           = $lastLogon
    }
    $computerInfoArray += $computerInfo
}

# Display the computer information in a table
$computerInfoArray | Format-Table -AutoSize

# Optionally, export the computer information to a CSV file
$csvFilePath = "[enter_file_path_here]\[file_name_here].csv"
$computerInfoArray | Export-Csv -Path $csvFilePath -NoTypeInformation

Write-Host "Computer information exported to $csvFilePath"
