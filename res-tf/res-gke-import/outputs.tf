# output "bootstrap_data" {
#   description = "Cluster's bootstrapping config in yaml"
#   value       = rafay_import_cluster.imported.bootstrap_data
#   sensitive   = true
# }

# output "values_data" {
#   description = "v2-infra helm chart values override context in yaml"
#   value       = rafay_import_cluster.imported.values_data
#   sensitive   = true
# }

output "rafay_project_name" {
  description = "Rafay project name the cluster is created in"
  value       = var.rafay_project_name
}

output "rafay_blueprint_name" {
  description = "Rafay blueprint name"
  value       = var.rafay_blueprint_name
}

output "rafay_blueprint_version" {
  description = "Rafay blueprint version"
  value       = var.rafay_blueprint_version
}
