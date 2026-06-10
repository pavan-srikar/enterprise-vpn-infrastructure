#!/usr/bin/env bash
set -euo pipefail

PEER_NAME="${1:-}"
PEER_IP="${2:-}"

WG_DIR="/etc/wireguard"
PEER_DIR="/etc/wireguard/peers"

if [[ -z "$PEER_NAME" || -z "$PEER_IP" ]]; then
  echo "Usage: ./add-peer.sh <peer-name> <peer-ip>"
  echo "Example: ./add-peer.sh dev-laptop 10.0.0.2"
  exit 1
fi

echo "[+] Creating peer directory..."
mkdir -p "$PEER_DIR/$PEER_NAME"
chmod 700 "$PEER_DIR/$PEER_NAME"

echo "[+] Generating peer keys..."
wg genkey | tee "$PEER_DIR/$PEER_NAME/private.key" | wg pubkey > "$PEER_DIR/$PEER_NAME/public.key"

PRIVATE_KEY=$(cat "$PEER_DIR/$PEER_NAME/private.key")
PUBLIC_KEY=$(cat "$PEER_DIR/$PEER_NAME/public.key")

SERVER_PUBLIC_KEY=$(cat "$WG_DIR/keys/server_public.key")

# Auto detect EC2 public IP (no manual edits)
SERVER_IP=$(curl -s ifconfig.me)

echo "[+] Server IP detected: $SERVER_IP"

# -------------------------
# Prevent duplicate peers
# -------------------------
if grep -q "$PUBLIC_KEY" "$WG_DIR/wg0.conf"; then
  echo "[!] Peer already exists in config. Aborting."
  exit 0
fi

echo "[+] Adding peer to WireGuard config..."

cat >> "$WG_DIR/wg0.conf" <<EOF

# Peer: $PEER_NAME
[Peer]
PublicKey = $PUBLIC_KEY
AllowedIPs = $PEER_IP/32
EOF

echo "[+] Restarting WireGuard..."
systemctl restart wg-quick@wg0

# -------------------------
# Client config
# -------------------------
echo "[+] Generating client config..."

cat > "$PEER_DIR/$PEER_NAME/client.conf" <<EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $PEER_IP/24
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

echo "[✓] Peer added: $PEER_NAME"
echo "[✓] Client config: $PEER_DIR/$PEER_NAME/client.conf"