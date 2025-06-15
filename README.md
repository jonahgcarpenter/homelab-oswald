# My Homelab config

## TODO: Fix svclb pods on reboot since we're using kubevip

### Check for all pods

kubectl get daemonset -n kube-system | grep svclb

### Delete those pods

kubectl delete daemonset -n kube-system \
 svclb-longhorn-frontend-65ffa9a9 \
 svclb-portainer-agent-e0afa5ce \
 svclb-traefik-a6e1f009
