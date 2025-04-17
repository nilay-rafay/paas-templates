data "external" "env" {
  program = ["${path.module}/scripts/env.sh"]
}

locals {
  rest_endpoint = data.external.env.result["RCTL_REST_ENDPOINT"]
  api_key       = data.external.env.result["RCTL_API_KEY"]
  insecure      = data.external.env.result["RCTL_SKIP_SERVER_CERT_VALIDATION"] != "" ? true : false
  hf_token      = data.external.env.result["HF_TOKEN"]
}



data "http" "get_org" {
  url      = "https://${local.rest_endpoint}/auth/v1/projects/?limit=48&offset=0&order=ASC&orderby=name&q=defaultproject"
  insecure = local.insecure
  request_headers = {
    "X-RAFAY-API-KEYID" = "${local.api_key}"
    Accept              = "application/json"
  }
}

locals {
  response_data             = jsondecode(data.http.get_org.response_body)
  org_hash                  = local.response_data.results[0].organization_id
  ingress_sub_domain        = "${var.name}-${local.org_hash}"
  rafay_ingress_domain_fqdn = var.ingress_domain_type == "Rafay" ? "${local.ingress_sub_domain}.${var.ingress_domain}" : var.ingress_custom_domain
  ingress_domain_name       = var.ingress_domain_type == "Rafay" ? local.rafay_ingress_domain_fqdn : var.ingress_custom_domain
  create_tls_secret         = var.ingress_domain_type == "Rafay" ? true : false
}


resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
  }
}
resource "kubernetes_secret" "hf_token" {
  metadata {
    name      = "hf-token"
    namespace = var.namespace
  }

  data = {
    token = local.hf_token
  }
}


resource "random_uuid" "test" {
}

resource "kubernetes_persistent_volume_claim" "pvc" {
  metadata {
    name      = "${var.name}-llm-pvc"
    namespace = resource.kubernetes_namespace.namespace.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.storage_size
      }
    }
    volume_mode        = var.volume_mode
    storage_class_name = try(var.storage_class, null)
  }
  wait_until_bound = false
}

resource "kubernetes_config_map" "chat_template" {
  metadata {
    name      = "${var.name}-chat-template"
    namespace = resource.kubernetes_namespace.namespace.metadata[0].name
  }

  data = {
    "template_llava.jinja" = "${file("template_llava.jinja")}"
  }

}

resource "kubernetes_deployment" "deployment" {
  depends_on = [kubernetes_secret.hf_token]
  metadata {
    name      = "${var.name}-llm-deployment"
    namespace = resource.kubernetes_namespace.namespace.metadata[0].name
    labels = {
      app = "${var.name}-llm"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "${var.name}-llm"
      }
    }
    template {
      metadata {
        labels = {
          app = "${var.name}-llm"
        }
      }
      spec {
        container {
          name    = "${var.name}-llm"
          image   = var.image
          command = ["/bin/sh", "-c"]
          args    = ["vllm serve ${var.model} --trust-remote-code --enable-chunked-prefill --max_num_batched_tokens 1024 --chat-template /tmp/template_llava.jinja --api-key ${random_uuid.test.result} --dtype=half"]
          env {
            name = "HUGGING_FACE_HUB_TOKEN"
            value_from {
              secret_key_ref {
                name = "hf-token"
                key  = "token"
              }
            }
          }
          resources {
            limits = {
              cpu                       = var.cpu_limits
              memory                    = var.memory_limits
              "${var.gpu_type}.com/gpu" = var.gpu_limits
            }
            requests = {
              cpu                       = var.cpu_requests
              memory                    = var.memory_requests
              "${var.gpu_type}.com/gpu" = var.gpu_requests
            }
          }
          port {
            container_port = 8000
          }
          volume_mount {
            mount_path = "/root/.cache/huggingface"
            name       = "cache-volume"
          }
          volume_mount {
            mount_path = "/dev/shm"
            name       = "shm"
          }
          volume_mount {
            mount_path = "/tmp/template_llava.jinja"
            name       = "chat-template-test"
            sub_path   = "template_llava.jinja"
          }
          readiness_probe {
            http_get {
              port = 8000
              path = "/health"
            }
            initial_delay_seconds = 60
            period_seconds        = 10
          }
        }
        volume {
          name = "cache-volume"
          persistent_volume_claim {
            claim_name = resource.kubernetes_persistent_volume_claim.pvc.metadata[0].name
          }
        }
        volume {
          name = "shm"
          empty_dir {
            medium     = "Memory"
            size_limit = "2Gi"
          }
        }
        volume {
          name = "chat-template-test"
          config_map {
            default_mode = "0644"
            name         = resource.kubernetes_config_map.chat_template.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "service" {
  metadata {
    name      = "${var.name}-llm-svc"
    namespace = resource.kubernetes_namespace.namespace.metadata[0].name
  }
  spec {
    port {
      name        = "${var.name}-llm-http"
      port        = 8000
      protocol    = "TCP"
      target_port = 8000
    }
    selector = {
      app = "${var.name}-llm"
    }
    type = "ClusterIP"

  }
}

locals {
  llm_crt           = var.ingress_domain_type == "Rafay" ? var.tls_crt : var.host_crt
  llm_key           = var.ingress_domain_type == "Rafay" ? var.tls_key : var.host_key
  local_secret_name = "${var.name}-llm-tls-secret"
}
resource "kubernetes_secret" "tls_secret" {

  metadata {
    name      = local.create_tls_secret ? "${local.local_secret_name}" : var.custom_secret_name
    namespace = resource.kubernetes_namespace.namespace.metadata[0].name
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = local.llm_crt
    "tls.key" = local.llm_key
  }
}

resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name        = "${var.namespace}-ingress"
    namespace   = resource.kubernetes_namespace.namespace.metadata[0].name
    annotations = var.ingress_annotations
  }
  spec {
    tls {
      hosts       = ["${local.ingress_domain_name}"]
      secret_name = kubernetes_secret.tls_secret.metadata[0].name
    }
    rule {
      host = local.ingress_domain_name
      http {
        path {
          path = "/"
          backend {
            service {
              name = resource.kubernetes_service.service.metadata[0].name
              port {
                number = 8000
              }
            }
          }
        }
      }
    }

  }
}




