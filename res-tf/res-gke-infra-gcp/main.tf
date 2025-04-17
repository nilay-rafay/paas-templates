provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

resource "google_sql_database_instance" "mlops_instance" {
  name             = var.gcp_sql_instance_name
  database_version = "MYSQL_8_0"
  deletion_protection = false
  settings {
    tier = var.gcp_sql_instance_tier
    ip_configuration {
      ipv4_enabled    = false
      private_network     = var.gke_network_name == "default" ? "projects/${var.gcp_project_id}/global/networks/default" : var.gke_network_name
    }
  }
  root_password = var.gcp_sql_root_password
}

resource "google_sql_user" "mlops_user" {
  host     = "%"
  name     = var.gcp_sql_user_name
  instance = google_sql_database_instance.mlops_instance.name
  password = var.gcp_sql_user_password
}

resource "google_sql_database" "mlflow_database" {
  name     = "mlflow"
  instance = google_sql_database_instance.mlops_instance.name
}

resource "google_sql_database" "katib_database" {
  name     = "katib"
  instance = google_sql_database_instance.mlops_instance.name
}

resource "google_sql_database" "feast_database" {
  name     = "feast"
  instance = google_sql_database_instance.mlops_instance.name
}

resource "google_storage_bucket" "kubeflow_bucket" {
  name                     = "${var.gcp_project_id}-${var.gcp_kubeflow_bucket_name}"
  location                 = var.gcp_region
  force_destroy            = true
  public_access_prevention = "enforced"
}

resource "google_storage_bucket" "mlflow_bucket" {
  name                     = "${var.gcp_project_id}-${var.gcp_mlflow_bucket_name}"
  location                 = var.gcp_region
  force_destroy            = true
  public_access_prevention = "enforced"
}

resource "google_service_account" "kubeflow_service_account" {
  account_id   = "${var.gke_cluster_name}-sa"
  display_name = "Service Account for Kubeflow bucket HMAC Access"
}

resource "google_project_iam_member" "kubeflow_bucket_access" {
  project = var.gcp_project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.kubeflow_service_account.email}"
}

resource "google_storage_hmac_key" "kubeflow_bucket_hmac_key" {
  service_account_email = google_service_account.kubeflow_service_account.email
  project               = var.gcp_project_id
}

resource "google_redis_instance" "feast_redis_instance" {
  count          = var.feast_redis_is_external ? 1 : 0
  name           = var.feast_redis_instance_name
  tier           = var.gcp_redis_instance_tier
  memory_size_gb = var.feast_redis_instance_memory_size_gb
  region         = var.gcp_region
  redis_version  = "REDIS_7_0"
  auth_enabled   = true
}
