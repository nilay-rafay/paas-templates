variable "host_cluster_name" {
  description = "The name of the host cluster"
  type        = string
  validation {
    condition     = length(var.host_cluster_name) > 0
    error_message = "The cluster name must not be empty."
  }
}

variable "vcluster_name" {
  description = "Name of the vcluster to deploy"
  type        = string
  validation {
    condition     = length(var.vcluster_name) > 0
    error_message = "The cluster name must not be empty."
  }
}

variable "project" {
  description = "The project to deploy the vcluster."
  type        = string
  validation {
    condition     = length(var.project) > 0
    error_message = "The project must not be empty."
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

variable "blueprint" {
  description = "The Blueprint to deploy the vcluster."
  type        = string
  default     = "minimal"
}

variable "blueprint_version" {
  description = "The Blueprint version"
  type        = string
  default     = "latest"
}

variable "default_charts" {
  description = "mapping for vcluster distro"
  default = {
    "k3s" = "vcluster",
    "k0s" = "vcluster-k0s",
    "k8s" = "vcluster-k8s"
  }
}

variable "distro" {
  description = "vCLuster Distribution"
  type        = string
  default     = "k3s"
}

variable "vcluster_store_size" {
  description = "Size is the persistent volume claim storage size for vCLuster"
  type        = string
  default     = "50Gi"

}

variable "namespace" {
  description = "The namespace to deploy the vcluster."
  type        = string
  validation {
    condition     = length(var.namespace) > 0
    error_message = "The namespace must not be empty."
  }
}

variable "namespace_labels" {
  type    = map(string)
  default = {}
}

variable "namespace_annotations" {
  type    = map(string)
  default = {}
}

variable "tolerations" {
  description = "Adding tolerations to vcluster config , for the pods to be synced to host cluster with a specific tolerations and placed on the respected allocated nodes/gpu type"
  type = map(object({
    key    = string
    value  = string
    effect = string
  }))
  default = {}
}



variable "vcluster_version" {
  description = "vCluster chart/application version"
  type        = string
  default     = "v0.20.0"

}

variable "kuberay_version" {
  description = "kuberay version"
  type        = string
  default     = "1.1.0"
}

variable "kuberay_head_config" {
  description = "kuberay head node configurations"
  type        = map(string)
  default = {
    "repository"              = "rayproject/ray"
    "tag"                     = "2.37.0"
    "enableInTreeAutoscaling" = true
    "cpu"                     = 4
    "memory"                  = "16Gi"
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
    "maxReplicas" = 5
    "cpu"         = 8
    "memory"      = "32Gi"
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

variable "cluster_issuer_name" {
  description = "CertManager Cluster Issuer name"
  type        = string
  default     = "vcluster-issuer"
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

variable "username" {
  description = "Username to add into new group"
  type        = string
}

variable "user_type" {
  description = "Rafay user type (sso or local)"
  type        = bool
}

variable "create_group" {
  description = "Create override group condition"
  type        = bool
  default     = true
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

variable "secret_name" {
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

variable "domain" {
  description = "Domain for kuberay cluster endpoint"
  type        = string
  default     = ""
}