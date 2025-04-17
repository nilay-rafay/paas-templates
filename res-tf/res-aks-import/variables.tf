# AKS cluster variable
variable "resource_group" {
  type        = string
  description = "The AKS resource group to host the cluster in (required)"
  validation {
    condition     = length(var.resource_group) > 0
    error_message = "The AKS resource group must not be empty."
  }
  default = "dev-rg-ci"
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster (required)"
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "The cluster name must not be empty."
  }
  default = "dev-caas-1"
}

# Rafay variables
variable "rafay_cluster_name" {
  type        = string
  description = "Rafay cluster name"
  validation {
    condition     = length(var.rafay_cluster_name) > 0
    error_message = "The Rafay cluster name must not be empty."
  }
  default = "dev-import-1"
}

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
#   default     = "/Users/mvgautham/go/src/github.com/RafaySystems/rctl/configs/tbd1.json"
# }
