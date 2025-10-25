module "talos_cluster" {
  source = "./modules/talos"

  cluster_name        = var.cluster_name
  cluster_endpoint    = var.cluster_endpoint
  control_plane_nodes = var.control_plane_nodes
  cluster_dns         = var.cluster_dns
  cluster_vip         = var.cluster_vip
}

module "flux_cluster" {
  source = "./modules/flux"

  kubeconfig = module.talos_cluster.kubeconfig

  git_repo_url    = "ssh://git@github.com/jonahgcarpenter/homelab-oswald.git"
  git_branch      = var.flux_git_branch
  git_path        = var.flux_git_path
  ssh_private_key = var.flux_ssh_private_key

  bootstrap_dependency = module.talos_cluster.bootstrap
}
