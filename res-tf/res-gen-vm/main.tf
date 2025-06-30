variable "input1" {
  description = "First input"
  type        = string
}

variable "vm_name" {
  description = "vm name"
  type        = string
}

output "vcluster_kubeconfig_url" {
  value = var.input1
}

resource "null_resource" "vcluster_kubeconfig" {
  provisioner "local-exec" {
    command = <<EOT
      curl -sSL -o /tmp/test/${var.vm_name}-kubeconfig.yaml ${var.vcluster_kubeconfig_url}
    EOT
  }

  triggers = {
    url = var.vcluster_kubeconfig_url
  }
}

resource "null_resource" "vcluster_kubeconfig_ready" {
  depends_on = [null_resource.vcluster_kubeconfig]
  provisioner "local-exec" {
    command = "while [ ! -f /tmp/test/${var.vm_name}-kubeconfig.yaml ]; do sleep 1; done"
  }
}

resource "kubernetes_manifest" "kubevirt_vm" {
  provider = kubernetes.vcluster
  depends_on = [null_resource.vcluster_kubeconfig_ready]
  manifest = {
    apiVersion = "kubevirt.io/v1"
    kind       = "VirtualMachine"
    metadata = {
      name      = var.vm_name
      namespace = "default"
    }
    spec = {
      running = true
      template = {
        metadata = {
          labels = {
            "kubevirt.io/domain" = var.vm_name
          }
        }
        spec = {
          domain = {
            devices = {
              disks = [
                {
                  disk = {
                    bus = "virtio"
                  }
                  name = "containerdisk"
                },
                {
                  disk = {
                    bus = "virtio"
                  }
                  name = "cloudinitdisk"
                }
              ]
            }
            resources = {
              requests = {
                memory = "512Mi"
              }
            }
          }
          volumes = [
            {
              name = "containerdisk"
              containerDisk = {
                image = "quay.io/containerdisks/fedora:37"
              }
            },
            {
              name = "cloudinitdisk"
              cloudInitNoCloud = {
                userData = <<-EOF
                  #cloud-config
                  password: fedora
                  chpasswd: { expire: False }
                  ssh_pwauth: True
                EOF
              }
            }
          ]
        }
      }
    }
  }
}
