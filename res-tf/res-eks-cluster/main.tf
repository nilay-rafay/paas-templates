# AWS Authentication Configuration
data "external" "aws_auth" {
  program = ["bash", "-c", <<-EOF
    cat <<JSON
    {
      "access_key": "$AWS_ACCESS_KEY_ID",
      "secret_key": "$AWS_SECRET_ACCESS_KEY",
      "role_arn": "$AWS_ROLE_ARN",
      "profile": "$AWS_PROFILE",
      "web_identity_token_file": "$AWS_WEB_IDENTITY_TOKEN_FILE",
      "shared_config_file": "$AWS_CONFIG_FILE",
      "shared_credentials_file": "$AWS_SHARED_CREDENTIALS_FILE"
    }
JSON
  EOF
  ]
}

# AWS Provider Configuration
provider "aws" {
  region                   = var.region
  access_key              = try(data.external.aws_auth.result.access_key, null)
  secret_key              = try(data.external.aws_auth.result.secret_key, null)
  profile                 = try(data.external.aws_auth.result.profile, null)
  shared_config_files     = try(coalesce(data.external.aws_auth.result.shared_config_file), "") != "" ? [data.external.aws_auth.result.shared_config_file] : null
  shared_credentials_files = try(coalesce(data.external.aws_auth.result.shared_credentials_file), "") != "" ? [data.external.aws_auth.result.shared_credentials_file] : null

  dynamic "assume_role" {
    for_each = try(coalesce(data.external.aws_auth.result.role_arn), "") != "" ? [1] : []
    content {
      role_arn = data.external.aws_auth.result.role_arn
    }
  }

  dynamic "assume_role_with_web_identity" {
    for_each = try(coalesce(data.external.aws_auth.result.web_identity_token_file), "") != "" ? [1] : []
    content {
      role_arn                = data.external.aws_auth.result.role_arn
      web_identity_token_file = data.external.aws_auth.result.web_identity_token_file
    }
  }
}

# Availability Zones Data Source
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Common Locals
locals {
  name     = "${var.cluster_name}-vpc"
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  # Common tags
  common_tags = merge(
    var.tags,
    {
      ManagedBy    = var.managed_by
      ClusterName  = var.cluster_name
    }
  )
}

# VPC Module
module "vpc" {
  source              = "terraform-aws-modules/vpc/aws"
  version             = "~> 5.0"
  count               = var.vpc_id == "" ? 1 : 0

  name                = local.name
  cidr                = local.vpc_cidr

  azs                 = local.azs
  private_subnets     = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets      = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  intra_subnets       = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

  enable_nat_gateway  = true
  single_nat_gateway  = true

  public_subnet_tags  = {
    "kubernetes.io/role/elb" = 1
     "auto-assign-public-ip"  = "true"
     "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  tags                = local.common_tags
  map_public_ip_on_launch = true
}

# Tag custom subnets
resource "aws_ec2_tag" "tag_subnets" {
  for_each = { for idx, subnet_id in concat(var.control_plane_subnet_ids, var.subnet_ids) : idx => subnet_id }

  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
  
  depends_on = [
    module.vpc
  ]
}

locals {
  # Determine which node groups info to check based on management type

  check_eks_managed = var.node_group_management == "eks-managed" || var.node_group_management == "mixed"
  check_self_managed = var.node_group_management == "self-managed" || var.node_group_management == "mixed"
  eks_managed_node_groups  =  var.eks_managed_node_groups_info
  self_managed_node_groups =  var.self_managed_node_groups_info 

  # Check if any node group has subnet_ids defined

  node_group_has_subnets = (
    (local.check_eks_managed && length(flatten([
      for ng in values(var.eks_managed_node_groups_info) : 
      try(ng.subnet_ids, [])
    ])) > 0) ||
    (local.check_self_managed && length(flatten([
      for ng in values(var.self_managed_node_groups_info) : 
      try(ng.subnet_ids, [])
    ])) > 0)
  )
}

module "eks_node_groups" {
  source = "./eks/"

  # Cluster 
  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version
  cluster_enabled_log_types                = var.cluster_enabled_log_types
  authentication_mode                      = var.authentication_mode
  cluster_upgrade_policy                   = var.cluster_upgrade_policy
  cluster_remote_network_config            = var.cluster_remote_network_config
  cluster_zonal_shift_config               = var.cluster_zonal_shift_config
  cluster_additional_security_group_ids    = var.cluster_additional_security_group_ids
  cluster_security_group_additional_rules  = var.cluster_security_group_additional_rules
  control_plane_subnet_ids                 = length(var.control_plane_subnet_ids) > 0 ? var.control_plane_subnet_ids : (var.vpc_id != "" ? var.subnet_ids : concat(module.vpc[0].private_subnets, module.vpc[0].public_subnets, module.vpc[0].intra_subnets))
  subnet_ids                               = length(var.subnet_ids) > 0 ? var.subnet_ids : (var.vpc_id != "" ? var.subnet_ids : module.vpc[0].public_subnets)
  cluster_endpoint_private_access          = var.cluster_endpoint_private_access
  cluster_endpoint_public_access           = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  cluster_ip_family                        = var.cluster_ip_family
  cluster_service_ipv4_cidr                = var.cluster_service_ipv4_cidr
  outpost_config                           = var.outpost_config
  cluster_encryption_config                = var.cluster_encryption_config
  attach_cluster_encryption_policy         = var.attach_cluster_encryption_policy
  cluster_timeouts                         = var.cluster_timeouts 

  #Access Entry
  access_entries                           = var.access_entries
  enable_cluster_creator_admin_permissions = var.authentication_mode == "CONFIG_MAP" ? false : var.enable_cluster_creator_admin_permissions
  
  #CloudWatch Log Group
  create_cloudwatch_log_group              = var.create_cloudwatch_log_group
  cloudwatch_log_group_retention_in_days   = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id          = var.cloudwatch_log_group_kms_key_id
  cloudwatch_log_group_class               = var.cloudwatch_log_group_class
  cloudwatch_log_group_tags                = var.cloudwatch_log_group_tags

  # Cluster Security Group
  create_cluster_security_group            = var.create_cluster_security_group
  cluster_security_group_id                = var.cluster_security_group_id
  vpc_id                                   = var.vpc_id != "" ? var.vpc_id : module.vpc[0].vpc_id
  

  # EKS Addons
  cluster_addons                           = var.cluster_addons

  #KMS Key
  create_kms_key                           = var.create_kms_key
  kms_key_deletion_window_in_days          = var.kms_key_deletion_window_in_days
  enable_kms_key_rotation                  = var.enable_kms_key_rotation
  kms_key_enable_default_policy            = var.kms_key_enable_default_policy

  # Node Group 
  # eks_managed_node_groups                  = var.node_group_management == "eks-managed" || var.node_group_management == "mixed" ? var.eks_managed_node_groups_info : {}
  # self_managed_node_groups                 = var.node_group_management == "self-managed" || var.node_group_management == "mixed" ? var.self_managed_node_groups_info : {}
  eks_managed_node_groups                  = local.eks_managed_node_groups
  self_managed_node_groups                 = local.self_managed_node_groups
  # Roles
  cluster_iam_role_arn                     = var.cluster_iam_role_arn
  node_iam_role_arn                        = var.node_iam_role_arn
  node_security_group_additional_rules     = var.node_security_group_additional_rules
  # Tags
  tags                                     = local.common_tags
  #pod identity association
  pod_identity_association                 = var.pod_identity_association

  region                                   = var.region
}
