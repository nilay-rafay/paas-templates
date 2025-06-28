provider "kubernetes" {
  alias       = "vcluster"
  config_path = "/tmp/test/${var.vm_name}-kubeconfig.yaml"
}

terraform {
  required_providers {
    rafay = {
     source  = "RafaySystems/rafay"
      version = "1.1.41"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.33.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
  }
}

provider "rafay" {
  provider_config_file = var.rctl_config_path
}
