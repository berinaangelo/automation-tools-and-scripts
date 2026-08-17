# Autoscaling Terraform template
#
# Multi-cloud starting point for a scale-out compute group (ASG / MIG / VMSS)
# with a CPU-based target-tracking scaling policy. Only ONE provider block
# should be active at a time — AWS is active by default. To target a
# different cloud: comment out the active provider + its resources,
# uncomment the one you want, and set cloud_provider in terraform.tfvars
# accordingly.

locals {
  name = "${var.project_name}-${var.environment}"
}

# --- AWS (active) ---

provider "aws" {
  region = var.aws_region
}

resource "aws_launch_template" "this" {
  name_prefix   = "${local.name}-"
  image_id      = var.aws_ami_id # placeholder — pin to a real AMI for your region
  instance_type = var.aws_instance_type

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = local.name
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  name                = local.name
  vpc_zone_identifier = var.aws_vpc_zone_identifiers # required — set in terraform.tfvars

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  health_check_type         = var.aws_health_check_type
  health_check_grace_period = 300
  target_group_arns         = var.aws_target_group_arns

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(var.tags, { Name = local.name })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target-tracking policy: ASG adds/removes instances to hold average CPU
# near var.target_cpu_utilization. Swap for a step-scaling or
# request-count-per-target policy if CPU isn't the right signal.
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${local.name}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type             = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.target_cpu_utilization
  }
}

# --- GCP (inactive — uncomment to use) ---

# provider "google" {
#   project = var.gcp_project_id
#   region  = var.gcp_region
#   zone    = var.gcp_zone
# }
#
# resource "google_compute_instance_template" "this" {
#   name_prefix  = "${local.name}-"
#   machine_type = var.gcp_machine_type
#
#   disk {
#     source_image = "debian-cloud/debian-12" # placeholder
#     auto_delete  = true
#     boot         = true
#   }
#
#   network_interface {
#     network = var.gcp_network
#   }
#
#   labels = var.tags
#
#   lifecycle {
#     create_before_destroy = true
#   }
# }
#
# resource "google_compute_region_instance_group_manager" "this" {
#   name               = local.name
#   region             = var.gcp_region
#   base_instance_name = local.name
#
#   version {
#     instance_template = google_compute_instance_template.this.id
#   }
#
#   target_size = var.desired_capacity
# }
#
# resource "google_compute_region_autoscaler" "this" {
#   name   = "${local.name}-autoscaler"
#   region = var.gcp_region
#   target = google_compute_region_instance_group_manager.this.id
#
#   autoscaling_policy {
#     min_replicas = var.min_size
#     max_replicas = var.max_size
#
#     cpu_utilization {
#       target = var.target_cpu_utilization / 100
#     }
#   }
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
# resource "azurerm_linux_virtual_machine_scale_set" "this" {
#   name                = local.name
#   resource_group_name = azurerm_resource_group.this.name
#   location            = azurerm_resource_group.this.location
#   sku                 = var.azure_vm_size
#   instances           = var.desired_capacity
#   admin_username      = var.azure_admin_username
#
#   admin_ssh_key {
#     username   = var.azure_admin_username
#     public_key = var.azure_admin_ssh_public_key # required — set in terraform.tfvars
#   }
#
#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-jammy"
#     sku       = "22_04-lts"
#     version   = "latest"
#   }
#
#   os_disk {
#     storage_account_type = "Standard_LRS"
#     caching               = "ReadWrite"
#   }
#
#   network_interface {
#     name    = "${local.name}-nic"
#     primary = true
#
#     ip_configuration {
#       name      = "internal"
#       primary   = true
#       subnet_id = var.azure_subnet_id # required — set in terraform.tfvars
#     }
#   }
#
#   tags = var.tags
# }
#
# resource "azurerm_monitor_autoscale_setting" "this" {
#   name                = "${local.name}-autoscale"
#   resource_group_name = azurerm_resource_group.this.name
#   location            = azurerm_resource_group.this.location
#   target_resource_id  = azurerm_linux_virtual_machine_scale_set.this.id
#
#   profile {
#     name = "cpu-target-tracking"
#
#     capacity {
#       default = var.desired_capacity
#       minimum = var.min_size
#       maximum = var.max_size
#     }
#
#     rule {
#       metric_trigger {
#         metric_name        = "Percentage CPU"
#         metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
#         time_grain         = "PT1M"
#         statistic          = "Average"
#         time_window        = "PT5M"
#         time_aggregation   = "Average"
#         operator            = "GreaterThan"
#         threshold           = var.target_cpu_utilization
#       }
#
#       scale_action {
#         direction = "Increase"
#         type      = "ChangeCount"
#         value     = "1"
#         cooldown  = "PT5M"
#       }
#     }
#
#     rule {
#       metric_trigger {
#         metric_name        = "Percentage CPU"
#         metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
#         time_grain         = "PT1M"
#         statistic          = "Average"
#         time_window        = "PT5M"
#         time_aggregation   = "Average"
#         operator            = "LessThan"
#         threshold           = var.target_cpu_utilization - 20
#       }
#
#       scale_action {
#         direction = "Decrease"
#         type      = "ChangeCount"
#         value     = "1"
#         cooldown  = "PT5M"
#       }
#     }
#   }
# }
