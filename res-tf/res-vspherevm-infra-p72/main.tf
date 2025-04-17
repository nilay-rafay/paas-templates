data "vsphere_datacenter" "datacenter" {
  name = var.vsphere_datacenter
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vsphere_compute_cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network_controlplane" {
  name          = var.vsphere_network_controlplane
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network_worker" {
  name          = var.vsphere_network_worker
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "vm_template" {
  name          = var.vsphere_vm_template
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "pool" {
  name  = var.vsphere_resource_pool
  datacenter_id = data.vsphere_datacenter.datacenter.id
}


# Declare the storage policy only if it is not an empty string
locals {
  storage_policy_enabled = var.vsphere_storage_policy != ""
}

# Conditionally create the storage policy data block
data "vsphere_storage_policy" "policy" {
  count = local.storage_policy_enabled ? 1 : 0
  name  = var.vsphere_storage_policy
}

locals {
  # For SSH configuration in outputs
  ssh_key_config = {
    private_key_path = try(
      coalesce(
        var.private_key_path,
        fileexists("private-key") ? "${path.module}/private-key" : null
      ),
      null
    )
  }
}

locals {
  ssh_public_key = try(
    var.authorized_key_path != null && var.authorized_key_path != "" ? file(var.authorized_key_path) :
    fileexists("authorized-key") ? file("authorized-key") :
    "",
    ""
  )
}

data "cloudinit_config" "controlplane" {
  count         = var.controlplane_vm_count
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = <<-EOF
      #cloud-config
      hostname: ${var.controlplane_vm_prefix}-controlplane-${count.index}
      users:
        - name: ${var.vm_username}
          passwd: '$6$rounds=4096$23GLKxe5CyPc1$fL5FgZCbCgw30ZHwqDt8hoO07m6isstJlxUIwvHBcSLVGzjdiR1Z1zA2yKGtR6EIv5LHflJuedbaiLUqU5Wfj0'
          sudo: ALL=(ALL) NOPASSWD:ALL
          lock_passwd: false
          shell: /bin/bash
          ssh-authorized-keys:
            - ${local.ssh_public_key}
    EOF
  }
}

data "cloudinit_config" "worker" {
  count         = var.worker_vm_count
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content      = <<-EOF
      #cloud-config
      hostname: ${var.worker_vm_prefix}-worker-${count.index}
      users:
        - name: ${var.vm_username}
          passwd: '$6$rounds=4096$23GLKxe5CyPc1$fL5FgZCbCgw30ZHwqDt8hoO07m6isstJlxUIwvHBcSLVGzjdiR1Z1zA2yKGtR6EIv5LHflJuedbaiLUqU5Wfj0'
          sudo: ALL=(ALL) NOPASSWD:ALL
          lock_passwd: false
          shell: /bin/bash
          ssh-authorized-keys:
            - ${local.ssh_public_key}
      EOF
  }
}

resource "vsphere_folder" "folder_controlplane" {
  path          = var.vsphere_folder_controlplane
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_virtual_machine" "controlplane" {
  # https://github.com/hashicorp/terraform-provider-vsphere/issues/1902
  # ignoring these fields due to the above issue and its causing the vm to restart
  lifecycle {
    ignore_changes = [
      ept_rvi_mode,
      hv_mode
    ]
  }
  count                = var.controlplane_vm_count
  folder               = vsphere_folder.folder_controlplane.path
  name                 = "${var.controlplane_vm_prefix}-controlplane-${count.index}"
  guest_id             = data.vsphere_virtual_machine.vm_template.guest_id
  firmware             = data.vsphere_virtual_machine.vm_template.firmware
  num_cpus             = var.controlplane_vm_cpu
  num_cores_per_socket = var.controlplane_vm_cpu
  memory               = var.controlplane_vm_memory * 1024
  nested_hv_enabled    = true
  vvtd_enabled         = true
  enable_disk_uuid     = true
  #Using compute_cluster resource pool in the absence of permission.
  resource_pool_id     = data.vsphere_compute_cluster.compute_cluster.resource_pool_id
  #Use data.vsphere_resource_pool.pool.id for resource_pool_id (example below line) line instead above line in case you have resource pool and permission configured else you will get Error: error cloning virtual machine: ServerFaultCode: Permission to perform this operation was denied. Error
  #resource_pool_id    = data.vsphere_resource_pool.pool.id 
  datastore_id         = data.vsphere_datastore.datastore.id
  scsi_type            = data.vsphere_virtual_machine.vm_template.scsi_type
  storage_policy_id = local.storage_policy_enabled && length(data.vsphere_storage_policy.policy) > 0 ? data.vsphere_storage_policy.policy[0].id : null
  disk {
    unit_number      = 0
    label            = "os"
    size             = max(data.vsphere_virtual_machine.vm_template.disks.0.size, var.vm_disk_os_size_controlplane)
    eagerly_scrub    = data.vsphere_virtual_machine.vm_template.disks.0.eagerly_scrub
    thin_provisioned = true
  }
  disk {
    unit_number      = 1
    label            = "data"
    size             = var.vm_disk_data_size_controlplane
    eagerly_scrub    = data.vsphere_virtual_machine.vm_template.disks.0.eagerly_scrub
    thin_provisioned = true
  }
  network_interface {
    network_id  = data.vsphere_network.network_controlplane.id
    adapter_type = data.vsphere_virtual_machine.vm_template.network_interface_types.0
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.vm_template.id
  }
  extra_config = {
    "guestinfo.userdata"           = data.cloudinit_config.controlplane[count.index].rendered
    "guestinfo.userdata.encoding"  = "gzip+base64"
  }
}

resource "vsphere_folder" "folder_worker" {
  path          = var.vsphere_folder_worker
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_virtual_machine" "worker" {
  # https://github.com/hashicorp/terraform-provider-vsphere/issues/1902
  # ignoring these fields due to the above issue and its causing the vm to restart
  lifecycle {
    ignore_changes = [
      ept_rvi_mode,
      hv_mode
    ]
  }
  count                = var.worker_vm_count
  folder               = vsphere_folder.folder_worker.path
  name                 = "${var.worker_vm_prefix}-worker-${count.index}"
  guest_id             = data.vsphere_virtual_machine.vm_template.guest_id
  firmware             = data.vsphere_virtual_machine.vm_template.firmware
  num_cpus             = var.worker_vm_cpu
  num_cores_per_socket = var.worker_vm_cpu
  memory               = var.worker_vm_memory * 1024
  nested_hv_enabled    = true
  vvtd_enabled         = true
  enable_disk_uuid     = true
  #Using compute_cluster resource pool in the absence of permission.
  resource_pool_id     = data.vsphere_compute_cluster.compute_cluster.resource_pool_id
  #Use data.vsphere_resource_pool.pool.id for resource_pool_id (example below line) line instead above line in case you have resource pool and permission configured else you will get Error: error cloning virtual machine: ServerFaultCode: Permission to perform this operation was denied. Error
  #resource_pool_id    = data.vsphere_resource_pool.pool.id 
  datastore_id         = data.vsphere_datastore.datastore.id
  scsi_type            = data.vsphere_virtual_machine.vm_template.scsi_type
  storage_policy_id = local.storage_policy_enabled && length(data.vsphere_storage_policy.policy) > 0 ? data.vsphere_storage_policy.policy[0].id : null
  disk {
    unit_number      = 0
    label            = "os"
    size             = max(data.vsphere_virtual_machine.vm_template.disks.0.size, var.vm_disk_os_size_worker)
    eagerly_scrub    = data.vsphere_virtual_machine.vm_template.disks.0.eagerly_scrub
    thin_provisioned = true
  }
  disk {
    unit_number      = 1
    label            = "data"
    size             = var.vm_disk_data_size_worker
    eagerly_scrub    = data.vsphere_virtual_machine.vm_template.disks.0.eagerly_scrub
    thin_provisioned = true
  }
  network_interface {
    network_id  = data.vsphere_network.network_worker.id
    adapter_type = data.vsphere_virtual_machine.vm_template.network_interface_types.0
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.vm_template.id
  }
  extra_config = {
    "guestinfo.userdata"           = data.cloudinit_config.worker[count.index].rendered
    "guestinfo.userdata.encoding"  = "gzip+base64"
  }
}
