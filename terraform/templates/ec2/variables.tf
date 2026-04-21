/*
Title:  AWS EC2 Instance Variables 
Description:  Terraform document for EC2 variables. 
*/

# Instance Configuration Variables
variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
}

variable "aws_region" {
  description = "AWS region where resources are launched"
  type        = string

}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "os_type" {
  description = "OS type for EC2 instance. Ignored if specific AMI Id is provided."
  type        = string
}

variable "instance_type" {
  description = "EC2 Instance type"
  default     = "t2.micro"
  type        = string
}

variable "subnet_id" {
  description = "Subnet for EC2 instance"
  type        = string
}

variable "sec_grp_ids" {
  description = "Security Groups for EC2 instance"
  type        = list(string)
}

variable "key_name" {
  description = "SSH key pair for EC2 instance"
  type        = string
  default     = "null"
}

variable "iam_profile" {
  description = "IAM profile attached to EC2 instance"
  type        = string
  default     = "null"
}

# EBS Root Volume Variables 
variable "root_vol_type" {
  description = "EBS root volume type"
  type        = string
}

variable "root_vol_size" {
  description = "EBS root volume size in GB"
  type        = number
  default     = 20
}

# Tag Variables 
variable "instance_name" {
  description = "Name of EC2 instance"
  type        = string

}

variable "environment" {
  description = "Environment where resource is launched"
  type        = string
}

variable "owner" {
  description = "Owner or POC for resource"
  type        = string
}

variable "project" {
  description = "Project resource is created for"
  type        = string
}

