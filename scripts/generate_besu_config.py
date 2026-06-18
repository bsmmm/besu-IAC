import os
import shutil
import subprocess
import glob
import json
import sys

# Paths
base_dir = "/tmp/besu-local-gen"
output_dir = os.path.join(base_dir, "output")
config_file = os.path.join(base_dir, "qbft-config.json")
dist_dir = "/tmp/besu-dist"
metadata_file = os.path.join(dist_dir, "metadata.json")

besu_version = os.environ.get("BESU_LAB_VERSION", "24.12.0")
chain_id = int(os.environ.get("BESU_LAB_CHAIN_ID", "1337"))
block_period_seconds = int(os.environ.get("BESU_LAB_BLOCK_PERIOD_SECONDS", "2"))
request_timeout_seconds = int(os.environ.get("BESU_LAB_REQUEST_TIMEOUT_SECONDS", "4"))
validator_count = int(os.environ.get("BESU_LAB_VALIDATOR_COUNT", "4"))

metadata = {
    "besu_version": besu_version,
    "chain_id": chain_id,
    "block_period_seconds": block_period_seconds,
    "request_timeout_seconds": request_timeout_seconds,
    "validator_count": validator_count,
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

# Write config file
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

validators = [f"validator-{i}" for i in range(1, validator_count + 1)]
for i, val_name in enumerate(validators):
    src_dir = os.path.join(keys_parent, generated_key_dirs[i])
    dest_dir = os.path.join(dist_dir, val_name)
    os.makedirs(dest_dir)
    shutil.copy(os.path.join(src_dir, "key.priv"), os.path.join(dest_dir, "key"))
    shutil.copy(os.path.join(src_dir, "key.pub"), os.path.join(dest_dir, "key.pub"))
    with open(os.path.join(dest_dir, "key.address"), "w") as f:
        f.write(generated_key_dirs[i])

with open(metadata_file, "w") as f:
    json.dump(metadata, f, indent=2)

print("Local Besu generation and mapping completed successfully!")
