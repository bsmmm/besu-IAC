# Hyperledger Besu Lab Cluster (QBFT, 4 Validators, 1 RPC)

This repository automates the creation of a local, production-ready, 5-node Hyperledger Besu blockchain cluster running the QBFT consensus mechanism. The nodes are provisioned on KVM/QEMU using Terraform, and configured securely with Ansible.

## Documentation Structure

For detailed setup instructions and specifications, please refer to the following documentation in the `docs/` folder:

* **[Getting Started](docs/01-getting-started.md)**: Steps to run Terraform provisioning and Ansible configuration.
* **[Architecture](docs/02-architecture.md)**: Overview of the 5-node topology, IP layout, dual-NIC setup, and QBFT settings.
* **[Debugging Tips](docs/03-debugging-tips.md)**: Quick commands for VM console, network troubleshooting, and querying Besu nodes.
* **[System Requirements](docs/04-requirements.md)**: Package dependencies, network setup, and permissions required on the Debian 13 host.

## Quick Run

```bash
# Phase 2: Provision VMs
cd infrastructure
chmod +x run.sh
./run.sh

# Phase 3: Configure and Start Cluster
cd ../configuration
ansible-playbook -i inventory/hosts.ini playbook.yml

# Phase 4: Run Health Check Playbook
ansible-playbook -i inventory/hosts.ini check.yml
```
