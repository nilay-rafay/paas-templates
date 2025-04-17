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
  response_data = jsondecode(data.http.get_org.response_body)
  org_hash = local.response_data.results[0].organization_id
  ingress_sub_domain = "${var.name}-${local.org_hash}"
  rafay_ingress_domain_fqdn = var.ingress_domain_type == "Rafay" ? "${local.ingress_sub_domain}.${var.ingress_domain}" : "${local.ingress_sub_domain}.${var.ingress_custom_domain}"
  ingress_domain_name = local.rafay_ingress_domain_fqdn 

  create_tls_secret = var.ingress_domain_type == "Rafay" ? true : false
}

resource "random_string" "token" {
  count = 1
  length = 32
  special = false
  upper   = false
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
  }
}

locals {
  token = one(random_string.token[*].result)
}

resource "kubernetes_persistent_volume_claim" "pvc" {
  metadata {
    name      = "${var.name}-workspace"
    namespace = resource.kubernetes_namespace.namespace.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.pvc_storage
      }
    }
  }
  wait_until_bound = false
}

resource "kubernetes_deployment" "deployment" {
  metadata {
    name      = "${var.name}-notebook"
    namespace = resource.kubernetes_namespace.namespace.metadata[0].name
    labels = {
      app = "${var.name}-notebook"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "${var.name}-notebook"
      }
    }
    template {
      metadata {
        labels = {
          app = "${var.name}-notebook"
        }
      }
      spec {
        container {
          name    = "${var.name}-notebook"
          image   = [for v in var.notebook_profiles: v.image if v.name == var.notebook_profile][0]
          image_pull_policy = "IfNotPresent" 
          command = ["start-notebook.sh"]
          args    = ["--NotebookApp.token='${local.token}'"]
          resources {
            limits = {
              cpu                       = "${var.cpu_limit}"
              memory                    = "${var.memory_limit}"
              "nvidia.com/gpu" = "${var.gpu_limit}"
            }
            requests = {
              cpu                       = "${var.cpu_request}"
              memory                    = "${var.memory_request}"
            }
          }
          volume_mount {
            mount_path = "/home/jovyan"
            name       = "${var.name}-workspace"
          }
          volume_mount {
            mount_path = "/dev/shm"
            name       = "dshm"
          }
        }
        security_context {
          fs_group = 100
        }

        volume {
          name = "dshm"
          empty_dir {
            medium     = "Memory"
          }
        }
        volume {
          name = "${var.name}-workspace"
          persistent_volume_claim {
            claim_name = resource.kubernetes_persistent_volume_claim.pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_secret" "tls_secret" {

  count = local.create_tls_secret ? 1 : 0
  metadata {
    name      = "${var.name}-notebook-tls"
    namespace = resource.kubernetes_namespace.namespace.metadata[0].name
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = var.tls_crt
    "tls.key" = var.tls_key
  }
}


resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name      = "${var.name}-notebook"
    namespace = resource.kubernetes_namespace.namespace.metadata[0].name
    annotations = var.ingress_annotations
  }
  spec {
    tls {
      hosts       = ["${local.ingress_domain_name}"]
      secret_name = local.create_tls_secret ? kubernetes_secret.tls_secret[0].metadata[0].name : var.custom_secret_name
    }
    rule {
      host = "${local.ingress_domain_name}"
      http {
        path {
          path = "/"
          backend {
            service {
              name = "${var.name}-notebook"
              port {
                number = 8888
              }
            }
          }
          path_type = "Prefix"
        }
      }
    }

  }
}

resource "kubernetes_service" "service" {
  metadata {
    name      = "${var.name}-notebook"
    namespace = resource.kubernetes_namespace.namespace.metadata[0].name
  }
  spec {
    port {
      port        = 8888
      protocol    = "TCP"
      target_port = 8888
    }
    selector = {
      app = "${var.name}-notebook"
    }
    type = "ClusterIP"
  }
}
