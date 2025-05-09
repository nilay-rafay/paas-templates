variable "cluster_name" {
  description = "The name of the host cluster"
  type        = string
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "The cluster name must not be empty."
  }
}

variable "rctl_config_path" {
  description = "The path to the Rafay CLI config file"
  type        = string
  default     = "opt/rafay"
}

variable "enable_kata" {
  description = "deploy kata"
  type = bool
  default = false
}