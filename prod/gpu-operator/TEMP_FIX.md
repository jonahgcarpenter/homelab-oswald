kubectl edit daemonset nvidia-container-toolkit-daemonset -n gpu-operator

# Change this

```bash
- hostPath:
          path: /etc/containerd
          type: DirectoryOrCreate
        name: containerd-config
      - hostPath:
          path: /run/containerd
          type: ""
        name: containerd-socket
```

# To this

```bash
- hostPath:
          path: /var/lib/rancher/k3s/agent/etc/containerd
          type: DirectoryOrCreate
        name: containerd-config
      - hostPath:
          path: /run/k3s/containerd
          type: ""
        name: containerd-socket
```
