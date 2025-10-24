module "talos_cluster" {
  source = "./modules/talos"

  cluster_name        = var.cluster_name
  cluster_endpoint    = var.cluster_endpoint
  control_plane_nodes = var.control_plane_nodes
  cluster_dns         = var.cluster_dns
}

module "flux_cluster" {
  source = "./modules/flux"

  bootstrap_node_ip    = var.control_plane_nodes[0]
  client_configuration = module.talos_cluster.client_configuration

  git_repo_url    = "ssh://git@github.com/jonahgcarpenter/homelab-oswald.git"
  git_branch      = var.flux_git_branch
  git_path        = var.flux_git_path
  ssh_private_key = var.flux_ssh_private_key
}
