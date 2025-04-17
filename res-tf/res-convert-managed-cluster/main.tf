resource "null_resource" "convert2managed_selected_cluster" {
  triggers = {
    name            = var.cluster_name
    project         = var.project_name
    credential      = var.cloud_credential
    resource_group  = var.resource_group
    region          = var.region
    cluster_type    = var.cluster_type
    retry   = var.rerun_trigger
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "chmod +x ./convert2managed.sh; ./convert2managed.sh"
    environment = {
      CLUSTER_NAME      = "${var.cluster_name}"
      PROJECT_NAME      = "${var.project_name}"
      REGION    = "${var.region}"
      CLOUD_CREDENTIAL = "${var.cloud_credential}"
      CLUSTER_TYPEP = "${var.cluster_type}"
      RESOURCE_GROUP = "${var.resource_group}"
    }
  }
}
