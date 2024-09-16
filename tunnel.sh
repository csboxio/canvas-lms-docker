#!/bin/bash

set -e

TUNNEL_NAME="canvas-lms-tunnel"
HOSTNAME="canvas.csbox.io"
SECRET_NAME="CF_TUNNEL_CANVAS"

sudo apt-get update
sudo apt-get install -y curl

# Download and install Cloudflare's package signing key
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

# Add the Cloudflare repository
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list

sudo apt-get update
sudo apt-get install -y cloudflared google-cloud-sdk

# Retrieve the tunnel token from Secret Manager
TUNNEL_TOKEN=$(gcloud secrets versions access latest --secret="${SECRET_NAME}")

sudo mkdir -p /etc/cloudflared

# Save the tunnel token to the credentials file
echo "${TUNNEL_TOKEN}" | sudo tee /etc/cloudflared/tunnel.json > /dev/null

# Create the configuration file
sudo tee /etc/cloudflared/config.yml > /dev/null <<EOL
tunnel: ${TUNNEL_NAME}
credentials-file: /etc/cloudflared/tunnel.json

ingress:
  - hostname: ${HOSTNAME}
    service: http://localhost:3000
  - service: http_status:404
EOL

# Install and start the cloudflared service
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared

echo "Cloudflare Tunnel setup complete. Tunnel '${TUNNEL_NAME}' is now running for ${HOSTNAME}"