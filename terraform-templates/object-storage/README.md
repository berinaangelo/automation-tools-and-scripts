# object-storage Terraform template

Starting point for a private object storage bucket — S3 / GCS / Azure Blob
Storage — encrypted, versioned, and fully blocked from public access by
default, with an optional CDN in front of it. Copy this directory per
project and trim it down to what that system actually needs.

## Layout

- `versions.tf` — Terraform + provider version pins, backend stub (commented).
- `variables.tf` — common vars (`enable_cdn`) plus per-provider vars
  (AWS/GCP/Azure).
- `main.tf` — provider blocks + bucket/container + encryption/versioning/
  public-access-block + optional CDN per cloud. **AWS is active by
  default**; GCP and Azure blocks are commented out.
- `outputs.tf` — outputs for the active provider's resources.
- `terraform.tfvars.example` — copy to `terraform.tfvars` and fill in
  (gitignored, so real values never get committed).

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars — aws_bucket_name is required and must be globally
# unique

terraform init
terraform plan
terraform apply
```

## Switching cloud provider

Only one provider should be active at a time:

1. In `main.tf`, comment out the currently active provider block + its
   resources.
2. Uncomment the target provider's block + resources.
3. In `outputs.tf`, swap the active outputs to match.
4. Set `cloud_provider` in `terraform.tfvars` (documentation only — it
   doesn't gate resources, the comment/uncomment in step 1–2 does).

## Notes

- Bucket/storage-account names have no default anywhere in this template —
  they're globally unique namespaces (across all AWS accounts / GCP
  projects / Azure tenants), so a generic default would collide for most
  people.
- The bucket stays fully private (`aws_s3_bucket_public_access_block` blocks
  all public access) even with the CDN enabled — CloudFront reads via
  Origin Access Control, not a public bucket policy.
- `enable_cdn = false` by default — flip it on once there's actually
  something to serve; it adds a CloudFront distribution, OAC, and the bucket
  policy that authorizes it.
- Never hardcode credentials here — use provider-standard auth (AWS
  profiles/env vars, `gcloud auth`, `az login`, or CI secrets).
