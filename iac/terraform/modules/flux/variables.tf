variable "cluster_endpoint" {
  description = "The FQDN or VIP of the cluster endpoint."
  type        = string
}

variable "kubeconfig" {
  description = "The raw kubeconfig for the cluster."
  type        = string
  sensitive   = true
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
