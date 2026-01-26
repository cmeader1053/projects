"""
Script Name:  fortinet_backup.py
Description:  Python script to automate full config backups of fortinet firewalls and save backup file to designated located. 
Directions:   Run script and enter information as prompted - Firewall IP, username, password, ssh port
Overview:     Script leverages netmiko library to form ssh tunnel to firewall utilizing information provided to prompts. 
              User interaction is required for successful execution.
"""

from netmiko import ConnectHandler
import pwinput
import datetime
import os

# Firewall Hostname
host = input('Enter Firewall IP: ')

# SSH Port
port = input('Enter Firewall SSH port: ')

# Credentials
username = input('Enter Username: ')
password = pwinput.pwinput(prompt='Enter your password: ')

# Firewall Details
fortigate_fw = {
    "device_type": "fortinet",
    "host": host,
    "username": username,
    "password": password, # Password is stored but not showed in confirmation
    "port": port
}

# Confirm Fortinet Firewall Details Hiding Password
safe_copy = fortigate_fw.copy()
safe_copy["password"] = "<hidden>"

print(safe_copy)

# Connect to Firewall via SSH
try:
    # Connect to Firewall
    print('Attempting to Connect to Firewall... ')
    connection = ConnectHandler(**fortigate_fw)
    print('Connection Successful')
    
    # Pull Firewall Configuration Backup
    print('Fetching full configuration...')
    backup = connection.send_command('show full-configuration', delay_factor=5)
    
    # Save Backup Config File
    file_path = r'{ENTER_FILE_PATH_HERE}'
    timestamp = datetime.datetime.now().strftime('%Y%m%d')
    backup_file = os.path.join(file_path, f'{host}_FW_Backup_Config_{timestamp}.config')
    
    with open(backup_file, "w", encoding="utf-8") as f:
        f.write(backup)
    
    print('Backup Complete')
    
except Exception as e:
    print(f'Connection Failed: {e}')
finally:
    if 'connection' in locals():
        connection.disconnect()
        print('Session Disconnected')   
