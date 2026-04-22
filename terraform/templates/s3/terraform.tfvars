/*
Title:       AWS S3 Bucket Deployment Template - Terraform tfvars
Description: Terraform tfvars template for S3 bucket creation.
Directions:  Replace default values with appropriate bucket specific values prior to creation
*/

# AWS Region
aws_region = "us-east-1"

# Bucket Configuration
bucket_name        = ""
force_destroy      = false
versioning_enabled = true

# Bucket Lifecycle Rules (in days)
ia_days         = 30
glacier_days    = 90
expiration_days = 365

# Tags
environment = "DEV"
owner       = ""
project     = ""
