
output "ray_cluster_url" {
  value = "https://${local.ingress_full_domain}"
}

output "user" {
  value = var.ingress_user
}

output "password" {
  value = nonsensitive(random_password.password.result)
}

output "sub_domain" {
  value = local.ingress_sub_domain
}