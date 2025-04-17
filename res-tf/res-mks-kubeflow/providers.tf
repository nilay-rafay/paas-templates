terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }
    rafay = {
      version = "1.1.38"
      source  = "RafaySystems/rafay"
    }
    bcrypt = {
      source  = "registry.opentofu.org/viktorradnai/bcrypt"
      version = "0.1.2"
    }
    random = {
      source  = "registry.opentofu.org/opentofu/random"
      version = "3.6.3"
    }
    kubernetes = {
      source  = "registry.opentofu.org/opentofu/kubernetes"
      version = "2.33.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = local_file.kubeconfig.filename
  }
}

provider "kubernetes" {
  config_path = local_file.kubeconfig.filename
}

provider "bcrypt" {}

provider "random" {}
