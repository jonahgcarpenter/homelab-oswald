provider "kubernetes" {
  host = var.cluster_endpoint

  client_certificate     = base64decode(var.client_configuration.client_certificate)
  client_key             = base64decode(var.client_configuration.client_key)
  cluster_ca_certificate = base64decode(var.client_configuration.ca_certificate)
}

provider "flux" {
  kubernetes = {
    host = var.cluster_endpoint

    client_certificate     = base64decode(var.client_configuration.client_certificate)
    client_key             = base64decode(var.client_configuration.client_key)
    cluster_ca_certificate = base64decode(var.client_configuration.ca_certificate)
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
}
