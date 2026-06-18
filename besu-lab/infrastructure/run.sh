#!/usr/bin/env bash
set -euo pipefail

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
