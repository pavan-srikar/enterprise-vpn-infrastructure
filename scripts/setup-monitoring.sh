#!/usr/bin/env bash

echo ""
echo "====================================================="
echo "        VPN Monitoring Stack Installer"
echo "        Prometheus + Grafana + WG Exporter"
echo "====================================================="
echo ""

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] Please run as root."
    echo ""
    echo "Example:"
    echo "  sudo ./scripts/setup-monitoring.sh"
    echo ""
    exit 1
fi

PROMETHEUS_VERSION="2.51.0"
WG_EXPORTER_VERSION="0.6.1"
GRAFANA_GPG_KEY="https://apt.grafana.com/gpg.key"

echo "[+] Updating packages..."
apt update -y
apt install -y curl wget adduser libfontconfig1 gnupg2 apt-transport-https software-properties-common

# ─────────────────────────────────────────────
# 1. Install Prometheus
# ─────────────────────────────────────────────
echo ""
echo "[+] Installing Prometheus $PROMETHEUS_VERSION..."

useradd --no-create-home --shell /bin/false prometheus 2>/dev/null || true
mkdir -p /etc/prometheus /var/lib/prometheus

wget -q "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz" \
    -O /tmp/prometheus.tar.gz

tar -xzf /tmp/prometheus.tar.gz -C /tmp
cp /tmp/prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus /usr/local/bin/
cp /tmp/prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool /usr/local/bin/
cp -r /tmp/prometheus-${PROMETHEUS_VERSION}.linux-amd64/consoles /etc/prometheus/
cp -r /tmp/prometheus-${PROMETHEUS_VERSION}.linux-amd64/console_libraries /etc/prometheus/

chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
chmod +x /usr/local/bin/prometheus /usr/local/bin/promtool

# Prometheus config
cat > /etc/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "wireguard"
    static_configs:
      - targets: ["localhost:9586"]
    scrape_interval: 30s

  - job_name: "node"
    static_configs:
      - targets: ["localhost:9100"]
    scrape_interval: 30s
EOF

chown prometheus:prometheus /etc/prometheus/prometheus.yml

# Prometheus systemd service
cat > /etc/systemd/system/prometheus.service << 'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.listen-address=0.0.0.0:9090 \
    --storage.tsdb.retention.time=15d
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "[✓] Prometheus installed."

# ─────────────────────────────────────────────
# 2. Install Node Exporter (system metrics)
# ─────────────────────────────────────────────
echo ""
echo "[+] Installing Node Exporter..."

NODE_EXPORTER_VERSION="1.7.0"
useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null || true

wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" \
    -O /tmp/node_exporter.tar.gz

tar -xzf /tmp/node_exporter.tar.gz -C /tmp
cp /tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "[✓] Node Exporter installed."

# ─────────────────────────────────────────────
# 3. Install WireGuard Exporter
# ─────────────────────────────────────────────
echo ""
echo "[+] Installing WireGuard Prometheus Exporter..."

wget -q "https://github.com/MindFlavor/prometheus_wireguard_exporter/releases/download/${WG_EXPORTER_VERSION}/prometheus_wireguard_exporter.amd64.deb" \
    -O /tmp/wg_exporter.deb 2>/dev/null || {
    # fallback: build from binary release
    wget -q "https://github.com/MindFlavor/prometheus_wireguard_exporter/releases/download/${WG_EXPORTER_VERSION}/prometheus_wireguard_exporter" \
        -O /usr/local/bin/prometheus_wireguard_exporter
    chmod +x /usr/local/bin/prometheus_wireguard_exporter
}

if [[ -f /tmp/wg_exporter.deb ]]; then
    dpkg -i /tmp/wg_exporter.deb
else
    cat > /etc/systemd/system/prometheus_wireguard_exporter.service << 'EOF'
[Unit]
Description=Prometheus WireGuard Exporter
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/prometheus_wireguard_exporter -a 0.0.0.0:9586
Restart=always
# needs root to read wg show output
User=root

[Install]
WantedBy=multi-user.target
EOF
fi

echo "[✓] WireGuard Exporter installed."

# ─────────────────────────────────────────────
# 4. Install Grafana
# ─────────────────────────────────────────────
echo ""
echo "[+] Installing Grafana..."

mkdir -p /etc/apt/keyrings
wget -q -O - "$GRAFANA_GPG_KEY" | gpg --dearmor > /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
    > /etc/apt/sources.list.d/grafana.list

apt update -y
apt install -y grafana

# Grafana config — bind to VPN interface only
sed -i 's/;http_addr =/http_addr = 10.0.0.1/' /etc/grafana/grafana.ini
sed -i 's/;http_port = 3000/http_port = 3000/' /etc/grafana/grafana.ini

# provision Prometheus datasource automatically
mkdir -p /etc/grafana/provisioning/datasources
cat > /etc/grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: false
EOF

echo "[✓] Grafana installed."

# ─────────────────────────────────────────────
# 5. Start all services
# ─────────────────────────────────────────────
echo ""
echo "[+] Starting all services..."

systemctl daemon-reload

systemctl enable prometheus && systemctl restart prometheus
systemctl enable node_exporter && systemctl restart node_exporter
systemctl enable prometheus_wireguard_exporter && systemctl restart prometheus_wireguard_exporter
systemctl enable grafana-server && systemctl restart grafana-server

sleep 3

# ─────────────────────────────────────────────
# 6. Verify
# ─────────────────────────────────────────────
echo ""
echo "[+] Verifying services..."

check_service() {
    if systemctl is-active --quiet "$1"; then
        echo "  [✓] $1 is running"
    else
        echo "  [✗] $1 failed to start"
    fi
}

check_service prometheus
check_service node_exporter
check_service prometheus_wireguard_exporter
check_service grafana-server

echo ""
echo "====================================================="
echo "           Monitoring Stack Ready"
echo "====================================================="
echo ""
echo "Connect to VPN first, then open in browser:"
echo ""
echo "  Grafana     : http://10.0.0.1:3000"
echo "  Prometheus  : http://10.0.0.1:9090"
echo ""
echo "Grafana Default Login:"
echo "  Username : admin"
echo "  Password : admin"
echo "  (change this immediately after first login)"
echo ""
echo "Next Steps:"
echo "  1. Open http://10.0.0.1:3000 in your browser"
echo "  2. Login and change the default password"
echo "  3. Import the WireGuard dashboard:"
echo "     Dashboards > Import > Upload JSON file"
echo "     File: monitoring/dashboards/wireguard-dashboard.json"
echo ""
echo "====================================================="s