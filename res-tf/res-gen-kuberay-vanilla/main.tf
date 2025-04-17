locals {
  kuberay_cert          = var.ingress_domain_type == "Rafay" ? var.tls_crt : var.kuberay_host_cert
  kuberay_key           = var.ingress_domain_type == "Rafay" ? var.tls_key : var.kuberay_host_key
  local_secret_name   = "${var.cluster_name}-tls-secret"
  service_name        = "ray-cluster-kuberay-head-svc"
}

resource "random_password" "password" {
  length  = 10
  special = true
}

resource "htpasswd_password" "hash" {
  depends_on = [random_password.password]
  password = random_password.password.result
}

locals {
  ingress = (join(":", [var.ingress_user, htpasswd_password.hash.apr1]))
}

resource "local_file" "auth" {
  content  = local.ingress
  filename = "auth"
}

resource "kubernetes_namespace" "volcano" {
  metadata {
    name = "volcano-system"
  }
}

resource "helm_release" "apply-volcano" {
  count = var.enable_volcano == "true" ? 1 : 0

  name       = "volcano"
  repository = "https://volcano-sh.github.io/helm-charts/"
  chart      = "volcano"
  version    = var.volcano_version
  namespace  = kubernetes_namespace.volcano.metadata[0].name

  create_namespace = false
}

resource "helm_release" "kuberay-operator" {
  depends_on = [helm_release.apply-volcano]
  name       = "kuberay-operator"
  repository = "https://ray-project.github.io/kuberay-helm/"
  chart      = "kuberay-operator"
  version    = var.kuberay_version
  namespace  = "kuberay"

  create_namespace = true

  values = [
        <<-EOF
    batchScheduler:
      enabled: ${var.enable_volcano}
    EOF
  ]
}

resource "helm_release" "ray-cluster" {
  depends_on = [helm_release.kuberay-operator]
  name       = "ray-cluster"
  repository = "https://ray-project.github.io/kuberay-helm/"
  chart      = "ray-cluster"
  version    = var.kuberay_version
  namespace  = "kuberay"

  create_namespace = true

  values = [templatefile("${path.module}/templates/raycluster-values.yaml.tftpl", {
    head_config          = var.kuberay_head_config
    worker_config        = var.kuberay_worker_config
    worker_tolerations   = length(var.kuberay_worker_tolerations) > 0 ? jsonencode(var.kuberay_worker_tolerations) : null
    worker_node_selector = length(var.kuberay_worker_node_selector) > 0 ? jsonencode(var.kuberay_worker_node_selector) : null
  })]
}


## Use api_key to get organization hash id
data "external" "env" {
  program = ["${path.module}/scripts/env.sh"]
}

locals {
  rest_endpoint = sensitive(data.external.env.result["RCTL_REST_ENDPOINT"])
  api_key       = sensitive(data.external.env.result["RCTL_API_KEY"])
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
  response_data       = jsondecode(data.http.get_org.response_body)
  org_hash            = local.response_data.results[0].organization_id
  ingress_sub_domain  = "${var.environment_name}-${local.org_hash}"
  ingress_full_domain = var.ingress_domain_type == "Rafay" ? "${local.ingress_sub_domain}.${var.ingress_domain}" : "${var.kuberay_host_name}"
}


resource "local_file" "ray_ingress" {
  content = templatefile("${path.module}/templates/ray-ingress.tftpl", {
    cluster_name        = var.cluster_name
    secret_name         = "${local.local_secret_name}"
    ingress_full_domain = local.ingress_full_domain
    ingress_class       = var.ingress_class
    service_name        = "${local.service_name}"
  })
  filename = "${path.module}/kuberay-ingress.yaml"
}


resource "local_file" "tls_secret" {
  content = templatefile("${path.module}/templates/tls-secret.tftpl", {
    cluster_name = var.cluster_name
    tls_crt      = base64encode(trimspace(local.kuberay_cert))
    tls_key      = base64encode(trimspace(local.kuberay_key))
  })
  filename = "${path.module}/tls-secret.yaml"
}


resource "null_resource" "apply_ingress" {
  depends_on = [
    helm_release.kuberay-operator, 
    helm_release.ray-cluster,
    local_file.tls_secret,
    local_file.ray_ingress
  ]
  triggers = {
    always_run    = timestamp()
    cluster_name  = var.cluster_name
    project       = var.host_project
  }

  provisioner "local-exec" {
    command = "chmod +x ${path.module}/scripts/apply-ingress.sh && ${path.module}/scripts/apply-ingress.sh"
    environment = {
      CLUSTER_NAME    = var.cluster_name
      PROJECT         = var.host_project
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOD
      chmod +x ${path.module}/scripts/delete-ns-kuberay.sh && ${path.module}/scripts/delete-ns-kuberay.sh
    EOD
    environment = {
      CLUSTER_NAME    = "${self.triggers.cluster_name}"
      PROJECT         = "${self.triggers.project}"
    }
  }
}