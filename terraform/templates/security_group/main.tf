/*
Title:       AWS Security Group Deployment - Terraform Main
Description: Terraform template for Security Group creation.
*/

# Required Providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider
provider "aws" {
  region = var.aws_region
}

# Locals
locals {
  name_prefix = "${var.project}-${var.environment}-${var.aws_region}"

  common_tags = {
    Environment = var.environment
    Owner       = var.owner
    Project     = var.project
  }
}

# Security Group Configuration
resource "aws_security_group" "main" {
  name        = "${local.name_prefix}-${var.sec_grp_name}"
  description = var.sec_grp_description
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${var.sec_grp_name}"
  })
}

# Ingress Rules - Comment/Uncomment which block based on OS (Linux/Windows)

# SSH Ingress Rule (Linux)
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  count             = var.allow_ssh ? 1 : 0
  security_group_id = aws_security_group.main.id
  description       = "Allow SSH"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.ssh_cidr
}

/*
# RDP Ingress Rule (Windows)
resource "aws_vpc_security_group_ingress_rule" "rdp" {
  count             = var.allow_rdp ? 1 : 0
  security_group_id = aws_security_group.main.id
  description       = "Allow RDP"
  from_port         = 3389
  to_port           = 3389
  ip_protocol       = "tcp"
  cidr_ipv4         = var.rdp_cidr
}
*/

# HTTP/HTTPS
resource "aws_vpc_security_group_ingress_rule" "http" {
  count             = var.allow_http ? 1 : 0
  security_group_id = aws_security_group.main.id
  description       = "Allow HTTP"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  count             = var.allow_https ? 1 : 0
  security_group_id = aws_security_group.main.id
  description       = "Allow HTTPS"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

/*
Blank Ingress Rule Block for future use

resource "aws_vpc_security_group_ingress_rule" "custom" {
  security_group_id = aws_security_group.main.id
  description       = description
  from_port         = from_port
  to_port           = to_port
  ip_protocol       = ip_protocol
  cidr_ipv4         = cidr_ipv4
}
*/

# Egress Rules
resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.main.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
