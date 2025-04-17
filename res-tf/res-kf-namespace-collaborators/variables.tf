variable "kubeflow_namespace_name" {
  description = "Profile name for the Kubeflow namespace"
  type        = string
  default     = "namespace-example"

  validation {
    condition     = (
      can(regex("^[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*$", var.kubeflow_namespace_name))
    )
    error_message = "The input must contain only letters, digits, and hyphens, and cannot start or end with a hyphen."
  }
}

variable "kubeflow_collaborator_editors" {
  description = "Emails of users to be added as namespace editors"
  type        = list(string)
  default     = [ "user@example.com", "user2@example.com" ]

  validation {
    condition     = alltrue([for email in var.kubeflow_collaborator_editors : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))])
    error_message = "Each item in the kubeflow_collaborator_editors list must be a valid email address."
  }
}

variable "kubeflow_collaborator_viewers" {
  description = "Emails of users to be added as namespace viewers"
  type        = list(string)
  default     = [ "user3@example.com" ]

  validation {
    condition     = alltrue([for email in var.kubeflow_collaborator_viewers : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))])
    error_message = "Each item in the kubeflow_collaborator_viewers list must be a valid email address."
  }
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
