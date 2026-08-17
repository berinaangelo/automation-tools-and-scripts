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
  default     = "iam"
}

variable "environment" {
  description = "Deployment environment, e.g. dev, staging, prod."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Common resource tags/labels applied across providers (AWS tags, GCP labels, Azure tags). GCP/Azure IAM resources here mostly ignore this — kept for parity with the other templates."
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

variable "aws_iam_role_name" {
  description = "Name for the IAM role + instance profile. Leave null to fall back to \"<project_name>-<environment>\"."
  type        = string
  default     = null
}

variable "aws_iam_trusted_service" {
  description = "AWS service principal allowed to assume this role, e.g. \"ec2.amazonaws.com\", \"ecs-tasks.amazonaws.com\", \"lambda.amazonaws.com\". User-defined rather than fixed to EC2 — pick whatever compute service this role is actually for."
  type        = string
  default     = "ec2.amazonaws.com"
}

variable "aws_iam_managed_policy_arns" {
  description = "AWS managed (or existing customer-managed) policy ARNs to attach to the role, e.g. [\"arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore\"]. Empty by default — an unattached role has no permissions beyond assuming itself."
  type        = list(string)
  default     = []
}

variable "aws_iam_inline_policy_json" {
  description = "Optional inline policy document (JSON string, e.g. via jsonencode({...}) or data.aws_iam_policy_document.this.json) for permissions specific to this role. Leave null to skip creating an inline policy — attach managed policies instead where possible."
  type        = string
  default     = null
}

# --- GCP ---

variable "gcp_project_id" {
  description = "GCP project ID to deploy into."
  type        = string
  default     = null
}

variable "gcp_service_account_id" {
  description = "Service account ID (the part before @project.iam.gserviceaccount.com). Leave null to fall back to \"<project_name>-<environment>\"."
  type        = string
  default     = null
}

variable "gcp_iam_roles" {
  description = "Project-level IAM roles granted to the service account, e.g. [\"roles/storage.objectViewer\"]. Empty by default."
  type        = list(string)
  default     = []
}

# --- Azure ---

variable "azure_location" {
  description = "Azure region/location to deploy into."
  type        = string
  default     = "eastus"
}

variable "azure_identity_name" {
  description = "Name for the user-assigned managed identity. Leave null to fall back to \"<project_name>-<environment>\"."
  type        = string
  default     = null
}

variable "azure_role_assignments" {
  description = "Map of role assignment name => { role_definition_name, scope } granted to the managed identity. Empty by default."
  type = map(object({
    role_definition_name = string
    scope                 = string
  }))
  default = {}
}
