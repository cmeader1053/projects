/*
Title       = EC2 Terraform Outputs
Description = Output values returned after EC2 instance creation.
*/

# Instance ID
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

# Instance Name
output "instance_name" {
  description = "Name of the EC2 instance"
  value       = var.name
}

# Private IP
output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.this.private_ip
}

# Public IP
output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.this.public_ip
}

# Subnet ID
output "subnet_id" {
  description = "Subnet ID the instance was deployed in"
  value       = aws_instance.this.subnet_id
}

# AMI ID
output "ami_id" {
  description = "AMI ID used for the instance"
  value       = aws_instance.this.ami
}

# Instance ARN
output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.this.arn
}
