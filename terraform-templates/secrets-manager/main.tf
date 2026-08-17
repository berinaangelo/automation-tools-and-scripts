# Secrets manager Terraform template
#
# Multi-cloud starting point for a single managed secret — AWS Secrets
# Manager, GCP Secret Manager, or an Azure Key Vault secret. Only ONE
# provider block should be active at a time — AWS is active by default. To
# target a different cloud: comment out the active provider + its
# resources, uncomment the one you want, and set cloud_provider in
# terraform.tfvars accordingly.
#
# Secret values are never hardcoded here — they come from *_secret_value
# variables with no usable default, meant to be supplied via
# TF_VAR_* environment variables rather than terraform.tfvars, since
# Terraform state will contain the value in plaintext either way (encrypt
# state at rest and restrict who can read it).

locals {
  name = "${var.project_name}-${var.environment}"
}

# --- AWS (active) ---

provider "aws" {
  region = var.aws_region
}

resource "aws_secretsmanager_secret" "this" {
  name                    = coalesce(var.aws_secret_name, local.name)
  description             = var.secret_description
  recovery_window_in_days = var.aws_recovery_window_in_days

  tags = merge(var.tags, {
    Name = local.name
  })
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.aws_secret_value # required — see the variable's description, never hardcode
}

# --- GCP (inactive — uncomment to use) ---

# provider "google" {
#   project = var.gcp_project_id
# }
#
# resource "google_secret_manager_secret" "this" {
#   secret_id = coalesce(var.gcp_secret_id, local.name)
#
#   replication {
#     auto {}
#   }
#
#   labels = var.tags
# }
#
# resource "google_secret_manager_secret_version" "this" {
#   secret      = google_secret_manager_secret.this.id
#   secret_data = var.gcp_secret_value # required — see the variable's description, never hardcode
# }

# --- Azure (inactive — uncomment to use) ---

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
# resource "azurerm_key_vault" "this" {
#   name                = var.azure_key_vault_name # required — see variable description, must be globally unique
#   resource_group_name = azurerm_resource_group.this.name
#   location            = azurerm_resource_group.this.location
#   tenant_id           = var.azure_tenant_id # required — see variable description
#   sku_name            = "standard"
#
#   tags = var.tags
# }
#
# resource "azurerm_key_vault_secret" "this" {
#   name         = coalesce(var.azure_secret_name, local.name)
#   value        = var.azure_secret_value # required — see the variable's description, never hardcode
#   key_vault_id = azurerm_key_vault.this.id
# }
