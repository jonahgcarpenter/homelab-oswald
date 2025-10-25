# --- Talos Variables ---

variable "cluster_name" {
  description = "A name for the cluster."
  type        = string
}

variable "cluster_endpoint" {
  description = "The Virtual IP (VIP) or Load Balancer IP for the control plane."
  type        = string
}

variable "control_plane_nodes" {
  description = "A list of IP addresses for the control plane nodes."
  type        = list(string)
}

variable "cluster_dns" {
  description = "An additional DNS name to add to the cluster's certificate."
  type        = string
  default     = null
}

variable "controlplane_subnet" {
  description = "The CIDR of the control plane subnet (e.g., 192.168.1.0/24)."
  type        = string
}

# --- Flux Variables ---

variable "flux_git_path" {
  description = "Path in the Git repo for Flux to sync."
  type        = string
}

variable "flux_git_branch" {
  description = "Branch for Flux to sync."
  type        = string
  default     = "main"
}

variable "flux_ssh_private_key" {
  description = "The SSH private key content for Flux."
  type        = string
  sensitive   = true
}
