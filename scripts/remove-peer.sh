#!/usr/bin/env bash
set -euo pipefail

PEER_NAME="${1:-}"
WG_DIR="/etc/wireguard"
PEER_DIR="/etc/wireguard/peers"

if [[ -z "$PEER_NAME" ]]; then
    echo ""
    echo "====================================================="
    echo "          WireGuard Peer Removal Tool"
    echo "====================================================="
    echo ""
    echo "Usage:"
    echo "  sudo ./scripts/remove-peer.sh <device-name>"
    echo ""
    echo "Examples:"
    echo "  sudo ./scripts/remove-peer.sh phone"
    echo "  sudo ./scripts/remove-peer.sh laptop"
    echo ""
    echo "List existing peers:"
    echo "  sudo wg show"
    echo "  ls /etc/wireguard/peers/"
    echo ""
    echo "====================================================="
    echo ""
    exit 1
fi

PEER_CONF_DIR="$PEER_DIR/$PEER_NAME"

if [[ ! -d "$PEER_CONF_DIR" ]]; then
    echo "[ERROR] Peer '$PEER_NAME' not found at $PEER_CONF_DIR"
    echo ""
    echo "Existing peers:"
    ls "$PEER_DIR" 2>/dev/null || echo "  (none)"
    echo ""
    exit 1
fi

PUBLIC_KEY=$(cat "$PEER_CONF_DIR/public.key" 2>/dev/null || true)

if [[ -z "$PUBLIC_KEY" ]]; then
    echo "[ERROR] Could not read public key for peer '$PEER_NAME'"
    exit 1
fi

echo ""
echo "====================================================="
echo "           Removing Peer: $PEER_NAME"
echo "====================================================="
echo "Public Key : $PUBLIC_KEY"
echo "Config Dir : $PEER_CONF_DIR"
echo "====================================================="
echo ""

read -r -p "[?] Are you sure you want to remove '$PEER_NAME'? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "[!] Aborted."
    exit 0
fi

echo "[+] Removing peer from live WireGuard interface..."
if wg show wg0 peers 2>/dev/null | grep -q "$PUBLIC_KEY"; then
    wg set wg0 peer "$PUBLIC_KEY" remove
    echo "[✓] Peer removed from live interface."
else
    echo "[!] Peer not active on interface (may already be gone)."
fi

echo "[+] Removing peer block from wg0.conf..."

python3 - "$WG_DIR/wg0.conf" "$PUBLIC_KEY" << 'PYEOF'
import sys

conf_path = sys.argv[1]
target_key = sys.argv[2]

with open(conf_path, 'r') as f:
    content = f.read()

lines = content.split('\n')
result = []
i = 0

while i < len(lines):
    line = lines[i]
    if line.strip().startswith('# Peer:') and i + 1 < len(lines) and lines[i+1].strip() == '[Peer]':
        block = []
        j = i
        while j < len(lines):
            block.append(lines[j])
            j += 1
            if j < len(lines) and lines[j].strip().startswith('[') and lines[j].strip() != '[Peer]':
                break
        block_str = '\n'.join(block)
        if target_key in block_str:
            i = j
            if result and result[-1].strip() == '':
                result.pop()
            continue
    result.append(line)
    i += 1

with open(conf_path, 'w') as f:
    f.write('\n'.join(result))

print("[✓] Peer block removed from wg0.conf.")
PYEOF

echo "[+] Removing peer files..."
rm -rf "$PEER_CONF_DIR"
echo "[✓] Peer directory removed: $PEER_CONF_DIR"

echo ""
echo "====================================================="
echo "      Peer '$PEER_NAME' Removed Successfully"
echo "====================================================="
echo ""
echo "Verify removal:"
echo "  sudo wg show"
echo ""