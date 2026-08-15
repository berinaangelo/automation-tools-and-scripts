output "instance_id" {
  description = "ID of the provisioned compute instance (currently AWS — update if you switch providers)."
  value       = try(aws_instance.this.id, null)
}

output "instance_public_ip" {
  description = "Public IP of the provisioned compute instance, if one was assigned."
  value       = try(aws_instance.this.public_ip, null)
}

# output "gcp_instance_id" {
#   value = try(google_compute_instance.this.instance_id, null)
# }

# output "azure_vm_id" {
#   value = try(azurerm_linux_virtual_machine.this.id, null)
# }
