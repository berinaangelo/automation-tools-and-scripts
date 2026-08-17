# container-orchestration Terraform template

Starting point for running a container as a managed service — AWS ECS on
Fargate, GCP Cloud Run, or Azure Container Apps. All three are
serverless/managed container runtimes, not a full Kubernetes cluster —
if you actually need EKS/GKE/AKS, that's a heavier setup this template
doesn't cover. Copy this directory per project and trim it down to what
that system actually needs.

## Layout

- `versions.tf` — Terraform + provider version pins, backend stub (commented).
- `variables.tf` — common vars (`container_port`, environment variables,
  `desired_count`) plus per-provider vars (AWS/GCP/Azure).
- `main.tf` — provider blocks + cluster/service + task execution role per
  cloud. **AWS is active by default**; GCP and Azure blocks are commented
  out.
- `outputs.tf` — outputs for the active provider's resources.
- `terraform.tfvars.example` — copy to `terraform.tfvars` and fill in
  (gitignored, so real values never get committed).

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars — aws_container_image, aws_subnet_ids, and
# aws_security_group_ids are required

terraform init
terraform plan
terraform apply
```

`aws_subnet_ids` and `aws_security_group_ids` come from the `networking`
template's outputs. `aws_target_group_arn` (optional) comes from the
`load-balancer` template — set it to register tasks with a load balancer
instead of running the service standalone. `aws_task_role_arn` (optional)
comes from the `iam` template, built with
`aws_iam_trusted_service = "ecs-tasks.amazonaws.com"`, if the running
container needs its own AWS permissions.

## Switching cloud provider

Only one provider should be active at a time:

1. In `main.tf`, comment out the currently active provider block + its
   resources.
2. Uncomment the target provider's block + resources.
3. In `outputs.tf`, swap the active outputs to match.
4. Set `cloud_provider` in `terraform.tfvars` (documentation only — it
   doesn't gate resources, the comment/uncomment in step 1–2 does).

## Notes

- This template creates its own **task execution role** (image pull +
  CloudWatch logging permissions) — that's separate from
  `aws_task_role_arn`, which is for the application's own AWS permissions
  and is optional/external (from the `iam` template).
- `aws_cpu`/`aws_memory` must be a valid Fargate CPU/memory combination —
  see AWS's Fargate task size table if you change the defaults.
- `gcp_allow_unauthenticated` and Container Apps' `ingress.external_enabled`
  both default to not-publicly-reachable — flip them deliberately, not by
  default.
- Never hardcode credentials or container registry tokens here — use
  provider-standard auth (AWS profiles/env vars, `gcloud auth`, `az login`,
  or CI secrets) and IAM/workload-identity-based registry access instead.
