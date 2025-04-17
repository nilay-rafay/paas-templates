variable "cert_manager_enabled" {
  description = "Boolean flag to determine if the cert-manager should be deployed"
  type        = bool
  default     = true
}

variable "kubeflow_static_user_email" {
  description = "Username for the static user"
  type        = string
  default     = "user@example.com"
}

variable "kubeflow_static_user_password" {
  description = "Password for the static user"
  type        = string
  default     = "user"
}

variable "okta_client_id" {
  description = "OKTA OAuth client ID for authentication"
}

variable "okta_domain" {
  description = "OKTA Domain"
}

variable "okta_client_secret" {
  description = "OKTA OAuth client secret for authentication"
}

variable "istio_svc_type" {
  description = "Service type for Istio ingress gateway"
  type        = string
  default     = "LoadBalancer"
}

variable "istio_svc_lb_type" {
  description = "Loadbalancer type for Istio ingress gateway"
  type        = string
  default     = "Internal"
}

variable "enable_culling" {
  description = "Boolean flag to enable or disable culling of idle notebooks"
  type        = bool
  default     = true  # Default to enable culling
}

variable "cull_idle_time" {
  description = "The idle time in minutes after which a notebook will be culled, only if culling is enabled."
  type        = string
  default     = "30"  # Default to 30 minutes
  validation {
    condition = (
      var.cull_idle_time != "" &&                          # Validate that it's not an empty string
      var.cull_idle_time != null &&                        # Validate that it's not null
      can(tonumber(var.cull_idle_time)) &&                 # Ensure it can be converted to a number
      tonumber(var.cull_idle_time) >= 30 &&                # Validate it is at least 30 minutes
      tonumber(var.cull_idle_time) <= 10080                # Validate that it is no more than 7 days
    )
    error_message = "CULL_IDLE_TIME must be a non-empty numeric string between 30 and 10,080 minutes (7 days)."
  }
}

variable "kubeflow_mysql_instance" {
  description = "MYSQL instance name"
}

variable "kubeflow_mysql_port" {
  description = "MYSQL port"
}

variable "kubeflow_mysql_user" {
  description = "MYSQL user"
}

variable "kubeflow_mysql_password" {
  description = "MYSQL password"
}

variable "pipeline_external_s3_host" {
  description = "External S3 host for pipeline storage"
}

variable "pipeline_external_s3_bucket" {
  description = "External S3 bucket for pipeline storage"
}

variable "pipeline_external_s3_access_key" {
  description = "External S3 access key for pipeline storage"
}

variable "pipeline_external_s3_secret_key" {
  description = "External S3 secret key for pipeline storage"
}

variable "pipeline_external_s3_region" {
  description = "External S3 region for pipeline storage"
  type        = string
  default     = "auto"
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  nullable    = false
}

variable "gcp_service_list" {
  description = "The list of apis necessary for the project"
  type        = list(string)
  default = [
    "sqladmin.googleapis.com",
  ]
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

variable "project" {
  description = "Environment Project Name"
  default     = ""
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

variable "tls_crt" {
  description = "Path to the TLS certificate for Kubeflow host"
  nullable    = false
}

variable "tls_key" {
  description = "Path to the TLS private key for Kubeflow host"
  nullable    = false
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

variable "ingress_domain" {
  description = "Rafay Ingress Domain"
  nullable    = false
  default     = "paas.dev.rafay-edge.net"
}
