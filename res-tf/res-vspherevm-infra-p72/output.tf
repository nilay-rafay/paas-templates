output "controlplane_node_details" {
  value = {
    for i in vsphere_virtual_machine.controlplane : i.name => {
      arch             = "amd64"
      hostname         = i.name
      operating_system = var.vm_os
      private_ip       = i.default_ip_address
      kubelet_extra_args = {
        max-pods                     = "300"
        cpu-manager-reconcile-period = "30s"
      }
      roles            = ["ControlPlane", "Worker"]
      ssh = merge({
        ip_address = i.default_ip_address
        port       = "22"
        username   = var.vm_username
      }, 
      local.ssh_key_config.private_key_path != null ? {
        private_key_path = local.ssh_key_config.private_key_path
      } : {})
    }
  }
}

output "worker_node_details" {
  value = {
    for i in vsphere_virtual_machine.worker : i.name => {
      arch             = "amd64"
      hostname         = i.name
      operating_system = var.vm_os
      private_ip       = i.default_ip_address
      kubelet_extra_args = {
        max-pods                     = "400"
        cpu-manager-reconcile-period = "40s"
      }
      roles            = ["Worker"]
      ssh = merge({
        ip_address = i.default_ip_address
        port       = "22"
        username   = var.vm_username
      },
      local.ssh_key_config.private_key_path != null ? {
        private_key_path = local.ssh_key_config.private_key_path
      } : {})
    }
  }
}