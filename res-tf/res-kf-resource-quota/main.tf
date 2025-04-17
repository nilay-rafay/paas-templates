# Apply a resource quota to the target namespace
resource "kubernetes_manifest" "namespace_resource_quota_profile" {

  # TODO: find out if this creates separate yaml files
  manifest = yamldecode(templatefile("charts/templates/Profile/profiles-resource-quota-Profile.yaml", {
      kubeflow_namespace_name     = "${var.kubeflow_namespace_name}"
      kubeflow_user_email         = "${var.kubeflow_user_email}"
      kubeflow_requests_cpu       = var.kubeflow_requests_cpu
      kubeflow_requests_memory    = var.kubeflow_requests_memory
      kubeflow_requests_storage   = var.kubeflow_requests_storage
      kubeflow_limit_cpu          = var.kubeflow_limit_cpu
      kubeflow_limit_memory       = var.kubeflow_limit_memory
      kubeflow_ephemeral_storage  = var.kubeflow_ephemeral_storage 
      }
    )
  )
}
