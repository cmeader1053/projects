<#
Title: Account Lockout Investigator
Script Name:  get-user-lockout-details.ps1
Description:  Searches domain controllers for account lockout events within the last 30 days and reports source including machine, caller, timestamps, etc.
Directions:  Requires a username (SAMAccountName) to be entered into the prompt to search. This script needs to be ran on a domain controller itself.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$Username,

    [int]$DaysBack = 30
)

# --- Requires ActiveDirectory module ---
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Error "ActiveDirectory module not found. Ensure this is being run on a Domain Controller."
    exit 1
}

Import-Module ActiveDirectory

# --- Get current account status ---
Write-Host "`n=== Account Status ===" -ForegroundColor Cyan
try {
    $user = Get-ADUser -Identity $Username -Properties LockedOut, BadLogonCount, LastBadPasswordAttempt, PasswordLastSet, PasswordExpired
    Write-Host "User              : $($user.SamAccountName)"
    Write-Host "Display Name      : $($user.Name)"
    Write-Host "Locked Out        : $($user.LockedOut)"
    Write-Host "Bad Logon Count   : $($user.BadLogonCount)"
    Write-Host "Last Bad Password : $($user.LastBadPasswordAttempt)"
    Write-Host "Password Last Set : $($user.PasswordLastSet)"
    Write-Host "Password Expired  : $($user.PasswordExpired)"
} catch {
    Write-Error "Could not find user '$Username' in Active Directory."
    exit 1
}

# --- Search local Security log for lockout events (Event ID 4740) ---
$startTime = (Get-Date).AddDays(-$DaysBack)
$lockoutEvents = @()

Write-Host "`n=== Searching Local Security Event Log (Last $DaysBack days) ===" -ForegroundColor Cyan
Write-Host "Start Time: $startTime"
Write-Host "Querying: $env:COMPUTERNAME ..." -NoNewline

try {
    $filter = @{
        LogName   = 'Security'
        Id        = 4740
        StartTime = $startTime
    }

    $events = Get-WinEvent -FilterHashtable $filter -ErrorAction Stop

    $userEvents = $events | Where-Object {
        $_.Properties[0].Value -eq $Username
    }

    if ($userEvents) {
        Write-Host " Found $($userEvents.Count) lockout event(s)" -ForegroundColor Yellow
        foreach ($evt in $userEvents) {
            $lockoutEvents += [PSCustomObject]@{
                Time          = $evt.TimeCreated
                LockedUser    = $evt.Properties[0].Value
                SourceMachine = $evt.Properties[1].Value
                ReportingDC   = $env:COMPUTERNAME
                EventRecordID = $evt.RecordId
            }
        }
    } else {
        Write-Host " No lockout events found for '$Username'" -ForegroundColor Green
    }
} catch [System.Exception] {
    if ($_.Exception.Message -match "No events") {
        Write-Host " No matching events in the last $DaysBack days" -ForegroundColor Green
    } else {
        Write-Host " ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --- Display Results ---
Write-Host "`n=== Lockout Events ===" -ForegroundColor Cyan

if ($lockoutEvents.Count -eq 0) {
    Write-Host "No lockout events found for '$Username' in the last $DaysBack days." -ForegroundColor Green
} else {
    $lockoutEvents | Sort-Object Time -Descending | Format-Table -AutoSize

    # --- Source machine summary ---
    Write-Host "`n=== Lockout Source Summary ===" -ForegroundColor Cyan
    $lockoutEvents | Group-Object SourceMachine | Sort-Object Count -Descending | ForEach-Object {
        Write-Host "  $($_.Count)x  -->  $($_.Name)" -ForegroundColor Yellow
    }

    # --- Frequency breakdown by day ---
    Write-Host "`n=== Lockouts by Day ===" -ForegroundColor Cyan
    $lockoutEvents | Group-Object { $_.Time.ToString("yyyy-MM-dd") } | Sort-Object Name -Descending | ForEach-Object {
        Write-Host "  $($_.Name)  :  $($_.Count) lockout(s)"
    }

    Write-Host "`n=== Recommended Next Steps ===" -ForegroundColor Cyan
    Write-Host "1. RDP or PSRemote into the source machine(s) listed above"
    Write-Host "2. Check Credential Manager for saved/stale credentials"
    Write-Host "3. Look for mapped drives, scheduled tasks, or services running as this user"
    Write-Host "4. Check for old sessions still authenticating (VPN clients, mobile devices)"
    Write-Host "5. Review application event logs on the source machine for repeated auth failures"
}

# --- Optional: Unlock the account ---
Write-Host ""
$unlock = Read-Host "Unlock '$Username' now? (y/N)"
if ($unlock -eq 'y') {
    Unlock-ADAccount -Identity $Username
    Write-Host "Account unlocked." -ForegroundColor Green
}
