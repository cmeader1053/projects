import datetime
import requests
import boto3
import logging
import urllib3
import io
import os

# === Disable SSL Warnings ===
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# === REST API Tokens ===
{Site_A_API_Token_Var} = os.environ.get('{Site_A_Env_Var}', None)
{Site_B_API_Token_Var} = os.environ.get('{Site_B_Env_Var}', None)
{Site_C_API_Token_Var} = os.environ.get('{Site_C_Env_Var}', None)
{Site_D_API_Token_Var} = os.environ.get('{Site_D_Env_Var}', None)

# === Firewall Details ===
firewalls = [
{'host': '{Enter_Host_IP_Here}', 'port': '{Enter_Host_Port_Here}', 'token': {Enter_API_Token_Var_Here}, 'site': '{Enter_Site_Name_Here}', 'scope': '{Enter_Host_Scope_Here}'},
{'host': '{Enter_Host_IP_Here}', 'port': '{Enter_Host_Port_Here}', 'token': {Enter_API_Token_Var_Here}, 'site': '{Enter_Site_Name_Here}', 'scope': '{Enter_Host_Scope_Here}'},
{'host': '{Enter_Host_IP_Here}', 'port': '{Enter_Host_Port_Here}', 'token': {Enter_API_Token_Var_Here}, 'site': '{Enter_Site_Name_Here}', 'scope': '{Enter_Host_Scope_Here}'},
{'host': '{Enter_Host_IP_Here}', 'port': '{Enter_Host_Port_Here}', 'token': {Enter_API_Token_Var_Here}, 'site': '{Enter_Site_Name_Here}', 'scope': '{Enter_Host_Scope_Here}'},
]

# === AWS Credentials ===
aws_access_key = os.environ.get('{AWS_Access_Key}', None)
aws_secret_key = os.environ.get('{AWS_Secret_Key}', None)
s3_bucket = '{S3_Bucket_Name}'


# === S3 Client ===
s3 = boto3.client(
    's3',
    aws_access_key_id=aws_access_key,
    aws_secret_access_key=aws_secret_key
)

# === Setup In Memory Logging ===
timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
log_stream = io.StringIO()
file_handler = logging.StreamHandler(log_stream)
file_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
    
logger = logging.getLogger('firewall_backup')
logger.setLevel(logging.INFO)
    
if logger.hasHandlers():
    logger.handlers.clear()
logger.addHandler(file_handler)

def fw_backup(fw):
    host = fw['host']
    port = fw['port']
    token = fw['token']
    site = fw['site']
    scope = fw['scope']
    
    logger.info('=' * 60)
    logger.info(f'Initiating config backup for {site}')
    logger.info('=' * 60)
    
    print(f'\n== {site} backup in progress ===')

    try:
        # === Connect to Firewall ===
        url = f'https://{host}:{port}/api/v2/monitor/system/config/backup?scope={scope}'
        headers = {'Authorization': f'Bearer {token}'}
        
        print('Attempting to Connect to Firewall... ')
        response = requests.get(url, headers=headers, verify=False, timeout=30)
        response.raise_for_status()
        
        if response.status_code == 200:
            print('Connection Successful')
            logger.info(f'{site}: Successful Connection.')
            
            # === Upload config to S3 ===
            fw_backup_file = f'{site}_fw_backup_config_{timestamp}.config'
            s3_backup_key = f'{ENTER_S3_KEY_HERE}/{fw_backup_file}'
            s3.put_object(
                Bucket=s3_bucket,
                Key=s3_backup_key,
                Body=response.content
            )
            logger.info(f'{site}: Backup uploaded to s3://{s3_bucket}/{s3_backup_key}')
            print(f'{site}: Backup uploaded to s3://{s3_bucket}/{s3_backup_key}')

        else:
            print(f'{site}: Backup Failed. See {fw_logs_file} for more details')
            logger.error(f'{site} backup failed. Status: {response.status_code}, Response: {response.text}')
       
    except Exception as e:
        logger.exception(f'{site}: Connection failed - {e}')
        print(f'{site} connection Failed: {e}')
       
    finally:
        logger.info(f'{site}: Session disconnected')
        print(f'{site} session Disconnected\n')
        
# === Run Backups for Each Firewall ===
for fw in firewalls:
    fw_backup(fw)
    
# === Upload Logs to S3 ===
log_stream.seek(0)
s3_logs_key = f'{ENTER_S3_LOGS_KEY}/fw_backup_logs_{timestamp}.log'
s3.put_object(
    Bucket=s3_bucket,
    Key=s3_logs_key,
    Body=log_stream.getvalue().encode('utf-8')
    )
print(f'\nLogs uploaded to s3://{s3_bucket}/{s3_logs_key}')
        
# === Cleanup Memory ===
log_stream.close()
        
