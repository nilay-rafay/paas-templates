terraform {
  required_providers {
    rafay = {
      source = "RafaySystems/rafay"
      version = "1.1.41"
    }
    kubectl = {
      source = "bnu0/kubectl"
      version = "0.27.0"
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

provider "helm" {
  kubernetes {
    host                   = local.k8s_host
    client_certificate     = local.k8s_client_certificate
    client_key             = local.k8s_client_key
    cluster_ca_certificate = local.k8s_cluster_ca_certificate
  }
}

provider "kubectl" {
  host                   = local.k8s_host
  client_certificate     = local.k8s_client_certificate
  client_key             = local.k8s_client_key
  cluster_ca_certificate = local.k8s_cluster_ca_certificate
  load_config_file = false
}

provider "rafay" {
  provider_config_file = var.rctl_config_path
}