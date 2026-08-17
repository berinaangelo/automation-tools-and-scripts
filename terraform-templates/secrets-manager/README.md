# secrets-manager Terraform template

Starting point for a single managed secret — AWS Secrets Manager, GCP
Secret Manager, or an Azure Key Vault secret. Copy this directory per
project and trim it down to what that system actually needs.

## Layout

- `versions.tf` — Terraform + provider version pins, backend stub (commented).
- `variables.tf` — common vars (`secret_description`) plus per-provider
  vars (AWS/GCP/Azure).
- `main.tf` — provider blocks + secret container + secret version per
  cloud. **AWS is active by default**; GCP and Azure blocks are commented
  out.
- `outputs.tf` — outputs for the active provider's resources.
- `terraform.tfvars.example` — copy to `terraform.tfvars` and fill in
  (gitignored, so real values never get committed).

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars

export TF_VAR_aws_secret_value="..."  # prefer this over putting it in tfvars

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

- **Terraform state will contain the secret value in plaintext**, regardless
  of how it's supplied — this is a fundamental Terraform limitation, not
  something this template can work around. Keep state encrypted at rest
  (a remote backend like S3+KMS) and tightly access-controlled. For
  anything highly sensitive, consider having an external process write the
  secret value out-of-band and only managing the secret's metadata here.
- `*_secret_value` variables have no usable default on purpose — set them
  via `TF_VAR_*` environment variables, not `terraform.tfvars`, to keep the
  value out of any file on disk.
- For structured secrets (multiple key/value pairs, e.g. DB credentials),
  pass a `jsonencode({...})` string as the value rather than adding more
  variables — this template stores one opaque string/blob per secret.
- Azure Key Vault is a container resource, unlike AWS/GCP's flat secret
  namespace — the commented Azure block creates the vault itself, not just
  the secret.
- Never hardcode credentials here — use provider-standard auth (AWS
  profiles/env vars, `gcloud auth`, `az login`, or CI secrets) for the
  provider itself.
