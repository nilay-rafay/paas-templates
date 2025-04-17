output "gcp_project_id" {
  description = "GCP Project ID"
  value       = google_container_cluster.primary.project
}

output "cluster_name" {
  description = "Cluster name"
  value       = google_container_cluster.primary.name
}

output "cluster_type" {
  description = "Cluster type (regional / zonal)"
  value       = local.cluster_type
}

output "location" {
  description = "Cluster location (region if regional cluster, zone if zonal cluster)"
  value       = google_container_cluster.primary.location
}

output "endpoint" {
  # Should be sensitive but EM UI is not showing sensitive outputs
  # hence commented out.
  #
  # sensitive   = true
  description = "Cluster endpoint"
  value       = local.cluster_endpoint
  depends_on = [
    /* Nominally, the endpoint is populated as soon as it is known to Terraform.
    * However, the cluster may not be in a usable state yet.  Therefore any
    * resources dependent on the cluster being up will fail to deploy.  With
    * this explicit dependency, dependent resources can wait for the cluster
    * to be up.
    */
    google_container_cluster.primary,
    # google_container_node_pool.pools,
  ]
}

output "current_control_plane_version" {
  description = "Current control plane kubernetes version"
  value       = google_container_cluster.primary.master_version
}

# output "ca_certificate" {
#   sensitive   = true
#   description = "Cluster ca certificate (base64 encoded)"
#   value       = local.cluster_ca_certificate
# }

output "cluster_labels" {
  description = "Cluster labels"
  value       = google_container_cluster.primary.effective_labels
}
