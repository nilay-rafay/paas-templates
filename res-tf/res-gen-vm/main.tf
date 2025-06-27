output "vcluster_kubeconfig_url" {
  value = $(resource.res-gen-kubeconfig.output.cluster_kubeconfig.value)$
}
