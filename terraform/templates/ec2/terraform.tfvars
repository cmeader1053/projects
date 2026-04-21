/*
Title:  Terraform tfvars file for EC2 deployment
Description:  Terraform tfvars file used to update variables to deploy EC2 instances
Directions:  Update each variable accordingly from their default values. 
If you know the specific AMI ID, comment out or remove the os_type and vice versa. 
*/


# Environment
environment = "DEV"

# AWS Region
aws_region = "us-east-1"

# Instance Configuration
instance_name  = ""
instance_count = 1
instance_type  = "t2.micro"
root_vol_type  = "gp3"
root_vol_size  = 20
ami_id         = null
os_type        = "linux"

# Networking
subnet_id   = ""
sec_grp_ids = [""]

# Access
key_name    = null
iam_profile = null

# Tags
owner   = ""
project = ""
