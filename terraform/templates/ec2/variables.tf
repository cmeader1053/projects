/*
Title = EC2 Terraform Variables
Description = Variables Terraform document for EC2 Instance deployment. 
Directions = Update the variables as seen fit to be called by the main.tf file.
*/

# Environment
variable "environment" {
	description = "Environment EC2 will be in"
	type = string
}

# AWS Access
variable "aws_access_key_id" {
	Description = "AWS access key for environment"
	type = string
}

variable "aws_secret_access_key" {
	Description = "AWS secret access key for environment"
	type = string
	sensitive = true
}

# Instance AMI
variable "ami_id" {
	description = "AMI ID for EC2 instance"
	type = string
}

# Define Instance Type
variable "instance_type" {
	description = "Instance type for EC2 instance"
	type = string
	default = "t3.micro"
}

# Subnets
variable "subnet_id" {
	description = "Subnet ID for EC2 instance"
	type = string
}

# Add Security Groups
variable "sec_grp_id" {
	description = "Security group ID for EC2 instance"
	type = list(string)
}

# Add SSH Key Pair
variable "key_name" {
	description = "SSH key pair for EC2 instance"
	type = string
	default = null
}

# Add IAM Profile
variable "iam_profile" {
	description = "IAM profile attached to EC2 instance"
	type = string
	default = null
}

# Define EBS Root Volume
variable "root_vol_size" {
	description = "Root EBS volume size in GB"
	type = number
	default = 20
}

# EC2 Instance Name
variable "name" {
	description = "Name of EC2 instance"
	type = string
}

# Tags		# Tags can be modified in the terraform.tfvars file
variable "tags" {
	description = "Tags applied to all resources"
	type = map(string)
	default = {}
}
