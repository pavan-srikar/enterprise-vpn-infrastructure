#!/usr/bin/env bash
set -euo pipefail

echo "[+] Updating packages..."
apt update -y

echo "[+] Installing WireGuard..."
apt install -y wireguard wireguard-tools qrencode iptables

# -----------------------------
# Detect outbound interface
# -----------------------------
OUT_IF=$(ip route | awk '/default/ {print $5}')

echo "[+] Detected outbound interface: $OUT_IF"

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
wg show wg0 || true

echo "[✓] WireGuard setup complete!"
echo "[✓] Server public key: ${SERVER_PUBLIC}"
echo "[✓] Interface: wg0 running on port 51820"