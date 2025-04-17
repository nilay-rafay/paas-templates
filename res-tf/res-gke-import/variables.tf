# GKE cluster variable
variable "project_id" {
  type        = string
  description = "The project ID to host the cluster in (required)"
  validation {
    condition     = length(var.project_id) > 0
    error_message = "The GCP project ID must not be empty."
  }
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster (required)"
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "The cluster name must not be empty."
  }
}

variable "cluster_location" {
  type        = string
  description = "The location of the cluster (region if regional, zone if zonal cluster) (required)"
  validation {
    condition     = length(var.cluster_location) > 0
    error_message = "The cluster location must not be empty."
  }
}

# Rafay variables
variable "rafay_project_name" {
  type        = string
  description = "Rafay project name"
  default     = "defaultproject"
  validation {
    condition     = length(var.rafay_project_name) > 0
    error_message = "The Rafay project name must not be empty."
  }
}

variable "rafay_blueprint_name" {
  type        = string
  description = "The name of the blueprint used for imported cluster"
  default     = "minimal"
  validation {
    condition     = length(var.rafay_blueprint_name) > 0
    error_message = "The Rafay blueprint name must not be empty."
  }
}

variable "rafay_blueprint_version" {
  type        = string
  description = "The version of the blueprint."
  default     = "latest"
}

# variable "provider_config_file" {
#   type        = string
#   description = "The absolute path of the config RCTL config file downloaded from Rafay controller"
#   default     = "/root/.rafay/cli/config.json"
# }
