/*
Title:  AWS Security Group Deployment - Terraform Variables
Description:  Terraform variables template for security group creation
*/

# AWS Region
variable "aws_region" {
  description = "AWS Region where resource is deployed too"
  type        = string
}

# Security Group Configuration Variables
variable "sec_grp_name" {
  description = "Name of security group"
  type        = string
}

variable "sec_grp_description" {
  description = "Security group description"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID "
  type        = string
}

# Ingress Variables 
variable "allow_ssh" {
  description = "Ingress rule to allow ssh traffic for linux"
  type        = bool
  default     = false
}

variable "ssh_cidr" {
  description = "CIDR for ssh traffic for linux"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allow_rdp" {
  description = "Ingress rule to allow rdp traffic for Windows"
  type        = bool
  default     = false
}

variable "rdp_cidr" {
  description = "CIDR for rdp traffic for windows"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allow_http" {
  description = "Ingress rule to allow HTTP traffic"
  type        = bool
  default     = false
}

variable "allow_https" {
  description = "Ingress rule to allow HTTPS traffic"
  type        = bool
  default     = false
}

# Tag Variables
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

/*
Blank variable block for easy copy/paste

variable "" {
  description = ""
  type        = 
}
*/
