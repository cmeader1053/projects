/*
Title:       AWS S3 Bucket Deployment Template - Terraform Variables 
Description: Terraform variables for S3 bucket template.
*/

# AWS Region
variable "aws_region" {
  description = "AWS region where resources are launched"
  type        = string

}

# S3 Bucket Configuration Variables
variable "bucket_name" {
  description = "Name of the S3 bucket. Combined with project, environment, and region to form the full bucket name."
  type        = string
}

variable "force_destroy" {
  description = "If true, allows bucket to be destroyed even if it contains objects. Use with caution."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable versioning on the S3 bucket. Recommended true for backups."
  type        = bool
  default     = true
}

# Lifecycle Rules Variables
variable "ia_days" {
  description = "Number of days before objects transition to Standard-IA storage class."
  type        = number
  default     = 30
}

variable "glacier_days" {
  description = "Number of days before objects transition to Glacier storage class."
  type        = number
  default     = 90
}

variable "expiration_days" {
  description = "Number of days before objects are permanently deleted. Set 0 to disable expiration."
  type        = number
  default     = 365
}

# Tag Variables
variable "environment" {
  description = "Environment where resource is launched"
  type        = string
}

variable "owner" {
  description = "Owner or POC for resource"
  type        = string
}

variable "project" {
  description = "Project resource is created for"
  type        = string
}
