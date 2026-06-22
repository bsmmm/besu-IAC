#!/usr/bin/env bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================="
echo "      Besu Infrastructure Observability Validator        "
echo "=========================================================="

# Extract node IPs dynamically
nodes=($(python3 -c "
import yaml, os
defaults = yaml.safe_load(open('$SCRIPTS_DIR/../config/settings.yml.default'))
user = yaml.safe_load(open('$SCRIPTS_DIR/../config/settings.yml')) if os.path.exists('$SCRIPTS_DIR/../config/settings.yml') else {}
nodes = user.get('infrastructure', {}).get('nodes', []) or defaults['infrastructure']['nodes']
print(' '.join([n['ip'] for n in nodes]))
"))

success=true

# Helper function to check curl status code
check_endpoint() {
  local url=$1
  local expected=$2
  local name=$3

  # Perform request with 2 second timeout
  response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$url")

  if [[ "$response" == "$expected" ]]; then
    echo -e "[${GREEN}PASS${NC}] $name is healthy ($url) -> HTTP $response"
  else
    echo -e "[${RED}FAIL${NC}] $name is NOT healthy ($url) -> Expected HTTP $expected, got $response"
    success=false
  fi
}

echo -e "\n--- Checking Host Monitoring Containers ---"
check_endpoint "http://localhost:9090/-/healthy" "200" "Prometheus UI"
check_endpoint "http://localhost:3000/api/health" "200" "Grafana API Health"

echo "Waiting for Blockscout to initialize and run database migrations..."
blockscout_ready=false
for i in {1..12}; do
  response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "http://localhost:4000/" || echo "000")
  if [[ "$response" == "200" ]]; then
    blockscout_ready=true
    break
  fi
  echo "  Blockscout not ready yet (HTTP $response). Retrying in 5s... ($i/12)"
  sleep 5
done

if [ "$blockscout_ready" = true ]; then
  echo -e "[${GREEN}PASS${NC}] Blockscout UI is healthy (http://localhost:4000/) -> HTTP 200"
else
  echo -e "[${RED}FAIL${NC}] Blockscout UI is NOT healthy (http://localhost:4000/) after 60 seconds."
  success=false
fi

echo -e "\n--- Checking VM Metric Exporters ---"
for node in "${nodes[@]}"; do
  echo "Testing VM: $node"
  check_endpoint "http://$node:9100/metrics" "200" "  Node Exporter"
  check_endpoint "http://$node:9256/metrics" "200" "  Process Exporter"
  check_endpoint "http://$node:9545/metrics" "200" "  Besu Metrics"
done

echo -e "\n=========================================================="
if [ "$success" = true ]; then
  echo -e "${GREEN}SUCCESS: All checks passed. Observability stack is operational.${NC}"
  exit 0
else
  echo -e "${RED}FAILURE: One or more checks failed. Please check container logs and VM services.${NC}"
  exit 1
fi
