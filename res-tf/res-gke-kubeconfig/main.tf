terraform {
  required_providers {
    rafay = {
      version = "= 1.1.38"
      source  = "RafaySystems/rafay"
    }
  }
}


/***************************************
  Get kubeconfig for cluster
 ***************************************/
data "rafay_download_kubeconfig" "kubeconfig_cluster" {
  cluster = var.cluster_name
}

provider "rafay" {
  provider_config_file = var.rctl_config_path
}
