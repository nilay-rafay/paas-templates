data "rafay_download_kubeconfig" "kubeconfig_cluster" {
  cluster = var.cluster_name
}

resource "local_file" "kubeconfig" {
  lifecycle {
    ignore_changes = all
  }
  depends_on = [data.rafay_download_kubeconfig.kubeconfig_cluster]
  content    = data.rafay_download_kubeconfig.kubeconfig_cluster.kubeconfig
  filename   = "/tmp/test/kubeconfig.yaml"
}

resource "null_resource" "kubeconfig_ready" {
  depends_on = [local_file.kubeconfig]
  provisioner "local-exec" {
    command = "while [ ! -f /tmp/test/kubeconfig.yaml ]; do sleep 1; done"
  }
}

resource "null_resource" "check_for_the_secret" {
  depends_on = [null_resource.kubeconfig_ready]
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
    chmod +x secret_check.sh && ./secret_check.sh
    EOT
  }
}

resource "helm_release" "kubeflow-namespace" {
  depends_on = [null_resource.check_for_the_secret]
  name       = "kubeflow"
  chart      = "charts/common/kubeflow-namespace"

  verify = false
}

resource "helm_release" "cert-manager" {
  depends_on = [
    helm_release.kubeflow-namespace
  ]
  count     = var.cert_manager_enabled ? 1 : 0
  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "cert-manager"
  chart     = "charts/common/cert-manager"

  verify = false
}


resource "helm_release" "kubeflow-issuer" {

  depends_on = [
    helm_release.kubeflow-namespace,
    helm_release.cert-manager
  ]

  name      = "kubeflow-issuer"
  namespace = helm_release.kubeflow-namespace.metadata[0].name
  chart     = "charts/common/kubeflow-issuer"

  verify = false
}

resource "helm_release" "kubeflow-roles" {

  depends_on = [
    helm_release.kubeflow-namespace
  ]

  name      = "kubeflow-roles"
  namespace = helm_release.kubeflow-namespace.metadata[0].name
  chart     = "charts/common/kubeflow-roles"

  verify = false
}

locals {
  encoded_cert = base64encode(trimspace(var.kubeflow_host_cert))
  encoded_key  = base64encode(trimspace(var.kubeflow_host_key))
}


resource "helm_release" "istio" {

  depends_on = [
    helm_release.kubeflow-namespace
  ]

  name      = "istio"
  namespace = helm_release.kubeflow-namespace.metadata[0].name
  chart     = "charts/common/istio"

  verify = false

  set {
    name  = "istio.host"
    value = var.kubeflow_host_name
  }
  set {
    //base64 encoded cert and key
    name  = "istio.tls.cert"
    value = local.encoded_cert
  }
  set {
    //base64 encoded cert and key
    name  = "istio.tls.key"
    value = local.encoded_key
  }
  set {
    name  = "istio.ingressClassName"
    value = var.istio_ingress_class_name
  }
  set {
    name  = "istioIngressgateway.istiosvc.type"
    value = var.istio_svc_type
  }
}



resource "helm_release" "cluster-local-gateway" {

  depends_on = [
    helm_release.istio
  ]

  namespace = "istio-system"
  name      = "cluster-local-gateway"
  chart     = "charts/common/cluster-local-gateway"

  verify = false
}

resource "bcrypt_hash" "hashed_local_users" {
  count     = length(var.kubeflow_local_users)
  cleartext = var.kubeflow_local_users[count.index].password
}

resource "helm_release" "dex" {

  depends_on = [
    helm_release.istio
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "dex"
  chart     = "charts/common/dex"

  values = [
    yamlencode({
      dex = {
        issuer = "https://${var.kubeflow_host_name}/dex"
        staticPasswords = [
          for index, user in var.kubeflow_local_users : {
            username = user.username
            password = bcrypt_hash.hashed_local_users[index].id
          }
        ]
      }
    })
  ]

  verify = false
}

resource "helm_release" "oidc-authservice" {

  depends_on = [
    helm_release.dex
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "oidc-authservice"
  chart     = "charts/common/oidc-authservice"

  set {
    name  = "oidc.issuer"
    value = "https://${var.kubeflow_host_name}/dex"
  }

  verify = false
  wait   = false
}


resource "helm_release" "jupyter-web-app" {

  depends_on = [
    helm_release.dex
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "jupyter-web-app"
  chart     = "charts/apps/jupyter-web-app"
  verify    = false
}

resource "helm_release" "notebook-controller" {

  depends_on = [
    helm_release.jupyter-web-app
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "notebook-controller"
  chart     = "charts/apps/notebook-controller"
  verify    = false
}

resource "helm_release" "admission-webhook" {

  depends_on = [
    helm_release.notebook-controller
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "admission-webhook"
  chart     = "charts/apps/admission-webhook"
  verify    = false
}

resource "kubernetes_namespace" "rafay_aiml" {
  metadata {
    name = "rafay-aiml"
  }
}

resource "helm_release" "kfp-poddefault-controller" {

  depends_on = [
    helm_release.admission-webhook,
    kubernetes_namespace.rafay_aiml,
  ]

  namespace = kubernetes_namespace.rafay_aiml.metadata[0].name
  name      = "kfp-poddefault-controller"
  chart     = "charts/apps/kfp-poddefault-controller"
  verify    = false
}

resource "helm_release" "central-dashboard" {

  depends_on = [
    helm_release.admission-webhook
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "central-dashboard"
  chart     = "charts/apps/central-dashboard"
  verify    = false

  set {
    name  = "centraldashboard.centraldashboard.mlflow.enabled"
    value = var.enable_mlflow
  }
}

resource "helm_release" "profiles-and-kfam" {

  depends_on = [
    helm_release.central-dashboard
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "profiles-and-kfam"
  chart     = "charts/apps/profiles-and-kfam"
  verify    = false
}

resource "random_password" "kfp_mysql_root_password" {
  length      = 12
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  # min_special = 1
  special = false
}

resource "random_password" "kfp_minio_secret_key" {
  length      = 12
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  # min_special = 1
  special = false
}

resource "helm_release" "kubeflow-pipelines" {

  depends_on = [
    helm_release.profiles-and-kfam
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "kubeflow-pipelines"
  chart     = "charts/self-contained/kubeflow-pipelines"
  verify    = false
  timeout   = 1000

  values = [
    yamlencode({
      minio = {
        persistence = {
          size         = var.kfp_persistence_config.minio.storage_size
          accessMode   = var.kfp_persistence_config.minio.access_mode
          storageClass = var.kfp_persistence_config.minio.storage_class_name
        }
        accessKey = "minio"
        secretKey = random_password.kfp_minio_secret_key.result
      }
      mysql = {
        persistence = {
          size         = var.kfp_persistence_config.mysql.storage_size
          accessMode   = var.kfp_persistence_config.mysql.access_mode
          storageClass = var.kfp_persistence_config.mysql.storage_class_name
        }
        rootPassword = random_password.kfp_mysql_root_password.result
      }
    })
  ]
}

resource "helm_release" "training-operator" {

  depends_on = [
    helm_release.kubeflow-pipelines
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "training-operator"
  chart     = "charts/apps/training-operator"
  verify    = false
}

resource "random_password" "katib_mysql_root_password" {
  length      = 12
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  # min_special = 1
  special = false
}


resource "helm_release" "katib" {

  depends_on = [
    helm_release.training-operator
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "katib"
  chart     = "charts/self-contained/katib"
  verify    = false
  timeout   = 1000

  values = [
    yamlencode({
      katibMysql = {
        persistence = {
          size         = var.katib_persistence_config.mysql.storage_size
          accessMode   = var.katib_persistence_config.mysql.access_mode
          storageClass = var.katib_persistence_config.mysql.storage_class_name
        }
        rootPassword = random_password.katib_mysql_root_password.result
      }
    })
  ]
}

resource "helm_release" "volumes-web-app" {

  depends_on = [
    helm_release.katib
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "volumes-web-app"
  chart     = "charts/apps/volumes-web-app"
  verify    = false
}

resource "helm_release" "pvcviewer-controller" {

  depends_on = [
    helm_release.volumes-web-app
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "pvcviewer-controller"
  chart     = "charts/apps/pvcviewer-controller"
  verify    = false
}

resource "helm_release" "knative-eventing" {

  depends_on = [
    helm_release.pvcviewer-controller
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "knative-eventing"
  chart     = "charts/common/knative-eventing"
  verify    = false
  timeout   = 1000
}


resource "helm_release" "knative-serving" {

  depends_on = [
    helm_release.knative-eventing
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "knative-serving"
  chart     = "charts/common/knative-serving"
  verify    = false
  timeout   = 1000
}

resource "helm_release" "kserve" {

  depends_on = [
    helm_release.knative-eventing
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "kserve"
  chart     = "charts/common/kserve"
  verify    = false
  timeout   = 1000
}

resource "helm_release" "models-web-app" {

  depends_on = [
    helm_release.kserve
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "models-web-app"
  chart     = "charts/apps/models-web-app"
  verify    = false
}

resource "helm_release" "tensorboard-controller" {

  depends_on = [
    helm_release.knative-serving
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "tensorboard-controller"
  chart     = "charts/apps/tensorboard-controller"
  verify    = false
}

resource "helm_release" "tensorboards-web-app" {

  depends_on = [
    helm_release.tensorboard-controller
  ]

  namespace = helm_release.kubeflow-namespace.metadata[0].name
  name      = "tensorboards-web-app"
  chart     = "charts/apps/tensorboards-web-app"
  verify    = false
}
