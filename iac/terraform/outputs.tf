output "kubeconfig" {
  description = "Kubeconfig for the cluster."
  value       = module.talos_cluster.kubeconfig
  sensitive   = true
}

output "talosconfig" {
  description = "Talosconfig for the cluster."
  value       = module.talos_cluster.talosconfig
  sensitive   = true
}
