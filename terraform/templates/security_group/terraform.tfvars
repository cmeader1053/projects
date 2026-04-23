/*
Title:  AWS Security Group Deployment - Terraform tfvars
Description:  Terraform tfvars template for security group creation
Directions:  Update each variable to appropriate value                   
*/

# AWS Region
aws_region = "us-east-1"

# Security Group Configuration
sec_grp_name        = ""
sec_grp_description = ""
vpc_id              = ""

# Ingress Rules
allow_ssh   = true
ssh_cidr    = ""
allow_rdp   = false
rdp_cidr    = ""
allow_http  = true
allow_https = true



# Tags
environment = "dev"
owner       = ""
project     = ""
