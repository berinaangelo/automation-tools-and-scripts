output "autoscaling_group_name" {
  description = "Name of the provisioned Auto Scaling Group (currently AWS — update if you switch providers)."
  value       = try(aws_autoscaling_group.this.name, null)
}

output "autoscaling_group_arn" {
  description = "ARN of the provisioned Auto Scaling Group."
  value       = try(aws_autoscaling_group.this.arn, null)
}

output "launch_template_id" {
  description = "ID of the launch template used by the Auto Scaling Group."
  value       = try(aws_launch_template.this.id, null)
}

# output "gcp_instance_group_manager_id" {
#   value = try(google_compute_region_instance_group_manager.this.id, null)
# }

# output "azure_scale_set_id" {
#   value = try(azurerm_linux_virtual_machine_scale_set.this.id, null)
# }
