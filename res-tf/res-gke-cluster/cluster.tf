/******************************************
  Create GKE Cluster
 *****************************************/
resource "google_container_cluster" "primary" {
  provider = google-beta

  name        = var.cluster_name
  description = var.description
  project     = var.project_id

  location       = local.location
  node_locations = var.default_node_locations
  network        = "projects/${local.network_project_id}/global/networks/${var.network}"
  subnetwork     = "projects/${local.network_project_id}/regions/${local.region}/subnetworks/${var.subnetwork}"

  min_master_version = var.kubernetes_version

  cluster_ipv4_cidr = var.cluster_ipv4_cidr
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.pods_cidr_block
    services_ipv4_cidr_block = var.services_cidr_block

    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  default_max_pods_per_node = var.default_max_pods_per_node
  vertical_pod_autoscaling {
    enabled = var.enable_vertical_pod_autoscaling
  }

  dynamic "network_policy" {
    for_each = local.cluster_network_policy

    content {
      enabled  = network_policy.value.enabled
      provider = network_policy.value.provider
    }
  }

  datapath_provider = var.datapath_provider

  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [true] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = lookup(cidr_blocks.value, "cidr_block", "")
          display_name = lookup(cidr_blocks.value, "display_name", "")
        }
      }
    }
  }

  dynamic "private_cluster_config" {
    for_each = local.private_network_config
    content {
      enable_private_nodes    = private_cluster_config.value.enable_private_nodes
      enable_private_endpoint = private_cluster_config.value.enable_private_endpoint
      master_ipv4_cidr_block  = private_cluster_config.value.master_ipv4_cidr_block
      private_endpoint_subnetwork = private_cluster_config.value.private_endpoint_subnetwork
      master_global_access_config {
        enabled = private_cluster_config.value.enable_master_global_access
      }
    }

  }

  default_snat_status {
    disabled = var.disable_default_snat
  }


  // Security features
  dynamic "workload_identity_config" {
    for_each = local.cluster_workload_identity_config

    content {
      workload_pool = workload_identity_config.value.workload_pool
    }
  }

  dynamic "authenticator_groups_config" {
    for_each = local.cluster_authenticator_security_group
    content {
      security_group = authenticator_groups_config.value.security_group
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = var.issue_client_certificate
    }
  }

  enable_legacy_abac = var.enable_legacy_abac

  // Features
  logging_config {
    enable_components = var.logging_enabled_components
  }

  monitoring_config {
    enable_components = var.monitoring_enabled_components
    managed_prometheus {
      enabled = var.monitoring_enable_managed_prometheus
    }
    advanced_datapath_observability_config {
      enable_metrics = var.monitoring_enable_observability_metrics
      enable_relay   = var.monitoring_enable_observability_relay
    }
  }

  addons_config {
    gcp_filestore_csi_driver_config {
      enabled = var.filestore_csi_driver
    }

    kalm_config {
      enabled = var.kalm_config
    }

    dynamic "gce_persistent_disk_csi_driver_config" {
      for_each = local.cluster_gce_pd_csi_config

      content {
        enabled = gce_persistent_disk_csi_driver_config.value.enabled
      }
    }

    dynamic "gke_backup_agent_config" {
      for_each = local.gke_backup_agent_config

      content {
        enabled = gke_backup_agent_config.value.enabled
      }
    }

    dns_cache_config {
      enabled = var.dns_cache
    }

    dynamic "ray_operator_config" {
      for_each = local.ray_operator_config

      content {

        enabled = ray_operator_config.value.enabled

        ray_cluster_logging_config {
          enabled = ray_operator_config.value.logging_enabled
        }
        ray_cluster_monitoring_config {
          enabled = ray_operator_config.value.monitoring_enabled
        }
      }
    }
  }

  node_pool_defaults {
    node_config_defaults {
      gcfs_config {
        enabled = var.enable_image_streaming
      }
    }
  }

  dynamic "maintenance_policy" {
    for_each = var.enable_maintenance_window ? [1] : []
    content {
      dynamic "recurring_window" {
        for_each = local.cluster_maintenance_window_is_recurring
        content {
          start_time = var.maintenance_start_time
          end_time   = var.maintenance_end_time
          recurrence = var.maintenance_recurrence
        }
      }

      dynamic "daily_maintenance_window" {
        for_each = local.cluster_maintenance_window_is_daily
        content {
          start_time = var.maintenance_start_time
        }
      }

      dynamic "maintenance_exclusion" {
        for_each = var.maintenance_exclusions
        content {
          exclusion_name = maintenance_exclusion.value.name
          start_time     = maintenance_exclusion.value.start_time
          end_time       = maintenance_exclusion.value.end_time

          dynamic "exclusion_options" {
            for_each = maintenance_exclusion.value.exclusion_scope == null ? [] : [maintenance_exclusion.value.exclusion_scope]
            content {
              scope = exclusion_options.value
            }
          }
        }
      }
    }
  }

  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [var.enable_binary_authorization] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }

  dynamic "secret_manager_config" {
    for_each = var.enable_secret_manager_addon ? [var.enable_secret_manager_addon] : []
    content {
      enabled = secret_manager_config.value
    }
  }

  dynamic "confidential_nodes" {
    for_each = var.enable_confidential_nodes ? [var.enable_confidential_nodes] : []
    content {
      enabled = confidential_nodes.value
    }
  }

  enable_cilium_clusterwide_network_policy = var.enable_cilium_clusterwide_network_policy

  enable_multi_networking = var.enable_multi_networking

  enable_fqdn_network_policy = var.enable_fqdn_network_policy

  enable_tpu                  = var.enable_tpu
  enable_intranode_visibility = var.enable_intranode_visibility

  enable_l4_ilb_subsetting = var.enable_l4_ilb_subsetting

  dynamic "gateway_api_config" {
    for_each = local.gateway_api_config

    content {
      channel = gateway_api_config.value.channel
    }
  }

  dynamic "cost_management_config" {
    for_each = var.enable_cost_allocation ? [1] : []
    content {
      enabled = var.enable_cost_allocation
    }
  }


  /// metadata mandatory for terraform

  # We can't create a cluster with no node pool defined, but we want
  # to only use separately managed node pools. So we create the
  # smallest possible default node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Release channel is not supported in Rafay yet. Defaulted to
  # no-channel.
  release_channel {
    channel = "UNSPECIFIED"
  }

  # Allow terraform to destroy cluster
  deletion_protection = false
}
