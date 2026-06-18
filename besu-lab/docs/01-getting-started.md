# Getting Started

This guide explains how to initialize and configure the Hyperledger Besu Lab Cluster.

## Step 1: Clone and Initialize
Navigate to the root directory `besu-lab/`.

## Step 2: Validate Prerequisites
Ensure you satisfy all requirements in [Requirements](04-requirements.md).

## Step 3: Run Terraform Provisioning
Navigate to `infrastructure/` and run the wrapper script:
```bash
chmod +x run.sh
./run.sh
```
This will:
1. Initialize the libvirt provider.
2. Download the Debian 13 base image.
3. Provision 5 VMs with double NIC configurations.
4. Dynamically generate the Ansible inventory file in `../configuration/inventory/hosts.ini`.

## Step 4: Run Ansible Configuration
Navigate to `configuration/` and run the playbook:
```bash
ansible-playbook -i inventory/hosts.ini playbook.yml
```
This will:
1. Update system packages, synchronize clocks, and enable UFW rules.
2. Generate TLS certificates and Besu node keys, distributing them securely.
3. Fetch the Besu binary, configure service scripts, initialize genesis, and boot the network.

## Step 5: Verify Cluster Health
To run the automated validation tests across all nodes, run the check playbook:
```bash
ansible-playbook -i inventory/hosts.ini check.yml
```
This script validates:
- Chrony clock synchronization daemon is running.
- The `besu` service status is active and enabled on all hosts.
- Node discovery ports (30303) are listening.
- JSON-RPC HTTPS port (8545) is running on the RPC node.
- Node peering is complete (4 peers found).
- Consensus block minting height is verified and healthy.
