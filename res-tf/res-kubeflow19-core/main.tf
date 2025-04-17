locals {
  kubeflow_cert       = var.ingress_domain_type == "Rafay" ? var.tls_crt : var.kubeflow_host_cert
  kubeflow_key        = var.ingress_domain_type == "Rafay" ? var.tls_key : var.kubeflow_host_key
  kubeflow_host_name  = var.kubeflow_host_name
  istio_svc_type      = var.istio_svc_type
  cull_idle_time      = var.cull_idle_time
  enable_culling      = var.enable_culling
  ingress_domain_type = var.ingress_domain_type
  response_data       = jsondecode(data.http.get_org.response_body)
  rest_endpoint       = data.external.env.result["RCTL_REST_ENDPOINT"]
  api_key             = data.external.env.result["RCTL_API_KEY"]
  okta_client_id      = var.okta_client_id
  okta_client_secret  = var.okta_client_secret
  okta_domain         = var.okta_domain
  insecure       = data.external.env.result["RCTL_SKIP_SERVER_CERT_VALIDATION"]
}

resource "bcrypt_hash" "hashed_local_users" {
  count     = length(var.kubeflow_local_users)
  cleartext = var.kubeflow_local_users[count.index].password
}

resource "bcrypt_hash" "password_hash" {
  cleartext = var.kubeflow_static_user_password
}

data "external" "env" {
  program = ["${path.module}/scripts/env.sh"]
}

data "http" "get_org" {
  url = "https://${local.rest_endpoint}/auth/v1/projects/?limit=48&offset=0&order=ASC&orderby=name&q=defaultproject"
  insecure = local.insecure != "" ? true : false
  request_headers = {
    "X-RAFAY-API-KEYID" = "${local.api_key}"
    Accept              = "application/json"
  }
}

locals {
  org_hash           = local.response_data.results[0].organization_id
  ingress_sub_domain = "${var.name}-${local.org_hash}"
  ingress_full_url   = var.ingress_domain_type == "Rafay" ? "${local.ingress_sub_domain}.${var.ingress_domain}" : var.kubeflow_host_name
}

resource "null_resource" "check_for_the_secret" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
    chmod +x scripts/secret_check.sh && bash scripts/secret_check.sh
    EOT
  }
}

resource "helm_release" "kubeflow-namespace" {
  depends_on = [bcrypt_hash.password_hash]
  name       = "kubeflow"
  chart      = "charts/common/kubeflow-namespace"
  verify     = false
  timeout    = var.helm_timeout
}

resource "helm_release" "cert-manager" {
  depends_on = [helm_release.kubeflow-namespace]
  count      = var.cert_manager_enabled ? 1 : 0
  name       = "cert-manager"
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  chart      = "charts/common/cert-manager"
  verify     = false
  timeout    = var.helm_timeout
}

resource "helm_release" "kubeflow-issuer" {
  depends_on = [helm_release.cert-manager]
  name       = "kubeflow-issuer"
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  chart      = "charts/common/kubeflow-issuer"
  verify     = false
  timeout    = var.helm_timeout
}

resource "helm_release" "kubeflow-roles" {
  depends_on = [helm_release.kubeflow-issuer]
  name       = "kubeflow-roles"
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  chart      = "charts/common/kubeflow-roles"
  verify     = false
  timeout    = var.helm_timeout
}

# resource "null_resource" "delete_ingress_nginx_admission" {
#   depends_on = [helm_release.kubeflow-roles]
#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]
#     command     = <<-EOT
#      chmod +x scripts/delete_admission_controller.sh && bash scripts/delete_admission_controller.sh
#     EOT
#   }
# }

resource "helm_release" "istio" {
  depends_on = [helm_release.kubeflow-roles]
  name       = "istio"
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  chart      = "charts/common/istio"
  verify     = false
  timeout    = var.helm_timeout

  set {
    name  = "istio.host"
    value = local.ingress_full_url
  }
  set {
    name  = "istio.tls.cert"
    value = base64encode(trimspace(local.kubeflow_cert))
  }
  set {
    name  = "istio.tls.key"
    value = base64encode(trimspace(local.kubeflow_key))
  }

  set {
    name  = "istioIngressgateway.istiosvc.type"
    value = local.istio_svc_type
  }
  set {
    name  = "istio.ingressClassName"
    value = var.istio_ingress_class_name
  }
}

resource "kubernetes_namespace" "cluster-local-gateway" {
  depends_on = [helm_release.istio]
  metadata {
    name = "cluster-local-gateway"
  }
}
resource "helm_release" "cluster-local-gateway" {
  depends_on = [kubernetes_namespace.cluster-local-gateway]
  namespace  = resource.kubernetes_namespace.cluster-local-gateway.metadata[0].name
  name       = "cluster-local-gateway"
  chart      = "charts/common/cluster-local-gateway"
  verify     = false
  timeout    = var.helm_timeout
}

resource "helm_release" "dex" {
  depends_on = [helm_release.cluster-local-gateway]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "dex"
  chart      = "charts/common/dex"
  timeout    = var.helm_timeout
  set {
    name  = "dex.issuer"
    value = "https://${local.ingress_full_url}/dex"
  }
  set {
    name  = "dex.connector.okta.clientID"
    value = local.okta_client_id
  }
  set {
    name  = "dex.connector.okta.clientSecret"
    value = local.okta_client_secret
  }

  set {
    name  = "dex.connector.okta.domain"
    value = local.okta_domain
  }

  values = [
    yamlencode({
      dex = {
        issuer = "https://${local.ingress_full_url}/dex"
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
  depends_on = [helm_release.dex]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "oidc-authservice"
  chart      = "charts/common/oidc-authservice"
  timeout    = var.helm_timeout
  set {
    name  = "oidc.issuer"
    value = "https://${local.ingress_full_url}/dex"
  }

  verify = false
  wait   = false
}


resource "helm_release" "jupyter-web-app" {
  depends_on = [helm_release.dex]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "jupyter-web-app"
  chart      = "charts/apps/jupyter-web-app"
  verify     = false
  timeout    = var.helm_timeout
}

resource "helm_release" "notebook-controller" {
  depends_on = [helm_release.jupyter-web-app]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "notebook-controller"
  chart      = "charts/apps/notebook-controller"
  verify     = false
  timeout    = var.helm_timeout

  set {
    name  = "notebookControllerDeployment.manager.enableCulling"
    value = var.enable_culling
  }

  dynamic "set" {
    for_each = var.enable_culling == true ? [1] : []
    content {
      name  = "notebookControllerDeployment.manager.cullIdleTime"
      value = var.cull_idle_time
    }
  }

}

resource "helm_release" "admission-webhook" {
  depends_on = [helm_release.notebook-controller]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "admission-webhook"
  chart      = "charts/apps/admission-webhook"
  verify     = false
  timeout    = var.helm_timeout
}


resource "helm_release" "central-dashboard" {
  depends_on = [helm_release.admission-webhook]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "central-dashboard"
  chart      = "charts/apps/central-dashboard"
  verify     = false
  timeout    = var.helm_timeout
}

resource "helm_release" "profiles-and-kfam" {
  depends_on = [helm_release.central-dashboard]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "profiles-and-kfam"
  chart      = "charts/apps/profiles-and-kfam"
  verify     = false
  timeout    = var.helm_timeout
}

resource "helm_release" "kubeflow-pipelines" {
  depends_on = [helm_release.profiles-and-kfam]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "kubeflow-pipelines"
  chart      = "charts/gcp/apps/kubeflow-pipelines/vanilla"
  verify     = false
  timeout    = var.helm_timeout
}

resource "helm_release" "training-operator" {
  depends_on = [helm_release.dex]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "training-operator"
  chart      = "charts/apps/training-operator"
  verify     = false
  timeout    = var.helm_timeout
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
  depends_on = [helm_release.training-operator]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "katib"
  chart      = "charts/gcp/apps/katib/vanilla"
  verify     = false
  timeout    = var.helm_timeout

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
  depends_on = [helm_release.training-operator]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "volumes-web-app"
  chart      = "charts/apps/volumes-web-app"
  verify     = false
  timeout    = var.helm_timeout
}

resource "helm_release" "pvcviewer-controller" {
  depends_on = [helm_release.volumes-web-app]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "pvcviewer-controller"
  chart      = "charts/apps/pvcviewer-controller"
  verify     = false
  timeout    = var.helm_timeout
}

resource "helm_release" "knative-eventing" {
  depends_on = [helm_release.pvcviewer-controller]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "knative-eventing"
  chart      = "charts/common/knative-eventing"
  verify     = false
  timeout    = var.helm_timeout
}


resource "helm_release" "knative-serving" {
  depends_on = [helm_release.knative-eventing]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "knative-serving"
  chart      = "charts/common/knative-serving"
  verify     = false
  timeout    = var.helm_timeout
}

resource "helm_release" "kserve" {
  depends_on = [helm_release.knative-eventing]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "kserve"
  chart      = "charts/common/kserve"
  verify     = false
  timeout    = var.helm_timeout
}

resource "helm_release" "models-web-app" {
  depends_on = [helm_release.kserve]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "models-web-app"
  chart      = "charts/apps/models-web-app"
  verify     = false
  timeout    = var.helm_timeout
}

resource "helm_release" "tensorboard-controller" {
  depends_on = [helm_release.knative-serving]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "tensorboard-controller"
  chart      = "charts/apps/tensorboard-controller"
  verify     = false
  timeout    = var.helm_timeout
}

resource "helm_release" "tensorboards-web-app" {
  depends_on = [helm_release.tensorboard-controller]
  namespace  = helm_release.kubeflow-namespace.metadata[0].name
  name       = "tensorboards-web-app"
  chart      = "charts/apps/tensorboards-web-app"
  verify     = false
  timeout    = var.helm_timeout
}

# resource "null_resource" "delete_authn_filter" {
#   depends_on = [helm_release.tensorboards-web-app]
#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]
#     command     = <<-EOT
#     chmod +x scripts/delete_envoy_filter.sh && bash scripts/delete_envoy_filter.sh
#     EOT
#   }
# }

data "kubernetes_service" "istio_ingressgateway" {
  depends_on = [helm_release.central-dashboard]
  metadata {
    name      = "istio-ingressgateway"
    namespace = "istio-system"
  }
}
