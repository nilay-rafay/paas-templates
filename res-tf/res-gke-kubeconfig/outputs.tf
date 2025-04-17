output "kubeconfig" {
  description = "Rafay ZTKA kubeconfig of the cluster"
  value       = data.rafay_download_kubeconfig.kubeconfig_cluster.kubeconfig
}
