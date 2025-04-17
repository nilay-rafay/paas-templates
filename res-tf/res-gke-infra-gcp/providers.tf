terraform {
  required_providers {
    rafay = {
      source  = "RafaySystems/rafay"
      version = "1.1.38"
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