variable "controlplane_vm_count" {
  description = "Number of controlplane VMs to create"
  type        = number
  default     = 3
  validation {
    condition     = var.controlplane_vm_count >= 1
    error_message = "Must be 1 or more."
  }
}

variable "worker_vm_count" {
  description = "Number of worker VMs to create"
  type        = number
  default     = 3
  validation {
    condition     = var.worker_vm_count >= 1
    error_message = "Must be 1 or more."
  }
}

variable "controlplane_vm_cpu" {
  description = "Number of CPUs per controlplane VM"
  type        = number
  default     = 4
}

variable "controlplane_vm_memory" {
  description = "Amount of memory [GiB] per controlplane VM"
  type        = number
  default     = 16
}

variable "worker_vm_cpu" {
  description = "Number of CPUs per worker VM"
  type        = number
  default     = 8
}

variable "worker_vm_memory" {
  description = "Amount of memory [GiB] per worker VM"
  type        = number
  default     = 64
}

variable "vm_disk_os_size_controlplane" {
  description = "Minimum size of  controlplane OS disk [GiB]"
  type        = number
  default     = 50
}

variable "vm_disk_os_size_worker" {
  description = "Minimum size of the worker OS disk [GiB]"
  type        = number
  default     = 50
}

variable "vm_disk_data_size_controlplane" {
  description = "Size of the controlplane DATA disk [GiB]"
  type        = number
  default     = 30
}

variable "vm_disk_data_size_worker" {
  description = "Size of the worker DATA disk [GiB]"
  type        = number
  default     = 30
}

variable "vsphere_user" {
  description = "vSphere username for authentication"
  default = "rafay"
}

variable "vsphere_password" {
  description = "vSphere password for authentication"
  default   = "password"
  sensitive = true
}

variable "vm_username" {
  description = "VM username for authentication"
  default = "ubuntu"
}

variable "vsphere_server" {
  description = "The vCenter server IP or FQDN"
  default = "pcc-14-15-3-5.ovh.us"
}

variable "vsphere_datacenter" {
  description = "vSphere datacenter to deploy virtual machines"
  default = "pcc-14-15-3-5_datacenter1145"
}

variable "vsphere_compute_cluster" {
  description = "vSphere compute cluster where virtual machines will be created"
  default = "Cluster1"
}

variable "vsphere_network_controlplane" {
  description = "Network to connect the controlplane virtual machines within vSphere"
  default = "controlplane-network"
}

variable "vsphere_network_worker" {
  description = "Network to connect the worker virtual machines within vSphere"
  default = "worker-network"
}

variable "vsphere_datastore" {
  description = "Datastore where virtual machines will reside"
  default = "ssd-001"
}

variable "vsphere_folder_controlplane" {
  description = "vSphere folder where the controlplane virtual machines will be organized"
  default = "controlplane-folder"
}

variable "vsphere_folder_worker" {
  description = "vSphere folder where worker virtual machines will be organized"
  default = "worker-folder"
}

variable "vsphere_vm_template" {
  description = "Template name for creating virtual machines"
  default = "vm-agent-template"
}

variable "controlplane_vm_prefix" {
  description = "Prefix for control plane virtual machine names"
  default = "controlplane_vm"
}

variable "worker_vm_prefix" {
  description = "Prefix for worker virtual machine names"
  default = "worker_vm"
}

variable "vm_os" {
  description = "Operating system of VM for output"
  default = "Ubuntu-22.04"
}

variable "vsphere_storage_policy" {
  description = "The vSphere storage policy. Set to empty string if not using a storage policy."
  type        = string
}

variable "vsphere_resource_pool" {
  description = "The vSphere resource pool to use for VM deployment. Set to an empty string to use the default cluster resource pool."
  type        = string
  default = "ovhServers"
}
