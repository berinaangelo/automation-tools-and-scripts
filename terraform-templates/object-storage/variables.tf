# --- General ---

variable "cloud_provider" {
  description = "Which provider block in main.tf is active for this run: \"aws\", \"gcp\", or \"azure\". Documentation only — Terraform doesn't gate resources on it here; enable/comment the matching provider + resource blocks in main.tf to match."
  type        = string
  default     = "aws"

  validation {
    condition     = contains(["aws", "gcp", "azure"], var.cloud_provider)
    error_message = "cloud_provider must be one of: aws, gcp, azure."
  }
}

variable "project_name" {
  description = "Short name for the system/project being provisioned. Used as a prefix/tag on created resources."
  type        = string
  default     = "object-storage"
}

variable "environment" {
  description = "Deployment environment, e.g. dev, staging, prod."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Common resource tags/labels applied across providers (AWS tags, GCP labels, Azure tags)."
  type        = map(string)
  default = {
    ManagedBy = "terraform"
  }
}

variable "enable_cdn" {
  description = "Whether to front the bucket/container with a CDN (CloudFront / Cloud CDN / Azure CDN)."
  type        = bool
  default     = false
}

# --- AWS ---

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "aws_bucket_name" {
  description = "Globally-unique S3 bucket name. No default on purpose — S3 bucket names collide across all AWS accounts, so a generic default would fail for most people."
  type        = string
  default     = null
}

variable "aws_enable_versioning" {
  description = "Whether object versioning is enabled on the bucket."
  type        = bool
  default     = true
}

variable "aws_cdn_price_class" {
  description = "CloudFront price class controlling which edge regions serve traffic. \"PriceClass_100\" (US/EU/Canada only) is cheapest; \"PriceClass_All\" covers every edge location."
  type        = string
  default     = "PriceClass_100"
}

# --- GCP ---

variable "gcp_project_id" {
  description = "GCP project ID to deploy into."
  type        = string
  default     = null
}

variable "gcp_region" {
  description = "GCP region to deploy into."
  type        = string
  default     = "us-central1"
}

variable "gcp_bucket_name" {
  description = "Globally-unique GCS bucket name. No default on purpose — bucket names collide across all GCP projects."
  type        = string
  default     = null
}

# --- Azure ---

variable "azure_location" {
  description = "Azure region/location to deploy into."
  type        = string
  default     = "eastus"
}

variable "azure_storage_account_name" {
  description = "Globally-unique Azure storage account name (lowercase alphanumeric, 3-24 chars). No default on purpose — storage account names collide across all Azure tenants."
  type        = string
  default     = null
}

variable "azure_container_name" {
  description = "Name of the blob container created inside the storage account."
  type        = string
  default     = "data"
}
