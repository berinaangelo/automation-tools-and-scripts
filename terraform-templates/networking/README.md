# networking Terraform template

Starting point for a VPC/VNet: public + private subnets, internet egress for
both tiers (IGW for public, NAT for private), and baseline security groups.
Copy this directory per project and trim it down to what that system
actually needs.

## Layout

- `versions.tf` — Terraform + provider version pins, backend stub (commented).
- `variables.tf` — common vars plus per-provider vars (AWS/GCP/Azure).
- `main.tf` — provider blocks + VPC, subnets, routing, NAT, and baseline
  security groups per cloud. **AWS is active by default**; GCP and Azure
  blocks are commented out.
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

## Wiring into the other templates

This template's state doesn't feed the `autoscaling` or `rds` templates
automatically — they're separate root modules with separate state. After
applying here, copy the relevant outputs into the other template's
`terraform.tfvars`:

- `private_subnet_ids` → `aws_vpc_zone_identifiers` (autoscaling) and
  `aws_db_subnet_group_subnet_ids` (rds)
- `internal_security_group_id` → `aws_vpc_security_group_ids` (rds)
- `public_subnet_ids` / `web_security_group_id` → wherever a load balancer
  or public-facing tier gets added

(If you'd rather wire these automatically, convert this into a proper
Terraform module and `terraform_remote_state`/output references instead of
copy-pasting IDs.)

## Switching cloud provider

Only one provider should be active at a time:

1. In `main.tf`, comment out the currently active provider block + its
   resources.
2. Uncomment the target provider's block + resources.
3. In `outputs.tf`, swap the active outputs to match.
4. Set `cloud_provider` in `terraform.tfvars` (documentation only — it
   doesn't gate resources, the comment/uncomment in step 1–2 does).

## Notes

- `aws_single_nat_gateway = true` (default) uses one shared NAT gateway for
  all private subnets — cheaper but a single point of failure. Set `false`
  for one NAT gateway per AZ in production.
- The `web` security group is intentionally broad (0.0.0.0/0 on 80/443) —
  narrow it further per app rather than reusing it for anything beyond an
  internet-facing HTTP(S) tier.
- Never hardcode credentials here — use provider-standard auth (AWS
  profiles/env vars, `gcloud auth`, `az login`, or CI secrets).
