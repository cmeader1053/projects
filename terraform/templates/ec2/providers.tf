/*
Title       = EC2 Terraform Provider
Description = Provider configuration for AWS deployment.
*/

# Terraform Version
terraform {
  required_version = ">= 1.0.0"     

# AWS Version
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"               
    }
  }
}

# AWS Region
provider "aws" {
  region = "us-east-1"
}
