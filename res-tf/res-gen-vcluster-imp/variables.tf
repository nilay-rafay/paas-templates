
variable "vcluster_name" {
  description = "Name of the vcluster to deploy"
  type        = string
  validation {
    condition     = length(var.vcluster_name) > 0
    error_message = "The cluster name must not be empty."
  }
}

variable "project" {
  description = "The project to deploy the vcluster."
  type        = string
  validation {
    condition     = length(var.project) > 0
    error_message = "The project must not be empty."
  }
}


variable "blueprint" {
  description = "The Blueprint to deploy the vcluster."
  type        = string
  default     = "minimal"
}

variable "blueprint_version" {
  description = "The Blueprint version"
  type        = string
  default     = "latest"
}

