#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-}"

echo ""
echo "====================================================="
echo "          WireGuard QR Code Generator"
echo "====================================================="
echo ""

# --------------------------------------------------
# Usage
# --------------------------------------------------
if [[ -z "$CONFIG_FILE" ]]; then
    echo "Usage:"
    echo "  sudo ./scripts/generate-qr.sh <client-config>"
    echo ""
    echo "Example:"
    echo "  sudo ./scripts/generate-qr.sh /etc/wireguard/peers/phone/client.conf"
    echo ""
    echo "Typical Workflow:"
    echo "  1. Create peer"
    echo "     sudo ./scripts/add-peer.sh phone 10.0.0.2 split"
    echo ""
    echo "  2. Generate QR"
    echo "     sudo ./scripts/generate-qr.sh /etc/wireguard/peers/phone/client.conf"
    echo ""
    echo "  3. Open WireGuard mobile app"
    echo "  4. Tap '+'"
    echo "  5. Scan QR Code"
    echo ""
    exit 1
fi

# --------------------------------------------------
# Verify config exists
# --------------------------------------------------
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[ERROR] Configuration file not found."
    echo ""
    echo "File:"
    echo "  $CONFIG_FILE"
    echo ""
    exit 1
fi

# --------------------------------------------------
# Verify qrencode exists
# --------------------------------------------------
if ! command -v qrencode >/dev/null 2>&1; then
    echo "[ERROR] qrencode is not installed."
    echo ""
    echo "Install it with:"
    echo "  sudo apt install qrencode"
    echo ""
    exit 1
fi

PEER_NAME=$(basename "$(dirname "$CONFIG_FILE")")

echo "Device Name : $PEER_NAME"
echo "Config File : $CONFIG_FILE"
echo ""
echo "[+] Generating QR code..."
echo ""

# --------------------------------------------------
# Generate QR
# --------------------------------------------------
qrencode -t ansiutf8 < "$CONFIG_FILE"

echo ""
echo "====================================================="
echo "                QR Generation Complete"
echo "====================================================="
echo ""
echo "[✓] Device : $PEER_NAME"
echo ""
echo "Mobile Onboarding Steps:"
echo ""
echo "  1. Open the WireGuard mobile app"
echo "  2. Tap the '+' button"
echo "  3. Select 'Scan from QR Code'"
echo "  4. Scan the QR code above"
echo "  5. Save the profile"
echo "  6. Activate the tunnel"
echo ""
echo "Verification:"
echo ""
echo "  On Server:"
echo "    sudo wg show"
echo ""
echo "  You should see:"
echo "    latest handshake"
echo "    transfer: X received, Y sent"
echo ""
echo "====================================================="
echo ""