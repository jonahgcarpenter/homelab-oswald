terraform {
  required_providers {
    flux = {
      source  = "fluxcd/flux"
      version = "1.7.3"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
  }
}
