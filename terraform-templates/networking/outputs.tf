output "vpc_id" {
  description = "ID of the provisioned VPC (currently AWS — update if you switch providers)."
  value       = try(aws_vpc.this.id, null)
}

output "public_subnet_ids" {
  description = "IDs of the public subnets — feed these into a load balancer or the autoscaling template's public-facing tier."
  value       = try(aws_subnet.public[*].id, null)
}

output "private_subnet_ids" {
  description = "IDs of the private subnets — feed these into the autoscaling and rds templates' subnet_ids inputs."
  value       = try(aws_subnet.private[*].id, null)
}

output "web_security_group_id" {
  description = "ID of the security group allowing inbound HTTP/HTTPS from the internet."
  value       = try(aws_security_group.web.id, null)
}

output "internal_security_group_id" {
  description = "ID of the security group allowing all traffic within the VPC — feed this into the rds template's aws_vpc_security_group_ids."
  value       = try(aws_security_group.internal.id, null)
}

output "nat_gateway_ids" {
  description = "IDs of the provisioned NAT gateway(s)."
  value       = try(aws_nat_gateway.this[*].id, null)
}

# output "gcp_network_id" {
#   value = try(google_compute_network.this.id, null)
# }

# output "azure_vnet_id" {
#   value = try(azurerm_virtual_network.this.id, null)
# }
