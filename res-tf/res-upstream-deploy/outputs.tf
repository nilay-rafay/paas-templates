output "cluster_name" {
  value = rafay_mks_cluster.upstream-sample-cluster.metadata.name
}

output "nodes_information" {
  value = {
    nodes_info = {
      for node_key, node in merge(var.controlplane_nodes, var.worker_nodes) : node_key => {
        private_ip       = node.private_ip
        ip_address       = node.ssh.ip_address
        hostname         = node.hostname
        operating_system = node.operating_system
      }
    }
    number_of_nodes = length(var.controlplane_nodes) + length(var.worker_nodes)
  }
}

output "network_configuration" {
  value = {
    cni            = var.network.cni
    pod_subnet     = var.network.pod_subnet
    service_subnet = var.network.service_subnet
  }
}
