resource "azurerm_kubernetes_cluster_node_pool" "nodepool_resource" {
  for_each               = var.node_pools
  name                   = each.key
  kubernetes_cluster_id  = azurerm_kubernetes_cluster.aks.id
  vm_size                = each.value.vm_size
  node_count             = each.value.node_count
  min_count              = each.value.min_count
  max_count              = each.value.max_count
  auto_scaling_enabled   = each.value.auto_scaling_enabled
  max_pods               = each.value.max_pods
  zones                  = each.value.availability_zones
  node_public_ip_enabled = each.value.node_public_ip_enabled
  vnet_subnet_id         = each.value.vnet_subnet_id != "" ? each.value.vnet_subnet_id : null
  pod_subnet_id          = each.value.pod_subnet_id != "" ? each.value.pod_subnet_id : null
  os_sku                 = each.value.os_sku
  snapshot_id            = each.value.snapshot_id != "" ? each.value.snapshot_id : null
  mode                   = each.value.mode

  dynamic "kubelet_config" {
    for_each = each.value.kubelet_config_enabled ? [1] : []
    content {
      cpu_manager_policy        = each.value.kubelet_config.cpu_manager_policy
      cpu_cfs_quota_enabled     = each.value.kubelet_config.cpu_cfs_quota_enabled
      cpu_cfs_quota_period      = each.value.kubelet_config.cpu_cfs_quota_period
      image_gc_high_threshold   = each.value.kubelet_config.image_gc_high_threshold
      image_gc_low_threshold    = each.value.kubelet_config.image_gc_low_threshold
      topology_manager_policy   = each.value.kubelet_config.topology_manager_policy
      allowed_unsafe_sysctls    = each.value.kubelet_config.allowed_unsafe_sysctls
      container_log_max_line    = each.value.kubelet_config.container_log_max_line
      container_log_max_size_mb = each.value.kubelet_config.container_log_max_size_mb
      pod_max_pid               = each.value.kubelet_config.pod_max_pid
    }
  }
}
