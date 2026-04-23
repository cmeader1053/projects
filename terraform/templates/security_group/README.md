# AWS Security Group Terraform Template

A reusable Terraform template for deploying a security group in AWS. Supports toggleable common ingress rules (SSH, RDP, HTTP, HTTPS, RDS) and fully custom ingress rules via tfvars. Designed to be deployed once and referenced by EC2, RDS, and ALB templates.

---

## File Structure

```
Security_Group/
├── main.tf             # Provider, locals, and security group resource blocks
├── variables.tf        # All variable definitions
├── terraform.tfvars    # Your deployment-specific values (edit this)
└── outputs.tf          # Values returned after deployment
```

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) v1.0 or higher installed
- AWS credentials configured (via environment variables, AWS CLI profile, or Terraform Cloud workspace)
- An existing VPC in your target AWS account

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
cp -r Security_Group/ my-new-sg/
cd my-new-sg/
```

### 2. Edit `terraform.tfvars` with your values

```hcl
# AWS Region
aws_region = "us-east-1"

# Security Group Configuration
sg_name        = "web-server-sg"
sg_description = "Security group for web server access"
vpc_id         = "vpc-xxxxxxxxxxxxxxxxx"

# Common Ingress Rules
allow_ssh   = true
ssh_cidr    = "10.0.0.0/8"
allow_rdp   = false
rdp_cidr    = "10.0.0.0/8"
allow_http  = true
allow_https = true
allow_rds   = false
rds_port    = 3306
rds_cidr    = "10.0.0.0/8"

# Custom Ingress Rules
custom_ingress_rules = []

# Tags
environment = "DEV"
owner       = "your-name"
project     = "your-project"
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan the deployment

```bash
terraform plan
```

### 5. Apply the deployment

```bash
terraform apply
```

To skip the confirmation prompt:
```bash
terraform apply -auto-approve
```

### 6. Review outputs

After a successful apply, Terraform will print the security group details:

```
security_group_id   = "sg-0abc123def456789"
security_group_arn  = "arn:aws:ec2:us-east-1:123456789012:security-group/sg-0abc123def456789"
security_group_name = "myproject-DEV-us-east-1-web-server-sg"
vpc_id              = "vpc-xxxxxxxxxxxxxxxxx"
```

---

## Security Group Naming

The full security group name is automatically constructed from your tfvars values:

```
{project}-{environment}-{aws_region}-{sg_name}
```

For example:

```hcl
project     = "myproject"
environment = "DEV"
aws_region  = "us-east-1"
sg_name     = "web-server-sg"
```

Produces:

```
myproject-DEV-us-east-1-web-server-sg
```

---

## Common Ingress Rules

Each common port is toggled on or off via a bool variable. If set to `false` the rule is not created at all.

| Variable | Port | Protocol | Description |
|---|---|---|---|
| `allow_ssh` | 22 | TCP | Linux instance access |
| `allow_rdp` | 3389 | TCP | Windows instance access |
| `allow_http` | 80 | TCP | HTTP web traffic |
| `allow_https` | 443 | TCP | HTTPS web traffic |
| `allow_rds` | `rds_port` | TCP | Database access (MySQL/PostgreSQL) |

> **Important:** Always restrict `ssh_cidr` and `rdp_cidr` to your office IP, VPN CIDR, or internal subnet range. Never leave these as `0.0.0.0/0` in a real deployment — open SSH and RDP to the world is one of the most common attack vectors in AWS.

---

## Custom Ingress Rules

For ports not covered by the common toggles, pass a list of custom rules via tfvars:

```hcl
custom_ingress_rules = [
  {
    description = "Allow app port"
    from_port   = 8080
    to_port     = 8080
    ip_protocol = "tcp"
    cidr_ipv4   = "10.0.0.0/8"
  },
  {
    description = "Allow monitoring"
    from_port   = 9100
    to_port     = 9100
    ip_protocol = "tcp"
    cidr_ipv4   = "10.0.0.0/8"
  }
]
```

Each rule requires all five fields. Leave `custom_ingress_rules = []` if no custom rules are needed.

---

## Egress

All outbound traffic is allowed by default. This is standard AWS practice — egress restrictions add significant complexity with minimal security benefit for most workloads.

---

## RDS Port Reference

When enabling `allow_rds`, set `rds_port` to match your database engine:

| Engine | Port |
|---|---|
| MySQL / MariaDB | 3306 |
| PostgreSQL | 5432 |
| MSSQL | 1433 |
| Oracle | 1521 |

---

## Using the Output in Other Templates

After deploying this template, copy the `security_group_id` output into the EC2, RDS, or ALB `terraform.tfvars`:

```hcl
# EC2 terraform.tfvars
sec_grp_ids = ["sg-0abc123def456789"]

# RDS terraform.tfvars
vpc_security_group_ids = ["sg-0abc123def456789"]
```

---

## Destroying Resources

```bash
terraform destroy
```

> **Note:** A security group cannot be destroyed while it is still attached to an active resource. Destroy or detach any EC2 instances, RDS databases, or ALBs using this security group first.

---

## Variable Reference

| Variable | Type | Default | Required | Description |
|---|---|---|---|---|
| `aws_region` | string | — | Yes | AWS region to deploy into |
| `sg_name` | string | — | Yes | Security group name suffix |
| `sg_description` | string | — | Yes | Description of the security group |
| `vpc_id` | string | — | Yes | VPC ID to create the security group in |
| `allow_ssh` | bool | `false` | No | Enable SSH ingress rule (port 22) |
| `ssh_cidr` | string | `0.0.0.0/0` | No | CIDR allowed for SSH. Restrict in production. |
| `allow_rdp` | bool | `false` | No | Enable RDP ingress rule (port 3389) |
| `rdp_cidr` | string | `0.0.0.0/0` | No | CIDR allowed for RDP. Restrict in production. |
| `allow_http` | bool | `false` | No | Enable HTTP ingress rule (port 80) |
| `allow_https` | bool | `false` | No | Enable HTTPS ingress rule (port 443) |
| `allow_rds` | bool | `false` | No | Enable RDS ingress rule |
| `rds_port` | number | `3306` | No | Database port for RDS rule |
| `rds_cidr` | string | `10.0.0.0/8` | No | CIDR allowed for RDS access |
| `custom_ingress_rules` | list(object) | `[]` | No | List of custom ingress rules |
| `environment` | string | — | Yes | Environment label (DEV, UAT, PROD) |
| `owner` | string | — | Yes | Owner or point of contact for the resource |
| `project` | string | — | Yes | Project the resource belongs to |
