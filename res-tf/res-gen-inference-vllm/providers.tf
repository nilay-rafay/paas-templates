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


provider "aws" {
  region = var.aws_region
}
