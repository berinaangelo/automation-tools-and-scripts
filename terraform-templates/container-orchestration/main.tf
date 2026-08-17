# Container orchestration Terraform template
#
# Multi-cloud starting point for running a container as a managed service —
# AWS ECS on Fargate, GCP Cloud Run, or Azure Container Apps. All three are
# serverless/managed container runtimes rather than a full Kubernetes
# cluster (EKS/GKE/AKS) — swap this template out entirely if you actually
# need Kubernetes; that's a heavier setup not covered here.
#
# Only ONE provider block should be active at a time — AWS is active by
# default. To target a different cloud: comment out the active provider +
# its resources, uncomment the one you want, and set cloud_provider in
# terraform.tfvars accordingly.

locals {
  name = "${var.project_name}-${var.environment}"
}

# --- AWS (active) — ECS on Fargate ---

provider "aws" {
  region = var.aws_region
}

resource "aws_ecs_cluster" "this" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, {
    Name = local.name
  })
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${local.name}"
  retention_in_days = var.aws_log_retention_days

  tags = merge(var.tags, {
    Name = local.name
  })
}

# Task execution role — lets ECS itself pull the image and write logs.
# Separate from aws_task_role_arn, which grants the running application
# its own AWS permissions.
data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${local.name}-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json

  tags = merge(var.tags, {
    Name = "${local.name}-execution"
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.aws_cpu
  memory                   = var.aws_memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = var.aws_task_role_arn

  container_definitions = jsonencode([
    {
      name  = local.name
      image = var.aws_container_image # required — see variable description
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        for key, value in var.container_environment_variables : { name = key, value = value }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = local.name
        }
      }
    }
  ])

  tags = merge(var.tags, {
    Name = local.name
  })
}

resource "aws_ecs_service" "this" {
  name            = local.name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.aws_subnet_ids # required — see variable description
    security_groups  = var.aws_security_group_ids # required — see variable description
    assign_public_ip = var.aws_assign_public_ip
  }

  # Only registers with a load balancer when aws_target_group_arn is set.
  dynamic "load_balancer" {
    for_each = var.aws_target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.aws_target_group_arn
      container_name    = local.name
      container_port    = var.container_port
    }
  }

  tags = merge(var.tags, {
    Name = local.name
  })
}

# --- GCP (inactive — uncomment to use) — Cloud Run ---

# provider "google" {
#   project = var.gcp_project_id
#   region  = var.gcp_region
# }
#
# resource "google_cloud_run_v2_service" "this" {
#   name     = local.name
#   location = var.gcp_region
#
#   template {
#     containers {
#       image = var.gcp_container_image # required — see variable description
#
#       ports {
#         container_port = var.container_port
#       }
#
#       dynamic "env" {
#         for_each = var.container_environment_variables
#         content {
#           name  = env.key
#           value = env.value
#         }
#       }
#
#       resources {
#         limits = {
#           cpu    = var.gcp_cpu
#           memory = var.gcp_memory
#         }
#       }
#     }
#
#     scaling {
#       min_instance_count = var.desired_count
#     }
#   }
# }
#
# # Only created when gcp_allow_unauthenticated = true.
# resource "google_cloud_run_v2_service_iam_member" "public" {
#   count    = var.gcp_allow_unauthenticated ? 1 : 0
#   location = google_cloud_run_v2_service.this.location
#   name     = google_cloud_run_v2_service.this.name
#   role     = "roles/run.invoker"
#   member   = "allUsers"
# }

# --- Azure (inactive — uncomment to use) — Container Apps ---

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
# resource "azurerm_log_analytics_workspace" "this" {
#   name                = "${local.name}-logs"
#   resource_group_name = azurerm_resource_group.this.name
#   location            = azurerm_resource_group.this.location
#   sku                 = "PerGB2018"
# }
#
# resource "azurerm_container_app_environment" "this" {
#   name                       = local.name
#   resource_group_name       = azurerm_resource_group.this.name
#   location                   = azurerm_resource_group.this.location
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
# }
#
# resource "azurerm_container_app" "this" {
#   name                        = local.name
#   resource_group_name        = azurerm_resource_group.this.name
#   container_app_environment_id = azurerm_container_app_environment.this.id
#   revision_mode               = "Single"
#
#   template {
#     min_replicas = var.desired_count
#     max_replicas = var.desired_count
#
#     container {
#       name   = local.name
#       image  = var.azure_container_image # required — see variable description
#       cpu    = var.azure_cpu
#       memory = var.azure_memory
#
#       dynamic "env" {
#         for_each = var.container_environment_variables
#         content {
#           name  = env.key
#           value = env.value
#         }
#       }
#     }
#   }
#
#   ingress {
#     external_enabled = false
#     target_port       = var.container_port
#
#     traffic_weight {
#       latest_revision = true
#       percentage       = 100
#     }
#   }
#
#   tags = var.tags
# }
