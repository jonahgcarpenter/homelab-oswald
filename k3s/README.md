# K3s Install using K3Sup

## Install k3sup on local machine

curl -sLS https://get.k3sup.dev | sh
sudo install k3sup /usr/local/bin/

k3sup --help

# Creating The Cluster

## MAIN NODE INSTALL

### NOTE: must disable sudo password for this user

k3sup install \
--ip <main-servers-ip> \
--tls-san <cluster-vip> \
--tls-san k3s.home.jonahsserver.com \
--cluster \
--k3s-channel latest \
--k3s-extra-args "--disable servicelb --disable traefik" \
--local-path $HOME/.kube/config \
--user k3s-1

## Installing KubeVIP on new node

ssh <user>@<main-servers-ip>

sudo mkdir -p /var/lib/rancher/k3s/server/manifests/

sudo su

curl https://kube-vip.io/manifests/rbac.yaml > /var/lib/rancher/k3s/server/manifests/kube-vip-rbac.yaml

kubectl apply -f https://kube-vip.io/manifests/rbac.yaml

### Pick an unused ip to set the vip for this cluster

export VIP=<cluster-vip>

### Use ip a command to find proper interface

export INTERFACE=<interface-name>

KVVERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")

alias kube-vip="ctr image pull ghcr.io/kube-vip/kube-vip:$KVVERSION; ctr run --rm --net-host ghcr.io/kube-vip/kube-vip:$KVVERSION vip /kube-vip"

kube-vip manifest daemonset \
 --interface $INTERFACE \
 --address $VIP \
 --inCluster \
 --taint \
 --controlplane \
 --services \
 --arp \
 --leaderElection

### Paste output of last command here beginning at "apiVersion" line

nano /var/lib/rancher/k3s/server/manifests/kube-vip-manifest.yaml

kubectl apply -f /var/lib/rancher/k3s/server/manifests/kube-vip-manifest.yaml

### Logout of root user

exit

### You should now see the new service

sudo k3s kubectl get ds --all-namespaces

## JOINING OTHER NODES

### NOTE: must disable sudo password for this user

k3sup join \
--ip <new-node-ip> \
--user <new-node-user> \
--server-ip <main-node-ip> \
--server-user <main-node-user> \
--server \
--k3s-channel latest

### Delete Traefik deployment and service

kubectl delete deployment traefik --namespace kube-system
kubectl delete service traefik --namespace kube-system

kubectl get services --all-namespaces

### Configure loadbalancer ip range

kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml

kubectl create configmap -n kube-system kubevip --from-literal range-global=<loadbalancer-ip-range>

### Test loadbalancer with nginx deployment

kubectl create namespace nginx

kubectl create deployment nginx --image nginx --namespace nginx

kubectl expose deployment nginx --namespace nginx --port=80 --type=LoadBalancer --name=nginx-service

## Optional

## Turn off password authentication for ssh for security

ssh-copy-id <username>@<ip>

### Edit ssh config

sudo nano /etc/ssh/sshd_config

### Edit the line:

### PasswordAuthentication no

### Restart SSH to apply

sudo systemctl reload ssh
sudo systemctl restart ssh
