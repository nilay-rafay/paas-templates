variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
  default     = "shishir-mks"
}

variable "gpu_chart_repository" {
  description = "Repository for GPU Operator Helm chart"
  type        = string
  default     = "https://helm.ngc.nvidia.com/nvidia"
}

variable "gpu_chart" {
  description = "value of the GPU Operator Helm chart"
  type        = string
  default     = "gpu-operator"
}

variable "gpu_chart_name" {
  description = "Name of the GPU Operator Helm chart"
  type        = string
  default     = "nvidia-gpu-operator"
}

variable "values_json" {
  description = "values.json file for the GPU Operator Helm chart"
  type        = string
  default     = <<EOF
  {
    "platform" : {
      "openshift" : false
    },
    "nfd" : {
      "enabled" : true,
      "nodefeaturerules" : false
    },
    "psa" : {
      "enabled" : false
    },
    "cdi" : {
      "enabled" : false,
      "default" : false
    },
    "sandboxWorkloads" : {
      "enabled" : false,
      "defaultWorkload" : "container"
    },
    "hostPaths" : {
      "rootFS" : "/",
      "driverInstallDir" : "/run/nvidia/driver"
    },
    "daemonsets" : {
      "labels" : {},
      "annotations" : {},
      "priorityClassName" : "system-node-critical",
      "tolerations" : [
        {
          "key" : "nvidia.com/gpu",
          "operator" : "Exists",
          "effect" : "NoSchedule"
        }
      ],
      "updateStrategy" : "RollingUpdate",
      "rollingUpdate" : {
        "maxUnavailable" : "1"
      }
    },
    "validator" : {
      "repository" : "nvcr.io/nvidia/cloud-native",
      "image" : "gpu-operator-validator",
      "imagePullPolicy" : "IfNotPresent",
      "imagePullSecrets" : [],
      "env" : [],
      "args" : [],
      "resources" : {},
      "plugin" : {
        "env" : [
          {
            "name" : "WITH_WORKLOAD",
            "value" : "false"
          }
        ]
      }
    },
    "operator" : {
      "repository" : "nvcr.io/nvidia",
      "image" : "gpu-operator",
      "imagePullPolicy" : "IfNotPresent",
      "imagePullSecrets" : [],
      "priorityClassName" : "system-node-critical",
      "defaultRuntime" : "docker",
      "runtimeClass" : "nvidia",
      "use_ocp_driver_toolkit" : false,
      "cleanupCRD" : false,
      "upgradeCRD" : true,
      "initContainer" : {
        "image" : "cuda",
        "repository" : "nvcr.io/nvidia",
        "version" : "12.6.2-base-ubi9",
        "imagePullPolicy" : "IfNotPresent"
      },
      "tolerations" : [
        {
          "key" : "node-role.kubernetes.io/master",
          "operator" : "Equal",
          "value" : "",
          "effect" : "NoSchedule"
        },
        {
          "key" : "node-role.kubernetes.io/control-plane",
          "operator" : "Equal",
          "value" : "",
          "effect" : "NoSchedule"
        }
      ],
      "annotations" : {
        "openshift.io/scc" : "restricted-readonly"
      },
      "affinity" : {
        "nodeAffinity" : {
          "preferredDuringSchedulingIgnoredDuringExecution" : [
            {
              "weight" : 1,
              "preference" : {
                "matchExpressions" : [
                  {
                    "key" : "node-role.kubernetes.io/master",
                    "operator" : "In",
                    "values" : [
                      ""
                    ]
                  }
                ]
              }
            },
            {
              "weight" : 1,
              "preference" : {
                "matchExpressions" : [
                  {
                    "key" : "node-role.kubernetes.io/control-plane",
                    "operator" : "In",
                    "values" : [
                      ""
                    ]
                  }
                ]
              }
            }
          ]
        }
      },
      "logging" : {
        "timeEncoding" : "epoch",
        "level" : "info",
        "develMode" : false
      },
      "resources" : {
        "limits" : {
          "cpu" : "600m",
          "memory" : "350Mi"
        },
        "requests" : {
          "cpu" : "200m",
          "memory" : "100Mi"
        }
      }
    },
    "mig" : {
      "strategy" : "single"
    },
    "driver" : {
      "enabled" : true,
      "nvidiaDriverCRD" : {
        "enabled" : false,
        "deployDefaultCR" : true,
        "driverType" : "gpu",
        "nodeSelector" : {}
      },
      "useOpenKernelModules" : false,
      "usePrecompiled" : false,
      "repository" : "nvcr.io/nvidia",
      "image" : "driver",
      "version" : "550.90.12",
      "imagePullPolicy" : "IfNotPresent",
      "imagePullSecrets" : [],
      "startupProbe" : {
        "initialDelaySeconds" : 60,
        "periodSeconds" : 10,
        "timeoutSeconds" : 60,
        "failureThreshold" : 120
      },
      "rdma" : {
        "enabled" : false,
        "useHostMofed" : false
      },
      "upgradePolicy" : {
        "autoUpgrade" : true,
        "maxParallelUpgrades" : 1,
        "maxUnavailable" : "25%",
        "waitForCompletion" : {
          "timeoutSeconds" : 0,
          "podSelector" : ""
        },
        "gpuPodDeletion" : {
          "force" : false,
          "timeoutSeconds" : 300,
          "deleteEmptyDir" : false
        },
        "drain" : {
          "enable" : false,
          "force" : false,
          "podSelector" : "",
          "timeoutSeconds" : 300,
          "deleteEmptyDir" : false
        }
      },
      "manager" : {
        "image" : "k8s-driver-manager",
        "repository" : "nvcr.io/nvidia/cloud-native",
        "version" : "v0.7.0",
        "imagePullPolicy" : "IfNotPresent",
        "env" : [
          {
            "name" : "ENABLE_GPU_POD_EVICTION",
            "value" : "true"
          },
          {
            "name" : "ENABLE_AUTO_DRAIN",
            "value" : "false"
          },
          {
            "name" : "DRAIN_USE_FORCE",
            "value" : "false"
          },
          {
            "name" : "DRAIN_POD_SELECTOR_LABEL",
            "value" : ""
          },
          {
            "name" : "DRAIN_TIMEOUT_SECONDS",
            "value" : "0s"
          },
          {
            "name" : "DRAIN_DELETE_EMPTYDIR_DATA",
            "value" : "false"
          }
        ]
      },
      "env" : [],
      "resources" : {},
      "repoConfig" : {
        "configMapName" : ""
      },
      "certConfig" : {
        "name" : ""
      },
      "licensingConfig" : {
        "configMapName" : "",
        "nlsEnabled" : true
      },
      "virtualTopology" : {
        "config" : ""
      },
      "kernelModuleConfig" : {
        "name" : ""
      }
    },
    "toolkit" : {
      "enabled" : true,
      "repository" : "nvcr.io/nvidia/k8s",
      "image" : "container-toolkit",
      "version" : "v1.16.2-ubuntu20.04",
      "imagePullPolicy" : "IfNotPresent",
      "imagePullSecrets" : [],
      "env" : [],
      "resources" : {},
      "installDir" : "/usr/local/nvidia"
    },
    "devicePlugin" : {
      "enabled" : true,
      "repository" : "nvcr.io/nvidia",
      "image" : "k8s-device-plugin",
      "version" : "v0.16.2-ubi8",
      "imagePullPolicy" : "IfNotPresent",
      "imagePullSecrets" : [],
      "args" : [],
      "env" : [
        {
          "name" : "PASS_DEVICE_SPECS",
          "value" : "true"
        },
        {
          "name" : "FAIL_ON_INIT_ERROR",
          "value" : "true"
        },
        {
          "name" : "DEVICE_LIST_STRATEGY",
          "value" : "envvar"
        },
        {
          "name" : "DEVICE_ID_STRATEGY",
          "value" : "uuid"
        },
        {
          "name" : "NVIDIA_VISIBLE_DEVICES",
          "value" : "all"
        },
        {
          "name" : "NVIDIA_DRIVER_CAPABILITIES",
          "value" : "all"
        }
      ],
      "resources" : {},
      "config" : {
        "create" : false,
        "name" : "",
        "default" : "",
        "data" : {}
      },
      "mps" : {
        "root" : "/run/nvidia/mps"
      }
    },
    "dcgm" : {
      "enabled" : false,
      "repository" : "nvcr.io/nvidia/cloud-native",
      "image" : "dcgm",
      "version" : "3.3.8-1-ubuntu22.04",
      "imagePullPolicy" : "IfNotPresent",
      "args" : [],
      "env" : [],
      "resources" : {}
    },
    "dcgmExporter" : {
      "enabled" : true,
      "repository" : "nvcr.io/nvidia/k8s",
      "image" : "dcgm-exporter",
      "version" : "3.3.8-3.6.0-ubuntu22.04",
      "imagePullPolicy" : "IfNotPresent",
      "env" : [
        {
          "name" : "DCGM_EXPORTER_LISTEN",
          "value" : ":9400"
        },
        {
          "name" : "DCGM_EXPORTER_KUBERNETES",
          "value" : "true"
        },
        {
          "name" : "DCGM_EXPORTER_COLLECTORS",
          "value" : "/etc/dcgm-exporter/dcp-metrics-included.csv"
        }
      ],
      "resources" : {},
      "serviceMonitor" : {
        "enabled" : false,
        "interval" : "15s",
        "honorLabels" : false,
        "additionalLabels" : {},
        "relabelings" : []
      }
    },
    "gfd" : {
      "enabled" : true,
      "repository" : "nvcr.io/nvidia",
      "image" : "k8s-device-plugin",
      "version" : "v0.16.2-ubi8",
      "imagePullPolicy" : "IfNotPresent",
      "imagePullSecrets" : [],
      "env" : [
        {
          "name" : "GFD_SLEEP_INTERVAL",
          "value" : "60s"
        },
        {
          "name" : "GFD_FAIL_ON_INIT_ERROR",
          "value" : "true"
        }
      ],
      "resources" : {}
    },
    "migManager" : {
      "enabled" : true,
      "repository" : "nvcr.io/nvidia/cloud-native",
      "image" : "k8s-mig-manager",
      "version" : "v0.8.0-ubuntu20.04",
      "imagePullPolicy" : "IfNotPresent",
      "imagePullSecrets" : [],
      "env" : [
        {
          "name" : "WITH_REBOOT",
          "value" : "false"
        }
      ],
      "resources" : {},
      "config" : {
        "default" : "all-disabled",
        "create" : false,
        "name" : "",
        "data" : {}
      },
      "gpuClientsConfig" : {
        "name" : ""
      }
    },
    "nodeStatusExporter" : {
      "enabled" : false,
      "repository" : "nvcr.io/nvidia/cloud-native",
      "image" : "gpu-operator-validator",
      "imagePullPolicy" : "IfNotPresent",
      "imagePullSecrets" : [],
      "resources" : {}
    },
    "gds" : {
      "enabled" : false,
      "repository" : "nvcr.io/nvidia/cloud-native",
      "image" : "nvidia-fs",
      "version" : "2.17.5",
      "imagePullPolicy" : "IfNotPresent",
      "imagePullSecrets" : [],
      "env" : [],
      "args" : []
    },
    "gdrcopy" : {
      "enabled" : false,
      "repository" : "nvcr.io/nvidia/cloud-native",
      "image" : "gdrdrv",
      "version" : "v2.4.1-2",
      "imagePullPolicy" : "IfNotPresent",
      "imagePullSecrets" : [],
      "env" : [],
      "args" : []
    },
    "vgpuManager" : {
      "enabled" : false,
      "repository" : "",
      "image" : "vgpu-manager",
      "version" : "",
      "imagePullPolicy" : "IfNotPresent",
      "imagePullSecrets" : [],
      "env" : [],
      "resources" : {},
      "driverManager" : {
        "image" : "k8s-driver-manager",
        "repository" : "nvcr.io/nvidia/cloud-native",
        "version" : "v0.7.0",
        "imagePullPolicy" : "IfNotPresent",
        "env" : [
          {
            "name" : "ENABLE_GPU_POD_EVICTION",
            "value" : "false"
          },
          {
            "name" : "ENABLE_AUTO_DRAIN",
            "value" : "false"
          }
        ]
      }
    },
    "vgpuDeviceManager" : {
      "enabled" : true,
      "repository" : "nvcr.io/nvidia/cloud-native",
      "image" : "vgpu-device-manager",
      "version" : "v0.2.8",
      "imagePullPolicy" : "IfNotPresent",
      "imagePullSecrets" : [],
      "env" : [],
      "config" : {
        "name" : "",
        "default" : "default"
      }
    },
    "vfioManager" : {
      "enabled" : true,
      "repository" : "nvcr.io/nvidia",
      "image" : "cuda",
      "version" : "12.6.2-base-ubi9",
      "imagePullPolicy" : "IfNotPresent",
      "imagePullSecrets" : [],
      "env" : [],
      "resources" : {},
      "driverManager" : {
        "image" : "k8s-driver-manager",
        "repository" : "nvcr.io/nvidia/cloud-native",
        "version" : "v0.7.0",
        "imagePullPolicy" : "IfNotPresent",
        "env" : [
          {
            "name" : "ENABLE_GPU_POD_EVICTION",
            "value" : "false"
          },
          {
            "name" : "ENABLE_AUTO_DRAIN",
            "value" : "false"
          }
        ]
      }
    },
    "kataManager" : {
      "enabled" : false,
      "config" : {
        "artifactsDir" : "/opt/nvidia-gpu-operator/artifacts/runtimeclasses",
        "runtimeClasses" : [
          {
            "name" : "kata-nvidia-gpu",
            "nodeSelector" : {},
            "artifacts" : {
              "url" : "nvcr.io/nvidia/cloud-native/kata-gpu-artifacts:ubuntu22.04-535.54.03",
              "pullSecret" : ""
            }
          },
          {
            "name" : "kata-nvidia-gpu-snp",
            "nodeSelector" : {
              "nvidia.com/cc.capable" : "true"
            },
            "artifacts" : {
              "url" : "nvcr.io/nvidia/cloud-native/kata-gpu-artifacts:ubuntu22.04-535.86.10-snp",
              "pullSecret" : ""
            }
          }
        ]
      },
      "repository" : "nvcr.io/nvidia/cloud-native",
      "image" : "k8s-kata-manager",
      "version" : "v0.2.2",
      "imagePullPolicy" : "IfNotPresent",
      "imagePullSecrets" : [],
      "env" : [],
      "resources" : {}
    },
    "sandboxDevicePlugin" : {
      "enabled" : true,
      "repository" : "nvcr.io/nvidia",
      "image" : "kubevirt-gpu-device-plugin",
      "version" : "v1.2.10",
      "imagePullPolicy" : "IfNotPresent",
      "imagePullSecrets" : [],
      "args" : [],
      "env" : [],
      "resources" : {}
    },
    "ccManager" : {
      "enabled" : false,
      "defaultMode" : "off",
      "repository" : "nvcr.io/nvidia/cloud-native",
      "image" : "k8s-cc-manager",
      "version" : "v0.1.1",
      "imagePullPolicy" : "IfNotPresent",
      "imagePullSecrets" : [],
      "env" : [
        {
          "name" : "CC_CAPABLE_DEVICE_IDS",
          "value" : "0x2339,0x2331,0x2330,0x2324,0x2322,0x233d"
        }
      ],
      "resources" : {}
    },
    "node-feature-discovery" : {
      "enableNodeFeatureApi" : true,
      "priorityClassName" : "system-node-critical",
      "gc" : {
        "enable" : true,
        "replicaCount" : 1,
        "serviceAccount" : {
          "name" : "node-feature-discovery",
          "create" : false
        }
      },
      "worker" : {
        "serviceAccount" : {
          "name" : "node-feature-discovery",
          "create" : false
        },
        "tolerations" : [
          {
            "key" : "node-role.kubernetes.io/master",
            "operator" : "Equal",
            "value" : "",
            "effect" : "NoSchedule"
          },
          {
            "key" : "node-role.kubernetes.io/control-plane",
            "operator" : "Equal",
            "value" : "",
            "effect" : "NoSchedule"
          },
          {
            "key" : "nvidia.com/gpu",
            "operator" : "Exists",
            "effect" : "NoSchedule"
          }
        ],
        "config" : {
          "sources" : {
            "pci" : {
              "deviceClassWhitelist" : [
                "02",
                "0200",
                "0207",
                "0300",
                "0302"
              ],
              "deviceLabelFields" : [
                "vendor"
              ]
            }
          }
        }
      },
      "master" : {
        "serviceAccount" : {
          "name" : "node-feature-discovery",
          "create" : true
        },
        "config" : {
          "extraLabelNs" : [
            "nvidia.com"
          ]
        }
      }
    }
  }
 
EOF
}
