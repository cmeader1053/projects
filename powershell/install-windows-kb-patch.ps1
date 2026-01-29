# Description: Powershell script used to verifed if a patch (KB number) is installed. If installed, no action. If patch not installed, prompts user to install patch. 

# Directions:  Run script in as an admin. Enter KB number to be verify if installed. Follow prompts to either install or not install patch. 

# Ensure Windows Update module is imported
Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue

# User greeting
Write-Host "`n*** Windows Update Checker ***`n" -ForegroundColor Magenta
Start-Sleep -Milliseconds 500

# Prompt user for KB number
$kbnum = Read-Host -Prompt "Please enter the KB number (e.g., KB5034441)"

# Confirmation of user input
Write-Host "`nYou entered KB: $kbnum" -ForegroundColor Yellow
Start-Sleep -Milliseconds 800

# Check if kb is installed
Write-Host "`nChecking if KB is installed..." -ForegroundColor Cyan
Start-Sleep -Milliseconds 1000

$kbinstalled = Get-WindowsUpdate -KBArticleID $kbnum -IsInstalled -ErrorAction SilentlyContinue

# Update user of KB installation status. Prompt user to install if missing 
if ($kbinstalled) {
    Write-Host "`n✅ Windows patch $kbnum is installed" -ForegroundColor Green
} else {
    Write-Host "`n❌ Windows patch $kbnum is NOT installed." -ForegroundColor Red

    # Prompt user for installation
    Write-Host ""
    $installkb = Read-Host "Do you wish to install KB now? (Y/N)"

    if ($installkb -match '^[Yy]$') {
        Write-Host "`n🔄 Starting installation of $kbnum..." -ForegroundColor Cyan
        Start-Sleep -Milliseconds 1000

        try {
            Install-WindowsUpdate -KBArticleID $kbnum -AcceptAll -Verbose -ErrorAction Stop

            # Check installation result
            $Successkbinstall = Get-WindowsUpdate -KBArticleID $kbnum -IsInstalled -ErrorAction SilentlyContinue

            if ($Successkbinstall) {
                Write-Host "`n✅ SUCCESS!" -ForegroundColor Green
            } else {
                Write-Host "`n❌ Failed to install $kbnum" -ForegroundColor Red
            }
        } catch {
            Write-Host "`n⚠️  Error occurred while installing $kbnum" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor DarkRed
        }

    } else {
        Write-Host "`n⏭️  Installation Declined. No further action to " -ForegroundColor Yellow
    }
}

# Check if reboot is required
if (Get-WURebootStatus) {
    $rebootnow = Read-Host "`n🚨 Reboot is required for $kbnum. do you wish to reboot now? (Y/N)" -ForegroundColor Yellow

    # Prompt user to reboot to complete update
    if ($rebootnow -match '^[Yy]$') {
        Write-Host "`n⏭️ Rebooting..." -ForegroundColor yellow
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    } else {
        Write-Host "Script completed successfully." -ForegroundColor Green
        Start-Sleep -Seconds 3
        exit 0
        }
}
