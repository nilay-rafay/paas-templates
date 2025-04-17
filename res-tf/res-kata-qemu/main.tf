data "rafay_download_kubeconfig" "kubeconfig_cluster" {
  cluster = var.cluster_name
}

locals {
  kubeconfig_data = yamldecode(data.rafay_download_kubeconfig.kubeconfig_cluster.kubeconfig)

  k8s_host                   = local.kubeconfig_data.clusters[0].cluster.server
  k8s_client_certificate     = base64decode(local.kubeconfig_data.users[0].user.client-certificate-data)
  k8s_client_key             = base64decode(local.kubeconfig_data.users[0].user.client-key-data)
  k8s_cluster_ca_certificate = base64decode(local.kubeconfig_data.clusters[0].cluster.certificate-authority-data)
}

resource "helm_release" "kata_admission_controller" {
  depends_on = [local.kubeconfig_data]
  count = var.enable_kata ? 1 : 0
  name       = "kata-admission-controller"
  chart      = "charts/kata-admission"
  verify     = false
  namespace = "kube-system"
}
