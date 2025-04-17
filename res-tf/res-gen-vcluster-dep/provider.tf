provider "helm" {
  kubernetes {
    config_path = local_file.kubeconfig.filename
  }
}

provider "kubernetes" {
  config_path = local_file.kubeconfig.filename
}

terraform {
  required_providers {
    rafay = {
      source = "RafaySystems/rafay"
      version = "1.1.41"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.16.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.33.0"
    }
    htpasswd = {
      source = "loafoe/htpasswd"
      version = "1.2.1"
    }
    null = {
      source = "hashicorp/null"
      version = "3.2.3"
    }
    local = {
      source = "hashicorp/local"
      version = "2.5.2"
    }
  }
}

provider "rafay" {
  provider_config_file = var.rctl_config_path
}
