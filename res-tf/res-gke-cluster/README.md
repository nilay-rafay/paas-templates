<!-- BEGIN_TF_DOCS -->
# Terraform GKE Cluster Module

This module handles GKE cluster for Rafay Environments.

## Requirements

### Google Cloud authentication
This module assumes you already have done [Google Cloud Authentication](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication).

### Configure a Service Account
In order to execute this module you must have a Service Account with the following project roles:

- roles/container.clusterAdmin

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 6.10.0 |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | 6.10.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.16.1 |

## Resources

| Name | Type |
|------|------|
| [google-beta_google_container_cluster.primary](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_container_cluster) | resource |
| [google_compute_firewall.rules](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_container_node_pool.pools](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool) | resource |
| [helm_release.prebootstrap](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [google_client_config.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_container_cluster.primary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/container_cluster) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_control_plane_external_ip"></a> [access\_control\_plane\_external\_ip](#input\_access\_control\_plane\_external\_ip) | When `false`, the cluster's private endpoint is used as the cluster endpoint and access through the public endpoint is disabled. When `true`, either endpoint can be used. This field only applies to private clusters, when `enable_private_cluster` is `true`. | `bool` | `true` | no |
| <a name="input_access_control_plane_global"></a> [access\_control\_plane\_global](#input\_access\_control\_plane\_global) | Whether the cluster master is accessible globally or not. | `bool` | `true` | no |
| <a name="input_authenticator_security_group"></a> [authenticator\_security\_group](#input\_authenticator\_security\_group) | The name of the RBAC security group for use with Google security groups in Kubernetes RBAC. Group name must be in format gke-security-groups@yourdomain.com | `string` | `null` | no |
| <a name="input_cluster_ipv4_cidr"></a> [cluster\_ipv4\_cidr](#input\_cluster\_ipv4\_cidr) | The IP address range of the kubernetes pods in this cluster. Default is an automatically assigned CIDR. This field will default a new cluster to routes-based, where `ip_allocation_policy` is not defined. | `string` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the cluster (required) | `string` | n/a | yes |
| <a name="input_control_plane_ipv4_cidr_block"></a> [control\_plane\_ipv4\_cidr\_block](#input\_control\_plane\_ipv4\_cidr\_block) | The IP range in CIDR notation to use for the hosted master network. This range will be used for assigning private IP addresses to the cluster master(s) and the ILB VIP. This range must not overlap with any other ranges in use within the cluster's network, and it must be a /28 subnet. This field only applies to private clusters, when `enable_private_cluster` is `true`. | `string` | `null` | no |
| <a name="input_datapath_provider"></a> [datapath\_provider](#input\_datapath\_provider) | The desired datapath provider for this cluster. By default, `DATAPATH_PROVIDER_UNSPECIFIED` enables the IPTables-based kube-proxy implementation. `ADVANCED_DATAPATH` enables Dataplane-V2 feature. Supported values: `DATAPATH_PROVIDER_UNSPECIFIED`, `LEGACY_DATAPATH` and `ADVANCED_DATAPATH` | `string` | `"DATAPATH_PROVIDER_UNSPECIFIED"` | no |
| <a name="input_default_max_pods_per_node"></a> [default\_max\_pods\_per\_node](#input\_default\_max\_pods\_per\_node) | The maximum number of pods to schedule per node | `number` | `110` | no |
| <a name="input_default_node_locations"></a> [default\_node\_locations](#input\_default\_node\_locations) | By default, Kubernetes Engine runs nodes of a regional cluster across three zones within a region. Select this option if you want to manually specify the zones in which this cluster's nodes run. All zones must be within the same region. | `list(string)` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | The description of the cluster | `string` | `""` | no |
| <a name="input_disable_default_snat"></a> [disable\_default\_snat](#input\_disable\_default\_snat) | Whether to disable the default SNAT to support the private use of public IP addresses | `bool` | `false` | no |
| <a name="input_dns_cache"></a> [dns\_cache](#input\_dns\_cache) | The status of the NodeLocal DNSCache addon. | `bool` | `false` | no |
| <a name="input_enable_binary_authorization"></a> [enable\_binary\_authorization](#input\_enable\_binary\_authorization) | Enable BinAuthZ Admission controller | `bool` | `false` | no |
| <a name="input_enable_confidential_nodes"></a> [enable\_confidential\_nodes](#input\_enable\_confidential\_nodes) | An optional flag to enable confidential node config. | `bool` | `false` | no |
| <a name="input_enable_cost_allocation"></a> [enable\_cost\_allocation](#input\_enable\_cost\_allocation) | Enables Cost Allocation Feature and the cluster name and namespace of your GKE workloads appear in the labels field of the billing export to BigQuery | `bool` | `false` | no |
| <a name="input_enable_image_streaming"></a> [enable\_image\_streaming](#input\_enable\_image\_streaming) | Whether Image streaming is enabled for this cluster. | `bool` | `false` | no |
| <a name="input_enable_intranode_visibility"></a> [enable\_intranode\_visibility](#input\_enable\_intranode\_visibility) | Whether Intra-node visibility is enabled for this cluster. This makes same node pod to pod traffic visible for VPC network | `bool` | `false` | no |
| <a name="input_enable_l4_ilb_subsetting"></a> [enable\_l4\_ilb\_subsetting](#input\_enable\_l4\_ilb\_subsetting) | Enable L4 ILB Subsetting on the cluster | `bool` | `false` | no |
| <a name="input_enable_legacy_abac"></a> [enable\_legacy\_abac](#input\_enable\_legacy\_abac) | Whether the ABAC authorizer is enabled for this cluster. When enabled, identities in the system, including service accounts, nodes, and controllers, will have statically granted permissions beyond those provided by the RBAC configuration or IAM. Defaults to `false` | `bool` | `false` | no |
| <a name="input_enable_maintenance_window"></a> [enable\_maintenance\_window](#input\_enable\_maintenance\_window) | Weather to enable maintenance window or not | `bool` | `true` | no |
| <a name="input_enable_private_cluster"></a> [enable\_private\_cluster](#input\_enable\_private\_cluster) | Whether to enable cluster network access private | `bool` | `false` | no |
| <a name="input_enable_secret_manager_addon"></a> [enable\_secret\_manager\_addon](#input\_enable\_secret\_manager\_addon) | Enable the Secret Manager add-on for this cluster | `bool` | `false` | no |
| <a name="input_enable_tpu"></a> [enable\_tpu](#input\_enable\_tpu) | Enable Cloud TPU resources in the cluster. WARNING: changing this after cluster creation is destructive! | `bool` | `false` | no |
| <a name="input_filestore_csi_driver"></a> [filestore\_csi\_driver](#input\_filestore\_csi\_driver) | The status of the Filestore CSI driver addon, which allows the usage of filestore instance as volumes | `bool` | `false` | no |
| <a name="input_firewall_rules"></a> [firewall\_rules](#input\_firewall\_rules) | List of custom rule definitions | <pre>list(object({<br>    name        = string<br>    description = optional(string, null)<br>    # INGRESS or EGRESS<br>    direction   = optional(string, null)<br>    priority    = optional(number, null)<br>    ranges      = optional(list(string), [])<br>    source_tags = optional(list(string))<br>    target_tags = optional(list(string))<br><br>    allow = optional(list(object({<br>      protocol = string<br>      ports    = optional(list(string))<br>    })), [])<br>    deny = optional(list(object({<br>      protocol = string<br>      ports    = optional(list(string))<br>    })), [])<br>  }))</pre> | `[]` | no |
| <a name="input_gateway_api_channel"></a> [gateway\_api\_channel](#input\_gateway\_api\_channel) | The gateway api channel of this cluster. Accepted values are `CHANNEL_STANDARD` and `CHANNEL_DISABLED`. | `string` | `null` | no |
| <a name="input_gce_pd_csi_driver"></a> [gce\_pd\_csi\_driver](#input\_gce\_pd\_csi\_driver) | Whether this cluster should enable the Google Compute Engine Persistent Disk Container Storage Interface (CSI) Driver. It is enabled by default | `bool` | `true` | no |
| <a name="input_gke_backup_agent_config"></a> [gke\_backup\_agent\_config](#input\_gke\_backup\_agent\_config) | Whether Backup for GKE agent is enabled for this cluster. | `bool` | `false` | no |
| <a name="input_identity_namespace"></a> [identity\_namespace](#input\_identity\_namespace) | The workload pool to attach all Kubernetes service accounts to. (Default value of `enabled` automatically sets project-based pool `[project_id].svc.id.goog`) | `string` | `"enabled"` | no |
| <a name="input_issue_client_certificate"></a> [issue\_client\_certificate](#input\_issue\_client\_certificate) | Issues a client certificate to authenticate to the cluster endpoint. To maximize the security of your cluster, leave this option disabled. Client certificates don't automatically rotate and aren't easily revocable. WARNING: changing this after cluster creation is destructive! | `bool` | `false` | no |
| <a name="input_kalm_config"></a> [kalm\_config](#input\_kalm\_config) | Whether enable KALM addon, which manages the lifecycle of k8s. It is disabled by default | `bool` | `false` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | The Kubernetes version of the masters. If set to 'latest' it will pull latest available version in the selected region. | `string` | `"latest"` | no |
| <a name="input_logging_enabled_components"></a> [logging\_enabled\_components](#input\_logging\_enabled\_components) | List of services to monitor: SYSTEM\_COMPONENTS, APISERVER, CONTROLLER\_MANAGER, SCHEDULER, and WORKLOADS. Empty list is logging disabled. | `list(string)` | `[]` | no |
| <a name="input_maintenance_end_time"></a> [maintenance\_end\_time](#input\_maintenance\_end\_time) | Time window specified for recurring maintenance operations in RFC3339 format | `string` | `""` | no |
| <a name="input_maintenance_exclusions"></a> [maintenance\_exclusions](#input\_maintenance\_exclusions) | List of maintenance exclusions. A cluster can have up to three | `list(object({ name = string, start_time = string, end_time = string, exclusion_scope = string }))` | `[]` | no |
| <a name="input_maintenance_recurrence"></a> [maintenance\_recurrence](#input\_maintenance\_recurrence) | Frequency of the recurring maintenance window in RFC5545 format. | `string` | `""` | no |
| <a name="input_maintenance_start_time"></a> [maintenance\_start\_time](#input\_maintenance\_start\_time) | Time window specified for daily or recurring maintenance operations in RFC3339 format | `string` | `"05:00"` | no |
| <a name="input_master_authorized_networks"></a> [master\_authorized\_networks](#input\_master\_authorized\_networks) | List of master authorized networks. If none are provided, disallow external access (except the cluster node IPs, which GKE automatically whitelists). | `list(object({ cidr_block = string, display_name = string }))` | `[]` | no |
| <a name="input_monitoring_enable_managed_prometheus"></a> [monitoring\_enable\_managed\_prometheus](#input\_monitoring\_enable\_managed\_prometheus) | Configuration for Managed Service for Prometheus. Whether or not the managed collection is enabled. | `bool` | `false` | no |
| <a name="input_monitoring_enable_observability_metrics"></a> [monitoring\_enable\_observability\_metrics](#input\_monitoring\_enable\_observability\_metrics) | Whether or not the advanced datapath metrics are enabled. | `bool` | `false` | no |
| <a name="input_monitoring_enable_observability_relay"></a> [monitoring\_enable\_observability\_relay](#input\_monitoring\_enable\_observability\_relay) | Whether or not the advanced datapath relay is enabled. | `bool` | `false` | no |
| <a name="input_monitoring_enabled_components"></a> [monitoring\_enabled\_components](#input\_monitoring\_enabled\_components) | List of services to monitor: SYSTEM\_COMPONENTS, APISERVER, SCHEDULER, CONTROLLER\_MANAGER, STORAGE, HPA, POD, DAEMONSET, DEPLOYMENT, STATEFULSET, KUBELET, CADVISOR and DCGM. In beta provider, WORKLOADS is supported on top of those 12 values. (WORKLOADS is deprecated and removed in GKE 1.24.) KUBELET and CADVISOR are only supported in GKE 1.29.3-gke.1093000 and above. Empty list is monitoring disabled. | `list(string)` | `[]` | no |
| <a name="input_network"></a> [network](#input\_network) | The VPC network to host the cluster in | `string` | `"default"` | no |
| <a name="input_network_policy"></a> [network\_policy](#input\_network\_policy) | Enable network policy addon | `bool` | `false` | no |
| <a name="input_network_policy_provider"></a> [network\_policy\_provider](#input\_network\_policy\_provider) | The network policy provider. Supported values: `CALICO` and `PROVIDER_UNSPECIFIED` | `string` | `"CALICO"` | no |
| <a name="input_network_project_id"></a> [network\_project\_id](#input\_network\_project\_id) | The project ID of the shared VPC's host (for shared vpc support) | `string` | `""` | no |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | List of maps containing node pools | `any` | <pre>[<br>  {<br>    "name": "default-node-pool"<br>  }<br>]</pre> | no |
| <a name="input_pods_cidr_block"></a> [pods\_cidr\_block](#input\_pods\_cidr\_block) | The IP address range for the cluster pod IPs. Set to blank to have a range chosen with the default size. Set to /netmask (e.g. /14) to have a range chosen with a specific netmask. Set to a CIDR notation (e.g. 10.96.0.0/14) from the RFC-1918 private networks (e.g. 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16) to pick a specific range to use. | `string` | `null` | no |
| <a name="input_pods_secondary_range_name"></a> [pods\_secondary\_range\_name](#input\_pods\_secondary\_range\_name) | The _name_ of the secondary subnet ip range to use for pods | `string` | `null` | no |
| <a name="input_prebootstrap_commands"></a> [prebootstrap\_commands](#input\_prebootstrap\_commands) | List of prebootstrap commands | `list(string)` | `[]` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project ID to host the cluster in (required) | `string` | n/a | yes |
| <a name="input_ray_operator_config"></a> [ray\_operator\_config](#input\_ray\_operator\_config) | The Ray Operator Addon configuration for this cluster. | <pre>object({<br>    enabled            = bool<br>    logging_enabled    = optional(bool, false)<br>    monitoring_enabled = optional(bool, false)<br>  })</pre> | <pre>{<br>  "enabled": false,<br>  "logging_enabled": false,<br>  "monitoring_enabled": false<br>}</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | The region to host the cluster in (optional if zonal cluster / required if regional) | `string` | `""` | no |
| <a name="input_regional"></a> [regional](#input\_regional) | Whether is a regional cluster (zonal cluster if set false. WARNING: changing this after cluster creation is destructive!) | `bool` | `true` | no |
| <a name="input_services_cidr_block"></a> [services\_cidr\_block](#input\_services\_cidr\_block) | The IP address range of the services IPs in this cluster. Set to blank to have a range chosen with the default size. Set to /netmask (e.g. /14) to have a range chosen with a specific netmask. Set to a CIDR notation (e.g. 10.96.0.0/14) from the RFC-1918 private networks (e.g. 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16) to pick a specific range to use. | `string` | `null` | no |
| <a name="input_services_secondary_range_name"></a> [services\_secondary\_range\_name](#input\_services\_secondary\_range\_name) | The _name_ of the secondary subnet range to use for services | `string` | `null` | no |
| <a name="input_subnetwork"></a> [subnetwork](#input\_subnetwork) | The subnetwork to host the cluster in | `string` | `"default"` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | The zone to host the cluster in (optional if regional cluster / required if zonal) | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_labels"></a> [cluster\_labels](#output\_cluster\_labels) | Cluster labels |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Cluster name |
| <a name="output_cluster_type"></a> [cluster\_type](#output\_cluster\_type) | Cluster type (regional / zonal) |
| <a name="output_current_control_plane_version"></a> [current\_control\_plane\_version](#output\_current\_control\_plane\_version) | Current control plane kubernetes version |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | Cluster endpoint |
| <a name="output_gcp_project_id"></a> [gcp\_project\_id](#output\_gcp\_project\_id) | GCP Project ID |
| <a name="output_location"></a> [location](#output\_location) | Cluster location (region if regional cluster, zone if zonal cluster) |
<!-- END_TF_DOCS -->