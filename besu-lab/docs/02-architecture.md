# Architecture

This document describes the 5-node Hyperledger Besu cluster topology and networking layout.

## 1. Network Layout

We utilize a double-NIC configuration for each virtual machine to combine security, connectivity, and local reachability:

* **NIC 1 (`enp1s0`):** Mapped to the `default` NAT switch (`virbr0`) with DHCP. Used exclusively for internet access (installing packages, synchronizing chrony).
* **NIC 2 (`enp2s0`):** Mapped to an isolated bridge (`virbr1` - `isolated-lan`) with static IPs (`10.10.10.11` to `10.10.10.15`). Used for secure peer-to-peer Besu node synchronization, TLS communication, and administration from the hypervisor host (`10.10.10.1`).

## 2. Cluster Nodes

The network consists of 5 nodes running Hyperledger Besu with the QBFT consensus algorithm:

| Node Name | IP (isolated-lan) | Role |
|-----------|--------------------|------|
| `validator-1` | `10.10.10.11` | QBFT Validator |
| `validator-2` | `10.10.10.12` | QBFT Validator |
| `validator-3` | `10.10.10.13` | QBFT Validator |
| `validator-4` | `10.10.10.14` | QBFT Validator |
| `rpc-node` | `10.10.10.15` | Non-validating RPC / WS Reader/Writer |

## 3. Consensus Mechanism

* **Consensus Engine:** QBFT (Istanbul Byzantine Fault Tolerant variant).
* **Block Time:** 2 seconds.
* **Epoch Length:** 30,000 blocks.
* **Native TLS:** Used to secure JSON-RPC and P2P communication channels.
