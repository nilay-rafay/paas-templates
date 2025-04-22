output "ssh_info" {
  value = data.local_file.ssh_login_info.content
}