data "rafay_download_kubeconfig" "kubeconfig_cluster" {
  cluster = var.host_cluster_name
}

data "rafay_download_kubeconfig" "vcluster_kubeconfig_cluster" {
  cluster = var.vcluster_name
}

resource "local_file" "vcluster_kubeconfig" {
  lifecycle {
    ignore_changes = all
  }
  depends_on = [
    data.rafay_download_kubeconfig.kubeconfig_cluster,
    data.rafay_download_kubeconfig.vcluster_kubeconfig_cluster,
  ]
  content    = data.rafay_download_kubeconfig.vcluster_kubeconfig_cluster.kubeconfig
  filename   = "/tmp/test/${var.vcluster_name}-kubeconfig.yaml"
}

resource "null_resource" "vcluster_kubeconfig_ready" {
  depends_on = [
    local_file.kubeconfig,
    local_file.vcluster_kubeconfig,
  ]
  provisioner "local-exec" {
    command = "while [ ! -f /tmp/test/${var.vcluster_name}-kubeconfig.yaml ]; do sleep 1; done"
  }
}

resource "local_file" "kubeconfig" {
  lifecycle {
    ignore_changes = all
  }
  depends_on = [data.rafay_download_kubeconfig.kubeconfig_cluster]
  content    = data.rafay_download_kubeconfig.kubeconfig_cluster.kubeconfig
  filename   = "/tmp/test/host-kubeconfig.yaml"
}

resource "null_resource" "host_kubeconfig_ready" {
  depends_on = [local_file.kubeconfig]
  provisioner "local-exec" {
    command = "while [ ! -f /tmp/test/host-kubeconfig.yaml ]; do sleep 1; done"
  }
}

resource "rafay_import_cluster" "import_vcluster" {
  depends_on = [ null_resource.host_kubeconfig_ready ]
  clustername           = var.vcluster_name
  projectname           = var.project
  blueprint             = var.blueprint
  blueprint_version     = var.blueprint_version
  values_path           = "${path.module}/values.yaml"
  kubernetes_provider   = "OTHER"
  provision_environment = "CLOUD"
}

resource "rafay_namespace" "namespace" {
  depends_on = [rafay_import_cluster.import_vcluster]
  metadata {
    name        = var.namespace
    project     = var.host_project
    labels      = merge(try(var.namespace_labels, {}), var.enable_kata_runtime ? {"runtimeClassName" = "kata"} : {})
    annotations = try(var.namespace_annotations, null)
    description = "Namespace for ${var.vcluster_name} vCluster"
  }
  spec {
    drift {
      enabled = false
    }
    placement {
      labels {
        key   = "rafay.dev/clusterName"
        value = var.host_cluster_name
      }
    }
    resource_quotas {
      cpu_requests    = var.namespace_quotas[var.namespace_quota_size]["cpu_requests"]
      memory_requests = var.namespace_quotas[var.namespace_quota_size]["memory_requests"]
      cpu_limits      = var.namespace_quotas[var.namespace_quota_size]["cpu_limits"]
      memory_limits   = var.namespace_quotas[var.namespace_quota_size]["memory_limits"]
      gpu_requests    = var.namespace_quotas[var.namespace_quota_size]["gpu_requests"]
      gpu_limits      = var.namespace_quotas[var.namespace_quota_size]["gpu_limits"]
    }
    limit_range {
      container {
        default {
          cpu    = var.namespace_container_limits.cpu_limits
          memory = var.namespace_container_limits.memory_limits
        }
        default_request {
          cpu    = var.namespace_container_limits.cpu_requests
          memory = var.namespace_container_limits.memory_requests
        }
      }
    }
  }
}
resource "helm_release" "vcluster" {
  name       = var.vcluster_name
  chart      = "${path.module}/chart/vcluster-0.25.0.tgz"
  version    = var.vcluster_version
  namespace  = resource.rafay_namespace.namespace.metadata[0].name

  create_namespace = true

  set {
    name  = "controlPlane.distro.${var.distro}.enabled"
    value = "true"
  }

  set {
    name  = "controlPlane.statefulSet.scheduling.podManagementPolicy"
    value = "OrderedReady"
  }

  set {
    name  = "controlPlane.statefulSet.persistence.volumeClaim.size"
    value = var.vcluster_store_size
  }

  values = [
    templatefile("${path.module}/templates/vcluster-values.yaml.tftpl", {
      tolerations = length(var.tolerations) > 0 ? jsonencode(var.tolerations) : null
      values      = indent(12, rafay_import_cluster.import_vcluster.values_data)
      device_details = var.device_details
    }),
    templatefile("${path.module}/templates/plugin.yaml.tftpl", {
      plugin_image = var.plugin_image
    })
  ]
}

resource "kubernetes_manifest" "kubevirt_vm" {
  provider   = kubernetes.vcluster
  depends_on = [
    local_file.kubeconfig,
    local_file.vcluster_kubeconfig,
    rafay_import_cluster.import_vcluster,
  ]
  manifest = {
    apiVersion = "kubevirt.io/v1"
    kind       = "VirtualMachine"
    metadata = {
      name      = "test-vm"
      namespace = "default"
    }
    spec = {
      running = true
      template = {
        metadata = {
          labels = {
            "kubevirt.io/domain" = "test-vm"
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

# Combine all namespaces
locals {
  all_namespaces = concat(var.default_namespaces, var.user_defined_namespaces, [var.namespace])
}

resource "kubernetes_network_policy" "cross_namespace_policy" {
  count = var.network_policy ? 1 : 0
  depends_on = [rafay_namespace.namespace]
  metadata {
    name      = "allow-to-vcluster"
    namespace = var.namespace
  }
  spec {
    pod_selector {}
    policy_types = ["Ingress"]
    ingress {
      from {
        namespace_selector {
          match_expressions {
            key      = "kubernetes.io/metadata.name"
            operator = "In"
            values   = local.all_namespaces
          }
        }
      }
    }
  }
}
