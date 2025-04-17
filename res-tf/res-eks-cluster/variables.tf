variable "region" {
  description = "The region of the EKS cluster"
  type        = string
  default     = "us-west-2"
}

################################################################################
# Cluster
################################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.32`)"
  type        = string
  default     = "1.32"
}

variable "managed_by" {
  description = "Enter the key for 'modified by' tag"
  type        = string
  default     = "Rafay"
}

variable "cluster_enabled_log_types" {
  description = "A list of the desired control plane logs to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)"
  type        = list(string)
  default     = ["audit", "api", "authenticator"]
}

variable "authentication_mode" {
  description = "The authentication mode for the cluster. Valid values are `CONFIG_MAP`, `API` or `API_AND_CONFIG_MAP`"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "cluster_upgrade_policy" {
  description = "Configuration block for the cluster upgrade policy"
  type        = any
  default     = {}
}

variable "cluster_remote_network_config" {
  description = "Configuration block for the cluster remote network configuration"
  type        = any
  default     = {}
}

variable "cluster_zonal_shift_config" {
  description = "Configuration block for the cluster zonal shift"
  type        = any
  default     = {}
}

variable "cluster_additional_security_group_ids" {
  description = "List of additional, externally created security group IDs to attach to the cluster control plane"
  type        = list(string)
  default     = []
}

variable "cluster_security_group_additional_rules" {
  description = "List of additional cluster security rules"
  type = any
  default     = {}
}
variable "node_security_group_additional_rules" {
  description = "List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source"
  type        = any
  default     = {}
}
variable "control_plane_subnet_ids" {
  description = "A list of subnet IDs where the EKS cluster control plane (ENIs) will be provisioned. Used for expanding the pool of subnets used by nodes/node groups without replacing the EKS control plane"
  type        = list(string)
  default     = []
}


variable "subnet_ids" {
  description = "List of subnet IDs where EKS cluster nodes will be deployed. Leave empty to auto-create."
  type        = list(string)
  default     = []
} 

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_ip_family" {
  description = "The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6`. You can only specify an IP family when you create a cluster, changing this value will force a new cluster to be created"
  type        = string
  default     = "ipv4"
}

variable "cluster_service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes service IP addresses from. If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks"
  type        = string
  default     = null
}

variable "outpost_config" {
  description = "Configuration for the AWS Outpost to provision the cluster on"
  type        = any
  default     = {}
}

variable "cluster_encryption_config" {
  description = "Configuration block with encryption configuration for the cluster. To disable secret encryption, set this value to `{}`"
  type        = any
  default = {
    resources = ["secrets"]
  }
}

variable "attach_cluster_encryption_policy" {
  description = "Indicates whether or not to attach an additional policy for the cluster IAM role to utilize the encryption key provided"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "cluster_timeouts" {
  description = "Create, update, and delete timeout configurations for the cluster"
  type        = map(string)
  default     = {}
}

################################################################################
# Access Entry
################################################################################

variable "access_entries" {
  description = "Map of access entries to add to the cluster"
  type        = any
  default     = {}
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Indicates whether or not to add the cluster creator (the identity used by Terraform) as an administrator via access entry"
  type        = bool
  default     = false
}
################################################################################
# KMS Key
################################################################################

variable "create_kms_key" {
  description = "Controls if a KMS key for cluster encryption should be created"
  type        = bool
  default     = true
}

variable "kms_key_deletion_window_in_days" {
  description = "The waiting period, specified in number of days. After the waiting period ends, AWS KMS deletes the KMS key. If you specify a value, it must be between `7` and `30`, inclusive. If you do not specify a value, it defaults to `30`"
  type        = number
  default     = null
}

variable "enable_kms_key_rotation" {
  description = "Specifies whether key rotation is enabled"
  type        = bool
  default     = true
}

variable "kms_key_enable_default_policy" {
  description = "Specifies whether to enable the default key policy"
  type        = bool
  default     = true
}

################################################################################
# CloudWatch Log Group
################################################################################

variable "create_cloudwatch_log_group" {
  description = "Determines whether a log group is created by this module for the cluster logs. If not, AWS will automatically create one if logging is enabled"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events. Default retention - 90 days"
  type        = number
  default     = 90
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "If a KMS Key ARN is set, this key will be used to encrypt the corresponding log group. Please be sure that the KMS Key has an appropriate key policy (https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html)"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_class" {
  description = "Specified the log class of the log group. Possible values are: `STANDARD` or `INFREQUENT_ACCESS`"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_tags" {
  description = "A map of additional tags to add to the cloudwatch log group created"
  type        = map(string)
  default     = {}
}

################################################################################
# Cluster Security Group
################################################################################

variable "create_cluster_security_group" {
  description = "Determines if a security group is created for the cluster. Note: the EKS service creates a primary security group for the cluster by default"
  type        = bool
  default     = true
}

variable "cluster_security_group_id" {
  description = "Existing security group ID to be attached to the cluster"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "ID of the VPC where EKS cluster will be deployed. Leave empty to auto-create."
  type        = string
  default     = ""
}

################################################################################
# EKS Addons
################################################################################

variable "cluster_addons" {
  description = "A map of the EKS addons to be enabled."
  type = any
  default = {}
}

################################################################################
# Node Group
################################################################################

variable "node_group_management" {
  description = "The type of node group management i.e self-managed/eks-managed"
  type        = string
  default     = "self-managed"
}


################################################################################
# Self Managed Node Group
################################################################################

variable "self_managed_node_groups_info" {
  description = "Map of EKS managed node group configurations"
  type = any
  default = {
    "default-node-group" = {
      ami_type       = "AL2_x86_64"
      instance_type = "t3.medium"
      min_size      = 1
      max_size      = 3
      desired_size  = 2
    }
  }
}


################################################################################
# EKS Managed Node Group
################################################################################

variable "eks_managed_node_groups_info" {
  description = "Map of EKS managed node group configurations"
  type = any
  default = {
    "default-node-group" = {
      ami_type       = "AL2_x86_64"
      instance_types = ["t3.medium"]
      min_size      = 1
      max_size      = 3
      desired_size  = 2
    }
  }
}

################################################################################
# Roles
################################################################################

variable "cluster_iam_role_arn" {
  description = "IAM Role ARN for the EKS cluster. Leave empty to auto-create."
  type        = string
  default     = ""
}

variable "node_iam_role_arn" {
  description = "IAM Role ARN for the EKS node role. Leave empty to auto-create."
  type        = string
  default     = ""
}

################################################################################
# Pod Identity
################################################################################

variable "pod_identity_association" {
  description = "Pod association if needed"
  type        = any
  default     = {
    "podassociation1" = {
      trust_policy_conditions = []
      trust_policy_statements = []
      permissions_boundary_arn = null
      additional_policy_arns = {}
      source_policy_documents = []
      attach_custom_policy = false
      custom_policy_description = ""
      override_policy_documents = []
      policy_statements = []
      associations = {}
    }
  }
}

