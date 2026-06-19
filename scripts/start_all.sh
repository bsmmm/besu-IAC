#!/usr/bin/env bash

# Script to start the virtual machines and resume the monitoring stack without recreating them.
# Location: scripts/start_all.sh

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

# 1. Start the KVM/libvirt virtual machines
log_info "Starting KVM/libvirt virtual machines..."
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
        if [ "$state" != "running" ]; then
            log_info "Starting VM: $node..."
            virsh -c qemu:///system start "$node" >/dev/null
            log_success "VM $node started."
        else
            log_info "VM $node is already running."
        fi
    else
        log_warn "VM $node does not exist in libvirt qemu:///system. Skipping."
    fi
done

# Wait a moment for network interfaces to initialize
log_info "Waiting 15 seconds for VM network services to initialize..."
sleep 15

# 2. Start the Docker Compose observability stack
log_info "Starting Docker Compose monitoring stack..."
if [ -f "$REPO_ROOT/monitoring/docker-compose.yml" ]; then
    docker compose -f "$REPO_ROOT/monitoring/docker-compose.yml" start
    log_success "Monitoring stack started."
else
    log_warn "monitoring/docker-compose.yml not found. Skipping Docker start."
fi

log_success "All virtual machines and observability services have been started successfully."
