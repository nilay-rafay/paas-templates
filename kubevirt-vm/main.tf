resource "macaddress" "vm_mac" {
  prefix = [82, 84, 0]
}

resource "kubectl_manifest" "vm" {
  depends_on = [macaddress.vm_mac]
  yaml_body = templatefile("${path.module}/templates/vm.tftpl", {
    vm_name              = var.vm_name
    namespace            = var.namespace
    run_strategy         = var.run_strategy
    vm_cpu               = var.cpu_count_vm
    vm_memory            = var.memory_size_vm
    vm_mac_address       = macaddress.vm_mac.address
    gpu_resource_name    = var.gpu_resource_name
    gpu_quotas           = var.gpu_quotas_vm
    storage_size         = var.storage_size
    additional_storage   = var.additional_storage
    ssh_key              = var.ssh_public_key
    vm_image             = [for v in var.operating_system_profile: v.image if v.name == var.operating_system][0]
    password             = [for v in var.operating_system_profile: v.password if v.name == var.operating_system][0]
  })
}

resource "kubernetes_service" "service" {
  depends_on = [kubectl_manifest.vm]
  metadata {
    name      = "${var.vm_name}-ssh-svc"
    namespace = var.namespace
  }
  spec {
    selector = {
      "kubevirt.io/vm" = var.vm_name
    }
    type = "NodePort"
    port {
      name        = "ssh"
      port        = 22
      target_port = 22
      protocol    = "TCP"
    }
  }
}

resource "terraform_data" "ssh_info" {
  triggers_replace = [
    timestamp()
  ]
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "chmod +x ./get_ssh_info.sh; ./get_ssh_info.sh"
    environment = {
      NAMESPACE = "${var.namespace}"
      VM_NAME = "${var.vm_name}"
      SERVICE_NAME = kubernetes_service.service.metadata[0].name
      USERNAME = [for v in var.operating_system_profile: v.username if v.name == var.operating_system][0]
    }
  }
  depends_on = [kubernetes_service.service]
}

data "local_file" "ssh_login_info" {
  depends_on = [terraform_data.ssh_info]
  filename   = "ssh_login_info"
}
