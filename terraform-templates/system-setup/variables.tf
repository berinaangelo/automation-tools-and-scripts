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
  default     = "system-setup"
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

# --- AWS ---

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "aws_instance_type" {
  description = "EC2 instance type for the example compute resource."
  type        = string
  default     = "t3.micro"
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

variable "gcp_zone" {
  description = "GCP zone for zonal resources."
  type        = string
  default     = "us-central1-a"
}

variable "gcp_machine_type" {
  description = "GCE machine type for the example compute resource."
  type        = string
  default     = "e2-micro"
}

# --- Azure ---

variable "azure_location" {
  description = "Azure region/location to deploy into."
  type        = string
  default     = "eastus"
}

variable "azure_vm_size" {
  description = "Azure VM size for the example compute resource."
  type        = string
  default     = "Standard_B1s"
}
