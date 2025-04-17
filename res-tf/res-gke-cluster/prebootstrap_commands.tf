/***********************************************
  Fetch Google Client config for authenticatin
 ***********************************************/
data "google_client_config" "default" {}

/***************************
  Get GKE cluster details
 ***************************/
data "google_container_cluster" "primary" {
  depends_on = [google_container_cluster.primary]
  name       = var.cluster_name
  project    = var.project_id

  location = local.cluster_location
}

provider "helm" {
  kubernetes {
    # uncomment to deploy resources to local/testing cluster
    # config_path = "~/.kube/config"

    host                   = "https://${data.google_container_cluster.primary.endpoint}"
    cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.default.access_token
  }
}

/******************************************
  Prebootstrap Commands on GKE cluster
 *****************************************/
resource "helm_release" "prebootstrap" {
  depends_on = [google_container_cluster.primary]
  count      = length(var.prebootstrap_commands) > 0 ? 1 : 0

  name       = "preboot"
  namespace  = "kube-system"
  repository = "charts/"
  chart      = "prebootstrap"
  values = [
    yamlencode({
      commands = var.prebootstrap_commands
    })
  ]
  version = "0.1.0"
}
