variable "input1" {
  description = "First input"
  type        = string
}

output "vcluster_kubeconfig_url" {
  value = var.input1
}
