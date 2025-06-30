output "vcluster_kubeconfig_url" {
  value = var.input1
}

#resource "null_resource" "vcluster_kubeconfig" {
#  provisioner "local-exec" {
#    command = <<EOT
#      curl -sSL -o /tmp/test/${var.vm_name}-kubeconfig.yaml ${var.input1}
#    EOT
#  }
#
#  triggers = {
#    url = var.input1
#  }
#}

#resource "null_resource" "vcluster_kubeconfig_ready" {
#  depends_on = [null_resource.vcluster_kubeconfig]
#  provisioner "local-exec" {
#    command = "while [ ! -f /tmp/test/${var.vm_name}-kubeconfig.yaml ]; do sleep 1; done"
#  }
#}

data "rafay_download_kubeconfig" "kubeconfig_cluster" {
  cluster = var.vcluster_name
}

resource "local_file" "kubeconfig" {
  lifecycle {
    ignore_changes = all
  }
  depends_on = [data.rafay_download_kubeconfig.kubeconfig_cluster]
  content    = data.rafay_download_kubeconfig.kubeconfig_cluster.kubeconfig
  filename   = "/tmp/test/vcluster2-kubeconfig.yaml"
}

resource "null_resource" "vcluster_kubeconfig_ready" {
  depends_on = [local_file.kubeconfig]
  provisioner "local-exec" {
    command = "while [ ! -f /tmp/test/vcluster2-kubeconfig.yaml ]; do sleep 1; done"
  }
}

#resource "kubectl_manifest" "kubevirt_vm" {
#  depends_on = [null_resource.vcluster_kubeconfig_ready]
#  yaml_body = <<EOF
#apiVersion: kubevirt.io/v1
#kind: VirtualMachine
#metadata:
#  name: test-vm2
#  namespace: default
#spec:
#  running: true
#  template:
#    metadata:
#      labels:
#        kubevirt.io/domain: test-vm2
#    spec:
#      domain:
#        devices:
#          disks:
#            - name: containerdisk
#              disk:
#                bus: virtio
#            - name: cloudinitdisk
#              disk:
#                bus: virtio
#        resources:
#          requests:
#            memory: 1024M
#      volumes:
#        - name: containerdisk
#          containerDisk:
#            image: quay.io/containerdisks/fedora:latest
#        - name: cloudinitdisk
#          cloudInitNoCloud:
#            userData: |
#              #cloud-config
#              password: fedora
#              chpasswd: { expire: False }
#EOF
#}

resource "kubectl_manifest" "kubevirt_vm" {
  depends_on = [null_resource.vcluster_kubeconfig_ready]
  yaml_body = templatefile("${path.module}/templates/vm.yaml.tmpl", {
    vm_name   = var.vm_name
    namespace = var.namespace
    memory    = var.memory
    image     = var.image
    user      = var.user
    password  = var.password
    ssh_key   = var.ssh_key
  })
#}
