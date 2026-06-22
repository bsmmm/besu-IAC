#!/usr/bin/env bash
set -euo pipefail
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITORING_DIR="$(cd "$SCRIPTS_DIR/../monitoring" && pwd)"

echo "Assembling trusted CA bundle..."
mkdir -p "$MONITORING_DIR/certs"

if [[ -f "$MONITORING_DIR/certs/rpc-node.crt" ]]; then
  if [[ -f /etc/ssl/certs/ca-certificates.crt ]]; then
    cat /etc/ssl/certs/ca-certificates.crt "$MONITORING_DIR/certs/rpc-node.crt" > "$MONITORING_DIR/certs/combined-ca-bundle.crt"
  else
    cat "$MONITORING_DIR/certs/rpc-node.crt" > "$MONITORING_DIR/certs/combined-ca-bundle.crt"
  fi
  echo "CA bundle updated successfully."
else
  echo "WARNING: rpc-node.crt not found. Copying standard CA bundle..."
  if [[ -f /etc/ssl/certs/ca-certificates.crt ]]; then
    cp /etc/ssl/certs/ca-certificates.crt "$MONITORING_DIR/certs/combined-ca-bundle.crt"
  else
    touch "$MONITORING_DIR/certs/combined-ca-bundle.crt"
  fi
fi

echo "Generating dynamic monitoring configurations..."
python3 "$SCRIPTS_DIR/generate_monitoring_config.py"

echo "Starting Docker Compose monitoring stack..."
docker compose -f "$MONITORING_DIR/docker-compose.yml" up -d

# Self-Healing Check for Blockchain Reset
echo "Performing blockchain height verification..."
# Allow Blockscout a moment if it was already running to query its health endpoint
if curl -s --max-time 2 http://localhost:4000/api/v2/stats > /dev/null; then
  db_block=$(curl -s http://localhost:4000/api/v2/stats | grep -o '"total_blocks":"[0-9]*"' | cut -d'"' -f4 || echo "0")
  if [[ -z "$db_block" ]]; then
    db_block=0
  fi

  # Query current RPC block height from the load balancer proxy
  rpc_block_hex=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545 | grep -o '"result":"[^"]*"' | cut -d'"' -f4 || echo "")
  if [[ ! -z "$rpc_block_hex" && "$rpc_block_hex" != "null" ]]; then
    rpc_block_dec=$((rpc_block_hex))
  else
    rpc_block_dec=0
  fi

  if (( db_block > rpc_block_dec )); then
    echo "Blockchain reset detected (RPC node block height: $rpc_block_dec, Explorer DB block height: $db_block)."
    echo "Wiping Blockscout database volume to synchronize from new genesis block..."
    docker compose -f "$MONITORING_DIR/docker-compose.yml" down -v
    docker compose -f "$MONITORING_DIR/docker-compose.yml" up -d
    echo "Stack restarted with fresh volumes."
  fi
fi

echo "Monitoring stack started."
