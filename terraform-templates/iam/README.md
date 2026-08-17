# iam Terraform template

Starting point for a reusable identity + permissions — an AWS IAM role +
instance profile, a GCP service account, or an Azure user-assigned managed
identity. Copy this directory per project and trim it down to what that
system actually needs.

## Layout

- `versions.tf` — Terraform + provider version pins, backend stub (commented).
- `variables.tf` — common vars plus per-provider vars (AWS/GCP/Azure).
- `main.tf` — provider blocks + role/service account/identity + policy
  attachments per cloud. **AWS is active by default**; GCP and Azure blocks
  are commented out.
- `outputs.tf` — outputs for the active provider's resources.
- `terraform.tfvars.example` — copy to `terraform.tfvars` and fill in
  (gitignored, so real values never get committed).

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars — at minimum set aws_iam_trusted_service and
# aws_iam_managed_policy_arns for what this role is actually for

terraform init
terraform plan
terraform apply
```

This template's `instance_profile_name` output feeds an EC2 launch
template's `iam_instance_profile` — e.g. add an `iam_instance_profile`
block to the `autoscaling` template's `aws_launch_template.this` pointing
at it.

## Switching cloud provider

Only one provider should be active at a time:

1. In `main.tf`, comment out the currently active provider block + its
   resources.
2. Uncomment the target provider's block + resources.
3. In `outputs.tf`, swap the active outputs to match.
4. Set `cloud_provider` in `terraform.tfvars` (documentation only — it
   doesn't gate resources, the comment/uncomment in step 1–2 does).

## Notes

- `aws_iam_trusted_service` is user-defined on purpose — this role isn't
  assumed to be for EC2 specifically. Set it to whatever service
  (`ecs-tasks.amazonaws.com`, `lambda.amazonaws.com`, ...) will actually
  assume it.
- With no managed policies or inline policy attached, the role can only
  assume itself — it has no permissions until you add
  `aws_iam_managed_policy_arns` and/or `aws_iam_inline_policy_json`.
- Prefer AWS managed policies (`aws_iam_managed_policy_arns`) over inline
  policies wherever one covers the need — they're easier to audit and keep
  current.
- Never hardcode credentials here — use provider-standard auth (AWS
  profiles/env vars, `gcloud auth`, `az login`, or CI secrets).
