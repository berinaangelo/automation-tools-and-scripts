# system-setup Terraform template

Starting point for provisioning infrastructure for a new system. Copy this
directory per project and trim it down to what that system actually needs.

## Layout

- `versions.tf` — Terraform + provider version pins, backend stub (commented).
- `variables.tf` — common vars plus per-provider vars (AWS/GCP/Azure).
- `main.tf` — provider blocks + one example compute resource per cloud.
  **AWS is active by default**; GCP and Azure blocks are commented out.
- `outputs.tf` — outputs for the active provider's resources.
- `terraform.tfvars.example` — copy to `terraform.tfvars` and fill in
  (gitignored, so real values never get committed).

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars

terraform init
terraform plan
terraform apply
```

## Switching cloud provider

Only one provider should be active at a time:

1. In `main.tf`, comment out the currently active provider block + its
   example resource.
2. Uncomment the target provider's block + resource.
3. In `outputs.tf`, swap the active outputs to match.
4. Set `cloud_provider` in `terraform.tfvars` (documentation only — it
   doesn't gate resources, the comment/uncomment in step 1–2 does).

## Notes

- The example resources (`aws_instance`, `google_compute_instance`,
  `azurerm_linux_virtual_machine`) are placeholders — swap for whatever the
  system needs (containers, managed DB, networking, etc.).
- Never hardcode credentials here — use provider-standard auth (AWS
  profiles/env vars, `gcloud auth`, `az login`, or CI secrets).
