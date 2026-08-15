#!/usr/bin/env bash
# Wraps fmt/init/validate/plan/apply with a confirm gate.
# Usage: ./tf-plan-apply.sh [terraform-dir]   (defaults to cwd)
set -euo pipefail

TF_DIR="${1:-.}"
cd "$TF_DIR"

echo "==> terraform fmt -check"
terraform fmt -check -recursive || {
  echo "Files not formatted. Run 'terraform fmt -recursive' first." >&2
  exit 1
}

echo "==> terraform init"
terraform init -input=false

echo "==> terraform validate"
terraform validate

PLAN_FILE="tfplan-$(date +%Y%m%d-%H%M%S)"
echo "==> terraform plan"
terraform plan -input=false -out="$PLAN_FILE"

read -r -p "Apply this plan? [y/N] " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  terraform apply -input=false "$PLAN_FILE"
  rm -f "$PLAN_FILE"
else
  echo "Not applied. Plan saved at $PLAN_FILE — rerun 'terraform apply $PLAN_FILE' when ready."
fi
