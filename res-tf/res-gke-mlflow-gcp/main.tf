locals {
  gcp_mysql_port = 3306
}

resource "google_project_service" "gcp_services" {
  disable_on_destroy = false
  for_each           = toset(var.gcp_service_list)
  project            = var.gcp_project_id
  service            = each.key
}

data "google_sql_database_instances" "all_instances" {
  depends_on = [google_project_service.gcp_services]
}

locals {
  mlflow_mysql_instance = [for i in data.google_sql_database_instances.all_instances.instances : i if i.name == var.mlflow_mysql_instance][0]
}

data "google_storage_bucket" "gcs_bucket" {
  depends_on = [google_project_service.gcp_services]
  name       = "${var.gcp_project_id}-${var.gcp_mlflow_bucket}"
}

resource "google_service_account" "gcp_mlflow_sa" {
  account_id   = var.gcp_mlflow_sa
  display_name = "MLflow tracking service account"
}

resource "google_storage_bucket_iam_member" "gcs_bucket_iam" {
  bucket = "${var.gcp_project_id}-${var.gcp_mlflow_bucket}"
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.gcp_mlflow_sa.email}"
}
resource "google_service_account_iam_member" "gke_sa_binding" {
  service_account_id = google_service_account.gcp_mlflow_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[${var.k8s_mlflow_namespace}/${var.k8s_mlflow_sa}]"
}

resource "kubernetes_namespace" "mlflow_namespace" {
  metadata {
    name = var.k8s_mlflow_namespace
  }
}

resource "kubernetes_secret" "mlflow_mysql_secret" {

  depends_on = [kubernetes_namespace.mlflow_namespace]
  metadata {
    name      = "mlflow-mysql-secret"
    namespace = var.k8s_mlflow_namespace
  }
  data = {
    "MYSQL_USER"     = var.mlflow_mysql_user
    "MYSQL_PASSWORD" = var.mlflow_mysql_pass
  }
}

resource "helm_release" "mlflow" {
  depends_on = [
    local.mlflow_mysql_instance,
    data.google_storage_bucket.gcs_bucket,
    kubernetes_secret.mlflow_mysql_secret,
    google_storage_bucket_iam_member.gcs_bucket_iam,
    google_service_account_iam_member.gke_sa_binding
  ]
  name       = "mlflow"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mlflow"
  version    = "1.3.2"
  timeout    = 3000
  namespace  = var.k8s_mlflow_namespace
  values = [
    file("values.yaml"),
    yamlencode({
      tracking = {
        extraEnvVars = [
          {
            name  = "MYSQL_HOST"
            value = local.mlflow_mysql_instance.private_ip_address
          },
          {
            name  = "MYSQL_PORT"
            value = tostring(local.gcp_mysql_port)
          },
          {
            name  = "MYSQL_DATABASE"
            value = var.mlflow_mysql_db
          },
          {
            name  = "GOOGLE_CLOUD_PROJECT"
            value = var.gcp_project_id
          },
          {
            name  = "GCS_BUCKET"
            value = var.gcp_mlflow_bucket
          }
        ]
        extraEnvVarsSecret = kubernetes_secret.mlflow_mysql_secret.metadata[0].name
        serviceAccount = {
          name = var.k8s_mlflow_sa
          annotations = {
            "iam.gke.io/gcp-service-account" = google_service_account.gcp_mlflow_sa.email
          }
        }
      }
    }),
  ]
}

locals {
  mlflow_service_endpoint = "mlflow-tracking.${var.k8s_mlflow_namespace}.svc.cluster.local"
}

resource "kubernetes_manifest" "create_mlflow_vs" {
  depends_on = [helm_release.mlflow]
  manifest = yamldecode(templatefile("mlflow.virtualservice.yaml.tftpl", {
    mlflow_service_endpoint = local.mlflow_service_endpoint
  }))
}

resource "kubernetes_manifest" "kserve_cluster_storage_container" {
  depends_on = [helm_release.mlflow]
  manifest = yamldecode(templatefile("mlflow.clusterstoragecontainer.yaml.tftpl", {
    mlflow_tracking_uri = "http://${local.mlflow_service_endpoint}/"
  }))
}
