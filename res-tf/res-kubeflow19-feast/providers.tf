terraform {
  required_providers {
    helm = {
      source  = "opentofu/helm"
      version = "2.15.0"
    }
    rafay = {
      version = "1.1.38"
      source  = "RafaySystems/rafay"
    }
    random = {
      source  = "opentofu/random"
      version = "3.6.3"
    }
    kubernetes = {
      source  = "opentofu/kubernetes"
      version = "2.32.0"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = var.hserver
    client_certificate     = base64decode(var.clientcertificatedata)
    client_key             = base64decode(var.clientkeydata)
    cluster_ca_certificate = base64decode(var.certificateauthoritydata)
  }
}

provider "kubernetes" {
  host                   = var.hserver
  client_certificate     = base64decode(var.clientcertificatedata)
  client_key             = base64decode(var.clientkeydata)
  cluster_ca_certificate = base64decode(var.certificateauthoritydata)
}

provider "random" {}