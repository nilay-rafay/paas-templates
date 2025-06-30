#variable "input1" {
#  description = "First input"
#  type        = string
#}

variable "vm_name" {
  description = "vm name"
  type        = string
}

#output "vcluster_kubeconfig_url" {
#  value = var.input1
#}

#resource "null_resource" "vcluster_kubeconfig" {
#  provisioner "local-exec" {
#    command = <<EOT
#      curl -sSL -o /tmp/test/${var.vm_name}-kubeconfig.yaml ${var.input1}
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

data "rafay_download_kubeconfig" "kubeconfig_cluster" {
  cluster = var.vcluster_name
}

resource "local_file" "kubeconfig" {
  lifecycle {
    ignore_changes = all
  }
  depends_on = [data.rafay_download_kubeconfig.kubeconfig_cluster]
  content    = data.rafay_download_kubeconfig.kubeconfig_cluster.kubeconfig
  filename   = "/tmp/test/vcluster-kubeconfig.yaml"
}

resource "null_resource" "vluster_kubeconfig_ready" {
  depends_on = [local_file.kubeconfig]
  provisioner "local-exec" {
    command = "while [ ! -f /tmp/test/vcluster-kubeconfig.yaml ]; do sleep 1; done"
  }
}

resource "kubectl_manifest" "kubevirt_vm" {
  depends_on = [null_resource.vcluster_kubeconfig_ready]
  yaml_body = <<YAML
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
  YAML
}
