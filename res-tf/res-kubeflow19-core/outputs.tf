output "kubeflow_url" {
  value = var.ingress_domain_type == "Rafay" ? "https://${local.ingress_full_url}" : "https://${local.kubeflow_host_name}"
}

output "sub_domain" {
  value = local.ingress_sub_domain
}
