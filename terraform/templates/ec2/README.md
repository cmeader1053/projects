# EC2 Module

## Description
Reusable Terraform module for deploying EC2 instances on AWS.

## Usage
Update terraform.tfvars with the required values and run:
    terraform init
    terraform plan
    terraform apply

## Files
| File | Description |
|---|---|
| provider.tf | AWS provider and Terraform version config |
| data.tf | AMI lookups for Linux and Windows |
| variables.tf | Input variable definitions |
| main.tf | EC2 resource configuration |
| outputs.tf | Return values after deployment |
| terraform.tfvars | Deployment values - update before each run |

## Required Variables
| Variable | Description |
|---|---|
| name | Name of the EC2 instance |
| instance_type | EC2 instance type |
| subnet_id | Subnet to deploy into |
| sec_grp_id | List of security group IDs |
| os_type | linux or windows |

## Notes
- AMI is selected automatically based on os_type
- Tags are managed via terraform.tfvars
```
