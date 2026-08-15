# System-setup Terraform template
#
# Multi-cloud starting point for provisioning a new system. Only ONE
# provider block should be active at a time — AWS is active by default.
# To target a different cloud: comment out the active provider + its
# example resource, uncomment the one you want, and set cloud_provider
# in terraform.tfvars accordingly.

locals {
  name = "${var.project_name}-${var.environment}"
}

# --- AWS (active) ---

provider "aws" {
  region = var.aws_region
}

# Example compute resource — replace with whatever the system actually needs
# (EC2, ECS, EKS, RDS, etc.).
resource "aws_instance" "this" {
  ami           = "ami-0c101f26f147fa7fd" # placeholder — pin to a real AMI for your region
  instance_type = var.aws_instance_type

  tags = merge(var.tags, {
    Name = local.name
  })
}

# --- GCP (inactive — uncomment to use) ---

# provider "google" {
#   project = var.gcp_project_id
#   region  = var.gcp_region
#   zone    = var.gcp_zone
# }
#
# resource "google_compute_instance" "this" {
#   name         = local.name
#   machine_type = var.gcp_machine_type
#   zone         = var.gcp_zone
#
#   boot_disk {
#     initialize_params {
#       image = "debian-cloud/debian-12" # placeholder
#     }
#   }
#
#   network_interface {
#     network = "default"
#   }
#
#   labels = var.tags
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
# resource "azurerm_linux_virtual_machine" "this" {
#   name                = local.name
#   resource_group_name = azurerm_resource_group.this.name
#   location            = azurerm_resource_group.this.location
#   size                = var.azure_vm_size
#   admin_username      = "azureuser"
#
#   # admin_ssh_key / network_interface_ids / os_disk / source_image_reference
#   # all need to be filled in before this resource is usable.
#
#   tags = var.tags
# }
