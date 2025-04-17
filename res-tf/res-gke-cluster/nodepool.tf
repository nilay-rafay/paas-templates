/******************************************
  Create Container Cluster node pools
 *****************************************/
resource "google_container_node_pool" "pools" {
  provider = google
  for_each = local.node_pools
  name     = each.key
  project  = var.project_id
  location = local.location

  // use node_locations if provided, defaults to cluster level node_locations if not specified
  node_locations = lookup(each.value, "node_locations", "") != "" ? split(",", each.value["node_locations"]) : null

  cluster = google_container_cluster.primary.name

  version            = lookup(each.value, "version", null)
  initial_node_count = lookup(each.value, "initial_node_count", 3)
  max_pods_per_node  = lookup(each.value, "max_pods_per_node", null)

  dynamic "autoscaling" {
    for_each = lookup(each.value, "autoscaling", true) ? [each.value] : []
    content {
      min_node_count = lookup(autoscaling.value, "min_count", 1)
      max_node_count = lookup(autoscaling.value, "max_count", 100)
    }
  }

  management {
    auto_upgrade = lookup(each.value, "auto_upgrade", false)
  }

  upgrade_settings {
    strategy        = lookup(each.value, "strategy", "SURGE")
    max_surge       = lookup(each.value, "strategy", "SURGE") == "SURGE" ? lookup(each.value, "max_surge", 1) : null
    max_unavailable = lookup(each.value, "strategy", "SURGE") == "SURGE" ? lookup(each.value, "max_unavailable", 0) : null

    dynamic "blue_green_settings" {
      for_each = lookup(each.value, "strategy", "SURGE") == "BLUE_GREEN" ? [1] : []
      content {
        node_pool_soak_duration = lookup(each.value, "node_pool_soak_duration", null)

        standard_rollout_policy {
          batch_soak_duration = lookup(each.value, "batch_soak_duration", null)
          batch_node_count    = lookup(each.value, "batch_node_count", null)
        }
      }
    }
  }

  placement_policy {
    type = lookup(each.value, "placement_policy_type", "")
    tpu_topology = lookup(each.value, "tpu_topology", null)
  }

  node_config {
    image_type   = lookup(each.value, "image_type", "COS_CONTAINERD")
    machine_type = lookup(each.value, "machine_type", "e2-medium")
    // TODO(Akshay): Check gvnic == integriry monitoring??

    dynamic "reservation_affinity" {
      for_each = lookup(each.value, "consume_reservation_type", "") != "" ? [each.value] : []
      content {
        consume_reservation_type = lookup(reservation_affinity.value, "consume_reservation_type", null)
        key                      = lookup(reservation_affinity.value, "reservation_affinity_key", null)
        values                   = lookup(reservation_affinity.value, "reservation_affinity_values", null) == null ? null : [for s in split(",", lookup(reservation_affinity.value, "reservation_affinity_values", null)) : trimspace(s)]
      }
    }

    dynamic "taint" {
      for_each = lookup(each.value, "taints", [])
      content {
        effect = taint.value.effect
        key    = taint.value.key
        value  = taint.value.value
      }
    }

    disk_size_gb = lookup(each.value, "disk_size_gb", 100)
    disk_type    = lookup(each.value, "disk_type", "pd-standard")

    spot = lookup(each.value, "spot", false)

    dynamic "guest_accelerator" {
      for_each = lookup(each.value, "accelerator_count", 0) > 0 ? [1] : []
      content {
        type               = lookup(each.value, "accelerator_type", "")
        count              = lookup(each.value, "accelerator_count", 0)
        gpu_partition_size = lookup(each.value, "gpu_partition_size", null)

        dynamic "gpu_driver_installation_config" {
          for_each = lookup(each.value, "gpu_driver_version", "") != "" ? [1] : []
          content {
            gpu_driver_version = lookup(each.value, "gpu_driver_version", "")
          }
        }

        dynamic "gpu_sharing_config" {
          for_each = lookup(each.value, "gpu_sharing_strategy", "") != "" ? [1] : []
          content {
            gpu_sharing_strategy       = lookup(each.value, "gpu_sharing_strategy", "")
            max_shared_clients_per_gpu = lookup(each.value, "max_shared_clients_per_gpu", 2)
          }
        }
      }
    }

    shielded_instance_config {
      enable_secure_boot          = lookup(each.value, "enable_secure_boot", false)
      enable_integrity_monitoring = lookup(each.value, "enable_integrity_monitoring", true)
    }

    tags = lookup(each.value, "tags", [])

    labels   = lookup(each.value, "k8s_labels", {})
    metadata = lookup(each.value, "instance_metadata", {})

    dynamic "kubelet_config" {
      for_each = length(setintersection(
        keys(each.value),
        ["cpu_manager_policy", "cpu_cfs_quota", "cpu_cfs_quota_period", "insecure_kubelet_readonly_port_enabled", "pod_pids_limit"]
      )) != 0 ? [1] : []

      content {
        cpu_manager_policy                     = lookup(each.value, "cpu_manager_policy", "static")
        cpu_cfs_quota                          = lookup(each.value, "cpu_cfs_quota", null)
        cpu_cfs_quota_period                   = lookup(each.value, "cpu_cfs_quota_period", null)
        insecure_kubelet_readonly_port_enabled = lookup(each.value, "insecure_kubelet_readonly_port_enabled", null) != null ? upper(tostring(each.value.insecure_kubelet_readonly_port_enabled)) : null
        pod_pids_limit                         = lookup(each.value, "pod_pids_limit", null)
      }
    }

    enable_confidential_storage = lookup(each.value, "enable_confidential_storage", false)

    dynamic "confidential_nodes" {
      for_each = lookup(each.value, "enable_confidential_nodes", null) != null ? [each.value.enable_confidential_nodes] : []
      content {
        enabled = confidential_nodes.value
      }
    }

    dynamic "linux_node_config" {
      for_each = length(setintersection(
        keys(each.value),
        ["sysctls_net_core_netdev_max_backlog", "sysctls_net.core.rmem_max", "cgroup_mode", "hugepages_config_hugepage_size_2m", "hugepages_config_hugepage_size_1g"]
      )) != 0 ? [1] : []

      content {
        sysctls = {
          "net.core.netdev_max_backlog" = lookup(each.value, "sysctls_net_core_netdev_max_backlog", "")
          "net.core.rmem_max" = lookup(each.value, "sysctls_net.core.rmem_max", "")
        }

        cgroup_mode = lookup(each.value, "cgroup_mode", "CGROUP_MODE_UNSPECIFIED")

        hugepages_config {
          hugepage_size_2m = lookup(each.value, "hugepages_config_hugepage_size_2m", "")
          hugepage_size_1g = lookup(each.value, "hugepages_config_hugepage_size_1g", "")
        }
      }
    }

  }

  lifecycle {
    ignore_changes = [initial_node_count]

    precondition {
      condition     = var.regional ? length(var.region) > 0 : length(var.zone) > 0
      error_message = "The region must be specified for regional cluster. If zonal then zone must be provided."
    }
  }

}
