locals {
  all_nodes = merge(var.controlplane_nodes, var.worker_nodes)
}
resource "rafay_mks_cluster" "upstream-sample-cluster" {
  api_version = "infra.k8smgmt.io/v3"
  kind        = "Cluster"
  metadata = {
    name    = var.cluster_name
    project = var.cluster_project
    labels  = var.cluster_labels
  }
  spec = {
    proxy = contains(keys(var.proxy_config), "default") ? var.proxy_config["default"] : null
    blueprint = {
      name    = var.cluster_blueprint
      version = var.cluster_blueprint_version
    }
    cloud_credentials = var.cloud_credentials
    config = {
      installer_ttl           = var.installer_ttl
      kubelet_extra_args      = var.kubelet_extra_args
      auto_approve_nodes      = var.auto_approve_nodes
      dedicated_control_plane = var.cluster_dedicated_controlplanes
      kubernetes_version      = var.cluster_kubernetes_version
      high_availability       = var.cluster_ha
      kubernetes_upgrade      = var.kubernetes_upgrade
      network                 = var.network
      nodes                   = local.all_nodes
    }
    system_components_placement = var.system_components_placement
  }
}



