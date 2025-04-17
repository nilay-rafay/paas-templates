locals {
  feast_mysql_port          = 3306
  feast_redis_port          = 6379
  feast_namespace           = "feast"
  feast_mysql_root_password = var.enable_feast ? random_password.feast_mysql_root_password[0].result : ""
  feast_redis_password      = var.enable_feast ? random_password.feast_redis_password[0].result : ""
}

resource "random_password" "feast_mysql_root_password" {
  count       = var.enable_feast ? 1 : 0
  length      = 12
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  # min_special = 1
  special = false
}

resource "kubernetes_namespace" "feast" {
  depends_on = [random_password.feast_mysql_root_password]
  count      = var.enable_feast ? 1 : 0
  metadata {
    name = local.feast_namespace
  }
}

resource "helm_release" "mysql" {
  depends_on = [kubernetes_namespace.feast]
  count      = var.enable_feast ? 1 : 0
  name       = var.mysql_feast_helm_release_name
  repository = var.mysql_feast_helm_repository
  chart      = var.mysql_feast_helm_chart
  namespace  = kubernetes_namespace.feast.0.metadata[0].name
  timeout    = var.helm_timeout
  set {
    name  = "auth.rootPassword"
    value = local.feast_mysql_root_password
  }

  set {
    name  = "primary.service.port"
    value = local.feast_mysql_port
  }

  set {
    name  = "primary.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "primary.image.tag"
    value = "latest"
  }

  set {
    name  = "primary.persistence.storageClass"
    value = var.feast_persistence_config.mysql.storage_class_name
  }

  set_list {
    name  = "primary.persistence.accessModes"
    value = [var.feast_persistence_config.mysql.access_mode]
  }

  set {
    name  = "primary.persistence.size"
    value = var.feast_persistence_config.mysql.storage_size
  }
}

resource "random_password" "feast_redis_password" {
  count            = var.enable_feast ? 1 : 0
  length           = 12
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  override_special = "!@#$%^&*()-_=+?"
}

# Deploy Redis using Helm
resource "helm_release" "redis" {
  depends_on = [kubernetes_namespace.feast]
  count      = var.enable_feast ? 1 : 0
  name       = var.redis_feast_helm_release_name
  repository = var.redis_feast_helm_repository
  chart      = var.redis_feast_helm_chart
  namespace  = kubernetes_namespace.feast.0.metadata[0].name
  timeout    = var.helm_timeout

  set {
    name  = "architecture"
    value = "standalone"
  }

  set {
    name  = "master.resources.limits.memory"
    value = var.feast_persistence_config.redis.memory_limit
  }

  set {
    name  = "auth.password"
    value = local.feast_redis_password
  }

  set {
    name  = "service.port"
    value = local.feast_redis_port
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set {
    name  = "image.tag"
    value = "latest"
  }
}

# Feast store configuration
locals {
  feast_store_values = {
    entity_key_serialization_version = 2
    project                          = "feast"
    provider                         = "local"
    registry = {
      registry_type = "sql"
      path          = "mysql+pymysql://root:${urlencode(local.feast_mysql_root_password)}@mysql.feast.svc.cluster.local:${local.feast_mysql_port}/my_database"
    }
    offline_store = {
      type = "file"
    }
    online_store = {
      type              = "redis"
      connection_string = "redis-master.feast.svc.cluster.local:${local.feast_redis_port},password=${local.feast_redis_password}"
    }
  }
}

# Deploy Feast using Helm
resource "helm_release" "feast" {
  count      = var.enable_feast ? 1 : 0
  depends_on = [helm_release.mysql, helm_release.redis]
  name       = var.feast_helm_release_name
  repository = var.feast_helm_repository
  chart      = var.feast_helm_chart
  namespace  = kubernetes_namespace.feast.0.metadata[0].name
  timeout    = var.helm_timeout
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
