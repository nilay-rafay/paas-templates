output "url" {
  value = var.ingress_domain_type == "Rafay" ? "https://${local.ingress_domain_name}" : "https://${var.ingress_custom_domain}"
}

output "sub_domain" {
  value = local.ingress_sub_domain
}


output "api_key" {
  value     = random_uuid.test.result
  sensitive = true
}
