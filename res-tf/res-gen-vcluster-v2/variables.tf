variable "hserver" {
  description = "Kubeconfig server"
  type        = string
}

variable "clientcertificatedata" {
  description = "Kubeconfig client-certificate-data"
  type        = string
}

variable "clientkeydata" {
  description = "Kubeconfig client-key-data"
  type        = string
}

variable "certificateauthoritydata" {
  description = "Kubeconfig certificate-authority-data"
  type        = string
}

variable "kubeconfig" {
  description = "Kubeconfig"
  type        = string
}

variable "host_cluster_name" {
  description = "The name of the host cluster"
  type        = string
  validation {
    condition     = length(var.host_cluster_name) > 0
    error_message = "The cluster name must not be empty."
  }
}

variable "vcluster_name" {
  description = "Name of the vcluster to deploy"
  type        = string
  validation {
    condition     = length(var.vcluster_name) > 0
    error_message = "The cluster name must not be empty."
  }
}

variable "project" {
  description = "The project to deploy the vcluster."
  type        = string
  validation {
    condition     = length(var.project) > 0
    error_message = "The project must not be empty."
  }
}

variable "host_project" {
  description = "The project of the host clustrer."
  type        = string
  validation {
    condition     = length(var.host_project) > 0
    error_message = "The project must not be empty."
  }
}

variable "blueprint" {
  description = "The Blueprint to deploy the vcluster."
  type        = string
  default     = "minimal"
}

variable "blueprint_version" {
  description = "The Blueprint version"
  type        = string
  default     = "latest"
}

variable "vcluster_version" {
  description = "vCluster chart/application version"
  type        = string
  default     = "v0.23.0"
}

variable "default_charts" {
  description = "mapping for vcluster distro"
  default = {
    "k3s" = "vcluster",
    "k0s" = "vcluster-k0s",
    "k8s" = "vcluster-k8s"
  }
}

variable "distro" {
  description = "vCLuster Distribution"
  type        = string
  default     = "k8s"
}

variable "vcluster_store_size" {
  description = "Size is the persistent volume claim storage size for vCLuster"
  type        = string
  default     = "50Gi"
}

variable "namespace" {
  description = "The namespace to deploy the vcluster."
  type        = string
  validation {
    condition     = length(var.namespace) > 0
    error_message = "The namespace must not be empty."
  }
}

variable "namespace_labels" {
  type    = map(string)
  default = {}
}

variable "namespace_annotations" {
  type    = map(string)
  default = {}
}

variable "tolerations" {
  description = "Adding tolerations to vcluster config , for the pods to be synced to host cluster with a specific tolerations and placed on the respected allocated nodes/gpu type"
  type = map(object({
    key    = string
    value  = string
    effect = string
  }))
  default = {}
}

variable "rctl_config_path" {
  description = "The path to the Rafay CLI config file"
  type        = string
  default     = "opt/rafay"
}

variable "namespace_quota_size" {
  type    = string
  default = "small"
}

variable "namespace_container_limits" {
  type = object({
    cpu_requests    = string
    memory_requests = string
    cpu_limits      = string
    memory_limits   = string
  })
  default = {
    cpu_requests    = "200m"
    memory_requests = "256Mi"
    cpu_limits      = "1000m"
    memory_limits   = "2Gi"
  }
}
variable "namespace_quotas" {
  type = map(object({
    cpu_requests    = string
    memory_requests = string
    cpu_limits      = string
    memory_limits   = string
    gpu_requests    = string
    gpu_limits      = string
  }))
  default = {
    small = {
      cpu_requests    = "4"
      memory_requests = "8Gi"
      cpu_limits      = "4"
      memory_limits   = "8Gi"
      gpu_requests    = "1"
      gpu_limits      = "1"
    }
    medium = {
      cpu_requests    = "8"
      memory_requests = "16Gi"
      cpu_limits      = "8"
      memory_limits   = "16Gi"
      gpu_requests    = "2"
      gpu_limits      = "2"
    }
    large = {
      cpu_requests    = "16"
      memory_requests = "32Gi"
      cpu_limits      = "16"
      memory_limits   = "32Gi"
      gpu_requests    = "4"
      gpu_limits      = "4"
    }
  }
}

variable "default_namespaces" {
  description = "List of predefined namespaces"
  type        = list(string)
  default     = ["kube-system", "rafay-system", "rafay-infra"] 
}

variable "user_defined_namespaces" {
  description = "List of user-defined namespaces for global network policies"
  type        = list(string)
  default     = []
}

variable "network_policy" {
  description = "Global network policy for the namespace"
  type        = bool
  default     = false
}

variable "enable_kata_runtime" {
  description = "Enable kata-qemu runtime class for the namespace"
  type        = bool
  default     = false
}


variable "device_details" {
  description = "Device/node on which vcluster pods will be deployed"
  type        = string
  default     = ""
}


variable "tocidr_ips" {
  description = "Name of the service"
  type        = list(string)
  default     = []
}
variable "fromcidr_ips" {
  description = "Name of the service"
  type        = list(string)
  default     = []
}
variable "cidrblock" {
  description = "CIDR block for the network"
  type        = string
  default     = ""
}

variable "gpu_type" {
  description = "The type of GPU to use"
  type        = string
  default     = "nvidia"
}

variable "frm_ns" {
  description = "Namespace for the Kubernetes resources"
  type        = any
  default     = [{"ns":"cloudeka-metric"},{"ns":"metallb-system"},{"ns":"ingress-nginx-public"},{"ns":"loft"},{"ns":"rafay-system"},{"ns":"rafay-infra"}]
}
variable "to_ns" {
  description = "Namespace for the Kubernetes resources"
  type        = any
  default     = [{"ns":"kube-system","app":"kube-dns"},{"ns":"kubevirt","app":"virt-api"},{"ns":"cdi","app":"cdi-apiserver"},{"ns":"kyverno","app":"admission-controller"},{"ns":"cloudeka-metric"}]
}

variable "plugin_image" {
  description = "Docker image to use for the vcluster plugin"
  type        = string
  default     = "registry.dev.rafay-edge.net/dev/rafay-vcluster-pro:20250519033318"
}