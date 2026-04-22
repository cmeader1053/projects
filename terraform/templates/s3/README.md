# AWS S3 Bucket Terraform Template

A reusable Terraform template for deploying a production-ready S3 bucket in AWS. Designed for general storage and backup use cases with encryption, versioning, public access blocking, and lifecycle management built in.

---

## File Structure

```
s3_template/
├── main.tf             # Provider, locals, and S3 resource blocks
├── variables.tf        # All variable definitions
├── terraform.tfvars    # Your deployment-specific values (edit this)
└── outputs.tf          # Values returned after deployment
```

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) v1.0 or higher installed
- AWS credentials configured (via environment variables, AWS CLI profile, or Terraform Cloud workspace)

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
cp -r s3_template/ my-new-bucket/
cd my-new-bucket/
```

### 2. Edit `terraform.tfvars` with your values

```hcl
# AWS Region
aws_region = "us-east-1"

# Bucket Configuration
bucket_name        = "backups"
force_destroy      = false
versioning_enabled = true

# Lifecycle Rules (days)
ia_days         = 30
glacier_days    = 90
expiration_days = 365

# Tags
environment = "DEV"
owner       = "your-name"
project     = "your-project"
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

Deploys the S3 bucket to AWS. You will be prompted to confirm before anything is created.

```bash
terraform apply
```

To skip the confirmation prompt:
```bash
terraform apply -auto-approve
```

### 6. Review outputs

After a successful apply, Terraform will print the bucket details:

```
bucket_name       = "myproject-DEV-us-east-1-backups"
bucket_id         = "myproject-DEV-us-east-1-backups"
bucket_arn        = "arn:aws:s3:::myproject-DEV-us-east-1-backups"
bucket_region     = "us-east-1"
versioning_status = "Enabled"
```

---

## Bucket Naming

This template automatically constructs the full bucket name from your tfvars values using a naming convention:

```
{project}-{environment}-{aws_region}-{bucket_name}
```

For example with these tfvars values:

```hcl
project     = "myproject"
environment = "DEV"
aws_region  = "us-east-1"
bucket_name = "backups"
```

The resulting bucket name in AWS will be:

```
myproject-DEV-us-east-1-backups
```

> **Important:** S3 bucket names must be globally unique across all AWS accounts worldwide — not just your own. If a bucket with the same name already exists anywhere in AWS, the deployment will fail. Keep `bucket_name` short and specific to avoid conflicts.

---

## Security Features

The following security controls are enabled by default and cannot be disabled via variables:

| Feature | Details |
|---|---|
| Public access block | All four public access block settings are enabled. No public access is possible regardless of object ACLs or bucket policies. |
| Server side encryption | AES256 (SSE-S3) encryption is applied to all objects at rest automatically. |
| Bucket key | Enabled to reduce encryption-related API call costs. |

---

## Versioning

Versioning is controlled by the `versioning_enabled` variable:

```hcl
versioning_enabled = true    # Keeps previous versions on overwrite or delete
versioning_enabled = false   # Suspends versioning (existing versions retained)
```

Versioning is strongly recommended for backup buckets. It allows recovery from accidental deletion or object corruption by restoring a previous version.

> **Note:** Once versioning has been enabled on a bucket it can be suspended but never fully disabled. Existing object versions are always retained.

---

## Lifecycle Rules

Objects are automatically moved through storage tiers to reduce cost over time. All thresholds are configurable in tfvars:

```
Upload → Standard (ia_days) → Standard-IA (glacier_days) → Glacier (expiration_days) → Deleted
```

| Variable | Default | Description |
|---|---|---|
| `ia_days` | `30` | Days before transition to Standard-IA |
| `glacier_days` | `90` | Days before transition to Glacier |
| `expiration_days` | `365` | Days before permanent deletion |

> **Important:** Values must follow this order — `ia_days` < `glacier_days` < `expiration_days`. Terraform will throw a validation error at plan time if they are out of order.

---

## Force Destroy

By default `force_destroy = false`, meaning Terraform will refuse to delete a bucket that contains objects:

```hcl
force_destroy = false   # Safe — Terraform will error if bucket has objects (default)
force_destroy = true    # Dangerous — Terraform will delete bucket and all contents
```

Only set `force_destroy = true` on dev or test buckets you are comfortable deleting entirely. Never use it on buckets containing production data or backups you need to retain.

---

## Destroying Resources

To tear down the bucket created by this template:

```bash
terraform destroy
```

To skip the confirmation prompt:
```bash
terraform destroy -auto-approve
```

> **Warning:** If `force_destroy = false` (the default) and the bucket contains objects, the destroy will fail. This is intentional to prevent accidental data loss. Either empty the bucket manually first or set `force_destroy = true` before destroying.

---

## Variable Reference

| Variable | Type | Default | Required | Description |
|---|---|---|---|---|
| `aws_region` | string | — | Yes | AWS region to deploy into |
| `bucket_name` | string | — | Yes | Bucket name suffix. Combined with project, environment, and region. |
| `force_destroy` | bool | `false` | No | Allow bucket destruction even if it contains objects |
| `versioning_enabled` | bool | `true` | No | Enable object versioning on the bucket |
| `ia_days` | number | `30` | No | Days before transition to Standard-IA storage class |
| `glacier_days` | number | `90` | No | Days before transition to Glacier storage class |
| `expiration_days` | number | `365` | No | Days before objects are permanently deleted |
| `environment` | string | — | Yes | Environment label (DEV, UAT, PROD) |
| `owner` | string | — | Yes | Owner or point of contact for the resource |
| `project` | string | — | Yes | Project the resource belongs to |
