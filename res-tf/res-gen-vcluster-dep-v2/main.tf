resource "kubernetes_namespace" "namespace" {

  metadata {
    name = var.namespace
    labels = merge(
      {
        "k8smgmt.io/project" = var.host_project
      },
      try(var.namespace_labels, {}),
      var.enable_kata_runtime ? { "runtimeClassName" = "kata" } : {}
    )
    annotations = try(var.namespace_annotations, null)
  }
}

resource "kubernetes_resource_quota" "resource_quota" {
  depends_on = [kubernetes_namespace.namespace]

  metadata {
    name      = "${var.namespace}-resource-quota"
    namespace = kubernetes_namespace.namespace.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = var.namespace_quotas[var.namespace_quota_size].cpu_requests
      "limits.cpu"      = var.namespace_quotas[var.namespace_quota_size].cpu_limits
      "requests.memory" = var.namespace_quotas[var.namespace_quota_size].memory_requests
      "limits.memory"   = var.namespace_quotas[var.namespace_quota_size].memory_limits
      
      "requests.${var.gpu_type}.com/gpu" = var.namespace_quotas[var.namespace_quota_size].gpu_requests
      "limits.${var.gpu_type}.com/gpu"   = var.namespace_quotas[var.namespace_quota_size].gpu_limits
    }
  }
}

resource "kubernetes_limit_range" "limit_range" {
  depends_on = [kubernetes_namespace.namespace]

  metadata {
    name      = "${var.namespace}-limit-range"
    namespace = kubernetes_namespace.namespace.metadata[0].name
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = var.namespace_container_limits.cpu_limits
        memory = var.namespace_container_limits.memory_limits
      }
      default_request = {
        cpu    = var.namespace_container_limits.cpu_requests
        memory = var.namespace_container_limits.memory_requests
      }
    }
  }
}

resource "local_file" "config" {
  depends_on = [rafay_import_cluster.import_vcluster,kubernetes_namespace.namespace]
  content = templatefile("${path.module}/templates/config.tftpl", {
    tocidr_ips  =   jsonencode(var.tocidr_ips)
    fromcidr_ips = jsonencode(var.fromcidr_ips)
    ns_name = var.namespace
    from_ns = jsonencode(var.frm_ns)
    to_ns = jsonencode(var.to_ns)
  })
  filename = "generated_config.yaml"
}
# # main.tf
resource "local_file" "config1" {
  depends_on = [rafay_import_cluster.import_vcluster,kubernetes_namespace.namespace]
  content = templatefile("${path.module}/templates/sub.tftpl", {
    cidr =   var.cidrblock
    ns_name = var.namespace
  })
  filename = "subnet.yaml"
}
resource "kubernetes_manifest" "generated_configmap" {
  manifest = yamldecode(local_file.config.content)
}
resource "kubernetes_manifest" "generated_configmap1" {
  manifest = yamldecode(local_file.config1.content)
}

resource "helm_release" "vcluster" {
  name       = var.vcluster_name
  # repository = "https://charts.loft.sh"
  chart      = "${path.module}/chart/vcluster-0.25.0.tgz"
  version    = var.vcluster_version
  namespace  = resource.kubernetes_namespace.namespace.metadata[0].name

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
      values      = indent(12, var.importcluster)
      device_details = var.device_details
    }),
    templatefile("${path.module}/templates/plugin.yaml.tftpl", {
      plugin_image = var.plugin_image
    })
  ]
}

# # Combine all namespaces
# locals {
#   all_namespaces = concat(var.default_namespaces, var.user_defined_namespaces, [var.namespace])
# }

# resource "kubernetes_network_policy" "cross_namespace_policy" {
#   count = var.network_policy ? 1 : 0
#   depends_on = [kubernetes_namespace.namespace]
#   metadata {
#     name      = "allow-to-vcluster"
#     namespace = var.namespace
#   }
#   spec {
#     pod_selector {}
#     policy_types = ["Ingress"]
#     ingress {
#       from {
#         namespace_selector {
#           match_expressions {
#             key      = "kubernetes.io/metadata.name"
#             operator = "In"
#             values   = local.all_namespaces
#           }
#         }
#       }
#     }
#   }
# }
