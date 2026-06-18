# System Requirements

Before deploying, ensure the hypervisor host meets the following prerequisites:

## Hypervisor OS
- Debian 13 (Trixie) or compatible Linux distribution.

## Installed Packages
The host system must have the following utilities installed and configured:
1. **QEMU / KVM & Libvirt:**
   ```bash
   sudo apt update && sudo apt install -y qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients virtinst bridge-utils
   ```
2. **Terraform:**
   - Terraform v1.5.0+ installed on host.
3. **Ansible:**
   - Ansible v2.12+ installed on host.

## Network Interfaces
- An active bridge `virbr0` for Default NAT network (`192.168.122.0/24`).
- An active bridge `virbr1` for the isolated private network (`10.10.10.0/24`) configured under the name `isolated-lan`.

## User Group Memberships
The user executing Terraform and Ansible playbooks must belong to the `libvirt` and `kvm` groups:
```bash
sudo usermod -aG libvirt,kvm $USER
newgrp libvirt
```
