output "bucket_id" {
  description = "ID/name of the provisioned bucket (currently AWS — update if you switch providers)."
  value       = try(aws_s3_bucket.this.id, null)
}

output "bucket_arn" {
  description = "ARN of the provisioned bucket."
  value       = try(aws_s3_bucket.this.arn, null)
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the bucket, useful as a CDN origin."
  value       = try(aws_s3_bucket.this.bucket_regional_domain_name, null)
}

output "cdn_domain_name" {
  description = "Domain name of the CDN distribution, if enable_cdn = true."
  value       = try(aws_cloudfront_distribution.this[0].domain_name, null)
}

# output "gcp_bucket_url" {
#   value = try(google_storage_bucket.this.url, null)
# }

# output "azure_storage_account_primary_blob_endpoint" {
#   value = try(azurerm_storage_account.this.primary_blob_endpoint, null)
# }
