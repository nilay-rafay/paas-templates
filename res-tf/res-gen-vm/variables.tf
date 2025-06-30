variable "input1" {
  description = "First input"
  type        = string
}

variable "rctl_config_path" {
  description = "The path to the Rafay CLI config file"
  type        = string
  default     = "opt/rafay"
}

variable "vcluster_name" {
  description = "vcluster name"
  type        = string
}

variable "vm_name" {
  description = "vm name"
  type        = string
}

variable "namespace" {
  description = "vm namespace"
  type        = string
  default     = "default"
}

variable "memory" {
  description = "vm memory"
  type        = string
  default     = "512Mi"
}

variable "image" {
  description = "vm image"
  type        = string
  default     = "quay.io/containerdisks/fedora:latest"
}

variable "user" {
  description = "user name"
  type        = string
  default     = "fedora"
}


variable "password" {
  description = "paasword name"
  type        = string
  default     = "fedora"
}


variable "ssh_key" {
  description = "public ssh key""
  type        = string
  default     = "abcd"
}




