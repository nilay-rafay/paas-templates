variable "cluster_name" {
  description = "The name of the host cluster"
  type        = string
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "The cluster name must not be empty."
  }
}

variable "rctl_config_path" {
  description = "The path to the Rafay CLI config file"
  type        = string
  default     = "opt/rafay"
}

variable "enable_opa_gatekeeper" {
  description = "deploy opa gatekeeper"
  type = bool 
  default = false
}

variable "constraints_yaml" {
  description = "All opa constraint yaml content"
  type = string
}

variable "templates_yaml" {
  type = string
  description = "All opa templates yaml content"
  default = <<YAML
# users
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: allowed-users
  annotations:
    description: Controls the user and group IDs of the container.
spec:
  crd:
    spec:
      names:
        kind: Allowed-Users
      validation:
        openAPIV3Schema:
          type: object
          properties:
            runAsUser:
              type: object
              properties:
                rule:
                  type: string
                ranges:
                  type: array
                  items:
                    type: object
                    properties:
                      min:
                        type: integer
                      max:
                        type: integer
            runAsGroup:
              type: object
              properties:
                rule:
                  type: string
                ranges:
                  type: array
                  items:
                    type: object
                    properties:
                      min:
                        type: integer
                      max:
                        type: integer
            supplementalGroups:
              type: object
              properties:
                rule:
                  type: string
                ranges:
                  type: array
                  items:
                    type: object
                    properties:
                      min:
                        type: integer
                      max:
                        type: integer
            fsGroup:
              type: object
              properties:
                rule:
                  type: string
                ranges:
                  type: array
                  items:
                    type: object
                    properties:
                      min:
                        type: integer
                      max:
                        type: integer
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package allowedusers

        violation[{"msg": msg}] {
          fields := ["runAsUser", "runAsGroup", "supplementalGroups", "fsGroup"]
          field := fields[_]
          container := input_containers[_]
          msg := get_type_violation(field, container)
        }

        get_type_violation(field, container) = msg {
          field == "runAsUser"
          params := input.parameters[field]
          msg := get_user_violation(params, container)
        }

        get_type_violation(field, container) = msg {
          field != "runAsUser"
          params := input.parameters[field]
          msg := get_violation(field, params, container)
        }

        # RunAsUser (separate due to "MustRunAsNonRoot")
        get_user_violation(params, container) = msg {
          rule := params.rule
          provided_user := get_field_value("runAsUser", container, input.review)
          not accept_users(rule, provided_user)
          msg := sprintf("Container %v is attempting to run as disallowed user %v. Allowed runAsUser: %v", [container.name, provided_user, params])
        }

        get_user_violation(params, container) = msg {
          not get_field_value("runAsUser", container, input.review)
          params.rule = "MustRunAs"
          msg := sprintf("Container %v is attempting to run without a required securityContext/runAsUser", [container.name])
        }

        get_user_violation(params, container) = msg {
          params.rule = "MustRunAsNonRoot"
          not get_field_value("runAsUser", container, input.review)
          not get_field_value("runAsNonRoot", container, input.review)
          msg := sprintf("Container %v is attempting to run without a required securityContext/runAsNonRoot or securityContext/runAsUser != 0", [container.name])
        }

        accept_users("RunAsAny", provided_user) {true}

        accept_users("MustRunAsNonRoot", provided_user) = res {res := provided_user != 0}

        accept_users("MustRunAs", provided_user) = res  {
          ranges := input.parameters.runAsUser.ranges
          res := is_in_range(provided_user, ranges)
        }

        # Group Options
        get_violation(field, params, container) = msg {
          rule := params.rule
          provided_value := get_field_value(field, container, input.review)
          not is_array(provided_value)
          not accept_value(rule, provided_value, params.ranges)
          msg := sprintf("Container %v is attempting to run as disallowed group %v. Allowed %v: %v", [container.name, provided_value, field, params])
        }
        # SupplementalGroups is array value
        get_violation(field, params, container) = msg {
          rule := params.rule
          array_value := get_field_value(field, container, input.review)
          is_array(array_value)
          provided_value := array_value[_]
          not accept_value(rule, provided_value, params.ranges)
          msg := sprintf("Container %v is attempting to run with disallowed supplementalGroups %v. Allowed %v: %v", [container.name, array_value, field, params])
        }

        get_violation(field, params, container) = msg {
          not get_field_value(field, container, input.review)
          params.rule == "MustRunAs"
          msg := sprintf("Container %v is attempting to run without a required securityContext/%v. Allowed %v: %v", [container.name, field, field, params])
        }

        accept_value("RunAsAny", provided_value, ranges) {true}

        accept_value("MayRunAs", provided_value, ranges) = res { res := is_in_range(provided_value, ranges)}

        accept_value("MustRunAs", provided_value, ranges) = res { res := is_in_range(provided_value, ranges)}


        # If container level is provided, that takes precedence
        get_field_value(field, container, review) = out {
          container_value := get_seccontext_field(field, container)
          out := container_value
        }

        # If no container level exists, use pod level
        get_field_value(field, container, review) = out {
          not has_seccontext_field(field, container)
          review.kind.kind == "Pod"
          pod_value := get_seccontext_field(field, review.object.spec)
          out := pod_value
        }

        # Helper Functions
        is_in_range(val, ranges) = res {
          matching := {1 | val >= ranges[j].min; val <= ranges[j].max}
          res := count(matching) > 0
        }

        has_seccontext_field(field, obj) {
          get_seccontext_field(field, obj)
        }

        has_seccontext_field(field, obj) {
          get_seccontext_field(field, obj) == false
        }

        get_seccontext_field(field, obj) = out {
          out = obj.securityContext[field]
        }

        input_containers[c] {
          c := input.review.object.spec.containers[_]
        }
        input_containers[c] {
          c := input.review.object.spec.initContainers[_]
        }

---
# selinux
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: se-linux
  annotations:
    description: Controls the SELinux context of the container.
spec:
  crd:
    spec:
      names:
        kind: SE-Linux
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          type: object
          properties:
            allowedSELinuxOptions:
              type: array
              items:
                type: object
                properties:
                  level:
                      type: string
                  role:
                      type: string
                  type:
                      type: string
                  user:
                      type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package selinux

        # Disallow top level custom SELinux options
        violation[{"msg": msg, "details": {}}] {
            has_field(input.review.object.spec.securityContext, "seLinuxOptions")
            not input_seLinuxOptions_allowed(input.review.object.spec.securityContext.seLinuxOptions)
            msg := sprintf("SELinux options is not allowed, pod: %v. Allowed options: %v", [input.review.object.metadata.name, input.parameters.allowedSELinuxOptions])
        }
        # Disallow container level custom SELinux options
        violation[{"msg": msg, "details": {}}] {
            c := input_security_context[_]
            has_field(c.securityContext, "seLinuxOptions")
            not input_seLinuxOptions_allowed(c.securityContext.seLinuxOptions)
            msg := sprintf("SELinux options is not allowed, pod: %v, container %v. Allowed options: %v", [input.review.object.metadata.name, c.name, input.parameters.allowedSELinuxOptions])
        }

        input_seLinuxOptions_allowed(options) {
            params := input.parameters.allowedSELinuxOptions[_]
            field_allowed("level", options, params)
            field_allowed("role", options, params)
            field_allowed("type", options, params)
            field_allowed("user", options, params)
        }

        field_allowed(field, options, params) {
            params[field] == options[field]
        }
        field_allowed(field, options, params) {
            not has_field(options, field)
        }

        input_security_context[c] {
            c := input.review.object.spec.containers[_]
            has_field(c.securityContext, "seLinuxOptions")
        }
        input_security_context[c] {
            c := input.review.object.spec.initContainers[_]
            has_field(c.securityContext, "seLinuxOptions")
        }

        # has_field returns whether an object has a field
        has_field(object, field) = true {
            object[field]
        }

---
# allow-privilege-escalation
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: allow-privilege-escalation-container
  annotations:
    description: Controls restricting escalation to root privileges.
spec:
  crd:
    spec:
      names:
        kind: Allow-Privilege-Escalation-Container
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package allowprivilegeescalationcontainer

        violation[{"msg": msg, "details": {}}] {
            c := input_containers[_]
            input_allow_privilege_escalation(c)
            msg := sprintf("Privilege escalation container is not allowed: %v", [c.name])
        }

        input_allow_privilege_escalation(c) {
            not has_field(c, "securityContext")
        }
        input_allow_privilege_escalation(c) {
            not c.securityContext.allowPrivilegeEscalation == false
        }
        input_containers[c] {
            c := input.review.object.spec.containers[_]
        }
        input_containers[c] {
            c := input.review.object.spec.initContainers[_]
        }
        # has_field returns whether an object has a field
        has_field(object, field) = true {
            object[field]
        }

---
# seccomp
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: seccomp
  annotations:
    description: Controls the seccomp profile used by containers.
spec:
  crd:
    spec:
      names:
        kind: Seccomp
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          type: object
          properties:
            allowedProfiles:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package seccomp

        violation[{"msg": msg, "details": {}}] {
            metadata := input.review.object.metadata
            not input_wildcard_allowed(metadata)
            container := input_containers[_]
            not input_container_allowed(metadata, container)
            msg := sprintf("Seccomp profile is not allowed, pod: %v, container: %v, Allowed profiles: %v", [metadata.name, container.name, input.parameters.allowedProfiles])
        }

        input_wildcard_allowed(metadata) {
            input.parameters.allowedProfiles[_] == "*"
        }

        input_container_allowed(metadata, container) {
            not get_container_profile(metadata, container)
            metadata.annotations["seccomp.security.alpha.kubernetes.io/pod"] == input.parameters.allowedProfiles[_]
        }

        input_container_allowed(metadata, container) {
          profile := get_container_profile(metadata, container)
          profile == input.parameters.allowedProfiles[_]
        }

        get_container_profile(metadata, container) = profile {
          value := metadata.annotations[key]
            startswith(key, "container.seccomp.security.alpha.kubernetes.io/")
            [prefix, name] := split(key, "/")
            name == container.name
            profile = value
        }

        input_containers[c] {
            c := input.review.object.spec.containers[_]
        }
        input_containers[c] {
            c := input.review.object.spec.initContainers[_]
        }
---
# volumes
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: volume-types
  annotations:
    description: Controls usage of volume types.
spec:
  crd:
    spec:
      names:
        kind: Volume-Types
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          type: object
          properties:
            volumes:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package volumetypes

        violation[{"msg": msg, "details": {}}] {
            volume_fields := {x | input.review.object.spec.volumes[_][x]; x != "name"}
            field := volume_fields[_]
            not input_volume_type_allowed(field)
            msg := sprintf("The volume type %v is not allowed, pod: %v. Allowed volume types: %v", [field, input.review.object.metadata.name, input.parameters.volumes])
        }

        # * may be used to allow all volume types
        input_volume_type_allowed(field) {
            input.parameters.volumes[_] == "*"
        }

        input_volume_type_allowed(field) {
            field == input.parameters.volumes[_]
        }

---
# host-filesystem
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: host-filesystem
  annotations:
    description: Controls usage of the host filesystem.
spec:
  crd:
    spec:
      names:
        kind: Host-Filesystem
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          type: object
          properties:
            allowedHostPaths:
              type: array
              items:
                type: object
                properties:
                  readOnly:
                    type: boolean
                  pathPrefix:
                    type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package hostfilesystem

        violation[{"msg": msg, "details": {}}] {
            volume := input_hostpath_volumes[_]
            allowedPaths := get_allowed_paths(input)
            input_hostpath_violation(allowedPaths, volume)
            msg := sprintf("HostPath volume %v is not allowed, pod: %v. Allowed path: %v", [volume, input.review.object.metadata.name, allowedPaths])
        }

        input_hostpath_violation(allowedPaths, volume) {
            # An empty list means all host paths are blocked
            allowedPaths == []
        }
        input_hostpath_violation(allowedPaths, volume) {
            not input_hostpath_allowed(allowedPaths, volume)
        }

        get_allowed_paths(arg) = out {
            not arg.parameters
            out = []
        }
        get_allowed_paths(arg) = out {
            not arg.parameters.allowedHostPaths
            out = []
        }
        get_allowed_paths(arg) = out {
            out = arg.parameters.allowedHostPaths
        }

        input_hostpath_allowed(allowedPaths, volume) {
            allowedHostPath := allowedPaths[_]
            path_matches(allowedHostPath.pathPrefix, volume.hostPath.path)
            not allowedHostPath.readOnly == true
        }

        input_hostpath_allowed(allowedPaths, volume) {
            allowedHostPath := allowedPaths[_]
            path_matches(allowedHostPath.pathPrefix, volume.hostPath.path)
            allowedHostPath.readOnly
            not writeable_input_volume_mounts(volume.name)
        }

        writeable_input_volume_mounts(volume_name) {
            container := input_containers[_]
            mount := container.volumeMounts[_]
            mount.name == volume_name
            not mount.readOnly
        }

        # This allows "/foo", "/foo/", "/foo/bar" etc., but
        # disallows "/fool", "/etc/foo" etc.
        path_matches(prefix, path) {
            a := split(trim(prefix, "/"), "/")
            b := split(trim(path, "/"), "/")
            prefix_matches(a, b)
        }
        prefix_matches(a, b) {
            count(a) <= count(b)
            not any_not_equal_upto(a, b, count(a))
        }

        any_not_equal_upto(a, b, n) {
            a[i] != b[i]
            i < n
        }

        input_hostpath_volumes[v] {
            v := input.review.object.spec.volumes[_]
            has_field(v, "hostPath")
        }

        # has_field returns whether an object has a field
        has_field(object, field) = true {
            object[field]
        }
        input_containers[c] {
            c := input.review.object.spec.containers[_]
        }

        input_containers[c] {
            c := input.review.object.spec.initContainers[_]
        }

---
# proc-mount
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: proc-mount
  annotations:
    description: Controls the allowed `procMount` types for the container.
spec:
  crd:
    spec:
      names:
        kind: Proc-Mount
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          type: object
          properties:
            procMount:
              type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package procmount

        violation[{"msg": msg, "details": {}}] {
            c := input_containers[_]
            allowedProcMount := get_allowed_proc_mount(input)
            not input_proc_mount_type_allowed(allowedProcMount, c)
            msg := sprintf("ProcMount type is not allowed, container: %v. Allowed procMount types: %v", [c.name, allowedProcMount])
        }

        input_proc_mount_type_allowed(allowedProcMount, c) {
            allowedProcMount == "default"
            lower(c.securityContext.procMount) == "default"
        }
        input_proc_mount_type_allowed(allowedProcMount, c) {
            allowedProcMount == "unmasked"
        }

        input_containers[c] {
            c := input.review.object.spec.containers[_]
            c.securityContext.procMount
        }
        input_containers[c] {
            c := input.review.object.spec.initContainers[_]
            c.securityContext.procMount
        }

        get_allowed_proc_mount(arg) = out {
            not arg.parameters
            out = "default"
        }
        get_allowed_proc_mount(arg) = out {
            not arg.parameters.procMount
            out = "default"
        }
        get_allowed_proc_mount(arg) = out {
            not valid_proc_mount(arg.parameters.procMount)
            out = "default"
        }
        get_allowed_proc_mount(arg) = out {
            out = lower(arg.parameters.procMount)
        }

        valid_proc_mount(str) {
            lower(str) == "default"
        }
        valid_proc_mount(str) {
            lower(str) == "unmasked"
        }

---
# privileged-containers
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: privileged-container
  annotations:
    description: Controls running of privileged containers.
spec:
  crd:
    spec:
      names:
        kind: Privileged-Container
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package privileged

        violation[{"msg": msg, "details": {}}] {
            c := input_containers[_]
            c.securityContext.privileged
            msg := sprintf("Privileged container is not allowed: %v, securityContext: %v", [c.name, c.securityContext])
        }

        input_containers[c] {
            c := input.review.object.spec.containers[_]
        }

        input_containers[c] {
            c := input.review.object.spec.initContainers[_]
        }

---
# linux-capabilities
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: linux-capabilities
  annotations:
    description: Controls Linux capabilities.
spec:
  crd:
    spec:
      names:
        kind: Linux-Capabilities
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          type: object
          properties:
            allowedCapabilities:
              type: array
              items:
                type: string
            requiredDropCapabilities:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package capabilities

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          has_disallowed_capabilities(container)
          msg := sprintf("container <%v> has a disallowed capability. Allowed capabilities are %v", [container.name, get_default(input.parameters, "allowedCapabilities", "NONE")])
        }

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          missing_drop_capabilities(container)
          msg := sprintf("container <%v> is not dropping all required capabilities. Container must drop all of %v", [container.name, input.parameters.requiredDropCapabilities])
        }



        violation[{"msg": msg}] {
          container := input.review.object.spec.initContainers[_]
          has_disallowed_capabilities(container)
          msg := sprintf("init container <%v> has a disallowed capability. Allowed capabilities are %v", [container.name, get_default(input.parameters, "allowedCapabilities", "NONE")])
        }

        violation[{"msg": msg}] {
          container := input.review.object.spec.initContainers[_]
          missing_drop_capabilities(container)
          msg := sprintf("init container <%v> is not dropping all required capabilities. Container must drop all of %v", [container.name, input.parameters.requiredDropCapabilities])
        }


        has_disallowed_capabilities(container) {
          allowed := {c | c := input.parameters.allowedCapabilities[_]}
          not allowed["*"]
          capabilities := {c | c := container.securityContext.capabilities.add[_]}
          count(capabilities - allowed) > 0
        }

        missing_drop_capabilities(container) {
          must_drop := {c | c := input.parameters.requiredDropCapabilities[_]}
          dropped := {c | c := container.securityContext.capabilities.drop[_]}
          count(must_drop - dropped) > 0
        }

        get_default(obj, param, _default) = out {
          out = obj[param]
        }

        get_default(obj, param, _default) = out {
          not obj[param]
          not obj[param] == false
          out = _default
        }

---
# flexvolume-drivers
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: flex-volumes
  annotations:
    description: Controls the allowlist of Flexvolume drivers.
spec:
  crd:
    spec:
      names:
        kind: Flex-Volumes
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          type: object
          properties:
            allowedFlexVolumes:
              type: array
              items:
                type: object
                properties:
                  driver:
                    type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package flexvolumes

        violation[{"msg": msg, "details": {}}] {
            volume := input_flexvolumes[_]
            not input_flexvolumes_allowed(volume)
            msg := sprintf("FlexVolume %v is not allowed, pod: %v. Allowed drivers: %v", [volume, input.review.object.metadata.name, input.parameters.allowedFlexVolumes])
        }

        input_flexvolumes_allowed(volume) {
            input.parameters.allowedFlexVolumes[_].driver == volume.flexVolume.driver
        }

        input_flexvolumes[v] {
            v := input.review.object.spec.volumes[_]
            has_field(v, "flexVolume")
        }

        # has_field returns whether an object has a field
        has_field(object, field) = true {
            object[field]
        }

---
# apparmor
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: app-armor
  annotations:
    description: Controls the AppArmor profile used by containers.
spec:
  crd:
    spec:
      names:
        kind: App-Armor
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          type: object
          properties:
            allowedProfiles:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package apparmor

        violation[{"msg": msg, "details": {}}] {
            metadata := input.review.object.metadata
            container := input_containers[_]
            not input_apparmor_allowed(container, metadata)
            msg := sprintf("AppArmor profile is not allowed, pod: %v, container: %v. Allowed profiles: %v", [input.review.object.metadata.name, container.name, input.parameters.allowedProfiles])
        }

        input_apparmor_allowed(container, metadata) {
            metadata.annotations[key] == input.parameters.allowedProfiles[_]
            key == sprintf("container.apparmor.security.beta.kubernetes.io/%v", [container.name])
        }

        input_containers[c] {
            c := input.review.object.spec.containers[_]
        }
        input_containers[c] {
            c := input.review.object.spec.initContainers[_]
        }
---
# host-network-ports
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: host-networking-ports
  annotations:
    description: Controls usage of host networking and ports.
spec:
  crd:
    spec:
      names:
        kind: Host-Networking-Ports
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          type: object
          properties:
            hostNetwork:
              type: boolean
            min:
              type: integer
            max:
              type: integer
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package hostnetworkingports

        violation[{"msg": msg, "details": {}}] {
          input_share_hostnetwork(input.review.object)
          msg := sprintf("The specified hostNetwork and hostPort are not allowed, pod: %v. Allowed values: %v", [input.review.object.metadata.name, input.parameters])
        }

        input_share_hostnetwork(o) {
          not input.parameters.hostNetwork
          o.spec.hostNetwork
        }

        input_share_hostnetwork(o) {
          hostPort := input_containers[_].ports[_].hostPort
          hostPort < input.parameters.min
        }

        input_share_hostnetwork(o) {
          hostPort := input_containers[_].ports[_].hostPort
          hostPort > input.parameters.max
        }

        input_containers[c] {
          c := input.review.object.spec.containers[_]
        }

        input_containers[c] {
          c := input.review.object.spec.initContainers[_]
        }

---
# host-namespaces
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: host-namespace
  annotations:
    description: Controls usage of host namespaces.
spec:
  crd:
    spec:
      names:
        kind: Host-Namespace
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package hostnamespace

        violation[{"msg": msg, "details": {}}] {
            input_share_hostnamespace(input.review.object)
            msg := sprintf("Sharing the host namespace is not allowed: %v", [input.review.object.metadata.name])
        }

        input_share_hostnamespace(o) {
            o.spec.hostPID
        }
        input_share_hostnamespace(o) {
            o.spec.hostIPC
        }

---
# read-only-root-filesystem
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: read-only-root-filesystem
  annotations:
    description: Requires the use of a read only root file system.
spec:
  crd:
    spec:
      names:
        kind: Read-Only-Root-Filesystem
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package readonlyrootfilesystem

        violation[{"msg": msg, "details": {}}] {
            c := input_containers[_]
            input_read_only_root_fs(c)
            msg := sprintf("only read-only root filesystem container is allowed: %v", [c.name])
        }

        input_read_only_root_fs(c) {
            not has_field(c, "securityContext")
        }
        input_read_only_root_fs(c) {
            not c.securityContext.readOnlyRootFilesystem == true
        }

        input_containers[c] {
            c := input.review.object.spec.containers[_]
        }
        input_containers[c] {
            c := input.review.object.spec.initContainers[_]
        }

        # has_field returns whether an object has a field
        has_field(object, field) = true {
            object[field]
        }

---
# forbidden-sysctls
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: forbidden-sysctls
  annotations:
    description: Controls the `sysctl` profile used by containers.
spec:
  crd:
    spec:
      names:
        kind: Forbidden-Sysctls
      validation:
        # Schema for the `parameters` field
        openAPIV3Schema:
          type: object
          properties:
            forbiddenSysctls:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package forbiddensysctls

        violation[{"msg": msg, "details": {}}] {
            sysctl := input.review.object.spec.securityContext.sysctls[_].name
            forbidden_sysctl(sysctl)
            msg := sprintf("The sysctl %v is not allowed, pod: %v. Forbidden sysctls: %v", [sysctl, input.review.object.metadata.name, input.parameters.forbiddenSysctls])
        }

        # * may be used to forbid all sysctls
        forbidden_sysctl(sysctl) {
            input.parameters.forbiddenSysctls[_] == "*"
        }

        forbidden_sysctl(sysctl) {
            input.parameters.forbiddenSysctls[_] == sysctl
        }

        forbidden_sysctl(sysctl) {
            startswith(sysctl, trim(input.parameters.forbiddenSysctls[_], "*"))
        }
YAML
}

variable "pod_labels" {
  description = "drift pod labels"
  type = map(string)
  default = {
    "rafay.dev/protected" = "true"
  }
}

variable "opa_excluded_namespaces" {
  description = "Namespaces excluded for opa"
  type = list(string)
}