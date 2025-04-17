output "kubeflow_url" {
  value = var.ingress_domain_type == "Rafay" ? "https://${local.ingress_full_url}" : "https://${local.kubeflow_host_name}"
}

output "istio_ingressgateway_loadbalancer_ip" {
  value = var.istio_svc_type == "LoadBalancer" ? data.kubernetes_service.istio_ingressgateway.status[0].load_balancer[0].ingress[0].ip : "Not LoadBalancer Svc or LoadBalancer IP not available"
}

output "sub_domain" {
  value = "${local.ingress_sub_domain}"
}