resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  config_patches = [
    yamlencode({
      cluster = {
        apiServer = {
          certSANs = [var.cluster_dns]
        }
      }
    }),
    yamlencode({
      cluster = {
        allowSchedulingOnControlPlanes = true
      }
    }),
    yamlencode({
      machine = {
        install = {
          disk = "/dev/vda"
        }
      }
    }),
    yamlencode({
      cluster = {
        network = {
          apiServer = {
            loadBalancer = {
              enabled = true
            }
          }
        }
      },
      machine = {
        network = {
          interfaces = [
            {
              subnet = var.controlplane_subnet
              vip = {
                ip = regex("https://([^:]+):", var.cluster_endpoint)[0]
              }
            }
          ]
        }
      }
    })
  ]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = var.control_plane_nodes
}


resource "talos_machine_configuration_apply" "controlplane" {
  for_each = toset(var.control_plane_nodes)

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration

  endpoint = each.key
  node     = each.key
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  client_configuration = talos_machine_secrets.this.client_configuration

  endpoint = var.control_plane_nodes[0]
  node     = var.control_plane_nodes[0]
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_machine_bootstrap.this]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.control_plane_nodes[0]
}
