"""
Script_Name: aws_key_rotation_v1.py
version:     1.0
Author:      Chris Meader, Cloud Systems Admin
Description: Python script to get aws IAM users and their active access keys. Script will calculate the age and notify appropriate groups if requires to be rotated.
             Alerts come as email warnings (age >= 75 days) and crtical alerts (>= 90 days) using Active Directory distribution groups. 
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

# Credentials
aws_access_key = os.environ.get('<ENTER_ACCESS_KEY_ENV_VARIABLE_HERE>', None)
aws_secret_key = os.environ.get('<ENTER_ACCESS_KEY_ENV_VARIABLE_HERE>', None)

# AWS Details
tag_key = "<ENTER_TAG_KEY>"
tag_value = "<ENTER_TAG_VALUE>"
# Configure IAM Client with Boto3
session = boto3.Session(
    aws_access_key_id=aws_access_key,
    aws_secret_access_key=aws_secret_key
)

iam = session.client("iam")

# Get IAM User with Tag
def get_users_by_tag(tag_key, tag_value):
    logging.info(f"Searching for users with tag {tag_key}={tag_value}")
    users = []
    paginator = iam.get_paginator("list_users")
    
    for page in paginator.paginate():
        for user in page["Users"]:
            username = user["UserName"]
            
            try:
                tag_response = iam.list_user_tags(UserName=username)
                tags = {t["Key"]: t["Value"] for t in tag_response.get("Tags", [])}
                
                if tags.get(tag_key) == tag_value:
                    logging.info(f"Matched user: {username}")
                    users.append(username)
                    
            except iam.exceptions.NoSuchEntityException:
                logging.warning(f"User not found when listing tags: {username}")
                continue
            
    return users

# Get IAM Users Access Key Age
def get_access_key_age(username):
    logging.info(f"Checking access keys for user: {username}")
    response = iam.list_access_keys(UserName=username)
    keys_info = []
    
    for key in response.get("AccessKeyMetadata", []):
        create_date = key["CreateDate"]
        key_age = (datetime.now(timezone.utc) - create_date).days
        
        logging.info(
            f"User={username}, Key={key['AccessKeyId']}, Age={key_age} days"
        )
        
        keys_info.append({
            "AccessKeyId": key["AccessKeyId"],
            "Status": key["Status"],
            "CreateDate": create_date,
            "Age": key_age
        })
        
    return keys_info
    
# Show IAM User Access Key Report
def main ():
    
    # Search for IAM User with Tag
    print(f"\nChecking IAM users for tag:  {tag_key}={tag_value}... \n")
    
    users = get_users_by_tag(tag_key, tag_value)
    
    if not users:
        print(f"No users found")
        return 
    
    # Calculate Age of IAM User Access Key
    for username in users:
        print(f"\nUser: {username}")
        keys = get_access_key_age(username)
        
        if not keys:
            print("No access keys found.\n")
            continue
            
        for key in keys:
            print(f"  AccessKeyId: {key['AccessKeyId']}")
            print(f"  Status:      {key['Status']}")
            print(f"  Created:     {key['CreateDate']}")
            print(f"  Age (days):  {key['Age']}\n")
            
            # Key Alert Configuration
            age = key["Age"]
            status = key["Status"]
            
            # Inactive Key Alerts
            if status == "Inactive":
                print(f"INACTIVE:  Key is {age} days old with {status} status. Review key and delete.\n")
                continue
            
            # Active Key Alerts
            if 75 <= age < 90:
                print(f" WARNING:  Active key is {age} days old. Schedule key rotation.\n")
                
            elif age >= 90:
                print(f" CRITICAL: Active key is {age} days old. Rotate key IMMEDIATELY!\n")
                
            else:
                print(f" COMPLIANT: Active key is {age} days old. No action required.\n")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
         logging.exception("FATAL ERROR in main()")
         print("\nFatal error. Check log file")
    finally:
         input("\nPress Enter to exit...")
