data "rafay_download_kubeconfig" "kubeconfig_cluster" {
  cluster = var.host_cluster_name
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

# First definition (no plugin)
resource "helm_release" "vcluster_no_plugin" {
  count      = var.use_plugin ? 0 : 1
  depends_on = [rafay_import_cluster.import_vcluster, rafay_namespace.namespace]

  name       = var.vcluster_name
  repository = "https://charts.loft.sh"
  chart      = "vcluster"
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
    })
  ]
}

# Second definition (with plugin)
resource "helm_release" "vcluster_with_plugin" {
  count      = var.use_plugin ? 1 : 0
  depends_on = [rafay_import_cluster.import_vcluster, rafay_namespace.namespace]

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
    }),
    templatefile("${path.module}/templates/plugin.yaml.tftpl", {
      plugin_image = var.plugin_image
    })
  ]
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
