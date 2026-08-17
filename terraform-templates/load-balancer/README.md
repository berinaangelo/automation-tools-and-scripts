# load-balancer Terraform template

Starting point for a load balancer + target group — AWS ALB/NLB, GCP
external HTTP(S) LB, or Azure Standard Load Balancer — in front of the
`autoscaling` template's scaling group. Copy this directory per project and
trim it down to what that system actually needs.

## Layout

- `versions.tf` — Terraform + provider version pins, backend stub (commented).
- `variables.tf` — common vars plus per-provider vars (AWS/GCP/Azure).
- `main.tf` — provider blocks + load balancer, target group/backend
  service, and listeners per cloud. **AWS is active by default**; GCP and
  Azure blocks are commented out.
- `outputs.tf` — outputs for the active provider's resources.
- `terraform.tfvars.example` — copy to `terraform.tfvars` and fill in
  (gitignored, so real values never get committed).

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars — aws_vpc_id and aws_subnet_ids are required

terraform init
terraform plan
terraform apply
```

`aws_vpc_id`, `aws_subnet_ids`, and `aws_security_group_ids` come from the
`networking` template's outputs. This template's `target_group_arn` output
feeds the `autoscaling` template's `aws_target_group_arns` variable —
apply this template first, then pass its output into that one.

## Switching cloud provider

Only one provider should be active at a time:

1. In `main.tf`, comment out the currently active provider block + its
   resources.
2. Uncomment the target provider's block + resources.
3. In `outputs.tf`, swap the active outputs to match.
4. Set `cloud_provider` in `terraform.tfvars` (documentation only — it
   doesn't gate resources, the comment/uncomment in step 1–2 does).

## Notes

- `aws_lb_type = "application"` (default) gives you an ALB (L7/HTTP,
  supports path-based routing, security groups, HTTPS termination).
  `"network"` gives you an NLB (L4/TCP, higher throughput, no security
  groups).
- `aws_enable_https` requires `aws_certificate_arn` (an ACM certificate) —
  neither has a usable default since both are account/domain-specific.
- The GCP block shows a regional external Application Load Balancer
  (HTTP); the Azure block shows a Standard Load Balancer (L4) — the closer
  analog to an NLB. For Azure L7/HTTP routing comparable to an ALB, use
  Application Gateway instead (not templated here).
- Never hardcode credentials here — use provider-standard auth (AWS
  profiles/env vars, `gcloud auth`, `az login`, or CI secrets).
