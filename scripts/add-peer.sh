#!/usr/bin/env bash
set -euo pipefail

PEER_NAME="${1:-}"
PEER_IP="${2:-}"
MODE="${3:-split}"

WG_DIR="/etc/wireguard"
PEER_DIR="/etc/wireguard/peers"

# --------------------------------------------------
# Usage / Help Menu
# --------------------------------------------------
if [[ -z "$PEER_NAME" || -z "$PEER_IP" ]]; then
    echo ""
    echo "====================================================="
    echo "         WireGuard Peer Provisioning Tool"
    echo "====================================================="
    echo ""
    echo "Usage:"
    echo "  sudo ./scripts/add-peer.sh <device-name> <vpn-ip> <mode>"
    echo ""
    echo "Examples:"
    echo "  sudo ./scripts/add-peer.sh phone 10.0.0.2 split"
    echo "  sudo ./scripts/add-peer.sh laptop 10.0.0.3 enterprise"
    echo "  sudo ./scripts/add-peer.sh tablet 10.0.0.4 full"
    echo ""
    echo "Tunnel Modes:"
    echo ""
    echo "  split"
    echo "     AllowedIPs = 10.0.0.0/24"
    echo "     Routes only VPN subnet traffic."
    echo ""
    echo "  enterprise"
    echo "     AllowedIPs = 10.0.0.0/16"
    echo "     Routes an entire company network."
    echo ""
    echo "  full"
    echo "     AllowedIPs = 0.0.0.0/0"
    echo "     Routes ALL internet traffic through VPN."
    echo ""
    echo "Example VPN Addresses:"
    echo "  10.0.0.1 = VPN Server"
    echo "  10.0.0.2 = Phone"
    echo "  10.0.0.3 = Laptop"
    echo "  10.0.0.4 = Tablet"
    echo ""
    echo "====================================================="
    echo ""
    exit 1
fi

# --------------------------------------------------
# Routing Mode Selection
# --------------------------------------------------
case "$MODE" in
    split)
        ALLOWED_IPS="10.0.0.0/24"
        MODE_DESC="Split Tunnel"
        ;;
    enterprise)
        ALLOWED_IPS="10.0.0.0/16"
        MODE_DESC="Enterprise Network"
        ;;
    full)
        ALLOWED_IPS="0.0.0.0/0"
        MODE_DESC="Full Tunnel"
        ;;
    *)
        echo ""
        echo "[ERROR] Invalid tunnel mode: $MODE"
        echo ""
        echo "Valid modes:"
        echo "  split"
        echo "  enterprise"
        echo "  full"
        echo ""
        exit 1
        ;;
esac

echo ""
echo "====================================================="
echo "        WireGuard Peer Configuration"
echo "====================================================="
echo "Device Name : $PEER_NAME"
echo "VPN Address : $PEER_IP"
echo "Tunnel Type : $MODE_DESC"
echo "AllowedIPs  : $ALLOWED_IPS"
echo "====================================================="
echo ""

echo "[+] Creating peer directory..."
mkdir -p "$PEER_DIR/$PEER_NAME"
chmod 700 "$PEER_DIR/$PEER_NAME"

echo "[+] Generating peer keys..."
wg genkey | tee "$PEER_DIR/$PEER_NAME/private.key" | wg pubkey > "$PEER_DIR/$PEER_NAME/public.key"

PRIVATE_KEY=$(cat "$PEER_DIR/$PEER_NAME/private.key")
PUBLIC_KEY=$(cat "$PEER_DIR/$PEER_NAME/public.key")

SERVER_PUBLIC_KEY=$(cat "$WG_DIR/keys/server_public.key")

echo "[+] Detecting public server IP..."
SERVER_IP=$(curl -s ifconfig.me)

if [[ -z "$SERVER_IP" ]]; then
    echo "[ERROR] Unable to determine public IP."
    exit 1
fi

echo "[+] Server IP detected: $SERVER_IP"

# --------------------------------------------------
# Prevent duplicate peers
# --------------------------------------------------
if grep -q "$PUBLIC_KEY" "$WG_DIR/wg0.conf"; then
    echo "[!] Peer already exists in WireGuard configuration."
    exit 0
fi

echo "[+] Adding peer to WireGuard configuration..."

cat >> "$WG_DIR/wg0.conf" <<EOF

# Peer: $PEER_NAME
[Peer]
PublicKey = $PUBLIC_KEY
AllowedIPs = $PEER_IP/32
EOF

echo "[+] Restarting WireGuard..."
systemctl restart wg-quick@wg0

echo "[+] Generating client configuration..."

cat > "$PEER_DIR/$PEER_NAME/client.conf" <<EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $PEER_IP/24
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_IP:51820
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25
EOF

echo ""
echo "[✓] Peer added successfully!"
echo ""
echo "Device Name : $PEER_NAME"
echo "VPN Address : $PEER_IP"
echo "Tunnel Type : $MODE_DESC"
echo "AllowedIPs  : $ALLOWED_IPS"
echo ""
echo "Client Config:"
echo "  $PEER_DIR/$PEER_NAME/client.conf"
echo ""
echo "Generate QR Code:"
echo "  sudo ./scripts/generate-qr.sh $PEER_DIR/$PEER_NAME/client.conf"
echo ""