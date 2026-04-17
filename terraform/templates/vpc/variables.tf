/*
Title          = VPC Variables Terraform
Description    = Variable Terraform document for VPC deployment
*/

# Global Variables
variable "aws_region" {
  description = "AWS region to deploy the resource to."
  type        = string
  default     = "us-east-1"
}

variable "default_tags" {
  description = "Default tags applied to all resources via the provider default_tags block."
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Deployment environment label (e.g. dev, staging, prod)."
  type        = string
}

variable "project" {
  description = "Project or application name used for resource naming."
  type        = string
}

# VPC Variables
variable "vpc_cidr" {
  description = "Primary IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block (e.g. 10.0.0.0/16)."
  }
}

variable "enable_dns_support" {
  description = "Enable DNS resolution support within the VPC. Required for most AWS services."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Assign public DNS hostnames to instances with public IPs. Required for services like RDS and ECS."
  type        = bool
  default     = true
}

# Subnet Variables
variable "availability_zones" {
  description = "List of availability zones to deploy subnets into. Must have exactly 2 entries."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Exactly 2 availability zones must be specified."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets. Must have the same number of entries as availability_zones."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly 2 public subnet CIDRs must be specified (one per AZ)."

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets. Must have the same number of entries as availability_zones."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Exactly 2 private subnet CIDRs must be specified (one per AZ)."
  }
}

# NAT Gateway Variables
variable "enable_nat_gateway" {
  description = "Deploy a NAT Gateway so private subnets can reach the internet outbound."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = <<-EOT
    Use a single NAT Gateway shared across all private subnets (cost-optimised).
    When false, one NAT Gateway is deployed per AZ (high-availability).
    Recommended: false for production, true for dev/test.
  EOT
  type        = bool
  default     = true
}

  
