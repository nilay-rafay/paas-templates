locals {
  conv_values_to_yaml = yamlencode(jsondecode(var.values_json))
}

data "rafay_download_kubeconfig" "kubeconfig_cluster" {
  cluster = var.cluster_name
}

resource "local_file" "kubeconfig" {
  lifecycle {
    ignore_changes = all
  }
  depends_on = [data.rafay_download_kubeconfig.kubeconfig_cluster]
  content    = data.rafay_download_kubeconfig.kubeconfig_cluster.kubeconfig
  filename   = "/tmp/test/kubeconfig.yaml"
}

resource "null_resource" "kubeconfig_ready" {
  depends_on = [local_file.kubeconfig]
  provisioner "local-exec" {
    command = "while [ ! -f /tmp/test/kubeconfig.yaml ]; do sleep 1; done"
  }
}

resource "kubernetes_namespace" "gpu_operator_resources" {
  depends_on = [local_file.kubeconfig, null_resource.kubeconfig_ready]
  metadata {
    name = "gpu-operator-resources"
  }
}


resource "kubernetes_resource_quota" "gpu_operator_quota" {
  depends_on = [kubernetes_namespace.gpu_operator_resources]
  metadata {
    name      = "gpu-operator-quota"
    namespace = kubernetes_namespace.gpu_operator_resources.metadata[0].name
  }
  spec {
    hard = {
      pods = 100
    }
    scope_selector {
      match_expression {
        operator   = "In"
        scope_name = "PriorityClass"
        values     = ["system-node-critical", "system-cluster-critical"]
      }
    }
  }
}


resource "helm_release" "nvidia_gpu_operator" {
  depends_on = [kubernetes_resource_quota.gpu_operator_quota]
  repository = var.gpu_chart_repository
  chart      = var.gpu_chart
  name       = var.gpu_chart_name
  namespace  = kubernetes_namespace.gpu_operator_resources.metadata[0].name
  values     = [local.conv_values_to_yaml]
}

resource "null_resource" "wait_for_gpu_operator_pods" {
  depends_on = [helm_release.nvidia_gpu_operator]
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
    chmod +x validation.sh && ./validation.sh
    EOT
  }
}


resource "kubernetes_daemonset" "nvidia_numa_node_reset" {
  depends_on = [null_resource.wait_for_gpu_operator_pods]
  metadata {
    name      = "nvidia-numa-node-reset"
    namespace = kubernetes_namespace.gpu_operator_resources.metadata.0.name
  }
  spec {
    selector {
      match_labels = {
        app = "nvidia-numa-node-reset"
      }
    }
    template {
      metadata {
        labels = {
          app = "nvidia-numa-node-reset"
        }
      }
      spec {
        node_selector = {
          "feature.node.kubernetes.io/pci-10de.present" = "true"
        }
        toleration {
          operator = "Exists"
        }

        restart_policy = "Always"
        container {
          name  = "nvidia-numa-node-reset"
          image = "ubuntu:latest"
          security_context {
            privileged = true
          }
          command = ["/bin/bash", "-c"]
          args = [
            <<-EOT
            for dir in /sys/bus/pci/devices/*; do
              if [ -f "$dir/vendor" ] && grep -q "0x10de" "$dir/vendor"; then
                if [ -f "$dir/numa_node" ]; then
                  echo "Resetting NUMA node for device $(basename $dir)"
                  echo 0 > "$dir/numa_node"
                fi
              fi
            done
            echo "Script completed, sleeping indefinitely."
            sleep infinity
            EOT
          ]
          resources {
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
          }
          volume_mount {
            name       = "sys"
            mount_path = "/sys"
            read_only  = false
          }
        }
        volume {
          name = "sys"
          host_path {
            path = "/sys"
            type = "Directory"
          }
        }
      }
    }
  }
}