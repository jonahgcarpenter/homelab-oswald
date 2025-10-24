module "talos_cluster" {
  source = "./modules/talos"

  cluster_name        = var.cluster_name
  cluster_endpoint    = var.cluster_endpoint
  control_plane_nodes = var.control_plane_nodes
  cluster_dns         = var.cluster_dns
}
