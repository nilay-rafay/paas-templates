output "feast_mysql_root_password" {
  description = "MySQL root password for Feast"
  value       = nonsensitive(local.feast_mysql_root_password)
}

output "feast_redis_password" {
  description = "Redis password for Feast"
  value       = nonsensitive(local.feast_redis_password)
}
