# Terraform

This directory is where I'm building out a library of reusable Terraform templates for AWS infrastructure. The goal is to have a go-to reference for standing up common resources consistently — same structure, same naming conventions, same tagging — every time.

Rather than starting from scratch on every deployment, I can pull from these templates, update the `terraform.tfvars` with the specifics, and have something production-ready without reinventing the wheel.

---

## Structure

```
terraform/
└── Templates/
    └── EC2/
```

More templates will be added over time as I build them out (ALB, S3, Security Groups, etc.).

---

## Templates

### EC2
Reusable template for deploying EC2 instances on AWS. Supports both Linux and Windows — AMI selection is handled automatically based on `os_type`. See the [EC2 README](Templates/EC2/README.md) for full details on variables, usage, and file breakdown.

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

Each template is self-contained — provider config, variables, data sources, and outputs are all included.

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
terraform plan -target="aws_instance.this"
terraform apply -target="aws_instance.this"

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
terraform state show aws_instance.this

# Import an existing AWS resource into Terraform state
# Format: terraform import <resource_type>.<local_name> <aws_resource_id>
terraform import aws_instance.this i-0abc123def456

# Remove a resource from state without destroying it in AWS
terraform state rm aws_instance.this

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
| `provider.tf` | AWS provider and Terraform version requirements |
| `data.tf` | Data source lookups (AMIs, existing resources, etc.) |
| `variables.tf` | Input variable definitions |
| `main.tf` | Resource configuration |
| `outputs.tf` | Values returned after apply |
| `terraform.tfvars` | Deployment-specific values — update this before each run |

Tags are passed in through `terraform.tfvars` and merged with resource-level tags in `main.tf`. Every resource gets at minimum a `Name`, `Environment`, `ManagedBy`, and `Owner` tag.

---

## Notes

- These are templates, not modules — they're meant to be copied and used directly, not called as a source reference
- `terraform.tfvars` is included but should be reviewed and updated before every deployment
