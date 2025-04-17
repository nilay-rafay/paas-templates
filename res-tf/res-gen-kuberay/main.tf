locals {
  kuberay_cert          = var.ingress_domain_type == "Rafay" ? var.tls_crt : var.kuberay_host_cert
  kuberay_key           = var.ingress_domain_type == "Rafay" ? var.tls_key : var.kuberay_host_key
  local_secret_name   = "${var.vcluster_name}-tls-secret"
  service_name        = "${var.vcluster_name}-kuberay-head-svc"
}


resource "local_file" "kubeconfig" {
  lifecycle {
    ignore_changes = all
  }
  content    = var.kubeconfig
  filename   = "/tmp/test/host-kubeconfig.yaml"
}

resource "null_resource" "host_kubeconfig_ready" {
  depends_on = [local_file.kubeconfig]
  provisioner "local-exec" {
    command = "while [ ! -f /tmp/test/host-kubeconfig.yaml ]; do sleep 1; done"
  }
}

resource "random_password" "password" {
  depends_on  = [null_resource.host_kubeconfig_ready]
  length      = 10
  special     = true
}

resource "htpasswd_password" "hash" {
  depends_on = [random_password.password]
  password   = random_password.password.result
}

locals {
  ingress = (join(":", [var.ingress_user, htpasswd_password.hash.apr1]))
}

resource "local_file" "auth" {
  content  = local.ingress
  filename = "auth"
}

resource "rafay_import_cluster" "import_vcluster" {
  clustername           = var.vcluster_name
  projectname           = var.project
  blueprint             = var.blueprint
  blueprint_version     = var.blueprint_version
  values_path           = "${path.module}/values.yaml"
  kubernetes_provider   = "OTHER"
  provision_environment = "CLOUD"
}

resource "rafay_namespace" "namespace" {
  depends_on = [rafay_import_cluster.import_vcluster]
  metadata {
    name        = var.namespace
    project     = var.host_project
    labels      = try(var.namespace_labels, null)
    annotations = try(var.namespace_annotations, null)
    description = "Namespace for ${var.vcluster_name} vCluster"
  }
  spec {
    drift {
      enabled = false
    }
    placement {
      labels {
        key   = "rafay.dev/clusterName"
        value = var.host_cluster_name
      }
    }
  }
}


resource "helm_release" "vcluster" {
  depends_on = [rafay_namespace.namespace]
  name       = var.vcluster_name
  repository = "https://charts.loft.sh"
  chart      = "vcluster"
  version    = var.vcluster_version
  namespace  = resource.rafay_namespace.namespace.metadata[0].name

  create_namespace = true

  set {
    name  = "controlPlane.distro.${var.distro}.enabled"
    value = "true"
  }

  set {
    name  = "controlPlane.statefulSet.scheduling.podManagementPolicy"
    value = "OrderedReady"
  }

  set {
    name  = "controlPlane.statefulSet.persistence.volumeClaim.size"
    value = var.vcluster_store_size
  }

  values = [templatefile("${path.module}/templates/vcluster-values.yaml.tftpl", {
    tolerations          = length(var.tolerations) > 0 ? jsonencode(var.tolerations) : null
    values               = indent(12, rafay_import_cluster.import_vcluster.values_data)
    kuberay_version      = var.kuberay_version
    vcluster_name        = var.vcluster_name
    head_config          = var.kuberay_head_config
    worker_config        = var.kuberay_worker_config
    worker_tolerations   = length(var.kuberay_worker_tolerations) > 0 ? jsonencode(var.kuberay_worker_tolerations) : null
    worker_node_selector = length(var.kuberay_worker_node_selector) > 0 ? jsonencode(var.kuberay_worker_node_selector) : null
  })]
}

resource "kubernetes_manifest" "volcano_queue" {
  depends_on = [helm_release.vcluster]
  manifest = {
    apiVersion = "scheduling.volcano.sh/v1beta1"
    kind       = "Queue"
    metadata = {
      name = var.vcluster_name
    }
    spec = {
      reclaimable = true
    }
  }
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
    Accept              = "application/json"
  }
}

locals {
  response_data       = jsondecode(data.http.get_org.response_body)
  org_hash            = local.response_data.results[0].organization_id
  ingress_sub_domain  = "${var.environment_name}-${local.org_hash}"
  ingress_full_domain = var.ingress_domain_type == "Rafay" ? "${local.ingress_sub_domain}.${var.ingress_domain}" : "${var.kuberay_host_name}.${var.domain}"
}


resource "local_file" "ray_ingress" {
  content = templatefile("${path.module}/templates/ray-ingress.tftpl", {
    cluster_name        = var.vcluster_name
    secret_name         = "${local.local_secret_name}"
    ingress_full_domain = local.ingress_full_domain
    ingress_class       = var.ingress_class
    cluster_issuer_name = var.cluster_issuer_name
    service_name        = "${local.service_name}"
  })
  filename = "${path.module}/kuberay-ingress.yaml"
}


resource "local_file" "tls_secret" {
  content = templatefile("${path.module}/templates/tls-secret.tftpl", {
    cluster_name = var.vcluster_name
    tls_crt      = base64encode(trimspace(local.kuberay_cert))
    tls_key      = base64encode(trimspace(local.kuberay_key))
  })
  filename = "${path.module}/tls-secret.yaml"
}


resource "null_resource" "apply_ingress" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "chmod +x ${path.module}/scripts/apply-ingress.sh && ${path.module}/scripts/apply-ingress.sh"
    environment = {
      CLUSTER_NAME = var.vcluster_name
      PROJECT      = var.project
    }
  }
  depends_on = [helm_release.vcluster]
}

resource "rafay_group" "group-dev" {
  count = var.create_group ? 1 : 0
  name  = "${var.vcluster_name}-group"
}

resource "rafay_groupassociation" "groupassociation" {
  count     = var.create_group ? 1 : 0
  project   = var.project
  group     = resource.rafay_group.group-dev[count.index].name
  roles     = ["PROJECT_ADMIN"]
  add_users = [var.username]
  idp_user  = var.user_type
}

resource "null_resource" "cleanup" {
  triggers = {
    vcluster_name = var.vcluster_name
    cluster_name  = var.host_cluster_name
    project       = var.host_project
  }
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = "${path.module}/scripts/vcluster-pods-delete.sh"
    environment = {
      VCLUSTER_NAME = "${self.triggers.vcluster_name}"
      CLUSTER_NAME  = "${self.triggers.cluster_name}"
      PROJECT       = "${self.triggers.project}"
    }
  }
}