# Object storage (+ CDN) Terraform template
#
# Multi-cloud starting point for a private object storage bucket — S3 / GCS
# / Azure Blob Storage — with encryption, versioning, and all public access
# blocked by default, plus an optional CDN in front of it. Only ONE
# provider block should be active at a time — AWS is active by default. To
# target a different cloud: comment out the active provider + its
# resources, uncomment the one you want, and set cloud_provider in
# terraform.tfvars accordingly.

locals {
  name = "${var.project_name}-${var.environment}"
}

# --- AWS (active) ---

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "this" {
  bucket = var.aws_bucket_name # required — see variable description, must be globally unique

  tags = merge(var.tags, {
    Name = local.name
  })
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.aws_enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CDN — only created when enable_cdn = true. Reads from the bucket via
# Origin Access Control, so the bucket itself stays fully private.
resource "aws_cloudfront_origin_access_control" "this" {
  count = var.enable_cdn ? 1 : 0

  name                              = local.name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  count = var.enable_cdn ? 1 : 0

  enabled             = true
  price_class         = var.aws_cdn_price_class
  default_root_object = "index.html"

  origin {
    domain_name               = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id                 = local.name
    origin_access_control_id  = aws_cloudfront_origin_access_control.this[0].id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods          = ["GET", "HEAD"]
    target_origin_id       = local.name
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(var.tags, {
    Name = local.name
  })
}

data "aws_iam_policy_document" "cdn_read" {
  count = var.enable_cdn ? 1 : 0

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this[0].arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cdn_read" {
  count = var.enable_cdn ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.cdn_read[0].json
}

# --- GCP (inactive — uncomment to use) ---

# provider "google" {
#   project = var.gcp_project_id
#   region  = var.gcp_region
# }
#
# resource "google_storage_bucket" "this" {
#   name                        = var.gcp_bucket_name # required — must be globally unique
#   location                    = var.gcp_region
#   uniform_bucket_level_access = true
#
#   versioning {
#     enabled = var.aws_enable_versioning
#   }
#
#   labels = var.tags
# }
#
# resource "google_compute_backend_bucket" "this" {
#   count       = var.enable_cdn ? 1 : 0
#   name        = local.name
#   bucket_name = google_storage_bucket.this.name
#   enable_cdn  = true
# }

# --- Azure (inactive — uncomment to use) ---

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
# resource "azurerm_storage_account" "this" {
#   name                     = var.azure_storage_account_name # required — must be globally unique
#   resource_group_name     = azurerm_resource_group.this.name
#   location                = azurerm_resource_group.this.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#
#   blob_properties {
#     versioning_enabled = var.aws_enable_versioning
#   }
#
#   tags = var.tags
# }
#
# resource "azurerm_storage_container" "this" {
#   name                  = var.azure_container_name
#   storage_account_name = azurerm_storage_account.this.name
#   container_access_type = "private"
# }
#
# resource "azurerm_cdn_profile" "this" {
#   count               = var.enable_cdn ? 1 : 0
#   name                = local.name
#   resource_group_name = azurerm_resource_group.this.name
#   location            = "global"
#   sku                 = "Standard_Microsoft"
# }
#
# resource "azurerm_cdn_endpoint" "this" {
#   count               = var.enable_cdn ? 1 : 0
#   name                = local.name
#   profile_name        = azurerm_cdn_profile.this[0].name
#   resource_group_name = azurerm_resource_group.this.name
#   location            = "global"
#
#   origin {
#     name       = "storage"
#     host_name  = azurerm_storage_account.this.primary_blob_host
#   }
# }
