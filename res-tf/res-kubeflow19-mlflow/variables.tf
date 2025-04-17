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

variable "helm_timeout" {
  description = "Time in seconds to wait for any individual kubernetes operation"
  type        = number
  default     = 1200
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  default     = "cluster-name"
}

variable "enable_mlflow" {
  description = "Enable MLflow"
  default     = true
}

variable "mlflow_persistence_config" {
  description = "MLFlow persistence configuration"
  type = object({
    postgres = object({
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
    postgres = {
      storage_class_name = ""
      storage_size       = "11Gi"
      access_mode        = "ReadWriteOnce"
    }
    minio = {
      storage_class_name = ""
      storage_size       = "11Gi"
      access_mode        = "ReadWriteOnce"
    }
  }
}

variable "k8s_mlflow_sa" {
  description = "The name of the Kubernetes service account to use for MLflow tracking."
  type        = string
  default     = "mlflow-tracking"
  nullable    = false
}
