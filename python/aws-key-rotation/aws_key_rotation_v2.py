"""
Script_Name: aws_key_rotation_v2.py
version:     2.0
Author:      Chris Meader, Cloud Systems Admin
Description: Python script can be run as a Lambda function or local host using IAM role. This script will search multiple AWS accounts for any user with a tag and check for
an access key. Any access keys located, it will calculate the current age and output if the key is compliant or not based on age.
"""

import os
import boto3
from datetime import datetime, timezone
import logging

# Logging Configuration
log_file = r"<ENTER_FILE_PATH_HERE>"
logging.basicConfig(
    filename=log_file,
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s" 
)

# Shared Services IAM User Credentials
aws_access_key = os.environ.get('<ENTER_ENV_VAR_HERE>', None)
aws_secret_key = os.environ.get('<ENTER_ENV_VAR_HERE>', None)

# Tag Filters
tag_key = "<ENTER_TAG_KEY>"
tag_values = ["<ENTER_TAG_KEY_1>", "<ENTER_TAG_KEY_2>"]

# AWS Accounts
target_accounts = {
    "<ENTER_ACCOUNT_NUMBER_1>": None, # ACCOUNT NUMBER WHERE MAIN CODE EXECUTES
    "<ENTER_ACCOUNT_NUMBER_2>": "<ENTER_ARN_IAM_ROLE>",
    "<ENTER_ACCOUNT_NUMBER_3>": "<ENTER_ARN_IAM_ROLE>",
}

# Establish IAM Sesson Per Account
def get_iam_session(account_id, role_arn=None):
    if role_arn:
        # Use Assumed Role Created in Each Account 
        try:
            sts_client = boto3.client(
                "sts",
                aws_access_key_id=aws_access_key,
                aws_secret_access_key=aws_secret_key
            )
            response = sts_client.assume_role(
                RoleArn=role_arn,
                RoleSessionName=f"KeyAuditSession-{account_id}"
            )
            creds = response["Credentials"]
            session = boto3.Session(
                aws_access_key_id=creds["AccessKeyId"],
                aws_secret_access_key=creds["SecretAccessKey"],
                aws_session_token=creds["SessionToken"]
            )
            return session
        except Exception as e:
            logging.exception(f"Failed to assume role for account {account_id}")
            return None
    else:
        # Use IAM User in Shared Services Account
        session = boto3.Session(
            aws_access_key_id=aws_access_key,
            aws_secret_access_key=aws_secret_key
        )
        return session

# Get IAM User by Tag
def get_users_by_tag(iam_client, tag_key, tag_values):
    logging.info(f"Searching for users with tag {tag_key} in {tag_values}")
    users = []
    paginator = iam_client.get_paginator("list_users")
    
    for page in paginator.paginate():
        for user in page["Users"]:
            username = user["UserName"]
            
            try:
                tag_response = iam_client.list_user_tags(UserName=username)
                tags = {t["Key"]: t["Value"] for t in tag_response.get("Tags", [])}
                
                if tags.get(tag_key) in tag_values:
                    logging.info(f"Matched user: {username}")
                    users.append(username)
                    
            except iam_client.exceptions.NoSuchEntityException:
                logging.warning(f"User not found when listing tags: {username}")
                continue
            
    return users

# Get IAM Users Access Key Age
def get_access_key_age(iam_client, username, account_id):
    logging.info(f"Checking access keys for user: {username} in account {account_id}")
    keys_info = []
    response = iam_client.list_access_keys(UserName=username)
    
    
    for key in response.get("AccessKeyMetadata", []):
        create_date = key["CreateDate"]
        key_age = (datetime.now(timezone.utc) - create_date).days
        
        logging.info(
            f"User={username}, Account={account_id}, Key={key['AccessKeyId']}, Age={key_age} days"
        )
        
        keys_info.append({
            "AccessKeyId": key["AccessKeyId"],
            "Status": key["Status"],
            "CreateDate": create_date,
            "Age": key_age
        })
        
    return keys_info
    
#
def process_account(account_id, role_arn):
    session = get_iam_session(account_id, role_arn)
    if not session:
        print(f"Failed to assume role for account {account_id}")
        return
        
    iam_client = session.client("iam")
    users = get_users_by_tag(iam_client, tag_key, tag_values)
     
    if not users:
       print(f"No users found in account {account_id}")
       return
    
    for username in users:
        print(f"\nAccount: {account_id} | User: {username}")
        keys = get_access_key_age(iam_client, username, account_id)
        if not keys:
            print("  No access keys found.\n")
            continue
        
        for key in keys:
            age = key["Age"]
            status = key["Status"]
            print(f"  AccessKeyId: {key['AccessKeyId']}")
            print(f"  Status:      {status}")
            print(f"  Created:     {key['CreateDate']}")
            print(f"  Age (days):  {age}")
            
            if status == "Inactive":
                print(f"  INACTIVE: Key is {age} days old. Review and delete.")
            elif 75 <= age < 90:
                print(f"  WARNING: Active key is {age} days old. Schedule rotation.")
            elif age >= 90:
                print(f"  CRITICAL: Active key is {age} days old. Rotate immediately!")
            else:
                print(f"  COMPLIANT: No action required.")
            print("")    

         
    
# Scan Each Target Account
def main ():
    
    for account_id, role_arn in target_accounts.items():
        print(f"\n=== Scanning Account {account_id} ===")
        process_account(account_id, role_arn)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
         logging.exception("FATAL ERROR in main()")
         print("\nFatal error. Check log file")
    finally:
         input("\nPress Enter to exit...")
