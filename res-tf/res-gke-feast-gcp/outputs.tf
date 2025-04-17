output "feast_redis_local_host" {
  value = var.feast_redis_is_external ? null : "${helm_release.redis_instance[0].name}-master.${helm_release.redis_instance[0].namespace}.svc.cluster.local"
}