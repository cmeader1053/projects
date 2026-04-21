# AWS EC2 Instance Terraform Template

A reusable Terraform template for deploying one or more EC2 instances in AWS. Supports Ubuntu 24.04 LTS and Windows Server 2022 with automatic AMI resolution, or a custom AMI ID if preferred.

---

## File Structure

```
ec2_template/
├── main.tf             # Provider, data sources, and EC2 resource block
├── variables.tf        # All variable definitions
├── terraform.tfvars    # Your deployment-specific values (edit this)
└── outputs.tf          # Values returned after deployment
```

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) v1.0 or higher installed
- AWS credentials configured (via environment variables, AWS CLI profile, or Terraform Cloud workspace)
- An existing VPC, subnet, and security group in your target AWS account

### Verify Terraform is installed
```bash
terraform version
```

### Verify AWS credentials are working
```bash
aws sts get-caller-identity
```

---

## Quick Start

### 1. Clone or copy the template folder

```bash
cp -r ec2_template/ my-new-server/
cd my-new-server/
```

### 2. Edit `terraform.tfvars` with your values

Open `terraform.tfvars` and fill in the required fields:

```hcl
# Environment
environment = "DEV"

# AWS Region
aws_region = "us-east-1"

# Instance Configuration
instance_name  = "my-server"
instance_count = 1
instance_type  = "t3.medium"
root_vol_type  = "gp3"
root_vol_size  = 30
ami_id         = null        # Leave null to use os_type auto-resolution
os_type        = "linux"     # "linux" or "windows"

# Networking
subnet_id   = "subnet-xxxxxxxxxxxxxxxxx"
sec_grp_ids = ["sg-xxxxxxxxxxxxxxxxx"]

# Access
key_name    = null           # SSH key pair name, or null if using SSM
iam_profile = null           # IAM instance profile name, or null if not needed

# Tags
owner   = "your-name"
project = "your-project"
```

### 3. Initialize Terraform

Downloads the AWS provider and sets up the working directory. Run this once per new copy of the template.

```bash
terraform init
```

### 4. Plan the deployment

Previews exactly what Terraform will create before anything is deployed. Always review this before applying.

```bash
terraform plan
```

### 5. Apply the deployment

Deploys the EC2 instance(s) to AWS. You will be prompted to confirm before anything is created.

```bash
terraform apply
```

To skip the confirmation prompt:
```bash
terraform apply -auto-approve
```

### 6. Review outputs

After a successful apply, Terraform will print the instance details:

```
instance_id       = ["i-0abc123def456789"]
instance_name     = ["my-server-1"]
private_ip        = ["10.0.1.50"]
public_ip         = [""]
availability_zone = ["us-east-1a"]
ami_id            = ["ami-009d9173b44d0482b"]
```

---

## OS Selection

This template supports automatic AMI resolution. Set `os_type` in your tfvars and leave `ami_id = null`:

| os_type     | AMI Resolved                          |
|-------------|---------------------------------------|
| `"linux"`   | Latest Ubuntu 24.04 LTS (Canonical)   |
| `"windows"` | Latest Windows Server 2022 (AWS)      |

To use a specific AMI instead, set `ami_id` directly and `os_type` will be ignored:

```hcl
ami_id  = "ami-0abcdef1234567890"
os_type = null
```

---

## Deploying Multiple Instances

Set `instance_count` to the number of instances needed. Each instance will be named sequentially:

```hcl
instance_count = 3
instance_name  = "web-server"
```

This produces: `web-server-1`, `web-server-2`, `web-server-3`

To scale back down, reduce `instance_count` and run `terraform apply` again.

---

## Windows-Specific Notes

When deploying a Windows instance, set `get_password_data = true` in your tfvars to allow Terraform to retrieve the encrypted Administrator password after launch:

```hcl
os_type           = "windows"
get_password_data = true
key_name          = "your-key-pair"   # Required to decrypt the password
```

Retrieve the password after apply:
```bash
aws ec2 get-password-data \
  --instance-id i-xxxxxxxxxxxxxxxxx \
  --priv-launch-key your-key.pem \
  --region us-east-1
```

---

## Destroying Resources

To tear down everything created by this template:

```bash
terraform destroy
```

To skip the confirmation prompt:
```bash
terraform destroy -auto-approve
```

> **Warning:** This permanently deletes all instances and their root volumes. Ensure any data is backed up before destroying.

---

## Variable Reference

| Variable         | Type         | Default      | Required | Description                                              |
|------------------|--------------|--------------|----------|----------------------------------------------------------|
| `aws_region`     | string       | —            | Yes      | AWS region to deploy into                                |
| `environment`    | string       | —            | Yes      | Environment label (DEV, UAT, PROD)                       |
| `instance_name`  | string       | —            | Yes      | Base name for the instance(s)                            |
| `instance_count` | number       | `1`          | No       | Number of instances to create                            |
| `instance_type`  | string       | `t2.micro`   | No       | EC2 instance type                                        |
| `ami_id`         | string       | `null`       | No       | Specific AMI ID. If null, os_type is used                |
| `os_type`        | string       | `linux`      | No       | OS for AMI resolution. Accepted: `linux`, `windows`      |
| `subnet_id`      | string       | —            | Yes      | Subnet ID to launch the instance into                    |
| `sec_grp_ids`    | list(string) | —            | Yes      | List of security group IDs to attach                     |
| `key_name`       | string       | `null`       | No       | EC2 key pair name for SSH/RDP access                     |
| `iam_profile`    | string       | `null`       | No       | IAM instance profile to attach                           |
| `root_vol_type`  | string       | —            | Yes      | EBS volume type (recommended: `gp3`)                     |
| `root_vol_size`  | number       | `20`         | No       | Root volume size in GB                                   |
| `owner`          | string       | —            | Yes      | Owner or point of contact for the resource               |
| `project`        | string       | —            | Yes      | Project the resource belongs to                          |
| `user_data`      | string       | `null`       | No       | Startup script (bash for Linux, PowerShell for Windows)  |
| `get_password_data` | bool      | `false`      | No       | Set true to retrieve Windows Administrator password      |

---

## Security Notes

- **EBS encryption is enabled** — root volumes are encrypted at rest by default and cannot be disabled via variables.
- **Ubuntu AMIs are sourced from Canonical's official AWS account** (`099720109477`) to prevent use of unverified community images.
- **Windows AMIs are sourced directly from AWS** (`amazon`) ensuring only official Microsoft-licensed images are used.
