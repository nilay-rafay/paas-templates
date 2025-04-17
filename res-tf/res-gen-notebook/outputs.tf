output "notebook_url" {
  value = "https://${local.ingress_domain_name}"
}

output "sub_domain" {
  value = "${local.ingress_sub_domain}"
}

output "token" {
  value = local.token
}

