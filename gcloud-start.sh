#!/bin/bash
apt-get update
apt-get install -y docker.io
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
apt-get install -y git
git clone --depth 1 https://github.com/ethan-mcc/canvas-lms-docker/
cd canvas-lms-docker
chmod +x run.sh
./run.sh