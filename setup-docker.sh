#!/bin/bash

# uninstall docker old versions to sanity check
echo -e "\nUninstalling docker old versions...\n"
sudo apt-get remove docker docker-engine docker.io containerd runc

echo -e "\nInstalling apt packages related to HTTPS...\n"
# install packages to allow apt to use a repository over HTTPS
sudo apt-get install ca-certificates curl gnupg lsb-release

echo -e "\nAdding docker's official GPG key...\n"
# add docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo -e "\nSetting up the stable docker repository...\n"
# set up the stable docker repository
echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo -e "\nInstalling docker...\n"
# install docker
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

echo -e "\nAdding user to docker group...\n"
# add user to docker group
sudo usermod -aG docker $USER

echo -e "\nConfiguring docker to start on boot...\n"
# configure docker to start on boot
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

echo -e "\nConfiguring docker daemon...\n"
# create docker daemon configuration file to set docker log driver
echo -e '{\n\t"log-driver": "local"\n}' | sudo tee /etc/docker/daemon.json > /dev/null
sudo systemctl restart docker

echo -e "\nInstalling docker compose...\n"
sudo curl -L "https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

exit 0