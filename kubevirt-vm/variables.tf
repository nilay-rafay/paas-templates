variable "vm_name" {
  type = string
}

variable "namespace" {
  type = string
  default = "default"
}

variable "run_strategy" {
  type = string
  default = "Always"
}

variable "cpu_count_vm" {
  type    = number
  default = 1
}

variable "memory_size_vm" {
  type    = number
  default = 1
}

variable "gpu_resource_name" {
  type    = string
  default = "nvidia.com/gpu"
}

variable "gpu_quotas_vm" {
  type    = number
  default = 0
}

variable "storage_size" {
  type = number
  default = 10
}

variable "additional_storage" {
  type = number
  default = 0
}

variable "ssh_public_key" {
  default = ""
  validation {
    condition     = length(regexall("\n", var.ssh_public_key)) == 0
    error_message = "OpenSSH public keys cannot multiple lines."
  }
}

variable "operating_system_profile" {
    description = "(Optional) Operating System"
    type = list(any)
    default = [
        {
            "name": "Ubuntu 22.04",
            "image": "https://cloud-images.ubuntu.com/releases/22.04/release-20250128/ubuntu-22.04-server-cloudimg-amd64-disk-kvm.img",
            "username": "ubuntu",
            "password": "ubuntu"
        },
        {
            "name" : "Fedora 41",
            "image": "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2",
            "username": "fedora",
            "password": "fedora"
        }
    ]
}

variable "operating_system" {
  default = "Ubuntu 22.04"
}
