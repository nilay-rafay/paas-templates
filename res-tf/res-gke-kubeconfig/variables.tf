variable "cluster_name" {
  type        = string
  description = "The name of the cluster (required)"
}

variable "rctl_config_path" {
  description = "Path to the Rafay config file"
  type        = string
  default     = "opt/rafay"
}
