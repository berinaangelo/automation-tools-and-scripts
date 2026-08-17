# Load balancer Terraform template
#
# Multi-cloud starting point for a load balancer + target group in front of
# the autoscaling template's ASG/MIG/VMSS. Only ONE provider block should be
# active at a time — AWS is active by default. To target a different cloud:
# comment out the active provider + its resources, uncomment the one you
# want, and set cloud_provider in terraform.tfvars accordingly.
#
# Feed this template's output target group ARN into the autoscaling
# template's aws_target_group_arns to wire the two together.

locals {
  name = "${var.project_name}-${var.environment}"
}

# --- AWS (active) ---

provider "aws" {
  region = var.aws_region
}

resource "aws_lb" "this" {
  name               = local.name
  internal           = var.aws_lb_internal
  load_balancer_type = var.aws_lb_type
  subnets            = var.aws_subnet_ids # required — see variable description
  security_groups    = var.aws_lb_type == "application" ? var.aws_security_group_ids : null

  tags = merge(var.tags, {
    Name = local.name
  })
}

resource "aws_lb_target_group" "this" {
  name        = local.name
  port        = var.aws_target_port
  protocol    = var.aws_target_protocol
  vpc_id      = var.aws_vpc_id # required — see variable description
  target_type = "instance"

  health_check {
    protocol = var.aws_target_protocol
    path     = var.aws_lb_type == "application" ? var.aws_health_check_path : null
    matcher  = var.aws_lb_type == "application" ? "200-399" : null
  }

  tags = merge(var.tags, {
    Name = local.name
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = var.aws_lb_type == "application" ? "HTTP" : "TCP"

  dynamic "default_action" {
    for_each = var.aws_lb_type == "application" && var.aws_enable_https ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.aws_lb_type == "application" && var.aws_enable_https ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this.arn
    }
  }
}

# HTTPS listener — only created for an ALB with aws_enable_https = true.
resource "aws_lb_listener" "https" {
  count = var.aws_lb_type == "application" && var.aws_enable_https ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.aws_certificate_arn # required when aws_enable_https = true

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# --- GCP (inactive — uncomment to use) ---
#
# Shown as a regional external Application Load Balancer (HTTP). Swap for a
# passthrough Network Load Balancer if you need L4 instead.

# provider "google" {
#   project = var.gcp_project_id
#   region  = var.gcp_region
# }
#
# resource "google_compute_health_check" "this" {
#   name = "${local.name}-health"
#
#   http_health_check {
#     port         = var.aws_target_port
#     request_path = var.gcp_health_check_path
#   }
# }
#
# resource "google_compute_backend_service" "this" {
#   name                  = local.name
#   protocol              = "HTTP"
#   load_balancing_scheme = "EXTERNAL"
#   health_checks         = [google_compute_health_check.this.id]
# }
#
# resource "google_compute_url_map" "this" {
#   name            = local.name
#   default_service = google_compute_backend_service.this.id
# }
#
# resource "google_compute_target_http_proxy" "this" {
#   name    = local.name
#   url_map = google_compute_url_map.this.id
# }
#
# resource "google_compute_global_forwarding_rule" "this" {
#   name                  = local.name
#   target                = google_compute_target_http_proxy.this.id
#   port_range            = "80"
#   load_balancing_scheme = "EXTERNAL"
# }

# --- Azure (inactive — uncomment to use) ---
#
# Shown as a Standard Load Balancer (L4) — the closer analog to an NLB.
# For L7/HTTP routing comparable to an ALB, use Application Gateway instead.

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
# resource "azurerm_public_ip" "lb" {
#   name                = "${local.name}-ip"
#   resource_group_name = azurerm_resource_group.this.name
#   location            = azurerm_resource_group.this.location
#   allocation_method   = "Static"
#   sku                 = var.azure_lb_sku
# }
#
# resource "azurerm_lb" "this" {
#   name                = local.name
#   resource_group_name = azurerm_resource_group.this.name
#   location            = azurerm_resource_group.this.location
#   sku                 = var.azure_lb_sku
#
#   frontend_ip_configuration {
#     name                 = "${local.name}-frontend"
#     public_ip_address_id = azurerm_public_ip.lb.id
#   }
#
#   tags = var.tags
# }
#
# resource "azurerm_lb_backend_address_pool" "this" {
#   loadbalancer_id = azurerm_lb.this.id
#   name            = "${local.name}-backend"
# }
#
# resource "azurerm_lb_probe" "this" {
#   loadbalancer_id = azurerm_lb.this.id
#   name            = "${local.name}-probe"
#   port            = var.aws_target_port
# }
#
# resource "azurerm_lb_rule" "this" {
#   loadbalancer_id                = azurerm_lb.this.id
#   name                           = "${local.name}-rule"
#   protocol                       = "Tcp"
#   frontend_port                  = 80
#   backend_port                   = var.aws_target_port
#   frontend_ip_configuration_name = "${local.name}-frontend"
#   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
#   probe_id                       = azurerm_lb_probe.this.id
# }
