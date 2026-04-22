/*
Title:       AWS S3 Bucket Deployment Template - Terraform Main 
Description: Terraform template for S3 bucket creation.
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

provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix = "${var.project}-${var.environment}-${var.aws_region}"
  common_tags = {
    Environment = var.environment
    Owner       = var.owner
    Project     = var.project
  }
}

# S3 Bucket Config
resource "aws_s3_bucket" "main" {
  bucket        = "${local.name_prefix}-${var.bucket_name}"
  force_destroy = var.force_destroy

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${var.bucket_name}"
  })
}

# Block Public Access to S3 Bucket 
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# S3 Server Side Encryption Enabled
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Enable S3 Bucket Lifecycle Rules
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "transition-and-expiration"
    status = "Enabled"

    transition {
      days          = var.ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.expiration_days
    }
  }
}
