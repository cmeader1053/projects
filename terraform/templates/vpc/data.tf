/*
Title        = VPC Data Terraform
Description  = Data file to pull available AZ's in region to verify AZ specified exist
*/

data "aws_availability_zones" "available" {
  state = "available"
}
