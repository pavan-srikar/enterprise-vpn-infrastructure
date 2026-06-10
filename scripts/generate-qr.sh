#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-}"

if [[ -z "$CONFIG_FILE" ]]; then
  echo "Usage: ./generate-qr.sh <client-config>"
  echo "Example: ./generate-qr.sh /etc/wireguard/peers/dev/client.conf"
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "[!] File not found: $CONFIG_FILE"
  exit 1
fi

echo "[+] Generating QR code..."

# Terminal QR (safe)
qrencode -t ansiutf8 < "$CONFIG_FILE"

echo ""
echo "[✓] QR generation complete"