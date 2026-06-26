#!/usr/bin/env bash

set -euo pipefail

###############################################
# Install cron job automatically
###############################################

CRON_JOB="* * * * * /usr/local/bin/wireguard-metrics.sh"

if ! crontab -l 2>/dev/null | grep -Fq "/usr/local/bin/wireguard-metrics.sh"; then
    (
        crontab -l 2>/dev/null
        echo "$CRON_JOB"
    ) | crontab -

    echo "[+] Installed cron job to update WireGuard metrics every minute."
fi

OUT="/var/lib/node_exporter/textfile_collector/wireguard.prom"
TMP=$(mktemp)

cleanup() {
    rm -f "$TMP"
}
trap cleanup EXIT

echo "# HELP wireguard_peers Number of configured peers" > "$TMP"
echo "# TYPE wireguard_peers gauge" >> "$TMP"

PEERS=$(wg show wg0 peers | wc -l)
echo "wireguard_peers $PEERS" >> "$TMP"

echo "# HELP wireguard_peer_connected Peer connected (1=yes,0=no)" >> "$TMP"
echo "# TYPE wireguard_peer_connected gauge" >> "$TMP"

echo "# HELP wireguard_latest_handshake_seconds Last handshake timestamp" >> "$TMP"
echo "# TYPE wireguard_latest_handshake_seconds gauge" >> "$TMP"

echo "# HELP wireguard_received_bytes Bytes received" >> "$TMP"
echo "# TYPE wireguard_received_bytes counter" >> "$TMP"

echo "# HELP wireguard_sent_bytes Bytes sent" >> "$TMP"
echo "# TYPE wireguard_sent_bytes counter" >> "$TMP"

echo "# HELP wireguard_allowed_ips Configured AllowedIPs" >> "$TMP"
echo "# TYPE wireguard_allowed_ips gauge" >> "$TMP"

CURRENT=$(date +%s)

wg show wg0 dump | tail -n +2 | while IFS=$'\t' read -r pubkey psk endpoint allowed_ips handshake rx tx keepalive
do
    if [[ "$handshake" -eq 0 ]]; then
        connected=0
    elif (( CURRENT - handshake < 180 )); then
        connected=1
    else
        connected=0
    fi

    echo "wireguard_peer_connected{peer=\"$pubkey\"} $connected" >> "$TMP"
    echo "wireguard_latest_handshake_seconds{peer=\"$pubkey\"} $handshake" >> "$TMP"
    echo "wireguard_received_bytes{peer=\"$pubkey\"} $rx" >> "$TMP"
    echo "wireguard_sent_bytes{peer=\"$pubkey\"} $tx" >> "$TMP"
    echo "wireguard_allowed_ips{peer=\"$pubkey\",allowed_ips=\"$allowed_ips\"} 1" >> "$TMP"
done

mv "$TMP" "$OUT"