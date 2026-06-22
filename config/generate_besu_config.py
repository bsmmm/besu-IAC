import os
import shutil
import subprocess
import glob
import json
import sys
import yaml

# Resolve paths relative to this script
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
defaults_path = os.path.join(project_root, "config", "settings.yml.default")
settings_path = os.path.join(project_root, "config", "settings.yml")

def deep_merge_and_warn(defaults, user, path=""):
    """
    Recursively merges user dict into defaults dict.
    If a key is missing in user, logs a warning about falling back to defaults.
    """
    merged = {}
    for key, default_val in defaults.items():
        current_path = f"{path}.{key}" if path else key
        if key not in user:
            print(f"[INFO] Parameter '{current_path}' not defined in settings.yml. Falling back to default: {default_val}")
            merged[key] = default_val
        else:
            user_val = user[key]
            if isinstance(default_val, dict) and isinstance(user_val, dict):
                merged[key] = deep_merge_and_warn(default_val, user_val, current_path)
            elif isinstance(default_val, list) and isinstance(user_val, list):
                merged[key] = user_val
            else:
                merged[key] = user_val
                
    for key, user_val in user.items():
        if key not in defaults:
            merged[key] = user_val
            
    return merged

# Load default settings
if not os.path.exists(defaults_path):
    print(f"Error: settings.yml.default not found at {defaults_path}")
    sys.exit(1)

with open(defaults_path) as f:
    defaults = yaml.safe_load(f) or {}

# Load user override settings
if os.path.exists(settings_path):
    with open(settings_path) as f:
        user_settings = yaml.safe_load(f) or {}
else:
    user_settings = {}
    print(f"[INFO] settings.yml not found. Using all default settings.")

# Perform fallback merge
settings = deep_merge_and_warn(defaults, user_settings)


# Paths
base_dir = "/tmp/besu-local-gen"
output_dir = os.path.join(base_dir, "output")
config_file = os.path.join(base_dir, "qbft-config.json")
dist_dir = "/tmp/besu-dist"
metadata_file = os.path.join(dist_dir, "metadata.json")

besu_version = settings["besu"]["version"]
chain_id = int(settings["besu"]["chain_id"])
block_period_seconds = int(settings["besu"]["block_period_seconds"])
request_timeout_seconds = int(settings["besu"]["request_timeout_seconds"])

# Count validators from the infrastructure nodes block
all_nodes = settings["infrastructure"]["nodes"]
validators = [n["name"] for n in all_nodes if "validator" in n.get("roles", [])]
validator_count = len(validators)

metadata = {
    "besu_version": besu_version,
    "chain_id": chain_id,
    "block_period_seconds": block_period_seconds,
    "request_timeout_seconds": request_timeout_seconds,
    "validator_count": validator_count,
    "node_names": sorted([n["name"] for n in all_nodes]),
    "validator_names": sorted(validators),
}

# Check if configuration already exists to preserve keys
if os.path.exists(dist_dir) and os.path.exists(os.path.join(dist_dir, "genesis.json")):
    if os.path.exists(metadata_file):
        with open(metadata_file) as f:
            current_metadata = json.load(f)
        if current_metadata == metadata:
            print("Local Besu configuration already exists. Skipping regeneration to preserve keys.")
            sys.exit(0)
    print("Local Besu generation metadata changed. Regenerating genesis and validator keys.")

# Cleanup
if os.path.exists(base_dir):
    shutil.rmtree(base_dir)
os.makedirs(base_dir)

if os.path.exists(dist_dir):
    shutil.rmtree(dist_dir)
os.makedirs(dist_dir)

# Extract Besu on host
tar_path = f"/tmp/besu-{besu_version}.tar.gz"
subprocess.run(["tar", "-xzf", tar_path, "-C", base_dir], check=True)

# Find extracted folder name
extracted_folders = glob.glob(os.path.join(base_dir, "besu-*"))
if extracted_folders:
    besu_bin_dir = extracted_folders[0]
else:
    besu_bin_dir = base_dir

# Write qbft config file
config_content = {
  "genesis": {
    "config": {
      "chainId": chain_id,
      "qbft": {
        "blockperiodseconds": block_period_seconds,
        "epochlength": 30000,
        "requesttimeoutseconds": request_timeout_seconds
      }
    },
    "nonce": "0x0",
    "timestamp": "0x58ee40ba",
    "gasLimit": "0x1fffffffffffff",
    "difficulty": "0x1",
    "alloc": {}
  },
  "blockchain": {
    "nodes": {
      "generate": True,
      "count": validator_count
    }
  }
}
with open(config_file, "w") as f:
    json.dump(config_content, f, indent=2)

# Run generator
besu_path = os.path.join(besu_bin_dir, "bin", "besu")
subprocess.run([besu_path, "operator", "generate-blockchain-config", f"--config-file={config_file}", f"--to={output_dir}"], check=True)

# Copy genesis
shutil.copy(os.path.join(output_dir, "genesis.json"), os.path.join(dist_dir, "genesis.json"))

# Map generated keys to validators
keys_parent = os.path.join(output_dir, "keys")
generated_key_dirs = sorted(os.listdir(keys_parent))

for i, val_name in enumerate(validators):
    src_dir = os.path.join(keys_parent, generated_key_dirs[i])
    dest_dir = os.path.join(dist_dir, val_name)
    os.makedirs(dest_dir)
    shutil.copy(os.path.join(src_dir, "key.priv"), os.path.join(dest_dir, "key"))
    shutil.copy(os.path.join(src_dir, "key.pub"), os.path.join(dest_dir, "key.pub"))
    with open(os.path.join(dest_dir, "key.address"), "w") as f:
        f.write(generated_key_dirs[i])

# Generate keys for non-validators dynamically
for node in all_nodes:
    node_name = node["name"]
    if node_name not in validators:
        node_dest_dir = os.path.join(dist_dir, node_name)
        os.makedirs(node_dest_dir, exist_ok=True)
        subprocess.run([
            besu_path, f"--data-path={node_dest_dir}",
            "public-key", "export",
            f"--to={os.path.join(node_dest_dir, 'key.pub')}"
        ], check=True)

with open(metadata_file, "w") as f:
    json.dump(metadata, f, indent=2)

print("Local Besu generation and mapping completed successfully!")
