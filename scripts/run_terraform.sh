#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"

# Aller dans le dossier infrastructure de besu-lab
cd "$REPO_ROOT/terraform"

# Parse logging settings using python helper
get_setting() {
    python3 -c "
import yaml, os
defaults = yaml.safe_load(open('$REPO_ROOT/config/settings.yml.default')) or {}
user = yaml.safe_load(open('$REPO_ROOT/config/settings.yml')) if os.path.exists('$REPO_ROOT/config/settings.yml') else {}
def get_val(d, u, keys):
    if not keys: return d
    k = keys[0]
    val_d = d.get(k) if isinstance(d, dict) else None
    val_u = u.get(k) if isinstance(u, dict) else None
    if isinstance(val_d, dict):
        return get_val(val_d, val_u or {}, keys[1:])
    return val_u if val_u is not None else val_d
print(get_val(defaults, user, '$1'.split('.')))
"
}

# Enable Terraform logging
export TF_LOG="$(get_setting 'logging.terraform_log_level')"
export TF_LOG_PATH="$(get_setting 'logging.terraform_log_path')"

echo "=== Starting Terraform Provisioning ==="

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Apply infrastructure plan
echo "Applying Terraform configuration..."
terraform apply -auto-approve

echo "=== Terraform Provisioning Completed ==="
