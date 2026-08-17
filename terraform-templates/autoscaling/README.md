# autoscaling Terraform template

Starting point for a scale-out compute group — AWS Auto Scaling Group / GCP
Managed Instance Group / Azure Virtual Machine Scale Set — with a CPU-based
target-tracking scaling policy. Copy this directory per project and trim it
down to what that system actually needs.

## Layout

- `versions.tf` — Terraform + provider version pins, backend stub (commented).
- `variables.tf` — common vars (min/max/desired size, target CPU) plus
  per-provider vars (AWS/GCP/Azure).
- `main.tf` — provider blocks + launch template/instance template + scaling
  group + CPU target-tracking policy per cloud. **AWS is active by
  default**; GCP and Azure blocks are commented out.
- `outputs.tf` — outputs for the active provider's resources.
- `terraform.tfvars.example` — copy to `terraform.tfvars` and fill in
  (gitignored, so real values never get committed).

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars — aws_vpc_zone_identifiers is required, no default

terraform init
terraform plan
terraform apply
```

Subnet IDs (and, once you're behind a load balancer, target group ARNs)
come from the `networking` template's outputs — see that template's README
for which output maps to which variable here.

## Switching cloud provider

Only one provider should be active at a time:

1. In `main.tf`, comment out the currently active provider block + its
   resources.
2. Uncomment the target provider's block + resources.
3. In `outputs.tf`, swap the active outputs to match.
4. Set `cloud_provider` in `terraform.tfvars` (documentation only — it
   doesn't gate resources, the comment/uncomment in step 1–2 does).

## Notes

- `aws_vpc_zone_identifiers` has no usable default — the ASG has no subnets
  to fall back to. Set it before applying.
- `target_cpu_utilization` drives a target-tracking policy on average CPU.
  Swap the `aws_autoscaling_policy` block for a step-scaling or
  request-count-per-target policy if CPU isn't the right signal for this
  workload.
- `aws_target_group_arns` is optional — leave it empty until there's an ALB/
  NLB target group to attach.
- Never hardcode credentials here — use provider-standard auth (AWS
  profiles/env vars, `gcloud auth`, `az login`, or CI secrets).
