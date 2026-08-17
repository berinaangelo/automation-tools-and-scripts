output "ecs_cluster_id" {
  description = "ID of the provisioned ECS cluster (currently AWS — update if you switch providers)."
  value       = try(aws_ecs_cluster.this.id, null)
}

output "ecs_service_name" {
  description = "Name of the provisioned ECS service."
  value       = try(aws_ecs_service.this.name, null)
}

output "task_execution_role_arn" {
  description = "ARN of the task execution role this template created (image pull + logging permissions, not application permissions)."
  value       = try(aws_iam_role.execution.arn, null)
}

# output "gcp_cloud_run_url" {
#   value = try(google_cloud_run_v2_service.this.uri, null)
# }

# output "azure_container_app_fqdn" {
#   value = try(azurerm_container_app.this.latest_revision_fqdn, null)
# }
