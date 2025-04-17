

resource "rafay_import_cluster" "import_vcluster" {
  clustername           = var.vcluster_name
  projectname           = var.project
  blueprint             = var.blueprint
  blueprint_version     = var.blueprint_version
  values_path           = "/tmp/test/impvalues.yaml"
  kubernetes_provider   = "OTHER"
  provision_environment = "CLOUD"
}
