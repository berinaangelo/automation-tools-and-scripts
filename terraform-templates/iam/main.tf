# IAM roles/policies Terraform template
#
# Multi-cloud starting point for a reusable role/identity + attached
# permissions — an EC2/ECS instance role on AWS, a service account on GCP, a
# user-assigned managed identity on Azure. Only ONE provider block should be
# active at a time — AWS is active by default. To target a different cloud:
# comment out the active provider + its resources, uncomment the one you
# want, and set cloud_provider in terraform.tfvars accordingly.
#
# Feed this template's output instance profile name into the autoscaling
# template's launch template (iam_instance_profile) to wire the two
# together.

locals {
  name = "${var.project_name}-${var.environment}"
}

# --- AWS (active) ---

provider "aws" {
  region = var.aws_region
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [var.aws_iam_trusted_service]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = coalesce(var.aws_iam_role_name, local.name)
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(var.tags, {
    Name = local.name
  })
}

resource "aws_iam_instance_profile" "this" {
  name = coalesce(var.aws_iam_role_name, local.name)
  role = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.aws_iam_managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# Only created when aws_iam_inline_policy_json is set — leave it null and
# rely on aws_iam_managed_policy_arns wherever a managed policy will do.
resource "aws_iam_role_policy" "inline" {
  count = var.aws_iam_inline_policy_json != null ? 1 : 0

  name   = "${local.name}-inline"
  role   = aws_iam_role.this.id
  policy = var.aws_iam_inline_policy_json
}

# --- GCP (inactive — uncomment to use) ---

# provider "google" {
#   project = var.gcp_project_id
# }
#
# resource "google_service_account" "this" {
#   account_id   = coalesce(var.gcp_service_account_id, local.name)
#   display_name = local.name
# }
#
# resource "google_project_iam_member" "this" {
#   for_each = toset(var.gcp_iam_roles)
#
#   project = var.gcp_project_id
#   role    = each.value
#   member  = "serviceAccount:${google_service_account.this.email}"
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
# resource "azurerm_user_assigned_identity" "this" {
#   name                = coalesce(var.azure_identity_name, local.name)
#   resource_group_name = azurerm_resource_group.this.name
#   location            = azurerm_resource_group.this.location
#   tags                = var.tags
# }
#
# resource "azurerm_role_assignment" "this" {
#   for_each = var.azure_role_assignments
#
#   principal_id         = azurerm_user_assigned_identity.this.principal_id
#   role_definition_name = each.value.role_definition_name
#   scope                = each.value.scope
# }
