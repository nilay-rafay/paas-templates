output "gke_cluster_name" {
  value = var.gke_cluster_name
}

output "mlops_sql_instance_name" {
  value = google_sql_database_instance.mlops_instance.name
}

output "mlops_sql_instance_root_password" {
  value     = google_sql_database_instance.mlops_instance.root_password
  sensitive = true
}

output "mlops_sql_instance_user_name" {
  value = google_sql_user.mlops_user.name
}

output "mlops_sql_instance_user_password" {
  value     = google_sql_user.mlops_user.password
  sensitive = true
}

output "kubeflow_bucket" {
  value = google_storage_bucket.kubeflow_bucket.name
}

output "mlflow_bucket" {
  value = google_storage_bucket.mlflow_bucket.name
}

output "kubeflow_bucket_hmac_key_id" {
  value = google_storage_hmac_key.kubeflow_bucket_hmac_key.id
}

output "kubeflow_bucket_hmac_key_secret" {
  value     = google_storage_hmac_key.kubeflow_bucket_hmac_key.secret
  sensitive = true
}

output "kubeflow_bucket_hmac_key_access_id" {
  value = google_storage_hmac_key.kubeflow_bucket_hmac_key.access_id
}

output "feast_redis_instance_name" {
  value = var.feast_redis_instance_name
}

# output "feast_redis_host" {
#   value = var.feast_redis_is_external ? google_redis_instance.feast_redis_instance[0].host : helm_release.redis_instance[0].status.host
# }

# output "feast_redis_port" {
#   value = 3679
# }

output "google_redis_host_output" {
  value = var.feast_redis_is_external ? google_redis_instance.feast_redis_instance[0].host : null
}
