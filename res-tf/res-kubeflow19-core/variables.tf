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

variable "name" {
  description = "Deployment Name"
  default     = ""
  type        = string
}

variable "ingress_domain_type" {
  description = "Specifies the DNS host"
  default     = "Rafay"
  type        = string
}

variable "helm_timeout" {
  description = "Time in seconds to wait for any individual kubernetes operation"
  type        = number
  default     = 1200
}

variable "tls_crt" {
  description = "Path to the TLS certificate for Kubeflow host"
  nullable    = false
}

variable "tls_key" {
  description = "Path to the TLS private key for Kubeflow host"
  nullable    = false
}

variable "ingress_domain" {
  description = "Rafay Ingress Domain"
  nullable    = false
  default     = "paas.dev.rafay-edge.net"
}

variable "okta_client_id" {
  description = "OKTA OAuth client ID for authentication"
  sensitive   = true
}

variable "okta_domain" {
  description = "OKTA Domain"
}

variable "okta_client_secret" {
  description = "OKTA OAuth client secret for authentication"
  sensitive   = true
}

variable "kubeflow_static_user_email" {
  description = "Username for the static user"
  type        = string
  default     = "user@example.com"
}

variable "kubeflow_static_user_password" {
  description = "Password for the static user"
  type        = string
  sensitive   = true
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

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  default     = "cluster-name"
}

variable "istio_ingress_class_name" {
  description = "Ingress class name for Istio"
  type        = string
  default     = "default-rafay-nginx"
}

variable "cert_manager_enabled" {
  description = "Boolean flag to determine if the cert-manager should be deployed"
  type        = bool
  default     = true
}

variable "kubeflow_host_name" {
  description = "Hostname for Kubeflow"
  validation {
    condition = (
      var.ingress_domain_type != "Custom" || length(var.kubeflow_host_name) > 0
    )
    error_message = "Kubeflow Host Name must be non-empty when Ingress Domain is set to 'Custom'."
  }
}

variable "kubeflow_host_cert" {
  description = "Path to the TLS certificate for Kubeflow host"
  default     = ""
  validation {
    condition = (
      var.ingress_domain_type != "Custom" || length(var.kubeflow_host_cert) > 0
    )
    error_message = "Kubeflow Host Cert must be non-empty when Ingress Domain is set to 'Custom'."
  }
}

variable "kubeflow_host_key" {
  description = "Path to the TLS private key for Kubeflow host"
  default     = ""
  validation {
    condition = (
      var.ingress_domain_type != "Custom" || length(var.kubeflow_host_key) > 0
    )
    error_message = "Kubeflow Host Key must be non-empty when Ingress Domain is set to 'Custom'."
  }
}

variable "istio_svc_type" {
  description = "Service type for Istio ingress gateway"
  type        = string
  default     = "ClusterIP"
}

variable "enable_culling" {
  description = "Boolean flag to enable or disable culling of idle notebooks"
  type        = bool
  default     = true # Default to enable culling
}

variable "cull_idle_time" {
  description = "The idle time in minutes after which a notebook will be culled, only if culling is enabled."
  type        = string
  default     = "30" # Default to 30 minutes
  validation {
    condition = (
      var.cull_idle_time != "" &&           # Validate that it's not an empty string
      var.cull_idle_time != null &&         # Validate that it's not null
      can(tonumber(var.cull_idle_time)) &&  # Ensure it can be converted to a number
      tonumber(var.cull_idle_time) >= 30 && # Validate it is at least 30 minutes
      tonumber(var.cull_idle_time) <= 10080 # Validate that it is no more than 7 days
    )
    error_message = "CULL_IDLE_TIME must be a non-empty numeric string between 30 and 10,080 minutes (7 days)."
  }
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
