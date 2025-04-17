################################################################################
# Cluster
################################################################################

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "region" {
  description = "The region in which the EKS cluster was created"
  value       = "${var.region}"
}

output "cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = module.eks.cluster_platform_version
}

output "node_group_names" {
  description = "The name of the EKS managed node group"
  value       = module.eks.eks_managed_node_group
}

output "self_managed_node_group_names" {
  description = "The names of the self-managed EKS node groups"
  value       = module.eks.self_managed_node_group
}

output "kubeconfig" {
  description = "Kubeconfig file content for the EKS cluster"
  value       = <<EOT
apiVersion: v1
clusters:
- cluster:
    server: "${module.eks.cluster_endpoint}"
    certificate-authority-data: "${module.eks.cluster_certificate_authority_data}"
  name: "${module.eks.cluster_arn}"
contexts:
- context:
    cluster: "${module.eks.cluster_arn}"
    user: "${module.eks.cluster_arn}"
  name: "${module.eks.cluster_arn}"
current-context: "${module.eks.cluster_arn}"
kind: Config
preferences: {}
users:
- name: "${module.eks.cluster_arn}"
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
      - --region
      - ${var.region}
      - eks
      - get-token
      - --cluster-name
      - ${var.cluster_name}
      - --output
      - json
EOT
}
