# Outputs для VPC и сети
output "vpc_id" {
  description = "ID of the created VPC network"
  value       = yandex_vpc_network.web_vpc.id
}

output "subnet_id" {
  description = "ID of the created subnet"
  value       = yandex_vpc_subnet.web_subnet.id
}

# Outputs для MySQL кластера
output "mysql_cluster_id" {
  description = "ID of the MySQL cluster"
  value       = yandex_mdb_mysql_cluster.app-mysql.id
}

output "mysql_cluster_name" {
  description = "Name of the MySQL cluster"
  value       = yandex_mdb_mysql_cluster.app-mysql.name
}

output "mysql_host" {
  description = "MySQL host FQDN"
  value       = yandex_mdb_mysql_cluster.app-mysql.host[0].fqdn
}

output "mysql_database_name" {
  description = "Name of the created database"
  value       = yandex_mdb_mysql_database.db1.name
}

output "mysql_user" {
  description = "MySQL user name"
  value       = yandex_mdb_mysql_user.user1.name
  sensitive   = true
}

# Outputs для VM
output "web_vm_external_ip" {
  description = "External IP address of the web VM"
  value       = yandex_compute_instance.web.network_interface.0.nat_ip_address
}

output "web_vm_internal_ip" {
  description = "Internal IP address of the web VM"
  value       = yandex_compute_instance.web.network_interface.0.ip_address
}

output "web_vm_name" {
  description = "Name of the web VM"
  value       = yandex_compute_instance.web.name
}

output "boot_disk_id" {
  description = "ID of the boot disk"
  value       = yandex_compute_disk.boot_disk_web.id
}

# Outputs для Registry
output "registry_id" {
  description = "ID of the container registry"
  value       = yandex_container_registry.docker_registry.id
}

output "registry_name" {
  description = "Name of the container registry"
  value       = yandex_container_registry.docker_registry.name
}

output "repository_name" {
  description = "Name of the Docker repository"
  value       = yandex_container_repository.app_docker.name
}

output "web_app_url" {
  description = "URL to access the web application"
  value       = "http://${yandex_compute_instance.web.network_interface.0.nat_ip_address}"
}