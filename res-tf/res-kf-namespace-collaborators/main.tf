locals {
  namespace_name = "${var.kubeflow_namespace_name}"
}


# Apply a RoleBinding to add collaborators to the target namespace
resource "kubernetes_manifest" "namespace_collaborators_rolebinding_editors" {


  for_each = toset(var.kubeflow_collaborator_editors)

  manifest = yamldecode(templatefile("charts/templates/RoleBinding/profiles-namespace-collaborators-RoleBinding.yaml", {
      kubeflow_namespace_name          = local.namespace_name
      kubeflow_collaborator_role       = "edit"
      kubeflow_raw_collaborator_email  = each.value
      kubeflow_safe_collaborator_email = lower(replace(replace(replace(each.value, ".", "-"), "_", "-"), "@", "-"))}
    )
  )
}


# Apply a RoleBinding to add collaborators to the target namespace
resource "kubernetes_manifest" "namespace_collaborators_rolebinding_viewers" {

  for_each = toset(var.kubeflow_collaborator_viewers)

  manifest = yamldecode(templatefile("charts/templates/RoleBinding/profiles-namespace-collaborators-RoleBinding.yaml", {
      kubeflow_namespace_name          = local.namespace_name
      kubeflow_collaborator_role       = "view"
      kubeflow_raw_collaborator_email  = each.value
      kubeflow_safe_collaborator_email = lower(replace(replace(replace(each.value, ".", "-"), "_", "-"), "@", "-"))}
    )
  )
}


# Apply an AuthorizationPolicy to allow collaborators to access the target namespace
resource "kubernetes_manifest" "namespace_collaborators_authpolicy_editors" {
  depends_on = [ kubernetes_manifest.namespace_collaborators_rolebinding_editors ]

  for_each = toset(var.kubeflow_collaborator_editors)

  manifest = yamldecode(templatefile("charts/templates/AuthorizationPolicy/profiles-namespace-collaborators-AuthorizationPolicy.yaml", {
      kubeflow_namespace_name          = local.namespace_name
      kubeflow_collaborator_role       = "edit"
      kubeflow_raw_collaborator_email  = each.value
      kubeflow_safe_collaborator_email = lower(replace(replace(replace(each.value, ".", "-"), "_", "-"), "@", "-"))
      }
    )
  )
}


# Apply an AuthorizationPolicy to allow collaborators to access the target namespace
resource "kubernetes_manifest" "namespace_collaborators_authpolicy_viewers" {
  depends_on = [ kubernetes_manifest.namespace_collaborators_rolebinding_viewers]

  for_each = toset(var.kubeflow_collaborator_viewers)

  manifest = yamldecode(templatefile("charts/templates/AuthorizationPolicy/profiles-namespace-collaborators-AuthorizationPolicy.yaml", {
      kubeflow_namespace_name          = local.namespace_name
      kubeflow_collaborator_role       = "view"
      kubeflow_raw_collaborator_email  = each.value
      kubeflow_safe_collaborator_email = lower(replace(replace(replace(each.value, ".", "-"), "_", "-"), "@", "-"))
      }
    )
  )
}
