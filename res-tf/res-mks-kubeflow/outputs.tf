output "kubeflow_url" {
  value = "https://${var.kubeflow_host_name}"
}

output "katib_mysql_root_password" {
  description = "MySQL root password for Katib"
  value       = nonsensitive(random_password.katib_mysql_root_password.result)
}

output "kfp_mysql_root_password" {
  description = "MySQL root password for Kubeflow Pipelines"
  value       = nonsensitive(random_password.kfp_mysql_root_password.result)
}

output "kfp_minio_secret_key" {
  description = "Minio secret key for Kubeflow Pipelines"
  value       = nonsensitive(random_password.kfp_minio_secret_key.result)
}
