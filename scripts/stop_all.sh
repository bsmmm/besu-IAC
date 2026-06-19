#!/usr/bin/env bash

# Script to stop the monitoring stack and power off virtual machines without destroying them.
# Location: scripts/stop_all.sh

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0;0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. Stop the Docker Compose observability stack
log_info "Stopping Docker Compose monitoring stack..."
if [ -f "$REPO_ROOT/monitoring/docker-compose.yml" ]; then
    docker compose -f "$REPO_ROOT/monitoring/docker-compose.yml" stop
    log_success "Monitoring stack stopped."
else
    log_warn "monitoring/docker-compose.yml not found. Skipping Docker stop."
fi

# 2. Stop the KVM/libvirt virtual machines
log_info "Stopping KVM/libvirt virtual machines..."
nodes=(
    "validator-1"
    "validator-2"
    "validator-3"
    "validator-4"
    "rpc-node"
)

for node in "${nodes[@]}"; do
    if virsh -c qemu:///system dominfo "$node" >/dev/null 2>&1; then
        state=$(virsh -c qemu:///system domstate "$node" 2>/dev/null || echo "unknown")
        if [ "$state" = "running" ]; then
            log_info "Powering off VM: $node..."
            virsh -c qemu:///system destroy "$node" >/dev/null
            log_success "VM $node stopped."
        else
            log_info "VM $node is already in state: $state."
        fi
    else
        log_warn "VM $node does not exist in libvirt qemu:///system. Skipping."
    fi
done

log_success "All services and virtual machines have been stopped successfully."
