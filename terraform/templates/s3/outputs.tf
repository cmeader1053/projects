/*
Title:       AWS S3 Bucket Deployment Template - Terraform Outputs
Description: Terraform outputs template for S3 bucket creation.
*/

# S3 Bucket Name
output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.main.bucket
}

# S3 Bucket ID
output "bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.main.Id
}

# S3 Bucket ARN
output "bucket_arn" {
  description = "S3 bucket arn"
  value       = aws_s3_bucket.main.arn
}

# S3 Bucket Region
output "bucket_region" {
  description = "S3 bucket AWS Region"
  value       = aws_s3_bucket.main.region
}

# S3 Bucket Versioning Status
output "versioning_status" {
  description = "S3 bucket versioning status"
  value       = aws_s3_bucket.main.versioning_configuration[0].status
}

/*
Blank S3 Outputs Block:

# S3 Bucket Versioning Status
output "" {
  description = ""
  value       = ws_s3_bucket.main.
}
*/
