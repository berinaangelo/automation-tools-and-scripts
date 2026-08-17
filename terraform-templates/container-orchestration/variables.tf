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
  default     = "container-orchestration"
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

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 80
}

variable "container_environment_variables" {
  description = "Environment variables passed to the container as plain key/value pairs. For secrets, reference the secrets-manager template's secret instead of putting values here."
  type        = map(string)
  default     = {}
}

variable "desired_count" {
  description = "Number of container instances/replicas to run."
  type        = number
  default     = 1
}

# --- AWS (ECS Fargate) ---

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "aws_container_image" {
  description = "Container image (repo:tag or full ECR URI) to run. No default on purpose — there's no sensible placeholder image for a real workload."
  type        = string
  default     = null
}

variable "aws_cpu" {
  description = "Fargate task-level vCPU units, e.g. \"256\" (.25 vCPU), \"512\" (.5 vCPU), \"1024\" (1 vCPU). Must be a valid Fargate cpu/memory combination."
  type        = string
  default     = "256"
}

variable "aws_memory" {
  description = "Fargate task-level memory in MiB, e.g. \"512\". Must be a valid Fargate cpu/memory combination for the chosen aws_cpu."
  type        = string
  default     = "512"
}

variable "aws_subnet_ids" {
  description = "Subnet IDs the service's tasks run in. Required — comes from the networking template's private_subnet_ids output (or public_subnet_ids if aws_assign_public_ip = true)."
  type        = list(string)
  default     = []
}

variable "aws_security_group_ids" {
  description = "Security group IDs attached to the service's tasks. Required — comes from the networking template's internal_security_group_id output."
  type        = list(string)
  default     = []
}

variable "aws_assign_public_ip" {
  description = "Whether tasks get a public IP. Only needed when running in public subnets without a NAT gateway for outbound access."
  type        = bool
  default     = false
}

variable "aws_target_group_arn" {
  description = "Optional ALB/NLB target group ARN (from the load-balancer template's target_group_arn output) to register tasks with. Leave null to run the service without a load balancer."
  type        = string
  default     = null
}

variable "aws_task_role_arn" {
  description = "Optional IAM role ARN (from the iam template, with aws_iam_trusted_service = \"ecs-tasks.amazonaws.com\") granting the running container application-level AWS permissions. Leave null if the container doesn't need to call AWS APIs. This is separate from the task execution role this template creates for itself (pulling the image, writing logs)."
  type        = string
  default     = null
}

variable "aws_log_retention_days" {
  description = "CloudWatch log group retention in days for the task's container logs."
  type        = number
  default     = 14
}

# --- GCP (Cloud Run) ---

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

variable "gcp_container_image" {
  description = "Container image to run, e.g. a Container Registry/Artifact Registry URI. No default on purpose."
  type        = string
  default     = null
}

variable "gcp_cpu" {
  description = "vCPU limit per Cloud Run instance, e.g. \"1\"."
  type        = string
  default     = "1"
}

variable "gcp_memory" {
  description = "Memory limit per Cloud Run instance, e.g. \"512Mi\"."
  type        = string
  default     = "512Mi"
}

variable "gcp_allow_unauthenticated" {
  description = "Whether the Cloud Run service is publicly invocable without auth. Keep false unless this is meant to be a public endpoint."
  type        = bool
  default     = false
}

# --- Azure (Container Apps) ---

variable "azure_location" {
  description = "Azure region/location to deploy into."
  type        = string
  default     = "eastus"
}

variable "azure_container_image" {
  description = "Container image to run, e.g. an ACR URI. No default on purpose."
  type        = string
  default     = null
}

variable "azure_cpu" {
  description = "vCPU allocated per container app replica, e.g. 0.5."
  type        = number
  default     = 0.5
}

variable "azure_memory" {
  description = "Memory allocated per container app replica, e.g. \"1Gi\"."
  type        = string
  default     = "1Gi"
}
