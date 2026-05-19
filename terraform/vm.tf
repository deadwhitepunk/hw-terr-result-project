resource "yandex_vpc_network" "web_vpc" {
  name = var.vpc_name
}

#Create subnet in zone A
resource "yandex_vpc_subnet" "web_subnet" {
  name           = "${var.vpc_name}-ru-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.web_vpc.id
  v4_cidr_blocks = var.vm_web_default_cidr
}

# Image OS
data "yandex_compute_image" "ubuntu_2204_lts" {
  family = "ubuntu-2204-lts"
}

#Disk for VM web
resource "yandex_compute_disk" "boot_disk_web" {
  image_id = var.image_id
  type     = var.boot_disk.disk.disk_type
  size     = var.boot_disk.disk.disk_size
  zone     = var.zone
}

#Create VM web
resource "yandex_compute_instance" "web" {
  name        = "${var.zone}-${var.hostname}"
  hostname    = var.hostname
#   platform_id = var.platform_id
  zone        = var.zone

  resources {
    cores         = var.instance_resources.cores
    memory        = var.instance_resources.memory
    core_fraction = var.instance_resources.core_fraction
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot_disk_web.id
  }

  scheduling_policy { preemptible = true }

  metadata = {
    user-data          = data.template_file.cloudinit.rendered 
    serial-port-enable = 1
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.web_subnet.id
    nat                = var.nat
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.web_out.id]
  }
}

data "template_file" "cloudinit" {
  template = file("./cloud-init.yml")

  vars = {
    ssh_public_key = file("~/.ssh/id_ed25519.pub")
  }
}