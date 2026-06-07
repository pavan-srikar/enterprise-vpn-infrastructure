# scripts/generate-qr.sh

#!/bin/bash

CONFIG_FILE=$1

if [ -z "$CONFIG_FILE" ]; then
echo "Usage: ./generate-qr.sh <client-config>"
echo "Example: ./generate-qr.sh peers/developer-laptop/client.conf"
exit 1
fi

echo "Generating QR code for mobile onboarding..."

qrencode -t ansiutf8 < $CONFIG_FILE

echo "QR generation complete."
