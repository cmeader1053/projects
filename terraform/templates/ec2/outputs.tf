/*
Title:       AWS EC2 Instance Outputs
Description: Terraform outputs for EC2 instance template.
*/

# Instance ID
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.server[*].id
}

# Instance Name
output "instance_name" {
  description = "Name tag of the EC2 instance"
  value       = aws_instance.server[*].tags["Name"]
}

# Private IP
output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.server[*].private_ip
}

# Public IP
output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.server[*].public_ip
}

# Availability Zone
output "availability_zone" {
  description = "Availability zone the EC2 instance was launched in"
  value       = aws_instance.server[*].availability_zone
}

# AMI ID
output "ami_id" {
  description = "AMI ID used by the EC2 instance"
  value       = aws_instance.server[*].ami
}
