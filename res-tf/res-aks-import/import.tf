terraform {
  required_providers {
    rafay = {
      version = "= 1.1.41"
      source  = "RafaySystems/rafay"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
}

provider "azurerm" {
  features {}
}


# provider "rafay" {
#   provider_config_file = var.provider_config_file
# }

/***************************
  Create Rafay Cluster
 ***************************/
resource "rafay_import_cluster" "imported" {
  clustername       = var.rafay_cluster_name
  projectname       = var.rafay_project_name
  blueprint         = var.rafay_blueprint_name
  blueprint_version = var.rafay_blueprint_version

  provision_environment = "CLOUD"
  kubernetes_provider   = "AKS"

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

    host                   = data.azurerm_kubernetes_cluster.cluster.kube_config[0].host
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate)
    token                  = data.azurerm_kubernetes_cluster.cluster.kube_config[0].password
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
  version          = "1.1.3"

  lifecycle {
    ignore_changes = [
      # to avoid reapplying helm release
      values,
      # fix: version is getting changed
      version
    ]
  }
}

resource "null_resource" "delete-webhook" {
  triggers = {
    cluster_name = var.rafay_cluster_name
    project_name = var.rafay_project_name
    tmp_dir      = "/tmp/rctl_tmp_dir"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "chmod +x delete-webhook.sh && ./delete-webhook.sh ${self.triggers.tmp_dir}"
    environment = {
      CLUSTER_NAME = "${self.triggers.cluster_name}"
      PROJECT      = "${self.triggers.project_name}"
    }
  }
  depends_on = [helm_release.v2-infra]
}

resource "null_resource" "delete_rafay_cluster" {
  triggers = {
    rafay_cluster_name = var.rafay_cluster_name
    rafay_project_name = var.rafay_project_name
    # tmp_dir            = "/tmp/rctl_tmp_dir_path"
  }

  provisioner "local-exec" {
    when = destroy
    # command = <<EOT
    #   TMP_DIR=$(cat ${self.triggers.tmp_dir})
    #   $TMP_DIR/rctl delete cluster --name ${self.triggers.rafay_cluster_name} --project ${self.triggers.rafay_project_name}
    #   rm -rf $TMP_DIR
    # EOT
    command = "rctl delete cluster --name ${self.triggers.rafay_cluster_name} --project ${self.triggers.rafay_project_name}"
  }
  depends_on = [null_resource.delete-webhook]
}
