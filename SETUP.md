# K3s Install using K3Sup

## Install k3sup on local machine

curl -sLS https://get.k3sup.dev | sh
sudo install k3sup /usr/local/bin/

k3sup --help

# Creating The Cluster

## MAIN NODE INSTALL

### NOTE: must disable sudo password for this user

k3sup install \
--ip ${main-server-ip} \
--tls-san ${cluster-vip} \
--tls-san k3s.home.jonahsserver.com \
--cluster \
--k3s-channel latest \
--k3s-extra-args "--disable servicelb --disable traefik" \
--local-path $HOME/.kube/config \
--user k3s-1

## JOINING OTHER NODES

### NOTE: must disable sudo password for this user

k3sup join \
--ip ${new-node-ip} \
--user ${new-node-user} \
--server-ip ${main-node-ip} \
--server-user ${main-node-user} \
--server \
--k3s-channel latest \
--k3s-extra-args "--disable servicelb --disable traefik"

## Optional

## Turn off password authentication for ssh for security

ssh-copy-id ${username}@{ip}

### Edit ssh config files

sudo nano /etc/ssh/sshd_config
sudo nano /etc/ssh/sshd_config/50-cloud-init.conf

### Edit the line:

### PasswordAuthentication no

### Restart SSH to apply

sudo systemctl reload ssh
sudo systemctl restart ssh
