output "secret_id" {
  description = "ID of the provisioned secret (currently AWS — update if you switch providers)."
  value       = try(aws_secretsmanager_secret.this.id, null)
}

output "secret_arn" {
  description = "ARN of the provisioned secret."
  value       = try(aws_secretsmanager_secret.this.arn, null)
}

# output "gcp_secret_id" {
#   value = try(google_secret_manager_secret.this.id, null)
# }

# output "azure_key_vault_secret_id" {
#   value = try(azurerm_key_vault_secret.this.id, null)
# }
