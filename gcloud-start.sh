#!/bin/bash

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo curl -L "https://github.com/docker/compose/releases/download/v2.29.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

docker-compose --version

sudo apt-get install -y git

git clone --depth 1 https://github.com/ethan-mcc/canvas-lms-docker/
cd canvas-lms-docker

sudo ufw allow 80/tcp
sudo ufw allow 3000/tcp
sudo ufw --force enable

sudo usermod -aG docker $USER

chmod +x setup.sh
sudo ./setup.sh

chmod +x run.sh
sudo ./run.sh

chmod +x tunnel.sh
sudo ./tunnel.sh

