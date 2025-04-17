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

variable "helm_timeout" {
  description = "Time in seconds to wait for any individual kubernetes operation"
  type        = number
  default     = 1200
}

variable "enable_feast" {
  description = "Enable Feast"
  default     = true
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  default     = "cluster-name"
}

variable "mysql_feast_helm_release_name" {
  description = "The name of the MySQL Feast Helm release"
  type        = string
  default     = "mysql"
}

variable "mysql_feast_helm_repository" {
  description = "The MySQL Feast Helm chart repository URL"
  type        = string
  default     = "oci://registry-1.docker.io/bitnamicharts"
}

variable "mysql_feast_helm_chart" {
  description = "The MySQL Feast Helm chart name"
  type        = string
  default     = "mysql"
}

variable "redis_feast_helm_release_name" {
  description = "The name of the Redis Feast Helm release"
  type        = string
  default     = "redis"
}

variable "redis_feast_helm_repository" {
  description = "The Redis Feast Helm chart repository URL"
  type        = string
  default     = "oci://registry-1.docker.io/bitnamicharts"
}

variable "redis_feast_helm_chart" {
  description = "The Redis Feast Helm chart name"
  type        = string
  default     = "redis"
}

variable "feast_helm_release_name" {
  description = "The name of the Feast Helm release"
  type        = string
  default     = "feast"
}

variable "feast_helm_repository" {
  description = "The Feast Helm chart repository URL"
  type        = string
  default     = "https://feast-helm-charts.storage.googleapis.com"
}

variable "feast_helm_chart" {
  description = "The Feast Helm chart name"
  type        = string
  default     = "feast-feature-server"
}

variable "feast_persistence_config" {
  description = "Feast persistence configuration"
  type = object({
    mysql = object({
      storage_class_name = string
      storage_size       = string
      access_mode        = string
    })
    redis = object({
      memory_limit = string
    })
  })
  default = {
    mysql = {
      storage_class_name = ""
      storage_size       = "11Gi"
      access_mode        = "ReadWriteOnce"
    }
    redis = {
      memory_limit = "5Gi"
    }
  }
}
