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

data "aws_availability_zones" "available" {
  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  name = "ex-${basename(path.cwd)}"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Test       = local.name
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags

  # Only create the VPC if not provided externally
  count = var.vpc_id == "" ? 1 : 0
}

module "eks" {
  source = "./eks/" # Your EKS module location

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  cluster_compute_config = {
    enabled    = var.cluster_compute_enabled
    node_pools = ["general-purpose"]
  }

  # Use provided VPC/Subnets or fall back to created ones
  vpc_id     = var.vpc_id != "" ? var.vpc_id : module.vpc[0].vpc_id
  subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : module.vpc[0].private_subnets

  tags = var.tags

  # IAM Roles
  cluster_iam_role_arn = var.cluster_iam_role_arn
  node_iam_role_arn    = var.node_iam_role_arn
}