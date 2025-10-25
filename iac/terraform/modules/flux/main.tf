# This provider is for any standard "kubernetes_*" resources
provider "kubernetes" {
  kubeconfig = var.kubeconfig
}

# Create a temporary kubeconfig file from the in-memory variable
# Use local_sensitive_file to remove the deprecation warning
resource "local_sensitive_file" "kubeconfig" {
  content  = var.kubeconfig
  filename = "${path.module}/.kubeconfig.yaml"
}

# This provider is for all "flux_*" resources
provider "flux" {
  kubernetes = {
    # Point the flux provider to the file we just created
    config_path = local_sensitive_file.kubeconfig.filename
  }

  git = {
    url    = var.git_repo_url
    branch = var.git_branch
    ssh = {
      username    = "git"
      private_key = var.ssh_private_key
    }
  }
}

resource "flux_bootstrap_git" "this" {
  path = var.git_path

  namespace            = "flux-system"
  components           = ["source-controller", "kustomize-controller", "helm-controller", "notification-controller"]
  components_extra     = ["image-reflector-controller", "image-automation-controller"]
  watch_all_namespaces = true

  depends_on = [
    var.bootstrap_dependency
  ]
}
