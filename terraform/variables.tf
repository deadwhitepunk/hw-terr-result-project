variable "folder_id" {
  description = "(Optional) - Yandex Cloud Folder ID where resources will be created."
  type        = string
  default = "b1gs2kftghrh9vu74phs"
}

variable "repository_name" {
  description = "Repository name inside registry"
  type        = string
  default     = "test-repository"
}

variable "cloud_id" {
    type = string
    default = "b1gj4267eqa8nhcdjka9"
}

variable "vpc_name" {
  type = string
  description = "Name of VPC"
  default = "web"
}

variable "vm_web_default_cidr" {
  type = list(string)
  description = "default cidr (like xxx.xxx.xxx.xxx/xx)"
  default = [ "10.0.1.0/24" ]
}

variable "zone" {
  type = string
  description = "YC Zone (A,B,C,E)"
  default = "ru-central1-a"
}

variable "registry_name" {
  type = string
  description = "Docker registry name"
  default = "webapp"
}

variable "nat" {
  type = bool
  default = true
  description = "NAT"
}

variable "nat_mysql" {
  type = bool
  default = true
  description = "NAT for MySQL"
}
variable "mysql_user" {
  type = string
  sensitive = true
  description = "Database user"
}
variable "mysql_password" {
  type = string
  sensitive = true
  description = "Database user password"
}
variable "mysql_database_name" {
  type = string
  default = "app"
  description = "name of first database"
}

variable "hostname" {
  type = string
  description = "hostname vm"
  default = "web"
}
variable "image_id" {
  description = "Boot disk image id. If not provided, it defaults to Ubuntu 22.04 LTS image id"
  type        = string
  default     = "fd833v6c5tb0udvk4jo6"
}

variable "boot_disk" {
  type = object({
    disk = object({
      disk_type = string
      disk_size = number
    })
  })

  default = {
    disk = {
      disk_type = "network-ssd"
      disk_size = 15
    }
  }
}

variable "ssh_public_key" {
  type = string
  description = "Variable for ssh key in cloud-init"
}

variable "instance_resources" {
    type = object({
      cores = number
      memory = number
      core_fraction = number
    })

    default = {
      cores = 2
      memory = 2
      core_fraction = 20
    }
}