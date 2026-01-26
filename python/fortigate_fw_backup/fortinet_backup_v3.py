"""
Script Name:  fortinet_backup_v3.py
Description:  Update to Fortinet firewall backup script to be able to access and drop backup file to an existing S3 bucket. 
              The script will still save the backup file to a local file path as well.
Directions:   Script requires a REST API token (see v2 script for directions) and previously created S3 bucket in AWS. 
              To access the S3 bucket, this requires the creation of an IAM user with permissions to drop objects into the 
              bucket and possibly KMS permissions to handle the encryption. Aditionally, you will need to generate access an 
              secret keys for the IAM user which confogured as environment variables on the local host where the script 
              executes. 
Updates:      Requires the use of environment variables configured on host. Adds boto3 to access S3 bucket and drop object 
              into bucket.  
"""
import pwinput
import datetime
import os
import requests
import boto3

# Firewall Details
host = input('Enter Firewall IP: ')
port = input('Enter Firewall HTTPS port: ')

# Credentials
api_token = os.environ.get('{ENTER_ENV_VARIABLE_HERE}', None)
aws_access_key = os.environ.get('{ENTER_ENV_VARIABLE_HERE}', None)
aws_secret_key = os.environ.get('{ENTER_ENV_VARIABLE_HERE}', None)

# Firewall Details
fortigate_fw = {
    "device_type": "fortinet",
    "host": host,
    "api_token": api_token, # API is stored not showed in confirmation
    "port": port,
    "access_key": aws_access_key,
    "secret_key": aws_secret_key
}

# Confirm Fortinet Firewall Details Hiding Password
safe_copy = fortigate_fw.copy()
safe_copy["api_token"] = "<hidden>"
safe_copy["secret_key"] = "<hidden>"

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
        
        # Local Environment 
        file_path = r'{ENTER_FILE_PATH_HERE}'
        timestamp = datetime.datetime.now().strftime('%Y%m%d')
        backup_file = os.path.join(file_path, f'{host}_FW_Backup_Config_{timestamp}.config')
              
        # Save Config Locally
        with open(backup_file, "wb") as f:
            f.write(backup)
            print(f'Backup Backup saved locally:  {backup_file}')
    
        # Upload Config to S3
        s3_client = boto3.client(
            's3', 
            aws_access_key_id=os.environ.get('{ENTER_ENV_VARIABLE_HERE}'),
            aws_secret_access_key=os.environ.get('{ENTER_ENV_VARIABLE_HERE}')
        )
            
        s3_bucket = '{ENTER_S3_BUCKET_NAME_HERE}'
        s3_object_key = f'{ENTER_S3_OBJECT_PATH_HERE}{host}_FW_Backup_Config_{timestamp}.config'
        
        s3_client.upload_file(backup_file, s3_bucket, s3_object_key)
        print(f'File uploaded to s3://{s3_bucket}/{s3_object_key}"')
    
    else: 
        print(f'Backup failed. Status: {response.status_code}, Response: {response.text}')
    
except Exception as e:
    print(f'Connection Failed: {e}')
finally:
        print('Session Disconnected')   
