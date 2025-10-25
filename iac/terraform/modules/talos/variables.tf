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
