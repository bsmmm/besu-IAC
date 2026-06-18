import os
import shutil
import subprocess
import glob

# Paths
base_dir = "/tmp/besu-local-gen"
output_dir = os.path.join(base_dir, "output")
config_file = os.path.join(base_dir, "qbft-config.json")
dist_dir = "/tmp/besu-dist"

# Check if configuration already exists to preserve keys
if os.path.exists(dist_dir) and os.path.exists(os.path.join(dist_dir, "genesis.json")):
    print("Local Besu configuration already exists. Skipping regeneration to preserve keys.")
    import sys
    sys.exit(0)

# Cleanup
if os.path.exists(base_dir):
    shutil.rmtree(base_dir)
os.makedirs(base_dir)

if os.path.exists(dist_dir):
    shutil.rmtree(dist_dir)
os.makedirs(dist_dir)

# Extract Besu on host
tar_path = "/tmp/besu-24.12.0.tar.gz"
subprocess.run(["tar", "-xzf", tar_path, "-C", base_dir], check=True)

# Find extracted folder name (it's besu-24.12.0)
extracted_folders = glob.glob(os.path.join(base_dir, "besu-*"))
if extracted_folders:
    besu_bin_dir = extracted_folders[0]
else:
    besu_bin_dir = base_dir

# Write config file
config_content = """{
  "genesis": {
    "config": {
      "chainId": 1337,
      "qbft": {
        "blockperiodseconds": 2,
        "epochlength": 30000,
        "requesttimeoutseconds": 4
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
      "generate": true,
      "count": 4
    }
  }
}"""
with open(config_file, "w") as f:
    f.write(config_content)

# Run generator
besu_path = os.path.join(besu_bin_dir, "bin", "besu")
subprocess.run([besu_path, "operator", "generate-blockchain-config", f"--config-file={config_file}", f"--to={output_dir}"], check=True)

# Copy genesis
shutil.copy(os.path.join(output_dir, "genesis.json"), os.path.join(dist_dir, "genesis.json"))

# Map generated keys to validators
keys_parent = os.path.join(output_dir, "keys")
generated_key_dirs = sorted(os.listdir(keys_parent))

validators = ["validator-1", "validator-2", "validator-3", "validator-4"]
for i, val_name in enumerate(validators):
    src_dir = os.path.join(keys_parent, generated_key_dirs[i])
    dest_dir = os.path.join(dist_dir, val_name)
    os.makedirs(dest_dir)
    # Copy key and key.pub
    shutil.copy(os.path.join(src_dir, "key.priv"), os.path.join(dest_dir, "key"))
    shutil.copy(os.path.join(src_dir, "key.pub"), os.path.join(dest_dir, "key.pub"))
    # Save the address (directory name)
    with open(os.path.join(dest_dir, "key.address"), "w") as f:
        f.write(generated_key_dirs[i])

print("Local Besu generation and mapping completed successfully!")
