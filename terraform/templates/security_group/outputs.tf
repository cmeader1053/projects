/*
Title:       AWS Security Group Deployment - Terraform Outputs
Description: Terraform outputs for security group creation
*/

# Security Group ID
output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.main.id
}

# Security Group ARN
output "security_group_arn" {
  description = "ARN of the security group"
  value       = aws_security_group.main.arn
}

# Security Group Name
output "security_group_name" {
  description = "Name of the security group"
  value       = aws_security_group.main.name
}

# VPC ID
output "vpc_id" {
  description = "VPC the security group was created in"
  value       = aws_security_group.main.vpc_id
}
