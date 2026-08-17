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
  default     = "autoscaling"
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

variable "min_size" {
  description = "Minimum number of instances the group/scale set should ever run."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances the group/scale set can scale out to."
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Initial/target number of instances. Ignored after the first apply where scaling policies are in play (they take over)."
  type        = number
  default     = 1
}

variable "target_cpu_utilization" {
  description = "Target average CPU utilization (percent) the scaling policy tries to hold across the group."
  type        = number
  default     = 60
}

# --- AWS ---

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "aws_instance_type" {
  description = "EC2 instance type used by the launch template."
  type        = string
  default     = "t3.micro"
}

variable "aws_ami_id" {
  description = "AMI ID for the launch template. Placeholder default — pin to a real, current AMI for your region before applying."
  type        = string
  default     = "ami-0c101f26f147fa7fd"
}

variable "aws_vpc_zone_identifiers" {
  description = "List of subnet IDs the Auto Scaling Group spreads instances across. Required — the ASG has no default subnets to fall back to."
  type        = list(string)
  default     = []
}

variable "aws_health_check_type" {
  description = "ASG health check type: \"EC2\" or \"ELB\". Use \"ELB\" once instances sit behind a load balancer/target group."
  type        = string
  default     = "EC2"

  validation {
    condition     = contains(["EC2", "ELB"], var.aws_health_check_type)
    error_message = "aws_health_check_type must be one of: EC2, ELB."
  }
}

variable "aws_target_group_arns" {
  description = "Optional list of ALB/NLB target group ARNs to attach the ASG to. Leave empty if there's no load balancer yet."
  type        = list(string)
  default     = []
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
  description = "GCP zone used as the base for the instance template's boot image."
  type        = string
  default     = "us-central1-a"
}

variable "gcp_machine_type" {
  description = "GCE machine type used by the instance template."
  type        = string
  default     = "e2-micro"
}

variable "gcp_network" {
  description = "VPC network the managed instance group's instances attach to."
  type        = string
  default     = "default"
}

# --- Azure ---

variable "azure_location" {
  description = "Azure region/location to deploy into."
  type        = string
  default     = "eastus"
}

variable "azure_vm_size" {
  description = "VM size used by the scale set."
  type        = string
  default     = "Standard_B1s"
}

variable "azure_admin_username" {
  description = "Admin username for scale set instances."
  type        = string
  default     = "azureuser"
}

variable "azure_admin_ssh_public_key" {
  description = "SSH public key content for the scale set admin user. Required before the Azure block is usable."
  type        = string
  default     = null
}

variable "azure_subnet_id" {
  description = "Subnet ID the scale set's network interfaces attach to. Required — no default subnet is created here."
  type        = string
  default     = null
}
