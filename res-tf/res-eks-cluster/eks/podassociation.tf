module "eks-pod-identity" {
    source = "./modules/eks-pod-identity"
    for_each = { for k, v in var.pod_identity_association : k => v  }

    cluster_name = time_sleep.this[0].triggers["cluster_name"]
    tags = var.tags
    name = each.key
    trust_policy_conditions = try(each.value.trust_policy_conditions, var.trust_policy_conditions,[])
    trust_policy_statements = try(each.value.trust_policy_statements, var.trust_policy_statements,[])
    permissions_boundary_arn = try(each.value.permissions_boundary_arn, var.permissions_boundary_arn,null)
    additional_policy_arns = try(each.value.additional_policy_arns, var.additional_policy_arns,{})
    source_policy_documents = try(each.value.source_policy_documents, var.source_policy_documents,[])
    attach_custom_policy = try(each.value.attach_custom_policy, var.attach_custom_policy,false)
    custom_policy_description = try(each.value.custom_policy_description, var.custom_policy_description,"Custom IAM Policy")
    override_policy_documents = try(each.value.override_policy_documents, var.override_policy_documents,[])
    policy_statements = try(each.value.policy_statements, var.policy_statements,[])
    associations = try(each.value.associations, var.associations,{})
    
    depends_on = [module.eks_managed_node_group, module.self_managed_node_group]

}