terraform {
  required_version = ">= 1.4.4"

  required_providers {
    helm = {
      source  = "registry.opentofu.org/opentofu/helm"
      version = "2.15.0"
    }
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

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
