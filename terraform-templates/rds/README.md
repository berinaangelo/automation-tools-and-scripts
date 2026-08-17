# rds Terraform template

Starting point for a managed relational database — AWS RDS / GCP Cloud SQL /
Azure Flexible Server. Copy this directory per project and trim it down to
what that system actually needs.

## Layout

- `versions.tf` — Terraform + provider version pins, backend stub (commented).
- `variables.tf` — common vars (`multi_az`) plus per-provider vars
  (AWS/GCP/Azure), including engine, sizing, and network inputs.
- `main.tf` — provider blocks + subnet group + DB instance per cloud.
  **AWS is active by default**; GCP and Azure blocks are commented out.
- `outputs.tf` — outputs for the active provider's resources.
- `terraform.tfvars.example` — copy to `terraform.tfvars` and fill in
  (gitignored, so real values never get committed).

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars — subnet IDs, security group IDs, and password
# are required, none have usable defaults

export TF_VAR_aws_db_password="..."   # prefer this over putting it in tfvars

terraform init
terraform plan
terraform apply
```

Subnet IDs and the internal security group come from the `networking`
template's outputs — see that template's README for which output maps to
which variable here.

## Switching cloud provider

Only one provider should be active at a time:

1. In `main.tf`, comment out the currently active provider block + its
   resources.
2. Uncomment the target provider's block + resources.
3. In `outputs.tf`, swap the active outputs to match.
4. Set `cloud_provider` in `terraform.tfvars` (documentation only — it
   doesn't gate resources, the comment/uncomment in step 1–2 does).

## Notes

- `aws_db_engine` is intentionally user-defined rather than restricted to a
  fixed list — RDS supports many engines and this template doesn't validate
  engine-specific option/parameter groups for you.
- `aws_db_port` is optional — leave it null to fall back to the standard
  port for the chosen engine (5432 for postgres, 3306 for mysql/mariadb).
- `multi_az` is off by default to keep a first apply cheap. Flip to `true`
  for anything production-facing.
- `aws_db_password` / `gcp_db_password` / `azure_db_admin_password` have no
  usable default on purpose — set them via `TF_VAR_*` environment variables,
  not `terraform.tfvars`, to avoid ever writing a real password to disk.
- Azure has a separate resource type per engine
  (`azurerm_postgresql_flexible_server` vs `azurerm_mysql_flexible_server`)
  — the commented block here shows PostgreSQL; swap the resource type for
  MySQL.
- Never hardcode credentials here — use provider-standard auth (AWS
  profiles/env vars, `gcloud auth`, `az login`, or CI secrets) for the
  provider itself, and `TF_VAR_*`/secrets managers for the DB password.
