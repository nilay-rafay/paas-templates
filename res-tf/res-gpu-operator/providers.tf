terraform {
  required_providers {
    rafay = {
      version = "1.1.38"
      source  = "RafaySystems/rafay"
    }
    kubernetes = {
      source = "registry.opentofu.org/opentofu/kubernetes"
      version = "2.33.0"
    }
     helm = {
      source = "hashicorp/helm"
      version = "2.16.1"
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

provider "kubernetes" {
  config_path = local_file.kubeconfig.filename
}

