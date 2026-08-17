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
  default     = "secrets-manager"
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

variable "secret_description" {
  description = "Human-readable description of what this secret is for."
  type        = string
  default     = null
}

# --- AWS ---

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "aws_secret_name" {
  description = "Name for the secret. Leave null to fall back to \"<project_name>-<environment>\"."
  type        = string
  default     = null
}

variable "aws_secret_value" {
  description = "Secret value/payload. No default on purpose — provide via terraform.tfvars (gitignored) or a TF_VAR_aws_secret_value environment variable, never hardcode. For structured secrets (multiple key/value pairs), pass a jsonencode({...}) string, e.g. jsonencode({ username = \"app\", password = \"...\" })."
  type        = string
  sensitive   = true
  default     = null
}

variable "aws_recovery_window_in_days" {
  description = "Days AWS retains a deleted secret before permanently purging it (allows recovery from an accidental delete). 0 deletes immediately — convenient for throwaway dev secrets, risky for anything else."
  type        = number
  default     = 7
}

# --- GCP ---

variable "gcp_project_id" {
  description = "GCP project ID to deploy into."
  type        = string
  default     = null
}

variable "gcp_secret_id" {
  description = "Secret ID. Leave null to fall back to \"<project_name>-<environment>\"."
  type        = string
  default     = null
}

variable "gcp_secret_value" {
  description = "Secret value/payload. No default on purpose — provide via terraform.tfvars (gitignored) or a TF_VAR_gcp_secret_value environment variable."
  type        = string
  sensitive   = true
  default     = null
}

# --- Azure ---
#
# Azure Key Vault is a container resource — unlike AWS/GCP's flat secret
# namespace, a vault has to exist before secrets can be created in it.

variable "azure_location" {
  description = "Azure region/location to deploy into."
  type        = string
  default     = "eastus"
}

variable "azure_key_vault_name" {
  description = "Globally-unique Key Vault name (3-24 chars). No default on purpose — vault names collide across all Azure tenants."
  type        = string
  default     = null
}

variable "azure_tenant_id" {
  description = "Azure AD tenant ID the Key Vault belongs to. Required — no default since it's tenant-specific."
  type        = string
  default     = null
}

variable "azure_secret_name" {
  description = "Name of the secret inside the Key Vault. Leave null to fall back to \"<project_name>-<environment>\"."
  type        = string
  default     = null
}

variable "azure_secret_value" {
  description = "Secret value/payload. No default on purpose — provide via terraform.tfvars (gitignored) or a TF_VAR_azure_secret_value environment variable."
  type        = string
  sensitive   = true
  default     = null
}
