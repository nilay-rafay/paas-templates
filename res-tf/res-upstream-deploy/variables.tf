variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
  default     = "cluster-name"
}

variable "cluster_project" {
  description = "Name of the project"
  type        = string
  default     = "project-name"
}

variable "cluster_labels" {
  type    = map(string)
  default = {}
}

variable "cluster_blueprint" {
  type    = string
  default = "minimal"
}

variable "cluster_blueprint_version" {
  type    = string
  default = "latest"
}

variable "cloud_credentials" {
  description = "upstream cloud credentials"
  type        = string
  default     = ""
}

variable "auto_approve_nodes" {
  description = "Auto approve nodes"
  type        = bool
  default     = true
}

variable "cluster_dedicated_controlplanes" {
  description = "Enable dedicated control planes"
  type        = bool
  default     = false
}

variable "cluster_ha" {
  description = "Enable high availability"
  type        = bool
  default     = false
}

variable "installer_ttl" {
  description = "Configure the validity period of the Installer certificate"
  type        = number
  default     = 365
}

variable "kubelet_extra_args" {
  description = "Configure Kubelet arguments to fine tune node-level configuration in your cluster"
  type        = map(string)
  default = {
    max-pods           = "200",
    cpu-manager-policy = "none"
  }
}

variable "cluster_kubernetes_version" {
  description = "Version of Kubernetes"
  type        = string
  default     = "v1.29.8"
}

variable "cluster_location" {
  description = "Location of the cluster"
  type        = string
  default     = "sanjose-us"
}

variable "network" {
  description = "The network configuration"
  type = object({
    cni = object({
      name    = string
      version = string
    })
    pod_subnet     = string
    service_subnet = string
  })
  default = {
    cni = {
      name    = "Calico"
      version = "3.26.1"
    }
    pod_subnet     = "10.244.0.0/16"
    service_subnet = "10.96.0.0/12"
  }
}

variable "proxy_config" {
  description = "Configuration for the proxy"
  type = map(object({
    enabled                  = bool
    allow_insecure_bootstrap = bool
    bootstrap_ca             = string
    http_proxy               = string
    https_proxy              = string
    no_proxy                 = string
    proxy_auth               = string
  }))
  default = {
    default = {
      enabled                  = false
      allow_insecure_bootstrap = true
      bootstrap_ca             = "cert"
      http_proxy               = "http://proxy.example.com:8080/"
      https_proxy              = "https://proxy.example.com:8080/"
      no_proxy                 = "10.96.0.0/12,10.244.0.0/16"
      proxy_auth               = "proxyauth"
    }
  }
}


variable "kubernetes_upgrade" {
  description = "Kubernetes upgrade strategy and parameters"
  type = object({
    strategy = string
    params = object({
      worker_concurrency = string
    })
  })
  default = {
    strategy = "sequential"
    params = {
      worker_concurrency = "50%"
    }
  }
}

variable "controlplane_nodes" {
  type = map(object({
    arch               = string
    hostname           = string
    operating_system   = string
    private_ip         = string
    kubelet_extra_args = optional(map(string))
    roles              = set(string)
    ssh = object({
      ip_address       = string
      port             = string
      private_key_path = string
      username         = string
    })
    labels = optional(map(string))
    taints = optional(list(object({
      effect = string
      key    = string
      value  = string
    })))
  }))
  default = {
    hostname1 = {
      arch             = "amd64"
      hostname         = "hostname1"
      operating_system = "Ubuntu22.04"
      private_ip       = "10.12.25.234"
      kubelet_extra_args = {
        max-pods                     = "300",
        cpu-manager-reconcile-period = "30s"
      }
      roles = ["ControlPlane", "Worker"]
      ssh = {
        ip_address       = "10.12.25.234"
        port             = "22"
        private_key_path = "/path/to/private/key"
        username         = "user"
      }
      labels = {
        "app"   = "infra"
        "infra" = "true"
      }
      taints = [
        {
          effect = "NoSchedule"
          key    = "infra"
          value  = "true"
        },
        {
          effect = "NoSchedule"
          key    = "app"
          value  = "infra"
        }
      ]
    }
  }
}

variable "worker_nodes" {
  type = map(object({
    arch               = string
    hostname           = string
    operating_system   = string
    private_ip         = string
    kubelet_extra_args = optional(map(string))
    roles              = set(string)
    ssh = object({
      ip_address       = string
      port             = string
      private_key_path = string
      username         = string
    })
    labels = optional(map(string))
    taints = optional(list(object({
      effect = string
      key    = string
      value  = string
    })))
  }))
  default = {
    hostname2 = {
      arch             = "amd64"
      hostname         = "hostname2"
      operating_system = "Ubuntu22.04"
      private_ip       = "10.12.25.235"
      kubelet_extra_args = {
        max-pods                     = "400",
        cpu-manager-reconcile-period = "40s"
      }
      roles = ["Worker"]
      ssh = {
        ip_address       = "10.12.25.235"
        port             = "22"
        private_key_path = "/path/to/private/key"
        username         = "user"
      }
      labels = {
        "app"   = "infra"
        "infra" = "true"
      }
      taints = [
        {
          effect = "NoSchedule"
          key    = "infra"
          value  = "true"
        },
        {
          effect = "NoSchedule"
          key    = "app"
          value  = "infra"
        }
      ]
    }
  }
}

variable "system_components_placement" {
  description = "Placement settings for system components"
  type = object({
    node_selector = map(string)
    tolerations = list(object({
      effect   = string
      key      = string
      operator = string
      value    = string
    }))
  })
  default = null
  # default = {
  #   node_selector = {
  #     # "app"   = "infra"
  #     # "infra" = "true"
  #   }
  #   tolerations = [
  #     # {
  #     #   effect   = "NoSchedule"
  #     #   key      = "infra"
  #     #   operator = "Equal"
  #     #   value    = "true"
  #     # },
  #     # {
  #     #   effect   = "NoSchedule"
  #     #   key      = "app"
  #     #   operator = "Equal"
  #     #   value    = "infra"
  #     # },
  #     # {
  #     #   effect   = "NoSchedule"
  #     #   key      = "app"
  #     #   operator = "Equal"
  #     #   value    = "platform"
  #     # }
  #   ]
  # }
}



