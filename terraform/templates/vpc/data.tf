/*
Title        = VPC Data Terraform
Description  = Data file to pull available AZ's in region to verify AZ specified exist
*/

# Get Current AWS Region
data "aws_region" "current" {}

# Check for available AZ's in current AWS Region
data "aws_availability_zones" "available" {
  state = "available"
}
