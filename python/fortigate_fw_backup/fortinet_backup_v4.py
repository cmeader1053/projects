"""
Script Name:  fortinet_backup_v4.py
Description:  Version 4 of script. Fortinet firewall backups to both local file path and S3 bucket including logging for script execution.
Directions:   Script requires a REST API token (see v2 script for directions) and previously created S3 bucket in AWS. 
              To access the S3 bucket, this requires the creation of an IAM user with permissions to drop objects into the 
              bucket and possibly KMS permissions to handle the encryption. Aditionally, you will need to generate access an 
              secret keys for the IAM user which confogured as environment variables on the local host where the script 
              executes. This script requires both a local file path and S3 object key for logs file uploads.
Updates:      Requires the use of the loggin python library. Introduces logging and uploads logs file for script execution to both local file path and S3 bucket.  
"""

import pwinput
import datetime
import os
import requests
import boto3
import logging

# Firewall Details
host = input('Enter Firewall IP: ')
port = input('Enter Firewall HTTPS port: ')

# Credentials
api_token = os.environ.get('{ENTER_API_ENV_VAR_HERE}', None)
aws_access_key = os.environ.get('{ENTER_ACCESS_ENV_VAR_HERE}', None)
aws_secret_key = os.environ.get('{ENTER_SECRET_ENV_VAR_HERE}', None)

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

# Set timestamp
timestamp = datetime.datetime.now().strftime('%Y%m%d')

# Local Environment 
backup_path = r'{ENTER_LOCAL_BACKUP_FILE_PATH_HERE}'
logs_path = os.path.join(backup_path, "LOGS")

if not os.path.exists(logs_path):
    os.makedirs(logs_path)

# Configure local log File
log_file = os.path.join(logs_path, f'{host}_fw_backup_LOGS_{timestamp}.log')
logging.basicConfig(filename=log_file, level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# S3 Bucket Details
s3_bucket = '{ENTER_S3_BUCKET_NAME_HERE}'
s3_object_key = f'{ENTER_BACKUP_OBJECT_KEY_HERE}/{host}_FW_Backup_Config_{timestamp}.config'
s3_logs_key = f'{ENTER_LOGS_OBJECT_KEY_HERE}/{host}_fw_backup_LOGS_{timestamp}.log'

# Connect to Firewall via SSH
try:
    # Connect to Firewall
    print('Attempting to Connect to Firewall... ')
    response = requests.get(url, headers=headers, verify=False)
    
    if response.status_code == 200:
        print('Connection Successful')
        logger.info("Successful Connection.")
    
        # Pull Firewall Configuration Backup
        print('Fetching full configuration...')
        backup = response.content

        backup_file = os.path.join(backup_path, f'{host}_FW_Backup_Config_{timestamp}.config')
        local_logs = os.path.join(logs_path, f'{host}_FW_Backup_LOGS_{timestamp}.log')
              
        # Save Config Locally
        with open(backup_file, "wb") as f:
            f.write(backup)
            print(f'Backup saved locally:  {backup_file}')
            logger.info(f'Backup file saved:  {backup_file}')
            
            print(f'Logs saved locally:  {log_file}')
    
        # Call access/secret keys to access S3
        s3_client = boto3.client(
            's3', 
            aws_access_key_id=os.environ.get('{ENTER_ACCESS_KEY_ENV_VAR_HERE}'),
            aws_secret_access_key=os.environ.get('{ENTER_SECRET_KEY_ENV_VAR_HERE}')
        )
        
        # Upload backup file to S3
        s3_client.upload_file(backup_file, s3_bucket, s3_object_key)
        logger.info(f'Backup file uploaded to S3')
        print(f'File uploaded to s3://{s3_bucket}/{s3_object_key}')
        
        # Upload log file to s3
        s3_client.upload_file(log_file, s3_bucket, s3_logs_key)
        logger.info(f'Log file uploaded to S3')
        print(f'Logs uploaded to S3://{s3_bucket}{s3_logs_key}')
       
    else: 
        print(f'Backup failed. See {log_file} for more details')
        logger.error(f'Backup failed. Status: {response.status_code}, Response: {response.text}')
    
except Exception as e:
    print(f'Connection Failed: {e}')
    logger.exception('Connection failed')
    
finally:
        print('Session Disconnected')
        logger.info('Session disconnected')
