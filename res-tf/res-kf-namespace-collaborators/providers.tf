terraform {
  required_providers {
    helm = {
      source  = "registry.opentofu.org/opentofu/helm"
      version = "2.15.0"
    }
    rafay = {
      version = "1.1.38"
      source  = "RafaySystems/rafay"
    }
    bcrypt = {
      source  = "viktorradnai/bcrypt"
      version = "0.1.2"
    }
    kubernetes = {
      source  = "registry.opentofu.org/opentofu/kubernetes"
      version = "2.33.0"
    }
  }
}


provider "helm" {
  kubernetes {
  host = var.hserver 
  client_certificate     = base64decode(var.clientcertificatedata)
  client_key             = base64decode(var.clientkeydata)
  cluster_ca_certificate = base64decode(var.certificateauthoritydata)
  }
}

provider "kubernetes" {
  host = var.hserver 
  client_certificate     = base64decode(var.clientcertificatedata)
  client_key             = base64decode(var.clientkeydata)
  cluster_ca_certificate = base64decode(var.certificateauthoritydata)
}

provider "bcrypt" {}


