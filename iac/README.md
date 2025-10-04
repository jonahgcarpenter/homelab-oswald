# Talos Proxmox Cluster Guide

## Talos Setup

Follow these steps in order to configure and bootstrap your Talos cluster. Official docs can be found [here](https://www.talos.dev/v1.11/talos-guides/install/virtualized-platforms/proxmox/).

1.  **Find Your Virtio Disk**

    Identify the name of the installation disk on your node.

    ```bash
    talosctl get disk -n $CONTROL_PLANE_IP --insecure
    ```

2.  **Generate Your Config**

    Create the configuration files. If necessary, replace `/dev/vda` with the disk you found in the previous step. You can optionally add a DNS name as the `--additional-sans` this makes sure a dns name will be added to the cert, this is for kubevip later.

    ```bash
    talosctl gen config --install-disk "/dev/vda" talos-proxmox-cluster https://$CONTROL_PLANE_IP:6443 --additional-sans $CLUSTER_DNS --output talos-config --install-image factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.11.0
    ```

3.  **(Optional) Modify Control Plane Config**

    > For my setup, I wanted only 3 control plane nodes.
    > To do this, uncomment the very last line in the `controlplane.yaml` config file to allow scheduling pods on the control plane nodes as explained [here](https://www.talos.dev/v1.11/talos-guides/howto/workers-on-controlplane/).

4.  **Apply the Config to All Nodes**

    Apply the generated machine configuration to your nodes.

    ```bash
    talosctl apply-config --insecure --nodes $CONTROL_PLANE_IPS --file talos-config/controlplane.yaml
    ```

5.  **Bootstrap the Cluster**

    Set your local `talosconfig` and bootstrap the cluster.

    ```bash
    export TALOSCONFIG="talos-config/talosconfig"
    talosctl config endpoint $CONTROL_PLANE_IP
    talosctl config node $CONTROL_PLANE_IP
    ```

    Now, run the bootstrap command:

    ```bash
    talosctl bootstrap
    ```

    Finally, grab your `kubeconfig` file:

    ```bash
    talosctl kubeconfig ~/.kube/config
    ```

---
