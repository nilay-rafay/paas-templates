locals {
  kubeflow_cert          = var.ingress_domain_type == "Rafay" ? var.tls_crt : var.kubeflow_host_cert
  kubeflow_key           = var.ingress_domain_type == "Rafay" ? var.tls_key : var.kubeflow_host_key
  kubeflow_host_name     = var.kubeflow_host_name
  ingress_domain_type    = var.ingress_domain_type
  okta_client_id         = var.okta_client_id
  okta_client_secret     = var.okta_client_secret
  okta_domain            = var.okta_domain
  istio_svc_type         = var.istio_svc_type
  istio_svc_lb_type      = var.istio_svc_lb_type
  cull_idle_time         = var.cull_idle_time
  enable_culling         = var.enable_culling
  mysql_instance         = var.kubeflow_mysql_instance
  mysql_port             = var.kubeflow_mysql_port
  mysql_user             = var.kubeflow_mysql_user
  mysql_password         = var.kubeflow_mysql_password
  external_s3_host       = var.pipeline_external_s3_host
  external_s3_bucket     = var.pipeline_external_s3_bucket
  external_s3_access_key = var.pipeline_external_s3_access_key
  external_s3_secret_key = var.pipeline_external_s3_secret_key
}

resource "bcrypt_hash" "password_hash" {
  cleartext = var.kubeflow_static_user_password
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

data "external" "env" {
  program = ["${path.module}/scripts/env.sh"]
}

locals {
  rest_endpoint = data.external.env.result["RCTL_REST_ENDPOINT"]
  api_key = data.external.env.result["RCTL_API_KEY"]
  insecure       = data.external.env.result["RCTL_SKIP_SERVER_CERT_VALIDATION"]
}

data "http" "get_org" {
  url = "https://${local.rest_endpoint}/auth/v1/projects/?limit=48&offset=0&order=ASC&orderby=name&q=defaultproject"
  insecure = local.insecure != "" ? true : false
  request_headers = {
    "X-RAFAY-API-KEYID" = "${local.api_key}"
    Accept        = "application/json"
  }
}

locals {
  kubeflow_mysql_instance   = [for i in data.google_sql_database_instances.all_instances.instances : i if i.name == local.mysql_instance][0]
  response_data             = jsondecode(data.http.get_org.response_body)
  org_hash                  = local.response_data.results[0].organization_id
  ingress_sub_domain        = "${var.name}-${local.org_hash}"
  ingress_full_url          = var.ingress_domain_type == "Rafay" ? "${local.ingress_sub_domain}.${var.ingress_domain}" : var.kubeflow_host_name
}



resource "helm_release" "cert-manager" {
  count = var.cert_manager_enabled ? 1 : 0

  name  = "cert-manager"
  chart = "charts/common/cert-manager"
  timeout = 3000
  verify = false
}

resource "helm_release" "kubeflow-namespace" {
  name  = "kubeflow-namespace"
  chart = "charts/common/kubeflow-namespace"
  timeout = 3000
  verify = false
}


resource "helm_release" "kubeflow-issuer" {

  depends_on = [
    helm_release.kubeflow-namespace
  ]

  name  = "kubeflow-issuer"
  chart = "charts/common/kubeflow-issuer"
  timeout = 3000
  verify = false
}

resource "helm_release" "kubeflow-roles" {

  depends_on = [
    helm_release.kubeflow-namespace
  ]

  name  = "kubeflow-roles"
  chart = "charts/common/kubeflow-roles"
  timeout = 3000
  verify = false
}


resource "helm_release" "istio" {

  name  = "istio"
  chart = "charts/common/istio"
  timeout = 3000
  verify = false

  set {
    name  = "istio.host"
    value = local.ingress_full_url
  }
  set {
    //base64 encoded crt
    name  = "istio.tls.crt"
    value = base64encode(trimspace(local.kubeflow_cert))
  }
  set {
    //base64 encoded key
    name  = "istio.tls.key"
    value = base64encode(trimspace(local.kubeflow_key))
  }
  
  set {
    name  = "istioIngressgateway.istiosvc.type"
    value = local.istio_svc_type
  }
  dynamic "set" {
    for_each = local.istio_svc_lb_type == "Internal" ? [local.istio_svc_lb_type] : []
    content {
      name  = "istioIngressgateway.istiosvc.annotations.networking\\.gke\\.io/load-balancer-type"
      value = set.value
    } 
  }
}

resource "kubernetes_namespace" "cluster-local-gateway" {
  depends_on = [helm_release.istio]
  metadata {
    name = "cluster-local-gateway"
  }
}

resource "helm_release" "cluster-local-gateway" {

  depends_on = [
    kubernetes_namespace.cluster-local-gateway
  ]

  namespace        = "cluster-local-gateway"
  create_namespace = false
  name             = "cluster-local-gateway"
  chart            = "charts/common/cluster-local-gateway"
  timeout          = 3000
  verify = false
}

resource "helm_release" "dex" {

  depends_on = [
    helm_release.istio,
    helm_release.kubeflow-namespace
  ]

  namespace = "kubeflow"
  name      = "dex"
  chart     = "charts/common/dex"
  timeout   = 3000
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

  set {
    name  = "dex.staticuser.email"
    value = var.kubeflow_static_user_email
  }

  set {
    name  = "dex.staticuser.password"
    value = bcrypt_hash.password_hash.id
  }

  verify = false
}

resource "helm_release" "oidc-authservice" {

  depends_on = [
    helm_release.dex,
    helm_release.kubeflow-namespace
  ]
  timeout   = 3000
  namespace = "kubeflow"
  name      = "oidc-authservice"
  chart     = "charts/common/oidc-authservice"

  set {
    name  = "oidc.issuer"
    value = "https://${local.ingress_full_url}/dex"
  }

  verify = false
  wait   = false
}


resource "helm_release" "jupyter-web-app" {

  depends_on = [
    helm_release.dex,
    helm_release.kubeflow-namespace
  ]

  namespace = "kubeflow"
  name      = "jupyter-web-app"
  chart     = "charts/apps/jupyter-web-app"
  verify    = false
  timeout   = 3000
}

resource "helm_release" "notebook-controller" {

  depends_on = [
    helm_release.jupyter-web-app,
    helm_release.kubeflow-namespace
  ]

  namespace = "kubeflow"
  name      = "notebook-controller"
  chart     = "charts/apps/notebook-controller"
  verify    = false
  timeout   = 3000 

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

  depends_on = [
    helm_release.notebook-controller,
    helm_release.kubeflow-namespace
  ]

  namespace = "kubeflow"
  name      = "admission-webhook"
  chart     = "charts/apps/admission-webhook"
  verify    = false
  timeout   = 3000
}


resource "helm_release" "central-dashboard" {

  depends_on = [
    helm_release.admission-webhook,
    helm_release.kubeflow-namespace
  ]

  namespace = "kubeflow"
  name      = "central-dashboard"
  chart     = "charts/apps/central-dashboard"
  verify    = false
  timeout   = 3000
}

resource "helm_release" "profiles-and-kfam" {

  depends_on = [
    helm_release.central-dashboard,
    helm_release.kubeflow-namespace
  ]

  namespace = "kubeflow"
  name      = "profiles-and-kfam"
  chart     = "charts/apps/profiles-and-kfam"
  verify    = false
  timeout   = 3000
}

resource "helm_release" "kubeflow-pipelines" {

  depends_on = [
    helm_release.profiles-and-kfam,
    helm_release.kubeflow-namespace
  ]

  namespace = "kubeflow"
  name      = "kubeflow-pipelines"
  chart     = "charts/gcp/apps/kubeflow-pipelines/vanilla"
  verify    = false
  timeout   = 3000

  set {
    name  = "pipelineSqlConfig.host"
    value = local.kubeflow_mysql_instance.private_ip_address
  }
  set {
    name  = "pipelineSqlConfig.port"
    value = local.mysql_port
  }
  set {
    name  = "pipelineSqlConfig.user"
    value = local.mysql_user
  }
  set {
    name  = "pipelineSqlConfig.password"
    value = local.mysql_password
  }
  set {
    name  = "pipelineexternals3.host"
    value = local.external_s3_host
  }
  set {
    name  = "pipelineexternals3.bucket"
    value = local.external_s3_bucket
  }
  set {
    name  = "pipelineexternals3.accesskey"
    value = local.external_s3_access_key
  }
  set {
    name  = "pipelineexternals3.secretkey"
    value = local.external_s3_secret_key
  }
}

resource "helm_release" "training-operator" {

  depends_on = [
    helm_release.dex,
    helm_release.kubeflow-namespace
  ]

  namespace = "kubeflow"
  name      = "training-operator"
  chart     = "charts/apps/training-operator"
  verify    = false
  timeout   = 3000
}


resource "helm_release" "katib" {

  depends_on = [
    helm_release.training-operator,
    helm_release.kubeflow-namespace
  ]

  namespace = "kubeflow"
  name      = "katib"
  chart     = "charts/gcp/apps/katib/vanilla"
  verify    = false
  timeout   = 3000

  set {
    name  = "katibMysql.host"
    value = local.kubeflow_mysql_instance.private_ip_address
  }
  set {
    name  = "katibMysql.port"
    value = local.mysql_port
  }
  set {
    name  = "katibMysql.user"
    value = local.mysql_user
  }
  set {
    name = "katibMysql.password"
    #base64 encoded password
    value = base64encode(local.mysql_password)
  }
}

resource "helm_release" "volumes-web-app" {

  depends_on = [
    helm_release.training-operator,
    helm_release.kubeflow-namespace
  ]
  
  namespace = "kubeflow"
  name      = "volumes-web-app"
  chart     = "charts/apps/volumes-web-app"
  verify    = false
  timeout   = 3000
}

resource "helm_release" "pvcviewer-controller" {

  depends_on = [
    helm_release.volumes-web-app,
    helm_release.kubeflow-namespace
  ]

  namespace = "kubeflow"
  name      = "pvcviewer-controller"
  chart     = "charts/apps/pvcviewer-controller"
  verify    = false
  timeout = 3000
}

resource "helm_release" "knative-eventing" {

  depends_on = [
    helm_release.pvcviewer-controller,
    helm_release.kubeflow-namespace
  ]

  namespace = "kubeflow"
  name      = "knative-eventing"
  chart     = "charts/common/knative-eventing"
  verify    = false
  timeout   = 3000
}


resource "helm_release" "knative-serving" {

  depends_on = [
    helm_release.knative-eventing,
    helm_release.kubeflow-namespace
  ]

  namespace = "kubeflow"
  name      = "knative-serving"
  chart     = "charts/common/knative-serving"
  verify    = false
  timeout   = 3000
}

resource "helm_release" "kserve" {

  depends_on = [
    helm_release.knative-eventing
  ]

  namespace = "kubeflow"
  name      = "kserve"
  chart     = "charts/common/kserve"
  verify    = false
  timeout   = 3000
}

resource "helm_release" "models-web-app" {

  depends_on = [
    helm_release.kserve,
    helm_release.kubeflow-namespace
  ]

  namespace = "kubeflow"
  name      = "models-web-app"
  chart     = "charts/apps/models-web-app"
  verify    = false
  timeout = 3000
}

resource "helm_release" "tensorboard-controller" {

  depends_on = [
    helm_release.knative-serving,
    helm_release.kubeflow-namespace
  ]

  namespace = "kubeflow"
  name      = "tensorboard-controller"
  chart     = "charts/apps/tensorboard-controller"
  verify    = false
  timeout = 3000
}

resource "helm_release" "tensorboards-web-app" {

  depends_on = [
    helm_release.tensorboard-controller,
    helm_release.kubeflow-namespace
  ]

  namespace = "kubeflow"
  name      = "tensorboards-web-app"
  chart     = "charts/apps/tensorboards-web-app"
  verify    = false
  timeout = 3000
}


data "kubernetes_service" "istio_ingressgateway" {

  depends_on = [
  helm_release.central-dashboard]

  metadata {
    name      = "istio-ingressgateway"
    namespace = "istio-system"
  }
}
