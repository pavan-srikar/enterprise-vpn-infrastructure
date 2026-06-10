#!/usr/bin/env bash

echo ""
echo "====================================================="
echo "      Enterprise VPN Infrastructure Installer"
echo "====================================================="
echo ""

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] Please run as root."
    echo ""
    echo "Example:"
    echo "  sudo ./scripts/setup-wireguard.sh"
    echo ""
    exit 1
fi

echo "[+] Updating packages..."
apt update -y

echo "[+] Installing WireGuard..."
apt install -y wireguard wireguard-tools qrencode iptables

# -----------------------------
# Detect outbound interface
# -----------------------------
OUT_IF=$(ip route | awk '/default/ {print $5}')

echo ""
echo "Network Information"
echo "-----------------------------------------------------"
echo "Outbound Interface : $OUT_IF"
echo "VPN Network        : 10.0.0.0/24"
echo "VPN Server Address : 10.0.0.1"
echo "WireGuard Port     : 51820"
echo "-----------------------------------------------------"
echo ""

# -----------------------------
# Enable IP forwarding (persistent)
# -----------------------------
echo "[+] Enabling IP forwarding..."
cat > /etc/sysctl.d/99-wireguard.conf <<EOF
net.ipv4.ip_forward=1
EOF

sysctl --system

# -----------------------------
# Create directories
# -----------------------------
echo "[+] Creating WireGuard directories..."
mkdir -p /etc/wireguard/keys
chmod 700 /etc/wireguard/keys

# -----------------------------
# Generate server keys (idempotent)
# -----------------------------
if [ ! -f /etc/wireguard/keys/server_private.key ]; then
    echo "[+] Generating WireGuard keys..."

    wg genkey | tee /etc/wireguard/keys/server_private.key | wg pubkey > /etc/wireguard/keys/server_public.key
else
    echo "[+] Keys already exist, reusing..."
fi

SERVER_PRIVATE=$(cat /etc/wireguard/keys/server_private.key)
SERVER_PUBLIC=$(cat /etc/wireguard/keys/server_public.key)

echo "[+] Server public key: $SERVER_PUBLIC"

# -----------------------------
# Create WireGuard config
# -----------------------------
echo "[+] Writing wg0 configuration..."

cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = ${SERVER_PRIVATE}
Address = 10.0.0.1/24
ListenPort = 51820

PostUp = iptables -t nat -A POSTROUTING -o ${OUT_IF} -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o ${OUT_IF} -j MASQUERADE
EOF

chmod 600 /etc/wireguard/wg0.conf

# -----------------------------
# Firewall rule (optional but safe)
# -----------------------------
echo "[+] Allowing UDP 51820..."
if command -v ufw >/dev/null 2>&1; then
    ufw allow 51820/udp || true
fi

# -----------------------------
# Start WireGuard
# -----------------------------
echo "[+] Starting WireGuard..."

systemctl enable wg-quick@wg0
systemctl restart wg-quick@wg0

# -----------------------------
# Verify
# -----------------------------
echo "[+] Checking status..."
if wg show wg0 >/dev/null 2>&1; then
    echo "[✓] WireGuard interface is running."
else
    echo "[ERROR] WireGuard failed to start."
    exit 1
fi

echo ""
echo "====================================================="
echo "              Installation Complete"
echo "====================================================="
echo ""
echo "WireGuard Interface"
echo "  Name     : wg0"
echo "  Address  : 10.0.0.1/24"
echo "  Port     : 51820"
echo ""
echo "Generated Files"
echo "  Config       : /etc/wireguard/wg0.conf"
echo "  Private Key  : /etc/wireguard/keys/server_private.key"
echo "  Public Key   : /etc/wireguard/keys/server_public.key"
echo ""
echo "Server Public Key"
echo "  $SERVER_PUBLIC"
echo ""
echo "Next Steps"
echo ""
echo "  Create a peer:"
echo "    sudo ./scripts/add-peer.sh phone 10.0.0.2 split"
echo ""
echo "  Generate QR code:"
echo "    sudo ./scripts/generate-qr.sh /etc/wireguard/peers/phone/client.conf"
echo ""
echo "  Show VPN status:"
echo "    sudo wg show"
echo ""
echo "====================================================="
echo ""