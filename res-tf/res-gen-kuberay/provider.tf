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

terraform {
  required_providers {
    rafay = {
      source = "RafaySystems/rafay"
      version = "1.1.41"
    }
    htpasswd = {
      source = "loafoe/htpasswd"
      version = "1.2.1"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.16.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.33.0"
    }
    null = {
      source = "hashicorp/null"
      version = "3.2.3"
    }
    local = {
      source = "hashicorp/local"
      version = "2.5.2"
    }
    random = {
      source = "hashicorp/random"
      version = "3.6.3"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.5"
    }
    external = {
      source = "hashicorp/external"
      version = "2.3.4"
    }
  }
}
