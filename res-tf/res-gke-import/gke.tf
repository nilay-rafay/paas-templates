/***********************************************
  Fetch Google Client config for authenticatin
 ***********************************************/
data "google_client_config" "default" {}

/***************************
  Get GKE cluster details
 ***************************/
data "google_container_cluster" "primary" {
  name    = var.cluster_name
  project = var.project_id

  location = var.cluster_location
}
