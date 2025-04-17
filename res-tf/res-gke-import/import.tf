terraform {
  required_providers {
    rafay = {
      version = "= 1.1.38"
      source  = "RafaySystems/rafay"
    }
    google = {
      version = "6.12.0"
      source = "registry.opentofu.org/hashicorp/google"
    }
     
    helm = {
      source = "hashicorp/helm"
      version = "2.16.1"
    }
    null = {
      source = "registry.opentofu.org/hashicorp/null"
      version = "3.2.3"
    }
  }
}

provider "google" {
  project = var.project_id
}


# provider "rafay" {
#   provider_config_file = var.provider_config_file
# }

/***************************
  Create Rafay Cluster
 ***************************/
resource "rafay_import_cluster" "imported" {
  clustername       = var.cluster_name
  projectname       = var.rafay_project_name
  blueprint         = var.rafay_blueprint_name
  blueprint_version = var.rafay_blueprint_version

  provision_environment = "CLOUD"
  kubernetes_provider   = "GKE"

  values_path = "values.yaml"

  lifecycle {
    ignore_changes = [
      bootstrap_path,
    ]
  }
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

/*****************************
  Bootstrap new imported cluster
 *****************************/
resource "helm_release" "v2-infra" {
  depends_on = [rafay_import_cluster.imported]

  name             = "v2-infra"
  namespace        = "rafay-system"
  create_namespace = true
  repository       = "https://rafaysystems.github.io/rafay-helm-charts/"
  chart            = "v2-infra"
  values           = [rafay_import_cluster.imported.values_data]
  version          = "1.1.2"

  lifecycle {
    ignore_changes = [
      # to avoid reapplying helm release
      values,
      # fix: version is getting changed
      version
    ]
  }
}

/***************************************
  Delete rafay drift webhook on destroy
 ***************************************/
resource "null_resource" "delete-webhook" {
  triggers = {
    cluster_name = var.cluster_name
    project_name = var.rafay_project_name
  }
  provisioner "local-exec" {
    when    = destroy
    command = "./delete-webhook.sh"
    environment = {
      CLUSTER_NAME = "${self.triggers.cluster_name}"
      PROJECT      = "${self.triggers.project_name}"
    }
  }
  depends_on = [helm_release.v2-infra]
}
