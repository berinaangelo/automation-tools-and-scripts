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
  default     = "load-balancer"
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

variable "aws_lb_type" {
  description = "\"application\" (ALB, L7/HTTP) or \"network\" (NLB, L4/TCP)."
  type        = string
  default     = "application"

  validation {
    condition     = contains(["application", "network"], var.aws_lb_type)
    error_message = "aws_lb_type must be one of: application, network."
  }
}

variable "aws_lb_internal" {
  description = "Whether the load balancer only gets a private (VPC-internal) address instead of a public one."
  type        = bool
  default     = false
}

variable "aws_vpc_id" {
  description = "VPC ID the target group belongs to. Required — comes from the networking template's vpc_id output."
  type        = string
  default     = null
}

variable "aws_subnet_ids" {
  description = "Subnet IDs the load balancer is placed in — public subnets for an internet-facing LB. Required — comes from the networking template's public_subnet_ids output."
  type        = list(string)
  default     = []
}

variable "aws_security_group_ids" {
  description = "Security group IDs attached to the load balancer. Only used when aws_lb_type = \"application\" (ALBs are the only LB type that supports SGs directly). Comes from the networking template's web_security_group_id output."
  type        = list(string)
  default     = []
}

variable "aws_target_port" {
  description = "Port the backend targets (instances/ASG) listen on."
  type        = number
  default     = 80
}

variable "aws_target_protocol" {
  description = "Protocol used between the load balancer and its targets, e.g. \"HTTP\" for an ALB or \"TCP\" for an NLB."
  type        = string
  default     = "HTTP"
}

variable "aws_health_check_path" {
  description = "HTTP path used for target health checks. Only applies to ALBs (aws_lb_type = \"application\")."
  type        = string
  default     = "/"
}

variable "aws_enable_https" {
  description = "Whether to add an HTTPS listener (443) and redirect HTTP (80) to it. Requires aws_certificate_arn."
  type        = bool
  default     = false
}

variable "aws_certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener. Required when aws_enable_https = true — no default since it's account/domain-specific."
  type        = string
  default     = null
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

variable "gcp_health_check_path" {
  description = "HTTP path used for backend service health checks."
  type        = string
  default     = "/"
}

# --- Azure ---

variable "azure_location" {
  description = "Azure region/location to deploy into."
  type        = string
  default     = "eastus"
}

variable "azure_lb_sku" {
  description = "Azure Load Balancer SKU. \"Standard\" is required for zone redundancy."
  type        = string
  default     = "Standard"
}
