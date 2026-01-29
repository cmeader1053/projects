<#
Script Name:  GetAccountSuccessfulLogins.ps1
Author:  Chris Meader, Cloud Sys Admin
Author Date:  10/13/2025
Description:
This script will search for successful logins of a domain account and return the IP of the targeted machine that it successfully logged into. Typically this returns an IP
Which can be queired against DNS to determine the hostname if needed. 
#>

# Enter domain to search against
Get-WinEvent -ComputerName <DCName> -FilterHashtable @{
    LogName='Security'     # Specific event log to search
    Id=4624                # Event log ID for successful logins on windows machines
    Data='<account_name>'  # Enter account name to search
} -MaxEvents 25 | 
Select-Object TimeCreated, MachineName, @{n='TargetComputer';e={$_.Properties[18].Value}}
