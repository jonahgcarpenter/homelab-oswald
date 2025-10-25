variable "cluster_endpoint" {
  description = "The Virtual IP (VIP) or Load Balancer IP for the control plane."
  type        = string
}

variable "client_configuration" {
  description = "The raw client configuration from talos_machine_secrets."
  type = object({
    ca_certificate     = string
    client_certificate = string
    client_key         = string
  })
  sensitive = true
}

variable "git_repo_url" {
  description = "The SSH URL of the Git repository."
  type        = string
}

variable "git_branch" {
  description = "The default branch of the repository."
  type        = string
  default     = "main"
}

variable "git_path" {
  description = "The path within the repository where Flux will look for its configuration."
  type        = string
}

variable "ssh_private_key" {
  description = "The SSH private key to access the Git repository."
  type        = string
  sensitive   = true
}

variable "bootstrap_dependency" {
  description = "A resource to explicitly depend on before running bootstrap."
  type        = any
  default     = null
}
