# Cluster variables
variable "project_id" {
  type        = string
  description = "The project ID to host the cluster in (required)"
  validation {
    condition     = length(var.project_id) > 0
    error_message = "The GCP project ID must not be empty."
  }
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster (required)"
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "The cluster name must not be empty."
  }
}

variable "description" {
  type        = string
  description = "The description of the cluster"
  default     = ""
}

variable "kubernetes_version" {
  type        = string
  description = "The Kubernetes version of the masters. If set to 'latest' it will pull latest available version in the selected region."
  default     = "latest"
}

variable "regional" {
  type        = bool
  description = "Whether is a regional cluster (zonal cluster if set false. WARNING: changing this after cluster creation is destructive!)"
  default     = true
}

variable "region" {
  type        = string
  description = "The region to host the cluster in (optional if zonal cluster / required if regional)"
  default     = ""
}

variable "zone" {
  type        = string
  description = "The zone to host the cluster in (optional if regional cluster / required if zonal)"
  default     = ""
}

variable "default_node_locations" {
  type        = list(string)
  description = "By default, Kubernetes Engine runs nodes of a regional cluster across three zones within a region. Select this option if you want to manually specify the zones in which this cluster's nodes run. All zones must be within the same region."
  default     = null
}

variable "network" {
  type        = string
  description = "The VPC network to host the cluster in"
  default     = "default"
  validation {
    condition     = length(var.network) > 0
    error_message = "The network name must not be empty."
  }
}

variable "network_project_id" {
  type        = string
  description = "The project ID of the shared VPC's host (for shared vpc support)"
  default     = ""
}

variable "subnetwork" {
  type        = string
  description = "The subnetwork to host the cluster in"
  default     = "default"
  validation {
    condition     = length(var.subnetwork) > 0
    error_message = "The subnetwork name must not be empty."
  }
}

variable "cluster_ipv4_cidr" {
  type        = string
  description = "The IP address range of the kubernetes pods in this cluster. Default is an automatically assigned CIDR. This field will default a new cluster to routes-based, where `ip_allocation_policy` is not defined."
  default     = null
}

variable "pods_cidr_block" {
  type        = string
  description = "The IP address range for the cluster pod IPs. Set to blank to have a range chosen with the default size. Set to /netmask (e.g. /14) to have a range chosen with a specific netmask. Set to a CIDR notation (e.g. 10.96.0.0/14) from the RFC-1918 private networks (e.g. 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16) to pick a specific range to use."
  default     = null
}

variable "services_cidr_block" {
  type        = string
  description = "The IP address range of the services IPs in this cluster. Set to blank to have a range chosen with the default size. Set to /netmask (e.g. /14) to have a range chosen with a specific netmask. Set to a CIDR notation (e.g. 10.96.0.0/14) from the RFC-1918 private networks (e.g. 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16) to pick a specific range to use."
  default     = null
}

variable "pods_secondary_range_name" {
  type        = string
  description = "The _name_ of the secondary subnet ip range to use for pods"
  default     = null
}

variable "services_secondary_range_name" {
  type        = string
  description = "The _name_ of the secondary subnet range to use for services"
  default     = null
}

variable "default_max_pods_per_node" {
  type        = number
  description = "The maximum number of pods to schedule per node"
  default     = 110
}

variable "network_policy" {
  type        = bool
  description = "Enable network policy addon"
  default     = false
}

variable "network_policy_provider" {
  type        = string
  description = "The network policy provider. Supported values: `CALICO` and `PROVIDER_UNSPECIFIED`"
  default     = "CALICO"
}

variable "datapath_provider" {
  type        = string
  description = "The desired datapath provider for this cluster. By default, `DATAPATH_PROVIDER_UNSPECIFIED` enables the IPTables-based kube-proxy implementation. `ADVANCED_DATAPATH` enables Dataplane-V2 feature. Supported values: `DATAPATH_PROVIDER_UNSPECIFIED`, `LEGACY_DATAPATH` and `ADVANCED_DATAPATH`"
  default     = "DATAPATH_PROVIDER_UNSPECIFIED"
}

variable "master_authorized_networks" {
  type        = list(object({ cidr_block = string, display_name = string }))
  description = "List of master authorized networks. If none are provided, disallow external access (except the cluster node IPs, which GKE automatically whitelists)."
  default     = []
}

variable "enable_private_cluster" {
  type        = bool
  description = "Whether to enable cluster network access private"
  default     = false
}

variable "access_control_plane_external_ip" {
  type        = bool
  description = "When `false`, the cluster's private endpoint is used as the cluster endpoint and access through the public endpoint is disabled. When `true`, either endpoint can be used. This field only applies to private clusters, when `enable_private_cluster` is `true`."
  default     = true
}

variable "control_plane_ipv4_cidr_block" {
  type        = string
  description = "The IP range in CIDR notation to use for the hosted master network. This range will be used for assigning private IP addresses to the cluster master(s) and the ILB VIP. This range must not overlap with any other ranges in use within the cluster's network, and it must be a /28 subnet. This field only applies to private clusters, when `enable_private_cluster` is `true`."
  default     = null
}

variable "access_control_plane_global" {
  type        = bool
  description = "Whether the cluster master is accessible globally or not."
  default     = true
}

variable "private_endpoint_subnetwork" {
  type        = string
  description = "Subnetwork in cluster's network where master's endpoint will be provisioned."
  default     = null
}

variable "disable_default_snat" {
  type        = bool
  description = "Whether to disable the default SNAT to support the private use of public IP addresses"
  default     = false
}

// security

variable "identity_namespace" {
  description = "The workload pool to attach all Kubernetes service accounts to. (Default value of `enabled` automatically sets project-based pool `[project_id].svc.id.goog`)"
  type        = string
  default     = "enabled"
}

variable "authenticator_security_group" {
  type        = string
  description = "The name of the RBAC security group for use with Google security groups in Kubernetes RBAC. Group name must be in format gke-security-groups@yourdomain.com"
  default     = null
}

variable "enable_legacy_abac" {
  type        = bool
  description = "Whether the ABAC authorizer is enabled for this cluster. When enabled, identities in the system, including service accounts, nodes, and controllers, will have statically granted permissions beyond those provided by the RBAC configuration or IAM. Defaults to `false`"
  default     = false
}

variable "issue_client_certificate" {
  type        = bool
  description = "Issues a client certificate to authenticate to the cluster endpoint. To maximize the security of your cluster, leave this option disabled. Client certificates don't automatically rotate and aren't easily revocable. WARNING: changing this after cluster creation is destructive!"
  default     = false
}

// features

variable "logging_enabled_components" {
  type        = list(string)
  description = "List of services to monitor: SYSTEM_COMPONENTS, APISERVER, CONTROLLER_MANAGER, SCHEDULER, and WORKLOADS. Empty list is logging disabled."
  default     = []
}

variable "monitoring_enabled_components" {
  type        = list(string)
  description = "List of services to monitor: SYSTEM_COMPONENTS, APISERVER, SCHEDULER, CONTROLLER_MANAGER, STORAGE, HPA, POD, DAEMONSET, DEPLOYMENT, STATEFULSET, KUBELET, CADVISOR and DCGM. In beta provider, WORKLOADS is supported on top of those 12 values. (WORKLOADS is deprecated and removed in GKE 1.24.) KUBELET and CADVISOR are only supported in GKE 1.29.3-gke.1093000 and above. Empty list is monitoring disabled."
  default     = []
}

variable "monitoring_enable_managed_prometheus" {
  type        = bool
  description = "Configuration for Managed Service for Prometheus. Whether or not the managed collection is enabled."
  default     = false
}

variable "monitoring_enable_observability_metrics" {
  type        = bool
  description = "Whether or not the advanced datapath metrics are enabled."
  default     = false
}

variable "monitoring_enable_observability_relay" {
  type        = bool
  description = "Whether or not the advanced datapath relay is enabled."
  default     = false
}

variable "filestore_csi_driver" {
  type        = bool
  description = "The status of the Filestore CSI driver addon, which allows the usage of filestore instance as volumes"
  default     = false
}

variable "kalm_config" {
  type        = bool
  description = "Whether enable KALM addon, which manages the lifecycle of k8s. It is disabled by default"
  default     = false
}

variable "gce_pd_csi_driver" {
  type        = bool
  description = "Whether this cluster should enable the Google Compute Engine Persistent Disk Container Storage Interface (CSI) Driver. It is enabled by default"
  default     = true
}

variable "gke_backup_agent_config" {
  type        = bool
  description = "Whether Backup for GKE agent is enabled for this cluster."
  default     = false
}

variable "enable_image_streaming" {
  type        = bool
  description = "Whether Image streaming is enabled for this cluster."
  default     = false
}

# GKE Node Pool variables

variable "node_pools" {
  type        = any
  description = "List of maps containing node pools"

  default = [
    {
      name = "default-node-pool"
      node_locations = "us-central1-c,us-central1-b,us-central1-f"
      # version = "1.30"
      initial_node_count = 1
      max_pods_per_node = 110
      autoscaling = true
      min_count = 1
      max_count = 100
      auto_upgrade = false
      strategy = "SURGE"
      max_surge = 1
      max_unavailable = 0
      # node_pool_soak_duration = "3600s"
      # batch_soak_duration = "30s"
      # batch_node_count = 2
      image_type = "COS_CONTAINERD"
      machine_type = "e2-medium"

      # consume_reservation_type = "SPECIFIC_RESERVATION"
      # reservation_affinity_key = "compute.googleapis.com/reservation-name"
      # reservation_affinity_values = "myreservation"

      taints = []

      disk_size_gb = 100
      disk_type = "pd-standard"

      spot = false

      # accelerator_count = 1
      # accelerator_type = "nvidia-tesla-p4"
      # gpu_partition_size = "1g.5gb"
      # gpu_driver_version = "LATEST"
      # gpu_sharing_strategy = "TIME_SHARING"
      # max_shared_clients_per_gpu = 3

      enable_secure_boot = false
      enable_integrity_monitoring = true
      tags = []
      k8s_labels = {}
      instance_metadata = {disable-legacy-endpoints=true}

      # placement_policy_type = "COMPACT"
      # tpu_topology = "2x2x1"

      # cpu_manager_policy = "static"
      # cpu_cfs_quota = true
      # cpu_cfs_quota_period = "100us"
      # insecure_kubelet_readonly_port_enabled = true
      # pod_pids_limit = 1024

      # enable_confidential_storage = false

      # enable_confidential_nodes = false

      # sysctls_net_core_netdev_max_backlog = "10000"
      # sysctls_net.core.rmem_max = "10000"
      # cgroup_mode = "CGROUP_MODE_UNSPECIFIED"
      # hugepages_config_hugepage_size_2m = ""
      # hugepages_config_hugepage_size_1g = ""
    },
  ]
}

variable "enable_maintenance_window" {
  type        = bool
  description = "Weather to enable maintenance window or not"
  default     = true
}

variable "maintenance_start_time" {
  type        = string
  description = "Time window specified for daily or recurring maintenance operations in RFC3339 format"
  default     = "05:00"
}

variable "maintenance_exclusions" {
  type        = list(object({ name = string, start_time = string, end_time = string, exclusion_scope = string }))
  description = "List of maintenance exclusions. A cluster can have up to three"
  default     = []
}

variable "maintenance_end_time" {
  type        = string
  description = "Time window specified for recurring maintenance operations in RFC3339 format"
  default     = ""
}

variable "maintenance_recurrence" {
  type        = string
  description = "Frequency of the recurring maintenance window in RFC5545 format."
  default     = ""
}

variable "enable_binary_authorization" {
  type        = bool
  description = "Enable BinAuthZ Admission controller"
  default     = false
}

variable "enable_secret_manager_addon" {
  description = "Enable the Secret Manager add-on for this cluster"
  type        = bool
  default     = false
}

variable "enable_confidential_nodes" {
  type        = bool
  description = "An optional flag to enable confidential node config."
  default     = false
}

variable "enable_intranode_visibility" {
  type        = bool
  description = "Whether Intra-node visibility is enabled for this cluster. This makes same node pod to pod traffic visible for VPC network"
  default     = false
}

variable "enable_l4_ilb_subsetting" {
  type        = bool
  description = "Enable L4 ILB Subsetting on the cluster"
  default     = false
}

variable "gateway_api_channel" {
  type        = string
  description = "The gateway api channel of this cluster. Accepted values are `CHANNEL_STANDARD` and `CHANNEL_DISABLED`."
  default     = null
}

variable "dns_cache" {
  type        = bool
  description = "The status of the NodeLocal DNSCache addon."
  default     = false
}

variable "ray_operator_config" {
  type = object({
    enabled            = bool
    logging_enabled    = optional(bool, false)
    monitoring_enabled = optional(bool, false)
  })
  description = "The Ray Operator Addon configuration for this cluster."
  default = {
    enabled            = false
    logging_enabled    = false
    monitoring_enabled = false
  }
}

variable "enable_tpu" {
  type        = bool
  description = "Enable Cloud TPU resources in the cluster. WARNING: changing this after cluster creation is destructive!"
  default     = false
}

variable "enable_cost_allocation" {
  type        = bool
  description = "Enables Cost Allocation Feature and the cluster name and namespace of your GKE workloads appear in the labels field of the billing export to BigQuery"
  default     = false
}

variable "firewall_rules" {
  description = "List of custom rule definitions"
  default     = []
  type = list(object({
    name        = string
    description = optional(string, null)
    # INGRESS or EGRESS
    direction   = optional(string, null)
    priority    = optional(number, null)
    ranges      = optional(list(string), [])
    source_tags = optional(list(string))
    target_tags = optional(list(string))

    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
  }))
}

variable "prebootstrap_commands" {
  type        = list(string)
  description = "List of prebootstrap commands"
  default     = []
}

variable "enable_vertical_pod_autoscaling" {
  type        = bool
  description = "Vertical Pod Autoscaling automatically adjusts the resources of pods controlled by it"
  default     = false
}

variable "enable_cilium_clusterwide_network_policy" {
  type        = bool
  description = "Enable Cilium Cluster Wide Network Policies on the cluster"
  default     = false
}

variable "enable_multi_networking" {
  type        = bool
  description = "Enable multi-networking on this cluster"
  default     = false
}

variable "enable_fqdn_network_policy" {
  type        = bool
  description = "Enable FQDN Network Policies on the cluster"
  default     = null
}
