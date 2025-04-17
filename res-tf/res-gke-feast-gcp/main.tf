resource "google_project_service" "gcp_services" {
  disable_on_destroy = false
  for_each           = toset(var.gcp_service_list)
  project            = var.gcp_project_id
  service            = each.key
}

data "google_sql_database_instances" "all_instances" {
  depends_on = [google_project_service.gcp_services]
}

data "google_redis_instance" "feast_instance" {
  count      = var.feast_redis_is_external ? 1 : 0
  region     = var.gcp_region
  depends_on = [google_project_service.gcp_services]
  name       = var.feast_redis_instance_name
}

locals {
  feast_mysql_instance = [for i in data.google_sql_database_instances.all_instances.instances : i if i.name == var.feast_mysql_instance][0]
}

## Random password generation for feast redis instance
resource "random_password" "redis_auth_string" {
  length  = 16
  special = true
}

resource "helm_release" "redis_instance" {
  count = var.feast_redis_is_external ? 0 : 1
  name             = var.feast_redis_instance_name
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "redis"
  create_namespace = true
  namespace        = "feast"
  version          = "17.0.1"
  timeout          = 3000
  set {
    name  = "global.redis.password"
    value = random_password.redis_auth_string.result
  }

  set {
    name  = "usePassword"
    value = "true"
  }

  set {
    name  = "cluster.enabled"
    value = "false"
  }
}

locals {
  feast_store_values = {
    project  = "feast"
    provider = "local"
    registry = {
      registry_type = "sql"
      path          = "mysql+pymysql://${var.feast_mysql_user}:${urlencode(var.feast_mysql_password)}@${local.feast_mysql_instance.private_ip_address}:${var.feast_mysql_port}/feast"
    }
    offline_store = {
      type = "file"
    }
    online_store = {
      type              = "redis"
      # connection_string = var.feast_redis_is_external ? "${data.google_redis_instance.feast_instance[0].host}:${var.feast_redis_port},password=${data.google_redis_instance.feast_instance[0].auth_string}" : "${helm_release.redis_instance[0].status.host}:${var.feast_redis_port},password=${random_password.redis_auth_string.result}"
      connection_string = var.feast_redis_is_external ? "${data.google_redis_instance.feast_instance[0].host}:${var.feast_redis_port},password=${data.google_redis_instance.feast_instance[0].auth_string}" : "${helm_release.redis_instance[0].name}-master.redis.svc.cluster.local:${var.feast_redis_port},password=${random_password.redis_auth_string.result}"
    }
  }
}

resource "helm_release" "feast" {
  name             = "feast"
  repository       = "https://feast-helm-charts.storage.googleapis.com"
  chart            = "feast-feature-server"
  create_namespace = true
  namespace        = "feast"
  timeout          = 3000
  set {
    name  = "feature_store_yaml_base64"
    value = base64encode(yamlencode(local.feast_store_values))
  }

  set {
    name  = "image.tag"
    value = "latest"
  }
  verify = false

}
