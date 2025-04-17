variable "feast_mysql_instance" {
  description = "MYSQL host"
}

variable "feast_mysql_port" {
  description = "MYSQL port"
}

variable "feast_mysql_user" {
  description = "MYSQL user"
}

variable "feast_mysql_password" {
  description = "MYSQL password"
}

variable "feast_redis_instance_name" {
  description = "Redis Instance Name"

  validation {
    condition = (
      // Ensure the name is not empty
      length(var.feast_redis_instance_name) > 0 &&

      // Length between 1 and 40 characters
      length(var.feast_redis_instance_name) >= 1 && length(var.feast_redis_instance_name) <= 40 &&

      // Validate format: 
      // - Must start with a lowercase letter
      // - Can contain lowercase letters, numbers, and hyphens
      // - Must end with a lowercase letter or number
      can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.feast_redis_instance_name)) &&

      // Ensure no consecutive hyphens
      !can(regex("--", var.feast_redis_instance_name))
    )

    error_message = "Redis instance name contains invalid character(s). Valid characters are [a-z0-9-], except at the beginning or the end. Minimum and maximum characters allowed are 1 and 40. Consecutive hyphens are not allowed."
  }
}

variable "feast_redis_is_external" {
  description = "Is Redis external"
  type = bool
}

variable "feast_redis_host" {
  description = "Redis host address"
  default     = "localhost"
}

variable "feast_redis_port" {
  description = "Redis port"
}

variable "gcp_service_list" {
  description = "The list of apis necessary for the project"
  type        = list(string)
  default = [
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
  ]
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  nullable    = false
}

variable "gcp_region" {
  description = "GCP Resource Region"
  type        = string
  nullable    = false
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