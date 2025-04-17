variable "image" {
  default = "jupyter/minimal-notebook:latest"
}

variable "ingress_domain_type" {
  default = "Rafay"
}

variable "ingress_domain" {
  default = "paas.dev.rafay-edge.net"
}

variable "ingress_custom_domain" {
  default = ""
}

variable "name" {
  default = ""
}

variable "project" {
  default = ""
}

variable "namespace" {
  default = ""
}

variable "cluster_name" {
  default = ""
}

variable "notebook_profiles" {
  description = "(Optional) Profiles of Notebook."
  type        = list(any)
  default = [
    {
      "name" : "Minimal environment",
      "image" : "jupyter/minimal-notebook:latest"
    },
    {
      "name" : "Datascience environment",
      "image" : "jupyter/datascience-notebook:latest"
    },
    {
      "name" : "Spark environment",
      "image" : "jupyter/all-spark-notebook:latest"
    },
    {
      "name" : "Tensorflow environment",
      "image" : "jupyter/tensorflow-notebook:latest"
    },
    {
      "name" : "Tensorflow environment with CUDA",
      "image" : "quay.io/jupyter/tensorflow-notebook:cuda-latest"
    },
    {
      "name" : "PyTorch environment with CUDA",
      "image" : "quay.io/jupyter/pytorch-notebook:cuda11-latest"
    }
  ]
}

variable "notebook_profile" {
  default = "Minimal environment"
}

variable "cpu_request" {
  default = "1"
}

variable "memory_request" {
  default = "1Gi"
}

variable "cpu_limit" {
  default = "2"
}

variable "memory_limit" {
  default = "4Gi"
}

variable "gpu_limit" {
  default = "0"
}

variable "pvc_storage" {
  default = "1Gi"
}

variable "hserver" {
}

variable "clientcertificatedata" {
}

variable "clientkeydata" {
}

variable "certificateauthoritydata" {
}

variable "ingress_annotations" {
  type        = map(string)
  description = "A map of annotations to apply to the ingress"
  default = {
      "kubernetes.io/tls-acme" = "true"
      "cert-manager.io/cluster-issuer" = "letsencrypt-demo"
      "kubernetes.io/ingress.class" = "nginx"
      "nginx.ingress.kubernetes.io/proxy-body-size" = "50m"
    }
}

variable "tls_crt" {}

variable "tls_key" {}

variable "custom_secret_name" {}
