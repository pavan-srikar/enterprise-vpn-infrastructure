#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo " VPN Monitoring Stack Setup"
echo " Prometheus + Grafana + Node Exporter"
echo "========================================"

if [ "$EUID" -ne 0 ]; then
    echo "Run with sudo."
    exit 1
fi

echo "[+] Updating packages..."
apt update

echo "[+] Installing dependencies..."
apt install -y curl wget gpg apt-transport-https software-properties-common

########################################################
# Install Prometheus + Node Exporter
########################################################

echo "[+] Installing Prometheus..."
apt install -y prometheus prometheus-node-exporter

########################################################
# Install Grafana
########################################################

if ! dpkg -s grafana >/dev/null 2>&1; then
    echo "[+] Installing Grafana..."

    mkdir -p /etc/apt/keyrings

    wget -qO- https://apt.grafana.com/gpg.key \
        | gpg --dearmor \
        -o /etc/apt/keyrings/grafana.gpg

    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
        > /etc/apt/sources.list.d/grafana.list

    apt update
    apt install -y grafana
else
    echo "[✓] Grafana already installed."
fi

########################################################
# Configure Prometheus
########################################################

echo "[+] Configuring Prometheus..."

cat >/etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s

scrape_configs:

  - job_name: prometheus
    static_configs:
      - targets:
          - localhost:9090

  - job_name: node
    static_configs:
      - targets:
          - localhost:9100
EOF

########################################################
# Enable services
########################################################

echo "[+] Starting services..."

systemctl daemon-reload

systemctl enable prometheus
systemctl enable prometheus-node-exporter
systemctl enable grafana-server

systemctl restart prometheus
systemctl restart prometheus-node-exporter
systemctl restart grafana-server

########################################################
# Wait a few seconds
########################################################

sleep 5

########################################################
# Health checks
########################################################

echo
echo "============== HEALTH CHECKS =============="

if curl -sf http://localhost:9090/-/healthy >/dev/null; then
    echo "[✓] Prometheus running"
else
    echo "[✗] Prometheus failed"
fi

if curl -sf http://localhost:9100/metrics >/dev/null; then
    echo "[✓] Node Exporter running"
else
    echo "[✗] Node Exporter failed"
fi

if curl -sf http://localhost:3000/api/health >/dev/null; then
    echo "[✓] Grafana running"
else
    echo "[✗] Grafana failed"
fi

########################################################
# Done
########################################################

echo
echo "========================================"
echo " Installation Complete"
echo "========================================"
echo

WG_IP=$(ip -4 addr show wg0 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1)

if [ -z "$WG_IP" ]; then
    WG_IP="<WireGuard_Server_IP>"
fi

echo "Grafana    : http://${WG_IP}:3000"
echo "Prometheus : http://${WG_IP}:9090"
echo
echo "Grafana Login"
echo "Username : admin"
echo "Password : admin"
echo
echo "Change the password on first login."