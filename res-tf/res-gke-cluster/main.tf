terraform {
  required_providers {
    
    google = {
      version = "6.12.0"
      source = "registry.opentofu.org/hashicorp/google"
    }
     google-beta = {
      version = "6.12.0"
      source = "registry.opentofu.org/hashicorp/google-beta"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.16.1"
    }
    
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
provider "google-beta" {
  project = var.project_id
  region  = var.region
}

locals {
  // ID of the cluster
  cluster_id = google_container_cluster.primary.id

  // location
  location = var.regional ? var.region : var.zone
  // For zonal cluster zone is always set.
  zone             = length(var.zone) > 0 ? var.zone : "us-central1-a"
  region           = var.regional ? var.region : join("-", slice(split("-", local.zone), 0, 2))
  cluster_type     = var.regional ? "regional" : "zonal"
  cluster_location = google_container_cluster.primary.location

  // networking
  network_project_id = var.network_project_id != "" ? var.network_project_id : var.project_id
  cluster_network_policy = var.network_policy ? [{
    enabled  = true
    provider = var.network_policy_provider
    }] : [{
    enabled  = false
    provider = null
  }]

  private_network_config = var.enable_private_cluster ? [{
    enable_private_nodes        = true
    enable_private_endpoint     = var.access_control_plane_external_ip ? false : true
    master_ipv4_cidr_block      = var.control_plane_ipv4_cidr_block
    enable_master_global_access = var.access_control_plane_global
    private_endpoint_subnetwork = var.private_endpoint_subnetwork
  }] : []

  // security
  workload_identity_enabled = !(var.identity_namespace == null || var.identity_namespace == "null")
  cluster_workload_identity_config = !local.workload_identity_enabled ? [] : var.identity_namespace == "enabled" ? [{
    workload_pool = "${var.project_id}.svc.id.goog" }] : [{ workload_pool = var.identity_namespace
  }]

  cluster_authenticator_security_group = var.authenticator_security_group == null ? [] : [{
    security_group = var.authenticator_security_group
  }]

  // Feature
  cluster_gce_pd_csi_config = var.gce_pd_csi_driver ? [{ enabled = true }] : [{ enabled = false }]
  gke_backup_agent_config   = var.gke_backup_agent_config ? [{ enabled = true }] : [{ enabled = false }]

  // automation
  cluster_maintenance_window_is_recurring = var.maintenance_recurrence != "" && var.maintenance_end_time != "" ? [1] : []
  cluster_maintenance_window_is_daily     = length(local.cluster_maintenance_window_is_recurring) > 0 ? [] : [1]

  gateway_api_config = var.gateway_api_channel != null ? [{ channel : var.gateway_api_channel }] : []

  ray_operator_config = length(var.ray_operator_config) > 0 && lookup(var.ray_operator_config, "enabled", false) ? [var.ray_operator_config] : []

  // node pools
  // Build a map of maps of node pools from a list of objects
  node_pool_names = [for np in toset(var.node_pools) : np.name]
  node_pools      = zipmap(local.node_pool_names, tolist(toset(var.node_pools)))


  cluster_endpoint = google_container_cluster.primary.endpoint

  cluster_min_master_version = google_container_cluster.primary.min_master_version
  cluster_master_version     = google_container_cluster.primary.master_version

  cluster_ca_certificate = concat(google_container_cluster.primary[*].master_auth, [])[0][0]["cluster_ca_certificate"]
}
