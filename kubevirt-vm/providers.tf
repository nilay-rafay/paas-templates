terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "=2.35.1"
    }
    local = {
      source = "hashicorp/local"
      version = "=2.5.2"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "=1.19.0"
    }
    macaddress = {
      source = "ivoronin/macaddress"
      version = "=0.3.2"
    }
  }
}

provider "kubectl" {
  config_path = "kubeconfig.json"
}

provider "kubernetes" {
  config_path = "kubeconfig.json"
}

provider "local" {}

provider "macaddress" {}
