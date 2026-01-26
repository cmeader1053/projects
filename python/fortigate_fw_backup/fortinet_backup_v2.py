"""
Script Name:  fortinet_backup_v2.py
Description:  Update to Fortinet firewall backup script to leverage a REST API Admin to connect to the firewall and 
              execute config backup command
Directions:   Scripts requires a REST API token generated from the firewall. This includes creating a REST API Admin profile 
              with appropriate permissions, creating a REST API Admin user associated with the previously created REST API 
              admin profile and setting trusted host. 
Updates:      Removed netmiko library and prompts for username/password. Added Requests library for HTTP client and adjusted 
              code to leverage library. Adjusted prompts for just IP of firewall and port used to access GUI of firewall 
              (HTTPS port). 

NOTE:  This version of the script requires a hard code of the API Token generated from the Fortinet. 
"""

import pwinput
import datetime
import os
import requests

# Firewall Hostname
host = input('Enter Firewall IP: ')
port = input('Enter Firewall HTTPS port: ')

# Credentials
api_token = "{Enter-API-Token-HERE}"

# Firewall Details
fortigate_fw = {
    "device_type": "fortinet",
    "host": host,
    "api_token": api_token, # API is stored not showed in confirmation
    "HTTPS_port": port
}

# Confirm Fortinet Firewall Details Hiding Password
safe_copy = fortigate_fw.copy()
safe_copy["api_token"] = "<hidden>"

print(safe_copy)

# REST API URL
url = f"https://{host}:{port}/api/v2/monitor/system/config/backup?scope=global"
headers = {"Authorization": f"Bearer {api_token}"}

# Disable SSL warnings
requests.packages.urllib3.disable_warnings()

# Connect to Firewall via SSH
try:
    # Connect to Firewall
    print('Attempting to Connect to Firewall... ')
    response = requests.get(url, headers=headers, verify=False)
    
    if response.status_code == 200:
        print('Connection Successful')
    
        # Pull Firewall Configuration Backup
        print('Fetching full configuration...')
        backup = response.content
    
        # Save Backup Config File
        file_path = r'{ENTER-YOUR-FILE-PATH-HERE}'
        timestamp = datetime.datetime.now().strftime('%Y%m%d')
        backup_file = os.path.join(file_path, f'{host}_FW_Backup_Config_{timestamp}.config')
    
        with open(backup_file, "wb") as f:
            f.write(backup)
            print('Backup Complete')
    else: 
        print(f'Backup failed. Status: {response.status_code}, Response: {response.text}')
    
except Exception as e:
    print(f'Connection Failed: {e}')
finally:
        print('Session Disconnected')   
