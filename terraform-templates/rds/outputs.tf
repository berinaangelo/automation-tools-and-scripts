output "db_instance_endpoint" {
  description = "Connection endpoint (host:port) of the provisioned database (currently AWS — update if you switch providers)."
  value       = try(aws_db_instance.this.endpoint, null)
}

output "db_instance_address" {
  description = "Hostname of the provisioned database, without the port."
  value       = try(aws_db_instance.this.address, null)
}

output "db_instance_port" {
  description = "Port the provisioned database listens on."
  value       = try(aws_db_instance.this.port, null)
}

output "db_instance_arn" {
  description = "ARN of the provisioned RDS instance."
  value       = try(aws_db_instance.this.arn, null)
}

# output "gcp_instance_connection_name" {
#   value = try(google_sql_database_instance.this.connection_name, null)
# }

# output "azure_flexible_server_fqdn" {
#   value = try(azurerm_postgresql_flexible_server.this.fqdn, null)
# }
