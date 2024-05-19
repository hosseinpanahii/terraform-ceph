#!/bin/bash
# sudo apt -y upgrade
#sudo systemctl rebooti
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
sudo tee /etc/apt/sources.list<<EOF
deb https://mirror.iranserver.com/ubuntu jammy main restricted universe multiverse
deb https://mirror.iranserver.com/ubuntu jammy-updates main restricted universe multiverse
deb https://mirror.iranserver.com/ubuntu jammy-security main restricted universe multiverse
EOF
sudo apt update
sudo mkdir -p /etc/apt/keyrings
sudo apt -y install software-properties-common  curl bash-completion
sudo rm /var/lib/dpkg/lock
sudo rm /var/lib/apt/lists/lock
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/cache/apt/archives/lock

cd ~/
