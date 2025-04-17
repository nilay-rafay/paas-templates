resource "random_password" "mlflow_postgres_root_password" {
  count       = var.enable_mlflow ? 1 : 0
  length      = 12
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  # min_special = 1
  special = false
}

resource "random_password" "mlflow_minio_secret_key" {
  count       = var.enable_mlflow ? 1 : 0
  length      = 12
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  # min_special = 1
  special = false
}

locals {
  mlflow_service_endpoint       = "mlflow-tracking.${resource.kubernetes_namespace.mlflow_namespace[0].metadata[0].name}.svc.cluster.local"
  mlflow_postgres_root_password = var.enable_mlflow ? random_password.mlflow_postgres_root_password[0].result : ""
  mlflow_minio_secret_key       = var.enable_mlflow ? random_password.mlflow_minio_secret_key[0].result : ""
}

resource "kubernetes_namespace" "mlflow_namespace" {
  count = var.enable_mlflow ? 1 : 0
  metadata {
    name = "mlflow"
  }
}

resource "helm_release" "mlflow" {
  depends_on = [resource.kubernetes_namespace.mlflow_namespace, random_password.mlflow_minio_secret_key, random_password.mlflow_postgres_root_password]
  name       = "mlflow"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "mlflow"
  version    = "1.3.2"
  timeout    = var.helm_timeout
  namespace  = resource.kubernetes_namespace.mlflow_namespace[0].metadata[0].name
  values = [
    yamlencode({
      tracking = {
        auth = {
          enabled = false
        }
        extraArgs = [
          "--dev"
        ]
        service = {
          type = "ClusterIP"
        }
      }
      run = {
        enabled = false
      }
      persistence = {
        enabled = false
      }
      postgresql = {
        auth = {
          password = local.mlflow_postgres_root_password
        }
      }
      minio = {
        auth = {
          rootUser     = "minio"
          rootPassword = local.mlflow_minio_secret_key
        }
        persistence = {
          storageClass = var.mlflow_persistence_config.minio.storage_class_name
          size         = var.mlflow_persistence_config.minio.storage_size
          accessModes  = [var.mlflow_persistence_config.minio.access_mode]
        }
      }
      externalS3 = {
        protocol = "http"
      }
    })
  ]
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
