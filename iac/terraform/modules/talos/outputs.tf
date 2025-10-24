output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "client_configuration" {
  description = "The raw client auth certificates."
  value       = talos_machine_secrets.this.client_configuration
  sensitive   = true
}
