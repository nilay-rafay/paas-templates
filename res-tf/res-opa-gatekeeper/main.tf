
data "rafay_download_kubeconfig" "kubeconfig_cluster" {
  cluster = var.cluster_name
}

data "external" "env" {
  program = ["sh", "-c", "echo '{\"value\": \"'\"$RCTL_REST_ENDPOINT\"'\"}'"]
}

locals {
  kubeconfig_data = yamldecode(data.rafay_download_kubeconfig.kubeconfig_cluster.kubeconfig)

  k8s_host                   = local.kubeconfig_data.clusters[0].cluster.server
  k8s_client_certificate     = base64decode(local.kubeconfig_data.users[0].user.client-certificate-data)
  k8s_client_key             = base64decode(local.kubeconfig_data.users[0].user.client-key-data)
  k8s_cluster_ca_certificate = base64decode(local.kubeconfig_data.clusters[0].cluster.certificate-authority-data)

  yaml_constraints = var.enable_opa_gatekeeper ? split("---", var.constraints_yaml) : []
  yaml_templates = var.enable_opa_gatekeeper ? split("---", var.templates_yaml) : []

  endpoint = data.external.env.result.value
  # Use regex to extract the part after "console-" and before ".dev"
  extracted_value = local.endpoint == "qc-console.stage.rafay.dev" ? "" : length(regex("console-([a-zA-Z0-9-]+)\\.dev", local.endpoint)) > 0 ? regex("console-([a-zA-Z0-9-]+)\\.dev", local.endpoint)[0] : ""
  # Check if the endpoint is exactly equal to one of the specified values
  fluentd_aggr_fqdn = local.endpoint == "qc-console.stage.rafay.dev"   ? "qc-fluentd-aggr.stage.rafay-edge.net" : local.endpoint == "console.stage.rafay.dev" ? "fluentd-aggr.stage.rafay-edge.net" : local.endpoint == "console.rafay.dev" ? "fluentd-aggr.rafay-edge.net" : "fluentd-aggr-${local.extracted_value}.dev.rafay-edge.net"
}

resource "helm_release" "opa-gatekeeper" {
  depends_on = [ local.kubeconfig_data ]
  count =  var.enable_opa_gatekeeper ? 1 : 0
  name       = "opa-gatekeeper"
  chart      = "charts/3.16.3"
  verify     = false
  namespace = "gatekeeper-system"
  values = [templatefile("${path.module}/templates/opa-values.yaml.tftpl", {
    registry_fqdn = "registry.dev.rafay-edge.net"
    fluentd_aggr_fqdn = local.fluentd_aggr_fqdn
    podLabels = var.pod_labels
    excludedNamespaces = jsonencode(var.opa_excluded_namespaces)
  })]
  create_namespace = true
}

resource "kubectl_manifest" "opa_policy_templates" {
  depends_on = [helm_release.opa-gatekeeper]
  for_each = var.enable_opa_gatekeeper  ? { for idx, template in local.yaml_templates : idx => template } : {}
  yaml_body = each.value
  wait = true
}

resource "kubectl_manifest" "opa_policy_constraints" {
  depends_on = [kubectl_manifest.opa_policy_templates]
  for_each = var.enable_opa_gatekeeper ? { for idx, constraint in local.yaml_constraints : idx => constraint } : {}
  yaml_body = each.value
  wait = true
}
