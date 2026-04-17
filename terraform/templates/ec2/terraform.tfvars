/*
Title = tfvars document for EC2 instance deployment
Description = tfvars terraform document to deploy EC2 instances
Directions = Update variables for the EC2 instance 
*/

# Environment
environment = "prod"

# Instance Details
name 			= "prd-web-svr"
instance_type	= "t2.micro"
root_vol_size	= 20	# Size in GB
root_vol_type 	= "gp3"
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
