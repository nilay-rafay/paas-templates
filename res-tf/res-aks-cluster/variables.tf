variable "resource_group" {
  type        = string
  description = "The resource group name"
  validation {
    condition     = length(var.resource_group) > 0
    error_message = "The resource group name must not be empty."
  }
  default = "dev-rg-ci"
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster (required)"
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "The cluster name must not be empty."
  }
  default = "dev-caas-1"
}

variable "location" {
  type        = string
  description = "The location of the cluster (required)"
  validation {
    condition     = length(var.location) > 0
    error_message = "The location must not be empty."
  }
  default = "centralindia"
}

variable "kubernetes_version" {
  type        = string
  description = "The Kubernetes version of the cluster"
  #   validation {
  #     condition     = contains(["1.29.2", "1.29.4", "1.29.5", "1.29.6", "1.29.7", "1.29.8", "1.29.9", "1.29.10", "1.29.11", "1.30.0", "1.30.1", "1.30.2", "1.30.3", "1.30.4", "1.30.5", "1.30.6", "1.30.7"], var.kubernetes_version)
  #     error_message = "The Kubernetes version must be one of '1.29.2', '1.29.4', '1.29.5', '1.29.6', '1.29.7', '1.29.8', '1.29.9', '1.29.10', '1.29.11', '1.30.0', '1.30.1', '1.30.2', '1.30.3', '1.30.4', '1.30.5', '1.30.6', '1.30.7'."
  #   }
  default = "1.30"
}

variable "cluster_tags" {
  type = map(string)
  default = {
    environment = "dev"
    email       = "cloudengg@rafay.co"
  }
}

variable "aks_pricing_tier" {
  type        = string
  description = "AKS pricing tier"
  default     = "Free"
  validation {
    condition     = length(var.aks_pricing_tier) > 0
    error_message = "The AKS pricing tier must not be empty."
  }
}

variable "identity_type" {
  type        = string
  description = "The type of identity to use for the AKS cluster. Possible values are 'SystemAssigned' and 'UserAssigned'."
  default     = "SystemAssigned"
  validation {
    condition     = contains(["SystemAssigned", "UserAssigned"], var.identity_type)
    error_message = "The identity_type must be one of 'SystemAssigned' or 'UserAssigned'."
  }
}

variable "user_managed_identities" {
  type        = list(string)
  description = "List of User Managed Identity IDs for the cluster. Required if identity_type is 'UserAssigned'."
  default     = []
}

variable "automatic_upgrade_channel" {
  type        = string
  description = "The upgrade channel for automatic upgrades"
  default     = "none"
  validation {
    condition     = contains(["none", "patch", "rapid", "node-image", "stable"], var.automatic_upgrade_channel)
    error_message = "The automatic_upgrade_channel must be one of 'none', 'patch', 'rapid', 'node-image', or 'stable'."
  }
}

variable "network_plugin" {
  type        = string
  description = "Network plugin to use for networking"
  default     = "azure"
}

variable "network_policy" {
  type        = string
  description = "Network policy to use for networking"
  default     = "azure"
  validation {
    condition     = contains(["azure", "calico", "cilium"], var.network_policy)
    error_message = "The network_policy must be one of 'azure', 'calico', or 'cilium'."
  }
}

variable "network_plugin_mode" {
  type        = string
  description = "Network plugin mode to use for networking"
  default     = "overlay"
}

variable "private_cluster_enabled" {
  type        = bool
  description = "Enable private cluster"
  default     = false
}

variable "private_cluster_public_fqdn_enabled" {
  type        = bool
  description = "Enable private cluster public FQDN"
  default     = false
  #   validation {
  #     condition     = var.private_cluster_enabled == false || var.private_cluster_public_fqdn_enabled == false
  #     error_message = "private_cluster_public_fqdn_enabled is applicable only when private_cluster_enabled is true."
  #   }
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS zone"
  default     = ""
}

variable "http_application_routing_enabled" {
  type        = bool
  description = "Should HTTP Application Routing be enabled?"
  default     = false
}

variable "azure_policy_enabled" {
  type        = bool
  description = "Should Azure Policy be enabled?"
  default     = false
}

variable "oidc_issuer_enabled" {
  type        = bool
  description = "Should OIDC issuer be enabled?"
  default     = true
}

variable "default_node_pool" {
  type = object({
    name                   = optional(string)
    node_count             = optional(number)
    vm_size                = optional(string)
    max_pods               = optional(number)
    availability_zones     = optional(list(string))
    node_public_ip_enabled = optional(bool)
    vnet_subnet_id         = optional(string)
    pod_subnet_id          = optional(string)
    os_sku                 = optional(string)
    snapshot_id            = optional(string)
    upgrade_settings = optional(object({
      drain_timeout_in_minutes      = optional(number)
      max_surge                     = optional(string)
      node_soak_duration_in_minutes = optional(number)
    }))
    # mode                     = optional(string) # Is not supported for default nodepools
  })
  description = "Configuration for the default node pool"
  default = {
    name                   = "default"
    node_count             = 1
    vm_size                = "Standard_DS2_v2"
    max_pods               = 30
    availability_zones     = ["1", "2", "3"]
    node_public_ip_enabled = false
    vnet_subnet_id         = ""
    pod_subnet_id          = ""
    os_sku                 = "Ubuntu"
    snapshot_id            = ""
    upgrade_settings = {
      drain_timeout_in_minutes      = 30
      max_surge                     = "33%"
      node_soak_duration_in_minutes = 0
    }
  }
}

variable "node_pools" {
  type = map(object({
    min_count              = optional(number)
    max_count              = optional(number)
    node_count             = optional(number)
    auto_scaling_enabled   = optional(bool)
    vm_size                = optional(string)
    max_pods               = optional(number)
    availability_zones     = optional(list(string))
    node_public_ip_enabled = optional(bool)
    vnet_subnet_id         = optional(string)
    pod_subnet_id          = optional(string)
    os_sku                 = optional(string)
    snapshot_id            = optional(string)
    mode                   = optional(string)
    kubelet_config_enabled = optional(bool)
    kubelet_config = optional(object({
      cpu_manager_policy        = optional(string)
      cpu_cfs_quota_enabled     = optional(bool)
      cpu_cfs_quota_period      = optional(string)
      image_gc_high_threshold   = optional(number)
      image_gc_low_threshold    = optional(number)
      topology_manager_policy   = optional(string)
      allowed_unsafe_sysctls    = optional(list(string))
      container_log_max_line    = optional(number)
      container_log_max_size_mb = optional(number)
      pod_max_pid               = optional(number)
    }))
  }))
  description = "Map of maps containing node pools"
  default = {
    p1 = {
      min_count              = 2
      max_count              = 2
      node_count             = 2
      auto_scaling_enabled   = true
      vm_size                = "Standard_B4ms"
      max_pods               = 110
      availability_zones     = ["1", "2", "3"]
      node_public_ip_enabled = false
      vnet_subnet_id         = ""
      pod_subnet_id          = ""
      os_sku                 = "Ubuntu"
      snapshot_id            = ""
      mode                   = "User"
      kubelet_config_enabled = false
      kubelet_config = {
        cpu_manager_policy        = "static"
        cpu_cfs_quota_enabled     = true
        cpu_cfs_quota_period      = "100ms"
        image_gc_high_threshold   = 85
        image_gc_low_threshold    = 80
        topology_manager_policy   = "best-effort"
        allowed_unsafe_sysctls    = []
        container_log_max_line    = 10
        container_log_max_size_mb = 10
        pod_max_pid               = 100
      }
    },
    p2 = {
      min_count              = 2
      max_count              = 2
      node_count             = 2
      auto_scaling_enabled   = true
      vm_size                = "Standard_B4ms"
      max_pods               = 110
      availability_zones     = ["1", "2", "3"]
      node_public_ip_enabled = false
      vnet_subnet_id         = ""
      pod_subnet_id          = ""
      os_sku                 = "Ubuntu"
      snapshot_id            = ""
      mode                   = "User"
      kubelet_config_enabled = false
      kubelet_config = {
        cpu_manager_policy        = "static"
        cpu_cfs_quota_enabled     = true
        cpu_cfs_quota_period      = "100ms"
        image_gc_high_threshold   = 85
        image_gc_low_threshold    = 80
        topology_manager_policy   = "best-effort"
        allowed_unsafe_sysctls    = []
        container_log_max_line    = 10
        container_log_max_size_mb = 10
        pod_max_pid               = 100
      }
    }
  }
}

variable "default_node_pool_kubelet_config_enabled" {
  type        = bool
  description = "Enable kubelet configuration for the default node pool"
  default     = false
}

variable "default_node_pool_kubelet_config" {
  type = object({
    cpu_manager_policy        = optional(string)
    cpu_cfs_quota_enabled     = optional(bool)
    cpu_cfs_quota_period      = optional(string)
    image_gc_high_threshold   = optional(number)
    image_gc_low_threshold    = optional(number)
    topology_manager_policy   = optional(string)
    allowed_unsafe_sysctls    = optional(list(string))
    container_log_max_line    = optional(number)
    container_log_max_size_mb = optional(number)
    pod_max_pid               = optional(number)
  })
  description = "Kubelet configuration for the default node pool"
  default = {
    cpu_manager_policy        = "static"
    cpu_cfs_quota_enabled     = true
    cpu_cfs_quota_period      = "100ms"
    image_gc_high_threshold   = 85
    image_gc_low_threshold    = 80
    topology_manager_policy   = "best-effort"
    allowed_unsafe_sysctls    = []
    container_log_max_line    = 10
    container_log_max_size_mb = 10
    pod_max_pid               = 100
  }
}

variable "maintenance_window_auto_upgrade_enabled" {
  type        = bool
  description = "Enable maintenance window auto upgrade"
  default     = false
}

variable "maintenance_window_auto_upgrade" {
  type = object({
    frequency    = optional(string)
    interval     = optional(number)
    duration     = optional(number)
    day_of_week  = optional(string)
    day_of_month = optional(number)
    week_index   = optional(string)
    start_time   = optional(string)
    utc_offset   = optional(string)
    start_date   = optional(string)
    not_allowed = optional(list(object({
      start_date = optional(string)
      end_date   = optional(string)
    })))
  })
  description = "Configuration for the maintenance window auto upgrade"
  default = {
    frequency    = "Weekly"
    interval     = 1
    duration     = 4
    day_of_week  = "Sunday"
    day_of_month = null
    week_index   = null
    start_time   = "00:00"
    utc_offset   = "+00:00"
    start_date   = null
    not_allowed  = []
  }
}

variable "maintenance_window_node_os_enabled" {
  type        = bool
  description = "Enable maintenance window node OS"
  default     = false
}

variable "maintenance_window_node_os" {
  type = object({
    frequency    = optional(string)
    interval     = optional(number)
    duration     = optional(number)
    day_of_week  = optional(string)
    day_of_month = optional(number)
    week_index   = optional(string)
    start_time   = optional(string)
    utc_offset   = optional(string)
    start_date   = optional(string)
    not_allowed = optional(list(object({
      start_date = optional(string)
      end_date   = optional(string)
    })))
  })
  description = "Configuration for the maintenance window node OS"
  default = {
    frequency    = "Weekly"
    interval     = 1
    duration     = 4
    day_of_week  = "Sunday"
    day_of_month = null
    week_index   = null
    start_time   = "00:00"
    utc_offset   = "+00:00"
    start_date   = null
    not_allowed  = []
  }
}

variable "node_os_upgrade_channel" {
  type        = string
  description = "The upgrade channel for this Kubernetes Cluster Nodes' OS Image"
  default     = "NodeImage"
  validation {
    condition     = contains(["Unmanaged", "SecurityPatch", "NodeImage", "None"], var.node_os_upgrade_channel)
    error_message = "The node_os_upgrade_channel must be one of 'Unmanaged', 'SecurityPatch', 'NodeImage', or 'None'."
  }
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix for the cluster"
  default     = ""
}

variable "authorized_ip_ranges_enabled" {
  type        = bool
  description = "Enable authorized IP ranges"
  default     = false
}

variable "authorized_ip_ranges" {
  type        = list(string)
  description = "Set of authorized IP ranges to allow access to API server"
  default     = []
}

variable "aad_tenant_id" {
  type        = string
  description = "The Tenant ID used for Azure Active Directory Application"
  default     = ""
}

variable "aad_admin_group_object_ids" {
  type        = list(string)
  description = "A list of Object IDs of Azure Active Directory Groups which should have Admin Role on the Cluster"
  default     = []
}

variable "aad_azure_rbac_enabled" {
  type        = bool
  description = "Is Role Based Access Control based on Azure AD enabled?"
  default     = false
}

variable "azure_active_directory_enabled" {
  type        = bool
  description = "Enable Azure Active Directory role-based access control"
  default     = false
}

variable "workload_identity_enabled" {
  type        = bool
  description = "Should workload identity be enabled?"
  default     = false
}

variable "workload_identities" {
  type = map(object({
    name           = optional(string)
    resource_group = optional(string)
    location       = optional(string)
    sa_namespaces = optional(list(object({
      sa_name      = optional(string)
      sa_namespace = optional(string)
    })))
    tags = optional(map(string))
    roleAssignments = optional(list(object({
      role  = string
      scope = string
    })))
  }))
  description = "Map of workload identities with roles and service accounts"
  default = {
    workload_identity_1 = {
      name           = "workload-identity-1"
      resource_group = "dev-rg-ci"
      location       = "centralindia"
      sa_namespaces = [
        {
          sa_name      = "sa1"
          sa_namespace = "namespace1"
        },
        {
          sa_name      = "sa2"
          sa_namespace = "namespace2"
        }
      ]
      tags = {
        environment = "dev"
      }
      roleAssignments = [
        {
          role  = "Contributor"
          scope = "subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.KeyVault/vaults/<key-vault>"
        }
      ]
    }
  }
}

variable "web_app_routing_enabled" {
  type        = bool
  description = "Should Web App Routing be enabled?"
  default     = false
}

variable "web_app_routing_dns_zone_ids" {
  type        = list(string)
  description = "List of DNS Zone IDs for Web App Routing"
  default     = []
}

variable "service_mesh_profile_enabled" {
  type        = bool
  description = "Enable service mesh profile"
  default     = false
}

variable "service_mesh_profile_mode" {
  type        = string
  description = "The mode of the service mesh. Possible value is Istio."
  default     = "Istio"
}

variable "service_mesh_profile_revisions" {
  type        = list(string)
  description = "Specify 1 or 2 Istio control plane revisions for managing minor upgrades using the canary upgrade process."
  default     = ["asm-1-22"]
}

variable "internal_ingress_gateway_enabled" {
  type        = bool
  description = "Is Istio Internal Ingress Gateway enabled?"
  default     = false
}

variable "external_ingress_gateway_enabled" {
  type        = bool
  description = "Is Istio External Ingress Gateway enabled?"
  default     = false
}

variable "certificate_authority" {
  type = object({
    key_vault_id           = optional(string)
    root_cert_object_name  = optional(string)
    cert_chain_object_name = optional(string)
    cert_object_name       = optional(string)
    key_object_name        = optional(string)
  })
  description = "Certificate authority configuration for Istio CA"
  default = {
    key_vault_id           = ""
    root_cert_object_name  = ""
    cert_chain_object_name = ""
    cert_object_name       = ""
    key_object_name        = ""
  }
  #   validation {
  #     condition     = var.certificate_authority.key_vault_id == "" || alltrue([for v in [var.certificate_authority.root_cert_object_name, var.certificate_authority.cert_chain_object_name, var.certificate_authority.cert_object_name, var.certificate_authority.key_object_name] : length(v) > 0])
  #     error_message = "All fields in certificate_authority must be non-empty strings if key_vault_id is provided."
  #   }
}

variable "key_vault_key_id" {
  description = "Identifier of Azure Key Vault key."
  type        = string
  default     = ""
}

variable "key_vault_network_access" {
  description = "Network access of the key vault. Possible values are Public and Private. Defaults to Public."
  type        = string
  default     = "Public"
}

variable "secret_rotation_enabled" {
  description = "Should the secret store CSI driver on the AKS cluster be enabled?"
  type        = bool
  default     = false
}

variable "secret_rotation_interval" {
  description = "The interval to poll for secret rotation. This attribute is only set when secret_rotation is true. Defaults to 2m."
  type        = string
  default     = "2m"
}

variable "oms_agent_log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace to use for the OMS agent."
  type        = string
  default     = ""
}

variable "oms_agent_msi_auth_for_monitoring_enabled" {
  description = "Should the OMS agent use MSI authentication for monitoring?"
  type        = bool
  default     = false
}

variable "oms_agent" {
  description = "Configuration for the OMS Agent"
  type = object({
    log_analytics_workspace_id      = optional(string)
    msi_auth_for_monitoring_enabled = optional(bool)
  })
  default = {
    log_analytics_workspace_id      = ""
    msi_auth_for_monitoring_enabled = false
  }
}

variable "workload_identity_key_vault_name" {
  description = "The name of the Key Vault for workload identity"
  type        = string
  default     = "dev-wi-1"
}

variable "key_vault_secrets_provider_enabled" {
  type        = bool
  description = "Enable Key Vault secrets provider"
  default     = false
}

variable "http_proxy_config_enabled" {
  type        = bool
  description = "Enable HTTP proxy configuration"
  default     = false
}

variable "http_proxy_config" {
  type = object({
    http_proxy  = optional(string)
    https_proxy = optional(string)
    no_proxy    = optional(list(string))
    trusted_ca  = optional(string)
  })
  description = "HTTP proxy configuration"
  default = {
    http_proxy  = ""
    https_proxy = ""
    no_proxy    = []
    trusted_ca  = ""
  }
}

variable "kubelet_identity_enabled" {
  type        = bool
  description = "Should kubelet identity be enabled?"
  default     = false
}

variable "kubelet_identity" {
  type = object({
    client_id                 = optional(string)
    object_id                 = optional(string)
    user_assigned_identity_id = optional(string)
  })
  description = "Configuration for the kubelet identity"
  default = {
    client_id                 = ""
    object_id                 = ""
    user_assigned_identity_id = ""
  }
}
