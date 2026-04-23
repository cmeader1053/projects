# Terraform

This directory is where I'm building out a library of reusable Terraform templates for AWS infrastructure. The goal is to have a go-to reference for standing up common resources consistently — same structure, same naming conventions, same tagging — every time.

Rather than starting from scratch on every deployment, I can pull from these templates, update the `terraform.tfvars` with the specifics, and have something production-ready without reinventing the wheel.

---

## Structure

```
terraform/
└── Templates/
    ├── EC2/
    ├── S3/
    ├── Security_Group/
    ├── VPC/
    ├── IAM_Role/
    ├── RDS/
    ├── ALB/
    └── CloudWatch/
```

---

## Templates

### Completed

#### EC2
Reusable template for deploying one or more EC2 instances on AWS. Supports Ubuntu 24.04 LTS and Windows Server 2022 with automatic AMI resolution based on `os_type`, or a custom AMI ID if preferred. Includes IMDSv2 enforcement and encrypted EBS volumes. See the [EC2 README](Templates/EC2/README.md) for full details.

#### S3
Reusable template for deploying a production-ready S3 bucket. Designed for general storage and backup use cases with encryption, versioning, public access blocking, and lifecycle management built in. See the [S3 README](Templates/S3/README.md) for full details.

#### Security Group
Reusable template for deploying a security group with toggleable common ingress rules (SSH, RDP, HTTP, HTTPS, RDS) and support for fully custom ingress rules via tfvars. See the [Security Group README](Templates/Security_Group/README.md) for full details.

---

### Planned

#### VPC
Template for deploying a VPC with subnets, route tables, internet gateway, and NAT gateway. Foundation for all other resources.

#### IAM Role
Template for deploying a reusable IAM role with policy attachments. Used to generate instance profiles for EC2 and other services.

#### RDS
Template for deploying an RDS instance (MySQL or PostgreSQL) with subnet groups, parameter groups, and encryption enabled.

#### ALB
Template for deploying an Application Load Balancer with target groups, listeners, and rules.

#### CloudWatch
Template for deploying CloudWatch alarms and SNS topics for infrastructure monitoring and alerting.

---

## How to Use a Template

1. Copy the template folder to your working directory
2. Open `terraform.tfvars` and fill in the values for your deployment
3. Run the standard Terraform workflow:

```bash
terraform init
terraform validate
terraform fmt
terraform plan
terraform apply
```

Each template is self-contained — provider config, variables, resources, and outputs are all included in a single directory.

---

## Terraform Command Reference

A quick reference for the commands you'll use regularly when working with these templates. Run these from inside the template directory.

### Core Workflow

```bash
# Initialize the working directory — downloads providers, sets up backend
# Run this first, and again any time you change provider versions
terraform init

# Validate the configuration for syntax and internal consistency
# Doesn't connect to AWS — purely a local config check
terraform validate

# Format all .tf files to HCL standard style
# Good habit before committing anything
terraform fmt

# Preview what Terraform will create, change, or destroy
# Always run this before apply — no changes are made
terraform plan

# Apply the changes from the last plan
# Prompts for confirmation unless you pass -auto-approve (avoid in prod)
terraform apply

# Destroy all resources managed by this configuration
# Double-check your workspace and state before running this
terraform destroy
```

### Targeted Operations

```bash
# Plan or apply changes to a specific resource only
terraform plan -target="aws_instance.main"
terraform apply -target="aws_instance.main"

# Pass a variable value at runtime instead of through tfvars
terraform plan -var="instance_type=t3.small"

# Use a specific tfvars file (useful if you maintain multiple environments)
terraform plan -var-file="prod.tfvars"
```

### State Management

```bash
# List all resources currently tracked in state
terraform state list

# Show the full details of a specific resource in state
terraform state show aws_instance.main

# Import an existing AWS resource into Terraform state
# Format: terraform import <resource_type>.<local_name> <aws_resource_id>
terraform import aws_instance.main i-0abc123def456

# Remove a resource from state without destroying it in AWS
terraform state rm aws_instance.main

# Pull the current remote state and display it locally
terraform state pull
```

### Inspection & Debugging

```bash
# Show all outputs after a successful apply
terraform output

# Show the value of a specific output
terraform output instance_id

# Show the full planned or current state in a readable format
terraform show

# Refresh state to match real AWS infrastructure (no changes applied)
terraform refresh

# View the dependency graph — pipe to a tool like Graphviz to visualize
terraform graph
```

### Workspace Commands (Terraform Cloud)

```bash
# List available workspaces
terraform workspace list

# Show the currently selected workspace
terraform workspace show

# Switch to a different workspace
terraform workspace select <workspace-name>
```

---

## Conventions

These templates follow a consistent file structure across all resources:

| File | Purpose |
|---|---|
| `main.tf` | Provider config, locals, and all resource blocks |
| `variables.tf` | Input variable definitions |
| `outputs.tf` | Values returned after apply |
| `terraform.tfvars` | Deployment-specific values — update this before each run |

### Naming Convention

All resources follow a consistent naming pattern using a `name_prefix` local built from your tfvars values:

```
{project}-{environment}-{aws_region}-{resource_name}
```

For example:
```
myproject-DEV-us-east-1-web-server
myproject-DEV-us-east-1-backups
myproject-DEV-us-east-1-web-server-sg
```

### Tagging

Tags are passed through `terraform.tfvars` and applied consistently across all resources via a `common_tags` local. Every resource gets at minimum:

| Tag | Source |
|---|---|
| `Name` | Built from `name_prefix` + resource-specific name |
| `Environment` | `var.environment` |
| `Owner` | `var.owner` |
| `Project` | `var.project` |

---

## Notes

- These are templates, not modules — they are meant to be copied and used directly, not called as a source reference
- `terraform.tfvars` is included in every template but must be reviewed and updated before every deployment
- All sensitive values such as subnet IDs, VPC IDs, and security group IDs should be verified in AWS before running `terraform plan`
