variable "cluster_name" {
  description = "The name of the host cluster"
  type        = string
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "The cluster name must not be empty."
  }
}

variable "host_project" {
  description = "The project of the host cluster."
  type        = string
  validation {
    condition     = length(var.host_project) > 0
    error_message = "The project must not be empty."
  }
}

variable "kuberay_version" {
  description = "kuberay version"
  type        = string
  default     = "1.1.0"
}

variable "volcano_version" {
  description = "volcano version"
  type        = string
  default     = "1.11.0"
}

variable "kuberay_head_config" {
  description = "kuberay head node configurations"
  type        = map(string)
  default = {
    "repository"              = "rayproject/ray"
    "tag"                     = "2.37.0"
    "enableInTreeAutoscaling" = true
    "cpu"                     = 1
    "memory"                  = "2Gi"
  }
}

variable "kuberay_worker_config" {
  description = "kuberay worker node configurations"
  type        = map(string)
  default = {
    "repository"  = "rayproject/ray"
    "tag"         = "2.37.0"
    "replicas"    = 0
    "minReplicas" = 0
    "maxReplicas" = 1
    "cpu"         = 1
    "memory"      = "2Gi"
    "gpu"         = 1
  }
}

variable "kuberay_worker_tolerations" {
  description = "Adding tolerations for kuberay worker nodes"
  type = map(object({
    key    = string
    value  = string
    effect = string
  }))
  default = {}
}

variable "kuberay_worker_node_selector" {
  description = "Adding nodeSelector for kuberay worker nodes"
  type        = map(string)
  default     = {}
}

variable "environment_name" {
  description = "Environment name for kuberay cluster endpoint"
  type        = string
  validation {
    condition     = length(var.environment_name) > 0
    error_message = "The environment name must not be empty."
  }
}

variable "ingress_user" {
  description = "Username to access kuberay cluster endpoint"
  type        = string
  default     = "admin"
}

variable "ingress_class" {
  description = "Ingress Class Name"
  type        = string
  default     = "default-rafay-nginx"
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
  description = "Kubeconfig "
  type        = string
}

variable "tls_crt" {
  description = "Path to the TLS certificate for Kubeflow host"
  nullable    = false
}

variable "tls_key" {
  description = "Path to the TLS private key for Kubeflow host"
  nullable    = false
}

variable "custom_secret_name" {
  description = "Secret Name of TLS Crt and Key file"
  default     = ""
}

variable "kuberay_host_name" {
  description = "Hostname for Kuberay"
  default     = ""
}

variable "kuberay_host_cert" {
  description = "Path to the TLS certificate for Kuberay host"
  default     = ""
}

variable "kuberay_host_key" {
  description = "Path to the TLS private key for Kuberay host"
  default     = ""
}

variable "enable_volcano" {
  description = "Toggle true if Volcano should be installed on the cluster"
  default     = "true"
}