#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"

# Aller dans le dossier infrastructure de besu-lab
cd "$REPO_ROOT/besu-lab/infrastructure"

# Enable Terraform logging
export TF_LOG=INFO
export TF_LOG_PATH="terraform.log"

echo "=== Starting Terraform Provisioning ==="

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Apply infrastructure plan
echo "Applying Terraform configuration..."
terraform apply -auto-approve

echo "=== Terraform Provisioning Completed ==="
