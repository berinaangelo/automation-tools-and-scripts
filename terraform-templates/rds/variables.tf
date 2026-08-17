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
  default     = "rds"
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

variable "multi_az" {
  description = "Whether the database runs with a synchronous standby in a second AZ (AWS Multi-AZ / GCP HA availability_type / Azure zone-redundant HA). Off by default to keep a first apply cheap — flip to true for anything production-facing."
  type        = bool
  default     = false
}

# --- AWS ---

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "aws_db_engine" {
  description = "RDS engine to provision, e.g. \"postgres\", \"mysql\", \"mariadb\", \"oracle-se2\", \"sqlserver-ex\". User-defined on purpose — not restricted to a fixed list since RDS supports many engines and this template doesn't validate engine-specific option/parameter groups for you."
  type        = string
  default     = "postgres"
}

variable "aws_db_engine_version" {
  description = "Engine version, e.g. \"16.3\". Leave null to let AWS pick the current default version for the chosen engine."
  type        = string
  default     = null
}

variable "aws_db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "aws_db_allocated_storage" {
  description = "Allocated storage in GiB."
  type        = number
  default     = 20
}

variable "aws_db_storage_type" {
  description = "EBS storage type backing the instance, e.g. \"gp3\", \"gp2\", \"io1\"."
  type        = string
  default     = "gp3"
}

variable "aws_db_name" {
  description = "Name of the default database created on the instance."
  type        = string
  default     = "app"
}

variable "aws_db_username" {
  description = "Master username for the instance."
  type        = string
  default     = "admin"
}

variable "aws_db_password" {
  description = "Master password for the instance. No usable default on purpose — required via terraform.tfvars (gitignored) or a TF_VAR_aws_db_password environment variable before applying. Never hardcode it in main.tf."
  type        = string
  sensitive   = true
  default     = null # only reached when the AWS block is actually used; AWS will reject a null password at apply
}

variable "aws_db_port" {
  description = "Port the instance listens on. Leave null to fall back to the standard port for the chosen engine (5432 for postgres, 3306 for mysql/mariadb, etc.)."
  type        = number
  default     = null
}

variable "aws_db_subnet_group_subnet_ids" {
  description = "Subnet IDs for the DB subnet group. Required — the instance has no default subnets to fall back to. Use at least two subnets in different AZs."
  type        = list(string)
  default     = []
}

variable "aws_vpc_security_group_ids" {
  description = "Security group IDs attached to the instance. Required — leaving this empty means no explicit ingress is granted."
  type        = list(string)
  default     = []
}

variable "aws_publicly_accessible" {
  description = "Whether the instance gets a publicly routable endpoint. Keep false unless you specifically need direct internet access to the database."
  type        = bool
  default     = false
}

variable "aws_backup_retention_period" {
  description = "Number of days to retain automated backups. 0 disables automated backups."
  type        = number
  default     = 7
}

variable "aws_skip_final_snapshot" {
  description = "Whether to skip taking a final snapshot on destroy. true is convenient for throwaway dev databases; set false for anything you can't afford to lose."
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

variable "gcp_db_version" {
  description = "Cloud SQL database_version, e.g. \"POSTGRES_16\", \"MYSQL_8_0\"."
  type        = string
  default     = "POSTGRES_16"
}

variable "gcp_db_tier" {
  description = "Cloud SQL machine tier, e.g. \"db-f1-micro\"."
  type        = string
  default     = "db-f1-micro"
}

variable "gcp_db_password" {
  description = "Password for the default Cloud SQL user. No default on purpose — required at apply time via terraform.tfvars (gitignored) or a TF_VAR_gcp_db_password environment variable."
  type        = string
  sensitive   = true
  default     = null # only reached when the GCP block is actually uncommented and used
}

# --- Azure ---

variable "azure_location" {
  description = "Azure region/location to deploy into."
  type        = string
  default     = "eastus"
}

variable "azure_db_sku_name" {
  description = "Flexible Server SKU, e.g. \"B_Standard_B1ms\"."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "azure_db_admin_username" {
  description = "Admin username for the flexible server."
  type        = string
  default     = "dbadmin"
}

variable "azure_db_admin_password" {
  description = "Admin password for the flexible server. No default on purpose — provide via terraform.tfvars (gitignored) or a TF_VAR_azure_db_admin_password environment variable."
  type        = string
  default     = null
  sensitive   = true
}

variable "azure_db_version" {
  description = "Engine version for the flexible server, e.g. \"16\" for PostgreSQL."
  type        = string
  default     = "16"
}
