TUNNEL_ID="your-tunnel-id"
TUNNEL_NAME="canvas-lms-tunnel"
HOSTNAME="canvas.csbox.io"

apt-get update
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl gpg

curl -L https://pkg.cloudflare.com/pubkey.gpg | gpg --dearmor --yes -o /usr/share/keyrings/cloudflare-main.gpg
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflared.list

apt-get update
apt-get install -y cloudflared

mkdir -p /etc/cloudflared

cat > /etc/cloudflared/config.yml <<EOL
tunnel: ${TUNNEL_ID}
credentials-file: /etc/cloudflared/${TUNNEL_ID}.json

ingress:
  - hostname: ${HOSTNAME}
    service: http://localhost:3000
  - service: http_status:404
EOL

cloudflared service install

systemctl start cloudflared
systemctl enable cloudflared

cloudflared tunnel route dns ${TUNNEL_NAME} ${HOSTNAME}
