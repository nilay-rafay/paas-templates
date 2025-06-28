
variable "input1" {
  description = "First input"
  type        = string
}

variable "vcluster_name" {
  description = "First input"
  type        = string
}

variable "rctl_config_path" {
  description = "The path to the Rafay CLI config file"
  type        = string
  default     = "opt/rafay"
}

output "vcluster_kubeconfig_url" {
    value = var.input1
}

variable "vm_name" {
  description = "vm name"
  type        = string
}

#output "vcluster_kubeconfig_url" {
#  value = var.input1
#}

#data "local_file" "downloaded_kubeconfig" {
#  filename = "/tmp/test/${var.vm_name}-kubeconfig.yaml"
#}

resource "local_file" "kubeconfig" {
  lifecycle {
    ignore_changes = all
  }
  provisioner "local-exec" {
    command = <<EOT
      echo "[INFO] Downloading kubeconfig from ${var.input1}"
      mkdir -p /tmp/test
      curl -sSL -o /tmp/test/${var.vm_name}-kubeconfig.yaml ${var.input1}
      echo "[INFO] File downloaded to /tmp/test/${var.vm_name}-kubeconfig.yaml"
      ls -l /tmp/test/${var.vm_name}-kubeconfig.yaml
      cat /tmp/test/${var.vm_name}-kubeconfig.yaml
    EOT
  }
  #depends_on = [null_resource.vcluster_kubeconfig]
  content    = ownloaded_kubeconfig.content
  filename   = "/tmp/test/${var.vm_name}-kubeconfig.yaml"
}

#resource "null_resource" "vcluster_kubeconfig_ready" {
#  depends_on = [local_file.kubeconfig]
#  provisioner "local-exec" {
#    command = "while [ ! -f /tmp/test/${var.vm_name}-kubeconfig.yaml ]; do sleep 1; done"
#  }
#}

#resource "null_resource" "vcluster_kubeconfig" {
#  provisioner "local-exec" {
#    command = <<EOT
#      echo "[INFO] Downloading kubeconfig from ${var.input1}"
#      mkdir -p /tmp/test
#      curl -sSL -o /tmp/test/${var.vm_name}-kubeconfig.yaml ${var.input1}
#      echo "[INFO] File downloaded to /tmp/test/${var.vm_name}-kubeconfig.yaml"
#      ls -l /tmp/test/${var.vm_name}-kubeconfig.yaml
#      cat /tmp/test/${var.vm_name}-kubeconfig.yaml
#    EOT
#  }
#
#  triggers = {
#    url = var.input1
#  }
#}

#resource "null_resource" "vcluster_kubeconfig_ready" {
#  depends_on = [null_resource.vcluster_kubeconfig]
#  provisioner "local-exec" {
#    command = "while [ ! -f /tmp/test/${var.vm_name}-kubeconfig.yaml ]; do sleep 1; done"
#  }
#}

resource "kubernetes_manifest" "kubevirt_vm" {
  provider = kubernetes.vcluster
  depends_on = [
    local_file.kubeconfig,
  ]
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
