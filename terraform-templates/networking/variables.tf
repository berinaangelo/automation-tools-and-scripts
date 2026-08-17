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
  default     = "networking"
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

variable "aws_vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ, in order). Instances here get a route to the internet gateway."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "aws_private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ, in order). Instances here route outbound through NAT and are not directly reachable from the internet — this is where the RDS and autoscaling templates' subnet_ids should point."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "aws_availability_zones" {
  description = "AZs to spread subnets across, e.g. [\"us-east-1a\", \"us-east-1b\"]. Leave empty to auto-select the first N available AZs in aws_region (N = max of the public/private subnet CIDR counts)."
  type        = list(string)
  default     = []
}

variable "aws_single_nat_gateway" {
  description = "true: one shared NAT gateway for all private subnets (cheaper, single point of failure). false: one NAT gateway per AZ (higher cost, no cross-AZ dependency). Default true keeps a first apply cheap."
  type        = bool
  default     = true
}

variable "aws_enable_dns_hostnames" {
  description = "Whether instances in the VPC get DNS hostnames. Needed for most managed services (e.g. RDS) to resolve cleanly."
  type        = bool
  default     = true
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

variable "gcp_public_subnet_cidr" {
  description = "CIDR block for the public subnet. GCP doesn't gate public/private on the subnet itself — this subnet is meant for resources that get an external IP."
  type        = string
  default     = "10.10.0.0/24"
}

variable "gcp_private_subnet_cidr" {
  description = "CIDR block for the private subnet. Outbound internet access for resources here goes through Cloud NAT."
  type        = string
  default     = "10.10.10.0/24"
}

# --- Azure ---

variable "azure_location" {
  description = "Azure region/location to deploy into."
  type        = string
  default     = "eastus"
}

variable "azure_vnet_cidr" {
  description = "CIDR block for the virtual network."
  type        = string
  default     = "10.20.0.0/16"
}

variable "azure_public_subnet_cidr" {
  description = "CIDR block for the public subnet."
  type        = string
  default     = "10.20.0.0/24"
}

variable "azure_private_subnet_cidr" {
  description = "CIDR block for the private subnet."
  type        = string
  default     = "10.20.10.0/24"
}
