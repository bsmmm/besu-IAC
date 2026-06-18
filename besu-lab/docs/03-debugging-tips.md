# Debugging Tips

Here are common issues and debugging steps for managing the Hyperledger Besu cluster.

## 1. Checking VM Status
Use `virsh` on the hypervisor host to check the status of the guest domains:
```bash
sudo virsh list --all
```

## 2. Direct Console Access
If a node is unreachable via SSH, connect via the serial console:
```bash
sudo virsh console validator-1
```
*(Press `Enter` to show the login prompt. Exit console by pressing `Ctrl + ]`)*

## 3. Reviewing cloud-init Logs
If the system configuration or SSH keys fail to deploy, check the logs on the guest:
```bash
tail -f /var/log/cloud-init-output.log
```

## 4. Querying Besu Node status
Verify the local peer counts and sync progress from the host or other nodes:
```bash
curl -k -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  https://10.10.10.15:8545
```
*(Note: `-k` is required since certificates are self-signed).*

## 5. Cleaning SSH host keys
If VM IP addresses are reused, clear cached SSH fingerprints:
```bash
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "10.10.10.11"
```
