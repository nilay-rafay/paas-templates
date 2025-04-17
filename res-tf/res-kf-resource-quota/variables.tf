variable "kubeconfig_path" {
  description = "Path to kubeconfig.json file"
  type        = string
  default     = "kubeconfig.json"

  validation {
    condition = (
      // Validate that the path is a valid file path:
      // - Can contain word characters, hyphens, periods, slashes, and underscores
      // - Must end with '.json'
      can(regex("^[\\w\\-./]+\\.json$", var.kubeconfig_path)) &&

      // - Ensure the length of the path does not exceed 255 characters
      length(var.kubeconfig_path) <= 255 &&

      // - Ensure the input is not empty
      var.kubeconfig_path != ""
    )
    
    error_message = "Config path must be a valid file path ending with '.json'. Maximum length is 255 characters."
  }
}

variable "kubeflow_namespace_name" {
  description = "Profile name for the Kubeflow namespace"
  type        = string
  default     = "example-namespace"

  validation {
    condition     = (
      // - Check that the namespace name is alphanumeric or has dashes (-) in between
      can(regex("^[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*$", var.kubeflow_namespace_name)) &&
      // - Check that the input is not empty
      var.kubeflow_namespace_name != ""
    )
    error_message = "The input must contain only letters, digits, and hyphens, and cannot start or end with a hyphen."
  }
}

variable "kubeflow_user_email" {
  description = "User email that owns Kubeflow namespace"
  type        = string
  default     = "user@example.com"

  validation {
    condition = (
      // Validate that the email address is valid
      // - Local email part can contain word characters, digits, dots, underscores, or hyphens
      // - Domain of email can contain word characters, digits, dots, or hyphens
      // - TLD of email can contain at least 2 characters and must be at end of string
      can(regex("^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.kubeflow_user_email)) &&
      // - Check that the input is not empty
      var.kubeflow_user_email != ""     

    )
    error_message = "The input must be a valid email address."
  }

}

variable "kubeflow_requests_cpu" {
  description = "Minimum CPU resources for Kubeflow namespace"
  type        = string
  default     = "1"

  validation {
    condition = (
      // Validate that the variable is only digits:
      // - Can contain digits
      can(regex("^[0-9]+$", var.kubeflow_requests_cpu)) &&  // Check the input is only comprised of digits
      can(tonumber(var.kubeflow_requests_cpu)) &&           // Check the input can be converted to a number
      tonumber(var.kubeflow_requests_cpu) > 0  &&           // Check that max number of CPU cores is at least 1
      var.kubeflow_requests_cpu != ""                       // Check that the input is not empty
    )
    
    error_message = "Kubeflow requests CPU must be a valid number greater than 0."
  }

}

variable "kubeflow_limit_cpu" {
  description = "Maximum CPU resources for Kubeflow namespace"
  type        = string
  default     = "5"

  validation {
    condition = (
      // Validate that the variable is only digits:
      // - Can contain digits
      can(regex("^[0-9]+$", var.kubeflow_limit_cpu)) &&  // Check the input is only comprised of digits
      can(tonumber(var.kubeflow_limit_cpu)) &&           // Check the input can be converted to a number
      tonumber(var.kubeflow_limit_cpu) > 0  &&           // Check that min number of CPU cores is at least 1
      var.kubeflow_limit_cpu != ""                       // Check that the input is not empty
    )
    
    error_message = "Kubeflow requests CPU must be a valid number greater than 0."
  }
}

variable "kubeflow_requests_memory" {
  description = "Minimum memory resources for Kubeflow namespace"
  type        = string
  default     = "1Gi"

  validation {
    condition = (
      // Validate that the variable is only digits:
      // - Can contain digits
      // - Must end with Gi or Mi
      can(regex("^[0-9]+(Gi|Mi)$", var.kubeflow_requests_memory)) &&
      // - Check that the input is not empty
      var.kubeflow_requests_memory != ""                       
    )
    
    error_message = "Kubeflow requests memory must be a valid number followed by Gi or Mi."
  }
}

variable "kubeflow_limit_memory" {
  description = "Maximum memory resources for Kubeflow namespace"
  type        = string
  default     = "10Gi"

  validation {
    condition = (
      // Validate that the variable is only digits:
      // - Can contain digits
      // - Must end with Gi or Mi
      can(regex("^[0-9]+(Gi|Mi)$", var.kubeflow_limit_memory)) &&

      // - Check that the input is not empty
      var.kubeflow_limit_memory != ""  
    )
    
    error_message = "Kubeflow limit memory must be a valid number followed by Gi or Mi."
  }
}

variable "kubeflow_requests_storage" {
  description = "Maximum storage resources for Kubeflow namespace"
  type        = string
  default     = "1Gi"

  validation {
    condition = (
      // Validate that the variable is only digits:
      // - Can contain digits
      // - Must end with Gi or Mi
      can(regex("^[0-9]+(Gi|Mi)$", var.kubeflow_requests_storage)) &&

      // - Check that the input is not empty
      var.kubeflow_requests_storage != ""
    )
    
    error_message = "Kubeflow requests storage must be a valid number followed by Gi or Mi."
  }
}

variable "kubeflow_ephemeral_storage" {
  description = "Maximum ephemeral storage resources for Kubeflow namespace"
  type        = string
  default     = "500Mi"

  validation {
    condition = (
      // Validate that the variable is only digits:
      // - Can contain digits
      // - Must end with Gi or Mi
      can(regex("^[0-9]+(Gi|Mi)$", var.kubeflow_ephemeral_storage)) &&

      // - Check that the input is not empty
      var.kubeflow_ephemeral_storage != ""  
    )
    
    error_message = "Kubeflow ephemeral storage must be a valid number followed by Gi or Mi."
  }
}

variable "hserver" {
  description = "Kubeconfig host server"
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
