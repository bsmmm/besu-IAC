import os
import yaml

# Resolve paths
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
defaults_path = os.path.join(project_root, "config", "settings.yml.default")
settings_path = os.path.join(project_root, "config", "settings.yml")

def deep_merge(defaults, user):
    merged = {}
    for key, default_val in defaults.items():
        if key not in user:
            merged[key] = default_val
        else:
            user_val = user[key]
            if isinstance(default_val, dict) and isinstance(user_val, dict):
                merged[key] = deep_merge(default_val, user_val)
            elif isinstance(default_val, list) and isinstance(user_val, list):
                merged[key] = user_val
            else:
                merged[key] = user_val
    for key, user_val in user.items():
        if key not in defaults:
            merged[key] = user_val
    return merged

# Load merged settings
with open(defaults_path) as f:
    defaults = yaml.safe_load(f) or {}

if os.path.exists(settings_path):
    with open(settings_path) as f:
        user_settings = yaml.safe_load(f) or {}
else:
    user_settings = {}

settings = deep_merge(defaults, user_settings)
nodes = settings["infrastructure"]["nodes"]
besu_metrics_port = settings["monitoring"]["besu_metrics_port"]

# Filter RPC nodes and others
rpc_nodes = [n for n in nodes if "rpc" in n.get("roles", [])]
if not rpc_nodes:
    # If no explicit RPC nodes, fall back to all nodes to be safe
    rpc_nodes = nodes

extra_hosts = [f"{n['name']}:{n['ip']}" for n in nodes]

# 1. Generate docker-compose.yml
docker_compose_content = f"""services:
  prometheus:
    image: prom/prometheus:v3.0.0
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"
      - "--web.enable-lifecycle"
    volumes:
      - ./prometheus:/etc/prometheus:ro
      - prometheus_data:/prometheus
    extra_hosts:
"""
for host in extra_hosts:
    docker_compose_content += f"      - \"{host}\"\n"

docker_compose_content += """
  grafana:
    image: grafana/grafana:11.0.0
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false

  alertmanager:
    image: prom/alertmanager:v0.27.0
    container_name: alertmanager
    restart: unless-stopped
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager:/etc/alertmanager:ro
      - alertmanager_data:/data
    command:
      - "--config.file=/etc/alertmanager/alertmanager.yml"
      - "--storage.path=/data"

  blockscout-db:
    image: postgres:15-alpine
    container_name: blockscout-db
    restart: unless-stopped
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=blockscout
    volumes:
      - blockscout_db_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  blockscout:
    image: blockscout/blockscout:6.8.0
    container_name: blockscout
    restart: unless-stopped
    command: sh -c "bin/blockscout eval \\"Elixir.Explorer.ReleaseTasks.create_and_migrate()\\" && bin/blockscout start"
    ports:
      - "4000:4000"
    environment:
      - PORT=4000
      - ECTO_SSL_MODE=disable
      - DATABASE_URL=postgresql://postgres:postgres@blockscout-db:5432/blockscout?ssl=false
      - ETHEREUM_JSONRPC_VARIANT=besu
      - ETHEREUM_JSONRPC_HTTP_URL=http://rpc-proxy:8545
      - ETHEREUM_JSONRPC_WS_URL=ws://rpc-proxy:8546
      - INDEXER_DISABLE_PENDING_TRANSACTIONS_FETCHER=true
      - INDEXER_DISABLE_BLOCK_REWARD_FETCHER=true
      - INDEXER_DISABLE_INTERNAL_TRANSACTIONS_FETCHER=true
      - COIN=ETH
    depends_on:
      - blockscout-db
      - rpc-proxy

  rpc-proxy:
    image: nginx:alpine
    container_name: rpc-proxy
    restart: unless-stopped
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    extra_hosts:
"""
for host in extra_hosts:
    docker_compose_content += f"      - \"{host}\"\n"

docker_compose_content += """
volumes:
  prometheus_data:
  grafana_data:
  alertmanager_data:
  blockscout_db_data:
"""

with open(os.path.join(project_root, "monitoring", "docker-compose.yml"), "w") as f:
    f.write(docker_compose_content)

# 2. Generate prometheus.yml
prometheus_content = f"""global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert.rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - "alertmanager:9093"

scrape_configs:
  - job_name: "node-exporter"
    static_configs:
      - targets:
"""
for n in nodes:
    prometheus_content += f"          - \"{n['name']}:9100\"\n"
prometheus_content += """        labels:
          role: "node"

  - job_name: "process-exporter"
    static_configs:
      - targets:
"""
for n in nodes:
    prometheus_content += f"          - \"{n['name']}:9256\"\n"
prometheus_content += """        labels:
          role: "process"

  - job_name: "besu"
    static_configs:
      - targets:
"""
for n in nodes:
    prometheus_content += f"          - \"{n['name']}:{besu_metrics_port}\"\n"
prometheus_content += """        labels:
          role: "blockchain"
"""

with open(os.path.join(project_root, "monitoring", "prometheus", "prometheus.yml"), "w") as f:
    f.write(prometheus_content)

# 3. Generate nginx.conf
nginx_content = """events {}
http {
    upstream rpc_backend_http {
"""
for r in rpc_nodes:
    nginx_content += f"        server {r['name']}:8545;\n"
nginx_content += """    }
    upstream rpc_backend_ws {
"""
for r in rpc_nodes:
    nginx_content += f"        server {r['name']}:8546;\n"
nginx_content += """    }
    server {
        listen 8545;
        location / {
            proxy_pass https://rpc_backend_http;
            proxy_ssl_verify off;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    server {
        listen 8546;
        location / {
            proxy_pass http://rpc_backend_ws;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host $host;
        }
    }
}
"""

with open(os.path.join(project_root, "monitoring", "nginx", "nginx.conf"), "w") as f:
    f.write(nginx_content)

print("Dynamic monitoring configuration files generated successfully!")
