output "iam_role_name" {
  description = "Name of the provisioned IAM role (currently AWS — update if you switch providers)."
  value       = try(aws_iam_role.this.name, null)
}

output "iam_role_arn" {
  description = "ARN of the provisioned IAM role."
  value       = try(aws_iam_role.this.arn, null)
}

output "instance_profile_name" {
  description = "Name of the instance profile — feed this into the autoscaling template's launch template (iam_instance_profile)."
  value       = try(aws_iam_instance_profile.this.name, null)
}

# output "gcp_service_account_email" {
#   value = try(google_service_account.this.email, null)
# }

# output "azure_identity_id" {
#   value = try(azurerm_user_assigned_identity.this.id, null)
# }
