output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks_node_groups.cluster_name
}

output "region" {
  description = "The region in which the EKS cluster was created"
  value       = "${var.region}"
}

output "kubernetes_version" {
  description = "The Kubernetes version of the EKS cluster"
  value       = module.eks_node_groups.cluster_version
}

output "node_group_names" {
  description = "The name of the EKS managed node group"
  # value       = keys(var.eks_managed_node_groups_info)
  value       = var.node_group_management == "self-managed" ? [] : keys(var.eks_managed_node_groups_info)
}

output "self_managed_node_group_names" {
  description = "The names of the self-managed EKS node groups"
  value       = var.node_group_management == "eks-managed" ? [] : keys(var.self_managed_node_groups_info)
}



