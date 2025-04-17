resource "azurerm_kubernetes_cluster" "aks" {
  name                      = var.cluster_name
  location                  = var.location
  resource_group_name       = var.resource_group
  dns_prefix                = local.dns_prefix
  kubernetes_version        = var.kubernetes_version
  automatic_upgrade_channel = var.automatic_upgrade_channel != "none" ? var.automatic_upgrade_channel : null

  default_node_pool {
    name                   = var.default_node_pool.name
    node_count             = var.default_node_pool.node_count
    vm_size                = var.default_node_pool.vm_size
    zones                  = var.default_node_pool.availability_zones
    max_pods               = var.default_node_pool.max_pods
    node_public_ip_enabled = var.default_node_pool.node_public_ip_enabled
    vnet_subnet_id         = var.default_node_pool.vnet_subnet_id != "" ? var.default_node_pool.vnet_subnet_id : null
    pod_subnet_id          = var.default_node_pool.pod_subnet_id != "" ? var.default_node_pool.pod_subnet_id : null
    os_sku                 = var.default_node_pool.os_sku
    snapshot_id            = var.default_node_pool.snapshot_id != "" ? var.default_node_pool.snapshot_id : null

    upgrade_settings {
      drain_timeout_in_minutes      = var.default_node_pool.upgrade_settings.drain_timeout_in_minutes
      max_surge                     = var.default_node_pool.upgrade_settings.max_surge
      node_soak_duration_in_minutes = var.default_node_pool.upgrade_settings.node_soak_duration_in_minutes
    }

    dynamic "kubelet_config" {
      for_each = var.default_node_pool_kubelet_config_enabled ? [1] : []
      content {
        cpu_manager_policy        = var.default_node_pool_kubelet_config.cpu_manager_policy
        cpu_cfs_quota_enabled     = var.default_node_pool_kubelet_config.cpu_cfs_quota_enabled
        cpu_cfs_quota_period      = var.default_node_pool_kubelet_config.cpu_cfs_quota_period
        image_gc_high_threshold   = var.default_node_pool_kubelet_config.image_gc_high_threshold
        image_gc_low_threshold    = var.default_node_pool_kubelet_config.image_gc_low_threshold
        topology_manager_policy   = var.default_node_pool_kubelet_config.topology_manager_policy
        allowed_unsafe_sysctls    = var.default_node_pool_kubelet_config.allowed_unsafe_sysctls
        container_log_max_line    = var.default_node_pool_kubelet_config.container_log_max_line
        container_log_max_size_mb = var.default_node_pool_kubelet_config.container_log_max_size_mb
        pod_max_pid               = var.default_node_pool_kubelet_config.pod_max_pid
      }
    }
  }

  identity {
    type         = var.identity_type
    identity_ids = var.identity_type == "UserAssigned" ? var.user_managed_identities : null
  }

  tags = var.cluster_tags

  network_profile {
    network_plugin      = var.network_plugin
    network_policy      = var.network_policy
    network_plugin_mode = var.network_plugin_mode
  }

  private_dns_zone_id = var.private_dns_zone_id != "" ? var.private_dns_zone_id : null

  dynamic "service_mesh_profile" {
    for_each = var.service_mesh_profile_enabled ? [1] : []
    content {
      mode                             = var.service_mesh_profile_mode
      revisions                        = var.service_mesh_profile_revisions
      internal_ingress_gateway_enabled = var.internal_ingress_gateway_enabled
      external_ingress_gateway_enabled = var.external_ingress_gateway_enabled

      dynamic "certificate_authority" {
        for_each = var.certificate_authority.key_vault_id != "" ? [1] : []
        content {
          key_vault_id           = var.certificate_authority.key_vault_id
          root_cert_object_name  = var.certificate_authority.root_cert_object_name
          cert_chain_object_name = var.certificate_authority.cert_chain_object_name
          cert_object_name       = var.certificate_authority.cert_object_name
          key_object_name        = var.certificate_authority.key_object_name
        }
      }
    }
  }

  dynamic "maintenance_window_auto_upgrade" {
    for_each = var.maintenance_window_auto_upgrade_enabled ? [1] : []
    content {
      frequency    = var.maintenance_window_auto_upgrade.frequency
      interval     = var.maintenance_window_auto_upgrade.interval
      duration     = var.maintenance_window_auto_upgrade.duration
      day_of_week  = var.maintenance_window_auto_upgrade.day_of_week
      day_of_month = var.maintenance_window_auto_upgrade.day_of_month
      week_index   = var.maintenance_window_auto_upgrade.week_index
      start_time   = var.maintenance_window_auto_upgrade.start_time
      utc_offset   = var.maintenance_window_auto_upgrade.utc_offset
      start_date   = var.maintenance_window_auto_upgrade.start_date
    }
  }

  dynamic "maintenance_window_node_os" {
    for_each = var.maintenance_window_node_os_enabled ? [1] : []
    content {
      frequency    = var.maintenance_window_node_os.frequency
      interval     = var.maintenance_window_node_os.interval
      duration     = var.maintenance_window_node_os.duration
      day_of_week  = var.maintenance_window_node_os.day_of_week
      day_of_month = var.maintenance_window_node_os.day_of_month
      week_index   = var.maintenance_window_node_os.week_index
      start_time   = var.maintenance_window_node_os.start_time
      utc_offset   = var.maintenance_window_node_os.utc_offset
      start_date   = var.maintenance_window_node_os.start_date
    }
  }

  dynamic "api_server_access_profile" {
    for_each = var.authorized_ip_ranges_enabled ? [1] : []
    content {
      authorized_ip_ranges = var.authorized_ip_ranges
    }
  }

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.azure_active_directory_enabled ? [1] : []
    content {
      tenant_id              = var.aad_tenant_id != "" ? var.aad_tenant_id : null
      admin_group_object_ids = var.aad_admin_group_object_ids
      azure_rbac_enabled     = var.aad_azure_rbac_enabled
    }
  }

  dynamic "http_proxy_config" {
    for_each = var.http_proxy_config_enabled ? [1] : []
    content {
      http_proxy  = var.http_proxy_config.http_proxy
      https_proxy = var.http_proxy_config.https_proxy
      no_proxy    = var.http_proxy_config.no_proxy
    }
  }

  workload_identity_enabled = var.workload_identity_enabled

  http_application_routing_enabled = var.http_application_routing_enabled

  azure_policy_enabled = var.azure_policy_enabled

  oidc_issuer_enabled = var.oidc_issuer_enabled

  dynamic "web_app_routing" {
    for_each = var.web_app_routing_enabled ? [1] : []
    content {
      dns_zone_ids = var.web_app_routing_dns_zone_ids
    }
  }

  dynamic "key_management_service" {
    for_each = var.key_vault_key_id != "" ? [1] : []
    content {
      key_vault_key_id         = var.key_vault_key_id
      key_vault_network_access = var.key_vault_network_access
    }
  }

  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider_enabled ? [1] : []
    content {
      secret_rotation_enabled  = var.secret_rotation_enabled
      secret_rotation_interval = var.secret_rotation_interval
    }
  }

  dynamic "oms_agent" {
    for_each = var.oms_agent.log_analytics_workspace_id != "" ? [1] : []
    content {
      log_analytics_workspace_id      = var.oms_agent.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = var.oms_agent.msi_auth_for_monitoring_enabled
    }
  }

  lifecycle {
    ignore_changes = [
      # Remove redundant attributes
    ]
  }
}
