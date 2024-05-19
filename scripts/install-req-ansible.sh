#!/bin/bash
# sudo apt -y upgrade
#sudo systemctl reboot
#sudo apt update
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
sudo tee /etc/apt/sources.list<<EOF
deb https://mirror.iranserver.com/ubuntu jammy main restricted universe multiverse
deb https://mirror.iranserver.com/ubuntu jammy-updates main restricted universe multiverse
deb https://mirror.iranserver.com/ubuntu jammy-security main restricted universe multiverse
EOF
sudo apt update
sudo apt -y install software-properties-common curl ansible
sudo rm /var/lib/dpkg/lock
sudo rm /var/lib/apt/lists/lock
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/cache/apt/archives/lock
ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa
sudo cat  ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys 
sudo -u ubuntu ssh-keygen -t rsa -b 4096 -N '' -f /home/ubuntu/.ssh/id_rsa
sudo cat  /home/ubuntu/.ssh/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys
CEPH_RELEASE=18.2.0
curl --silent --remote-name --location https://download.ceph.com/rpm-${CEPH_RELEASE}/el9/noarch/cephadm
chmod +x cephadm
sudo mv cephadm  /usr/local/bin/
cephadm --help
sudo tee -a ~/.ssh/config<<EOF
Host *
    UserKnownHostsFile /dev/null
    StrictHostKeyChecking no
    IdentitiesOnly yes
    ConnectTimeout 0
    ServerAliveInterval 300
EOF
sudo systemctl restart sshd
cd ~/
sudo mkdir -p /etc/apt/keyrings
