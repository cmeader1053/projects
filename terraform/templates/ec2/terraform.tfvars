/*
Title = tfvars document for EC2 instance deployment
Description = tfvars terraform document to deploy EC2 instances
Directions = Update variables for the EC2 instance 
*/

# Instance Details
name 			= "prd-web-svr"
instance_type	= ""
root_vol_size	= 20	# Size in GB
os_type			= "linux"

# Security
key_name		= ""
iam_profile		= ""

# Networking
subnet_id		= ""
sec_grp_id		= [""]

# Tags
tags = {
	Environment = "Prod"
	Project		= "Website"
	Owner		= "Infrastructure"
	ManagedBy	= "Terraform"
}
