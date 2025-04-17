output "resource_group_name" {
  description = "AKS Resource Group"
  value       = azurerm_kubernetes_cluster.aks.resource_group_name
}

output "cluster_name" {
  description = "AKS Cluster Name"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "location" {
  description = "AKS Cluster Location"
  value       = azurerm_kubernetes_cluster.aks.location
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "workload_identity_client_ids" {
  description = "The client IDs of the created managed identities to use for the annotation 'azure.workload.identity/client-id' on your service accounts"
  value       = var.workload_identity_enabled ? { for identity in azurerm_user_assigned_identity.workload_identity : identity.name => identity.client_id } : {}
}

output "kubelet_identity" {
  description = "The kubelet identity configuration"
  value       = var.kubelet_identity
}
