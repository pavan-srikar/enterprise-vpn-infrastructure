# scripts/add-peer.sh

#!/bin/bash

PEER_NAME=$1
PEER_IP=$2

if [ -z "$PEER_NAME" ] || [ -z "$PEER_IP" ]; then
echo "Usage: ./add-peer.sh <peer-name> <peer-ip>"
echo "Example: ./add-peer.sh developer-laptop 10.0.0.2"
exit 1
fi

echo "Creating peer directory..."
mkdir -p peers/$PEER_NAME

echo "Generating peer keys..."
wg genkey | tee peers/$PEER_NAME/private.key | wg pubkey > peers/$PEER_NAME/public.key

PRIVATE_KEY=$(cat peers/$PEER_NAME/private.key)
PUBLIC_KEY=$(cat peers/$PEER_NAME/public.key)
SERVER_PUBLIC_KEY=$(sudo cat server_public.key)

SERVER_IP="YOUR_EC2_PUBLIC_IP"

echo "Adding peer to WireGuard server configuration..."

sudo bash -c "cat >> /etc/wireguard/wg0.conf <<EOF

[Peer]
PublicKey = $PUBLIC_KEY
AllowedIPs = $PEER_IP/32
EOF"

echo "Restarting WireGuard..."
sudo wg-quick down wg0
sudo wg-quick up wg0

echo "Generating client configuration..."

cat > peers/$PEER_NAME/client.conf <<EOF
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

echo "Peer added successfully."
echo "Client configuration saved to:"
echo "peers/$PEER_NAME/client.conf"
