# RDS / managed-database Terraform template
#
# Multi-cloud starting point for a managed relational database (RDS / Cloud
# SQL / Azure Flexible Server). Only ONE provider block should be active at
# a time — AWS is active by default. To target a different cloud: comment
# out the active provider + its resources, uncomment the one you want, and
# set cloud_provider in terraform.tfvars accordingly.
#
# Passwords are never hardcoded here — they come from *_password variables
# with no usable default, meant to be supplied via terraform.tfvars
# (gitignored) or TF_VAR_* environment variables.

locals {
  name = "${var.project_name}-${var.environment}"

  # var.aws_db_port is user-definable but optional — fall back to the
  # standard port for the chosen engine when it's left null.
  aws_engine_default_ports = {
    postgres = 5432
    mysql    = 3306
    mariadb  = 3306
  }
  aws_db_port = coalesce(var.aws_db_port, lookup(local.aws_engine_default_ports, var.aws_db_engine, 5432))
}

# --- AWS (active) ---

provider "aws" {
  region = var.aws_region
}

resource "aws_db_subnet_group" "this" {
  name       = local.name
  subnet_ids = var.aws_db_subnet_group_subnet_ids # required — set in terraform.tfvars

  tags = merge(var.tags, {
    Name = local.name
  })
}

resource "aws_db_instance" "this" {
  identifier = local.name

  engine         = var.aws_db_engine # user-defined — see variables.tf for supported values
  engine_version = var.aws_db_engine_version

  instance_class    = var.aws_db_instance_class
  allocated_storage = var.aws_db_allocated_storage
  storage_type      = var.aws_db_storage_type

  db_name  = var.aws_db_name
  username = var.aws_db_username
  password = var.aws_db_password # required — see the variable's description, never hardcode
  port     = local.aws_db_port

  multi_az = var.multi_az

  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = var.aws_vpc_security_group_ids # required — no ingress without it
  publicly_accessible     = var.aws_publicly_accessible
  backup_retention_period = var.aws_backup_retention_period
  skip_final_snapshot     = var.aws_skip_final_snapshot

  final_snapshot_identifier = var.aws_skip_final_snapshot ? null : "${local.name}-final"

  tags = merge(var.tags, {
    Name = local.name
  })
}

# --- GCP (inactive — uncomment to use) ---

# provider "google" {
#   project = var.gcp_project_id
#   region  = var.gcp_region
# }
#
# resource "google_sql_database_instance" "this" {
#   name             = local.name
#   region           = var.gcp_region
#   database_version = var.gcp_db_version
#
#   settings {
#     tier              = var.gcp_db_tier
#     availability_type = var.multi_az ? "REGIONAL" : "ZONAL"
#   }
#
#   deletion_protection = false # dev-friendly default — flip to true once this is a real system
# }
#
# resource "google_sql_database" "this" {
#   name     = var.project_name
#   instance = google_sql_database_instance.this.name
# }
#
# resource "google_sql_user" "this" {
#   name     = "app"
#   instance = google_sql_database_instance.this.name
#   password = var.gcp_db_password # required — see the variable's description, never hardcode
# }

# --- Azure (inactive — uncomment to use) ---
#
# Shown here for PostgreSQL. Azure has a separate resource type per engine
# (azurerm_postgresql_flexible_server vs azurerm_mysql_flexible_server) —
# swap the resource type if you need MySQL instead.

# provider "azurerm" {
#   features {}
# }
#
# resource "azurerm_resource_group" "this" {
#   name     = "${local.name}-rg"
#   location = var.azure_location
#   tags     = var.tags
# }
#
# resource "azurerm_postgresql_flexible_server" "this" {
#   name                = local.name
#   resource_group_name = azurerm_resource_group.this.name
#   location            = azurerm_resource_group.this.location
#
#   sku_name = var.azure_db_sku_name
#   version  = var.azure_db_version
#
#   administrator_login    = var.azure_db_admin_username
#   administrator_password = var.azure_db_admin_password # required — see the variable's description, never hardcode
#
#   high_availability {
#     mode = var.multi_az ? "ZoneRedundant" : "Disabled"
#   }
#
#   tags = var.tags
# }
