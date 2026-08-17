output "lb_dns_name" {
  description = "DNS name of the provisioned load balancer (currently AWS — update if you switch providers)."
  value       = try(aws_lb.this.dns_name, null)
}

output "lb_arn" {
  description = "ARN of the provisioned load balancer."
  value       = try(aws_lb.this.arn, null)
}

output "target_group_arn" {
  description = "ARN of the target group — feed this into the autoscaling template's aws_target_group_arns."
  value       = try(aws_lb_target_group.this.arn, null)
}

# output "gcp_forwarding_rule_ip" {
#   value = try(google_compute_global_forwarding_rule.this.ip_address, null)
# }

# output "azure_lb_public_ip" {
#   value = try(azurerm_public_ip.lb.ip_address, null)
# }
