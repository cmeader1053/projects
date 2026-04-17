/*
Title    = VPC Outputs
Description  = Outputs terraform file for VPC creation in AWS
*/

# VPC ID
output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

# VPC ARN
output "vpc_arn" {
  description = "ARN of the VPC."
  value       = aws_vpc.this.arn
}

# VPC CIDR
output "vpc_cidr" {
  description = "Primary CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

# Internet Gateway
output "internet_gateway_id" {
  description = "ID of the internet gateway."
  value       = aws_internet_gateway.this.id
}

# Public Subnet ID, CIDR & Route Table ID
  output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks."
  value       = aws_subnet.public[*].cidr_block
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}

# Private Subnet ID, CIDR & Route Table ID
output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks."
  value       = aws_subnet.private[*].cidr_block
}

output "private_route_table_ids" {
  description = "List of private route table IDs (one per subnet)."
  value       = aws_route_table.private[*].id
}

# NAT Gateway ID and Public IP's
output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs. Empty if enable_nat_gateway = false."
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public Elastic IP addresses assigned to NAT Gateways."
  value       = aws_eip.nat[*].public_ip
}
