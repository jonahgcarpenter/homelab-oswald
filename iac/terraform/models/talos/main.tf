locals {
  talos_nodes = {
    "talos-01" = {
      target_node = "pve-3"
    },
    "talos-02" = {
      target_node = "pve-3"
    },
    "talos-03" = {
      target_node = "pve-3"
    },
  }
}

resource "proxmox_vm_qemu" "talos" {
  for_each = local.talos_nodes

  agent  = 1
  boot   = "order=virtio0;ide2;net0"
  memory = 4096
  cpu {
    cores = 2
  }
  name        = each.key
  onboot      = true
  scsihw      = "virtio-scsi-single"
  target_node = each.value.target_node

  disks {
    ide {
      ide2 {
        cdrom {
          iso = "local:iso/nocloud-amd64.iso"
        }
      }
    }
    virtio {
      virtio0 {
        disk {
          size    = "100G"
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    bridge = "vmbr0"
    id     = 0
    model  = "virtio"
  }
}
