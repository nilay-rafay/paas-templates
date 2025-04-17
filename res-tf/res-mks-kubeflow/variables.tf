variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  default     = "upstream-cluster"
}

variable "cert_manager_enabled" {
  description = "Boolean flag to determine if the cert-manager should be deployed"
  type        = bool
  default     = true
}

variable "enable_mlflow" {
  description = "Enable MLflow"
  default     = true
}

variable "kubeflow_host_name" {
  description = "Hostname for Kubeflow"
  default     = "test-kubeflowhost"
  nullable    = false
}

variable "istio_svc_type" {
  description = "Service type for Istio ingress gateway"
  type        = string
  default     = "ClusterIP"
}

variable "istio_ingress_class_name" {
  description = "Ingress class name for Istio"
  type        = string
  default     = "default-rafay-nginx"
}

variable "kubeflow_host_cert" {
  description = "Path to the TLS certificate for Kubeflow host"
  sensitive   = true
  nullable    = false
  validation {
    condition = startswith(trimspace(var.kubeflow_host_cert), "-----BEGIN CERTIFICATE-----") && endswith(
    trimspace(var.kubeflow_host_cert), "-----END CERTIFICATE-----")
    error_message = "The certificate must begin with '-----BEGIN CERTIFICATE-----' and end with '-----END CERTIFICATE-----'."
  }
}

variable "kubeflow_host_key" {
  description = "Path to the TLS private key for Kubeflow host"
  sensitive   = true
  nullable    = false
  validation {
    condition = startswith(trimspace(var.kubeflow_host_key), "-----BEGIN PRIVATE KEY-----") && endswith(
    trimspace(var.kubeflow_host_key), "-----END PRIVATE KEY-----")
    error_message = "The private key must begin with '-----BEGIN PRIVATE KEY-----' and end with '-----END PRIVATE KEY-----'."
  }
}

variable "kubeflow_local_users" {
  description = "List of local users to create"
  type = list(object({
    username = string
    password = string
  }))
  default = [
    {
      username = "admin@example.com"
      password = "changeplz"
    }
  ]
  sensitive = true
}

variable "katib_persistence_config" {
  description = "Katib persistence configuration"
  type = object({
    mysql = object({
      storage_class_name = string
      storage_size       = string
      access_mode        = string
    })
  })
  default = {
    mysql = {
      storage_class_name = ""
      storage_size       = "12Gi"
      access_mode        = "ReadWriteOnce"
    }
  }
}

variable "kfp_persistence_config" {
  description = "Kubeflow Pipelines persistence configuration"
  type = object({
    mysql = object({
      storage_class_name = string
      storage_size       = string
      access_mode        = string
    })
    minio = object({
      storage_class_name = string
      storage_size       = string
      access_mode        = string
    })
  })
  default = {
    mysql = {
      storage_class_name = ""
      storage_size       = "12Gi"
      access_mode        = "ReadWriteOnce"
    }
    minio = {
      storage_class_name = ""
      storage_size       = "13Gi"
      access_mode        = "ReadWriteOnce"
    }
  }
}
