variable "name" {
  default = ""
}

variable "namespace" {
  type = string
}

variable "storage_size" {
  type    = string
  default = "200Gi"
}

variable "volume_mode" {
  type    = string
  default = "Filesystem"
}

variable "storage_class" {
  type    = string
  default = ""
}

variable "image" {
  type = string
}

variable "model" {
  type = string
}

variable "ingress_class_name" {
  type    = string
  default = "nginx"
}


variable "domain" {
  type    = string
  default = ""
}

variable "ingress_custom_domain" {
  type    = string
  default = ""
}
variable "gpu_type" {
  type    = string
  default = ""
}

variable "cpu_requests" {
  type    = string
  default = "2"
}

variable "cpu_limits" {
  type    = string
  default = "10"
}

variable "memory_requests" {
  type    = string
  default = "6Gi"
}

variable "memory_limits" {
  type    = string
  default = "20Gi"
}

variable "gpu_requests" {
  type    = string
  default = "1"
}

variable "gpu_limits" {
  type    = string
  default = "1"
}

variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "route53_zone_id" {
  default = "Z1OM749F0P8E4R"
}

variable "ingress_controller_ips" {
  default = []
}

variable "ingress_domain_type" {
  description = "Specifies the DNS host"
  default     = "Rafay"
  type        = string
}

variable "ingress_domain" {
  description = "Rafay Ingress Domain"
  nullable    = false
  default     = "paas.dev.rafay-edge.net"
}

variable "hserver" {
  description = "Kubeconfig server"
  type        = string
}

variable "clientcertificatedata" {
  description = "Kubeconfig client-certificate-data"
  type        = string
}

variable "clientkeydata" {
  description = "Kubeconfig client-key-data"
  type        = string
}

variable "certificateauthoritydata" {
  description = "Kubeconfig certificate-authority-data"
  type        = string
}

variable "kubeconfig" {
  description = "Kubeconfig"
  type        = string
}

variable "host_crt" {
  default = ""
}

variable "host_key" {
  default = ""
}

variable "tls_crt" {
  default = ""
}

variable "tls_key" {
  default = ""
}

variable "custom_secret_name" {
  default = ""
}

variable "ingress_annotations" {
  type        = map(string)
  description = "A map of annotations to apply to the ingress"
  default = {
    "kubernetes.io/tls-acme"                      = "true"
    "cert-manager.io/cluster-issuer"              = "letsencrypt-demo"
    "kubernetes.io/ingress.class"                 = "nginx"
    "nginx.ingress.kubernetes.io/proxy-body-size" = "50m"
  }
}