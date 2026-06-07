# scripts/setup-wireguard.sh

#!/bin/bash

echo "Updating packages..."
sudo apt update -y

echo "Installing WireGuard..."
sudo apt install wireguard qrencode -y

echo "Enabling IP forwarding..."
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl -p

echo "Generating server keys..."
wg genkey | tee server_private.key | wg pubkey > server_public.key

echo "Creating WireGuard configuration..."

SERVER_PRIVATE_KEY=$(cat server_private.key)

sudo bash -c "cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = $SERVER_PRIVATE_KEY
Address = 10.0.0.1/24
ListenPort = 51820

PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF"

echo "Starting WireGuard..."
sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0

echo "WireGuard setup complete."
